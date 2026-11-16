# Chapter 11 · The Environment
📖 Book: Part II, pp. 115–125 · ⏱ ~90 min · Prereq: Part 1

## Learning goals
- Distinguish shell variables from environment variables
- Inspect and change the environment
- Know which startup files run, and when
- Safely edit `.bashrc` and `PATH`

## 1. Core concepts
- The **environment** is data the shell passes to every program it starts: variables and settings.
- **Shell variables:** local to the current shell. **Environment variables:** exported, inherited by child processes.
- Variables are `NAME=value` (no spaces around `=`). Read with `$NAME`.

| Command | Purpose |
|---|---|
| `printenv` / `env` | Show environment variables |
| `set` | Show shell variables, functions, and environment (use `set \| less`) |
| `printenv USER` / `echo $USER` | One variable |
| `VAR=value` | Create a shell variable |
| `export VAR` / `export VAR=value` | Make it an environment variable |
| `unset VAR` | Remove it |
| `source file` / `. file` | Run a file in the current shell |
| `alias` | Show aliases |

**Important variables:** `HOME`, `USER`, `SHELL`, `PATH`, `PWD`, `OLDPWD`, `LANG`, `EDITOR`, `PAGER`, `PS1` (prompt), `HISTFILE`, `TERM`, `DISPLAY`.

## 2. Startup files
**Login shell** (SSH, virtual console, macOS Terminal): reads, in order, `/etc/profile`, then the **first found** of `~/.bash_profile`, `~/.bash_login`, `~/.profile`.
**Non-login interactive shell** (new terminal window on most Linux desktops): reads `~/.bashrc`, and system-wide `/etc/bash.bashrc` (Debian/Ubuntu) or `/etc/bashrc` (RHEL/Fedora).

| Shell | Files |
|---|---|
| bash | `~/.bash_profile` / `~/.profile` (login), `~/.bashrc` (interactive), `~/.bash_logout` |
| zsh (Kali, macOS) | `~/.zshenv` (all), `~/.zprofile` (login), `~/.zshrc` (interactive), `~/.zlogin`, `~/.zlogout` |
| Alpine (ash) | `/etc/profile`, `~/.profile`; interactive config via `ENV` variable |
| System-wide extras | `/etc/profile.d/*.sh` |

Most distros' `~/.profile` or `~/.bash_profile` ends by sourcing `~/.bashrc`, so put your daily settings in **`~/.bashrc`**.

## 3. Editing safely
```bash
cp ~/.bashrc ~/.bashrc.bak          # always back up first
nano ~/.bashrc                      # or vim (chapter 12)
# add at the end:
export EDITOR=vim
export PATH="$HOME/bin:$PATH"       # prepend personal tools
alias ll='ls -lAh'
source ~/.bashrc                    # reload without logging out
```
Add `# comments` explaining each change. Test in a new terminal; keep the old one open in case you break something.

## 4. Guided walkthrough
```bash
printenv | less
printenv | grep -i '^HOME\|^USER\|^SHELL'
echo $PATH | tr ':' '\n'
MYVAR="hello"; echo $MYVAR
bash -c 'echo "child sees: $MYVAR"'        # empty (not exported)
export MYVAR; bash -c 'echo "child sees: $MYVAR"'   # now visible
unset MYVAR
mkdir -p ~/bin && echo 'echo hi from my tool' > ~/bin/hi && chmod +x ~/bin/hi
export PATH="$HOME/bin:$PATH"; hi
```

## 5. 🔐 Cyber relevance
- **PATH hijacking:** a writable directory early in `PATH` (or `.` in it) lets an attacker's `ls`/`sudo` run instead of the real one. Audit PATH after any compromise.
- **Persistence:** attackers add lines to `~/.bashrc`, `~/.profile`, `/etc/profile`, and `/etc/profile.d/*.sh` so their code runs at every login. During investigations: `ls -la ~ | grep '^-.*\.'`, then read these files; compare timestamps with `stat`.
- **Secrets in environment:** API keys exported in `~/.bashrc` are visible in child processes and to the same user via `/proc/PID/environ` (`sudo tr '\0' '\n' < /proc/PID/environ`). Use a secrets manager or short-lived tokens.
- **Dangerous variables:** `LD_PRELOAD` and `LD_LIBRARY_PATH` inject libraries into programs; `PROMPT_COMMAND` runs code on every prompt; `BASH_ENV`/`ENV` run scripts for non-interactive shells. Unexpected values are a red flag.
- **sudo and the environment:** `sudo` resets the environment (`env_reset`) to block this class of attacks. Check `sudo -l` for `env_keep` and `SETENV`.
- **Proxy variables:** `http_proxy`/`https_proxy` can silently route traffic through an attacker. Check with `env | grep -i proxy`.
- **Clean-room execution for testing:** `env -i bash --noprofile --norc` starts a shell with an empty environment.
- macOS: GUI apps don't read `.zshrc`; Terminal opens login shells, so `.zprofile`/`.zshrc` both matter.

## 6. Labs
**Easy**
1. Find your `HOME`, `USER`, `SHELL`, `LANG` using `printenv`.
2. Set `GREETING="Hi"`, print it; start `bash`, print it again; `exit`. Explain.
3. Export it and repeat.

**Medium**
4. Create `~/bin`, add a script `hello`, put `~/bin` in PATH via `~/.bashrc`, open a new terminal and run `hello`.
5. Add an alias to `~/.bashrc`, reload it with `source`, confirm with `alias`.
6. Show which startup files exist in your home: `ls -a ~ | grep -E 'profile|bashrc|bash_|zsh'`.

**Hard (cyber)**
7. Audit PATH: list each directory with `ls -ld`. Flag any directory writable by group/others, or any relative entry (`.` or an empty entry).
8. Demonstrate the risk: make `~/bin/ls` print "hijacked" and put `~/bin` first in PATH. Run `type -a ls`. Undo it. Write 3 sentences about detection.
9. Review `/etc/profile` and `/etc/profile.d/`. List who owns them and when they were modified.
10. Run `sudo -l` and look for `env_keep`; read `man sudoers` about `env_reset`.

## 7. Common mistakes
- Spaces around `=` (`VAR = x` fails)
- Editing `.bashrc` but forgetting to `source` it
- Overwriting `PATH` (`PATH=/bin`) and losing commands. Use `PATH="$HOME/bin:$PATH"`
- Putting secrets in startup files

## 8. Quiz
1. `export` does what?
2. Which file should hold your normal aliases?
3. Login vs non-login shell?
4. Name two startup files attackers abuse.
5. Which environment variable injects shared libraries?

<details><summary>Answers</summary>

1. Makes a variable part of the environment so child processes inherit it.
2. `~/.bashrc` (zsh: `~/.zshrc`).
3. Login reads profile files; non-login interactive reads `.bashrc`.
4. `~/.bashrc`, `~/.profile`, `/etc/profile.d/*.sh`, etc.
5. `LD_PRELOAD` (also `LD_LIBRARY_PATH`).
</details>

## 9. Mastery checklist
- [ ] I can inspect, set, export and unset variables
- [ ] I know which startup file runs in which situation
- [ ] I extend PATH safely
- [ ] I audit startup files and PATH for persistence and hijack signs

## Next → `12-a-gentle-introduction-to-vi.md`
