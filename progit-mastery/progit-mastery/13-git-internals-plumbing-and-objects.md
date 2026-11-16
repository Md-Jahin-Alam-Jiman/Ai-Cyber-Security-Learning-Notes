# 13 · Git Internals: Plumbing, Objects, References, Packfiles and Recovery
> Book reference: Pro Git, Chapter 10, "Git Internals" (book pp. 431–~480)
> Level: Advanced · Est. time: 4–5 h
> All labs are local and were run on Git 2.43. Hashes in your run will differ unless noted (blob hashes of fixed content are identical everywhere; commit hashes contain timestamps).

## 1. Why this matters
Everything you have learned is built from four things: **objects** (blob, tree, commit, tag), **references** (names pointing at objects), the **index**, and **packfiles/transfer protocols**. Once you can build a commit by hand with plumbing commands, Git stops being magic: you can reason about `reset`, `rebase`, `gc`, "lost" commits, and corrupted repos with confidence.

## 2. Prerequisites
- Everything through [10-git-tools-submodules-bundling-replace-and-credentials.md](10-git-tools-submodules-bundling-replace-and-credentials.md); especially the three trees in [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md) and reflog in [07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md).
- [04-git-on-the-server.md](04-git-on-the-server.md) for the dumb vs smart protocol ideas.

## 3. Learning objectives
- [ ] Distinguish plumbing from porcelain.
- [ ] Explain how a blob's SHA-1 is computed and where it is stored.
- [ ] Build blobs, trees and commits by hand with `hash-object`, `update-index`, `write-tree`, `commit-tree`.
- [ ] Explain branches, tags, `HEAD` and remote-tracking refs as files and `packed-refs`.
- [ ] Explain packfiles, deltas and `git gc`; inspect with `verify-pack`, `count-objects`.
- [ ] Read and write refspecs (fetch, push, delete).
- [ ] Describe the dumb and smart transfer protocols.
- [ ] Recover lost commits (`reflog`, `fsck`) and understand what `gc`/`prune` really delete.
- [ ] Remove a huge or secret object from history safely.

## 4. Core concepts

### 4.1 Plumbing and porcelain
**Porcelain** = user-friendly commands (`add`, `commit`, `checkout`, `switch`, `log`). **Plumbing** = low-level building blocks (`hash-object`, `cat-file`, `update-index`, `write-tree`, `commit-tree`, `update-ref`, `rev-parse`, `ls-tree`, `read-tree`, `for-each-ref`, `rev-list`, `fsck`…). Porcelain scripts are composed of plumbing. `.git/` is the entire database:
```
.git/HEAD            current branch pointer          .git/objects/    all content
.git/config          repo config                     .git/refs/       branches/tags/remotes
.git/index           staging area (binary)           .git/hooks/, .git/info/, .git/packed-refs ...
```

### 4.2 Objects: a content-addressable file system
Git is a key→value store; the key is the **hash of the content**. Four object types:
| Type | Holds |
|------|-------|
| **blob** | a file's bytes (no name, no mode) |
| **tree** | a directory: lines of `mode type sha name` pointing at blobs and subtrees |
| **commit** | one tree sha, 0..n parent shas, author, committer, message |
| **tag** (annotated) | a pointer to an object plus tagger and message |

**How the id is computed:** `sha1("<type> <size in bytes>\0" + content)`. Stored at `.git/objects/<first 2 hex>/<remaining 38 hex>`, **zlib-compressed**. (Git is moving to SHA-256 repos via `git init --object-format=sha256`; the principle is identical.)
- Same content → same object → automatic de-duplication. Identical files in different commits/dirs cost one blob.
- Immutable: change a byte and you get a new id. A commit id depends on its tree and parents, so it covers the whole history (a Merkle DAG).
- A **tree** records modes: `100644` file, `100755` executable, `120000` symlink, `040000` tree, `160000` gitlink (submodule).
- A commit with two parents is a merge.

