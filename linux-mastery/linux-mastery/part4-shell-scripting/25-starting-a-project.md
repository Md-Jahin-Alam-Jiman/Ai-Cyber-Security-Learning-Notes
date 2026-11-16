# Chapter 25 · Starting a Project
📖 Book: Part IV, pp. 337–349 · ⏱ ~90 min · Prereq: Chapter 24

## Learning goals
- Build a script in small, tested steps (a *project*)
- Use variables and constants; assign values with command substitution
- Use **here documents** to output blocks of text
- Generate a text/HTML system report safely

## 1. Concepts
| Topic | Syntax | Notes |
|---|---|---|
| Variable | `name="value"` | No spaces around `=`; use `"$name"` |
| Constant | `readonly NAME="value"` | Can't be changed or unset; use UPPERCASE by convention |
| Command substitution | `now="$(date -u +%FT%TZ)"` | Capture output |
| Default | `"${var:-default}"` | Use `default` when `var` is unset/empty |
| Arithmetic | `n=$((n + 1))` | |
| Here document | `cat <<EOF ... EOF` | Multi-line text; variables and `$(...)` **are expanded** |
| Quoted here doc | `cat <<'EOF' ... EOF` | **No** expansion; literal text |
| Indented here doc | `cat <<-EOF` | Strips leading **tabs** (not spaces) |
| Here string | `cmd <<< "text"` | Feed a string to stdin (bash/zsh) |

**Naming:** letters, digits, underscore; can't start with a digit. Lowercase for ordinary variables, UPPERCASE for constants/environment. Avoid names of real environment variables (`PATH`, `HOME`, `USER`) unless you mean them.

## 2. Build it in steps: `triage-v1.sh`
**Step 1: Text report with a here document**
```bash
#!/usr/bin/env bash
# triage-v1.sh - text system report (chapter 25)
readonly TITLE="Triage report for $(hostname)"
readonly TS="$(date -u +%FT%TZ)"
readonly OPERATOR="${USER:-unknown}"     # USER can be unset in cron

cat <<_EOF_
$TITLE
==============================
Generated (UTC): $TS
Operator       : $OPERATOR
Kernel         : $(uname -sr)
Uptime         : $(uptime)
_EOF_
```
**Step 2: Make it an HTML report**
```bash
#!/usr/bin/env bash
# triage-html-v1.sh - HTML report with escaped command output
readonly TITLE="Triage report for $(hostname)"
readonly TS="$(date -u +%FT%TZ)"

# Escape HTML special characters in untrusted/command output
html_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

cat <<_EOF_
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>$TITLE</title></head>
<body>
<h1>$TITLE</h1>
<p>Generated (UTC): $TS</p>
<h2>Uptime</h2>
<pre>$(uptime | html_escape)</pre>
<h2>Disk</h2>
<pre>$(df -h | html_escape)</pre>
<h2>Logged-in users</h2>
<pre>$(who | html_escape)</pre>
</body>
</html>
_EOF_
```
Run: `bash triage-html-v1.sh > report.html` and open in a browser.
(Here, `html_escape` is a **function**, a preview of chapter 26.)

**Quoted here doc (no expansion) example**
```bash
cat <<'EOT'
The variable $HOME and the command $(whoami) are printed literally.
EOT
```

## 3. 🔐 Cyber relevance
- **Reports are evidence.** Include UTC timestamp, hostname, operator, script name and version, and the hash of the script. A consistent report format makes cases comparable and auditable.
- **Escape untrusted data.** Log lines, filenames, usernames, and process names can contain `<script>` or other markup. Putting them unescaped into HTML creates **stored XSS** in your own report. Always escape (`html_escape`) or avoid HTML (use plain text/CSV/Markdown).
- **Here-document injection:** in an *unquoted* here document, `$(...)` and backticks **execute**. If untrusted text is inserted into the *template* (rather than a variable's value) it can run commands. Use `<<'EOF'` for static text and pass data through variables.
- **Constants for safety:** `readonly` protects values such as output paths or tool locations from accidental (or injected) modification in long scripts.
- **Don't embed secrets.** Not in variables in scripts, not in here-docs, not in reports. Use `read -s` (chapter 28) or protected files with mode 600.
- **Collection scope and privacy:** a triage script gathers sensitive data (users, processes, network). Restrict the output file's permissions (`umask 077`), document what is collected, and follow legal and policy requirements.
- **Idempotent, read-only collectors:** a good triage script **does not change** the system (no installs, no deletes). Use read-only commands and write only to your evidence directory (preferably on external media).
- **Anti-forensics awareness:** attackers' scripts often wipe history, modify timestamps, or disable logging. Compare your report with other sources (`journalctl`, `last`, `/var/log`).
- **Defanging in reports:** reuse the `sed` defang pattern when including IPs/URLs.

## 4. Labs
**Easy**
1. Write `triage-v1.sh`, run it, and save the output to a file with `tee`.
2. Add three more facts using command substitution (for example: `whoami`, `id -u`, `uname -m`).
3. Make `TITLE` a `readonly` constant and try to change it later in the script. Read the error.

**Medium**
4. Build `triage-html-v1.sh`, generate `report.html`, and view it in a browser.
5. Show the difference between `<<EOF` and `<<'EOF'` with `$HOME` and `$(date)` inside.
6. Use `${1:-output.txt}` to choose a default output name when no argument is given.

**Hard (cyber)**
7. Put `<script>alert(1)</script>` into a filename in a test directory (`touch '<script>alert(1)</script>'`), list it inside the HTML report **without** escaping, view it, then fix with `html_escape`. Explain the risk.
8. Add the script's own SHA-256 to the report (`sha256sum "$0"`) and a line stating the operator and UTC time.
9. Add a "listening ports" section (`ss -tuln` or `netstat -an | grep LISTEN`) and a "recent logins" section (`last -n 5`).
10. Make the report file private: `umask 077` at the top, generate it, then verify permissions with `ls -l`.

## 5. Common mistakes
- Spaces around `=` (`x = 5` runs a command named `x`)
- Forgetting quotes: `$var` with spaces/globs
- Using `<<-` with spaces instead of tabs
- The ending marker (`_EOF_`) not alone at the start of its line
- Inserting raw command output into HTML

## 6. Quiz
1. How do you make a constant?
2. Difference between `<<EOF` and `<<'EOF'`?
3. What does `${var:-x}` do?
4. Why escape HTML in reports?
5. Why should collectors be read-only?

<details><summary>Answers</summary>

1. `readonly NAME=value`.
2. The first expands variables and `$(...)`; the second prints text literally.
3. Uses `x` when `var` is unset or empty.
4. Untrusted data may contain markup/script (XSS).
5. To avoid altering evidence or the system state.
</details>

## 7. Mastery checklist
- [ ] I build scripts incrementally and test every step
- [ ] I use variables, constants, and here documents correctly
- [ ] I escape untrusted data in generated documents
- [ ] My reports include provenance (who/what/when/hash)

## Next → `26-top-down-design.md`
