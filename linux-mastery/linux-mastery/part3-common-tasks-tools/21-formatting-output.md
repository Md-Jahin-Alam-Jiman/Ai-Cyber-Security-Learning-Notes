# Chapter 21 · Formatting Output (lighter chapter)
📖 Book: Part III, pp. 275–296 · ⏱ ~60 min · Prereq: Chapter 20

## Learning goals
- Format text for clear terminal and printed reports
- Use `nl`, `fold`, `fmt`, `pr`, `printf`, `column`, and a taste of `groff`
- Produce neat, evidence-ready report output

## 1. Command table
| Command | Purpose | Example |
|---|---|---|
| `nl` | Number lines | `nl -ba file` |
| `fold` | Hard-wrap lines | `fold -w 60 -s file` |
| `fmt` | Reflow paragraphs | `fmt -w 70 file` |
| `pr` | Paginate with headers | `pr -l 30 -w 80 -h "Report" file` |
| `column -t` | Align into a table | `column -t -s: /etc/passwd` |
| `printf` | Precise formatted output | `printf '%-15s %5d\n' name 42` |
| `expand` / `unexpand` | Tabs ↔ spaces | `expand -t4 file` |
| `less -S` | Scroll wide lines | `less -S wide.txt` |
| `groff` | Typesetting (man pages) | `groff -man -Tascii page.1 \| less` |
| `tee` | Display + save | `cmd \| tee out.txt` |

`printf` basics: `%s` string · `%d` integer · `%f` float · `%-10s` left-justify width 10 · `%5.2f` · `\n` newline. Always give a format string: `printf '%s\n' "$var"`.
`column` isn't installed on every minimal image (`bsdextrautils`/`util-linux`); macOS has a BSD `column` (use `-t`).

## 2. Walkthrough
```bash
cd ~/linux-lab && mkdir -p fm && cd fm
ls /etc | head -20 | nl
echo "A very long line of text that should be wrapped nicely at word boundaries for readability." | fold -w 30 -s
printf '%-12s %-8s %s\n' USER UID SHELL
awk -F: '$3>=1000 && $3<65534 {printf "%-12s %-8s %s\n", $1, $3, $7}' /etc/passwd
awk -F: '{print $1":"$3":"$7}' /etc/passwd | head | column -t -s:
ls -l /usr/bin | head -30 | pr -3 -t -w 120
printf 'Report generated: %s\n' "$(date -u +%FT%TZ)"
```

## 3. 🔐 Cyber relevance
- **Reports must be reproducible and readable.** Stamp them with UTC, host, and operator:
  ```bash
  printf '== Host report ==\nHost: %s\nUser: %s\nTime (UTC): %s\n\n' "$(hostname)" "$(whoami)" "$(date -u +%FT%TZ)"
  ```
- **Aligned tables** make findings obvious to reviewers: `printf` with widths or `column -t`. A table of `IP  FAILURES  SUCCESSES` is far better than raw `uniq -c`.
- **Wrapping can corrupt evidence:** `fold` and `fmt` alter line structure, so only use them on **copies** for presentation; keep raw logs untouched and hashed.
- **Untrusted text can attack your terminal.** Escape sequences in logs or filenames can change colors, titles, or hide text. Use `cat -v`, `less`, or `cat -A` to reveal them. Never `cat` unknown files in a privileged terminal.
- **`printf` format-string safety:** never pass untrusted data as the format (`printf "$input"`). Use `printf '%s\n' "$input"`. (A bug class in C programs and a bad habit in shell.)
- **CSV/TSV for hand-off:** use `printf '%s,%s,%s\n' ...` or `awk -v OFS=,` to produce CSVs that analysts can open in spreadsheets, but beware of spreadsheet formula injection: prefix cells starting with `= + - @` with a quote or strip them.
- **Man page style docs:** `groff -man` lets you ship tool docs. Lightweight alternative for reports: Markdown plus `pandoc` (`pandoc report.md -o report.pdf`; install `pandoc`).
- Wide tables: `column -t file | less -S`.

## 4. Labs
**Easy**
1. Number the lines of `/etc/services` (first 20) with `nl`.
2. Wrap a long sentence at 40 columns without breaking words.
3. Print a 3-column table with `printf`.

**Medium**
4. Turn `/etc/passwd` into an aligned table of user, UID, shell with `column -t`.
5. Use `pr` to paginate a file with a header and 20-line pages.
6. Print floats with `printf '%.2f\n' 3.14159`.

**Hard (cyber)**
7. Build a report header (host, user, UTC time, kernel) with `printf`, followed by a table of the top 5 processes by memory.
8. Produce a CSV of `IP,FAILURES` from the `auth.log` of chapter 20 and open or display it with `column -t -s,`.
9. Put an escape sequence into a file: `printf 'normal\033[31mred\033[0m\n' > esc.txt`; display with `cat`, `cat -v`, `less`. Explain why `cat -v` is safer for untrusted logs.
10. Show the unsafe `printf "$x"` with `x='%s%s%s'` versus the safe form, and explain.

## 5. Common mistakes
- Using `fold`/`fmt` on original evidence
- `printf` without `\n`
- Misaligned columns due to tabs (use `expand`)
- Printing untrusted data with a variable as the format string

## 6. Quiz
1. Which command aligns columns into a table?
2. `fold` vs `fmt`?
3. How do you right-pad a string to 12 chars in `printf`?
4. Why use `cat -v` on untrusted files?

<details><summary>Answers</summary>

1. `column -t`.
2. `fold` hard-wraps at a column width; `fmt` reflows paragraphs.
3. `%-12s`.
4. It displays control and escape characters visibly instead of interpreting them.
</details>

## 7. Mastery checklist
- [ ] I produce clean tables and stamped reports
- [ ] I keep originals untouched and format copies
- [ ] I handle escape sequences and `printf` safely

## Next → `22-printing.md`
