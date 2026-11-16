# Checkpoint 3 · Log Analysis + Backup Project
🎯 Covers chapters 14–23 · ⏱ ~3–4 hours · Do this **after** Chapter 23

## Scenario
You're the on-call analyst for a small server. An alert says *"unusual SSH activity."* You must (1) analyze the authentication log, (2) find out whether an account was compromised, (3) sweep the host for follow-up signs, (4) package the evidence, (5) take a verified backup, and (6) deliver a formatted incident report. No scripting yet; use pipelines, `find`, `tar`, `rsync`, `sed`, `awk`, and `printf`.

## Setup
```bash
mkdir -p ~/linux-lab/checkpoint3/{raw,work,evidence,backup,report}
cd ~/linux-lab/checkpoint3
```
**Dataset:** use a synthetic log so everyone gets the same answers. Save as `gen_log.py`, run `python3 gen_log.py`, then `cp auth-sample.log raw/` (process substitution `<( )` needs bash or zsh, not plain `sh`) and make it read-only (`chmod 444 raw/auth-sample.log`).
```python
#!/usr/bin/env python3
import random, datetime
random.seed(42)
t = datetime.datetime(2026, 11, 10, 0, 0, 0)
attackers = ["203.0.113.5", "203.0.113.50", "198.51.100.23", "192.0.2.77"]
bad_users = ["admin", "root", "test", "oracle", "ubuntu", "postgres", "guest"]
legit = {"alice": "198.51.100.7", "bob": "192.0.2.10"}
ts = lambda x: x.strftime("%b %e %H:%M:%S")
port = lambda: random.randint(1024, 65000)
out = []
for _ in range(900):
    t += datetime.timedelta(seconds=random.randint(5, 240))
    r = random.random()
    pid = random.randint(1000, 32000)
    if r < 0.70:
        ip, u = random.choice(attackers[:3]), random.choice(bad_users)
        who = u if u == "root" else "invalid user " + u
        msg = f"Failed password for {who} from {ip} port {port()} ssh2"
    elif r < 0.90:
        u = random.choice(list(legit))
        msg = f"Accepted publickey for {u} from {legit[u]} port {port()} ssh2"
    else:
        msg = f"Invalid user {random.choice(bad_users)} from {random.choice(attackers)} port {port()}"
    out.append(f"{ts(t)} labhost sshd[{pid}]: {msg}")
t += datetime.timedelta(minutes=3)
out.append(f"{ts(t)} labhost sshd[4242]: Accepted password for bob from 203.0.113.50 port 51515 ssh2")
t += datetime.timedelta(seconds=40)
out.append(f"{ts(t)} labhost sudo:      bob : TTY=pts/0 ; PWD=/home/bob ; USER=root ; COMMAND=/usr/bin/tar czf /tmp/.x.tgz /etc")
open("auth-sample.log", "w").write("\n".join(out) + "\n")
print(len(out), "lines written")
```
You may also practice on your real `/var/log/auth.log` (or `/var/log/secure`), but the synthetic log has a planted compromise.

## Stage 1 · Integrity and first look (chapters 6, 18)
1. `sha256sum raw/auth-sample.log | tee evidence/auth-sample.log.sha256`
2. `wc -l`, `head`, `tail`; what time range does the log cover?
3. Work only on a copy in `work/`.

## Stage 2 · Analysis with pipelines (chapters 19, 20)
Save each result to `work/` and record the command you used.
1. **Top 10 attacking IPs** by failed login count.
2. **Top 10 usernames** targeted (including "invalid user" names).
3. **Failures per hour** (the log spans about two days, so group by date and hour: `awk '{print $1, $2, substr($3,1,2)}' | sort | uniq -c`).
4. **Successful logins**: user, IP, auth method.
5. **The key question:** which IP(s) appear in **both** failed and accepted lines? (`comm -12` on sorted unique IP lists.)
6. Find any `sudo` activity and the exact command run.
7. Extract all unique IPs to `work/ips.txt` and a **defanged** copy (`1[.]2[.]3[.]4`) to `report/ips-defanged.txt`.

## Stage 3 · Host sweep (chapters 9, 10, 16, 17)
Run on your lab host; save to `evidence/`:
1. Files changed in the last 2 days outside `/proc`, `/sys`, `/var/log`.
2. SUID/SGID files and world-writable files/directories.
3. Executable files in `/tmp`, `/var/tmp`, `/dev/shm`; hidden files there; any archive named like `.x.tgz` (the planted log mentions `/tmp/.x.tgz`; simulate it: `tar czf /tmp/.x.tgz /etc/hostname`, find it with `find`, **then** delete it).
4. Listening ports with processes (`ss -tulpn`) and current SSH sessions (`who`, `last | head`).
5. Package integrity check for the OS (chapter 14): `debsums -c` / `rpm -Va`.

