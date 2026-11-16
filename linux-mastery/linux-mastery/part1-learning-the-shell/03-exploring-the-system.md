# Chapter 3 · Exploring the System
📖 Book: Part I, pp. 13–22 · ⏱ ~75 min · Prereq: Chapter 2

## Learning goals
- Use `ls` options and read the long format
- Identify file types with `file` and read files with `less`
- Understand symbolic and hard links
- Explore the system like an investigator

## 1. Commands
| Command | Purpose |
|---|---|
| `ls -l` | Long format (permissions, owner, size, date) |
| `ls -a` | Show hidden files |
| `ls -d */` | Directories themselves, not contents |
| `ls -F` | Append `/` (dir), `*` (executable), `@` (symlink) |
| `ls -h` | Human-readable sizes (with `-l`) |
| `ls -t` / `-S` / `-r` | Sort by time / size / reverse |
| `ls -i` | Show inode numbers |
| `file name` | Identify the real type of a file |
| `less file` | Page through text |
| `stat file` | Full metadata (all timestamps, inode) |

**less keys:** `Space`/`b` page down/up · `G`/`g` end/start · `/text` search · `n` next match · `h` help · `q` quit.

## 2. Reading `ls -l`
```
-rwxr-xr-x 1 root root 1048576 Nov 11 10:30 tool
│└┬┘└┬┘└┬┘ │ └┬─┘ └┬─┘ └──┬──┘ └───┬────┘ └─┬─┘
│ │  │  │  │  owner group size  modified   name
│ │  │  │  link count
│ │  │  └ others: r-x
│ │  └ group: r-x
│ └ owner: rwx
└ type: - file, d directory, l symlink, c/b device
```

## 3. Links
- **Symbolic (soft) link:** a pointer to a *path*. Shown as `l` and `name -> target`. Breaks if the target is removed. Can cross file systems and point to directories.
- **Hard link:** another *name* for the same data (same inode). Deleting one name doesn't delete the data. Cannot cross file systems; not for directories.

## 4. Guided tour (read-only)
```bash
ls -lh /etc | head
file /bin/ls /etc/passwd /usr/share
less /etc/passwd            # q to quit
ls -l /bin                  # note symlinks (l) on modern distros /bin -> usr/bin
ls -lt /var/log | head      # newest first
stat /etc/passwd            # compare atime, mtime, ctime
```
Directories worth browsing: `/etc`, `/usr/bin`, `/usr/share/doc`, `/var/log`, `/proc` (try `less /proc/cpuinfo`).

## 5. 🔐 Cyber relevance
- **`file` beats extensions.** A "photo.jpg" may be an ELF executable. Check with `file`.
- **Timestamps tell stories:** `ls -lat` and `stat` show when files changed. `ctime` (metadata change) can't be set by normal tools, which makes it forensically valuable.
- **Spot privileged programs:** an `s` in `-rwsr-xr-x` means setuid, which runs as the file owner. Attackers love misconfigured ones. (Deep dive in chapter 9.)
- **Symlink attacks:** a predictable file in `/tmp` replaced by a link to `/etc/passwd` can trick a privileged script. Always check with `ls -l`.
- **Hard links** hide extra names for data; inode numbers (`ls -i`) reveal them.
- **Quick content peeking:** `strings binary | less` and `xxd file | head` (`xxd` ships with vim; `hexdump -C` is the alternative, and on Alpine install `xxd`). Do this only on files you're authorized to analyze, and never execute unknown files.
- macOS: `ls -l@` shows extended attributes; `ls -lO` shows flags.

## 6. Labs
**Easy**
1. `ls -l /etc`. Identify one directory, one regular file, one symlink.
2. `ls -lh /var/log`. Which file is largest? Use `ls -lS` to confirm.
3. `file /etc/passwd /bin/ls ~` and describe the results.

**Medium**
4. `ls -lat ~ | head`. Which files changed most recently?
5. `stat /etc/hostname`. What are Access, Modify, and Change times?
6. Open `/etc/services` in `less`; search for `ssh` (`/ssh`), jump to the end (`G`), and quit.

**Hard (cyber)**
7. `ls -li /usr/bin | head`. Pick two files with the same inode number, if any (hard links). What does that mean?
8. Find where `/bin` points: `ls -ld /bin`. Why do modern distros do this?
9. Run `strings /bin/ls | head -30` and `file /bin/ls`. What kind of file is it, and what readable text is inside?

## 7. Common mistakes
- Using `less` on binary files (garbled screen; press `q`, then run `reset`)
- Reading `ls -l` columns wrong; permissions are 10 characters, not 9
- Thinking a symlink *is* the file
- Trusting a file's extension

## 8. Quiz
1. What does `-rwsr-xr-x` indicate?
2. Soft vs hard link?
3. Which command reveals real file type?
4. How do you list newest files first?
5. Why is `ctime` useful in investigations?

<details><summary>Answers</summary>

1. A regular file with the setuid bit set.
2. Soft points to a path and can break; hard is another name for the same inode.
3. `file`.
4. `ls -lt`.
5. It records metadata changes and can't be freely set by ordinary tools.
</details>

## 9. Mastery checklist
- [ ] I can read every column of `ls -l`
- [ ] I use `file`, `stat`, and `less` comfortably
- [ ] I can explain symlinks vs hard links
- [ ] I can spot a setuid file in a listing

## Next → `04-manipulating-files-and-directories.md`
