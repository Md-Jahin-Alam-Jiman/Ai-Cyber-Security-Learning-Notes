# Chapter 9 · Permissions
📖 Book: Part I, pp. 81–98 · ⏱ ~120 min · Prereq: Chapter 8 · **Core security chapter**

## Learning goals
- Read and set file permissions in symbolic and octal form
- Understand `umask`, setuid, setgid, and the sticky bit
- Switch identities safely with `su` and `sudo`
- Change ownership with `chown` and `chgrp`

## 1. The model
Every file has an **owner**, a **group**, and **everyone else (other)**, each with **r**ead, **w**rite, e**x**ecute.
| | Files | Directories |
|---|---|---|
| r | read contents | list names |
| w | modify contents | create/delete/rename entries (needs `x` too) |
| x | run as program | enter (`cd`) and access items |

Identity commands: `id`, `whoami`, `groups`. Account data: `/etc/passwd` (users), `/etc/group` (groups), `/etc/shadow` (password hashes, root only).

## 2. Octal and symbolic
| Octal | Perms | | Octal | Perms |
|---|---|---|---|---|
| 7 | rwx | | 3 | -wx |
| 6 | rw- | | 2 | -w- |
| 5 | r-x | | 1 | --x |
| 4 | r-- | | 0 | --- |

```bash
chmod 755 script.sh        # rwxr-xr-x
chmod 600 secret.key       # rw-------
chmod u+x file             # add execute for owner
chmod go-rwx file          # remove all from group and others
chmod a+r file             # everyone can read
chmod -R 750 dir           # recursive
```
Symbolic: who `u g o a` · operator `+ - =` · perms `r w x`.

## 3. Defaults: umask
`umask` subtracts permissions from new files (base 666) and directories (base 777). `umask 022` gives files 644, dirs 755. `umask 077` gives 600/700 (private). Ubuntu commonly uses `0002` for users with private groups; RHEL typically `0022`.

## 4. Special permissions
| Bit | Octal | Symbol | Effect |
|---|---|---|---|
| setuid | 4000 | `s` in owner x | Runs as the file's **owner** |
| setgid | 2000 | `s` in group x | Runs as the group; on dirs, new files inherit the group |
| sticky | 1000 | `t` in other x | In a directory, only the file's owner can delete it (`/tmp`) |