### 4.3 The index
`.git/index` is a sorted list of `mode sha stage path` entries: the proposed next tree. `git add` = write blob + update index entry. `git commit` = `write-tree` + `commit-tree` + `update-ref`. Stage numbers 1/2/3 are conflict versions (see [09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md)).

### 4.4 References
A **ref** is a file whose content is a SHA (or another ref). Branch = `refs/heads/<n>`; remote-tracking = `refs/remotes/<remote>/<n>`; tag = `refs/tags/<n>`. Always change them with `git update-ref`, not by editing files (it keeps the reflog correct and is atomic).
- **HEAD** is normally a **symbolic ref** (`ref: refs/heads/main`); detached HEAD stores a raw SHA. `git symbolic-ref HEAD`.
- **Tags:** *lightweight* = a ref directly to a commit; *annotated* = a ref to a tag **object** (which points to the commit). `v2^{}` peels a tag to its target.
- **`packed-refs`**: after `git gc`, loose ref files are consolidated into this one file (loose refs still override).
- `refs/stash`, `refs/notes/*`, `refs/replace/*` are other namespaces; `reflogs` live under `.git/logs/`.

### 4.5 Packfiles
Loose objects are one file each; Git **packs** them (`git gc`, `git push`, or automatically when there are many loose objects) into a `.pack` plus an `.idx`. Similar objects are stored as **deltas** against a base, so history of a changing file costs little (the **latest** version is normally stored whole, older versions as deltas). Tools: `git count-objects -v`, `git verify-pack -v <idx>` (type, size, packed size, offset, delta depth, base sha), `git gc [--aggressive] [--prune=<when>]`, `git repack -a -d`. Additional files in modern Git: `commit-graph`, `.rev`, `.mtimes`: caches for speed.

### 4.6 Refspecs
Format `[+]<src>:<dst>`: *source pattern on one side : destination pattern on the other*. `+` = allow non-fast-forward.
- **Fetch** default (written by `git remote add`): `+refs/heads/*:refs/remotes/origin/*` (remote branches → local remote-tracking refs). Add `fetch = +refs/pull/*/head:refs/remotes/origin/pr/*` for GitHub PRs.
- **Push:** `git push origin main:refs/heads/qa/main` (local → differently named remote branch); `git push origin :branch` or `--delete` (empty source = delete); config `remote.<r>.push`.
- Command-line refspecs: `git fetch origin main:refs/remotes/origin/mymain`.
- `git ls-remote <remote>` lists the refs a server advertises.

### 4.7 Transfer protocols
- **Dumb (HTTP):** client fetches files with plain GET: `info/refs`, `HEAD`, then loose objects by hash (or `objects/info/packs` + packs) walking from the commit's tree & parents. Works on any static web server; slow, no push.
- **Smart:** client runs `upload-pack` (fetch) / `receive-pack` (push) on the server (via SSH, `git://`, or smart HTTP `git-upload-pack`). Both sides negotiate what they have (have/want lists), the server builds a **single thin packfile** with only the missing objects. This is why `git push` of large histories is efficient.
- `GIT_TRACE_PACKET=1`, `GIT_TRACE=1`, `GIT_CURL_VERBOSE=1` show what's happening.

