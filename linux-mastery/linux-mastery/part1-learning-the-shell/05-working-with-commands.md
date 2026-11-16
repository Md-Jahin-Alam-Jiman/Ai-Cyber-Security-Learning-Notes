# Chapter 5 · Working with Commands
📖 Book: Part I, pp. 39–48 · ⏱ ~60 min · Prereq: Chapter 4

## Learning goals
- Know the four kinds of commands
- Find where a command comes from and how to read its documentation
- Create your own shortcuts with `alias`

## 1. The four kinds of commands
| Kind | Example | Notes |
|---|---|---|
| Executable program | `/usr/bin/ls` | Compiled binary or script |
| Shell builtin | `cd`, `type` | Built into bash |
| Shell function | (you'll write some later) | Defined in the shell |
| Alias | `ll` | A nickname for another command |

## 2. Identify and locate
| Command | Purpose |
|---|---|
| `type cmd` | What kind of command is it? `type -a cmd` shows **all** matches |
| `which cmd` | Path of the executable (external only; behavior varies by distro) |
| `command -v cmd` | Portable way to find a command (works in scripts) |

## 3. Get documentation
| Command | Purpose |
|---|---|
| `help cd` | Help for shell builtins |
| `cmd --help` | Usage summary for most programs |
| `man cmd` | Full manual (`q` quits, `/` searches) |
| `man 5 passwd` | Specific section (1 user cmds, 5 file formats, 8 admin) |
| `apropos word` / `man -k word` | Search manual descriptions |
| `whatis cmd` | One-line description |
| `info cmd` | GNU info pages |
| `/usr/share/doc/` | READMEs and extras |

If `apropos` finds nothing on a fresh system, build the index: Debian/Ubuntu `sudo mandb`; RHEL/Fedora `sudo mandb` (or `makewhatis` on old versions); Alpine install `mandoc` and `man-pages`. macOS: `man -k` works out of the box.

## 4. Aliases
```bash
alias                     # list aliases
alias ll='ls -lAh --color=auto'
alias ..='cd ..'
type ll                   # shows it's an alias
unalias ll
```
Aliases vanish when the terminal closes. To make them permanent, put them in `~/.bashrc` (chapter 11). On macOS/Kali (zsh): `~/.zshrc`.

## 5. Guided walkthrough
```bash
type ls cd date
which ls
help cd | head
ls --help | less
man ls
apropos partition
whatis passwd
type -a echo          # builtin AND /bin/echo may both exist
```

## 6. 🔐 Cyber relevance
- **Which `ls` am I actually running?** Attackers can **hijack** commands by placing a malicious program earlier in `$PATH`, or by defining an alias or function. `type -a ls` is a quick trust check. `\ls` bypasses aliases.
- **PATH inspection:** `echo $PATH | tr ':' '\n'`. A `.` or a writable directory early in PATH is dangerous.
- **`man` is your offline cheat sheet.** In a locked-down environment with no internet, you'll lean on `man`, `--help`, and `/usr/share/doc`.
- **Learn config file formats:** `man 5 sshd_config`, `man 5 sudoers`, `man 5 passwd`.
- **Persistence check:** shell startup files (`~/.bashrc`, `~/.profile`) can hide malicious aliases/functions. Review them during investigations.
- Tool discovery: `apropos network`, `apropos encrypt`, `apropos hash`. This is a fast way to find what's installed.

## 7. Labs
**Easy**
1. `type` each of: `cd`, `ls`, `echo`, `ll` (may be alias), `date`. Classify them.
2. Read `help cd` and `man date` (find how to print the date in `YYYY-MM-DD`).
3. Create alias `today='date +%F'`, run it, then remove it.

**Medium**
4. `type -a echo`. Why are there multiple results?
5. Use `apropos` to find commands about "partition" and "checksum".
6. Open `man 5 passwd`. What are the 7 fields of an `/etc/passwd` line?

**Hard (cyber)**
7. Print each `$PATH` entry on its own line. Check which are writable by you (`ls -ld dir`).
8. Create an alias `ls='echo hacked'`, run `ls`, then run `type ls` and `\ls`. Remove with `unalias ls`. Explain how an attacker could abuse this.
9. Read `/usr/share/doc` and find three packages' docs. Open one README.

## 8. Common mistakes
- Using `which` for builtins (it won't find them)
- Forgetting aliases aren't permanent
- Reading only `--help` and missing man page examples
- Skipping `type` and assuming what runs

## 9. Quiz
1. Four command types?
2. Difference between `help` and `man`?
3. How to see every match for a command name?
4. How could PATH ordering be abused?
5. Which man section describes file formats?

<details><summary>Answers</summary>

1. Executable, builtin, function, alias.
2. `help` documents shell builtins; `man` documents programs and files.
3. `type -a name`.
4. A malicious program earlier in PATH runs instead of the real one.
5. Section 5.
</details>

## 10. Mastery checklist
- [ ] I can classify any command with `type`
- [ ] I find documentation without a browser
- [ ] I create and remove aliases
- [ ] I audit `$PATH` for risks

## Next → `06-redirection.md`
