# Chapter 31 · Flow Control: Branching with `case`
📖 Book: Part IV, pp. 415–422 · ⏱ ~75 min · Prereq: Chapter 30

## Learning goals
- Use `case` for clean multi-way decisions
- Write patterns (wildcards, alternatives, classes)
- Build OS/distro-aware scripts and allow-list command gates
- Replace long `if/elif` chains

## 1. Syntax
```bash
case "$word" in
  pattern1)        commands ;;
  pat2|pat3)       commands ;;       # alternatives with |
  [[:digit:]]*)    commands ;;       # classes and wildcards
  *)               default commands ;;   # always last: the "else"
esac
```
| Piece | Meaning |
|---|---|
| `;;` | End of this branch |
| `;&` (bash 4+) | Fall through to run the **next** branch's commands |
| `;;&` (bash 4+) | Continue testing the following patterns |
| `*` `?` `[abc]` `[a-z]` `[[:upper:]]` | Glob-style patterns (not regex) |
| `"quoted"` | Quoted pattern text matches literally |
| `shopt -s nocasematch` | Case-insensitive matching (bash) |

`case` uses **glob patterns**, not regex. The word is not word-split, so quoting is optional but still good practice.

## 2. Examples
```bash
read -r -p "Continue? [y/n] " ans
case "${ans,,}" in             # ${var,,} lowercases (bash 4+); macOS bash 3.2: use tr
  y|yes) echo "Continuing" ;;
  n|no)  echo "Stopping"; exit 0 ;;
  *)     echo "Please answer y or n" >&2; exit 1 ;;
esac

case "$(uname -s)" in
  Linux)  echo "Linux" ;;
  Darwin) echo "macOS" ;;
  FreeBSD|OpenBSD) echo "BSD" ;;
  *)      echo "Unknown" ;;
esac
```

## 3. Project: `pkg.sh`, the right install command for any distro
It **prints** the command (nothing is installed), so it is safe to run anywhere.
```bash
#!/usr/bin/env bash
# pkg.sh - show the install command for this system (chapter 31)
# Usage: ./pkg.sh PACKAGE
pkg="${1:?usage: pkg.sh PACKAGE}"

# Allow-list the package name: letters, digits, + . _ - only
if [[ ! $pkg =~ ^[a-zA-Z0-9][a-zA-Z0-9+._-]*$ ]]; then
  echo "invalid package name" >&2; exit 2
fi

case "$(uname -s)" in
  Darwin) echo "brew install $pkg"; exit 0 ;;
  Linux)  ;;
  *)      echo "unsupported OS" >&2; exit 1 ;;
esac

[ -r /etc/os-release ] || { echo "no /etc/os-release" >&2; exit 1; }
. /etc/os-release                       # defines ID, ID_LIKE, PRETTY_NAME ...

case "${ID:-unknown}" in
  debian|ubuntu|kali|linuxmint|raspbian|parrot) echo "sudo apt install $pkg" ;;
  rhel|centos|rocky|almalinux|fedora|ol)        echo "sudo dnf install $pkg" ;;
  arch|manjaro|endeavouros)                     echo "sudo pacman -S $pkg" ;;
  alpine)                                       echo "sudo apk add $pkg" ;;
  opensuse*|sles)                               echo "sudo zypper install $pkg" ;;
  *) echo "unknown distro '${ID:-?}' (ID_LIKE='${ID_LIKE:-}')" >&2; exit 1 ;;
esac
```
Sourcing `/etc/os-release` runs it as code: acceptable because it is root-owned; never `source` files from writable locations in privileged scripts.

## 4. Project: a restricted SSH "forced command" gate
Allow a remote key to run **only** three commands:
```bash
#!/bin/bash
# restricted.sh - allow-list for an SSH forced command (chapter 31)
case "${SSH_ORIGINAL_COMMAND:-}" in
  uptime)  uptime ;;
  "df -h") df -h ;;
  status)  systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo unknown ;;
  *)       echo "denied" >&2; exit 126 ;;
esac
```
Installed in the server's `~/.ssh/authorized_keys` like this (all on one line):
```
command="/usr/local/bin/restricted.sh",no-port-forwarding,no-pty,no-agent-forwarding,no-X11-forwarding ssh-ed25519 AAAA... backup-key
```
Anything the client types is available in `SSH_ORIGINAL_COMMAND`; the script decides. Each permitted branch runs a **fixed** command, so the client's text is never executed.

