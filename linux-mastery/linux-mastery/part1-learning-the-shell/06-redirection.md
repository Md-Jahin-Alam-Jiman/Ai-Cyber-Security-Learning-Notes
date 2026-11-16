# Chapter 6 · Redirection
📖 Book: Part I, pp. 49–59 · ⏱ ~90 min · Prereq: Chapter 5

## Learning goals
- Understand stdin, stdout, and stderr
- Redirect to and from files; build pipelines
- Use filters: `sort`, `uniq`, `wc`, `grep`, `head`, `tail`, `tee`

## 1. Core concept
Every program has three streams:
| Stream | Number | Default |
|---|---|---|
| stdin | 0 | keyboard |
| stdout | 1 | screen |
| stderr | 2 | screen |

## 2. Operators
| Syntax | Meaning |
|---|---|
| `cmd > file` | stdout to file (**overwrites**) |
| `cmd >> file` | stdout appended |
| `cmd 2> file` | stderr to file |
| `cmd > file 2>&1` | both to one file (portable) |
| `cmd &> file` | both to one file (bash shortcut) |
| `cmd 2> /dev/null` | discard errors |
| `cmd < file` | stdin from file |
| `cmd1 \| cmd2` | pipe stdout of cmd1 into cmd2 |
| `cmd \| tee file` | show **and** save output |
| `> file` | create/empty a file |

`/dev/null` is the "black hole" device.

## 3. Filters
| Command | Use | Handy options |
|---|---|---|
| `sort` | Sort lines | `-n` numeric · `-r` reverse · `-u` unique |
| `uniq` | Collapse adjacent duplicates (sort first!) | `-c` count · `-d` only dupes |
| `wc` | Count lines/words/bytes | `-l` lines |
| `grep` | Lines matching a pattern | `-i` ignore case · `-v` invert · `-c` count · `-n` line no. · `-r` recursive |
| `head` / `tail` | First / last lines | `-n 20` · `tail -f` follow live |
| `cat` | Concatenate/show files | `-n` number lines |
| `tee` | Split output to file | `-a` append |

## 4. Guided walkthrough
```bash
cd ~/linux-lab
ls -l /usr/bin > ls-output.txt            # save listing
ls -l /bin/usr 2> ls-error.txt            # save the error (directory doesn't exist)
ls -l /bin/usr > all.txt 2>&1             # both together
cat ls-error.txt
> empty.txt                               # make empty file
ls -l /usr/bin | less                     # pipe to a pager
ls /bin /usr/bin | sort | uniq | wc -l    # how many unique names?
ls /bin /usr/bin | sort | uniq -d | head  # duplicates
ls /usr/bin | grep zip
ls /usr/bin | tail -5
ls /usr/bin | tee ls.txt | grep zip       # save AND filter
```

## 5. 🔐 Cyber relevance
Pipelines are how analysts triage logs in seconds. Replace the log path for your distro: `/var/log/auth.log` (Debian/Ubuntu/Kali), `/var/log/secure` (RHEL-family). On systemd systems: `journalctl -u ssh` (Debian) or `-u sshd` (RHEL).
```bash
sudo grep "Failed password" /var/log/auth.log | wc -l          # failed SSH logins
sudo grep -i "failed" /var/log/auth.log | tail -20             # last failures
sudo grep "Accepted" /var/log/auth.log | tail                  # successful logins
sudo tail -f /var/log/auth.log                                 # watch live (Ctrl+C)
last | head                                                    # recent logins
sudo lastb | head                                              # failed logins (if available)
```
- **Overwrite danger:** `>` can destroy a file. `set -o noclobber` blocks accidental overwrites (override with `>|`).
- **Don't hide errors during investigation.** `2>/dev/null` is handy but can mask "Permission denied", which is itself information.
- **Log tampering:** attackers run `> /var/log/auth.log` to empty logs. Empty or truncated logs are an alert. Ship logs elsewhere (syslog server/SIEM).
- **Save evidence of your own work:** `command | tee -a ~/linux-lab/notes.txt`.
- macOS: logs are in the unified log; use `log show --last 1h | grep -i fail`.

## 6. Labs
**Easy**
1. Save `ls -l /etc` to `etc-list.txt`; append `date` to it.
2. Run `ls /nonexistent`. Capture the error in `err.txt` only.
3. Count how many entries are in `/usr/bin`.

**Medium**
4. List the 10 largest files in `/usr/bin`: `ls -lS /usr/bin | head`.
5. Find all commands in `/usr/bin` containing "zip", sorted in reverse.
6. Show the output of `df -h` on screen and save it to `disk.txt` at once.

**Hard (cyber)**
7. Count failed SSH logins in your auth log (adapt to your distro; if the log is empty, run `ssh baduser@localhost` once with a wrong password, only on your own machine).
8. Use `last | head -5` and `who` and save a "login report" into `login-report.txt` with both commands' outputs plus a heading using `echo`.
9. Test `noclobber`: `set -o noclobber`, then `echo hi > file`, `echo hi > file` (error), `echo hi >| file` (works). Turn off with `set +o noclobber`.

## 7. Common mistakes
- `cmd 2>&1 > file` (wrong order); use `cmd > file 2>&1`
- Running `uniq` without `sort`
- `cat file | grep x` is fine but `grep x file` is simpler
- Forgetting `sudo` to read protected logs (and seeing silent empties)

## 8. Quiz
1. Which number is stderr?
2. `>` vs `>>`?
3. Why sort before uniq?
4. What does `tee` do?
5. How to discard error messages?

<details><summary>Answers</summary>

1. 2.
2. `>` overwrites; `>>` appends.
3. `uniq` only removes adjacent duplicates.
4. Writes stdin to both stdout and a file.
5. `2> /dev/null`.
</details>

## 9. Mastery checklist
- [ ] I redirect stdout, stderr, and both
- [ ] I chain at least 3 commands in a pipeline
- [ ] I can count and filter log events from the terminal
- [ ] I know `>` can destroy data and how to prevent it

## Next → `07-seeing-the-world-as-the-shell-sees-it.md`
