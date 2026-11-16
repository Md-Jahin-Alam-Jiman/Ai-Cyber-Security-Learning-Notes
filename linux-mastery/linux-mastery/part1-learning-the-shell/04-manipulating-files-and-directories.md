# Chapter 4 · Manipulating Files and Directories
📖 Book: Part I, pp. 23–37 · ⏱ ~90 min · Prereq: Chapter 3

## Learning goals
- Use wildcards (globbing) to select many files
- Create, copy, move, rename, link, and delete safely
- Build a playground and practice without risk
- Understand why `rm` is not secure deletion

## 1. Wildcards
| Pattern | Matches |
|---|---|
| `*` | Any characters |
| `?` | Exactly one character |
| `[abc]` | One of a, b, c |
| `[!abc]` | Any character except a, b, c |
| `[[:upper:]]` `[[:digit:]]` `[[:alpha:]]` `[[:alnum:]]` `[[:lower:]]` | Character classes |

Examples: `*.txt` · `data???` · `[abc]*` · `[[:upper:]]*` · `*[![:lower:]]`

The **shell** expands wildcards *before* the command runs.

## 2. Commands
| Command | Purpose | Useful options |
|---|---|---|
| `mkdir a b c` | Create directories | `-p` create parents |
| `cp src dst` | Copy | `-i` ask · `-r`/`-a` recursive/archive (keeps perms & times) · `-u` newer only · `-v` verbose |
| `mv src dst` | Move or rename | `-i` ask · `-u` · `-v` |
| `rm file` | Delete (no trash!) | `-i` ask · `-r` recursive · `-f` force · `-v` |
| `ln src link` | Hard link | |
| `ln -s target link` | Symbolic link | |
| `touch file` | Create empty file / update time | |

## 3. Build the playground
```bash
mkdir -p ~/linux-lab/playground && cd ~/linux-lab/playground
mkdir dir1 dir2
cp /etc/passwd .                  # copy a system file (readable by all)
cp -i /etc/hostname dir1          # -i asks before overwriting
mv passwd fun
mv fun dir1
mv dir1/fun dir2
ln dir2/fun fun-hard              # hard link: ln EXISTING NEWNAME
ln -s dir2/fun fun-sym
ls -li                            # compare inodes of hard vs soft link
rm fun-hard
rm -ri dir1                       # interactive recursive delete
```
Make sure you can explain every line and what each `ls -li` column shows.

## 4. 🔐 Cyber relevance
- **`rm` only unlinks the name.** Data remains on disk until overwritten. For real wiping, `shred -u file` (GNU; unreliable on SSDs, journaling or copy-on-write file systems) or full-disk encryption plus key destruction. On macOS `shred` isn't included.
- **Danger commands:** `rm -rf /` or `rm -rf ~/ *` (a stray space!). Always `ls` the same pattern first: `ls *.log` then `rm *.log`.
- **Filenames starting with `-`:** `rm -rf` as a *filename* gets read as options. Use `rm -- -rf` or `rm ./-rf`. This trick is also used in wildcard injection attacks (`*` expanding to `--checkpoint-action=...` with tar); defend with `./*` and `--`.
- **Evidence handling:** copy with `cp -a` to keep timestamps and permissions, then verify:
  ```bash
  sha256sum original.bin copy.bin    # macOS: shasum -a 256
  ```
  Never work on the original evidence.
- **Backups before changes:** `cp -a file file.bak.$(date +%F)`.
- **`touch` can fake timestamps** (`touch -d "2020-01-01" file`), a reason mtime alone can't be trusted.
- BSD/macOS `cp`/`mv` behave the same for basics; some GNU long options (like `--backup`) aren't available.

## 5. Labs
**Easy**
1. In the playground, create `a.txt b.txt c.log` with `touch`. List with `ls *.txt`, `ls ?.log`, `ls [ab]*`.
2. Copy `a.txt` to `a-copy.txt`; rename it to `archive.txt`.
3. Create `projects/web/css` in one command.

**Medium**
4. Create files `Aa1 bB2 Cc3 d4`. Select only those starting with an uppercase letter using a character class.
5. Make a hard link and a symlink to `a.txt`. Delete `a.txt`. Which link still works? Why?
6. Use `cp -v` and `mv -v` to copy 5 files at once into a directory. Read the verbose output.

**Hard (cyber)**
7. Create a file called `-rf` (`touch ./-rf`) and a file `my file` (with a space). Delete both safely.
8. Create `evidence.txt` with a few lines, copy with `cp -a`, hash both with `sha256sum`, then change one character in the copy and hash again. Explain the difference.
9. Run `shred -u -v testfile` on a throwaway file. Then explain why this may not guarantee erasure on SSDs.

## 6. Common mistakes
- `rm * .txt` (space!) deletes everything, then complains about `.txt`
- `mv` silently overwrites without `-i`
- `cp dir newdir` without `-r` fails
- Assuming a trash can exists; it doesn't

## 7. Quiz
1. What does `[![:lower:]]*` match?
2. `cp` vs `cp -a`?
3. Which link type survives deleting the original file?
4. How do you delete a file named `-rf`?
5. Why isn't `rm` enough to destroy sensitive data?

<details><summary>Answers</summary>

1. Names starting with a character that is not lowercase.
2. `-a` keeps permissions, ownership, timestamps and recurses.
3. Hard link.
4. `rm -- -rf` or `rm ./-rf`.
5. It removes the name only; the data blocks remain recoverable until overwritten.
</details>

## 8. Mastery checklist
- [ ] I can select files with `*`, `?`, `[ ]` and classes
- [ ] I copy, move, rename, link and delete without mistakes
- [ ] I `ls` a pattern before I `rm` it
- [ ] I can verify copies with a checksum

## Next → `05-working-with-commands.md`