### 4.8 Maintenance and data recovery
- **Auto gc** runs after commands when loose objects pile up (~7000) or packs exceed 50: `git gc --auto`. 💡 Newer Git also offers `git maintenance start` for scheduled background tasks.
- **Unreachable** objects are not deleted immediately: reflog entries keep commits reachable (default 90 days; 30 days for unreachable), and `gc --prune` has a grace period (2 weeks) so concurrent operations are safe.
- **Recovery ladder:** (1) `git reflog` → `git branch rescue <sha>`; (2) if the reflog is gone, `git fsck --lost-found` / `git fsck --unreachable --no-reflogs` finds **dangling commits/blobs**; (3) for stray stash-like commits, `git log --merges --no-walk $(git fsck --no-reflogs | awk '/dangling commit/ {print $3}')`.
- Real deletion: `git reflog expire --expire=now --all && git gc --prune=now`.
- **Removing a big/secret object from history:** find it (`git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sort -k3 -n | tail`), then rewrite with `git filter-repo --path <p> --invert-paths` (preferred) or `git filter-branch --index-filter 'git rm --cached --ignore-unmatch <p>' -- --all`, expire reflogs, `gc --prune=now`. **Rewriting changes every later SHA; coordinate with everyone; rotate any leaked secret anyway.** Remote hosts may keep the old objects cached (ask them to garbage collect).
- **Environment variables:** `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_OBJECT_DIRECTORY`, `GIT_AUTHOR_*`/`GIT_COMMITTER_*` (control identity & dates), `GIT_EDITOR`, `GIT_PAGER`, `GIT_SSH_COMMAND`, `GIT_TRACE*`.

## 5. Command cheat sheet
| Command | What it does |
|---------|--------------|
| `git hash-object [-w] [--stdin] <file>` | Compute (and with `-w` store) a blob id |
| `git cat-file -t/-s/-p <sha>` | Type / size / pretty content |
| `git cat-file --batch-check` / `--batch` | Bulk lookups |
| `git update-index --add [--cacheinfo mode,sha,path] <file>` | Stage by hand |
| `git ls-files -s` | Show index entries |
| `git write-tree` | Snapshot the index as a tree |
| `git read-tree [--prefix=dir/] <tree>` | Load a tree into the index (optionally as a subdir) |
| `git commit-tree <tree> [-p parent] [-m msg]` | Create a commit object |
| `git update-ref <ref> <sha>` / `-d` | Move/delete a ref safely |
| `git symbolic-ref HEAD [<ref>]` | Read/set HEAD |
| `git rev-parse <name>` | Resolve a name to a sha |
| `git for-each-ref` | List refs with formats |
| `git ls-tree [-r] <tree>` | List a tree |
| `git count-objects -v` / `git verify-pack -v` | Object-store and pack stats |
| `git gc [--prune=now]` / `git repack` | Pack, prune |
| `git fsck [--lost-found] [--unreachable]` | Integrity & dangling objects |
| `git ls-remote <remote>` | List remote refs |

## 6. Hands-on labs
Setup (sandboxed config):
```bash
mkdir -p ~/git-labs/13 && cd ~/git-labs/13
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
LAB="$PWD"
```

### Lab 1 · Blobs: the object database by hand
```bash
cd "$LAB" && rm -rf t && git init -q t && cd t
find .git/objects -type f | wc -l                        # 0 (only empty dirs)
echo 'test content' | git hash-object -w --stdin         # d670460b4b4aece5915caf5c68d12f560a9fe3e4 (same on every machine)
find .git/objects -type f                                 # .git/objects/d6/70460b…
git cat-file -t d670460b; git cat-file -s d670460b; git cat-file -p d670460b
# Prove the hash formula yourself
printf 'blob 13\0test content\n' | sha1sum                # same hash
python3 -c "import zlib;print(zlib.decompress(open('.git/objects/d6/70460b4b4aece5915caf5c68d12f560a9fe3e4','rb').read()))"
# Versions are just different blobs
echo 'version 1' > test.txt; git hash-object -w test.txt
echo 'version 2' > test.txt; git hash-object -w test.txt
git cat-file -p 83baae61                                  # version 1 (retrievable by hash)
```
**Expected:** hash `d670460b…`, type `blob`, size `13`, and the Python line prints `b'blob 13\x00test content\n'`.

