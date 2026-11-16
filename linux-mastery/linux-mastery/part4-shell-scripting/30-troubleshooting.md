# Chapter 30 · Troubleshooting
📖 Book: Part IV, pp. 401–414 · ⏱ ~90 min · Prereq: Chapter 29

## Learning goals
- Recognize syntax errors, logical errors, and defensive-programming gaps
- Trace and debug with `bash -x`, `set -x`, `PS4`, `trap`, and `shellcheck`
- Write scripts that fail safely
- Analyze unknown scripts without running them

## 1. Types of bugs
| Type | Example | Typical symptom |
|---|---|---|
| **Syntax** | Missing quote, `then`, `fi`, `;;` | `unexpected EOF`, `syntax error near...` |
| **Unexpected expansion** | Unquoted variable with spaces/globs | Wrong arguments, `too many arguments` |
| **Logical** | Wrong condition, off-by-one, wrong order | Script runs but gives the wrong answer |
| **Environment** | Relies on `PATH`, locale, GNU-only flags, bash-only syntax | Works on your machine, fails elsewhere |
| **Missing validation** | Empty variable, nonexistent directory | Deletes the wrong thing |

## 2. Tools
| Tool | Use |
|---|---|
| `bash -n script` | Parse only; find syntax errors |
| `bash -x script` / `set -x` … `set +x` | Trace each command after expansion |
| `bash -v script` | Print lines as read |
| `PS4='+ $LINENO: '` | Add line numbers to the trace |
| `shellcheck script` | Static analysis (best first step) |
| `echo`/`printf '%q\n' "$var"` | Show exactly what a variable holds |
| `trap 'cmd' ERR` / `EXIT` / `DEBUG` | Run code on failure/exit/each command |
| `set -u` | Error on unset variables |
| `set -e` / `set -o pipefail` | Exit on errors / failing pipeline stages (understand the caveats first) |
| `${var:?message}` | Abort with a message if `var` is unset/empty |
| `type`, `declare -f` | Inspect aliases/functions |
| `strace -f -e trace=file,network cmd` | See system calls (what files/sockets a script touches) |

```bash
#!/usr/bin/env bash
PS4='+ line $LINENO: '
set -u
trap 'echo "ERROR on line $LINENO (status $?)" >&2' ERR
set -x
name="World"
echo "Hello, $name"
false                       # triggers the ERR trap
set +x
```

## 3. The "bug museum": spot and fix
| # | Buggy code | Problem | Fix |
|---|---|---|---|
| 1 | `rm -rf $DIR/*` | If `DIR` is empty this becomes `rm -rf /*` | `rm -rf "${DIR:?DIR not set}"/*` |
| 2 | `cd "$d"; rm *` | If `cd` fails you delete in the wrong place | `cd "$d" \|\| exit 1` |
| 3 | `[ $name = bob ]` | Empty/space values break the test | `[ "$name" = bob ]` or `[[ $name == bob ]]` |
| 4 | `[$x -eq 1]` | Missing spaces: command `[1` not found | `[ "$x" -eq 1 ]` |
| 5 | `for f in $(ls *.txt)` | Splits on spaces; breaks on odd names | `for f in *.txt` |
| 6 | `cmd \| while read l; do n=$((n+1)); done` | `n` lost (subshell) | `done < <(cmd)` |
| 7 | `if [ $a > $b ]` | `>` is a redirection, creates a file named `$b` | `[ "$a" -gt "$b" ]` or `(( a > b ))` |
| 8 | `cat file \| grep x \| wc -l` (fine) but `grep -c x file` is simpler | Not a bug; style | Use fewer processes |
| 9 | `echo $line` | Collapses whitespace, expands globs | `printf '%s\n' "$line"` |
| 10 | `mkdir $dir && cd $dir \|\| echo failed` | `echo` also runs if `cd` fails for other reasons | Use `if` |

## 4. Defensive programming
- Validate inputs and preconditions at the start (`[ -d "$dir" ] || exit 2`)
- Quote everything; use `--` before user-supplied values
- Check the status of commands that matter (`cp a b || exit 1`)
- Use `mktemp`, `trap 'rm -rf "$tmp"' EXIT` for cleanup
- Prefer `printf` over `echo` for arbitrary data
- Test with **empty values, spaces, leading dashes, very long input, nonexistent files, and no permissions**
- Make destructive code dry-run by default (`--run` to act)
- Keep functions small; test them alone

### About `set -euo pipefail`
Helpful, but not magic: `set -e` is ignored inside `if` conditions and `&&/||` lists and surprises in subshells and functions; `set -u` breaks on unset positional parameters unless you use `${1:-}`; `pipefail` changes pipeline statuses (e.g. `grep -q` closing a pipe early can trigger `SIGPIPE` failures). Use deliberately, and test.