## 5. Changing identities and ownership
| Command | Purpose |
|---|---|
| `su -` | Become root with a login shell (needs root's password) |
| `su - user` | Become another user |
| `sudo cmd` | Run one command as root, logged and policy-controlled |
| `sudo -l` | What may I run with sudo? |
| `sudo -u user cmd` | Run as another user |
| `chown user:group file` | Change owner and group (root) |
| `chgrp group file` | Change group |
| `passwd` | Change your password |

Admin group: Debian/Ubuntu/Kali use group **sudo**; RHEL/Fedora/Arch/Alpine (with sudo) use **wheel**.
Add a user: `sudo usermod -aG sudo alice` (Debian) · `sudo usermod -aG wheel alice` (RHEL/Arch). Alpine often uses `doas`.
Edit sudo rules only with `sudo visudo`.
macOS: users are managed with `dscl`/System Settings; `chmod` and `chown` are the same; ACLs use `chmod +a`.

## 6. Guided walkthrough
```bash
cd ~/linux-lab
id; groups
umask
touch f1; ls -l f1
umask 077; touch f2; ls -l f2; umask 022
chmod 600 f1; ls -l f1
chmod 755 f1; chmod g+w f1; ls -l f1
ls -l /etc/passwd /etc/shadow /usr/bin/passwd
ls -ld /tmp
sudo -l
sudo chown root:root f1; ls -l f1; sudo chown $USER:$USER f1
```

### Shared-directory exercise
```bash
sudo groupadd labteam
sudo useradd -m -s /bin/bash -G labteam alice       # Debian also has: adduser
sudo useradd -m -s /bin/bash -G labteam bob
sudo passwd alice; sudo passwd bob
sudo mkdir /srv/shared
sudo chown root:labteam /srv/shared
sudo chmod 2770 /srv/shared                          # setgid + rwx for owner/group, none for others
sudo -u alice touch /srv/shared/a.txt
sudo -u bob ls -l /srv/shared                        # bob sees alice's file, group = labteam
sudo -u nobody ls /srv/shared                        # denied
# cleanup afterwards:
sudo userdel -r alice; sudo userdel -r bob; sudo groupdel labteam; sudo rm -rf /srv/shared
```
(On Debian-family `useradd` works; on RHEL-family too. macOS uses `sysadminctl`/`dscl` instead.)

## 7. 🔐 Cyber relevance
This chapter is the base of **privilege escalation** and **hardening**.
- **Find setuid/setgid files** (classic audit and attacker enumeration):
  ```bash
  find / -perm -4000 -type f 2>/dev/null     # setuid
  find / -perm -2000 -type f 2>/dev/null     # setgid
  find / -perm -0002 -type f 2>/dev/null     # world-writable files
  find / -perm -0002 -type d ! -perm -1000 2>/dev/null   # world-writable dirs w/o sticky
  ```
  Compare with known-good lists (GTFOBins is a public reference for abusable binaries).
- **Key permissions:** SSH private keys must be `600`; `~/.ssh` must be `700`. SSH refuses loose keys. `/etc/shadow` should be `640 root:shadow` (Debian) or `000/0` (RHEL), unreadable to normal users.
- **Never `chmod 777`.** It's a symptom of laziness and a vulnerability.
- **`sudo` hygiene:** review `sudo -l`; `NOPASSWD: ALL` or editors/interpreters in sudo rules are escalation paths. Logs: `/var/log/auth.log` or `/var/log/secure`.
- **Mandatory access control** adds a second layer: SELinux (`getenforce`, `ls -Z`, RHEL-family) and AppArmor (`sudo aa-status`, Ubuntu/Debian/SUSE). "Permission denied" may come from these, not from rwx.
- **Extended ACLs:** `getfacl file`, `setfacl -m u:alice:r file` when classic permissions are too coarse. A `+` at the end of `ls -l` perms signals ACLs.
- **Immutable files:** `lsattr` / `sudo chattr +i file` stop even root from modifying a file; attackers and defenders both use this.
- **Check accounts:** `awk -F: '$3==0' /etc/passwd` lists UID 0 accounts (only root should appear; `awk` comes in chapter 20). Simpler now: `grep ':0:' /etc/passwd`.

## 8. Labs
**Easy**
1. Make `notes.txt`, set it to `640`, then `600`. Verify with `ls -l`.
2. Write a tiny script `hello.sh` (`echo hello`), run it (fails), `chmod +x`, then run `./hello.sh`.
3. Show your `umask`, then create a file and directory and compare permissions.

**Medium**
4. Convert: what are `rwxr-x---`, `rw-r--r--`, and `rwx------` in octal?
5. With `umask 077`, create a file and a directory. Explain the result.
6. Run the shared-directory exercise and confirm bob can read alice's file but `nobody` cannot.

**Hard (cyber)**
7. Run the four `find` commands above. List every setuid binary on your system and look up what three of them do.
8. Compare `ls -l /etc/passwd` and `ls -l /etc/shadow`. Explain why they differ.
9. Create `~/.ssh` and a fake key file with permissions `755`/`666`; fix them to `700`/`600`. Explain why SSH enforces this.
10. Run `ls -Z ~` (SELinux) or `sudo aa-status` (AppArmor). Which one is on your distro?

## 9. Common mistakes
- `chmod -R 777` to "fix" an error
- Forgetting directories need `x`
- Using `sudo` for everything, including editing user files (leaves root-owned files in home)
- Confusing `su` (switch user) with `sudo` (run command)

## 10. Quiz
1. What's 640 in symbolic form?
2. What does setuid do?
3. Why is `/tmp` mode `1777`?
4. `umask 027` creates files with what permissions?
5. Which command lists what you may run as root?
6. Name two ways to find privilege-escalation candidates.

<details><summary>Answers</summary>

1. `rw-r-----`.
2. The program runs with its owner's privileges instead of the caller's.
3. Everyone can write, but the sticky bit stops users deleting others' files.
4. 640 (666 minus 027).
5. `sudo -l`.
6. Finding setuid binaries, world-writable files/directories, weak `sudo` rules.
</details>

## 11. Mastery checklist
- [ ] I read and write octal and symbolic modes fluently
- [ ] I explain setuid, setgid, and sticky bit
- [ ] I audit a system for risky permissions
- [ ] I use `sudo` instead of root shells where possible
- [ ] I know SELinux/AppArmor can also deny access

## Next → `10-processes.md`
