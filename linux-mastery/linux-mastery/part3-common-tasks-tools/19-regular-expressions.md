# Chapter 19 · Regular Expressions
📖 Book: Part III, pp. 227–243 · ⏱ ~120 min · Prereq: Chapter 18 · **Core analyst skill**

## Learning goals
- Read and write regular expressions (regex) for `grep`
- Know BRE vs ERE and when to use `grep -E`
- Extract IPs, hashes, users and other indicators from text
- Avoid regex traps (over-matching, false validation, ReDoS)

## 1. `grep` options you'll use daily
| Option | Meaning |
|---|---|
| `-i` | Ignore case |
| `-v` | Invert (lines that do **not** match) |
| `-c` | Count matching lines |
| `-n` | Show line numbers |
| `-o` | Print only the matched part |
| `-l` / `-L` | Files with / without matches |
| `-w` | Match whole words |
| `-r` | Recursive (`-R` follows symlinks) |
| `-E` | Extended regex (ERE); same as the old `egrep` |
| `-F` | Fixed string, no regex (fast and safe) |
| `-A n` / `-B n` / `-C n` | Context lines after / before / around |
| `-P` | Perl regex (GNU grep only; macOS: `brew install grep` → `ggrep`) |

## 2. The building blocks
| Syntax | Meaning |
|---|---|
| `.` | Any single character |
| `^` / `$` | Start / end of line |
| `[abc]` | One of a, b, c |
| `[^abc]` | Any character **except** a, b, c |
| `[a-z]` `[0-9]` | Ranges (locale-sensitive; prefer classes) |
| `[[:digit:]]` `[[:alpha:]]` `[[:alnum:]]` `[[:upper:]]` `[[:lower:]]` `[[:space:]]` `[[:punct:]]` | POSIX classes |
| `\` | Escape a metacharacter (`\.` is a literal dot) |

**ERE (`grep -E`) additions**
| Syntax | Meaning |
|---|---|
| `x?` | Zero or one |
| `x*` | Zero or more |
| `x+` | One or more |
| `x{3}` `x{2,5}` `x{3,}` | Exact / range / at least |
| `(ab)+` | Grouping |
| `a\|b` (written `a|b` in ERE) | Alternation |

**BRE (plain `grep`)**: `?`, `+`, `{}`, `()`, `|` are literal unless escaped (GNU: `\?`, `\+`, `\{ \}`, `\( \)`, `\|`). Just use `grep -E` to stay sane.
**Metacharacters that need escaping to be literal:** `^ $ . [ ] { } ( ) * + ? | \`. Inside `[...]` most lose special meaning.

## 3. Guided walkthrough
Create a test file (the IPs are from reserved documentation ranges, so they're safe):
```bash
cd ~/linux-lab && mkdir -p rx && cd rx
cat > data.txt <<'EOT'
alice@example.com logged in from 203.0.113.5
BOB@Example.org failed login from 198.51.100.23
Phone: (555) 123-4567, backup 555-987-6543
md5: d41d8cd98f00b204e9800998ecf8427e
sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
url: https://example.com/login?user=admin&pass=1234
invalid IP: 999.300.1.1
Failed password for invalid user admin from 203.0.113.5 port 4242 ssh2
EOT
grep -n 'login' data.txt
grep -i 'bob' data.txt
grep -E '^[[:alpha:]]+@' data.txt
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' data.txt
grep -Eo '[[:alnum:]._-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}' data.txt
grep -E '\(?[0-9]{3}\)?[ -][0-9]{3}-[0-9]{4}' data.txt
grep -Eo '\b[a-f0-9]{32}\b' data.txt           # MD5-looking strings
grep -Eo '\b[a-f0-9]{64}\b' data.txt           # SHA-256-looking strings
grep -Eo 'https?://[^ ]+' data.txt
grep -Ev '^(md5|sha256|url)' data.txt
```

## 4. 🔐 Cyber relevance
**Indicators of compromise (IOC) extraction**
| Pattern (ERE) | Finds |
|---|---|
| `([0-9]{1,3}\.){3}[0-9]{1,3}` | IPv4-looking strings |
| `\b[a-fA-F0-9]{32}\b` / `{40}` / `{64}` | MD5 / SHA-1 / SHA-256 |
| `https?://[^ "'<>]+` | URLs |
| `[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}` | Emails |
| `Failed password for (invalid user )?[^ ]+` | SSH failures with username |
| `(\.\./){2,}` | Path traversal attempts in web logs |
| `(union.*select|<script|%3Cscript)` (use `-i`) | Naive SQLi/XSS probes |
| `[A-Za-z0-9+/]{40,}={0,2}` | Long base64-like blobs |

