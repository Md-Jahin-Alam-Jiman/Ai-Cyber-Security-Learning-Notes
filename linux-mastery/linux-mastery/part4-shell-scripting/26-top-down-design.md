# Chapter 26 · Top-Down Design
📖 Book: Part IV, pp. 351–360 · ⏱ ~90 min · Prereq: Chapter 25

## Learning goals
- Design a script from the top down: outline first, details later
- Write and call **shell functions**; use **local** variables and return values
- Use **stubs** to test the skeleton
- Follow a clean `main` structure

## 1. Concepts
**Top-down design:** break a big task into steps, name each step as a function, and fill them in one by one.
```
triage.sh
├── report_identity
├── report_uptime
├── report_disk
├── report_users
├── report_processes
├── report_network
└── report_suid
```
| Item | Syntax | Notes |
|---|---|---|
| Function | `name() { commands; }` | POSIX form; also `function name { ... }` in bash |
| Call | `name arg1 arg2` | Arguments appear as `$1`, `$2`, `$@` inside |
| Local variable | `local x="..."` | Keeps variables inside the function (bash/zsh/ash; not strict POSIX) |
| Return value | `return N` | Status code 0–255; output is passed by `echo`/`printf` and captured with `$(func)` |
| Order | Define before first use | Functions are read top to bottom |
| Stub | `report_disk() { echo "report_disk called" >&2; }` | Placeholder to test structure |
| `main` pattern | `main() { ...; }` then `main "$@"` | Easy to read and test |

## 2. The project: `triage.sh`
```bash
#!/usr/bin/env bash
# triage.sh - read-only host triage report (chapter 26: functions, top-down)
# Usage: ./triage.sh            (prints report and saves a timestamped copy)
umask 077
readonly TS="$(date -u +%FT%TZ)"
readonly OUT="triage-$(hostname)-$(date -u +%Y%m%dT%H%M%SZ).txt"

section() { printf '\n== %s ==\n' "$1"; }

report_identity() {
  section "Identity"
  echo "Time (UTC): $TS"
  echo "Host      : $(hostname)"
  echo "Kernel    : $(uname -a)"
  id
}
report_uptime()    { section "Uptime";            uptime; }
report_disk()      { section "Disk usage";        df -h; }
report_users() {
  section "Logged in / recent logins"
  who
  echo "--"
  last -n 5 2>/dev/null
}
report_processes() {
  section "Top 5 processes by memory"
  ps -eo pid,user,%mem,comm | sort -k3 -nr | head -6
}
report_network() {
  section "Listening sockets"
  ss -tuln 2>/dev/null || netstat -an | grep LISTEN
}
report_suid() {
  section "SUID files in standard locations"
  find /usr/bin /usr/sbin /bin /sbin -xdev -perm -4000 -type f 2>/dev/null
}

main() {
  report_identity
  report_uptime
  report_disk
  report_users
  report_processes
  report_network
  report_suid
}

main | tee "$OUT"
echo "Saved to $OUT" >&2
```
`ss ... || netstat ...` means "if the first command fails, run the second" (explained in chapter 27).

**Stub-first workflow:** start with functions that only `echo "name called"`, run, and confirm the order. Then replace stubs one at a time and test each.

**Function arguments and `local`:**
```bash
check_file() {            # usage: check_file /path
  local path="$1"
  [ -e "$path" ] && echo "exists: $path" || echo "missing: $path"
}
check_file /etc/passwd
```
**Returning data:** `size=$(get_size "$f")` captures what the function prints; `if is_root; then` uses its exit status.

## 3. 🔐 Cyber relevance
- **Functions make audits modular and reviewable:** one function per check ("SSH config", "world-writable files", "SUID drift") means you can test, reuse, and extend them like a library of controls.
- **Local variables prevent cross-contamination:** a variable accidentally reused in two functions can silently change behavior, a classic bug class in long scripts.
- **Functions override commands, so be careful:** defining `ls() { ... }` or `sudo() { ... }` in a profile can hijack commands (a known persistence/credential-theft trick). Inspect with `type -a name` and `declare -f name` / `declare -F`. In your own scripts, call external programs with absolute paths or `command name` when you must bypass functions/aliases.
- **Least privilege by design:** keep privileged actions in small, separate functions (or separate scripts), validate input before using them, and run the rest as a normal user. Check privileges explicitly:
  ```bash
  require_root() { [ "$(id -u)" -eq 0 ] || { echo "Run as root" >&2; exit 1; }; }
  ```
- **Fail loudly, log clearly:** write errors to **stderr** (`>&2`) with timestamps; return meaningful exit codes so cron/CI can alert.
- **Library files:** `source ./lib.sh` is powerful and dangerous; never source files from writable or untrusted locations (that is code execution). Check ownership/permissions of anything you source in privileged scripts.
- **Testability:** modular checks let you add unit-style tests in a lab and detect regressions, which matters when scripts protect production.
- **Report ordering:** put cheap, high-value checks first (identity, listening ports); slow ones (full-disk `find`) last, so partial output still helps if the run is interrupted.

## 4. Labs
**Easy**
1. Write stubs for all functions, run the script, and verify the order.
2. Implement `report_identity` and `report_uptime` and test.
3. Write a function `say_hello name` that prints `Hello, name` using a local variable.

**Medium**
4. Complete `triage.sh`. Run it as a normal user and as root (`sudo ./triage.sh`); compare what each can see.
5. Write `is_root` (returns 0 if root) and use it: `if is_root; then ...` (preview of chapter 27).
6. Add `report_cron` that lists `crontab -l` and files in `/etc/cron*` (hide errors, print "none" if empty).

**Hard (cyber)**
7. Add `report_sudoers_users` (members of `sudo`/`wheel`: `getent group sudo wheel`) and `report_uid0` (`awk -F: '$3==0 {print $1}' /etc/passwd`).
8. Demonstrate function hijacking safely: define `ls() { echo "hijacked"; }`, show `type -a ls`, call `command ls`, then `unset -f ls`. Write 3 sentences on how you'd detect it in a startup file.
9. Add `report_recent_files` using `find /etc -xdev -type f -mtime -2 2>/dev/null | head -20`.
10. Make every function write its section to a variable or temp file, then print **only** sections that produced output. Explain the benefit for long reports.

## 5. Common mistakes
- Calling a function before defining it
- Forgetting `local` (variables leak)
- Using `exit` inside a function when you meant `return`
- Expecting `return` to hand back text (it returns a status code)
- Defining functions named like real commands by accident

## 6. Quiz
1. What is a stub?
2. How do you return text from a function?
3. Difference between `return` and `exit`?
4. Why use `local`?
5. How can functions help attackers' persistence?

<details><summary>Answers</summary>

1. A placeholder function used to test the structure before the details exist.
2. Print it and capture with `$(func)`.
3. `return` leaves the function; `exit` ends the whole script.
4. To keep variables from leaking into the global scope.
5. A function named like a command (`sudo`, `ls`) in a startup file can intercept or alter calls.
</details>

## 7. Mastery checklist
- [ ] I outline scripts as functions before writing details
- [ ] I use `local`, arguments, and return codes correctly
- [ ] I structure scripts with `main`
- [ ] I can detect function/alias hijacks

## Next → `27-flow-control-branching-with-if.md`
