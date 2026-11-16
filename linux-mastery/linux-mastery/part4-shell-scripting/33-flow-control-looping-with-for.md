# Chapter 33 · Flow Control: Looping with `for`
📖 Book: Part IV, pp. 439–446 · ⏱ ~90 min · Prereq: Chapter 32

## Learning goals
- Loop over lists, globs, ranges, and arguments
- Use C-style `for` loops
- Process files safely (spaces, dashes, empty matches)
- Build bulk-hashing, user-audit, and port-checking tools

## 1. Forms
```bash
for x in one two three; do echo "$x"; done          # word list
for f in *.txt; do echo "$f"; done                   # glob (files)
for n in {1..5}; do echo "$n"; done                  # brace range (bash/zsh)
for n in $(seq 1 5); do echo "$n"; done              # seq (portable, GNU/BSD)
for ((i = 0; i < 5; i++)); do echo "$i"; done        # C-style (bash)
for arg in "$@"; do echo "$arg"; done                # every argument (also: for arg; do ...)
```
| Tip | Why |
|---|---|
| `"$f"` always quoted | Names with spaces/globs |
| `for f in ./*` or `-- "$f"` | Names beginning with `-` |
| `shopt -s nullglob` | An unmatched glob expands to nothing (otherwise the literal `*.txt`) |
| `shopt -s dotglob` | Include hidden files in `*` |
| `[ -e "$f" ] \|\| continue` | Guard against a literal unmatched glob |
| `break` / `continue` | Leave / skip |
| Don't `for f in $(ls)` or `$(cat file)` | Word splitting breaks names/lines |

Use `for` for lists you *already have*; use `while read` for lines of a file or command output.

## 2. Bulk rename (preview of parameter expansion, chapter 34)
```bash
for f in *.txt; do
  [ -e "$f" ] || continue
  mv -n -- "$f" "${f%.txt}.bak"        # %.txt strips the suffix; -n = never overwrite
done
```

## 3. Project A: `hash-dir.sh`, build an integrity baseline
```bash
#!/usr/bin/env bash
# hash-dir.sh - SHA-256 of every regular file in a directory (non-recursive)
# Usage: ./hash-dir.sh DIR > baseline.sha256     (macOS: replace sha256sum with 'shasum -a 256')
dir="${1:?usage: hash-dir.sh DIR}"
[ -d "$dir" ] || { echo "not a directory: $dir" >&2; exit 2; }
shopt -s nullglob dotglob
for f in "$dir"/*; do
  [ -f "$f" ] && [ ! -L "$f" ] || continue          # regular files only, skip symlinks
  sha256sum -- "$f"
done
```
Verify later: `sha256sum -c baseline.sha256` (prints OK / FAILED per file). For recursive trees use `find DIR -type f -print0 | xargs -0 sha256sum`.

## 4. Project B: `user-audit.sh`, who can log in?
```bash
#!/usr/bin/env bash
# user-audit.sh - interesting accounts from /etc/passwd (chapter 33)
printf '%-16s %-6s %-26s %s\n' USER UID HOME SHELL
while IFS=: read -r user _ uid _ _ home shell; do
  if [[ $uid == 0 || ( $uid -ge 1000 && $uid -lt 65534 ) ]]; then
    printf '%-16s %-6s %-26s %s\n' "$user" "$uid" "$home" "$shell"
  fi
done < /etc/passwd

echo
echo "UID-0 accounts besides root:"
awk -F: '$3 == 0 && $1 != "root" {print "  " $1}' /etc/passwd
echo "Accounts with an empty password field in /etc/passwd:"
awk -F: '$2 == "" {print "  " $1}' /etc/passwd
```
(On macOS, users live in the directory service: `dscl . list /Users UniqueID`.)

## 5. Project C: `port-check.sh`, test TCP ports **on hosts you own**
```bash
#!/usr/bin/env bash
# port-check.sh - which TCP ports accept connections (bash /dev/tcp)
# Usage: ./port-check.sh [HOST] [PORT...]      Only use on systems you are authorized to test!
host="${1:-127.0.0.1}"; [ $# -gt 0 ] && shift
[[ $host =~ ^[A-Za-z0-9.-]+$ ]] || { echo "invalid host" >&2; exit 2; }
ports="${*:-22 80 443 8080}"

for p in $ports; do                                   # $ports is split on purpose
  [[ $p =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 65535 )) || { echo "skip invalid port: $p" >&2; continue; }
  # pass host/port as ARGUMENTS to bash -c (never splice them into the command string)
  if timeout 1 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$p" 2>/dev/null; then
    printf '%-6s open\n' "$p"
  else
    printf '%-6s closed/filtered\n' "$p"
  fi
done
```
`timeout` is GNU coreutils (macOS: `brew install coreutils` → `gtimeout`). Safe test:
`python3 -m http.server 8099 --bind 127.0.0.1 &` then `./port-check.sh 127.0.0.1 22 8099`; stop with `kill %1`.