## 5. 🔐 Cyber relevance
- **Real incidents from tiny bugs:** the unquoted-empty-variable `rm -rf` pattern (#1) has wiped real systems and backups. `${VAR:?}` and `set -u` are cheap insurance. Build **guard rails** into any script that runs as root.
- **Debug output can leak secrets.** `set -x` prints expanded commands including passwords and tokens, and the trace goes to stderr and may land in logs/CI output. Wrap sensitive sections with `set +x`/`set -x`, or never trace secret-handling code.
- **Analyzing suspicious scripts safely (static first):**
  1. `file`, `head`, `wc`, `sha256sum` (record hash); open with `less` or `cat -v` (hidden escapes!)
  2. `bash -n` (does it parse?) and `shellcheck`
  3. `grep -nE 'eval|base64|curl|wget|/dev/tcp|nc |mkfifo|chmod \+x|crontab|authorized_keys|rm -rf|\\x[0-9a-f]{2}' file`
  4. **De-obfuscate without executing:** replace `eval`/`| bash` with `echo`/`cat` in a *copy* to print what would be executed; decode base64 with `base64 -d` into a file and inspect it
  5. Only then, dynamic analysis in an **isolated VM** with a snapshot, no network (or fake network), `strace -f -o trace.log bash script`, and `bash -x`
- **`PS4` for audit trails:** `PS4='+ $(date -u +%T) ${BASH_SOURCE:-main}:${LINENO}: '` timestamps every traced command. Useful for incident-response runbooks you want to review later (mind the secret-leak warning above).
- **Error handling = security control.** Scripts that "fail open" (continue after a failed permission change, ignore a failed `chown`) create vulnerabilities. For security-relevant operations check status and abort.
- **Exit codes feed detection:** nonzero statuses and `trap ... ERR` messages routed to syslog (`logger`) give you visibility when a hardening job silently breaks.
- **Race conditions & temp files:** non-reproducible bugs often hide TOCTOU issues; use `mktemp` and avoid predictable names.
- **Environment assumptions are attack surface:** scripts that rely on `PATH`, `IFS`, locale, or inherited variables can be manipulated by whoever controls those. For privileged scripts set `PATH`, `IFS=$' \t\n'`, `umask`, and `unset BASH_ENV ENV` explicitly.
- **Dynamic analysis tools:** `strace` (`-f` follow children, `-e trace=network` for connections, `-e trace=file` for file access), `ltrace`, `lsof -p PID`. Great for seeing what a script *really* does.

## 6. Labs
**Easy**
1. Create a script with a missing `fi`. Run `bash -n` and read the error.
2. Trace a three-line script with `bash -x`. Add `PS4='+ $LINENO: '`.
3. Install and run `shellcheck` on `triage.sh` (chapter 26). Fix every warning that applies.

**Medium**
4. Reproduce bugs #3, #4, #5, and #7 from the museum in a lab directory. Observe each symptom, then fix it.
5. Add `trap 'rm -rf "$tmp"' EXIT` to a script that creates a `mktemp -d` directory and verify cleanup even when the script fails midway.
6. Write a function `die() { echo "ERROR: $*" >&2; exit 1; }` and use it for preconditions.

**Hard (cyber)**
7. In a **lab directory**, write a "cleanup" script with the bug `rm -rf $DIR/*` where `DIR` is unset and the working directory contains test files; use `echo` instead of `rm` to show what would be deleted. Fix it with `${DIR:?}` and `set -u`.
8. Build a "suspicious" sample script (inert!) with `eval "$(echo ZWNobyBoZWxsbw== | base64 -d)"`. Without running it, decode the payload, then run only the harmless decoded `echo`. Document each step as in the static-analysis checklist.
9. Use `strace -f -e trace=file,network -o trace.log bash recon-lite.sh` and list the files it opened (`grep openat trace.log | head`). Explain what this technique tells an analyst.
10. Demonstrate secret leakage: `set -x; password=hunter2; echo "$password" > /dev/null; set +x`. Show the leak in the trace and rewrite the code so the secret never appears.

## 7. Common mistakes
- Debugging by guessing instead of tracing
- Leaving `set -x` on in production
- Using `set -e` without understanding its exceptions
- Ignoring `shellcheck` warnings
- Not testing with awkward input (spaces, empty, `-`)

## 8. Quiz
1. What does `bash -n` do?
2. Why is `rm -rf $DIR/*` dangerous?
3. How do you show line numbers in a trace?
4. What's the risk of `set -x` with secrets?
5. Give two safe-first steps for analyzing an unknown script.

<details><summary>Answers</summary>

1. Checks syntax without executing the script.
2. An empty/unset `DIR` expands to `rm -rf /*`; word splitting can also add extra paths.
3. Set `PS4='+ $LINENO: '` (or `${BASH_SOURCE}:${LINENO}`).
4. Expanded commands (with the secret values) are printed to stderr/logs.
5. Hash it and read it with `less`/`cat -v`; run `bash -n`/`shellcheck`; grep for risky idioms; de-obfuscate by printing instead of executing.
</details>

## 9. Mastery checklist
- [ ] I debug with `-n`, `-x`, `PS4`, `trap`, and `shellcheck`
- [ ] I use guard rails (`${var:?}`, `set -u`, `|| exit`)
- [ ] I can statically analyze an unknown script without running it
- [ ] I don't leak secrets in traces or logs

## Next → `31-flow-control-branching-with-case.md`
