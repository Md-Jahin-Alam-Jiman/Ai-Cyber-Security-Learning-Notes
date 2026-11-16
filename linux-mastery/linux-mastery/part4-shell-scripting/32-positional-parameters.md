# Chapter 32 · Positional Parameters
📖 Book: Part IV, pp. 423–438 · ⏱ ~100 min · Prereq: Chapter 31

## Learning goals
- Read command-line arguments (`$1`, `$#`, `$@`, `shift`)
- Tell `"$@"` from `$*` and why it matters
- Parse options with `getopts`
- Write professional CLI tools with usage help and exit codes

## 1. The variables
| Variable | Meaning |
|---|---|
| `$0` | Script name (as invoked) |
| `$1` … `$9`, `${10}` | Arguments |
| `$#` | Number of arguments |
| `"$@"` | **Each argument as a separate, intact word** (use this almost always) |
| `"$*"` | All arguments joined into **one** word |
| `$@` / `$*` (unquoted) | Re-split on whitespace and globbed (usually a bug) |
| `shift [n]` | Drop the first `n` arguments |
| `set -- a b c` | Replace the arguments |
| `$?` | Last exit status |
| `$$` / `$!` | This shell's PID / last background PID |

```bash
show() { printf '[%s] ' "$@"; echo; }
set -- "a b" c
show $*       # [a] [b] [c]
show "$*"     # [a b c]
show $@       # [a] [b] [c]
show "$@"     # [a b] [c]       <- preserves the original arguments
```

## 2. Required arguments and defaults
```bash
file="${1:?usage: $0 FILE}"          # abort with a message if missing
count="${2:-10}"                     # default 10
(( $# >= 1 )) || { echo "usage: $0 FILE [COUNT]" >&2; exit 64; }
```
Exit code **64** is the conventional "usage error" (`EX_USAGE` from sysexits).

Loop over every argument: `for f in "$@"; do ...; done` (or simply `for f; do ...; done`).

## 3. Parsing options with `getopts`
```bash
while getopts ":ho:v" opt; do
  case "$opt" in
    h) usage; exit 0 ;;
    o) outfile="$OPTARG" ;;
    v) verbose=1 ;;
    :) echo "Option -$OPTARG requires an argument" >&2; exit 64 ;;
    \?) echo "Unknown option -$OPTARG" >&2; exit 64 ;;
  esac
done
shift $((OPTIND - 1))                # what's left are the non-option arguments
```
The leading `:` in `":ho:v"` enables silent mode so you print your own errors; `o:` means `-o` takes a value. `getopts` handles short options only. For long options (`--output`), parse with a `while`/`case` over `"$@"`:
```bash
while (( $# )); do
  case "$1" in
    --output) outfile="$2"; shift 2 ;;
    --output=*) outfile="${1#*=}"; shift ;;
    --) shift; break ;;
    -*) echo "unknown option $1" >&2; exit 64 ;;
    *) break ;;
  esac
done
```
macOS/BSD also offers `getopt` with different behavior than GNU `getopt`, so prefer the `getopts` builtin for portability.

## 4. Project: `triage2.sh`, a real command-line tool
```bash
#!/usr/bin/env bash
# triage2.sh - read-only host triage with options (chapter 32)
usage() {
  cat <<_EOF_
Usage: $(basename "$0") [-h] [-o FILE] [-s] [-q]
  -o FILE  write the report to FILE (default: triage-HOST-TIMESTAMP.txt)
  -s       include the slow SUID scan
  -q       quiet: don't print the report to the screen
  -h       show this help
Exit codes: 0 ok, 1 runtime error, 64 usage error
_EOF_
}

umask 077
out="triage-$(hostname)-$(date -u +%Y%m%dT%H%M%SZ).txt"
slow=0 quiet=0

while getopts ":ho:sq" opt; do
  case "$opt" in
    h)  usage; exit 0 ;;
    o)  out="$OPTARG" ;;
    s)  slow=1 ;;
    q)  quiet=1 ;;
    :)  echo "Option -$OPTARG requires an argument" >&2; usage >&2; exit 64 ;;
    \?) echo "Unknown option -$OPTARG" >&2; usage >&2; exit 64 ;;
  esac
done
shift $((OPTIND - 1))
(( $# == 0 )) || { echo "Unexpected arguments: $*" >&2; usage >&2; exit 64; }

# Refuse to overwrite files or follow symlinks (evidence safety)
if [ -e "$out" ] || [ -L "$out" ]; then echo "Refusing to overwrite $out" >&2; exit 1; fi

section() { printf '\n== %s ==\n' "$1"; }
report() {
  section "Identity";  echo "Time (UTC): $(date -u +%FT%TZ)"; echo "Host: $(hostname)"; uname -a; id
  section "Uptime";    uptime
  section "Disk";      df -h
  section "Listening"; ss -tuln 2>/dev/null || netstat -an | grep LISTEN
  if (( slow )); then
    section "SUID files"; find /usr/bin /usr/sbin /bin /sbin -xdev -perm -4000 -type f 2>/dev/null
  fi
}

if (( quiet )); then report > "$out"; else report | tee "$out"; fi
echo "Saved to $out" >&2
```
Try: `./triage2.sh -h`, `./triage2.sh -s -o case1.txt`, `./triage2.sh -x`, `./triage2.sh -o` (missing value), and run the same output name twice.

