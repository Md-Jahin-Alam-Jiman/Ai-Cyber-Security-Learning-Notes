# Chapter 14 · Package Management
📖 Book: Part III, pp. 153–164 · ⏱ ~90 min · Prereq: Part 2

## Learning goals
- Understand packages, repositories, and dependencies
- Install, update, search, inspect and remove software on the major distro families
- Verify package integrity and answer "which package owns this file?"
- Treat software installation as a security decision

## 1. Core concepts
- A **package** bundles programs, config, and metadata. A **repository** is a signed collection of packages. **Dependencies** are resolved for you.
- **Two layers:** low-level tools install one file (`dpkg`, `rpm`); high-level tools talk to repositories and resolve dependencies (`apt`, `dnf`, `zypper`).

| Family | Format | Low-level | High-level | Repo config |
|---|---|---|---|---|
| Debian / Ubuntu / Kali | `.deb` | `dpkg` | `apt` | `/etc/apt/sources.list`, `/etc/apt/sources.list.d/` |
| RHEL / Rocky / Alma / Fedora | `.rpm` | `rpm` | `dnf` (`yum`) | `/etc/yum.repos.d/` |
| openSUSE / SLES | `.rpm` | `rpm` | `zypper` | `/etc/zypp/repos.d/` |
| Arch / Manjaro | `.pkg.tar.zst` | `pacman -U` | `pacman` | `/etc/pacman.conf` |
| Alpine | `.apk` | `apk` | `apk` | `/etc/apk/repositories` |
| macOS | formula/cask | n/a | `brew` | taps |
| Universal | snap / flatpak | | `snap`, `flatpak` | |

## 2. Everyday command table
| Task | Debian/Ubuntu/Kali | RHEL/Fedora/Rocky | Arch | Alpine | openSUSE | macOS |
|---|---|---|---|---|---|---|
| Refresh index | `sudo apt update` | `dnf check-update` | `sudo pacman -Sy` | `sudo apk update` | `sudo zypper refresh` | `brew update` |
| Upgrade all | `sudo apt upgrade` | `sudo dnf upgrade` | `sudo pacman -Syu` | `sudo apk upgrade` | `sudo zypper update` | `brew upgrade` |
| Search | `apt search x` | `dnf search x` | `pacman -Ss x` | `apk search x` | `zypper search x` | `brew search x` |
| Show info | `apt show x` | `dnf info x` | `pacman -Si x` | `apk info x` | `zypper info x` | `brew info x` |
| Install | `sudo apt install x` | `sudo dnf install x` | `sudo pacman -S x` | `sudo apk add x` | `sudo zypper install x` | `brew install x` |
| Remove | `sudo apt remove x` | `sudo dnf remove x` | `sudo pacman -Rs x` | `sudo apk del x` | `sudo zypper remove x` | `brew uninstall x` |
| List installed | `apt list --installed` | `dnf list installed` | `pacman -Q` | `apk list -I` | `zypper se -i` | `brew list` |
| Files of a pkg | `dpkg -L x` | `rpm -ql x` | `pacman -Ql x` | `apk info -L x` | `rpm -ql x` | `brew list x` |
| Which pkg owns file | `dpkg -S /bin/ls` | `rpm -qf /bin/ls` | `pacman -Qo /bin/ls` | `apk info -W /bin/ls` | `rpm -qf /bin/ls` | n/a |
| Install local file | `sudo apt install ./x.deb` | `sudo dnf install ./x.rpm` | `sudo pacman -U x.pkg.tar.zst` | `sudo apk add --allow-untrusted x.apk` | `sudo zypper install ./x.rpm` | n/a |
| Clean unused | `sudo apt autoremove` | `sudo dnf autoremove` | `pacman -Qdtq \| sudo pacman -Rns -` | n/a | `sudo zypper packages --unneeded` | `brew cleanup` |

Notes: `apt remove` keeps config files; `apt purge` deletes them too. Never use `--allow-untrusted` except in an isolated lab. Which command finds the package providing a missing command? Debian `apt-file search bin/name` (install `apt-file`), RHEL `dnf provides '*/name'`, Arch `pacman -F name`.

## 3. Guided walkthrough (safe, simulated)
```bash
# Debian/Ubuntu/Kali
sudo apt update
apt search tree | head
apt show tree
sudo apt install -s tree        # -s = simulate, changes nothing
sudo apt install tree
dpkg -L tree
dpkg -S $(which tree)
apt-cache policy tree           # version, repo origin
sudo apt remove tree
# RHEL-family: sudo dnf install tree ; rpm -ql tree ; rpm -qf $(which tree) ; dnf history
```

