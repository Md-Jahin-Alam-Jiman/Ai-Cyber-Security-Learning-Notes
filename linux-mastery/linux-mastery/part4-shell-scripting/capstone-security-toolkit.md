# Capstone · Build `seckit`, Your Own Defensive Toolkit
🎯 Covers the **whole course** (chapters 1–36) · ⏱ ~6–8 hours over several sessions · Do this **after** chapter 36

## Mission
Build one professional-quality command-line tool, `seckit.sh`, that an analyst could drop onto a Linux server and use to **triage, audit, analyze logs, back up, and verify evidence**. It combines everything you learned: navigation and files, permissions, processes, redirection and pipelines, regex, text processing, archiving, networking basics, and every scripting feature from chapters 24–36.

> 📌 **Rule:** attempt each stage on your own first. A tested reference solution is in `capstone/seckit.sh`. Open it only **after** you finish a stage, to compare designs, not to copy.

## Ground rules
- Work in `~/linux-lab/capstone`
- Bash 4+ (`echo "$BASH_VERSION"`). On macOS: `brew install bash`. On Alpine: `apk add bash`
- Read-only by default; only `triage` and `backup` write files, and they must **refuse to overwrite**
- No secrets in arguments, no `eval`, quote every expansion, use `--` before untrusted values
- Run `shellcheck` and `bash -n` before every stage's acceptance test
- Keep a hash of your final script and of any evidence/test data

## Specification
| Subcommand | Behavior | Exit codes |
|---|---|---|
| `seckit.sh triage [-o DIR]` | Writes `triage.txt` + `triage.txt.sha256` to a **new** directory (default `./seckit-out/HOST-TIMESTAMP`): identity, kernel, uptime, disk, listening sockets, top-5 memory processes, recent logins. Refuses an existing path (including symlinks). | 0 ok · 1 error · 64 usage |
| `seckit.sh audit` | PASS/FAIL/SKIP checks: `/etc/shadow` not accessible to others; SSH root login not enabled; SSH password auth disabled; `~/.ssh` is 700; no extra UID-0 accounts; no empty password fields in `/etc/passwd`; no world-writable files in `/etc`. Prints failure count. | 0 clean · 3 findings |
| `seckit.sh logs [-t N] LOGFILE` | Summarizes **failed SSH logins**: total, top 5 IPs, top 5 usernames, alerts for IPs with ≥ N failures (default 20). Uses associative arrays. | 0 clean · 3 alerts · 1 error · 64 usage |
| `seckit.sh backup SRC DEST_DIR` | Creates `DEST_DIR/NAME-UTCTIME.tar.gz` and a `.sha256` file; tests gzip integrity; refuses to overwrite, to back up `/`, or to write inside SRC. | 0 ok · 1 error |
| `seckit.sh verify ARCHIVE` | Checks the checksum file (if present), that the archive is readable, and that it contains **no absolute or `..` paths**. | 0 ok · 3 problems |
| `seckit.sh help` | Usage text. | 0 |

**Global requirements:** `umask 077`; UTC timestamps; messages on stderr; consistent exit codes; syslog entries via `logger` (ignore failure); portable `sha256sum`/`shasum -a 256` helper; helpful usage on errors (exit 64).

## Architecture (top-down, chapter 26)
```
seckit.sh
├── helpers        die, usage_err, log, note, pass/fail/skip, mode_of, sha256
├── usage
├── cmd_triage     getopts -o, mkdir, brace-group output, checksum
├── cmd_audit      stat + grep + awk + find, FAILS counter
├── cmd_logs       getopts -t, associative arrays, regex with BASH_REMATCH
├── cmd_backup     path checks, tar -C, gzip -t, checksum
├── cmd_verify     sha256 -c, tar -t, grep traversal patterns
└── main           case dispatch (default-deny on unknown commands)
```

## Stages

### Stage 1 · Skeleton and safety (chapters 24, 26, 30, 31)
1. Shebang, header comment, `set -u`, `umask 077`, constants with `readonly`.
2. Write `usage`, `die`, `usage_err`, `log`, and the `main` dispatcher with `case`; every `cmd_*` is a **stub** printing its name.
3. Test: `./seckit.sh help`, `./seckit.sh nonsense` (exit 64), `./seckit.sh` (shows help).
✅ *Accept when:* all six subcommands dispatch, unknown commands are denied, `bash -n` and `shellcheck` are clean.

