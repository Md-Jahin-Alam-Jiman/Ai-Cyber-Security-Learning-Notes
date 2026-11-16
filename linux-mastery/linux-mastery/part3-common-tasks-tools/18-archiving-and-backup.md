# Chapter 18 · Archiving and Backup
📖 Book: Part III, pp. 213–226 · ⏱ ~100 min · Prereq: Chapter 17

## Learning goals
- Compress with `gzip`, `bzip2`, `xz`, `zstd`
- Create, list and extract archives with `tar` and `zip`
- Synchronize and back up with `rsync`
- Design backups that survive ransomware and verify them

## 1. Compression vs archiving
- **Compression** shrinks one stream/file (`gzip`, `bzip2`, `xz`, `zstd`).
- **Archiving** bundles many files with metadata into one (`tar`, `zip`).

| Tool | Create | Extract | Notes |
|---|---|---|---|
| gzip | `gzip file` | `gunzip file.gz` | Fast; `-k` keep original; `zcat`, `zless` to read |
| bzip2 | `bzip2 file` | `bunzip2 file.bz2` | Slower, smaller |
| xz | `xz file` | `unxz file.xz` | Smallest, slow |
| zstd | `zstd file` | `unzstd file.zst` | Fast and efficient (install: `zstd`) |
| zip | `zip -r a.zip dir` | `unzip a.zip` | Cross-platform with Windows |

## 2. `tar` essentials
| Command | Meaning |
|---|---|
| `tar -czvf a.tar.gz dir/` | Create gzip archive (`c` create, `z` gzip, `v` verbose, `f` file) |
| `tar -cjvf a.tar.bz2 dir/` | bzip2 (`j`) |
| `tar -cJvf a.tar.xz dir/` | xz (`J`) |
| `tar --zstd -cvf a.tar.zst dir/` | zstd (GNU tar ≥ 1.31) |
| `tar -tf a.tar.gz` | **List** contents (do this before extracting!) |
| `tar -xzvf a.tar.gz -C /target/` | Extract into a directory |
| `tar -xzf a.tar.gz path/in/archive` | Extract one item |
| `tar -czf a.tar.gz --exclude='*.tmp' dir/` | Exclude |
| `tar -cpzf ...` | Preserve permissions (`p`) |
| `tar -czf - dir \| ssh host 'cat > b.tar.gz'` | Stream over SSH |

Modern GNU tar auto-detects compression on extract (`tar -xf file`). macOS uses `bsdtar` (similar flags; add `--xattrs` support differs). BusyBox tar (Alpine) supports the basics.

## 3. `rsync` (the backup workhorse)
```bash
rsync -avh --progress src/ dest/            # archive mode, verbose, human-readable
rsync -avh --delete src/ dest/              # make dest an exact mirror (DANGEROUS)
rsync -avhn --delete src/ dest/             # -n = dry run: ALWAYS do this first
rsync -avz -e ssh src/ user@host:/backup/   # remote over SSH, compressed
rsync -avh --link-dest=../prev src/ ./new/  # snapshot-style incremental backups
```
**Trailing slash matters:** `src/` copies the *contents*; `src` copies the directory itself.
Alpine/macOS: install a full `rsync` (`apk add rsync`, `brew install rsync`); older macOS versions ship an outdated one.

## 4. Guided walkthrough
```bash
cd ~/linux-lab && mkdir -p bk/src/sub && cd bk
for i in 1 2 3; do echo "file $i" > src/f$i.txt; done
echo "deep" > src/sub/deep.txt
tar -czvf src.tar.gz src/
tar -tzf src.tar.gz
mkdir restore && tar -xzvf src.tar.gz -C restore
diff -r src restore/src && echo IDENTICAL
sha256sum src.tar.gz | tee src.tar.gz.sha256
sha256sum -c src.tar.gz.sha256
gzip -t src.tar.gz && echo "gzip integrity OK"
rsync -avhn --delete src/ mirror/      # dry run
rsync -avh src/ mirror/
touch src/new.txt; rsync -avh src/ mirror/    # only the new file is copied
zip -r src.zip src && unzip -l src.zip
```

## 5. 🔐 Cyber relevance
- **Backups are ransomware insurance** only if they're **offline/immutable** and **tested**. Use the **3-2-1 rule**: 3 copies, 2 media types, 1 off-site (plus 1 immutable/air-gapped). Mounted, always-writable backup shares get encrypted too. Test restores regularly.
- **Encrypt backups** that leave your control:
  ```bash
  tar -czf - dir | gpg --symmetric --cipher-algo AES256 -o backup.tar.gz.gpg   # decrypt: gpg -d file | tar -xzf -
  ```
  Modern alternatives: `age` (`age -p`), `restic`, `borgbackup` (encrypted, deduplicated, verifiable).
