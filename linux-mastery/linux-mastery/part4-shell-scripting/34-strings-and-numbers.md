# Chapter 34 · Strings and Numbers
📖 Book: Part IV, pp. 447–470 · ⏱ ~120 min · Prereq: Chapter 33

## Learning goals
- Master **parameter expansion**: defaults, lengths, substrings, trimming, replacing, case conversion
- Do integer arithmetic, bases, and bit operations in the shell
- Handle decimals with `bc`/`awk`
- Apply it to IP/CIDR math, input sanitizing, and secure randomness

## 1. Parameter expansion cheat table
| Syntax | Result |
|---|---|
| `${var}` | Value (use braces to separate from text: `${var}_x`) |
| `${var:-word}` | `word` if `var` is unset or empty (var unchanged) |
| `${var:=word}` | Same, but also **assigns** `word` to `var` |
| `${var:?message}` | **Abort** with `message` if unset or empty |
| `${var:+word}` | `word` only if `var` is set and non-empty |
| `${#var}` | Length of the string |
| `${var:2:3}` | 3 characters starting at offset 2 (`${var: -4}` = last 4; note the space) |
| `${var#pat}` / `${var##pat}` | Remove shortest / longest match of `pat` from the **front** |
| `${var%pat}` / `${var%%pat}` | Remove shortest / longest match from the **end** |
| `${var/pat/rep}` / `${var//pat/rep}` | Replace first / all matches |
| `${var^^}` / `${var,,}` | UPPER / lower case (bash 4+; macOS bash 3.2 lacks it) |
| `${var@Q}` | Value quoted for reuse as shell input (bash 4.4+) |

```bash
path=/var/log/auth.log.1.gz
echo "${path##*/}"      # auth.log.1.gz  (basename)
echo "${path%/*}"       # /var/log       (dirname)
echo "${path%%.*}"      # /var/log/auth  (strip everything from the first dot)
echo "${path#/}"        # var/log/auth.log.1.gz
echo "${path//\//_}"    # _var_log_auth.log.1.gz
file=report.txt; echo "${file%.txt}.bak"     # report.bak
name="Alice"; echo "${name^^} ${name,,} ${#name}"
```

## 2. Arithmetic
| Form | Use |
|---|---|
| `$(( expr ))` | Expression → value: `x=$(( 3 + 4 * 2 ))` |
| `(( expr ))` | Evaluate/compare; status 0 if non-zero: `if (( x > 5 ))` |
| `let x+=1`, `(( x++ ))` | Assignment forms |
| Operators | `+ - * / % **` · `++ --` · `+= -= *=` · `< <= > >= == !=` · `&& \|\| !` · `?:` |
| Bits | `& \| ^ ~ << >>` |
| Bases | `0x1F` hex · `010` **octal** · `2#1010` binary · `10#08` force decimal |
| Output in hex/octal | `printf '%x %o %d\n' 255 8 0x1f` |

- Shell arithmetic is **integers only**; `/` truncates (`7/2=3`).
- **Floating point:** `echo "scale=2; 10/3" | bc` or `awk 'BEGIN{printf "%.2f\n", 10/3}'`.
- Inside `(( ))` and `$(( ))` variables need no `$`.
- Declare integers: `declare -i n=5`.

⚠️ **Octal trap:** a leading zero means octal: `$(( 010 ))` is 8 and `$(( 08 ))` is an **error**. Always force decimal for user data: `$(( 10#$value ))`.

## 3. Project: `ipcalc-lite.sh`, IP and CIDR checks in pure bash
```bash
#!/usr/bin/env bash
# ipcalc-lite.sh - IPv4 validation and CIDR membership (chapter 34)
# Usage: ./ipcalc-lite.sh IP CIDR     e.g.  ./ipcalc-lite.sh 10.1.2.3 10.0.0.0/8

valid_ip() {                      # 0 if valid IPv4 dotted quad
  local ip="$1" o
  [[ $ip =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || return 1
  local IFS=.
  for o in $ip; do (( 10#$o <= 255 )) || return 1; done
  return 0
}

ip2int() {                        # 10.0.0.1 -> 167772161
  local a b c d IFS=.
  read -r a b c d <<< "$1"
  echo $(( (10#$a << 24) + (10#$b << 16) + (10#$c << 8) + 10#$d ))
}

in_cidr() {                       # in_cidr IP NET/BITS
  local ip="$1" net="${2%/*}" bits="${2#*/}" mask
  valid_ip "$ip" && valid_ip "$net" && [[ $bits =~ ^[0-9]+$ ]] && (( bits <= 32 )) || return 2
  mask=$(( bits == 0 ? 0 : (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF ))
  (( ( $(ip2int "$ip") & mask ) == ( $(ip2int "$net") & mask ) ))
}

[ $# -eq 2 ] || { echo "usage: ${0##*/} IP NET/BITS" >&2; exit 64; }
in_cidr "$1" "$2"
case $? in
  0) echo "$1 is inside $2" ;;
  1) echo "$1 is NOT inside $2"; exit 1 ;;
  *) echo "invalid input" >&2; exit 2 ;;
esac
```
Tests: `10.1.2.3 10.0.0.0/8` (inside), `192.168.1.5 10.0.0.0/8` (outside), `999.1.1.1 10.0.0.0/8` (invalid), `010.001.002.003 10.0.0.0/8` (leading zeros handled with `10#`).

