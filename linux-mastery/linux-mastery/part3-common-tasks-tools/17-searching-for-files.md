# Chapter 17 · Searching for Files
📖 Book: Part III, pp. 197–212 · ⏱ ~100 min · Prereq: Chapter 16 · **Core investigation skill**

## Learning goals
- Find files fast with `locate` and precisely with `find`
- Combine tests and operators; run actions on results
- Use `xargs` safely with odd filenames
- Hunt for suspicious files like an analyst

## 1. `locate` (fast, database-based)
| Command | Notes |
|---|---|
| `locate bin/zip` | Searches a prebuilt index |
| `locate -i name` | Ignore case |
| `sudo updatedb` | Refresh index (usually daily via cron/timer) |
Install: Debian `plocate`, RHEL `plocate` (or `mlocate`), Arch `plocate`, Alpine `plocate`/`mlocate`, macOS `locate` (index builds weekly) or `mdfind name` (Spotlight).
⚠️ The index can be stale: new files are missing, deleted ones still appear. Use `find` for live truth.

## 2. `find`: syntax
`find <where> <tests> <actions>`
| Test | Meaning |
|---|---|
| `-name 'pat'` / `-iname` | Name match (quote the pattern!) |
| `-type f/d/l` | File / directory / symlink |
| `-size +10M` / `-size -1k` | Larger / smaller (`c` bytes, `k`, `M`, `G`) |
| `-mtime -2` / `+30` / `0` | Modified within 2 days / over 30 days ago / today |
| `-mmin -60` | Modified in last 60 minutes |
| `-atime`, `-ctime` | Access / metadata-change time |
| `-newer ref` | Modified after `ref` |
| `-user u`, `-group g` | Owner / group |
| `-nouser`, `-nogroup` | Owner no longer exists (suspicious) |
| `-perm 644` / `-perm -4000` / `-perm /022` | Exactly / all of these bits / any of these bits |
| `-empty` | Empty files/dirs |
| `-maxdepth N`, `-xdev` | Limit depth / stay on one file system |

Operators: `-and` (default), `-or`, `-not` / `!`, grouping `\( ... \)`.
Actions: `-print` (default), `-ls`, `-delete`, `-exec cmd {} \;` (one run per file), `-exec cmd {} +` (batched), `-ok` (asks).
GNU only: `-printf '%p %u %m %TY-%Tm-%Td\n'`. BSD/macOS `find` lacks `-printf`; use `-exec stat -f '...'`; BusyBox/Alpine has fewer features (`apk add findutils` for GNU find).

## 3. `xargs`
```bash
find . -name '*.log' -print0 | xargs -0 ls -l        # safe for spaces/newlines
find . -type f -print0 | xargs -0 -n 50 sha256sum
```
Always pair `-print0` with `xargs -0`. Use `xargs -r` (GNU) to avoid running with empty input.

## 4. Guided walkthrough
```bash
cd ~/linux-lab && mkdir -p ft && cd ft
mkdir -p a/b c && touch a/x.txt a/b/y.log c/z.txt "my file.txt"
find . -type f
find . -name '*.txt'
find . -type f \( -name '*.txt' -o -name '*.log' \)
find . -not -name '*.txt' -type f
find . -type f -name '*.txt' -exec ls -l {} \;
find . -type f -name '*.txt' -exec ls -l {} +
find . -name '*.txt' -print0 | xargs -0 wc -c
find ~ -maxdepth 2 -type f -mtime -1 2>/dev/null
touch -d '2020-01-01' old.txt ; find . -newer old.txt
```
Verify before deleting: run with `-print` first, then replace with `-delete`.

