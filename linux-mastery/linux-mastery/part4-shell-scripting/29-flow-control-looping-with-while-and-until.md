# Chapter 29 · Flow Control: Looping with `while` and `until`
📖 Book: Part IV, pp. 393–400 · ⏱ ~90 min · Prereq: Chapter 28

## Learning goals
- Repeat actions with `while` and `until`; control loops with `break` and `continue`
- Read files line by line the **safe** way
- Avoid the pipeline-subshell trap
- Build a log monitor and a brute-force detector

## 1. Syntax
```bash
while COMMAND; do         # repeat while COMMAND succeeds (status 0)
  ...
done

until COMMAND; do         # repeat until COMMAND succeeds
  ...
done
```
| Keyword | Effect |
|---|---|
| `break` | Leave the loop |
| `continue` | Skip to the next iteration |
| `while true; do ...; done` | Infinite loop (leave with `break`/`exit`) |
| `(( i++ ))` / `i=$((i+1))` | Counters. (Beware: `(( i++ ))` returns status 1 when `i` was 0, which matters with `set -e`) |
| `sleep N` | Wait between iterations |

**Counting:**
```bash
i=1
while (( i <= 5 )); do echo "round $i"; i=$((i + 1)); done
```

## 2. Reading files line by line (the right way)
```bash
while IFS= read -r line; do
  printf 'line: %s\n' "$line"
done < /etc/hostname
```
- `IFS=` keeps leading/trailing whitespace; `-r` keeps backslashes.
- Split into fields: `while IFS=: read -r user _ uid _ _ home shell; do ... done < /etc/passwd`
- **Do not** loop over `$(cat file)` or `$(ls)`; that splits on whitespace and globs.

### The subshell trap
```bash
count=0; printf 'a\nb\n' | while read -r l; do count=$((count+1)); done; echo "$count"       # prints 0 !
count=0; while read -r l; do count=$((count+1)); done < <(printf 'a\nb\n'); echo "$count"  # prints 2
```
Each side of a pipe runs in a **subshell**; changes to variables vanish. Use redirection (`< file`) or process substitution (`< <(cmd)`, bash/zsh) so the loop runs in your shell.

## 3. Project A: looping menu (`menu-loop.sh`)
```bash
#!/usr/bin/env bash
# menu-loop.sh - menu that repeats until the user quits (chapter 29)
selection=
until [[ $selection == 0 ]]; do
  cat <<_EOF_

System information menu
  1) System information
  2) Disk space
  3) Recent logins
  0) Quit
_EOF_
  read -r -p "Enter selection [0-3]: " selection || break     # stop on end of input
  if [[ ! $selection =~ ^[0-3]$ ]]; then echo "Invalid entry." >&2; continue; fi
  if   [[ $selection == 1 ]]; then uname -a; uptime
  elif [[ $selection == 2 ]]; then df -h
  elif [[ $selection == 3 ]]; then last -n 5
  fi
done
echo "Bye."
```

## 4. Project B: brute-force detector (`brute-detect.sh`)
Works on the synthetic `auth-sample.log` from Checkpoint 3 or on your real auth log.
```bash
#!/usr/bin/env bash
# brute-detect.sh - flag IPs with many failed SSH logins (chapter 29)
# Usage: ./brute-detect.sh [LOGFILE] [THRESHOLD]   exit 0 = no alerts, 1 = alerts, 2 = error
LOG="${1:-auth-sample.log}"
THRESHOLD="${2:-10}"
[ -r "$LOG" ] || { echo "Cannot read $LOG" >&2; exit 2; }
[[ $THRESHOLD =~ ^[0-9]+$ ]] || { echo "Threshold must be a number" >&2; exit 2; }

alerts=0
while read -r count ip; do
  if (( count >= THRESHOLD )); then
    printf 'ALERT  %-16s %5d failures\n' "$ip" "$count"
    alerts=$((alerts + 1))
  fi
done < <(grep 'Failed password' "$LOG" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -nr)

echo "Alerts: $alerts"
[ "$alerts" -eq 0 ]
```

## 5. Project C: live log watcher (`watch-log.sh`)
```bash
#!/usr/bin/env bash
# watch-log.sh - print an alert for every new failed login (chapter 29)
LOG="${1:?usage: watch-log.sh LOGFILE}"
tail -Fn0 "$LOG" | while IFS= read -r line; do
  if [[ $line == *"Failed password"* ]]; then
    printf '[%s] ALERT: %s\n' "$(date -u +%T)" "$line"
  fi
done
```
Safe demo: `touch demo.log; ./watch-log.sh demo.log &` then `echo "Failed password for root from 203.0.113.5 port 22 ssh2" >> demo.log`, then `kill %1`.