**Typical one-liners**
```bash
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' access.log | sort | uniq -c | sort -nr | head     # top IPs
grep -Ei '(\.\./|%2e%2e%2f|union.*select|<script)' access.log                             # suspicious web requests
grep -rIlE 'BEGIN (RSA|OPENSSH|EC) PRIVATE KEY' /home /srv 2>/dev/null                   # leaked private keys
grep -rIn --include='*.{conf,env,yml,yaml}' -E '(password|passwd|secret|token)[[:space:]]*[=:]' /etc 2>/dev/null
```
**Traps**
- **Regex ≠ validation.** The IP pattern also matches `999.300.1.1`. Use it to *find candidates*, then validate (e.g. with a script or `ipcalc`). Anchors and context lower false positives.
- **Over-matching `.`:** `192.168.1.1` as regex also matches `192x168y1z1`. Escape dots: `192\.168\.1\.1` (or use `grep -F`).
- **Greedy matching:** `.*` takes as much as possible. Use `[^ ]*` or similar to stop at delimiters.
- **ReDoS:** nested quantifiers like `(a+)+$` can make some regex engines (PCRE, JavaScript, Python) take exponential time on crafted input; a known DoS technique against web apps and WAFs. GNU `grep -E` is far more resilient, but don't expose user-controlled regex to a backtracking engine.
- **User-supplied patterns:** use `grep -F` or `--` and quote; never place unsanitized input into `grep -P`.
- **Case and encoding:** attackers vary case, encoding (`%2e`), and whitespace. Use `-i` and consider normalizing first.
- **Locale:** ranges like `[a-z]` can behave unexpectedly under some locales; set `LC_ALL=C` for byte-wise behavior or use POSIX classes.
- Regex dialects differ: grep BRE/ERE, `sed`, `awk`, PCRE (`grep -P`, Python `re`, Splunk, Elastic, YARA). Learn the ideas once, then check each tool's syntax.
- **Platform:** macOS/BSD `grep` supports `-E`, `-o`, `-r` but not `-P`; BusyBox grep (Alpine) supports `-E` and `-o` but not `-P` (`apk add grep` for GNU).

## 5. Labs
Use `~/linux-lab/rx/data.txt` from the walkthrough.

**Easy**
1. List lines containing `login` and show line numbers.
2. Show lines that begin with a capital letter.
3. Show only the lines that do **not** contain `http`.

**Medium**
4. Extract all email addresses (case-insensitive).
5. Extract all phone numbers in both formats.
6. Show only the 32-character hex hash and the 64-character hash, one per command.

**Hard (cyber)**
7. Extract all IPv4 candidates, then explain which one is invalid and why a regex alone can't catch it. Then write a stricter regex for the 0–255 octet: `(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})`. Use it in `grep -Eo '\b((25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\b'`. Test whether it rejects `999.300.1.1`.
8. Search your own `/etc` for lines that assign something like a password or token (`grep -rIn -E '(password|secret|token)\s*=' /etc 2>/dev/null`). Report which look sensitive.
9. Build a mini-detector: a file `ioc-patterns.txt` with 5 ERE patterns (one per line). Run `grep -Ef ioc-patterns.txt data.txt` and show which lines match.
10. Experiment safely with a greedy pattern: `echo 'a="x" b="y"' | grep -Eo '".*"'` vs `grep -Eo '"[^"]*"'`. Explain the difference.

## 6. Common mistakes
- Forgetting `-E` and wondering why `+` or `|` doesn't work
- Unescaped dots
- Forgetting to quote the pattern (the shell eats `*`, `?`, `|`)
- Treating regex matches as proof (false positives/negatives)
- Using `.*` where a negated class is better

## 7. Quiz
1. `^` and `$` mean what?
2. What does `[^0-9]` match?
3. Difference between `grep` and `grep -E`?
4. Why is `\.` used in an IP regex?
5. What is ReDoS?
6. How could `999.300.1.1` slip through a simple IPv4 regex?

<details><summary>Answers</summary>

1. Start and end of the line.
2. Any single character that is not a digit.
3. `-E` enables extended regex (`+ ? | () {}` work without backslashes).
4. A bare `.` matches any character; `\.` matches a literal dot.
5. Regular-expression denial of service: crafted input makes a backtracking engine take exponential time.
6. The simple pattern checks digit counts, not value ranges (0–255).
</details>

## 8. Mastery checklist
- [ ] I write ERE patterns with classes, quantifiers, groups, alternation
- [ ] I extract IPs, hashes, emails and URLs from text
- [ ] I know where regex can mislead me
- [ ] I choose `-F` or quoting when handling untrusted patterns

## Next → `20-text-processing.md`
