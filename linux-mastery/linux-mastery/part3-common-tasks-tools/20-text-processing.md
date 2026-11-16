# Chapter 20 · Text Processing
📖 Book: Part III, pp. 245–274 · ⏱ ~150 min · Prereq: Chapter 19 · **The log-analysis toolbox**

## Learning goals
- Slice, sort, join and compare text with `cut`, `sort`, `uniq`, `paste`, `join`, `comm`, `diff`, `tr`
- Edit streams with `sed`
- Use `awk` for field-based reports (an essential extra beyond the book)
- Turn raw logs into answers

## 1. Tool table
| Tool | Purpose | Key options |
|---|---|---|
| `cat -A` / `cat -n` | Show hidden characters / number lines | `-A` shows `$` at EOL, `^I` tabs |
| `sort` | Sort | `-n` numeric · `-r` · `-u` · `-k2,2` by field · `-t:` delimiter · `-h` human sizes · `-f` fold case |
| `uniq` | Dedupe adjacent | `-c` count · `-d` dupes · `-u` unique |
| `cut` | Select columns | `-d, -f1,3` fields · `-c1-5` chars |
| `paste` | Merge files side by side | `-d,` |
| `join` | Join sorted files on a field | `-1 f -2 f` |
| `comm` | Compare sorted files | `-12` common · `-23` only in file 1 |
| `diff` | Differences | `-u` unified · `-r` recursive · `-q` brief |
| `patch` | Apply a diff | `-p1 < fix.diff` |
| `tr` | Translate/delete chars | `tr a-z A-Z` · `-d '\r'` · `-s ' '` |
| `sed` | Stream editor | `s/a/b/g` · `-n '5,10p'` · `/re/d` · `-i` in-place · `-E` |
| `awk` | Fields + logic | `-F:` · `'{print $1}'` · `'$3>100'` · `END{}` |
| `wc`, `head`, `tail`, `tee` | (chapter 6) | |
| `aspell` | Spell check | `aspell check file` |

Platform: macOS `sed -i ''` needs an empty suffix (`sed -i '' 's/a/b/' f`); `sort` on macOS lacks `-h` in older versions. BSD `cut`, `tr` are fine for basics. Alpine: BusyBox awk/sed lack some GNU features; `apk add gawk sed coreutils` for full versions.

## 2. Walkthrough: build a sample log
```bash
cd ~/linux-lab && mkdir -p tp && cd tp
cat > auth.log <<'EOT'
Nov 10 02:11:01 lab sshd[101]: Failed password for invalid user admin from 203.0.113.5 port 4001 ssh2
Nov 10 02:11:05 lab sshd[102]: Failed password for root from 203.0.113.5 port 4002 ssh2
Nov 10 02:12:10 lab sshd[103]: Failed password for invalid user test from 198.51.100.23 port 5001 ssh2
Nov 10 02:13:44 lab sshd[104]: Accepted publickey for alice from 192.0.2.10 port 6001 ssh2
Nov 10 02:14:00 lab sshd[105]: Failed password for root from 203.0.113.5 port 4003 ssh2
Nov 10 02:15:30 lab sshd[106]: Accepted password for bob from 203.0.113.5 port 4004 ssh2
Nov 10 02:16:00 lab sudo:      bob : TTY=pts/0 ; PWD=/home/bob ; USER=root ; COMMAND=/bin/bash
EOT
```
**cut / sort / uniq / tr / sed / awk**
```bash
cut -d' ' -f1,2,3 auth.log                                  # timestamps
grep 'Failed' auth.log | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -nr
grep 'Failed password' auth.log | sed -E 's/.*for (invalid user )?([^ ]+) from.*/\2/' | sort | uniq -c | sort -nr
awk '/Failed password/ {print $(NF-3)}' auth.log | sort | uniq -c | sort -nr    # IP is 4th from the end
awk '{print $5}' auth.log | sort | uniq -c                  # which service/process
awk -F: '$3 == 0 {print $1}' /etc/passwd                    # all UID-0 accounts
awk '{c[$1" "$2]++} END {for (k in c) print c[k], k}' auth.log | sort -k1,1nr
sed -n '2,4p' auth.log                                      # lines 2–4
sed 's/203\.0\.113\.5/[REDACTED]/g' auth.log                # redact
sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/\1[.]\2[.]\3[.]\4/g' auth.log   # defang IPs
tr 'a-z' 'A-Z' < auth.log | head -2
tr -d '\r' < windows.txt > unix.txt                         # CRLF → LF
```
**Compare and diff**
```bash
printf '203.0.113.5\n198.51.100.23\n' | sort > blocklist.txt
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' auth.log | sort -u > seen.txt
comm -12 blocklist.txt seen.txt        # in both
comm -13 blocklist.txt seen.txt        # seen but not on blocklist
cp /etc/hostname h1; echo extra >> h1; diff -u /etc/hostname h1
```