### Lab 2 · Trees and the index by hand
```bash
git update-index --add --cacheinfo 100644 83baae61804e65cc73a7201a7252750c76066a30 test.txt
git ls-files -s                                           # 100644 83baae61… 0   test.txt
T1=$(git write-tree); echo $T1; git cat-file -t $T1; git cat-file -p $T1
echo 'new file' > new.txt && git update-index --add new.txt
T2=$(git write-tree); git cat-file -p $T2                 # two entries
git read-tree --prefix=bak $T1                            # tree 1 mounted as subdirectory bak/
T3=$(git write-tree); git cat-file -p $T3                 # includes: 040000 tree … bak
git ls-tree -r $T3
```
**Expected:** tree listings as annotated; `bak` appears as `040000 tree`.

### Lab 3 · Commits by hand
```bash
C1=$(echo 'first commit'  | git commit-tree $T1);        git cat-file -p $C1       # tree, author, committer, no parent
C2=$(echo 'second commit' | git commit-tree $T2 -p $C1)
C3=$(echo 'third commit'  | git commit-tree $T3 -p $C2)
git log --stat $C3                                        # a normal-looking history though no branch exists yet
```
**Expected:** three commits chained by `parent`. You just did what `git add` + `git commit` do.

### Lab 4 · References, HEAD, tags
```bash
git update-ref refs/heads/main $C3
git log --oneline main; cat .git/refs/heads/main          # file containing the commit sha
git symbolic-ref HEAD                                     # refs/heads/main
git update-ref refs/tags/v1 $C1                           # lightweight tag
git tag -a v2 $C2 -m "annotated"                          # tag object
cat .git/refs/tags/v2; git cat-file -p v2                 # tag object content: object/type/tag/tagger
git rev-parse v2; git rev-parse 'v2^{}'                   # tag-object sha vs the commit it peels to
git cat-file -t v1; git cat-file -t v2                    # commit vs tag
git update-ref refs/remotes/origin/main $C2; cat .git/refs/remotes/origin/main
git checkout -q $C1 2>&1; cat .git/HEAD                   # detached: raw sha
git switch -q main; cat .git/HEAD                         # ref: refs/heads/main
```
**Expected:** a branch is a 41-byte file; a lightweight tag points at a commit, an annotated tag at a tag object.

### Lab 5 · Packfiles and `gc`
```bash
git reset -q --hard main
for i in 1 2 3 4 5; do seq 1 3000 > big.txt; echo $i >> big.txt; git add big.txt; git commit -qm "c$i"; done
find .git/objects -type f | grep -v -e pack -e info | wc -l       # many loose objects
du -sk .git | cut -f1
git gc -q
find .git/objects -type f | grep -v -e pack -e info | wc -l       # 0 loose objects
git count-objects -v                                      # in-pack: N, count: 0
git verify-pack -v .git/objects/pack/*.idx | sort -k3 -n | tail -5   # type, size, packed-size, offset [depth base]
cat .git/packed-refs                                      # refs consolidated here
```
**Expected:** loose objects collapse into a pack; `verify-pack` shows some blobs as deltas (extra columns: depth and base sha); `packed-refs` lists branches/tags.

### Lab 6 · Refspecs and remotes
```bash
cd "$LAB" && git init -q --bare srv.git && cd t
git remote add origin ../srv.git
git config --get-all remote.origin.fetch                  # +refs/heads/*:refs/remotes/origin/*
git push -q origin main && git fetch -q && git branch -r
git push origin main:refs/heads/qa/main                   # push under a different name
git ls-remote origin                                      # HEAD, main, qa/main
git push origin :refs/heads/qa/main                       # delete it (empty source)
git ls-remote origin | wc -l                              # 2 (HEAD, main)
git config remote.origin.push 'refs/heads/main:refs/heads/main'   # default push refspec
git fetch origin main:refs/remotes/origin/mirror          # command-line refspec
git branch -r
```
**Expected:** push/delete via refspecs reflected in `ls-remote`; `origin/mirror` appears.

