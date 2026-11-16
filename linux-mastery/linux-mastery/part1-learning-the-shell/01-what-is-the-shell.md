# Chapter 1 · What Is the Shell?
📖 Book: Part I, pp. 3–6 · ⏱ ~60 min · Prereq: `00-setup-practice-environment.md`

## Learning goals
- Explain what the shell, bash, and a terminal emulator are
- Read a prompt and know what `$` vs `#` means
- Use command history and cursor movement
- Run basic commands: `date`, `cal`, `df`, `free`, `exit`
- Run the same ideas on other distros and name the first recon commands every security person types

## 1. Core concepts
| Term | Plain meaning |
|---|---|
| **Shell** | Program that takes your typed commands and passes them to the OS |
| **bash** | "Bourne-again shell", an upgrade of the original `sh` by Steve Bourne. Default on most distros |
| **Terminal emulator** | The GUI window that gives you access to the shell (`gnome-terminal`, `konsole`, `xterm`) |
| **Prompt** | `[me@linuxbox ~]$`: user, machine, current directory, then the symbol |
| `$` vs `#` | `$` = normal user. `#` = superuser (root). Treat `#` with extra care |
| **Virtual console** | Text login sessions behind the desktop: `Ctrl+Alt+F1…F6` (return with `Alt+F7`; the key varies by distro) |

**Other shells you will meet:**
| Shell | Where |
|---|---|
| `bash` | Ubuntu, Debian, RHEL, most servers |
| `zsh` | Default on Kali (2020.4+) and macOS |
| `dash` | `/bin/sh` on Debian/Ubuntu, used for fast system scripts |
| `ash` (BusyBox) | Alpine, routers, embedded devices |
| `fish`, `ksh`, `PowerShell` | Niche or cross-platform use |

Check yours: `echo $SHELL` (login shell) and `ps -p $$` (the shell running now).

## 2. Command cheat table
| Command | What it does | Same on other systems? |
|---|---|---|
| `date` | Current date and time | Yes, everywhere |
| `cal` | Calendar | Missing on minimal RHEL/Alpine: `dnf install util-linux`/`ncal` (RHEL 9: `dnf install ncal`), `apk add util-linux` |
| `df` | Disk free space | Yes. On macOS the columns differ slightly |
| `free` | Memory usage | **Linux only.** macOS: `vm_stat` and `top -l 1 \| head` |
| `exit` / `Ctrl+D` | End session | Yes |
| `uname -a` | Kernel and architecture | Yes |
| `cat /etc/os-release` | Which distro and version | Linux only. macOS: `sw_vers` |

## 3. Keys to know
- **↑ / ↓**: history (about 1,000 commands remembered by default)
- **← / →**: move the cursor to edit the line
- **Copy/paste in terminal:** `Ctrl+Shift+C` / `Ctrl+Shift+V` (plain `Ctrl+C` means *interrupt*)
- **Mouse trick:** highlighting text copies it; middle-click pastes it (X Window System)

## 4. Guided walkthrough
```bash
kaekfjaeifj          # gibberish -> "command not found"; just feedback, not a crash
# press ↑, edit with ← →, press Enter
date
cal
df
free
```
Journal questions:
1. What does the "Mounted on" column of `df` tell you?
2. Is your prompt `$` or `#`? Why does it matter?

## 5. 🔐 Cyber relevance: your first recon commands
When you land on an unknown Linux box (an incident, a CTF, an authorized pentest), the first minute looks like this:

```bash
whoami              # which user am I?
id                  # my UID, GID, and groups (am I in sudo/wheel/docker?)
hostname            # machine name
uname -a            # kernel version (hints at known vulnerabilities)
cat /etc/os-release # distro and version
uptime              # time since boot (a recent reboot is interesting in incidents)
df -h               # disks: is something full or oddly mounted?
free -h             # memory
date; timedatectl   # time and timezone (critical when correlating logs)
echo $SHELL
```
Why this matters:
- **`#` in the prompt** means a root shell. For attackers it's the goal; for defenders it's what to audit.
- **Shell history is evidence.** Bash stores it in `~/.bash_history` (zsh: `~/.zsh_history`). Investigators read it, and attackers try to wipe it. Never assume history is complete: it's only written on clean exit, and it can be disabled.
- **Prompt spoofing:** the prompt is just text, so don't trust it alone. Use `whoami`.
- **Time zone mistakes** wreck incident timelines. Always record `date -u` (UTC).

## 6. Same task, different systems
| Task | Debian/Ubuntu/Kali | RHEL/Fedora/Rocky | Arch | Alpine | macOS |
|---|---|---|---|---|---|
| Show OS info | `cat /etc/os-release` | same | same | same | `sw_vers` |
| Install a package | `sudo apt install pkg` | `sudo dnf install pkg` | `sudo pacman -S pkg` | `apk add pkg` | `brew install pkg` |
| Memory | `free -h` | `free -h` | `free -h` | `free -m` (BusyBox) | `vm_stat` |
| Default shell | bash | bash | bash | ash | zsh |
| Root prompt | `sudo -i` | `sudo -i` | `sudo -i` | `su -` or `doas -s` | `sudo -i` |

## 7. Labs
**Easy**
1. Run `date`, `cal`, `df`, `free`. Describe each output in one sentence.
2. Use ↑ to re-run `date` three times without retyping.
3. Run `echo $SHELL` and `cat /etc/os-release`. Write both in your journal.

**Medium**
4. Run `cal 2026` and `cal 11 2026`. Guess the arguments, then check `man cal` (`q` to quit).
5. Open a second terminal tab (`Ctrl+Shift+T`). Run `echo $$` in each. Why do the numbers differ?
6. Run `df -h` and `free -h`. Why is it easier to read? (Options come in chapter 3.)

**Hard (cyber)**
7. Write the "first minute recon" block above into a file `recon.txt` using only what you know. (Redirection comes in chapter 6, so for now just run each command and paste the results into your journal.)
8. Look at `~/.bash_history` with `less ~/.bash_history` (`q` to quit). Find the gibberish command you typed. If it's not there, why? (Hint: history is saved when the shell exits. Type `exit`, reopen, then check.)
9. Switch to a virtual console (`Ctrl+Alt+F3`), log in, run `whoami`, `exit`, return with `Alt+F7` or `Ctrl+Alt+F2`. *(Doesn't work in some VMs/Wayland setups; skip if it fails.)*

## 8. Common mistakes
- **Typing the `$`** from examples. It's the prompt, not part of the command
- **Ctrl+V pastes nothing:** use Ctrl+Shift+V
- **Panic at "command not found":** usually a typo, or the tool isn't installed
- **Assuming all systems are bash:** check with `echo $SHELL`

## 9. Quiz
1. Shell vs terminal emulator?
2. What does a `#` at the end of the prompt mean?
3. Two ways to end a session?
4. Why might `.bash_history` be missing a command you just ran?
5. Name three commands for identifying who and where you are on a system.

<details><summary>Answers</summary>

1. The shell interprets commands; the terminal emulator is the window that hosts it.
2. Superuser (root) privileges.
3. `exit`, `Ctrl+D`, or closing the window.
4. History is written on shell exit; it may also be disabled or cleared.
5. `whoami`, `id`, `hostname` (also `uname -a`).
</details>

## 10. Mastery checklist
- [ ] I can explain shell vs bash vs terminal
- [ ] I can tell a normal prompt from a root prompt, and I know the prompt alone isn't proof
- [ ] I can recall and edit commands with the arrow keys
- [ ] I can run the first-minute recon block and explain each line
- [ ] I know the package manager for at least 3 distro families

## Next → Chapter 2: Navigation (`02-navigation.md`)
