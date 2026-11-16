# Chapter 13 · Customizing the Prompt
📖 Book: Part II, pp. 143–150 · ⏱ ~60 min · Prereq: Chapter 12

## Learning goals
- Understand `PS1` and its escape codes
- Add colors and useful information
- Make the prompt permanent and safe
- Use the prompt as a security aid

## 1. Core concept
The prompt text comes from the variable **`PS1`** (primary prompt). `PS2` is the continuation prompt (`>`), `PROMPT_COMMAND` runs before each prompt.

Default example: `[\u@\h \W]\$ `

| Code | Meaning |
|---|---|
| `\u` | Username |
| `\h` / `\H` | Short / full hostname |
| `\w` / `\W` | Full cwd / last part only |
| `\d` | Date |
| `\t` / `\T` / `\@` / `\A` | Time 24h / 12h / am-pm / HH:MM |
| `\$` | `$` for users, `#` for root |
| `\!` / `\#` | History number / command number |
| `\n` | Newline |
| `\[ ... \]` | Wrap non-printing characters (colors) so line editing works |

## 2. Colors
Format: `\[\e[STYLE;COLORm\]` and reset with `\[\e[0m\]`.
| Color | Code | | Color | Code |
|---|---|---|---|---|
| Black | 30 | | Blue | 34 |
| Red | 31 | | Magenta | 35 |
| Green | 32 | | Cyan | 36 |
| Yellow | 33 | | White | 37 |
Styles: `0` normal, `1` bold, `4` underline. Background: add 10 (e.g. `41` red background).

## 3. Examples
```bash
cp ~/.bashrc ~/.bashrc.bak                       # back up first
PS1_OLD="$PS1"                                   # remember the original
PS1='\u@\h:\w\$ '                                # simple, shows full path
PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '     # green user, blue path
PS1='[\t] \u@\h \W\$ '                           # with time
PS1='\n[\d \t]\n\u@\h:\w\n\$ '                   # two-line prompt
PS1="$PS1_OLD"                                   # restore
```
Make it permanent: add `PS1='...'` to `~/.bashrc`, then `source ~/.bashrc`.

**Show last exit status:**
```bash
PS1='[$?] \u@\h:\w\$ '
```
**Red for root:**
```bash
if [ "$EUID" -eq 0 ]; then PS1='\[\e[1;31m\]\u@\h:\w# \[\e[0m\]'
else PS1='\[\e[32m\]\u@\h:\w$ \[\e[0m\]'; fi
```
(`if` is formally taught in chapter 27; copy it for now.)

**zsh (Kali/macOS):** uses `PROMPT`: `PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '`. Codes: `%n` user, `%m` host, `%~` cwd, `%#` `%` or `#`, `%*` time, `%?` exit status.
**Fish/Alpine ash:** ash supports `PS1` with fewer escapes; fish uses a `fish_prompt` function.

## 4. 🔐 Cyber relevance
A good prompt prevents expensive mistakes and supports evidence.
- **Know where you are:** show `user@host` and make **root visually loud** (red). Running a destructive command on the wrong server (prod vs lab) is a classic incident; color-code hosts (e.g. red for production).
- **Timestamps in the prompt** help you reconstruct a terminal session from screenshots or logs: `\D{%F %T}` gives full date-time (e.g. `PS1='[\D{%F %T}] \u@\h:\w\$ '`).
- **Exit status in the prompt** (`$?`) gives instant feedback about failed commands in scripts and tests.
- **Prompts can lie.** `PS1` is text controlled by the user or by a malicious startup file; it could display a fake `user@host` or hide being root. Verify with `whoami`, `id`, `hostname`.
- **`PROMPT_COMMAND` is a persistence and auditing hook.** Defenders can use it for logging: `PROMPT_COMMAND='history -a'` appends each command to the history file immediately (so history survives crashes). Attackers can abuse it to run code or suppress history, so check `echo "$PROMPT_COMMAND"` on suspicious accounts.
- **Terminal escape sequences** in untrusted text (for example, file names or logs) can change your title or hide content; viewing with `cat -v` or `less` (which shows escapes) is safer than raw `cat`.
- **Pentest/CTF habit:** put the IP/interface in your prompt to avoid attacking the wrong target: `PS1='\u@\h [$(hostname -I | cut -d" " -f1)] \w\$ '` (Linux; macOS uses `ipconfig getifaddr en0`).

## 5. Labs
**Easy**
1. Show your current `PS1` with `echo "$PS1"`.
2. Temporarily set `PS1='\u@\h:\w\$ '` and then a version with the time.
3. Restore your original prompt.

**Medium**
4. Create a colored prompt: green username, blue directory, white `$`.
5. Make it permanent in `~/.bashrc`, reload, and test it in a new terminal.
6. Create a two-line prompt with date/time on the first line.

**Hard (cyber)**
7. Build a prompt that shows exit status, UTC time, `user@host`, and cwd, with root in **bold red**. Test as root using `sudo -i` and confirm the color changes.
8. Add `PROMPT_COMMAND='history -a'`; run commands in two terminals and verify they appear in `~/.bash_history` immediately.
9. Simulate a "lying" prompt: `PS1='root@trusted-server:~# '` in a normal user shell, then reveal the truth with `whoami; hostname`. Restore the original.
10. Make a bright red production-style prompt for a hostname you choose, using a condition on `$(hostname)`.

## 6. Common mistakes
- Forgetting `\[` and `\]` around color codes, so long lines wrap and overwrite
- Not backing up `.bashrc` and then breaking the shell
- Quotes: use single quotes so `$?` and command substitutions evaluate at each prompt, not once
- Forgetting a trailing space after `$`

## 7. Quiz
1. Which variable controls the primary prompt?
2. Why wrap colors in `\[ \]`?
3. Which code shows `$` or `#` depending on privilege?
4. Why can't you trust a prompt as proof of identity?
5. What does `PROMPT_COMMAND='history -a'` do?

<details><summary>Answers</summary>

1. `PS1`.
2. They mark non-printing characters, so bash computes line length correctly.
3. `\$`.
4. It's just text anyone can set; verify with `whoami`/`id`.
5. Appends new history lines to the history file after every command.
</details>

## 8. Mastery checklist
- [ ] I read and modify `PS1`
- [ ] I make root and production hosts visually obvious
- [ ] I keep backups before editing startup files
- [ ] I never treat a prompt as proof of identity

## Next → `checkpoint-2-build-your-own-bashrc.md`