### Stage 2 · `triage` (chapters 6, 10, 21, 25, 32)
1. Parse `-o DIR` with `getopts` (silent mode), reject extra arguments.
2. Default path with hostname and UTC time; refuse existing paths and symlinks.
3. Write all sections with one `{ ...; } > file` group; add a checksum file.
✅ *Accept when:* running twice with the same `-o` fails safely; `sha256sum -c triage.txt.sha256` passes inside the directory; file mode is `600`.

### Stage 3 · `audit` (chapters 9, 17, 27)
1. Implement `pass/fail/skip` helpers and a `mode_of` helper that works with GNU and BSD `stat`.
2. Implement the seven checks. Each must **SKIP** (not crash) when its file doesn't exist.
3. Exit 3 if any failure.
✅ *Accept when:* on a clean lab VM you get PASS/SKIP only; after you deliberately create a failure (e.g. `chmod 666 /etc/testfile` on a **lab VM**) the audit reports exactly that check and exits 3.

### Stage 4 · `logs` (chapters 19, 20, 29, 34, 35)
1. Generate the synthetic log from Checkpoint 3 (`gen_log.py`).
2. Use `[[ $line =~ $re ]]` with `BASH_REMATCH`, associative arrays, and a threshold check.
3. Validate `-t` as numeric and LOGFILE as readable.
✅ *Accept when:* it reports 647 failed logins on the Checkpoint 3 sample log; `-t 210` alerts for `203.0.113.50` and `198.51.100.23`; `-t 9999` exits 0; `-t abc` exits 64.

### Stage 5 · `backup` and `verify` (chapters 15, 18, 28, 36)
1. Resolve SRC with `cd ... && pwd -P`; reject `/` and a DEST inside SRC (clean up a directory you created).
2. `tar -czf ... -C parent -- name`, `gzip -t`, checksum file with relative names.
3. `verify`: checksum, readability, and the path-traversal check (`grep -E '(^/|(^|/)\.\.(/|$))'`).
✅ *Accept when:* backup → verify passes; flipping one byte of the archive makes `verify` fail (exit 3); an archive created with Python `arcname='../outside.txt'` fails the path check; a restore into an empty directory matches the source (`diff -r`).

### Stage 6 · Hardening review (chapters 28, 30, 32, 36)
Walk the security checklist below and fix every "no".

### Stage 7 · Packaging and cross-platform run (chapters 11, 14, 24)
1. Install for your user: `install -m 750 seckit.sh ~/bin/seckit` (or system-wide `sudo install -o root -g root -m 755 seckit.sh /usr/local/bin/seckit`).
2. Record `sha256sum seckit.sh > seckit.sh.sha256` and keep a copy off the machine.
3. Run it in at least **two** environments: e.g. your main distro and a container (`docker run --rm -it -v "$PWD":/w -w /w rockylinux:9 bash` or `debian:12`, `alpine` with `apk add bash`). Write down every difference.
4. Write a one-page `README.md` for the tool: purpose, install, examples, exit codes, limitations.

