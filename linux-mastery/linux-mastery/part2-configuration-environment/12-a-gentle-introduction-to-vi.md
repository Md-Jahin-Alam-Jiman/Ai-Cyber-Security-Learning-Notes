# Chapter 12 · A Gentle Introduction to vi
📖 Book: Part II, pp. 127–142 · ⏱ ~120 min · Prereq: Chapter 11

## Learning goals
- Open, edit, save, and quit files in `vi`/`vim` without panic
- Move, delete, copy, paste, undo, and search
- Use substitute for find-and-replace
- Edit privileged files safely

## 1. Why learn vi?
`vi` (or its clone `vim`) is on virtually **every** Unix-like system, including minimal servers, containers and recovery shells. On Alpine and BusyBox, `vi` is a small version: install the full one with `apk add vim`. Debian/Ubuntu minimal installs may have `vim-tiny`: `apt install vim`; RHEL: `dnf install vim-enhanced`. macOS ships vim.

Practice tutor: run `vimtutor` (30 minutes, interactive; excellent).

## 2. Modes
| Mode | Enter | Use |
|---|---|---|
| **Normal** (command) | `Esc` | Move, delete, copy, paste |
| **Insert** | `i` `a` `o` etc. | Type text |
| **Command-line** | `:` | Save, quit, search/replace, settings |
| **Visual** | `v` / `V` / `Ctrl+V` | Select text |

If confused: press `Esc` twice. You are in normal mode.

## 3. Cheat table
| Keys | Action |
|---|---|
| `i` / `a` | Insert before / after cursor |
| `I` / `A` | Insert at line start / end |
| `o` / `O` | New line below / above |
| `h j k l` | Left, down, up, right |
| `w` / `b` | Next / previous word |
| `0` / `$` | Start / end of line |
| `gg` / `G` / `5G` | First line / last line / line 5 |
| `Ctrl+F` / `Ctrl+B` | Page down / up |
| `x` | Delete character |
| `dd` / `dw` / `d$` / `3dd` | Delete line / word / to end of line / 3 lines |
| `yy` / `yw` / `3yy` | Copy line / word / 3 lines |
| `p` / `P` | Paste after / before |
| `u` / `Ctrl+R` | Undo / redo |
| `J` | Join lines |
| `.` | Repeat last change |
| `/text` `n` `N` | Search forward, next, previous |
| `:%s/old/new/g` | Replace all in file (add `c` to confirm) |
| `:w` `:q` `:wq` `ZZ` | Save, quit, both, both |
| `:q!` | Quit, discard changes |
| `:w newname` | Save as |
| `:e file` | Open another file |
| `:r file` | Insert another file |
| `:set number` | Show line numbers |
| `:set nu!` / `:noh` | Toggle numbers / clear search highlight |

## 4. Guided walkthrough
```bash
cd ~/linux-lab
cp /etc/services services-copy
vi services-copy
```
Inside: `:set number`, `/ssh`, `n`, `gg`, `G`, `dd`, `u`, `yy`, `p`, `:%s/tcp/TCP/g` (then `u`), `:wq`.

Then create a new file:
```bash
vi hello.txt        # press i, type 3 lines, Esc, :wq
```
Reopen it, copy line 1 to the end, delete line 2, save as `hello2.txt` with `:w hello2.txt`, quit with `:q!`.

Customize: create `~/.vimrc`:
```vim
syntax on
set number
set tabstop=4 shiftwidth=4 expandtab
set hlsearch incsearch
set ignorecase smartcase
```

## 5. 🔐 Cyber relevance
- **Edit privileged files with the right tools**
  - `sudo visudo` for sudoers (syntax-checked: a bad file can lock you out of sudo)
  - `sudo vipw` / `vigr` for `/etc/passwd`, `/etc/group`
  - `sudoedit /etc/ssh/sshd_config` (or `sudo -e`) edits a temp copy as *you*, safer than running the whole editor as root.
  - Always back up first: `sudo cp -a file file.bak.$(date +%F)`.
- **Shell escapes are escalation vectors.** Inside vim, `:!command` or `:shell` runs commands. If a user may run `sudo vim` or `sudo vi file`, they effectively have root. This is a classic GTFOBins entry. Audit `sudo -l` for editors, pagers (`less`, `man`) and interpreters.
- **Editors leave traces:** swap files (`.file.swp`), `~/.viminfo` (search and command history, registers) and `~/.vim` can reveal what someone edited. Investigators check them; for sensitive files consider `set noswapfile nobackup viminfo=` in a hardened `.vimrc`.
- **Quick config review:** use `/` search for `PermitRootLogin`, `PasswordAuthentication`, `NOPASSWD`.
- **Multi-file mass edits:** `sed` (chapter 20) is non-interactive; vim `:%s` is the interactive version.
- **Trust but verify config changes:** `diff file.bak file`, then validate the service (`sudo sshd -t` before restarting SSH).
- **Don't lose your remote session:** when editing SSH config on a remote host, keep a second session open and test before closing.

## 6. Labs
**Easy**
1. Run `vimtutor` through lesson 3. Write down 5 commands you learned.
2. Create `notes.txt` with 5 lines; save and quit.
3. In vim, delete line 3, undo, and redo.

**Medium**
4. Open `services-copy`: jump to line 50, search for `http`, change every `tcp` to `TCP` with confirmation (`:%s/tcp/TCP/gc`), discard the changes (`:q!`).
5. Build `~/.vimrc` as shown and confirm line numbers and syntax color appear.
6. Copy 3 lines and paste them 5 times using a count: `3yy` then `5p`.

**Hard (cyber)**
7. Copy `/etc/ssh/sshd_config` (if it exists) to your lab folder; open the copy; find `PermitRootLogin` and `PasswordAuthentication`; note current values and safer settings. Never edit the real file until you know the lockout risk.
8. Run `visudo -c` (syntax check) and describe what it validates. Don't edit sudoers in this lab.
9. In vim type `:!whoami` then `:!id`. Write down why `sudo vim` is dangerous in a sudo rule.
10. Create a file with vim, look for the `.swp` file from another terminal (`ls -la`), then quit and see it disappear. Explain what an investigator could learn from one left behind after a crash.

## 7. Common mistakes
- Typing text while in normal mode (commands fire unexpectedly)
- Can't exit: press `Esc`, then `:q!`
- Caps Lock on in normal mode (`G`, `A` do different things)
- Editing system files as root with no backup
- Pasting into vim without `:set paste` (indent chaos)

## 8. Quiz
1. How do you leave vim without saving?
2. `dd` vs `yy` vs `p`?
3. What does `:%s/a/b/g` do?
4. Why is `sudo vim` risky in a sudoers rule?
5. Which tool safely edits sudoers?

<details><summary>Answers</summary>

1. `Esc`, then `:q!`.
2. Delete (cut) line, copy line, paste.
3. Replace every `a` with `b` across the whole file.
4. It can spawn a root shell (`:!sh`).
5. `visudo`.
</details>

## 9. Mastery checklist
- [ ] I open, edit, save, quit, and undo without looking
- [ ] I search and replace
- [ ] I use `sudoedit`, `visudo`, and backups for system files
- [ ] I know vim's shell-escape risk

## Next → `13-customizing-the-prompt.md`
