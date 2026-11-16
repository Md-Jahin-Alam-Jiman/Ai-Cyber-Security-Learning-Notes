# Chapter 10 · Processes
📖 Book: Part I, pp. 99–111 · ⏱ ~90 min · Prereq: Chapter 9

## Learning goals
- Understand what a process is (PID, PPID, owner, state)
- View and monitor processes
- Control jobs: foreground, background, stop
- Send signals with `kill`, `killall`, `pkill`

## 1. Core concepts
- Linux is multitasking: each running program is a **process** with a **PID**. Every process has a parent (**PPID**). The first is `init`/`systemd` (PID 1).
- States seen in `ps`: **R** running · **S** sleeping · **D** uninterruptible I/O · **T** stopped · **Z** zombie.
- `/proc/PID/` exposes live information about each process.

## 2. Commands
| Command | Purpose |
|---|---|
| `ps` | Your shell's processes |
| `ps aux` | All processes (BSD style) |
| `ps -ef` | All processes (System V style, shows PPID) |
| `ps -ef --forest` / `pstree -p` | Parent-child tree |
| `top` / `htop` | Live view (`q` quit; `k` kill; `M`/`P` sort memory/CPU in top) |
| `jobs` | Shell jobs |
| `cmd &` | Start in background |
| `Ctrl+Z` | Stop (pause) foreground job |
| `bg %1` / `fg %1` | Resume in background / foreground |
| `Ctrl+C` | Interrupt (SIGINT) |
| `kill PID` | Send SIGTERM (polite) |
| `kill -9 PID` | SIGKILL (cannot be caught) |
| `kill -l` | List signals |
| `killall name` / `pkill name` | Signal by name |
| `nice` / `renice` | Set priority |
| `nohup cmd &` | Keep running after logout |
| `uptime`, `vmstat`, `free`, `lsof`, `ss` | Related system info |
| `shutdown -h now` / `reboot` / `poweroff` | Stop the system (root) |

Common signals: `1 HUP` reload/hangup · `2 INT` · `9 KILL` · `15 TERM` · `18 CONT` · `19 STOP` · `20 TSTP`.

**Platform notes:** macOS `ps aux` and `top -o cpu` work, but `--forest` doesn't (use `pstree` from brew). Alpine's BusyBox `ps` has fewer options (`ps -o pid,user,args`); install `procps` for full features. `htop`: `apt/dnf/pacman/apk add htop`, `brew install htop`.

## 3. Guided walkthrough
```bash
ps
ps aux | head
ps -ef --forest | head -20
top                            # q to quit
sleep 300 &                    # background job
jobs
fg %1                          # bring back; press Ctrl+Z to stop
bg %1                          # resume in background
kill %1                        # kill by job number
sleep 600 &
ps aux | grep sleep
kill <PID>                     # replace with the real PID
sleep 600 &  killall sleep
pgrep -a sleep                 # find by name
```

## 4. 🔐 Cyber relevance
Process analysis is core to **incident response** and **threat hunting**.
- **Triage commands:**
  ```bash
  ps auxf                                  # tree with owners
  ps -eo pid,ppid,user,etime,cmd --sort=-etime | head
  ss -tulpn                                # listening ports + owning process (sudo for names)
  sudo lsof -i -P -n                       # network connections by process
  ```
  Old systems use `netstat -tulpn`. macOS: `lsof -i -P -n | grep LISTEN`.
- **Red flags:** processes running from `/tmp`, `/dev/shm`, or hidden dirs; odd parent-child links (a web server spawning `sh`); names mimicking system ones (`kworker` lookalikes, `sshd ` with trailing space); high CPU with unknown names (cryptominers).
- **Inspect a PID deeply:**
  ```bash
  sudo ls -l /proc/PID/exe        # real binary ("(deleted)" = ran from a deleted file, suspicious)
  sudo cat /proc/PID/cmdline | tr '\0' ' '
  sudo ls -l /proc/PID/cwd /proc/PID/fd
  ```
- **Don't just `kill -9` evidence.** For forensics, capture first (`ps`, `lsof`, `/proc` data, memory) and then contain.
- **Reverse shells** typically appear as `bash`/`sh` with network sockets connected to unknown IPs: look for them with `ss -tp` and `lsof -i`.
- **Persistence & services:** `systemctl list-units --type=service --state=running`, `crontab -l`, `ls /etc/cron*`. Check these when a suspicious process keeps returning (Alpine uses OpenRC: `rc-status`).
- **Signals as a service tool:** `kill -HUP` reloads configs (e.g. `sshd`) without dropping everything.
- **Zombie processes** are harmless-ish but can mean a buggy parent.

## 5. Labs
**Easy**
1. Run `ps`, `ps aux | head`, `ps -ef | head`. Compare their columns.
2. Start `sleep 120 &`, list with `jobs`, kill it.
3. Open `top`: find the process using the most memory (`M`), then quit.

**Medium**
4. Start `sleep 200`, stop it with `Ctrl+Z`, send it to background with `bg`, then bring it back with `fg` and interrupt with `Ctrl+C`.
5. Use `pstree -p` (or `ps -ef --forest`) to trace your terminal back to PID 1.
6. Use `kill -l`. Send `SIGSTOP` and `SIGCONT` to a sleeping job; check state with `ps -o pid,stat,cmd -p PID`.

**Hard (cyber)**
7. List every listening port with its process: `sudo ss -tulpn`. For each, decide: expected or suspicious?
8. Start `sleep 500 &`, get its PID, and inspect `/proc/PID/cmdline`, `/proc/PID/exe`, `/proc/PID/cwd`.
9. Find the five longest-running processes and their parents with `ps -eo pid,ppid,etime,user,cmd --sort=-etime | head`.
10. Copy `/bin/sleep` to `/tmp/notsleep`, run `/tmp/notsleep 300 &`, then find it as an analyst: `ps aux | grep notsleep` and `ls -l /proc/PID/exe`. Clean up.

## 6. Common mistakes
- Using `kill -9` first (skips cleanup)
- Killing the wrong PID: always check with `ps -p PID -o cmd`
- Forgetting `nohup`/`tmux` for long jobs over SSH
- `killall` on Solaris kills *everything* (a different command there; on Linux it's by name)

## 7. Quiz
1. Which signal does plain `kill` send?
2. `Ctrl+C` vs `Ctrl+Z`?
3. What does `(deleted)` after `/proc/PID/exe` suggest?
4. Command to show listening ports with process names?
5. Why prefer SIGTERM over SIGKILL?
6. What is PID 1?

<details><summary>Answers</summary>

1. SIGTERM (15).
2. Interrupt (terminate) vs stop/pause the job.
3. The binary was deleted while running, a common malware trait.
4. `sudo ss -tulpn` (or `lsof -i`, `netstat -tulpn`).
5. SIGTERM lets the program clean up; SIGKILL can't be caught.
6. The init system (usually `systemd`), parent of all processes.
</details>

## 8. Mastery checklist
- [ ] I read `ps`/`top` output and sort by CPU/memory
- [ ] I manage background and stopped jobs
- [ ] I can send the right signal to the right process
- [ ] I run a basic process and network triage on an unknown host
- [ ] I recognize at least 5 suspicious process indicators

## Next → Part 1 checkpoint: `checkpoint-1-filesystem-playground-project.md`