### Lab 7 · Data recovery
```bash
cd "$LAB" && rm -rf rec && git init -q rec && cd rec
for i in 1 2 3; do echo $i > f; git add f; git commit -qm "c$i"; done
LOST=$(git rev-parse HEAD); git reset -q --hard HEAD~2     # "lose" two commits
git log --oneline                                          # only c1
git reflog | head -4                                       # find the lost sha
git branch rescue $LOST && git log --oneline rescue       # recovered via reflog
git branch -D rescue -q
git reflog expire --expire=now --all                       # wipe the safety net
git fsck --lost-found | grep commit                        # dangling commit(s) still on disk
git branch rescue2 $LOST && git log --oneline rescue2 | head -1    # recovered via fsck
git branch -D rescue2 -q
git reflog expire --expire=now --all; git gc -q --prune=now         # now truly deleted
git fsck --lost-found | grep -c commit                     # 0
git cat-file -t $LOST 2>&1 | head -1                       # fatal: git cat-file: could not get object info
```
**Expected:** recovery works until `reflog expire` **and** `gc --prune=now` have both run; afterwards the commit is gone for good.

### Lab 8 · Find the biggest objects and purge a file from history
```bash
cd "$LAB" && rm -rf big && git init -q big && cd big
echo code > a.c; git add .; git commit -qm code
head -c 2000000 /dev/urandom > huge.bin; git add .; git commit -qm "oops huge"
git rm -q huge.bin; git commit -qm "remove huge"           # still in history!
du -sk .git | cut -f1                                      # ~2000 KB
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sort -k3 -n | tail -2
git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch -q huge.bin' -- --all 2>&1 | tail -1
rm -rf .git/refs/original && git reflog expire --expire=now --all && git gc -q --prune=now
du -sk .git | cut -f1                                      # back to ~170 KB (mostly sample hooks)
git log --oneline
```
**Expected:** the big blob listed with its size; after the purge `.git` drops from ~2 MB to ~170 KB (the sample hooks); the `oops huge` commit remains, now empty. (`filter-branch` prints a deprecation warning; `git filter-repo` is the modern tool but not installed in the sandbox.)

### Lab 9 · Capstone: write `mini-commit`
Write a shell script `mini-commit.sh "<msg>"` that does what `git commit -a` does using only plumbing: `git add -A` is allowed for staging, then `write-tree`, `commit-tree` with the current branch's tip as parent (omit `-p` for the first commit), `update-ref` for the current branch (from `symbolic-ref HEAD`), then verify with `git log`, `git fsck`, and `git status` (clean).

## 7. Practice challenges
1. Compute a blob's SHA-1 without Git using Python's `hashlib`, for a file you choose; compare with `git hash-object`.
2. Create a tree containing a nested directory `a/b/c.txt` by hand and read it with `ls-tree -r -t`.
3. Make a **merge commit** with `commit-tree -p A -p B` and show `git log --graph`.
4. Create a branch and delete it with only `update-ref`; show it in `reflog`.
5. Make two identical files in different directories and prove only one blob exists.
6. Compare size of `.git` for 20 small edits to a 1 MB text file before and after `git gc`.
7. Use `GIT_AUTHOR_DATE`/`GIT_COMMITTER_DATE` to craft a commit dated 2020-01-01 and verify with `git log --format=%ad`.
8. Write a fetch refspec that mirrors only `refs/heads/release/*` into `refs/remotes/rel/*`.

<details><summary>Hints</summary>

