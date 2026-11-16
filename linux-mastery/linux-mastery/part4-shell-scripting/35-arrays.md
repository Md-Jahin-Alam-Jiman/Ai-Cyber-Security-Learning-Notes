# Chapter 35 · Arrays
📖 Book: Part IV, pp. 471–484 · ⏱ ~90 min · Prereq: Chapter 34

## Learning goals
- Create and use indexed and associative arrays
- Loop, slice, append, delete, and sort arrays
- Count, group, and look things up (IOCs, allow-lists, per-IP counters)
- Build commands safely with arrays instead of strings

> **Version note:** associative arrays, `mapfile`, and `${var,,}` need **bash 4+**. Linux distros have bash 5.x; **macOS ships bash 3.2** (`brew install bash`, then use `#!/usr/bin/env bash`). **Alpine:** `apk add bash`. zsh arrays are **1-indexed** and behave differently. Check: `echo "$BASH_VERSION"`.

## 1. Indexed arrays
```bash
a=(alpha beta gamma)          # create
a[3]=delta                    # set an element
a+=(epsilon)                  # append
echo "${a[0]}"                # first element
echo "${a[@]}"                # all elements (each as a separate word when quoted: "${a[@]}")
echo "${#a[@]}"               # number of elements
echo "${!a[@]}"               # indices
echo "${a[@]:1:2}"            # slice: 2 elements from index 1
unset 'a[1]'                  # delete one element (leaves a gap)
for x in "${a[@]}"; do echo "$x"; done
for i in "${!a[@]}"; do echo "$i = ${a[$i]}"; done
```
| Form | Meaning |
|---|---|
| `"${a[@]}"` | Each element as its **own** word (almost always what you want) |
| `"${a[*]}"` | All elements joined into **one** word |
| `${#a[0]}` | Length of element 0 |
| `mapfile -t lines < file` | Read file lines into an array (bash 4+; also `readarray`) |
| `mapfile -d '' -t files < <(find . -type f -print0)` | NUL-delimited, safe for any filename (bash 4.4+) |
| `sorted=($(printf '%s\n' "${a[@]}" \| sort))` | Sort (breaks on whitespace in elements; prefer `mapfile`) |

## 2. Associative arrays (dictionaries)
```bash
declare -A age                 # must declare with -A
age[alice]=31
age[bob]=27
echo "${age[alice]}"
echo "${!age[@]}"              # keys
echo "${age[@]}"               # values
[[ -v age[carol] ]] || echo "carol missing"      # test for a key (bash 4.3+)
count=$(( ${age[dave]:-0} + 1 ))                 # default when missing
unset 'age[bob]'
for k in "${!age[@]}"; do printf '%s=%s\n' "$k" "${age[$k]}"; done
```
Key order is **not** guaranteed; sort output when order matters (`| sort`).

## 3. Project A: `ip-counter.sh`, per-IP and per-user failed logins
```bash
#!/usr/bin/env bash
# ip-counter.sh - failed SSH logins per source IP and per username (bash 4+)
(( BASH_VERSINFO[0] >= 4 )) || { echo "needs bash 4 or newer" >&2; exit 2; }
LOG="${1:?usage: ip-counter.sh LOGFILE}"
[ -r "$LOG" ] || { echo "cannot read $LOG" >&2; exit 2; }

declare -A by_ip by_user
re='Failed password for (invalid user )?([^ ]+) from ([0-9.]+)'
total=0
while IFS= read -r line; do
  if [[ $line =~ $re ]]; then
    user="${BASH_REMATCH[2]}"; ip="${BASH_REMATCH[3]}"
    by_ip[$ip]=$(( ${by_ip[$ip]:-0} + 1 ))
    by_user[$user]=$(( ${by_user[$user]:-0} + 1 ))
    total=$(( total + 1 ))
  fi
done < "$LOG"

echo "Total failed logins: $total"
echo; echo "Top source IPs"
for ip in "${!by_ip[@]}"; do printf '%6d  %s\n' "${by_ip[$ip]}" "$ip"; done | sort -nr | head -5
echo; echo "Top targeted usernames"
for u in "${!by_user[@]}"; do printf '%6d  %s\n' "${by_user[$u]}" "$u"; done | sort -nr | head -5
```
Keeping the regex in a variable (`$re`, unquoted on the right of `=~`) avoids quoting headaches.

## 4. Project B: `ioc-match.sh`, fast IOC lookup
```bash
#!/usr/bin/env bash
# ioc-match.sh - report log lines that contain known-bad IPs (bash 4+)
# Usage: ./ioc-match.sh IOCFILE LOGFILE     IOCFILE: one IP per line, '#' comments allowed
(( BASH_VERSINFO[0] >= 4 )) || { echo "needs bash 4 or newer" >&2; exit 2; }
ioc_file="${1:?usage: ioc-match.sh IOCFILE LOGFILE}"; log="${2:?missing LOGFILE}"

declare -A bad
while IFS= read -r ioc; do
  [[ -z $ioc || $ioc == \#* ]] && continue
  bad[$ioc]=1
done < "$ioc_file"
echo "Loaded ${#bad[@]} indicators" >&2

ip_re='([0-9]{1,3}\.){3}[0-9]{1,3}'
hits=0
while IFS= read -r line; do
  rest="$line"
  while [[ $rest =~ $ip_re ]]; do
    ip="${BASH_REMATCH[0]}"
    if [[ -n ${bad[$ip]:-} ]]; then printf 'HIT %-16s %s\n' "$ip" "$line"; hits=$((hits + 1)); break; fi
    rest="${rest#*"$ip"}"
  done
done < "$log"
echo "Lines with hits: $hits" >&2
(( hits == 0 ))
```