## 4. 🔐 Cyber relevance
- **Patching is your biggest control.** Unpatched packages are the leading cause of compromises. Check updates:
  - Debian: `apt list --upgradable`; automate with `unattended-upgrades`
  - RHEL: `dnf updateinfo list security`, `sudo dnf upgrade --security`; automate with `dnf-automatic`
  - Alpine: `apk version -l '<'`
  - Ubuntu: `ubuntu-security-status`
- **Supply-chain risk:** a repository or key you add gets root-level trust. Review `sources.list.d`, `/etc/yum.repos.d`, and key files; check that repos use `https` and `signed-by`/`gpgcheck=1`. Remove unknown third-party repos. `apt-key` is deprecated; use per-repo keyrings in `/etc/apt/keyrings/`.
- **`curl ... | sudo bash` is remote code execution with extra steps.** Download, read, checksum, then run. Compare with vendor-published SHA-256 and GPG signatures (`gpg --verify`).
- **Verify installed files against the package database** (after a suspected compromise, to detect tampered binaries):
  - Debian: `sudo apt install debsums; sudo debsums -c` (changed files only) or `dpkg -V`
  - RHEL/SUSE: `sudo rpm -Va` (flags `5` = checksum changed, `S` size, `M` mode, `U` owner)
  - Arch: `sudo pacman -Qkk`
  - Alpine: `apk verify`
  Caveat: an attacker with root can also alter the database; use trusted offline copies for serious cases.
- **Attack-surface reduction:** fewer packages, fewer vulnerabilities. List installed: `apt list --installed | wc -l`; remove compilers and dev tools from production hosts.
- **Kali tooling:** `sudo apt install kali-tools-top10` or the `kali-linux-default` metapackage; always from Kali's official repos.
- **Inventory for vulnerability scanning:** feed `dpkg -l` or `rpm -qa` output to a scanner (Trivy, Grype, OpenSCAP, Lynis: `sudo apt install lynis; sudo lynis audit system`).
- **Containers and snaps** carry their own dependency trees; scan them separately.

## 5. Labs
**Easy**
1. Identify your distro's package manager. Run its refresh/update command.
2. Search for `tree`, `htop`, `nmap`; read `show/info` for each.
3. Install `tree` and `htop`; verify with `which`.

**Medium**
4. Find which package owns `/bin/ls` and `/etc/passwd` (use `dpkg -S`/`rpm -qf`).
5. List all files installed by `tree`. Then remove it and check they're gone.
6. Simulate an install (`-s` on apt, `--assumeno` on dnf) and read what would change.

**Hard (cyber)**
7. List your configured repositories and note each URL and whether it uses a signature check.
8. Run an integrity check (`debsums -c` / `rpm -Va` / `pacman -Qkk`). Explain each flagged item (config files often change legitimately).
9. Make a security-updates report: count pending updates and save to `~/linux-lab/updates.txt`.
10. Modify a harmless packaged file in a *container* (`docker run -it ubuntu:24.04 bash`), then detect the change with `dpkg -V`/`debsums`.

## 6. Common mistakes
- Forgetting to refresh the index first
- Mixing package managers (`pip`/`npm` as root over system packages, `brew` on Linux without isolation)
- Adding random PPAs/repos
- Using `-y` blindly in production scripts
- Interrupting an upgrade (leaves a locked/broken dpkg: `sudo dpkg --configure -a`)

## 7. Quiz
1. Difference between `dpkg` and `apt`?
2. How do you find which package owns a file?
3. Why is `curl | bash` risky?
4. Which command verifies installed RPM files?
5. What does `apt purge` do that `remove` doesn't?

<details><summary>Answers</summary>

1. `dpkg` handles single `.deb` files; `apt` resolves dependencies and uses repositories.
2. `dpkg -S`, `rpm -qf`, `pacman -Qo`, `apk info -W`.
3. It runs unreviewed remote code with your privileges.
4. `rpm -Va` (or `rpm -V pkg`).
5. It also deletes the package's configuration files.
</details>

## 8. Mastery checklist
- [ ] I install, update and remove software on at least two distro families
- [ ] I can trace any file to its package
- [ ] I check signatures and sources before trusting software
- [ ] I can run a package-integrity check and read its output

## Next → `15-storage-media.md`