1. `hashlib.sha1(b'blob %d\0' % len(data) + data).hexdigest()`.
2. Build the inner file blob, `update-index --add --cacheinfo 100644 <sha> a/b/c.txt`, `write-tree`; Git creates the subtrees automatically.
3. `git commit-tree <tree> -p $A -p $B -m merge`.
4. `git update-ref refs/heads/x $C`, then `git update-ref -d refs/heads/x`.
5. `git hash-object` both, or `git count-objects -v` after `git add`.
6. Append a line each time and commit; `du -sk .git` before/after.
7. `GIT_COMMITTER_DATE="2020-01-01T00:00:00" GIT_AUTHOR_DATE=... git commit ...`.
8. `git config remote.origin.fetch '+refs/heads/release/*:refs/remotes/rel/*'`.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Editing `.git/refs/...` files by hand | Use `git update-ref` (keeps reflog consistent) |
| "Lost" commits after reset/rebase | `git reflog` → `git branch rescue <sha>` |
| Reflog already expired | `git fsck --lost-found` (works until `gc --prune`) |
| Ran `gc --prune=now` and need it back | Only luck: other clones, hosting service, backups. Treat as gone |
| Blob "removed" but repo is still large | It's still in history; rewrite history, expire reflog, `gc --prune=now` |
| Secret committed and pushed | Rotate it first; then rewrite and force-push; hosting caches and forks may retain it |
| `git filter-branch` leaves old data | Remove `refs/original`, expire reflog, gc |
| `commit-tree` prints nothing/fails | It needs a **tree** sha (not a commit/blob); message comes from `-m` or stdin |
| Manual `echo > .git/HEAD` | Use `git symbolic-ref HEAD refs/heads/x` |
| Packed refs ignored? | A loose ref file overrides `packed-refs` of the same name; delete with `update-ref -d` |

## 9. Real-world use cases
- Diagnosing "where did my commit go" and corruption (`fsck`) incidents.
- Cleaning repos: purging binaries, secrets, or old history; sizing and tuning repos (`gc`, `repack`, partial clone).
- Writing tools on top of Git (CI systems, importers, static-site publishers) using plumbing like `commit-tree`/`update-ref` to commit without a working tree.
- Understanding hosting behaviours: shallow/partial clones, packfile negotiation, why force-pushed objects linger.

## 10. Self-check quiz
1. How is a blob's id computed?
2. Why do two identical files share storage?
3. What does a tree entry contain? What does a commit contain?
4. Which plumbing commands does `git commit` effectively run (in order)?
5. Difference between a lightweight and an annotated tag at object level?
6. What is stored in `.git/HEAD` on a branch vs detached?
7. What does `+refs/heads/*:refs/remotes/origin/*` mean?
8. How do you delete a remote branch with a refspec?
9. Why are old versions of a file often stored as deltas of the newer one?
10. After a bad `reset --hard`, which command do you try first? Which second?
11. Which two steps make unreachable objects permanently disappear?

<details><summary>Answers</summary>

1. `sha1("blob <size>\0" + content)`.
2. Same content → same hash → same object.
3. Tree: mode, type, sha, name per entry. Commit: tree, parents, author, committer, message.
4. `write-tree`, `commit-tree` (with parent), `update-ref` (move branch).
5. Lightweight: ref → commit. Annotated: ref → tag object → commit.
6. `ref: refs/heads/<branch>` vs a raw commit sha.
7. Fetch every remote branch into a remote-tracking ref of the same name; `+` allows non-fast-forward updates.
8. `git push origin :branch` (empty source) or `--delete`.
9. Recent versions are accessed most often; storing the tip whole and history as deltas keeps checkouts fast.
10. `git reflog`, then `git fsck --lost-found`.
11. Expire reflog entries (`reflog expire --expire=now --all`) and `git gc --prune=now`.
</details>

## 11. Mastery checklist & next step
- [ ] Build a repo from nothing using only plumbing and explain each object produced.
- [ ] Explain refs, HEAD, tags, packed-refs and where each is stored.
- [ ] Read a refspec and write fetch/push/delete refspecs.
- [ ] Explain packs and the smart protocol in two minutes.
- [ ] Recover deleted commits and purge a file from history safely.

**Next:** [14-appendix-a-git-in-other-environments.md](14-appendix-a-git-in-other-environments.md): using Git from IDEs, shells, GUIs and scripting languages.
