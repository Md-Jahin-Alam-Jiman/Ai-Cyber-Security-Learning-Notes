# Chapter 28 · Reading Keyboard Input
📖 Book: Part IV, pp. 379–392 · ⏱ ~90 min · Prereq: Chapter 27

## Learning goals
- Read user input with `read` (prompts, silent input, timeouts, limits)
- Parse input into fields with `IFS`
- Validate input before using it
- Build an interactive, safe menu-driven tool

## 1. The `read` command (bash)
| Form | Meaning |
|---|---|
| `read var` | Read a line into `var` (default variable: `REPLY`) |
| `read -r var` | **Raw**: don't treat backslashes as escapes (**use always**) |
| `read -p "Prompt: " var` | Show a prompt (bash; zsh uses `read "var?Prompt: "`) |
| `read -s var` | Silent (no echo), for passwords |
| `read -t 10 var` | Timeout in seconds (status > 128 on timeout) |
| `read -n 1 var` | Read exactly N characters |
| `read -a arr` | Split into an array |
| `read a b c` | Split by `IFS` into several variables (the last gets the remainder) |
| `IFS=: read -r u x uid rest` | Use a different separator for this command only |
| `read -r var <<< "text"` | Read from a string (here string) |
POSIX-portable prompt: `printf 'Name: '; read -r name`.

```bash
read -r -p "Enter your name: " name
echo "Hello, $name"
read -r -s -p "Password: " pw; echo       # echo prints the newline the silent read swallowed
read -r -t 5 -p "Quick, 5 seconds: " ans || echo "too slow"
IFS=: read -r user x uid gid rest <<< "$(grep '^root:' /etc/passwd)"
echo "user=$user uid=$uid"
```
macOS bash 3.2: `-t` accepts only whole seconds and some newer options are missing.

## 2. Validation pattern
```bash
read -r -p "Enter a port (1-65535): " port
if [[ ! $port =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
  echo "Invalid port" >&2
  exit 1
fi
echo "Port $port accepted"
```
Order matters: check that it's numeric **before** doing arithmetic with it.

## 3. The project: `menu.sh`
```bash
#!/usr/bin/env bash
# menu.sh - interactive menu with validated input (chapter 28)
clear
cat <<_EOF_
System information menu
  1) System information
  2) Disk space
  3) Recent logins
  4) Listening ports
  0) Quit
_EOF_
read -r -p "Enter selection [0-4]: " selection

if [[ $selection =~ ^[0-4]$ ]]; then
  if   [[ $selection == 0 ]]; then echo "Bye."; exit 0
  elif [[ $selection == 1 ]]; then uname -a; uptime
  elif [[ $selection == 2 ]]; then df -h
  elif [[ $selection == 3 ]]; then last -n 10
  elif [[ $selection == 4 ]]; then ss -tuln 2>/dev/null || netstat -an | grep LISTEN
  fi
else
  echo "Invalid entry." >&2
  exit 1
fi
```
(In chapters 29 and 31 you'll make this menu loop and use `case`.)

## 4. 🔐 Cyber relevance
- **Input is the #1 attack surface.** Every `read`, argument, environment variable, filename, or log line is attacker-controlled until validated. Prefer **allow-list regexes** (`^[a-z_][a-z0-9_-]{0,31}$`), length limits, and canonicalization (`realpath`) before using input in commands or paths.
- **Never feed input to `eval`, `sh -c`, `bash -c`, or build commands by string concatenation.** That is **command injection**. Use arrays and quoted expansions: `grep -F -- "$term" file`, `useradd -- "$user"`. The `--` stops option injection if a value starts with `-`.
- **Always `read -r`:** without it, backslashes alter data; `-r` keeps what the user typed.
- **Secrets:** read with `-s`; never echo; don't pass as command-line arguments (visible in `ps`/history); `unset pw` after use; avoid writing to disk; prefer tools that read from stdin or a root-only file (`chmod 600`). Passing on stdin: `printf '%s' "$pw" | tool --password-stdin`.
- **Restore the terminal on abort.** With `-s`, if the user hits Ctrl+C the echo may stay off. Run `stty echo` or use `trap 'stty echo' EXIT`, or `reset`.
- **Timeouts prevent hangs** in automation and fail-closed behavior in "approve" prompts (`read -t 30 ... || exit 1`).
- **Confirmation for destructive actions:** require typing the target name, not just `y`:
  ```bash
  read -r -p "Type the hostname to confirm wipe: " c
  [[ $c == "$(hostname)" ]] || { echo "Aborted"; exit 1; }
  ```
- **Social-engineering resilience:** show exactly what will happen (paths, host, user) before asking to continue.
- **Prompt injection via filenames/logs:** if you print untrusted strings to a terminal, escape sequences can mislead the operator (chapter 21): use `printf '%q'` or `cat -v` to display safely.
- **Menu-driven admin tools** reduce operator error but must still authenticate and log who did what: `logger -t mytool "user=$(id -un) action=$selection"` writes to syslog.
- **zsh/macOS differences:** `read -p` means something else in zsh; scripts meant for both should use the portable `printf ...; read -r` form.

## 5. Labs
**Easy**
1. Ask for a name and greet the user. Use `read -r -p`.
2. Read two words into two variables with one `read`.
3. Use `read -t 5` and print a message when time runs out.

**Medium**
4. Write a script that asks for a directory, checks that it exists (`[ -d ]`), and prints its size with `du -sh` or "not found".
5. Build and run `menu.sh`; add an option 5 that shows your `id`.
6. Parse `/etc/passwd` entries with `IFS=: read -r user x uid gid comment home shell`: print the first line's fields (you'll loop through all lines in chapter 29).

**Hard (cyber)**
7. Validate a username with an allow-list regex and refuse anything else; test with `alice`, `bob_1`, `-rf`, `root;id`, and an empty string.
8. Write `ask_password.sh` that reads a password silently twice, compares them with `[[ ]]`, never prints them, and `unset`s the variables. Add `trap 'stty echo' EXIT`.
9. Demonstrate injection: write a bad script that does `eval "ls $dir"` and show what `dir='/tmp; id'` does in a lab; then fix it with `ls -- "$dir"`. Explain why the fix works.
10. Add logging to `menu.sh` with `logger -t menu "..."` and find the entries in `journalctl -t menu` or `/var/log/syslog`.

## 6. Common mistakes
- Forgetting `-r`
- Using `[ $var = x ]` with empty input
- Doing arithmetic on unvalidated strings
- Printing secrets or passing them as arguments
- Leaving the terminal in no-echo mode

## 7. Quiz
1. What does `read -r` prevent?
2. How do you read a password without showing it?
3. Why validate before arithmetic?
4. What does `--` do in `grep -- "$x" file`?
5. Why is `eval "ls $dir"` dangerous?

<details><summary>Answers</summary>

1. Backslash interpretation (mangling of the input).
2. `read -s`.
3. Non-numeric input causes errors or, in some contexts, unintended evaluation.
4. Ends option parsing, so a value beginning with `-` isn't treated as an option.
5. `$dir` is expanded into code, so `; id` becomes another command (injection).
</details>

## 8. Mastery checklist
- [ ] I read input safely (`-r`, `-s`, `-t`, `IFS`)
- [ ] I validate with allow-lists before use
- [ ] I never `eval` untrusted data; I use `--` and quoting
- [ ] I handle secrets and terminal state properly

## Next → Batch 2: `29-flow-control-looping-with-while-and-until.md`
