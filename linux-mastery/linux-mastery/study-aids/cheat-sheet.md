# Linux Command Line Cheat Sheet (by task)
Quick reference for the whole course. Details live in the chapter files.

## Orientation (ch 1–3)
| Task | Command |
|---|---|
| Who/where am I | `whoami`, `id`, `hostname`, `uname -a`, `cat /etc/os-release`, `uptime` |
| Where am I / move | `pwd`, `cd dir`, `cd`, `cd -`, `ls -lah`, `ls -lat` |
| What is this file | `file f`, `stat f`, `less f`, `strings f \| less`, `xxd f \| head` |
| Disk / memory | `df -hT`, `lsblk -f`, `free -h` |

## Files (ch 4, 9, 17, 18)
| Task | Command |
|---|---|
| Make / copy / move | `mkdir -p a/b`, `cp -a src dst`, `mv -n a b`, `ln -s target link` |
| Delete (carefully) | `ls pattern` first, then `rm -- file`, `rm -ri dir` |
| Permissions | `chmod 640 f`, `chmod u+x f`, `chown user:group f`, `umask 027` |
| Find | `find / -xdev -name '*.conf'`, `-mtime -2`, `-perm -4000`, `-nouser`, `-print0 \| xargs -0` |
| Archive | `tar -czf a.tgz dir/`, `tar -tzf a.tgz`, `tar -xzf a.tgz -C dest/` |
| Sync / hash | `rsync -avhn src/ dst/` (dry run), `sha256sum f`, `sha256sum -c f.sha256` |

## Pipes and text (ch 6, 19, 20, 21)
| Task | Command |
|---|---|
| Redirect | `> f`, `>> f`, `2> f`, `> f 2>&1`, `2>/dev/null`, `\| tee f` |
| Filter | `grep -Ei 'x' f`, `grep -Eo 'regex' f`, `grep -v`, `grep -c`, `grep -rIn` |
| Sort / count | `sort \| uniq -c \| sort -nr \| head` |
| Columns | `cut -d: -f1,3 f`, `awk -F: '{print $1}' f`, `column -t` |
| Edit stream | `sed -E 's/old/new/g' f`, `sed -n '5,10p' f`, `tr -d '\r'` |
| Compare | `diff -u a b`, `comm -12 <(sort a) <(sort b)` |
| Regex (ERE) | `.` any · `^ $` anchors · `[a-z]` `[^0-9]` · `? * + {n,m}` · `( )` `\|` · `[[:digit:]]` |

## Shell mechanics (ch 5, 7, 8, 11)
| Task | Command |
|---|---|
| What is this command | `type -a cmd`, `man cmd`, `cmd --help`, `apropos word` |
| Quote | `"$var"` expands · `'$var'` literal · `\$` escape |
| Expansion | `{a,b}`, `{1..5}`, `$(cmd)`, `$((1+2))`, `~` |
| Variables | `VAR=x`, `export VAR`, `printenv`, `echo "$PATH" \| tr ':' '\n'` |
| History keys | `Ctrl+R` search · `!!` last · `Ctrl+A/E` line start/end · `Ctrl+U/K/Y` cut/paste · `Alt+B/F` word |

## Processes and network (ch 10, 16)
| Task | Command |
|---|---|
| Processes | `ps aux`, `ps -ef --forest`, `top`, `pgrep -a name` |
| Jobs | `cmd &`, `Ctrl+Z`, `bg`, `fg`, `jobs`, `kill %1` |
| Signals | `kill PID` (TERM) · `kill -9 PID` (last resort) · `kill -HUP PID` (reload) |
| Network state | `ip -br a`, `ip r`, `ss -tulpn`, `sudo lsof -i -P -n` |
| Test | `ping -c3 h`, `dig +short h`, `curl -I url`, `nc -zv h 22` |
| Remote | `ssh user@h`, `scp f h:path`, `rsync -avz -e ssh src/ h:dst/`, `ssh-keygen -t ed25519` |

## Packages (ch 14)
| Distro | Update · Install · Remove · Owns file |
|---|---|
| Debian/Ubuntu/Kali | `apt update && apt upgrade` · `apt install x` · `apt remove x` · `dpkg -S file` |
| RHEL/Rocky/Fedora | `dnf upgrade` · `dnf install x` · `dnf remove x` · `rpm -qf file` |
| Arch | `pacman -Syu` · `pacman -S x` · `pacman -Rs x` · `pacman -Qo file` |
| Alpine | `apk update && apk upgrade` · `apk add x` · `apk del x` · `apk info -W file` |
| openSUSE | `zypper update` · `zypper install x` · `zypper remove x` · `rpm -qf file` |
| macOS | `brew update && brew upgrade` · `brew install x` · `brew uninstall x` |

## Scripting essentials (ch 24–36)
```bash
#!/usr/bin/env bash
set -u; umask 077
usage() { echo "usage: ${0##*/} [-o FILE] ARG" >&2; exit 64; }
while getopts ":o:" opt; do case "$opt" in o) out="$OPTARG" ;; *) usage ;; esac; done
shift $((OPTIND - 1))
file="${1:?missing ARG}"                        # abort if empty
[[ $file =~ ^[A-Za-z0-9._/-]+$ ]] || usage      # allow-list validation
tmp="$(mktemp -d)"; trap 'rm -rf -- "$tmp"' EXIT
while IFS= read -r line; do printf '%s\n' "$line"; done < "$file"
for f in ./*; do [ -e "$f" ] || continue; echo "$f"; done
case "$x" in a|b) echo ab ;; *) echo other ;; esac
declare -A count; count[$k]=$(( ${count[$k]:-0} + 1 ))
```
| Test | Meaning |
|---|---|
| `[ -f f ]` `-d` `-e` `-r` `-w` `-x` `-s` `-L` | File tests |
| `[ -z s ]` `-n` `=` `!=` | Strings |
| `[ a -eq b ]` `-ne -lt -le -gt -ge` | Integers (or `(( a < b ))`) |
| `${v:-d}` `${v:?msg}` `${#v}` `${v##*/}` `${v%.txt}` `${v//a/b}` `${v,,}` | Parameter expansion |
| `bash -n` · `bash -x` · `shellcheck f` | Check / trace / lint |

## Security triage quick list
```bash
# Orientation
whoami; id; hostname; uname -a; date -u; uptime
# Persistence and privilege
sudo -l; find / -xdev -perm -4000 -type f 2>/dev/null
crontab -l; ls -la /etc/cron* ; systemctl list-units --type=service --state=running
# Network and processes
sudo ss -tulpn; ps auxf; sudo lsof -i -P -n
# Recent changes and temp dirs
sudo find / -xdev -type f -mtime -2 -not -path '/proc/*' 2>/dev/null | head
ls -la /tmp /var/tmp /dev/shm
# Logins and logs
last | head; sudo lastb | head
sudo grep "Failed password" /var/log/auth.log | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c | sort -nr | head
# Integrity (Debian / RHEL)
sudo debsums -c        sudo rpm -Va
```
Authorization first: scan and test only what you own or have written permission to test.

## Seven habits that prevent most disasters
1. Quote every expansion: `"$var"`, `"$@"`
2. `--` before untrusted values; `./*` instead of `*`
3. Dry-run first (`rsync -n`, `echo rm ...`, `make -n`)
4. Never `eval` or `curl | bash`; validate input with allow-lists
5. No secrets in arguments, history, or `set -x` traces
6. `mktemp` + `trap` for temp files; `umask 077` for sensitive output
7. Verify, don't trust: hashes, signatures, `type -a`, `shellcheck`