## 5. 🔐 Cyber relevance
- **Arguments are attacker-controlled input** whenever a script is called by a web app, cron job, CI pipeline, SSH forced command, or another script. Validate every argument (type, range, allowed characters); use allow-lists.
- **Option injection:** a value starting with `-` can be misread as an option: `rm "$file"` with `file="-rf"`. Always use `--` before untrusted names (`rm -- "$file"`, `grep -F -- "$pattern" file`) or prefix paths with `./`.
- **Always `"$@"`, never `$*` or unquoted `$@`.** Unquoted forms re-split and glob arguments and are a classic injection bug, same family as wildcard injection.
- **Secrets on the command line leak:** arguments appear in `ps aux`, `/proc/PID/cmdline`, shell history, audit logs, and process accounting. Don't accept `--password=...`; read from a file (mode 600), prompt (`read -s`), environment *with care*, or stdin (`--password-stdin`).
- **Exit codes are API.** Cron, CI, monitoring, and incident automations act on them. Document and keep them stable (0 ok, 1 error, 2/64 usage, 3 findings...).
- **Principle of least surprise for dangerous options:** destructive flags should require explicit confirmation or a `--yes`/`--run` and default to **dry-run**. Log who ran what: `logger -t tool "user=$(id -un) args=$*"` (be careful not to log secrets).
- **Refuse overwrites and symlinks** for report/evidence files (shown above) to avoid clobbering evidence or following an attacker-planted link.
- **Handle filenames robustly:** names can contain spaces, newlines, or begin with `-`. Pass lists with `"$@"`, arrays, or NUL-delimited streams (`find -print0 | xargs -0`).
- **Privilege checks at the top:** `(( EUID == 0 )) || { echo "run as root" >&2; exit 77; }` for admin tools; the opposite (refuse root) for tools that shouldn't need it.
- **Reviewing others' scripts:** look for `$*`, unquoted `$1`, `eval`, `sh -c "...$1..."`, and arguments passed to `system()`-style calls.

## 6. Labs
**Easy**
1. Write `args.sh` printing `$0`, `$#`, `$1`, `$2`, and all arguments with `"$@"`. Run it with `a "b c" d`.
2. Demonstrate `$*` vs `"$@"` using the `show` function.
3. Write `greet.sh` that uses the first argument or "world" if none is given.

**Medium**
4. Write `lines.sh FILE [N]` that prints the first `N` lines (default 5) and fails with exit 64 on bad usage.
5. Use `shift` to process arguments three at a time in a loop.
6. Add `-v` (verbose) and `-n NAME` options with `getopts` to `greet.sh`.

**Hard (cyber)**
7. Build and test `triage2.sh`: all options, bad options, a missing option value, an existing output file, an output path that is a symlink (`ln -s /etc/passwd evil.txt`).
8. Demonstrate option injection: create a file named `-rf` and a script that does `ls $1`; show the problem; fix with `ls -- "$1"`. Repeat with `grep`.
9. Prove secrets leak: run `sleep 100 --password=hunter2 &` and find the secret with `ps aux | grep sleep` and `cat /proc/$!/cmdline | tr '\0' ' '`. Then redesign the interface to read the password from stdin or a file.
10. Add a long option `--output=FILE` to `triage2.sh` using the `while`/`case` pattern while keeping `-o` working.

## 7. Common mistakes
- Unquoted `$1`/`$@`
- Forgetting `shift $((OPTIND - 1))`
- Accepting secrets as arguments
- No usage message or inconsistent exit codes
- Forgetting `--` for untrusted values

## 8. Quiz
1. `"$@"` vs `$*`?
2. What does `shift` do?
3. What does the leading `:` in a `getopts` string do?
4. Why is `--` important?
5. Why are secrets in arguments dangerous?
6. What does exit code 64 mean by convention?

<details><summary>Answers</summary>

1. `"$@"` preserves each argument; unquoted `$*` re-splits and globs (quoted `"$*"` joins into one string).
2. Removes the first positional parameter, shifting the others down.
3. Enables silent error mode so you handle invalid options yourself.
4. It ends option parsing so values beginning with `-` are treated as data.
5. They show up in `ps`, `/proc`, history, and logs.
6. Usage error (`EX_USAGE`).
</details>

## 9. Mastery checklist
- [ ] I handle arguments safely with `"$@"`, `shift`, `--`
- [ ] I parse options with `getopts` and give good usage/exit codes
- [ ] I never accept secrets via arguments
- [ ] I validate all inputs and refuse unsafe output paths

## Next → `33-flow-control-looping-with-for.md`
