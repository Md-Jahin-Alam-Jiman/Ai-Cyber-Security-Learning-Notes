# Chapter 36 · Exotica
📖 Book: Part IV, pp. 485–505 · ⏱ ~120 min · Prereq: Chapter 35 · **Advanced shell features**

## Learning goals
- Use group commands and subshells, and know the difference
- Use process substitution and here strings
- Handle signals and cleanup with `trap`
- Run work asynchronously (`&`, `wait`, `flock`, `timeout`) and use named pipes
- Recognize how these features appear in attacker tradecraft, and hunt for them

## 1. Group commands vs subshells
| Form | Runs in | Use |
|---|---|---|
| `{ cmd1; cmd2; }` | **Current shell** (note the `;` and spaces) | Redirect/pipe several commands as one |
| `( cmd1; cmd2 )` | **Subshell** (copy of the shell) | Isolate `cd`, variables, `umask`, `set` changes |
```bash
x=1; ( x=2; cd /tmp ); echo "$x $PWD"        # x is still 1, still in the old directory
x=1; { x=2; }; echo "$x"                      # 2
{ date -u; id; uname -a; } > triage-head.txt  # one redirect for all three commands
```
Pipelines run each stage in a subshell (the trap from chapter 29).

## 2. Process substitution and here strings
```bash
diff <(sort a.txt) <(sort b.txt)               # treat command output as a file (bash/zsh)
comm -12 <(sort ips1.txt) <(sort ips2.txt)
tee >(grep ERROR > errors.txt) > all.txt < app.log     # fan one stream out to a command
read -r a b <<< "hello world"                          # here string
```
Not available in `dash`/POSIX `sh` or BusyBox `ash`.

## 3. Signals and `trap`
| Signal | Number | Typical cause |
|---|---|---|
| `EXIT` (pseudo) | | Script ends for any reason |
| `INT` | 2 | Ctrl+C |
| `TERM` | 15 | `kill PID` |
| `HUP` | 1 | Terminal closed |
| `ERR` (pseudo) | | A command fails (bash) |
| `DEBUG` (pseudo) | | Before every command (bash) |
| `KILL`/`STOP` | 9/19 | **Cannot be trapped** |

```bash
tmp="$(mktemp -d)"
cleanup() { rm -rf -- "$tmp"; }
trap cleanup EXIT                                 # runs on normal exit, errors, and most signals
trap 'echo "interrupted" >&2; exit 130' INT TERM  # exit 128+signal number by convention
trap '' HUP                                       # ignore a signal
trap - INT                                        # restore default
trap -p                                           # list the traps currently set
```

## 4. Asynchronous execution
```bash
sleep 3 & pid=$!            # start in background; $! is its PID
wait "$pid"; echo "status=$?"     # wait for one job and get its exit status
for h in a b c; do (sleep 1; echo "done $h") & done; wait    # run three jobs in parallel
timeout 5 command           # kill after 5 seconds (GNU; macOS: gtimeout from coreutils)
flock -n 9 || exit 1        # single-instance lock (Linux util-linux)
nohup cmd > out.log 2>&1 &  # keep running after logout
disown %1                   # detach a job from the shell
```

## 5. Named pipes (FIFOs)
A FIFO is a file that acts as a one-way pipe between unrelated processes.
```bash
dir="$(mktemp -d)"; fifo="$dir/pipe"; mkfifo -m 600 "$fifo"
trap 'rm -rf -- "$dir"' EXIT
( for i in 1 2 3; do echo "message $i"; sleep 0.2; done > "$fifo" ) &    # producer
while IFS= read -r m; do echo "consumer got: $m"; done < "$fifo"          # consumer
wait
```
Use `mktemp -d` and a private directory; `mktemp -u` (name only) is race-prone.

## 6. `select`: a built-in menu
```bash
PS3="Choose a host: "
select h in web1 db1 quit; do
  case "$h" in
    quit) break ;;
    "")   echo "invalid choice" ;;
    *)    echo "selected: $h" ;;
  esac
done
```