## 5. 🔐 Cyber relevance
**Post-compromise / threat-hunting queries** (use `sudo`, `-xdev`, redirect errors with `2>/dev/null`):
```bash
# Files changed recently (last 2 days)
sudo find / -xdev -type f -mtime -2 -not -path '/proc/*' -not -path '/var/log/*' 2>/dev/null | head -100
# Metadata changes (harder to forge than mtime)
sudo find /etc /usr/bin /usr/sbin -xdev -ctime -7 2>/dev/null
# Privilege-escalation candidates
sudo find / -xdev -perm -4000 -type f 2>/dev/null                 # setuid
sudo find / -xdev -perm -2000 -type f 2>/dev/null                 # setgid
sudo find / -xdev -type f -perm -0002 2>/dev/null                 # world-writable files
sudo find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null   # world-writable dirs w/o sticky
# Orphaned or hidden items
sudo find / -xdev \( -nouser -o -nogroup \) 2>/dev/null
find /tmp /var/tmp /dev/shm -type f -name '.*' 2>/dev/null        # hidden files in temp dirs
# Executables where they shouldn't be
find /tmp /var/tmp /dev/shm -type f -perm /111 2>/dev/null
find /tmp /var/tmp /dev/shm -type f -exec file {} + 2>/dev/null | grep -Ei 'ELF|script'
# Large files (data staging)
sudo find / -xdev -type f -size +500M 2>/dev/null
# Hashing a set of binaries to build a baseline
sudo find /usr/bin /usr/sbin -type f -print0 | sort -z | xargs -0 sha256sum > ~/linux-lab/bin-baseline.sha256
# Hunting for secrets (authorized scopes only)
grep -rIl --exclude-dir={proc,sys,dev} -iE 'password|secret|api[_-]?key' /etc ~ 2>/dev/null
find / -xdev -name 'id_rsa' -o -name 'id_ed25519' -o -name '*.pem' -o -name '.env' 2>/dev/null
```
**Cautions**
- **Timestamps can be forged** (`touch -d`); `ctime` can't be changed by normal tools but a root attacker with a clock change or direct disk edits can still interfere. Combine multiple signals.
- `-delete` and `-exec rm` are irreversible; test with `-print` first and put `-delete` **last**.
- Searching `/proc` and network mounts is slow or noisy; use `-xdev` and prune: `-path /proc -prune -o ...`.
- A rootkit can hide files from `find`/`ls`. If results look "too clean," compare with an offline image or a trusted live tool (and chapter 15's disk imaging).
- **Timeline building:** `find / -xdev -printf '%T@ %Tc %u %p\n' | sort -n | tail -50` (GNU) gives a quick "what changed last" list.
- **Weekly cron or systemd job idea:** run the setuid/world-writable queries, store output with a date, and `diff` against the previous week (we'll script this in Part 4).

## 6. Labs
**Easy**
1. Find all `.conf` files under `/etc` (use `sudo` or `2>/dev/null`).
2. Find files in your home larger than 10 MB.
3. Find directories named `bin` under `/usr`.

**Medium**
4. Find files modified in the last 60 minutes in `~/linux-lab`.
5. List all `.txt` files and print their size and owner using `-exec ls -l {} +`.
6. Create files with spaces in their names; process them safely with `find -print0 | xargs -0`.

**Hard (cyber)**
7. Run the setuid and world-writable queries and save the results with date: `... > ~/linux-lab/suid-$(date +%F).txt`.
8. Plant a test "payload": `cp /bin/ls /tmp/.hidden-tool`; detect it with at least two different `find` commands (hidden name, executable in `/tmp`). Remove it.
9. Build a baseline hash list of `/usr/bin`, modify one *copy* of a binary, then compare with `sha256sum -c`.
10. Create a timeline of the 20 most recently changed files in `/etc` and `/var/log`; explain one entry.

## 7. Common mistakes
- Forgetting quotes: `find . -name *.txt` lets the shell expand `*` first
- Putting `-maxdepth` after other tests (warning)
- `-exec ... {} \;` without escaping the semicolon
- Using `-delete` before testing
- Trusting a stale `locate` database

## 8. Quiz
1. `locate` vs `find`?
2. How do you find setuid files?
3. Why `-print0` with `xargs -0`?
4. `-mtime -2` means what?
5. Which time is hardest to forge: atime, mtime, or ctime?

<details><summary>Answers</summary>

1. `locate` uses a pre-built index (fast, can be stale); `find` walks the file system live.
2. `find / -xdev -perm -4000 -type f 2>/dev/null`.
3. Handles filenames containing spaces/newlines safely.
4. Modified less than 2 days (48 hours) ago.
5. ctime (metadata change time), though not tamper-proof against root.
</details>

## 9. Mastery checklist
- [ ] I combine tests with `-and/-or/-not` and parentheses
- [ ] I use `-exec` and `xargs -0` safely
- [ ] I can run a standard "what's suspicious" sweep
- [ ] I always dry-run before deleting

## Next → `18-archiving-and-backup.md`