## 5. Safe command construction with arrays
```bash
# BAD: builds a string, then re-parses it (breaks on spaces, allows injection)
cmd="grep -F $term $file"; eval "$cmd"

# GOOD: an array keeps every argument intact
args=(-F -n --)
[[ $ignore_case == 1 ]] && args=(-i "${args[@]}")
grep "${args[@]}" "$term" "$file"

# Build a find command with optional parts
find_args=(/var/log -type f)
[[ -n ${days:-} ]] && find_args+=(-mtime "-$days")
find "${find_args[@]}"
```

## 6. 🔐 Cyber relevance
- **Arrays are how scripts represent security data:** lists of hosts in scope, allow-listed users/IPs, IOCs, ports, file paths, and counters keyed by IP/user/hash. Associative arrays give O(1) lookups, so matching millions of log lines against an IOC list is quick without external tools.
- **Safe command building:** string concatenation + `eval` is the classic injection route. Arrays preserve argument boundaries, so a value like `x; rm -rf ~` stays a single harmless argument. Use `"${args[@]}"` and `--` before untrusted values.
- **Always quote expansions:** unquoted `${a[@]}` re-splits and globs. A single filename containing a space or `*` changes the command. Same rule as `"$@"`.
- **Handling hostile filenames:** read `find -print0` into an array (`mapfile -d '' -t`) or loop with `read -r -d ''`. Newlines in filenames break line-based processing and have been used to hide files or smuggle arguments.
- **Associative-array key injection:** keys come from attacker-controlled text (IPs, usernames, URLs). Keys like `a]b` or `$(cmd)` can confuse `(( ))` arithmetic subscripts (`(( by_ip[$ip]++ ))` evaluates `$ip` as an expression). Safer: assign via `by_ip[$ip]=$(( ${by_ip[$ip]:-0} + 1 ))` after validating the key with a regex.
- **Counters and thresholds:** per-key counting is the engine of rate-limit logic (login failures, requests, DNS lookups) and of simple anomaly detection, such as many distinct usernames from one IP (credential stuffing) or one username from many IPs (distributed brute force). Try both on your log.
- **Memory limits:** arrays live in RAM. For huge logs use streaming tools (`awk`, `sort | uniq -c`) or databases; unbounded dictionaries are a DoS risk if an attacker controls key diversity.
- **Version portability:** a script silently misbehaving on bash 3.2 (macOS) or `sh` can *skip a check*, so fail loudly with the version test used above.
- **Don't store secrets in arrays/environment longer than needed;** `unset` after use, and avoid printing arrays when they might contain credentials.

## 7. Labs
**Easy**
1. Create an array of 5 hostnames. Print the count, the first and last items, and each with its index.
2. Append two items, remove one, and print the array again.
3. Read `/etc/shells` into an array with `mapfile -t` and print how many shells are listed.

**Medium**
4. Create an associative array mapping ports to service names (`22=ssh`, `80=http`, `443=https`). Print a table sorted by port.
5. Write a script that counts words in a file with an associative array and prints the top 5.
6. Use `mapfile -d '' -t` with `find` to list files in a directory that contains the nasty names from chapter 33, then print each in brackets.

**Hard (cyber)**
7. Run `ip-counter.sh` on the Checkpoint 3 sample log. Extend it to also count **distinct usernames per IP** (hint: key `"$ip|$user"` → then count keys per IP) and flag potential credential stuffing.
8. Build `ioc-match.sh`, create an IOC file with two of the log's attacker IPs, and verify it reports only lines containing them. Time it against `grep -Ff` and compare.
9. Rewrite a function that runs `grep "$pattern" "$file"` via `eval` into a safe array-based version. Prove the fix with a pattern like `a; touch /tmp/pwned`.
10. Make a scope checker: read allowed CIDRs from a file into an array and, for each IP read from stdin, print `IN SCOPE` or `OUT OF SCOPE` using `in_cidr` from chapter 34.

## 8. Common mistakes
- Forgetting `declare -A` (bash then treats keys as arithmetic → everything lands in index 0)
- Using `${a[@]}` without quotes
- Expecting ordered keys from associative arrays
- Assuming bash 4+ on macOS or Alpine's default shell
- Passing arrays to functions by value (pass `"${a[@]}"` and rebuild, or use namerefs `declare -n`)

## 9. Quiz
1. `"${a[@]}"` vs `"${a[*]}"`?
2. Why must associative arrays be declared?
3. How do you test if a key exists?
4. Why are arrays safer than strings for building commands?
5. Why can `(( counts[$key]++ ))` be unsafe with untrusted keys?

<details><summary>Answers</summary>

1. The first yields each element as a separate word; the second joins them into one word.
2. Without `declare -A`, bash treats the subscript as arithmetic on an indexed array.
3. `[[ -v arr[key] ]]` (bash 4.3+) or `[[ -n ${arr[key]:-} ]]`.
4. Argument boundaries are preserved, so no re-splitting, globbing, or injection.
5. `$key` is evaluated as an arithmetic expression, which can execute embedded expressions; validate the key and use the explicit assignment form.
</details>

## 10. Mastery checklist
- [ ] I use indexed and associative arrays with proper quoting
- [ ] I read files/NUL-delimited lists into arrays
- [ ] I build commands with arrays, never `eval`
- [ ] I can count, group, and look up events by key
- [ ] I check the bash version before using bash 4+ features

## Next → `36-exotica.md`
