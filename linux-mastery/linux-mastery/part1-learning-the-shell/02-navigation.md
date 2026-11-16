# Chapter 2 · Navigation
📖 Book: Part I, pp. 7–12 · ⏱ ~60 min · Prereq: Chapter 1

## Learning goals
- Picture the Linux file system as one tree starting at `/`
- Use `pwd`, `ls`, `cd` fluently
- Tell absolute from relative pathnames and use `.`, `..`, `~`, `-`
- Know the important directories and why attackers and defenders care about them

## 1. Core concepts
- Linux has **one tree** with a single root `/`. There are no drive letters. Extra disks are *mounted* into the tree.
- **Current working directory (cwd):** where you are right now. Every relative path starts here.
- **Absolute path:** starts at `/` (e.g. `/usr/bin`). Works from anywhere.
- **Relative path:** starts from cwd (e.g. `../logs`).
- Filenames are **case-sensitive** (`File` ≠ `file`). Names starting with `.` are **hidden**.
- Avoid spaces in names. Extensions (`.txt`) are only convention; Linux doesn't need them.

## 2. Commands
| Command | Purpose |
|---|---|
| `pwd` | Print working directory |
| `ls` | List directory contents |
| `cd dir` | Change directory |
| `cd` | Go to your home directory |
| `cd -` | Go back to the previous directory |
| `cd ~user` | Go to another user's home |
| `.` / `..` | This directory / parent directory |
| `~` | Your home directory |
| `realpath path` | Resolve to a full, real path (GNU coreutils; on macOS use `realpath` from coreutils or `cd path && pwd -P`) |

## 3. Key directories (Filesystem Hierarchy Standard)
| Path | Contains | 🔐 Security note |
|---|---|---|
| `/` | Root of everything | |
| `/home` | User home directories | Look for `.ssh`, history files, credentials |
| `/root` | The root user's home | High-value target |
| `/etc` | System configuration | `passwd`, `shadow`, `ssh/sshd_config`, `sudoers` |
| `/var/log` | Logs | First stop in an investigation |
| `/tmp`, `/var/tmp` | Temporary files, world-writable | Malware staging area |
| `/bin`, `/usr/bin`, `/sbin` | Programs | Modified binaries = red flag |
| `/dev` | Device files | |
| `/proc`, `/sys` | Kernel/process info (virtual) | Live process inspection |
| `/opt`, `/srv` | Add-on software, service data | |
| `/mnt`, `/media` | Mount points | |

**Distro/OS differences:** RHEL-family logs auth events in `/var/log/secure`, Debian-family in `/var/log/auth.log`. Many modern systems use `journalctl`. Alpine uses BusyBox with `/var/log/messages`. macOS uses `/Users` instead of `/home`, and `/var` is really `/private/var`.

## 4. Guided walkthrough
```bash
pwd                 # where am I?
cd /usr/bin         # absolute path
pwd
cd ..               # up one level -> /usr
cd ./bin            # relative path (same as cd bin)
cd                  # home
cd -                # back to /usr/bin
cd ~root 2>&1       # probably "Permission denied"; try reading the message
ls                  # list cwd
ls /etc             # list another directory without moving
ls -a ~             # include hidden files
```

## 5. 🔐 Cyber relevance
- **Hidden files are not secret.** `ls -a` shows them. Attackers hide files with names like `.. ` (dot dot space) or `...`.
- **Path traversal:** `../../etc/passwd` is just a relative path. Web apps that don't sanitize paths can be tricked into reading it. You now know why `..` matters.
- **Orientation commands for any box:**
  ```bash
  ls -la /home /tmp /var/tmp /root 2>/dev/null
  ls -la /etc | head -30
  ```
- **Symlink awareness:** the path you see may not be the real location. Use `realpath` or `ls -l`.

## 6. Labs
**Easy**
1. `cd /`, then `ls`. Name 5 directories you recognize.
2. Go home with `cd` (no arguments). Confirm with `pwd`.
3. From home, go to `/var/log` using an **absolute** path, then back using `cd -`.

**Medium**
4. From `/usr/share`, reach `/usr/bin` using only a **relative** path.
5. Run `ls -a ~`. List every hidden file; guess what each is for.
6. Run `ls -la /tmp`. Why does it look different from your home directory? (We'll explain the `t` in chapter 9.)

**Hard (cyber)**
7. Without `cd`, list `/etc`, `/var/log`, and `/home` in a single `ls` command.
8. Find which distro log file records logins: does `/var/log/auth.log` or `/var/log/secure` exist? Do you have permission to read it?
9. Draw (on paper) the tree for the top level of `/`, marking which directories you could write to.

## 7. Common mistakes
- Typing `cd Documents` when not in home. Use `pwd` first
- Forgetting case sensitivity (`cd documents` fails)
- Confusing `/` (root) with `~` (home)
- Spaces in names: `cd My Docs` fails. Use `cd "My Docs"` or `cd My\ Docs`

## 8. Quiz
1. Absolute vs relative path?
2. What does `cd -` do?
3. Which directory holds system configuration? Which holds logs?
4. Why is `/tmp` interesting to attackers?
5. What are `.` and `..`?

<details><summary>Answers</summary>

1. Absolute begins at `/`; relative begins at the cwd.
2. Returns to the previous directory.
3. `/etc`; `/var/log`.
4. World-writable and executable-friendly, so it's a common place to drop tools.
5. Current directory and its parent.
</details>

## 9. Mastery checklist
- [ ] I can move anywhere using both absolute and relative paths
- [ ] I know what `~`, `.`, `..`, `-` mean
- [ ] I can name 8 key directories and what lives there
- [ ] I know where auth logs live on my distro

## Next → `03-exploring-the-system.md`