## Acceptance test script (run at the end)
Save as `test-seckit.sh` and make every line pass. This turns your tool into something you can *prove* works.
```bash
#!/usr/bin/env bash
# test-seckit.sh - minimal acceptance tests (run from the capstone directory)
S=./seckit.sh; T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; fails=0
check() { local want="$1" desc="$2"; shift 2; "$@" >/dev/null 2>&1; local got=$?
  if [ "$got" -eq "$want" ]; then echo "ok   $desc"; else echo "FAIL $desc (got $got, want $want)"; fails=$((fails+1)); fi; }

python3 gen_log.py >/dev/null 2>&1 && mv auth-sample.log "$T/log"
mkdir -p "$T/src/sub"; echo data > "$T/src/a.txt"; echo more > "$T/src/sub/b c.txt"
echo x > "$T/f"; python3 -c "import tarfile; t=tarfile.open('$T/evil.tar.gz','w:gz'); t.add('$T/f', arcname='../x'); t.close()"

check 0  "help"                      $S help
check 64 "unknown command"           $S nonsense
check 0  "triage new dir"            $S triage -o "$T/t1"
check 1  "triage refuses reuse"      $S triage -o "$T/t1"
check 64 "triage bad option"         $S triage -z
check 0  "audit runs (0 or 3 ok)"    bash -c "$S audit; [ \$? -eq 0 ] || [ \$? -eq 3 ]"
check 3  "logs alerts"               $S logs -t 210 "$T/log"
check 0  "logs clean"                $S logs -t 9999 "$T/log"
check 64 "logs bad threshold"        $S logs -t abc "$T/log"
check 0  "backup"                    $S backup "$T/src" "$T/bk"
check 1  "backup inside source"      $S backup "$T/src" "$T/src/in"
A=$(ls "$T"/bk/*.tar.gz 2>/dev/null | head -1)
check 0  "verify good archive"       $S verify "$A"
check 3  "verify traversal archive"  $S verify "$T/evil.tar.gz"
printf 'x' >> "$A"
check 3  "verify tampered archive"   $S verify "$A"
echo "failures: $fails"; [ "$fails" -eq 0 ]
```
Run it with `bash test-seckit.sh` (it expects `gen_log.py` and `seckit.sh` in the current directory).

## Security review checklist (fix every "no")
- [ ] Every variable expansion is quoted; every glob is controlled
- [ ] No `eval`, no `sh -c` with spliced strings, no unvalidated input in commands
- [ ] `--` precedes untrusted filenames/values where the tool supports it
- [ ] Numeric input is validated **before** arithmetic; leading zeros handled (`10#`)
- [ ] Output files/directories are created with `umask 077`, never overwrite, never follow symlinks
- [ ] Temp files (if any) come from `mktemp` with a cleanup `trap`
- [ ] No secrets in arguments, logs, or traces
- [ ] The script exits **non-zero on failure** and distinct codes mean distinct things
- [ ] `set -x` is never left on; shellcheck warnings are fixed or consciously justified in comments
- [ ] The installed script and its directory are **not writable by others**
- [ ] The tool declares its limits honestly (README), e.g. "heuristic checks, not a full compliance scanner"

## Stretch goals
- Add `seckit.sh baseline DIR` and `seckit.sh drift DIR BASELINE` using hashes and `diff <( ) <( )` (chapter 36)
- Add `--json` output for `audit` and `logs` (careful with escaping untrusted strings!)
- Add detection for **success-after-failures** (same IP in both failed and accepted events) to `logs`
- Add an `audit` check for firewall status (`ufw status`, `firewall-cmd --state`, `nft list ruleset`) with SKIP when unavailable
- Add RHEL-family support to `logs` by auto-detecting `/var/log/secure`, and `journalctl -u sshd` input via `-` for stdin
- Install a systemd timer or cron entry that runs `audit` daily and mails/logs failures (run as an unprivileged user where possible)
- Re-implement the log analysis in Python and compare readability, speed, and safety (a natural next step)

## Self-scoring (100 pts)
| Area | Points |
|---|---|
| Correctness: all acceptance tests pass | 30 |
| Security review checklist completed | 20 |
| Structure: functions, `main`, naming, comments | 15 |
| Robustness: validation, error handling, exit codes | 15 |
| Portability and documentation (README, tested on 2 environments) | 10 |
| Reflection and stretch goals | 10 |

**≥ 85:** you've reached the course goal. Move on to the career path in `../next-steps-cyber-career-path.md` · **70–84:** fix the weak stage and re-test · **< 70:** revisit the chapters named in the stages above.

## Reflection (write in your journal)
1. Which chapter helped you most while building this? Which command do you now type without thinking?
2. What was the most dangerous mistake you almost made, and which habit (quoting, `--`, `${var:?}`, dry-run, tests) caught it?
3. What would an attacker try against your tool, and how does it defend?
4. What will you automate next in your own environment?

🎉 **If you finished this, you didn't just read a book. You built, tested, and hardened real tooling.**
