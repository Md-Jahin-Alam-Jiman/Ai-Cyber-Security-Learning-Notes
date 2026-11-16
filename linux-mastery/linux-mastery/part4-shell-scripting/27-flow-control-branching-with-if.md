# Chapter 27 · Flow Control: Branching with `if`
📖 Book: Part IV, pp. 361–378 · ⏱ ~120 min · Prereq: Chapter 26 · **Scripts start making decisions**

## Learning goals
- Understand exit status and how `if` uses it
- Use `test`, `[ ]`, `[[ ]]`, and `(( ))` correctly
- Combine conditions with `&&`, `||`, `!`
- Write a security-audit script that decides pass/fail

## 1. Exit status
Every command ends with a status: **0 = success/true**, non-zero = failure/false. `$?` holds the last one.
```bash
ls /etc/passwd; echo $?      # 0
ls /nonexistent 2>/dev/null; echo $?   # 2 (or 1)
```
`if` runs the *command*; if its status is 0, the `then` branch runs:
```bash
if grep -q '^root:' /etc/passwd; then
  echo "root entry found"
elif [ -e /etc/passwd ]; then
  echo "file exists but no root entry"
else
  echo "no passwd file"
fi
```
`grep -q` is quiet and only sets status: ideal inside `if`.

## 2. Tests
**`[ ... ]` (POSIX `test`):** spaces required inside brackets; quote variables.
| File tests | Meaning |
|---|---|
| `-e f` / `-f f` / `-d f` | Exists / regular file / directory |
| `-r f` / `-w f` / `-x f` | Readable / writable / executable by you |
| `-s f` | Exists and size > 0 |
| `-L f` | Is a symlink |
| `f1 -nt f2` / `-ot` | Newer / older than |

| String tests | Meaning |
|---|---|
| `-z "$s"` / `-n "$s"` | Empty / non-empty |
| `"$a" = "$b"` / `!=` | Equal / not equal (`[ ]` uses a single `=`) |

| Integer tests | Meaning |
|---|---|
| `-eq -ne -lt -le -gt -ge` | `[ "$n" -gt 5 ]` |

**`[[ ... ]]` (bash/zsh/ksh, not POSIX `sh`):** safer with unquoted variables, supports `==` pattern match (`[[ $f == *.log ]]`), regex `=~` (`[[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]]`), and `&&`/`||` inside.
**`(( ... ))` (bash):** arithmetic: `if (( count > 3 )); then`.

**Logical operators**
| Form | Meaning |
|---|---|
| `! cmd` | Negate |
| `cmd1 && cmd2` | Run `cmd2` only if `cmd1` succeeded |
| `cmd1 \|\| cmd2` | Run `cmd2` only if `cmd1` failed |
| `[ a ] && [ b ]` | AND (preferred over `-a` in `[ ]`) |
| `{ cmd1; cmd2; }` | Group commands |
```bash
mkdir -p dir && cd dir || exit 1     # careful: A && B || C is not a strict if/else
[ -f /etc/hostname ] && echo "has hostname file"
```
**Exit codes in your own scripts:** `exit 0` (OK), `exit 1` (general error), `exit 2` (misuse). Document them.

## 3. The project: `perm-audit.sh`
```bash
#!/usr/bin/env bash
# perm-audit.sh - read-only baseline checks (chapter 27)
FAILS=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }
skip() { printf 'SKIP  %s\n' "$1"; }

# Portable file-mode helper: GNU stat first, then BSD/macOS stat
mode_of() { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null; }

# 1. /etc/shadow must not be accessible to "others"
if [ -e /etc/shadow ]; then
  m="$(mode_of /etc/shadow)"
  if [ "${m: -1}" = "0" ]; then pass "/etc/shadow not accessible to others (mode $m)"
  else fail "/etc/shadow is accessible to others (mode $m)"; fi
else
  skip "/etc/shadow not present on this OS"
fi

# 2. SSH root login must not be explicitly enabled
cfg=/etc/ssh/sshd_config
if [ -r "$cfg" ]; then
  if grep -Eqi '^[[:space:]]*PermitRootLogin[[:space:]]+yes' "$cfg"; then
    fail "SSH PermitRootLogin yes"
  else
    pass "SSH root login not explicitly enabled"
  fi
else
  skip "$cfg missing or unreadable"
fi

# 3. SSH password authentication (informational)
if [ -r "$cfg" ] && grep -Eqi '^[[:space:]]*PasswordAuthentication[[:space:]]+no' "$cfg"; then
  pass "SSH password authentication disabled"
elif [ -r "$cfg" ]; then
  fail "SSH password authentication not disabled (key-only login recommended)"
fi

# 4. ~/.ssh permissions
if [ -d "$HOME/.ssh" ]; then
  m="$(mode_of "$HOME/.ssh")"
  if [ "$m" = "700" ]; then pass "~/.ssh mode is 700"; else fail "~/.ssh mode is $m (should be 700)"; fi
else
  skip "no ~/.ssh directory"
fi

# 5. Running as root? (warn, because audits should be least-privilege where possible)
if [ "$(id -u)" -eq 0 ]; then echo "NOTE  running as root"; fi

# 6. Only root should have UID 0
extra="$(awk -F: '$3==0 && $1!="root" {print $1}' /etc/passwd)"
if [ -z "$extra" ]; then pass "no extra UID-0 accounts"; else fail "extra UID-0 accounts: $extra"; fi

echo "----"
echo "Failures: $FAILS"
[ "$FAILS" -eq 0 ]          # exit status = 0 if no failures
```
`[ "$FAILS" -eq 0 ]` as the last command makes the script exit 0 when clean, 1 when not: perfect for cron/CI alerts.