## 7. Project: `safe-runner.sh`, run any command in a controlled sandbox-lite
```bash
#!/usr/bin/env bash
# safe-runner.sh - run a command with a time limit, private temp dir, clean PATH, and cleanup
# Usage: ./safe-runner.sh SECONDS COMMAND [ARGS...]
(( $# >= 2 )) || { echo "usage: ${0##*/} SECONDS COMMAND [ARGS...]" >&2; exit 64; }
secs="$1"; shift
[[ $secs =~ ^[0-9]+$ ]] && (( secs >= 1 && secs <= 3600 )) || { echo "SECONDS must be 1-3600" >&2; exit 64; }

umask 077
PATH=/usr/local/bin:/usr/bin:/bin
tmp="$(mktemp -d)" || exit 1
cleanup() { rm -rf -- "$tmp"; }
trap cleanup EXIT
trap 'echo "interrupted" >&2; exit 130' INT TERM

start="$(date -u +%FT%TZ)"
( cd "$tmp" && timeout "$secs" "$@" ) > "$tmp/run.log" 2>&1
status=$?
printf 'start=%s status=%s cmd=%q\n' "$start" "$status" "$*" >&2
cat "$tmp/run.log"
[ "$status" -eq 124 ] && echo "TIMED OUT after ${secs}s" >&2
exit "$status"
```
Try: `./safe-runner.sh 5 echo hello`, `./safe-runner.sh 2 sleep 10` (exit 124), `./safe-runner.sh 0 ls` (rejected), and press Ctrl+C during a long run to see the trap and cleanup.

> ⚠️ This is a convenience wrapper, **not a security sandbox**: the command still runs with your privileges and network. For real isolation use containers, VMs, namespaces (`unshare`, `bwrap`/bubblewrap, `firejail`), seccomp, or disposable cloud lab machines.

## 8. 🔐 Cyber relevance
**Defender uses**
- **Reliable cleanup of sensitive material:** `trap cleanup EXIT` removes temp files, unmounts images, and deletes decrypted copies even when a script fails, which matters for evidence handling and secrets.
- **Subshell isolation:** change `umask`, `PATH`, or `cd` inside `( ... )` so a privileged helper can't leak its state into the rest of the script; run risky parsing in a subshell and discard it.
- **Process substitution** makes **baseline diffs** and **IOC set operations** one-liners without temp files: `diff <(sudo find /usr/bin -type f -exec sha256sum {} + | sort -k2) baseline.txt`.
- **Single-instance, bounded jobs:** `flock` stops overlapping cron runs; `timeout` stops hung scanners and runaway analysis tools.
- **Parallel collection:** `&` + `wait` (or `xargs -P`) speeds up fleet checks; capture each job's exit status for reporting.
- **Restricted shells (`rbash`, `bash -r`)** limit what a user can type, but they're **not a security boundary** (escapes via `vi`, `less`, `awk`, environment tricks). Pair with least-privilege accounts, containers, `ForceCommand`, and auditing.

**Attacker tradecraft to recognize (blue-team view)**
- **`trap` and `DEBUG`/`PROMPT_COMMAND` hooks in startup files** (`~/.bashrc`, `/etc/profile.d/*.sh`) can log keystrokes' commands, capture credentials, or re-establish persistence. Hunt: `grep -RnE 'trap |PROMPT_COMMAND|DEBUG' ~/.bashrc ~/.bash_profile ~/.profile /etc/profile /etc/profile.d /etc/bash.bashrc 2>/dev/null`. In a live shell: `trap -p`, `echo "$PROMPT_COMMAND"`, `declare -f`.
- **Surviving logout:** `nohup`, `disown`, `setsid`, `tmux/screen` sessions, and `trap '' HUP` keep malicious processes alive after the session ends. Hunt: `ps -eo pid,ppid,tty,etime,cmd | awk '$3=="?"'` for orphaned interpreters, `ls /tmp/tmux-*`, `screen -ls`, user crontabs, systemd user units.
- **Named pipes + netcat/`bash -i` reverse shells:** FIFOs and `/dev/tcp` redirections are a well-known way to wire a shell to a network socket. You don't need the recipe to detect it: look for **shells with network connections or odd file descriptors** and for FIFOs in writable directories.
  ```bash
  find / -xdev -type p 2>/dev/null                              # named pipes (expect a few system ones)
  sudo ss -tnp | grep -E 'bash|sh|nc|ncat|socat|python|perl'    # interpreter or netcat with a socket
  sudo ls -l /proc/<PID>/fd                                      # a shell whose fds 0,1,2 are sockets/pipes
  sudo grep -a '/dev/tcp/' -r /home /tmp /var/tmp /etc/cron* 2>/dev/null
  ```
