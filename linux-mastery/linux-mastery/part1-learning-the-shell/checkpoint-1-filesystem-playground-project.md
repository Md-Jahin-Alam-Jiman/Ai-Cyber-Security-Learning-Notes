# Checkpoint 1 · File-System Playground & Host Triage Project
🎯 Covers chapters 1–10 · ⏱ ~2–3 hours · Do this **after** Chapter 10

## Scenario
You are a junior analyst. A colleague hands you a Linux workstation and says: *"Set up a case folder, collect basic host information, check for risky permissions, and write a report."* You'll use only what you learned in Part 1. No scripting yet.

## Rules
- Work only in `~/linux-lab/checkpoint1`
- Type every command, no copy-paste
- Quote variables and `ls` before you `rm`
- Time-box yourself; use `man` before asking for help

## Stage 1 · Build the case structure (chapters 2, 4, 7)
1. Create the tree with a **single** command using brace expansion:
   `case-001/{evidence,notes,reports,tools}` and `case-001/evidence/{logs,configs,listings}`.
2. Verify with `tree case-001` (or `find case-001`).
3. Create `notes/journal.md` and `notes/README.md` with `touch`.

## Stage 2 · Collect host facts (chapters 1, 3, 6)
Append each command's output to `reports/triage-report.txt` with a heading, using `echo "== TITLE ==" >> file` then `command >> file`:
- Date in UTC (`date -u`) and local
- `whoami`, `id`, `hostname`, `uname -a`, `cat /etc/os-release`
- `uptime`, `df -h`, `free -h`
- Last 10 logins: `last | head`
- Home directory listing: `ls -la ~`
- Newest 10 changes under `/etc`: `ls -lt /etc | head`

## Stage 3 · Evidence handling (chapter 4)
1. Copy `/etc/passwd`, `/etc/group`, `/etc/hostname`, `/etc/os-release` into `evidence/configs/` with `cp -a`.
2. Hash originals and copies; save to `evidence/configs/hashes.sha256`: `sha256sum /etc/passwd evidence/configs/passwd >> ...`
3. Compare hashes. Do they match?
4. Make evidence read-only: `chmod 440` on the copies, and `chmod 750` on the directories.

## Stage 4 · Permission audit (chapter 9)
Save to `evidence/listings/`:
1. `find /usr/bin /usr/sbin /bin -perm -4000 -type f 2>/dev/null > setuid.txt`
2. `find /tmp /var/tmp -type f -perm -0002 2>/dev/null > world-writable.txt`
3. `ls -l /etc/passwd /etc/shadow /etc/sudoers > key-file-perms.txt 2>&1`
4. `sudo -l > sudo-rights.txt`
5. Count lines in each file with `wc -l`. Add the counts to the report.

## Stage 5 · Process & network triage (chapter 10)
Save to `evidence/listings/`:
1. `ps auxf > processes.txt`
2. `sudo ss -tulpn > listening-ports.txt` (or `netstat -tulpn`)
3. Top 10 memory users: `ps aux --sort=-%mem | head -11 > top-mem.txt`
4. Start `sleep 900 &`, find it with `ps`, inspect `/proc/PID/cmdline`, then kill it politely (SIGTERM). Record in `notes/journal.md`.

## Stage 6 · Log hunt (chapter 6)
1. Count failed SSH logins and successful ones (auth log for your distro). Save counts.
2. Save the 20 most recent auth-related lines to `evidence/logs/auth-tail.txt`.
3. Note in the journal: is the log empty or unusually short? Why might that matter?

## Stage 7 · Tools & aliases (chapter 5, 8)
1. In `tools/`, create a symlink `latest-report` pointing to `../reports/triage-report.txt`.
2. Create temporary aliases: `ll='ls -lAh'` and `cases='cd ~/linux-lab/checkpoint1/case-001'`.
3. Use `Ctrl+R` to recall one of your earlier `find` commands instead of retyping it.

## Stage 8 · Write the findings (chapter 1–10)
In `reports/triage-report.txt` (use `cat >> file` then type, `Ctrl+D` to end) add a **Findings** section answering:
1. Which setuid programs did you find? Any you don't recognize?
2. Are `/etc/shadow` permissions correct? Why?
3. Which ports are listening, and which process owns each?
4. Any suspicious processes or `/tmp` files?
5. Three recommendations to harden this machine.

## Verification checklist
Run these and confirm each succeeds:
```bash
cd ~/linux-lab/checkpoint1
tree case-001 | head -30
wc -l case-001/reports/triage-report.txt
ls -l case-001/evidence/configs
sha256sum -c case-001/evidence/configs/hashes.sha256 2>&1 | head   # optional, if you used relative paths
ls -l case-001/tools/latest-report
```
- [ ] Directory tree built with one command
- [ ] Report has at least 8 headed sections
- [ ] Evidence copies match originals by hash and are read-only
- [ ] Permission audit files exist and are non-empty (except if none found)
- [ ] You can explain every command you typed

## Self-scoring (100 pts)
| Area | Points |
|---|---|
| Structure and naming (brace expansion, tidy) | 15 |
| Redirection and pipelines used correctly | 20 |
| Evidence handling and hashes | 15 |
| Permission audit | 20 |
| Process/network triage | 15 |
| Findings quality and clarity | 15 |

**≥ 85:** move on · **70–84:** redo the weak stage · **< 70:** revisit the matching chapters.

## Stretch goals
- Redo the whole project from memory in 30 minutes
- Repeat on a second distro (VM or container): `docker run -it rockylinux:9 bash` or `alpine`. Note which commands differ
- Compare a fresh install's setuid list with a colleague's

## Reflection (journal)
What was hardest? Which command would you automate first? (Part 4 will teach you how.)

## Next → Part 2: `../part2-configuration-environment/11-the-environment.md`
