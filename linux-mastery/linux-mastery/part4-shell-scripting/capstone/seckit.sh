#!/usr/bin/env bash
# seckit.sh - small defensive toolkit (capstone for "The Linux Command Line" course)
# Subcommands: triage | audit | logs | backup | verify | help
# Requires bash 4+ (associative arrays). Read-only except where noted (triage/backup write files).
set -u
umask 077
readonly VERSION="1.0"
PROG="$(basename "$0")"
FAILS=0

# ---------- helpers ----------
die()       { echo "$PROG: error: $*" >&2; exit 1; }
usage_err() { echo "$PROG: $*" >&2; usage >&2; exit 64; }
log()       { printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*" >&2; }
note()      { logger -t seckit "$*" 2>/dev/null || true; }
pass()      { printf 'PASS  %s\n' "$1"; }
fail()      { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }
skip()      { printf 'SKIP  %s\n' "$1"; }
mode_of()   { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null; }
sha256()    { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }

usage() {
  cat <<_EOF_
$PROG $VERSION - small defensive toolkit
Usage:
  $PROG triage [-o DIR]         collect read-only host facts into DIR (default: ./seckit-out/HOST-TIME)
  $PROG audit                   run baseline security checks
  $PROG logs [-t N] LOGFILE     summarize failed SSH logins; alert at N failures per IP (default 20)
  $PROG backup SRC DEST_DIR     create DEST_DIR/NAME-TIME.tar.gz plus a .sha256 file
  $PROG verify ARCHIVE          check the checksum and scan archive paths for traversal
  $PROG help                    show this help
Exit codes: 0 ok / clean, 1 error, 3 findings (audit/logs/verify), 64 usage error
_EOF_
}

# ---------- triage ----------
cmd_triage() {
  local outdir="" opt
  OPTIND=1
  while getopts ":o:" opt; do
    case "$opt" in
      o)  outdir="$OPTARG" ;;
      :)  usage_err "option -$OPTARG needs a value" ;;
      *)  usage_err "unknown option -$OPTARG" ;;
    esac
  done
  shift $((OPTIND - 1))
  (( $# == 0 )) || usage_err "unexpected arguments: $*"
  [ -n "$outdir" ] || outdir="seckit-out/$(hostname)-$(date -u +%Y%m%dT%H%M%SZ)"
  if [ -e "$outdir" ] || [ -L "$outdir" ]; then die "refusing to reuse existing path: $outdir"; fi
  mkdir -p -- "$outdir" || die "cannot create $outdir"
  local f="$outdir/triage.txt"
  {
    printf '== Identity ==\nTime (UTC): %s\nHost: %s\nUser: %s\n' "$(date -u +%FT%TZ)" "$(hostname)" "$(id)"
    printf '\n== Kernel ==\n';          uname -a
    printf '\n== Uptime ==\n';          uptime
    printf '\n== Disk ==\n';            df -h
    printf '\n== Listening ==\n';       ss -tuln 2>/dev/null || netstat -an 2>/dev/null | grep LISTEN
    printf '\n== Top memory ==\n';      ps -eo pid,user,%mem,comm | sort -k3 -nr | head -6
    printf '\n== Recent logins ==\n';   last -n 5 2>/dev/null
  } > "$f"
  ( cd "$outdir" && sha256 triage.txt > triage.txt.sha256 )
  log "triage saved: $f"
  note "triage by $(id -un) -> $f"
}

# ---------- audit ----------
cmd_audit() {
  local m cfg=/etc/ssh/sshd_config extra
  FAILS=0
  if [ -e /etc/shadow ]; then
    m="$(mode_of /etc/shadow)"
    if [ "${m: -1}" = "0" ]; then pass "/etc/shadow not accessible to others (mode $m)"
    else fail "/etc/shadow accessible to others (mode $m)"; fi
  else skip "/etc/shadow not present"; fi

  if [ -r "$cfg" ]; then
    if grep -Eqi '^[[:space:]]*PermitRootLogin[[:space:]]+yes' "$cfg"; then fail "SSH PermitRootLogin yes"
    else pass "SSH root login not explicitly enabled"; fi
    if grep -Eqi '^[[:space:]]*PasswordAuthentication[[:space:]]+no' "$cfg"; then pass "SSH password authentication disabled"
    else fail "SSH password authentication not disabled"; fi
  else skip "$cfg unreadable or missing"; fi

  if [ -d "$HOME/.ssh" ]; then
    m="$(mode_of "$HOME/.ssh")"
    if [ "$m" = "700" ]; then pass "~/.ssh mode 700"; else fail "~/.ssh mode $m (expected 700)"; fi
  else skip "no ~/.ssh"; fi

  extra="$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)"
  if [ -z "$extra" ]; then pass "no extra UID-0 accounts"; else fail "extra UID-0 accounts: $extra"; fi

  extra="$(awk -F: '$2 == "" {print $1}' /etc/passwd)"
  if [ -z "$extra" ]; then pass "no empty password fields in /etc/passwd"; else fail "empty password field: $extra"; fi

  extra="$(find /etc -xdev -type f -perm -0002 2>/dev/null | head -5)"
  if [ -z "$extra" ]; then pass "no world-writable files in /etc"; else fail "world-writable in /etc: $extra"; fi

  echo "----"; echo "Failures: $FAILS"
  note "audit by $(id -un): failures=$FAILS"
  (( FAILS == 0 )) || exit 3
}

# ---------- logs ----------
cmd_logs() {
  (( BASH_VERSINFO[0] >= 4 )) || die "logs needs bash 4 or newer (macOS: brew install bash)"
  local threshold=20 opt
  OPTIND=1
  while getopts ":t:" opt; do
    case "$opt" in
      t)  threshold="$OPTARG" ;;
      :)  usage_err "option -$OPTARG needs a value" ;;
      *)  usage_err "unknown option -$OPTARG" ;;
    esac
  done
  shift $((OPTIND - 1))
  [[ $threshold =~ ^[0-9]+$ ]] || usage_err "threshold must be a number"
  (( $# == 1 )) || usage_err "logs needs exactly one LOGFILE"
  local logfile="$1"
  [ -r "$logfile" ] || die "cannot read $logfile"

  local -A by_ip by_user
  local re='Failed password for (invalid user )?([^ ]+) from ([0-9.]+)'
  local line user ip total=0 alerts=0
  while IFS= read -r line; do
    if [[ $line =~ $re ]]; then
      user="${BASH_REMATCH[2]}"; ip="${BASH_REMATCH[3]}"
      by_ip[$ip]=$(( ${by_ip[$ip]:-0} + 1 ))
      by_user[$user]=$(( ${by_user[$user]:-0} + 1 ))
      total=$((total + 1))
    fi
  done < "$logfile"

  echo "Total failed logins: $total"
  echo; echo "Top source IPs"
  for ip in "${!by_ip[@]}"; do printf '%6d  %s\n' "${by_ip[$ip]}" "$ip"; done | sort -nr | head -5
  echo; echo "Top targeted usernames"
  for user in "${!by_user[@]}"; do printf '%6d  %s\n' "${by_user[$user]}" "$user"; done | sort -nr | head -5
  echo
  for ip in "${!by_ip[@]}"; do
    if (( by_ip[$ip] >= threshold )); then
      printf 'ALERT  %-16s %5d failures (threshold %d)\n' "$ip" "${by_ip[$ip]}" "$threshold"
      alerts=$((alerts + 1))
    fi
  done
  echo "Alerts: $alerts"
  note "logs analysis of $logfile: total=$total alerts=$alerts"
  (( alerts == 0 )) || exit 3
}

# ---------- backup ----------
cmd_backup() {
  (( $# == 2 )) || usage_err "backup needs SRC and DEST_DIR"
  local src="$1" dest="$2" abs name ts archive
  [ -d "$src" ] || die "source is not a directory: $src"
  abs="$(cd "$src" && pwd -P)" || die "cannot resolve $src"
  [ "$abs" != "/" ] || die "refusing to back up /"
  local created=0
  if [ ! -d "$dest" ]; then mkdir -p -- "$dest" || die "cannot create $dest"; created=1; fi
  case "$(cd "$dest" && pwd -P)/" in
    "$abs"/*) (( created )) && rmdir -- "$dest" 2>/dev/null; die "DEST_DIR must not be inside SRC" ;;
  esac
  name="$(basename -- "$abs")"
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  archive="$dest/$name-$ts.tar.gz"
  if [ -e "$archive" ] || [ -L "$archive" ]; then die "refusing to overwrite $archive"; fi
  tar -czf "$archive" -C "$(dirname -- "$abs")" -- "$name" || die "tar failed"
  gzip -t "$archive" || die "gzip integrity test failed"
  ( cd "$dest" && sha256 "$(basename -- "$archive")" > "$(basename -- "$archive").sha256" ) || die "checksum failed"
  log "backup created: $archive"
  note "backup of $abs -> $archive"
}

# ---------- verify ----------
cmd_verify() {
  (( $# == 1 )) || usage_err "verify needs exactly one ARCHIVE"
  local a="$1" bad=0 dir base
  [ -f "$a" ] || die "no such file: $a"
  dir="$(dirname -- "$a")"; base="$(basename -- "$a")"
  if [ -f "$a.sha256" ]; then
    if ( cd "$dir" && sha256 -c "$base.sha256" ) >/dev/null 2>&1; then pass "checksum matches"
    else fail "checksum MISMATCH"; bad=$((bad + 1)); fi
  else
    echo "WARN  no $base.sha256 file found"
  fi
  if tar -tzf "$a" >/dev/null 2>&1; then pass "archive readable"
  else fail "archive unreadable"; bad=$((bad + 1)); fi
  if tar -tzf "$a" 2>/dev/null | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
    fail "unsafe paths found (absolute or contains ..)"; bad=$((bad + 1))
  else
    pass "no absolute or .. paths"
  fi
  (( bad == 0 )) || exit 3
}

# ---------- main ----------
main() {
  local cmd="${1:-help}"
  (( $# == 0 )) || shift
  case "$cmd" in
    triage) cmd_triage "$@" ;;
    audit)  cmd_audit "$@" ;;
    logs)   cmd_logs "$@" ;;
    backup) cmd_backup "$@" ;;
    verify) cmd_verify "$@" ;;
    help|-h|--help) usage ;;
    *) usage_err "unknown command: $cmd" ;;
  esac
}
main "$@"
