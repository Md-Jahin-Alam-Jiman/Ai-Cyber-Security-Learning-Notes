# Chapter 7 · Seeing the World as the Shell Sees It
📖 Book: Part I, pp. 61–71 · ⏱ ~90 min · Prereq: Chapter 6

## Learning goals
- Understand **expansion**: the shell rewrites your command before running it
- Use pathname, tilde, arithmetic, brace, parameter expansion and command substitution
- Master quoting: when to use `" "`, `' '`, and `\`

## 1. Expansions
| Type | Example | Result |
|---|---|---|
| Pathname | `echo D*` | Files starting with D |
| Tilde | `echo ~` / `~root` | Home directories |
| Arithmetic | `echo $((2 + 3 * 4))` | `14` |
| Brace | `echo {a,b,c}` · `{1..5}` · `{A..E}` | Lists/sequences |
| Parameter | `echo $USER` | Variable value |
| Command substitution | `echo $(date +%F)` | Output of the command |

Useful brace example: `mkdir {2025,2026}-{01..03}` creates six directories.

Hide-and-seek tip: `echo` shows what the shell *really* passed to a command.

Old-style command substitution uses backticks (`` `cmd` ``); prefer `$(cmd)` because it nests.

## 2. Quoting
| Quote | Effect |
|---|---|
| `"double"` | Suppresses word splitting and wildcards, but **allows** `$var`, `$(cmd)`, `$((math))`, `\` |
| `'single'` | Suppresses **all** expansion |
| `\` | Escapes one character |

```bash
echo this is a    test           # extra spaces collapse
echo "this is a    test"         # preserved
echo "$USER $((2+2)) $(date +%F)"   # expansions work in double quotes
echo '$USER $((2+2))'               # nothing expands
echo "Cost: \$5"                     # escaped dollar
echo -e "a\tb\nc"                    # backslash sequences (\n \t \a \\)
echo $'a\tb'                         # bash ANSI-C quoting
```

## 3. Guided walkthrough
```bash
echo *                      # see what the shell expands * into
echo ~ ~root
echo $((5**2)) $((10%3))
echo Front-{A,B,C}-Back
echo {Z..A}
echo $USER $HOME $SHELL
ls -l $(which cp)
file $(ls /usr/bin/* | head -5)
mkdir -p ~/linux-lab/exp && cd ~/linux-lab/exp
mkdir {2025,2026}-{01..03}
ls
touch "my report.txt"
ls -l my report.txt          # error! the shell splits into 3 arguments
ls -l "my report.txt"        # correct
```

## 4. 🔐 Cyber relevance
- **Expansion order is a security topic.** Unquoted variables get **word-split** and **globbed**. A filename like `a b` or `*` silently changes a command's meaning. Always write `"$var"`.
- **Command injection** exists because untrusted text ends up where the shell expands it. Compare:
  ```bash
  name='report; id'
  ls $name            # shell splits on spaces; ';' stays text here, but quoting habits matter
  echo "$name"        # safe, printed as one string
  ```
  The real danger is `eval`, `sh -c "...$input..."`, or building commands from user input in scripts and web apps. Defense: quote variables, validate input, avoid `eval`.
- **Wildcard injection:** a file named `--checkpoint=1` in a directory can be consumed as an option by `tar *` run in a cron job. Defense: use `./*` and `--`.
- **Single vs double quotes in payload analysis:** reading obfuscated shell one-liners starts with understanding what expands where. Break them apart with `echo` before ever running them. (Never run unknown commands; analyze them first.)
- **Brace expansion for fast recon setup:** `mkdir -p case01/{evidence,notes,reports,tools}`.
- zsh note (Kali/macOS): an unmatched glob is an *error* by default, whereas bash passes it literally.

## 5. Labs
**Easy**
1. `echo $((7*6))`, `echo $((2**10))`, `echo $((17%5))`.
2. `echo {1..10}` and `echo {a..e}{1..2}`.
3. `echo "Today is $(date +%A)"`.

**Medium**
4. Create folders `case/{evidence,notes,reports}/{2026}` using one `mkdir -p` command.
5. Show the difference between `echo $HOME`, `echo "$HOME"`, and `echo '$HOME'`.
6. Create a file named `my notes.txt`; list it correctly three different ways (quotes, backslash, wildcard).

**Hard (cyber)**
7. Create files `a`, `b c`, and `*`. Run `for f in $(ls); do echo "[$f]"; done` and then explain why filenames break the loop. Remove them carefully with `rm -- ./'*'` and others.
8. Predict, then verify with `echo`, what these print: `echo "$(echo '$USER')"`, `echo '$(date)'`, `echo "\$(date)"`.
9. Build a one-line command creating a dated case folder: `mkdir -p "case-$(date +%F)"/{evidence,notes}`.

## 6. Common mistakes
- Unquoted filenames with spaces
- Thinking `*` is expanded by the command (it is the shell)
- Using single quotes when you wanted a variable to expand
- Forgetting `$` inside `$(( ))` is optional but `$` for command substitution is required

## 7. Quiz
1. Who expands `*`: the shell or `ls`?
2. Which quotes stop `$USER` expanding?
3. What does `{1..3}` produce?
4. Why quote `"$var"`?
5. Name a vulnerability class caused by unsafe expansion.

<details><summary>Answers</summary>

1. The shell.
2. Single quotes.
3. `1 2 3`.
4. To prevent word splitting and globbing.
5. Command injection (also wildcard/argument injection).
</details>

## 8. Mastery checklist
- [ ] I can predict what the shell will pass to a command
- [ ] I choose the right quote type
- [ ] I use `$( )` and `$(( ))` confidently
- [ ] I always quote variables by habit

## Next → `08-advanced-keyboard-tricks.md`