## Stage 4 · Evidence packaging (chapters 15, 18)
1. Archive `evidence/` and `raw/` with metadata: `tar --numeric-owner -cpzf case-$(date -u +%F).tar.gz evidence raw` (use GNU tar; on macOS use `tar -czf`).
2. Create a SHA-256 manifest: `sha256sum case-*.tar.gz > case.manifest.sha256`
3. Encrypt a copy: `gpg --symmetric --cipher-algo AES256 case-*.tar.gz` (or `age -p`).
4. **List** the archive (`tar -tzf`) and test integrity (`gzip -t`).
5. Write 3 lines of **chain of custody**: who, what, when (UTC), where stored.

## Stage 5 · Backup and restore test (chapter 18)
1. `rsync -avhn --delete` dry-run, then a real `rsync -avh` of `~/linux-lab/checkpoint3/work` to `backup/`.
2. Change one file, rerun, and show only the delta was copied.
3. **Restore test:** extract the encrypted archive into an empty `restore/` directory and `diff -r` it with the original.
4. Write a short 3-2-1 plan (which copies, which media, which location, how often, who tests restores).

## Stage 6 · Compile a tool (chapter 23)
Compile a tiny C program `ipcount.c` that reads IPs line by line and prints how many it saw (or any other small utility). Build with hardening flags; run `file` and `readelf -d` on it. Keep the source, Makefile, and hash in `tools/`. *(Optional if short on time; it can be replaced by compiling GNU Hello into `$HOME/opt`.)*

## Stage 7 · The incident report (chapter 21)
Create `report/incident-report.txt` using `printf`, `column -t`, `fmt`, and `tee` (no word processor). It must contain:
1. **Header:** case ID, host, analyst, UTC time
2. **Summary (≤ 5 sentences):** what happened, was there a compromise, confidence level
3. **Timeline table:** time (UTC) | event | evidence source
4. **Top attacker table:** IP | failures | successes
5. **Findings:** compromised account, suspicious `sudo` command, likely data staged in `/tmp/.x.tgz`
6. **Indicators (defanged):** IPs, file paths, commands
7. **Recommendations:** at least 6 (e.g. disable password auth, rotate bob's credentials, block IPs, review `/etc` exfiltration, enable MFA, centralize logs, rate-limit with fail2ban, patch)
8. **Limitations:** what you could not determine

## Expected findings (check yourself after finishing)
- The planted compromise: **`bob` logs in with a password from `203.0.113.50`**, an IP that also appears in many failed attempts, followed 40 seconds later by `sudo tar czf /tmp/.x.tgz /etc` (collection/staging of configuration data).
- Legitimate users `alice` and `bob` normally use public keys from fixed IPs. A *password* login from a new IP is the anomaly.
- Exact counts depend on the generator; compute them from the data, don't guess.

## Verification checklist
- [ ] Hash of original log unchanged at the end (`sha256sum -c`)
- [ ] All analysis commands recorded in `work/commands.txt`
- [ ] `comm`-based IP overlap found `203.0.113.50`
- [ ] Archive lists cleanly, passes `gzip -t`, and the encrypted copy restores identically
- [ ] Report contains all 8 sections and defanged IOCs
- [ ] No evidence file was edited in place (check timestamps/permissions)

## Self-scoring (100 pts)
| Area | Points |
|---|---|
| Correct analysis (top IPs, users, overlap, sudo event) | 25 |
| Evidence integrity and chain of custody | 15 |
| Host sweep quality | 15 |
| Backup, encryption, verified restore | 15 |
| Report clarity and accuracy | 20 |
| Tooling and compile stage | 10 |

**≥ 85:** proceed to Part 4 · **70–84:** redo weak stages · **< 70:** revisit chapters 17–20 first.

## Stretch goals
- Redo the analysis with `journalctl -u ssh -o short-iso` on a real machine
- Write down which pipeline you'd automate first. In Part 4 you'll turn this entire project into a reusable shell script.
- Repeat on a RHEL-family container (`docker run -it rockylinux:9 bash`) and note differences in log paths and package tools

## Next → Part 4: `../part4-shell-scripting/24-writing-your-first-script.md`