- **`/dev/tcp` and `/dev/udp`** are bash features (not real devices), so file-based detection misses them; monitor process network behavior (auditd, EDR, `ss`), egress filtering, and command-line logging.
- **Lock files and PID files as persistence markers:** `/tmp/.X11-lock`-style names for malware; check hidden files in `/tmp`, `/var/tmp`, `/dev/shm`.
- **Signal tricks:** `kill -STOP` on a monitoring agent or `kill -9` on security tools are attacker moves; alert on unexpected termination of EDR/auditd/rsyslog and use systemd `Restart=` plus tamper-resistant logging.
- **Process substitution artifacts:** you'll see `/dev/fd/63` in command lines and `ps`; benign in your own scripts, but worth understanding when reviewing suspicious one-liners.
- **`exec` replaces the process image** (`exec cmd` leaves no shell parent) and `exec 3<>/dev/tcp/host/port` opens sockets without external tools; both complicate process-tree analysis.
- **`eval`, `source`, and `.`** execute text. Never apply them to untrusted data, and keep sourced files root-owned and non-writable.
- **IR commands for shell state:** `declare -p` and `declare -f` dump variables/functions, `alias`, `trap -p`, `set -o`, `shopt`, `type -a`: run them in a *suspect* interactive shell session to spot hijacks.

## 9. Labs
**Easy**
1. Demonstrate the difference between `( cd /tmp; pwd )` and `{ cd /tmp; pwd; }` in terms of your working directory afterwards.
2. Use `diff <(sort fileA) <(sort fileB)` on two small files.
3. Start three `sleep` jobs in the background, then `wait` for them and print a message.

**Medium**
4. Write `cleanup-demo.sh` that creates a temp directory and file, sets `trap cleanup EXIT`, then (a) exits normally, (b) fails with `false`, (c) is interrupted with Ctrl+C. Verify the directory is removed each time.
5. Build the FIFO producer/consumer demo and extend it with two producers.
6. Create a `select` menu for the three checks of `perm-audit.sh` (chapter 27).

**Hard (cyber)**
7. Build and test `safe-runner.sh`: timeouts, rejected input, Ctrl+C, and a command that writes to its working directory (confirm the file disappears afterwards).
8. Hunt for hooks: add `PROMPT_COMMAND='echo hooked >> /tmp/hook.log'` to a **lab copy** of a bashrc (`bash --rcfile`), run a few commands, and then find it with the grep command above and `trap -p`/`echo "$PROMPT_COMMAND"`. Remove it.
9. In a lab VM, start a harmless long-running shell loop with `nohup` + `disown`, close the terminal, and find it from another login using the "orphaned interpreter" `ps` filter and `/proc/PID/cwd`/`fd`. Kill it.
10. Run the named-pipe, socket, and `/dev/tcp` hunting commands above on your own system. Record what's normal on a clean host (system FIFOs, legitimate sockets) to build a baseline for later comparison.

## 10. Common mistakes
- Missing `;` or spaces in `{ ...; }`
- Expecting variable changes to persist from a subshell or pipeline
- `trap` set *after* the code that needs cleanup (set it first)
- Using `kill -9` as a first resort (skips traps)
- Unbounded background jobs without `wait`/limits
- Predictable temp or FIFO names in shared directories

## 11. Quiz
1. `{ }` vs `( )`?
2. Which signals can't be trapped?
3. What does `trap cleanup EXIT` guarantee (and not)?
4. Why is `mktemp -d` safer than `/tmp/myapp.$$`?
5. Name two places attackers hide shell hooks.
6. Is `rbash` a security boundary?

<details><summary>Answers</summary>

1. `{ }` runs in the current shell; `( )` runs in a subshell, isolating changes.
2. `SIGKILL` and `SIGSTOP`.
3. Cleanup runs on normal exit, errors, and most catchable signals, but not if the process is killed with `-9` or power is lost.
4. It atomically creates an unpredictable, private path, avoiding symlink/race attacks.
5. Startup files (`~/.bashrc`, `/etc/profile.d/*`), `PROMPT_COMMAND`/`DEBUG` traps, cron, systemd units.
6. No; it can often be escaped, so use real isolation and least privilege.
</details>

## 12. Mastery checklist
- [ ] I choose between group commands and subshells deliberately
- [ ] I use `trap`, `wait`, `timeout`, `flock`, and process substitution confidently
- [ ] I clean up secrets and temp data reliably
- [ ] I can hunt for shell hooks, persistence, and FIFO/socket-based shells
- [ ] I understand what restricted shells and wrappers do and don't protect

## Next → `capstone-security-toolkit.md` (the final project)
