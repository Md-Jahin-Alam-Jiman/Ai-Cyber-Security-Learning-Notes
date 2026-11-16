# 12 · Git and Other Systems: Subversion, Mercurial, Perforce and Migration
> Book reference: Pro Git, Chapter 9, "Git as a Client", "Migrating to Git" (book pp. 367–~430)
> Level: Intermediate–Advanced · Est. time: 3 h
> 🌐 Labs 1–2 need a Subversion install (`svn`, `git svn`), which the sandbox used to test this file did **not** have, so those commands are **untested here**. Labs 3–5 (fast-import, custom importer, history rewriting) were run and verified.

## 1. Why this matters
Most real organisations do not switch to Git overnight. You will meet Subversion (SVN), Mercurial, Perforce or CVS servers that you must keep using, or move away from while **keeping history**. This chapter gives you two skills: (1) use Git as a *client* to a non-Git server, and (2) *migrate* a repository to Git cleanly, including writing your own importer.

## 2. Prerequisites
- [03-git-branching-and-merging.md](03-git-branching-and-merging.md), [05-distributed-git-workflows.md](05-distributed-git-workflows.md), [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md).
- Helpful: [13-git-internals-plumbing-and-objects.md](13-git-internals-plumbing-and-objects.md) (fast-import writes objects for you).

## 3. Learning objectives
- [ ] Explain how Git bridges to another VCS (`git svn`, `git-remote-hg`, `git p4`, Git Fusion).
- [ ] Run the `git svn` workflow: clone, commit locally, `dcommit`, `rebase`.
- [ ] Understand why `git svn` forces **linear history** (rebase, never merge back).
- [ ] Migrate SVN/Mercurial/Perforce history with the right tool and an authors map.
- [ ] Write a custom importer that emits a **`git fast-import`** stream.
- [ ] Clean up after migration (rename branches/tags, strip junk, verify).

## 4. Core concepts

### 4.1 The bridge idea
Git is distributed; SVN/Perforce are centralised. A bridge keeps your **local Git repository** as the working environment and translates to/from the central server on demand. You get fast local branches, stash, rebase and offline commits; the server sees only normal commits.

| System | Bridge | Notes |
|--------|--------|-------|
| Subversion | `git svn` (ships with Git; needs the SVN Perl bindings) | Most common. Linear history only |
| Mercurial | `git-remote-hg` (third-party) or `hg-git` (on the Mercurial side) | Bookmarks ↔ branches |
| Perforce | `git p4` (ships with Git) or Perforce Git Connector/Git Fusion | Needs `p4` client |
| TFS/Azure DevOps | `git-tfs`, or their native Git repos (preferred today) | |
| CVS, Bazaar, others | converters (`cvs2git`, `git-bzr`) or custom `fast-import` | |
💡 Modern note: most teams now **migrate once** and retire the old server, rather than bridging forever. Use a bridge as a transition.

### 4.2 Git and Subversion (`git svn`)
**Setup.** SVN repos usually have `trunk/`, `branches/`, `tags/`. Clone:
```bash
git svn clone -s https://svn.example.com/project        # -s = standard layout (trunk, branches, tags)
git svn clone -s --authors-file=authors.txt URL         # map SVN usernames to Git identities
git svn clone -s -r1234:HEAD URL                        # only recent revisions (much faster)
```
It fetches every revision as a commit and stores the SVN revision in each message as a trailer: `git-svn-id: URL@REV UUID`. Remote branches appear as `remotes/origin/trunk`, `remotes/origin/<branch>`, `remotes/origin/tags/<tag>`.

**Authors file** (`authors.txt`) one line per SVN user:
```
jdoe = Jane Doe <jane@example.com>
```
Generate the user list from SVN with `svn log --xml | grep -P "^<author" | sort -u`.