## 6. Parallelism and rate control
```bash
for h in host1 host2 host3; do ( check "$h" ) & done; wait        # simple parallel
printf '%s\n' "${list[@]}" | xargs -P 4 -I{} ./check.sh {}        # up to 4 at a time
```
Limit concurrency and add delays so you don't overload hosts, networks, or yourself.

## 7. 🔐 Cyber relevance
- **Authorization first:** port, host, and credential checks are only legitimate against systems you own or have written permission to test. Keep scope files (`scope.txt`) and loop only over them: `while read -r h; do ...; done < scope.txt`.
- **Defensive uses of `for`:** baseline hashing (above), checking every user's `~/.ssh/authorized_keys` and permissions, auditing every cron directory, validating configs across a fleet, rotating logs, bulk IOC lookups against a blocklist.
- **Filename hostility:** attackers create names like `-rf`, `; id`, `$(x)`, newlines, or very long names to break careless loops. Quoting, `--`, `./*`, and `-print0` are your defense. Test every loop with a "nasty names" directory (lab 6).
- **Unmatched-glob bug:** `for f in /tmp/evil-*; do rm "$f"; done` with no matches would try to delete a file literally named `/tmp/evil-*`. Use `nullglob` or `[ -e ]` guards.
- **Don't `for u in $(cut ...)` over security data** unless values can't contain whitespace; prefer `while IFS=: read -r ...` with redirection, which handles fields explicitly.
- **Scanning loops are noisy.** They show up in firewall logs and IDS alerts; sequential port loops generate many SYNs. Use proper tools (`nmap`) with agreed rates, and tell the SOC before authorized tests.
- **Brute-force loops (for defenders to recognize):** attackers wrap `ssh`, `curl`, or `su` in loops over wordlists. Your detections: bursts of failed logins, many connections per second, fixed intervals. Controls: key-only SSH, rate limiting, lockouts (`pam_faillock`), fail2ban, MFA, strong unique passwords. **Do not** write or run guessing loops against any system you don't own; in labs, practice only against your own throwaway VM.
- **Resource safety:** unbounded loops that spawn background jobs can exhaust PIDs/memory. Use `wait`, limits (`ulimit -u`), `xargs -P`, and `timeout`.
- **Hash baselines are only as trustworthy as where you store them.** Keep the baseline and the checking tool off the monitored host (read-only media, remote store) or an attacker will update both.

## 8. Labs
**Easy**
1. Loop over `apple banana cherry` and print each with its length (`${#x}` preview).
2. Print the numbers 1–10 with brace expansion, with `seq`, and with a C-style loop.
3. Loop over `*.txt` in a lab directory and print each name.

**Medium**
4. Rename all `*.txt` to `*.bak` with a `for` loop using `mv -n --`. Then reverse it.
5. Write `sizes.sh` that prints each regular file in a directory and its size (use `stat -c %s`, or `wc -c < "$f"` for portability).
6. Create a "nasty names" directory: `touch ./-rf 'a b' $'new\nline' '*' ';id'`. Run the unsafe loop `for f in $(ls); do echo "[$f]"; done` and the safe one `for f in ./*; do echo "[$f]"; done`. Compare.

**Hard (cyber)**
7. Build and run `hash-dir.sh` on `/usr/bin` copy (or a lab dir), then modify one file and detect it with `sha256sum -c`.
8. Run `user-audit.sh`. Add a check for accounts whose shell is not `nologin`/`false` and UID < 1000 (service accounts that can log in are a red flag).
9. Write `ssh-key-audit.sh`: for each home directory in `/home/*`, report whether `.ssh` exists, its mode (should be 700), and the mode of `authorized_keys` (should be 600 or 644), plus the number of keys in it.
10. Use `port-check.sh` against `127.0.0.1` with a local test server, then compare with `ss -tuln`. Explain the differences (listening vs reachable from elsewhere; firewall rules).

## 9. Common mistakes
- Looping over `$(ls)`
- Unquoted `$f`
- Forgetting `nullglob` and acting on the literal `*`
- Using `{1..$n}` (brace expansion happens before variable expansion; use `seq` or a C-style loop)
- Changing the list while looping over it

## 10. Quiz
1. Why is `for f in $(ls)` wrong?
2. What does `shopt -s nullglob` change?
3. How can you iterate over every argument?
4. Why use `./*` or `--` with untrusted names?
5. Why must scanning loops be authorized?

<details><summary>Answers</summary>

1. It splits on whitespace and globs, breaking names with spaces or special characters.
2. Unmatched globs expand to nothing instead of the literal pattern.
3. `for a in "$@"; do ...; done` (or `for a; do ...; done`).
4. Names beginning with `-` would otherwise be parsed as options.
5. Unauthorized scanning/probing may be illegal and disrupts systems.
</details>

## 11. Mastery checklist
- [ ] I choose the right `for` form and quote every expansion
- [ ] I process filenames safely (spaces, dashes, empty globs)
- [ ] I can build baseline, audit, and check tools with loops
- [ ] I restrict loops to authorized scope and limit their rate

## Next → Batch 3: `34-strings-and-numbers.md`