## 5. Log classifier with `case`
```bash
classify() {
  case "$1" in
    *"Failed password"*|*"Invalid user"*)    echo "auth-failure" ;;
    *"Accepted publickey"*|*"Accepted password"*) echo "auth-success" ;;
    *sudo*COMMAND=*)                         echo "privilege-use" ;;
    *)                                       echo "other" ;;
  esac
}
while IFS= read -r line; do printf '%-14s %s\n' "$(classify "$line")" "$line"; done < auth-sample.log | head
```

## 6. 🔐 Cyber relevance
- **Default deny is `case`'s superpower.** The final `*)` branch rejects everything you haven't explicitly allowed. This is the pattern for **allow-list gates**: command wrappers, restricted shells, sudo wrapper scripts, SSH forced commands, CI/CD tasks.
- **Never build commands from the matched text.** `eval "$cmd"` or `exec $SSH_ORIGINAL_COMMAND` after a loose `case` check lets an attacker append `; rm -rf ~`. Keep branches mapped to fixed commands and pass validated values as quoted arguments.
- **Glob ≠ regex:** `case` patterns like `*.log` match filenames with weird characters; `foo*` matches `foo; id`. Validate with anchored regexes (`[[ =~ ]]`) *before* using data.
- **Platform awareness for tooling:** the same script must detect Linux vs macOS, distro family, and package manager before acting (as in `pkg.sh`). Ansible/Chef-style hardening scripts do this constantly. Wrong assumptions (for example `apt` on RHEL) cause silent failure of security updates.
- **Event classification:** `case` is a neat way to map log lines to categories (auth failure, success, privilege use) for counting and alerting.
- **Quotes matter:** `case $x in "a b")` vs `a b)` differ; `*)` must be last.
- **Normalizing case before comparing** (`${var,,}` or `tr`) avoids bypasses like `YES`/`Yes`; but note locale and Unicode edge cases; for security decisions prefer exact-match allow-lists.
- **Restricted wrappers can be bypassed by environment**: forced-command scripts should set `PATH` explicitly and not trust other variables sent by the client (`AcceptEnv` in `sshd_config`, `LC_*`).
- **Audit trail:** log every allow/deny decision: `logger -t restricted "user=$USER cmd='${SSH_ORIGINAL_COMMAND:-}' result=denied"`.

## 7. Labs
**Easy**
1. Write a `case` that responds to `start`, `stop`, `status`, and anything else.
2. Convert the menu from chapter 28 from `if/elif` to `case`.
3. Make a script that says whether a filename ends in `.txt`, `.log`, or something else.

**Medium**
4. Run `pkg.sh` with `tree`, `htop`, and `nmap`; check the output matches your distro. Test an invalid name like `tree;id`.
5. Add a branch for `Linux` WSL detection by inspecting `/proc/version` for `microsoft`.
6. Write `yesno()` that accepts `y`, `Y`, `yes`, `YES` (using `shopt -s nocasematch` or `${var,,}`) and rejects the rest.

**Hard (cyber)**
7. Create `restricted.sh`, test it locally by setting the variable: `SSH_ORIGINAL_COMMAND="uptime" ./restricted.sh`, then with `"uptime; id"` and `"df -h"` (observe the deny). Document why `"uptime; id"` is not allowed.
8. Install a forced-command key on `localhost` in a lab VM (a **separate** key, restricted options) and prove the key can run `uptime` but not an interactive shell.
9. Build the log classifier and produce a count of each category: pipe `classify` results into `sort | uniq -c`.
10. Extend `pkg.sh` with a `--run` option (preview of chapter 32) that executes the command only if the user confirms by typing the package name; keep default dry-run.

## 8. Common mistakes
- Forgetting `;;` or the final `esac`
- Putting `*)` first (it matches everything)
- Expecting regex behavior
- Using `exec`/`eval` on the matched string
- Missing quotes around patterns with spaces

## 9. Quiz
1. What does `*)` do?
2. How do you match several values in one branch?
3. Why is `case` good for allow-lists?
4. Are `case` patterns regex or globs?
5. Why is `exec $SSH_ORIGINAL_COMMAND` after a loose check risky?

<details><summary>Answers</summary>

1. It is the default branch that matches anything not matched earlier.
2. Separate patterns with `|`.
3. Anything not listed falls into the deny/default branch.
4. Globs.
5. The attacker's string is executed as code (command injection).
</details>

## 10. Mastery checklist
- [ ] I replace `if/elif` chains with `case` where appropriate
- [ ] I write allow-list gates with a default-deny branch
- [ ] I detect OS/distro and choose tools accordingly
- [ ] I never execute the matched text

## Next → `32-positional-parameters.md`