**Daily loop**
```bash
git switch -c fix-login            # local branch, free to use
# ... edit, commit as usual, as many commits as you like ...
git svn rebase                     # fetch new SVN revisions and rebase your work on top
git svn dcommit                    # send each local commit to SVN as one revision
```
- `dcommit` **rewrites** your commits (adds the `git-svn-id` line), so your SHAs change. Run it from a branch that is rebased onto `trunk`.
- Pulling = `git svn rebase`, **not** `git pull` (a merge would create history SVN cannot represent).
- `git svn dcommit --dry-run` previews; `git svn log`, `git svn blame`, `git svn info`, `git svn show-ignore` (or `git svn create-ignore`) mirror SVN commands.

**Branching.** Git branches are *local*. To work against an SVN branch: `git checkout -b mybranch remotes/origin/branch-name`; `git svn dcommit` goes to that branch. Create a real SVN branch with `git svn branch name`. **Do not merge** locally and then dcommit: SVN doesn't understand merge commits. Squash-merge (`git merge --squash`) or cherry-pick instead, so history stays linear.

**Rules for sharing with other Git users around an SVN server:** never push to a *separate* Git server a branch that you also `dcommit`, because dcommit rewrites SHAs. If you must share, share only commits that have already been dcommitted (they have `git-svn-id`).

### 4.3 Git and Mercurial / Perforce (client use)
- **Mercurial:** `git clone hg::https://host/repo` (with `git-remote-hg` on PATH) then ordinary `git fetch/push`; hg bookmarks become branches; hg named branches appear under `branches/`.
- **Perforce:** `git p4 clone //depot/path@all` (all history) or `//depot/path` (latest only); work in Git; `git p4 sync` to pull; `git p4 submit` to push each commit as a changelist. Large depots: import only the paths/changes you need.
- Both treat the other server as the source of truth. Same caution: keep history linear when submitting.