## 6. Waiting patterns
```bash
# wait up to 30 s for a local service (bash /dev/tcp)
tries=0
until (exec 3<>/dev/tcp/127.0.0.1/8080) 2>/dev/null; do
  tries=$((tries + 1)); (( tries >= 30 )) && { echo "timeout" >&2; exit 1; }
  sleep 1
done
echo "service is up"
```
Always bound waiting loops (max tries or `timeout`) so automation can't hang forever.

## 7. 🔐 Cyber relevance
- **Detection engineering in miniature:** "count events per source, compare to a threshold, alert" is the core of fail2ban, SIEM rules, and EDR heuristics. `brute-detect.sh` is that pattern. Next steps: time windows, account-lockout correlation, allow-lists for trusted IPs, and output to syslog (`logger -p auth.warning`).
- **Real-time monitoring:** `tail -F | while read` is the base of lightweight log watchers; `-F` follows through log rotation (plain `-f` loses the file). For production, prefer `journalctl -f`, `auditd`, fail2ban, or a SIEM agent, but this teaches the mechanics.
- **Treat every log line as hostile input.** Attackers control usernames and other fields in logs. Don't `eval` them or put them unquoted into commands; print with `printf '%s'`, not `echo -e`; escape or sanitize before writing to HTML/CSV/syslog.
- **`while read` and stdin hijacking:** commands inside the loop that read stdin (`ssh`, `ffmpeg`, `mysql`) eat the rest of your input. Use `ssh -n`, or redirect `</dev/null` for those commands.
- **Rate limits and backoff** protect services and make your scripts less noisy (and less detectable): `sleep $((2 ** tries))`. Conversely, attackers use "low and slow" loops to stay below naive thresholds. Detect patterns over long windows too.
- **Lock files and overlap:** loops started from cron can overlap. Use `flock -n /var/lock/job.lock cmd` (Linux) or a `mkdir` lock to avoid two copies running.
- **Resource exhaustion:** unbounded loops that spawn processes can take down a host. Limit with `ulimit -u`, systemd resource controls, and `timeout`. Watch for runaway shells with `ps`/`top`.
- **Persistence loops:** malicious `while true; do ...; sleep 60; done` backgrounded with `nohup` or run from cron are common beacon patterns: look for long-running `sh -c 'while true...'` in `ps auxf` and for odd entries in `crontab -l`.
- **Don't parse `ls`:** use globs or `find -print0` with `while IFS= read -r -d '' f` to handle every filename safely.

## 8. Labs
**Easy**
1. Print numbers 1–10 with `while`, then with `until`.
2. Read `/etc/hostname` line by line and print each line with its number.
3. Prove the subshell trap with both versions of the counter example.

**Medium**
4. Run `menu-loop.sh` and make option 4 show listening ports. Handle end-of-input with `|| break` and test with `echo -e "1\n0" | ./menu-loop.sh`.
5. Read `/etc/passwd` with `IFS=: read` and print only users whose shell is not `nologin`/`false`.
6. Write `wait-for-file.sh FILE SECONDS`: loops until the file exists or the time runs out.

**Hard (cyber)**
7. Generate the Checkpoint 3 sample log, run `brute-detect.sh` with thresholds 10, 100, and 300. Interpret the result and record the exit code (`echo $?`).
8. Run the live watcher against `demo.log`, append 3 events (2 failed, 1 accepted), and verify that exactly 2 alerts fire. Then rotate the log (`mv demo.log demo.log.1; touch demo.log`) and confirm `tail -F` still follows.
9. Extend `brute-detect.sh` to ignore allow-listed IPs read from a file `trusted.txt` (use `grep -vFxf trusted.txt`).
10. Make the detector log alerts with `logger -t brute-detect -p auth.warning "..."` and find them in the journal/syslog.

## 9. Common mistakes
- Looping over `$(cat file)` instead of `while read`
- Forgetting `-r` and `IFS=`
- Variables lost after a pipe (subshell)
- Infinite loops with no exit condition or sleep
- Using `tail -f` on rotating logs

## 10. Quiz
1. `while` vs `until`?
2. Why does `cmd | while read ...; done` lose variable changes?
3. What do `IFS=` and `-r` do in the read loop?
4. Why `tail -F` instead of `-f` for logs?
5. Name two ways to keep a loop from running forever.

<details><summary>Answers</summary>

1. `while` repeats while the command succeeds; `until` repeats until it succeeds.
2. The loop runs in a subshell; its variables aren't visible to the parent.
3. `IFS=` preserves surrounding whitespace; `-r` stops backslash processing.
4. `-F` re-opens the file after rotation.
5. A counter/maximum tries, `timeout`, a `break` condition, or a deadline check.
</details>

## 11. Mastery checklist
- [ ] I loop with `while`/`until` and control them with `break`/`continue`
- [ ] I read files safely and avoid the subshell trap
- [ ] I can build a threshold-based detector and a live watcher
- [ ] I bound loops and treat log input as hostile

## Next → `30-troubleshooting.md`