- **Integrity:** store `sha256sum` (or signed) manifests separately from the backup. Check `gzip -t` / `tar -tf` / `unzip -t`.
- **Never extract untrusted archives blindly.** List first (`tar -tf`). Dangers: **path traversal** (`../../etc/cron.d/x`, absolute paths), **symlink tricks**, setuid files, **decompression bombs** (tiny zip expanding to terabytes), huge file counts. Extract as an unprivileged user into an empty directory in a sandbox/VM; avoid `sudo tar -x`; GNU tar strips leading `/` by default, but use `--no-same-owner` and `--no-same-permissions` when handling untrusted files.
- **Wildcard injection:** `tar czf backup.tgz *` in a directory where an attacker can create files named `--checkpoint=1` and `--checkpoint-action=exec=...` can execute commands. Use `tar czf backup.tgz -- ./*` or archive the directory itself.
- **Forensics packaging:** preserve metadata: `tar --xattrs --acls --numeric-owner -cpf case.tar dir`; hash before and after; record who collected what and when (chain of custody).
- **`rsync --delete` can propagate attacker deletions** (or your typos) to the backup. Prefer versioned/snapshot backups and always dry-run.
- **Exfiltration awareness:** attackers `tar`+compress data before sending it out. Watch for large archives in `/tmp`, `/var/tmp`, or hidden dirs: `find / -xdev -type f \( -name '*.tar*' -o -name '*.zip' -o -name '*.7z' \) -mtime -7 -size +50M 2>/dev/null`.
- **Cron safety:** backup jobs run as root; make sure scripts and their directories aren't writable by others.

## 6. Labs
**Easy**
1. Compress a file with `gzip`, `bzip2`, `xz`; compare sizes with `ls -l` (use `-k` to keep the original).
2. Create `docs.tar.gz` from a directory, list it, extract it elsewhere.
3. Zip a folder and list the zip's contents.

**Medium**
4. Archive a directory excluding `*.log` files.
5. Use `rsync -avhn` dry-run, then a real sync, then change one file and observe only the delta being copied.
6. Back up a directory over SSH to `localhost` with `rsync -avz -e ssh`.

**Hard (cyber)**
7. Make an encrypted backup (`tar | gpg`), delete the originals in your lab dir, restore from the encrypted file, verify with `diff -r`.
8. Build a malicious-looking test archive safely: create `evil.tar` containing a file stored with path `../outside.txt` (use Python: `python3 -c "import tarfile; t=tarfile.open('evil.tar','w'); t.add('file', arcname='../outside.txt'); t.close()"`). Inspect with `tar -tvf`, observe what GNU tar does on extraction (warning/refusal), and clean up. Explain how to detect it before extracting.
9. Reproduce the wildcard problem harmlessly: in an empty directory create files `a`, `b`, and one named `--verbose`; run `echo tar cf x.tar *` (just echo) and then `ls -- *`. Explain what would happen with the real command and how `./*` or `--` fixes it.
10. Write a 3-2-1 backup plan for your lab (what, where, how often, how verified) in `~/linux-lab/backup-plan.md`. Include a monthly restore test.

## 7. Common mistakes
- Forgetting `-C` and extracting into the wrong place
- Missing trailing slash behavior in `rsync`
- Using `--delete` without a dry-run
- Never testing restores
- Backing up to the same disk as the original

## 8. Quiz
1. What does `tar -tzf` do?
2. `rsync src dst` vs `rsync src/ dst`?
3. What does the "1" in 3-2-1 mean?
4. Name two risks of extracting untrusted archives.
5. How can wildcards cause command injection with `tar`?

<details><summary>Answers</summary>

1. Lists the contents of a gzip-compressed tar archive without extracting.
2. Without the slash it copies the directory itself into dst; with it, only the contents.
3. One copy stored off-site.
4. Path traversal/overwriting system files, decompression bombs, malicious symlinks or setuid files.
5. File names that look like options (`--checkpoint-action=...`) get interpreted by `tar` after the shell expands `*`.
</details>

## 9. Mastery checklist
- [ ] I create, list and extract tar/zip archives reliably
- [ ] I mirror and back up with `rsync`, dry-run first
- [ ] I encrypt and verify backups
- [ ] I inspect untrusted archives before extracting
- [ ] I can design and test a 3-2-1 backup plan

## Next → `19-regular-expressions.md` (next batch, with chapters 20–23 and Checkpoint 3)