## 4. More recipes
```bash
# Sanitize a string for use in a filename
safe="${input//[^A-Za-z0-9._-]/_}"
# Trim whitespace
trimmed="${s#"${s%%[![:space:]]*}"}"; trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
# Percent-decode (URL) for log analysis, then view safely with cat -v
printf '%b' "${s//%/\\x}" | cat -v
# Hex/ASCII conversions
printf '%d\n' 0x41; printf '\x41\n'; printf '%x\n' 255
# Permission bit test: is "others" write set?   mode=0666
(( (8#666 & 8#002) != 0 )) && echo "world-writable"
# Random values
openssl rand -hex 16                    # cryptographically secure
tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24; echo
```

## 5. 🔐 Cyber relevance
- **Bit math is everyday security math:** subnet masks (CIDR membership, as above), permission bits (`mode & 0002`), flags in packet captures and file headers, XOR (`^`) in simple malware obfuscation, hex/octal/decimal conversion of IPs (`http://2130706433/` = `127.0.0.1`: attackers use alternative number formats to evade naive filters).
- **Octal/leading-zero bugs are real vulnerabilities.** A library treating `010.0.0.1` as octal (`8.0.0.1`) while another treats it as decimal has caused SSRF and access-control bypasses. Normalize with `10#` and validate.
- **Validate numeric input before arithmetic.** `(( x ))` and `$(( x ))` can evaluate **expressions and array subscripts inside variables**, which in some contexts leads to code execution when `x` is attacker-controlled (for example a value such as `a[$(cmd)]`). Always check `[[ $x =~ ^[0-9]+$ ]]` first.
- **Use `${var:?}` guards** on anything that builds a path or a destructive command; this is the antidote to `rm -rf "$DIR"/*` disasters.
- **Parameter expansion replaces forks:** `${path##*/}` beats `basename` for speed and avoids spawning processes on hostile input (and avoids option injection via `basename -- "$x"` omissions).
- **Randomness:** `$RANDOM` (15-bit, predictable, seedable) is **not** for tokens, passwords, or keys. Use `/dev/urandom`, `openssl rand`, or `python3 -c 'import secrets; print(secrets.token_hex(16))'`. Predictable "random" filenames in `/tmp` enable symlink attacks; use `mktemp`.
- **String length and truncation:** check `${#var}` to limit inputs (log injection, buffer-size assumptions in other tools). Normalize case/Unicode before comparing for security decisions; remember bash 3.2's limits.
- **Percent-decoding/obfuscation:** web logs and payloads use `%2e%2e%2f`, double encoding, hex, and base64. Decode (in a controlled way) before pattern matching, then display with `cat -v` so control characters can't hijack your terminal.
- **Defanging and redaction** with `${var//./[.]}` (IPs/domains) or `${var//$secret/****}` before sharing logs.
- **Floating point and money-like values:** avoid shell arithmetic for them; use `bc`/`awk`.

## 6. Labs
**Easy**
1. Given `file=/home/alice/report.final.txt`, extract the directory, file name, and extension using only parameter expansion.
2. Use `${var:-default}` and `${var:?}` with an unset variable; compare behaviors.
3. Compute `17 % 5`, `2 ** 10`, and `7 / 2` in the shell; compute `7 / 2` with two decimals via `bc`.

**Medium**
4. Convert `ABC.txt` → `abc.TXT` using `${var,,}` and `${var^^}` (or `tr` on bash 3.2).
5. Replace all spaces in a filename with underscores, using `${var// /_}`, and then sanitize with the allow-list pattern.
6. Print `255` in hex, octal, and binary (`bc` with `obase=2`, or a loop with `(( ))`).

**Hard (cyber)**
7. Build and test `ipcalc-lite.sh` with the five cases above. Add a mode that reads many IPs from stdin and prints those inside a given CIDR (a mini "scope checker").
8. Demonstrate the octal trap: show `$(( 010 ))`, `$(( 08 ))` (error), and `$(( 10#08 ))`. Explain how a mismatch between two parsers could bypass an allow-list.
9. Convert `127.0.0.1` to decimal (`2130706433`) and hex (`0x7f000001`) with your `ip2int`, then convert back. Explain why a filter that only matches the dotted string is weak.
10. Write `genpass.sh [LENGTH]` that validates the length (8–128), generates a password from `/dev/urandom`, and never prints anything else. Compare with a `$RANDOM`-based version and explain why the latter is unsafe.

## 7. Common mistakes
- Forgetting that arithmetic is integer-only
- Leading zeros (octal) in decimal data
- `${var:-x}` vs `${var:=x}` confusion
- Missing the space in `${var: -3}`
- Using `$RANDOM` for security values
- Trusting unvalidated numeric strings in `(( ))`

## 8. Quiz
1. What does `${path##*/}` return?
2. What does `${var:?msg}` do?
3. Result of `$(( 7 / 2 ))`? How to get 3.50?
4. What is the octal trap?
5. Why isn't `$RANDOM` suitable for passwords?
6. How can the same IP be written in several numeric forms?

<details><summary>Answers</summary>

1. The part after the last `/` (the basename).
2. Aborts with an error message if `var` is unset or empty.
3. `3`; use `bc` or `awk` (`echo "scale=2; 7/2" | bc`).
4. A leading `0` makes the shell read numbers as octal (and `08`/`09` are errors); use `10#`.
5. It is small, predictable, and not cryptographically secure.
6. Dotted decimal, a single decimal integer, hex, octal, or mixed forms (e.g. `127.0.0.1`, `2130706433`, `0x7f000001`).
</details>

## 9. Mastery checklist
- [ ] I use parameter expansion for trimming, replacing, defaults, and guards
- [ ] I do integer, bitwise, and base-conversion math confidently
- [ ] I validate numeric input and avoid octal traps
- [ ] I use secure randomness and know the risks of `$RANDOM`

## Next → `35-arrays.md`