## 4. 🔐 Cyber relevance
- **Compliance-as-code:** scripts like this are miniature versions of CIS benchmark checks, Lynis, and OpenSCAP: each check is *test → PASS/FAIL → evidence*. Extend yours to cover password aging (`/etc/login.defs`), `PermitEmptyPasswords`, firewall state, and world-writable files.
- **Quote and test defensively:** an unset or empty variable inside `[ ]` can change meaning: `[ $x = y ]` with empty `x` becomes `[ = y ]` (syntax error), and values with spaces split. Use `[ "$x" = "y" ]` or `[[ ]]`. Consider `set -u` to catch unset variables.
- **Allow-list input validation:** validate before use. Example: only accept usernames matching `^[a-z_][a-z0-9_-]{0,31}$`:
  ```bash
  if [[ ! $user =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then echo "invalid user" >&2; exit 2; fi
  ```
  Prefer **allow-lists** (what is valid) over deny-lists (what is bad).
- **TOCTOU races:** "check, then use" gaps (`if [ -f "$f" ]; then cat "$f"`) can be exploited if an attacker swaps the file or symlink between steps. Mitigations: operate on a private directory, use `mktemp`, open once and read from the descriptor, avoid following symlinks in privileged contexts (`-L` check, `readlink -f`, `realpath`).
- **Exit codes for detection pipelines:** your script's status can trigger alerts (cron `MAILTO`, systemd `OnFailure=`, CI). Return distinct codes for "critical finding" vs "tool error."
- **`A && B || C` pitfalls:** `C` also runs if `B` fails. For security decisions use a real `if/then/else`.
- **`-w`/`-r`/`-x` tests reflect *your* privileges.** Running as root, `-w` is true almost everywhere. Use `stat` to examine actual modes in audits.
- **Case matters on file systems** but not on some (macOS default APFS is case-insensitive); validate paths with care.
- **Don't parse `ls`:** use globs, `find`, or `stat` for file attributes.

## 5. Labs
**Easy**
1. Write `if [ -f /etc/passwd ]; then ...; else ...; fi`. Then test a nonexistent file.
2. Print the exit status of `grep -q root /etc/passwd` and `grep -q nonesuch /etc/passwd`.
3. Write a script that says whether a number given in a variable is greater than 10.

**Medium**
4. Write a script that checks whether `/etc/passwd`, `/etc/shadow`, and `/etc/hosts` exist and are readable by you; print a clear line for each.
5. Rewrite one `[ ]` test as `[[ ]]` and one as `(( ))`.
6. Check whether a string matches a pattern: `[[ $file == *.log ]]` and a regex: `[[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]]`.

**Hard (cyber)**
7. Run `perm-audit.sh`. Deliberately create a failure in a lab copy (for example a file with mode 777), observe the FAIL, fix it, and show the exit status with `echo $?`.
8. Add three checks of your own: (a) `/etc/passwd` is not world-writable, (b) no files under `/tmp` are SUID (use `find`; empty output means pass), (c) `ufw status`/`firewall-cmd --state` reports an active firewall (skip if the tool isn't installed).
9. Write `is_valid_ip()` using a regex and arithmetic to ensure every octet ≤ 255; test with `203.0.113.5`, `999.300.1.1`, and `1.2.3`.
10. Demonstrate a TOCTOU pattern in a lab (check file, then replace it with a symlink before use) and describe how you'd fix it.

## 6. Common mistakes
- No spaces inside `[ ]` (`[$x=y]`)
- Using `=` vs `-eq` wrongly (string vs number)
- Unquoted variables in `[ ]`
- `>` and `<` inside `[ ]` act as redirection (use `[[ ]]` or `\<`)
- Forgetting `then` or `fi`

## 7. Quiz
1. What exit status means success?
2. Why is `grep -q` handy in `if`?
3. `[ ]` vs `[[ ]]`?
4. Why can `A && B || C` mislead?
5. What is a TOCTOU bug?

<details><summary>Answers</summary>

1. 0.
2. It stays silent and only returns a status.
3. `[ ]` is POSIX and needs careful quoting; `[[ ]]` is a bash/zsh keyword with safer parsing, patterns, and regex.
4. `C` runs whenever `A` fails **or** `B` fails.
5. Time-of-check to time-of-use: the state changes between checking and using a resource.
</details>

## 8. Mastery checklist
- [ ] I use exit status and `if/elif/else` fluently
- [ ] I choose the right test (`[ ]`, `[[ ]]`, `(( ))`)
- [ ] I write PASS/FAIL checks with meaningful exit codes
- [ ] I validate input with allow-lists and know TOCTOU basics

## Next → `28-reading-keyboard-input.md`
