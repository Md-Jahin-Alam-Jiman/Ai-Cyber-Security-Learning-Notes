# 00 · Setup: Your Practice Environment

## Goal
A safe lab where you can break things without risk, on the distros you'll meet in security work.

## 1. Pick a safe machine
- A VM (VirtualBox/VMware/KVM) with **snapshots**, so you can roll back after mistakes
- Or a container: `docker run -it ubuntu:24.04 bash`
- Never practice destructive commands on your daily machine

## 2. Distros worth knowing for a cyber career
| Distro family | Why it matters | Package manager |
|---|---|---|
| Debian / Ubuntu | Most servers, cloud images | `apt` |
| Kali / Parrot (Debian-based) | Pentesting toolkits | `apt` |
| RHEL / Rocky / Alma / Fedora | Enterprise servers | `dnf` (older: `yum`) |
| Arch / Manjaro | Rolling releases, deep learning | `pacman` |
| Alpine | Containers, tiny images | `apk` |
| openSUSE / SLES | Enterprise | `zypper` |
| macOS (Unix, not Linux) | Common analyst laptop | `brew` (Homebrew) |

## 3. Install the helper tools
| Distro | Command |
|---|---|
| Ubuntu/Debian/Kali | `sudo apt update && sudo apt install -y man-db tree vim aspell lftp openssh-client zip` |
| RHEL/Rocky/Fedora | `sudo dnf install -y man-db tree vim-enhanced aspell lftp openssh-clients zip` |
| Arch | `sudo pacman -S --needed man-db tree vim aspell lftp openssh zip` |
| Alpine | `apk add mandoc man-pages tree vim aspell lftp openssh-client zip` |
| openSUSE | `sudo zypper install man tree vim aspell lftp openssh zip` |
| macOS | `brew install tree vim aspell lftp` (man, ssh, zip already included) |

## 4. Create your lab and journal
```bash
mkdir -p ~/linux-lab && cd ~/linux-lab
touch journal.md
```
After each chapter write 3 lines: what I learned, what confused me, what to try next.

## Golden rules
- Never run `rm -rf` on a path you haven't listed with `ls` first
- Never use `sudo` for a command you don't understand
- Only scan or test systems **you own or are authorized to test**
- Keep labs inside `~/linux-lab`

## Done when
- [ ] Terminal opens and shows a prompt
- [ ] `~/linux-lab` exists
- [ ] `tree --version` and `vim --version` print output
- [ ] You know which distro you're on: `cat /etc/os-release`