### 4.4 Migrating to Git
**Subversion → Git**
1. Make an authors file (`svn log --xml | …`).
2. `git svn clone -s --no-metadata --authors-file=authors.txt URL project` (`--no-metadata` drops the `git-svn-id` lines for a one-way move; omit it if you'll keep syncing).
3. Convert `remotes/origin/tags/*` to real tags and `remotes/origin/*` to local branches:
```bash
git for-each-ref refs/remotes/origin/tags | cut -d / -f 5- |
  while read t; do git tag "$t" "refs/remotes/origin/tags/$t"; git branch -r -d "origin/tags/$t"; done
for b in $(git for-each-ref --format='%(refname:short)' refs/remotes); do git branch "${b#origin/}" "refs/remotes/$b"; done
```
4. Remove `git-svn` leftovers (`trunk` → `main`; a leftover `@NNN` branch usually means an SVN copy artefact), add the new remote, push everything.
💡 Large or messy SVN repos: also look at **`svn2git`** (Ruby wrapper) or **`reposurgeon`**, which handle odd layouts and tag/branch cleanup better.

**Mercurial → Git:** `hg-fast-export`: `git init repo; cd repo; hg-fast-export.sh -r /path/to/hg-repo; git checkout HEAD`. Mercurial bookmarks/branches map to Git branches; tags convert.
**Perforce → Git:** `git p4 clone //depot/project@all` and fix up; for huge depots, a staged approach (history by branch) or Git Fusion.
**Anything else → Git:** custom `fast-import`.

### 4.5 `git fast-import` and `fast-export`
**`git fast-import`** reads a simple text stream and builds the objects directly: far faster and more robust than running `git add/commit` thousands of times. Stream grammar (core commands):
```
commit refs/heads/main
mark :1                                   # label to refer back to
committer Name <email> <unix-seconds> +0000
data <byte-count>
<exactly that many bytes of commit message>
from :0                                   # parent (mark or sha); omit for root
deleteall                                  # start from an empty tree...
M 100644 inline path/file.txt              # ...then add files (mode, inline data)
data <byte-count>
<file content>
```
Also: `author`, `merge :n` (second parent), `tag`, `blob`/`reset`, `D path` (delete), `R old new` (rename). `data <n>` byte counts must be exact, so a custom importer's main job is counting bytes correctly (use bytes, not characters).

**`git fast-export`** is the reverse: it dumps a repository as a stream, which you can transform with a script and re-import. That is the mechanism behind rewrite tools such as `git filter-repo` (the recommended replacement for `git filter-branch`; separate install).

**Pattern for a custom importer.** Your script walks the legacy source (here: a folder of dated snapshots), prints a stream on stdout, and you pipe it: `python3 import.py backups | git fast-import`.

### 4.6 After any migration, check
- Commit count and a sampling of dates/authors per branch.
- A file-level diff of the final trees: export the old VCS head and compare with `git archive HEAD | tar -x` + `diff -r`.
- Tags and branches present and named correctly; no `@123` strays; large files noticed (consider LFS) before pushing.
- `git gc --aggressive --prune=now` on the new repo, then push; tell the team the old server is read-only.

## 5. Command cheat sheet
| Command | What it does |
|---------|--------------|
| `git svn clone -s URL` | Import SVN (trunk/branches/tags) |
| `git svn clone -s --authors-file=f URL` | Map authors |
| `git svn rebase` | Fetch + rebase onto SVN |
| `git svn dcommit [--dry-run]` | Send local commits to SVN |
| `git svn branch <name>` | Create an SVN branch |
| `git svn blame/log/info` | SVN-style views |
| `git p4 clone //depot/path@all` / `sync` / `submit` | Perforce bridge |
| `git fast-export [--all]` | Dump a repo as a stream |
| `git fast-import` | Build a repo from a stream |
| `git for-each-ref --format=... refs/remotes/origin/tags` | Enumerate refs to convert |
| `git tag <name> <ref>` / `git branch <name> <ref>` | Promote remote refs to real tags/branches |

## 6. Hands-on labs
### Lab 1 · `git svn` against a local SVN repo (🌐 untested here, needs `svn`)
```bash
svnadmin create ~/svnrepo && svn mkdir -m layout file://$HOME/svnrepo/{trunk,branches,tags}
svn co file://$HOME/svnrepo/trunk ~/svnwc && cd ~/svnwc && echo one > a && svn add a && svn commit -m "first"
git svn clone -s file://$HOME/svnrepo ~/gitsvn && cd ~/gitsvn
git log --oneline && git log -1 | grep git-svn-id
echo two >> a && git commit -am "second from git"
git svn dcommit && svn log file://$HOME/svnrepo/trunk | head
```
**Expected:** two SVN revisions; Git log shows `git-svn-id` lines; the Git commit became SVN revision 3 (rewritten SHA).

### Lab 2 · Bridge workflow (🌐 untested here)
Create an SVN branch with `git svn branch feature`; commit locally; `git svn dcommit`; then simulate another developer committing in `~/svnwc`; run `git svn rebase` and confirm the history stays linear (`git log --graph` shows no merge).

### Lab 3 · Hand-written fast-import stream (tested)
```bash
mkdir -p ~/git-labs/12 && cd ~/git-labs/12
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
git init -q fi && cd fi
printf 'commit refs/heads/main\nmark :1\ncommitter Ann <ann@example.com> 1577836800 +0000\ndata 6\nfirst\nM 100644 inline hello.txt\ndata 6\nhello\n\n' | git fast-import --quiet
printf 'commit refs/heads/main\nmark :2\ncommitter Bob <bob@example.com> 1577923200 +0000\ndata 7\nsecond\nfrom refs/heads/main^0\nM 100644 inline hello.txt\ndata 12\nhello world\n\n' | git fast-import --quiet
git log --format='%h %an %ad %s' --date=iso
git show main:hello.txt
```
**Expected:** two commits by Ann (2020-01-01) and Bob (2020-01-02) with the right content, with no `git add` or `commit` run. Note: `mark :N` labels only live within **one** fast-import run, so a second run must name its parent by ref (`from refs/heads/main^0`).

### Lab 4 · A custom importer: dated snapshot folders → history (tested)
```bash
cd ~/git-labs/12
for v in 1 2 3; do mkdir -p back/2020010$v; echo "v$v" > back/2020010$v/f.txt; [ $v -ge 2 ] && echo extra > back/2020010$v/g.txt; done
cat > import.py <<'PY'
#!/usr/bin/env python3
"""Turn a folder of dated snapshots (YYYYMMDD/) into a fast-import stream."""
import os, sys, calendar, time
out = sys.stdout.buffer
root = sys.argv[1]
def w(s): out.write(s.encode() if isinstance(s, str) else s)
for i, d in enumerate(sorted(os.listdir(root)), 1):
    ts = calendar.timegm(time.strptime(d, "%Y%m%d"))        # UTC midnight
    msg = f"import {d}\n".encode()
    w(f"commit refs/heads/main\nmark :{i}\n")
    w(f"committer Old Timer <old@example.com> {ts} +0000\n")
    w(f"data {len(msg)}\n"); w(msg)                           # byte length, not characters
    if i > 1: w(f"from :{i-1}\n")
    w("deleteall\n")                                         # each snapshot is a complete tree
    for f in sorted(os.listdir(os.path.join(root, d))):
        data = open(os.path.join(root, d, f), "rb").read()
        w(f"M 100644 inline {f}\ndata {len(data)}\n"); w(data); w("\n")
    w("\n")
PY
git init -q imported && cd imported
python3 ../import.py ../back | git fast-import --quiet
git checkout -q -f main
git log --format='%h %ad %an %s' --date=short
git ls-tree -r --name-only main
git diff --stat HEAD~2 HEAD                      # g.txt appeared, f.txt changed
```
**Expected:** 3 commits dated 2020-01-01..03; `main` ends with `f.txt` and `g.txt`; the diff between the last two snapshots matches what changed. Pitfall to try: change `len(data)` to a wrong number and read the `fatal:` message.

### Lab 5 · Export, transform, re-import (tested)
```bash
cd ~/git-labs/12/imported
git fast-export main | head -6                               # blob/mark/data lines
git fast-export main | sed 's/Old Timer/Jane Doe/; s/old@example.com/jane@example.com/' |
  { git init -q ../rewritten && cd ../rewritten && git fast-import --quiet && git log --format='%an <%ae>' | sort -u; }
```
**Expected:** a single author line, `Jane Doe <jane@example.com>`. Real repos are better rewritten with `git filter-repo --mailmap` or `git filter-branch` (see [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md)), but this shows exactly how those tools work.

### Lab 6 · Convert "remote tags" to real tags (tested pattern)
```bash
cd ~/git-labs/12 && rm -rf conv && git init -q conv && cd conv
git commit -q --allow-empty -m base
git update-ref refs/remotes/origin/tags/v1.0 HEAD; git update-ref refs/remotes/origin/trunk HEAD
git for-each-ref refs/remotes/origin/tags | cut -d / -f 5- |
  while read t; do git tag "$t" "refs/remotes/origin/tags/$t"; git update-ref -d "refs/remotes/origin/tags/$t"; done
git tag; git for-each-ref --format='%(refname)' refs/remotes
```
**Expected:** tag `v1.0` exists; only `refs/remotes/origin/trunk` remains. (`git branch -r -d` also works on real clones.)

## 7. Practice challenges
1. Extend `import.py` to read a `CHANGELOG` file in each snapshot and use its first line as the commit message.
2. Make it skip unchanged snapshots (identical to the previous one) instead of creating empty commits.
3. Support subdirectories (walk with `os.walk` and emit `M 100644 inline dir/file`).
4. Add executable-file support (`100755` when the source file has the exec bit).
5. Tag each imported snapshot `snap-YYYYMMDD` with a `tag` command or `git tag` afterwards.
6. Write an `authors.txt` mapping and apply it to `git fast-export` output with a short script.
7. Write a verification script that compares the last snapshot with `git archive HEAD | tar -x`.

<details><summary>Hints</summary>

1. Read the file, take first line, encode, use its byte length in `data`.
2. Compare the dict `{name: bytes}` of this snapshot with the previous; `continue` when equal (keep marks consistent: track the last mark, not `i-1`).
3. `for dp, dn, fn in os.walk(...)`, path = `os.path.relpath(...)` with `/` separators.
4. `os.stat(p).st_mode & 0o111` → mode `100755`.
5. Add `tag snap-X\nfrom :N\ntagger Name <e> ts +0000\ndata n\nmsg` blocks after the commit.
6. Replace `committer` lines using a dict lookup; remember `data` lengths are unaffected for committer lines.
7. `diff -r snapshotdir extracted/` prints nothing when identical.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| `git pull` in a `git svn` repo | Use `git svn rebase`; undo a stray merge with `git reset --hard ORIG_HEAD` |
| Merging then `dcommit` | SVN loses the merge; use squash/cherry-pick to keep history linear |
| Slow SVN clone | `-r<REV>:HEAD`, or clone from a local `svnsync` mirror |
| Wrong authors in imported history | Redo with `--authors-file`, or rewrite after with `filter-repo --mailmap`/`fast-export` + script |
| `fast-import` "Not enough data" / bad `data` count | Count **bytes** (`len(x.encode())`), include the newline you write after data accurately |
| Imported repo has weird `@123` branches or `trunk` | SVN copy artefacts; delete extra refs, rename `trunk`→`main` |
| Huge binaries imported | Find with `git rev-list --objects --all`; move to LFS before sharing |
| Forgot to freeze the old server | Make it read-only at cut-over, else history diverges |

## 9. Real-world use cases
- Enterprise moves from SVN/Perforce/TFVC to Git hosting with history intact.
- Gradual adoption: developers use Git locally while CI and release still run on SVN.
- Archaeology: importing zip/tarball backups into Git to get `blame`/`bisect` on ancient code.
- Splitting or merging repositories by exporting, filtering and re-importing a stream.

## 10. Self-check quiz
1. Why does `git svn` require linear history?
2. What does `git svn dcommit` do to your commit SHAs, and why?
3. Why use `git svn rebase` instead of `git pull`?
4. What are the three things a custom importer must produce for each commit in a fast-import stream?
5. Why is `git fast-import` preferred over looping `git commit`?
6. What does `deleteall` do in a stream?
7. How do you turn `remotes/origin/tags/x` into a real tag?
8. What's an authors file for?

<details><summary>Answers</summary>

1. SVN has no real concept of merge commits; Git merges can't be expressed in it.
2. It rewrites them to add the `git-svn-id` trailer after sending each to SVN.
3. A pull creates merges; rebase keeps your commits on top of SVN's linear history.
4. Committer (and optional author) with timestamp, message via `data <bytes>`, and file changes (`M`/`D`) plus `from` for the parent.
5. It writes objects directly: much faster, no working tree, precise control of dates/authors.
6. Empties the tree so the commit lists only the files you then add.
7. `git tag x refs/remotes/origin/tags/x`, then delete the remote ref.
8. Maps SVN usernames to proper Git name/email identities.
</details>

## 11. Mastery checklist & next step
- [ ] Explain how bridges work and their linear-history constraint.
- [ ] Recite the `git svn` clone → commit → rebase → dcommit loop.
- [ ] Plan an SVN/Perforce/Mercurial migration end-to-end (authors, tags, branches, verification, cut-over).
- [ ] Write and run a fast-import importer from scratch.

**Next:** [13-git-internals-plumbing-and-objects.md](13-git-internals-plumbing-and-objects.md), where you'll see how Git really stores data.
