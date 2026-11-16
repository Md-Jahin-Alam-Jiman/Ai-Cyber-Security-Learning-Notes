# Checkpoint 2 · Build Your Own Hardened `.bashrc`
🎯 Covers chapters 11–13 · ⏱ ~1.5–2 hours · Do this **after** Chapter 13

## Scenario
You'll create a secure, comfortable shell environment you can reuse on every machine and defend: it's a portable "analyst workstation profile".

## Safety first
```bash
cp ~/.bashrc ~/.bashrc.backup.$(date +%F)
mkdir -p ~/linux-lab/checkpoint2
```
Keep one terminal open as a recovery shell. If anything breaks: `cp ~/.bashrc.backup.* ~/.bashrc` (pick the right file).
Write your new file at `~/linux-lab/checkpoint2/bashrc-analyst` first, test with `bash --rcfile ~/linux-lab/checkpoint2/bashrc-analyst`, and only then append or source it from `~/.bashrc`.

## Requirements (build each in order)

### A · Basics (chapter 11)
- Header comment: author, date, purpose
- `export EDITOR=vim` and `export PAGER=less`
- A personal bin: `~/bin` added to `PATH` safely (prepend with `$HOME/bin`, no `.`, no empty entries)
- `umask 027` (private by default) with a comment on why

### B · History (chapter 8)
```bash
HISTSIZE=10000
HISTFILESIZE=20000
HISTTIMEFORMAT="%F %T "
HISTCONTROL=ignoredups        # don't use ignorespace; auditing is the goal
shopt -s histappend
PROMPT_COMMAND='history -a'
```
Explain each line in a comment.

### C · Aliases (chapter 5)
Include at least 8, for example:
```bash
alias ll='ls -lAh --color=auto'     # macOS: ls -lAhG
alias ..='cd ..'
alias grep='grep --color=auto'
alias ports='sudo ss -tulpn'        # macOS: sudo lsof -i -P -n | grep LISTEN
alias myip='hostname -I'            # macOS: ipconfig getifaddr en0
alias psmem='ps aux --sort=-%mem | head'
alias psc='ps aux --sort=-%cpu | head'
alias now='date -u +"%F %T UTC"'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
```
Add one safe alias of your own design.

### D · Prompt (chapter 13)
- Two-line prompt with UTC time, exit status, `user@host`, cwd
- Green for normal user, **bold red for root**
- Test as root (`sudo -i`; it uses root's own `.bashrc`, so also test with `sudo -E bash --rcfile file`)

### E · Defensive checks (chapters 9, 10, 11)
Add three small *aliases or functions* that help you audit:
```bash
alias suid='find / -perm -4000 -type f 2>/dev/null'
alias wwdirs='find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null'
whereis_cmd() { type -a "$1"; }        # trust check
```
(Functions are taught formally in chapter 24+. Treat this as a preview.)

### F · Portability
Add a comment block listing which lines differ on macOS/zsh/Alpine, and a zsh version of the prompt (`PROMPT=...`) kept in a separate file `zshrc-analyst`.

## Test plan
Run each and record pass/fail in `~/linux-lab/checkpoint2/test-log.txt`:
```bash
bash --rcfile ~/linux-lab/checkpoint2/bashrc-analyst -i
echo "$PATH" | tr ':' '\n'                 # no '.' and no empty lines
type ll now suid                           # all resolve
echo "$HISTTIMEFORMAT"
umask                                      # 0027
```
Then:
1. Open two terminals, run one command in each, and confirm both appear in history file.
2. Break it on purpose (add a syntax error), observe the error, fix it.
3. Restore from backup to prove your recovery path works.

## Hardening review (write 5 sentences)
1. Why is `umask 027` better than `022`?
2. What are the risks of `PROMPT_COMMAND`?
3. Why prepend `~/bin` to PATH? What's the risk?
4. How would you detect someone modifying your `.bashrc`? (Hint: `stat`, `sha256sum`; store the hash.)
5. Which of your settings help an investigator, and which help an attacker?

## Verification checklist
- [ ] File has comments and no unexplained lines
- [ ] `bash -n ~/linux-lab/checkpoint2/bashrc-analyst` reports no syntax errors
- [ ] PATH is clean
- [ ] Root prompt is visibly different
- [ ] History records timestamps and updates immediately
- [ ] You can restore your original `.bashrc`
- [ ] Integrity baseline created: `sha256sum ~/.bashrc > ~/linux-lab/checkpoint2/bashrc.sha256`

## Self-scoring (100 pts)
| Area | Points |
|---|---|
| Correctness (loads cleanly, no errors) | 25 |
| Safety (backup, recovery, clean PATH) | 20 |
| History/audit configuration | 15 |
| Aliases and tools | 15 |
| Prompt design | 15 |
| Documentation and review answers | 10 |

## Stretch goals
- Add `~/.bash_aliases` and source it from `.bashrc` if present
- Create a `~/.inputrc` with case-insensitive tab completion (`set completion-ignore-case on`)
- Test the profile inside a fresh container: `docker run -it ubuntu:24.04 bash`
- Write a cron or systemd timer idea that alerts you if `.bashrc` hash changes (we'll build it in Part 4)

## Next → Part 3: `../part3-common-tasks-tools/14-package-management.md`
