# Chapter 8 · Advanced Keyboard Tricks
📖 Book: Part I, pp. 73–80 · ⏱ ~60 min · Prereq: Chapter 7

## Learning goals
- Edit command lines at speed (readline shortcuts)
- Use tab completion and history search
- Understand how history works and why it matters for security

## 1. Cursor movement
| Keys | Action |
|---|---|
| `Ctrl+A` / `Ctrl+E` | Start / end of line |
| `Ctrl+F` / `Ctrl+B` | Forward / back one character |
| `Alt+F` / `Alt+B` | Forward / back one word |
| `Ctrl+L` | Clear screen |

## 2. Editing
| Keys | Action |
|---|---|
| `Ctrl+D` | Delete character under cursor (on an empty line: exit shell) |
| `Ctrl+T` / `Alt+T` | Transpose characters / words |
| `Alt+L` / `Alt+U` | Lowercase / UPPERCASE word |
| `Ctrl+K` | Cut from cursor to end of line |
| `Ctrl+U` | Cut from cursor to start of line |
| `Alt+D` | Cut word after cursor |
| `Alt+Backspace` | Cut word before cursor |
| `Ctrl+Y` | Paste (yank) last cut text |

macOS Terminal: set "Use Option as Meta key" so `Alt` shortcuts work. zsh uses similar bindings.

## 3. Completion
- `Tab` completes commands, files, variables (`$HO<Tab>`), users (`~ro<Tab>`).
- Press `Tab` twice to list options. `Alt+?` lists, `Alt+*` inserts all matches.
- Install `bash-completion` for smart completion (Debian: `apt install bash-completion`; RHEL: `dnf install bash-completion`; Arch: `pacman -S bash-completion`; macOS: `brew install bash-completion@2`).

## 4. History
| Command/keys | Action |
|---|---|
| `history` | List history (`history \| less`, `history 20`) |
| `Ctrl+R` | Reverse-incremental search (type; `Ctrl+R` again for older; `Enter` run; `Esc` edit) |
| `Ctrl+P` / `Ctrl+N` | Previous / next |
| `!!` | Repeat last command (`sudo !!` is a classic) |
| `!42` | Run history entry 42 |
| `!string` | Run last command starting with `string` |
| `!?string` | Run last command containing `string` |
| `history -c` | Clear in-memory history |

History expansion is powerful but can surprise you: use `Ctrl+R` or `history | grep` first.

## 5. Guided walkthrough
```bash
ls /usr/share/doc | head
# press Ctrl+A, type 'echo ' then Ctrl+E
# type: cp /etc/hostname ~/linux-lab/h<Tab>  (complete)
# type a long command, then Ctrl+U to cut it and Ctrl+Y to paste it back
history | tail -10
history | grep ls
!!                                   # re-run the last command
# press Ctrl+R, type "usr", find it, press Enter
```

## 6. 🔐 Cyber relevance
- **History files** (`~/.bash_history`, `~/.zsh_history`) record what a user typed. For defenders they show attacker activity; attackers clear or avoid them.
- **Never type secrets in commands:** passwords or API keys pass into history (and `ps` output while running). Use prompts (`read -s`), environment files with strict permissions, or password managers.
- **Hide a command from history (convenience, not security):** with `HISTCONTROL=ignorespace`, a command with a leading space isn't saved. Attackers use this too, so absence of evidence isn't evidence of absence.
- **Hardening for auditing:**
  ```bash
  export HISTTIMEFORMAT="%F %T "     # timestamps in history
  export HISTSIZE=10000
  shopt -s histappend                # don't overwrite history on exit
  ```
  Put these in `~/.bashrc`. Real auditing uses `auditd` (RHEL: `ausearch`/`aureport`) or `sudo` logging, not history alone.
- **Attacker habits to recognize:** `unset HISTFILE`, `export HISTFILE=/dev/null`, `history -c`, `ln -sf /dev/null ~/.bash_history`. Finding any of these is a red flag.
- **`!` history expansion in scripts can bite:** quote with single quotes, or use `set +H`.

## 7. Labs
**Easy**
1. Type `echo hello world`, move with `Ctrl+A`, `Ctrl+E`, `Alt+B`, `Alt+F` without arrow keys.
2. Cut `world` with `Alt+D` and paste it at the line's start with `Ctrl+Y`.
3. Run `history | tail -20`.

**Medium**
4. Use `Ctrl+R` to find your last `cp` or `ls` command.
5. Use tab completion to type `/usr/share/doc` without typing full names, count your keystrokes.
6. Run `sudo !!` after forgetting sudo: `ls /root` then `sudo !!`.

**Hard (cyber)**
7. Set `HISTTIMEFORMAT="%F %T "`, run 3 commands, and view `history | tail -5`.
8. Check your history file: `wc -l ~/.bash_history`. Run `HISTFILE=/dev/null bash`, type a command, `exit`, and confirm it isn't saved. Write what an investigator should look for.
9. Search history for risky patterns: `history | grep -Ei 'password|passwd|token|secret|key='`.

## 8. Common mistakes
- Using `Ctrl+C` to copy
- `!!` blindly re-running a dangerous command
- Assuming history is complete or tamper-proof
- Putting passwords in command arguments

## 9. Quiz
1. Which key deletes everything before the cursor?
2. How do you search old commands interactively?
3. What does `sudo !!` do?
4. Why is history weak evidence?
5. Name two tricks that stop commands being saved.

<details><summary>Answers</summary>

1. `Ctrl+U`.
2. `Ctrl+R`.
3. Re-runs the previous command with `sudo`.
4. It's user-controlled, written at exit, and easy to disable or edit.
5. Leading space with `ignorespace`, `unset HISTFILE`/`HISTFILE=/dev/null`, `history -c`.
</details>

## 10. Mastery checklist
- [ ] I edit command lines without arrow keys
- [ ] I rely on Tab and `Ctrl+R`
- [ ] I know the weaknesses of history as evidence
- [ ] I never place secrets on command lines

## Next → `09-permissions.md`