## 3. 🔐 Cyber relevance
- **Brute-force triage in 30 seconds:**
  ```bash
  grep 'Failed password' /var/log/auth.log | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -nr | head
  ```
  (RHEL: `/var/log/secure`; systemd: `journalctl -u ssh --no-pager | ...`; macOS: `log show`.)
- **Compromise pattern: failures followed by a success from the same IP.** Compare the IPs of `Failed` vs `Accepted` lines with `comm -12 <(grep Failed log | ... | sort -u) <(grep Accepted log | ... | sort -u)` (process substitution works in bash/zsh, not plain `sh`). This is the classic "they guessed it" signal.
- **Baseline vs. now (drift detection):** `diff -u baseline-suid.txt suid-today.txt`; `diff -u <(sudo sha256sum /usr/bin/* 2>/dev/null) baseline.sha256`. New or changed entries deserve investigation.
- **IOC matching:** `grep -Fwf iocs.txt logfile` (fixed strings, whole words, patterns from file) or `comm` for sorted IOC lists.
- **Quick decoding:** `echo 'cGFzcw==' | base64 -d`; `tr 'A-Za-z' 'N-ZA-Mn-za-m'` (ROT13); `xxd -r -p` for hex. Analyze unknown strings with care; never pipe decoded text into a shell.
- **Defang IOCs in reports** (`1[.]2[.]3[.]4`, `hxxp://`) so nobody clicks live links: use the `sed` example above.
- **Sanitize before sharing:** `sed` to redact usernames/IPs; double-check with `grep` that nothing remains.
- **Time zones and formats:** normalize timestamps (`date -u`) before sorting across systems; `sort -k1,3M` sorts month names in syslog lines.
- **Dangers:** `sed -i` rewrites files in place: use a backup suffix (`-i.bak`) or test without `-i` first. `patch` from an untrusted source can modify anything under its paths: read the diff (`diff` headers, `--dry-run`) before applying. `awk` and `sed` can execute commands (`system()`, `e` flag) in untrusted scripts, so don't run scripts you haven't read.
- **JSON logs?** Use `jq` (`jq -r '.src_ip' log.json | sort | uniq -c | sort -nr`). Install: `apt/dnf/pacman/apk/brew install jq`.

## 4. Labs (use the `auth.log` from the walkthrough)
**Easy**
1. Print only the first 3 fields of every line.
2. Sort the lines by IP address count (use the pipeline above) and show the top attacker.
3. Convert the log to upper case and back with `tr`.

**Medium**
4. Count failed logins per **username** (including the `invalid user` ones).
5. Using `sed`, print lines 3–5, delete lines containing `sudo`, and replace `ssh2` with `SSH-v2`.
6. Create two small sorted files and use `comm` to show items unique to each.

**Hard (cyber)**
7. Find IPs that appear in **both** `Failed password` and `Accepted` lines. Explain the finding as if writing an incident note.
8. Make a "defanged" copy of the log and verify with `grep -E '([0-9]+\.){3}[0-9]+'` that no raw IPs remain.
9. Write a baseline of `/etc/passwd` and `/etc/group` hashes, change a *copy*, and use `diff -u` to show the difference.
10. Build a top-10 table with `awk`: for each IP, number of failures and number of successes: `awk '/Failed/ {f[$(NF-3)]++} /Accepted/ {s[$(NF-3)]++} END {for (i in f) print i, f[i], s[i]+0}' auth.log`.

## 5. Common mistakes
- `uniq` without `sort`
- Text vs numeric sort (`sort` vs `sort -n`)
- Hardcoding field numbers when lines have variable-length fields (use anchors/regex or `$(NF-n)`)
- `sed -i` without a backup
- Ignoring CRLF line endings from Windows files (`cat -A` reveals `^M`)

## 6. Quiz
1. Which command removes `\r` characters?
2. What does `comm -12 a b` show?
3. Why sort before `comm` or `uniq`?
4. What's the risk of `sed -i`?
5. How do you print the 4th-to-last field with awk?
6. Why defang IOCs in reports?

<details><summary>Answers</summary>

1. `tr -d '\r'`.
2. Lines common to both sorted files.
3. They compare adjacent/ordered lines only.
4. It edits the file in place; mistakes are permanent unless you keep a backup (`-i.bak`).
5. `awk '{print $(NF-3)}'`.
6. So no one accidentally clicks or resolves a malicious indicator.
</details>

## 7. Mastery checklist
- [ ] I can turn a raw log into a ranked list (top IPs/users) with one pipeline
- [ ] I use `sed` and `awk` for extraction and redaction
- [ ] I compare files and sets with `diff` and `comm`
- [ ] I handle untrusted scripts and patches carefully

## Next → `21-formatting-output.md`
