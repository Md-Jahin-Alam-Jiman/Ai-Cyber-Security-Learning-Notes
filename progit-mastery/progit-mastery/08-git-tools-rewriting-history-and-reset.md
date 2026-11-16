# 08 · Git Tools II: Rewriting History and Reset Demystified
> Book reference: Pro Git, Chapter 7 "Git Tools", sections "Rewriting History" and "Reset Demystified" (book pp. 243–270)
> Level: Intermediate–Advanced · Est. time: 5 h

## 1. Why this matters
Clean history is a professional habit: one logical change per commit, readable messages, no "oops" commits or committed secrets. `amend`, interactive rebase and `filter-branch` let you fix history *before it's shared*, and `reset` is the command everyone fears because they've never seen the model behind it. After this file you'll know exactly what each command changes, and how to recover when you get it wrong.

## 2. Prerequisites
- [03-git-branching-and-merging.md](03-git-branching-and-merging.md): especially rebasing and the **golden rule** (never rewrite shared history).
- [07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md): `HEAD~n`, reflog, `add -p`.

## 3. Learning objectives
- [ ] Amend the last commit's message, content, author and date.
- [ ] Use `git rebase -i` to reword, reorder, drop, squash, fixup, edit and split commits.
- [ ] Use `--autosquash`, `--exec`, `--root`.
- [ ] Remove a file (or secret) from every commit with `filter-branch` (and know `git filter-repo` is preferred).
- [ ] Explain the **three trees** (HEAD, index, working directory).
- [ ] Predict what `reset --soft`, `--mixed`, `--hard`, and `reset <path>` do, and how they differ from `checkout`/`restore`.
- [ ] Squash with `reset --soft`; choose `revert` vs `reset`.
- [ ] Recover from rewrite mistakes via `ORIG_HEAD` and the reflog.

## 4. Core concepts

### 4.1 Rewriting = creating new commits
Commits are immutable. "Changing" one makes a **new commit with a new hash** (and everything after it changes too, since each commit includes its parent's hash). The old commits stay in the object database, reachable via the **reflog** until garbage-collected.

**Rule:** rewrite only commits that **haven't been pushed/shared**. If you must update a pushed branch you own (e.g. a PR branch), use `git push --force-with-lease` (refuses if someone else pushed in the meantime), never plain `--force`.

### 4.2 Changing the last commit
```bash
git commit --amend                       # edit message (opens editor) and include anything staged
git commit --amend -m "New message"
git commit --amend --no-edit             # keep message, add staged changes (forgot a file)
git commit --amend --reset-author        # use your current user.name/email
git commit --amend --date="2020-01-01T10:00:00"
```
Amend *replaces* the tip commit. It's exactly "undo the commit but keep its changes staged, then recommit".

### 4.3 Interactive rebase: the history editor
```bash
git rebase -i HEAD~3        # rewrite the last 3 commits
git rebase -i <commit>^     # …or starting at <commit> (inclusive): the base is its PARENT
git rebase -i --root        # include the very first commit
```
Git opens a **todo list**, **oldest commit first** (the reverse of `git log`), each line `command hash message`. It executes top to bottom, replaying commits on the base.

| Command | Short | Effect |
|---------|-------|--------|
| `pick` | `p` | keep as is |
| `reword` | `r` | keep changes, edit message |
| `edit` | `e` | **stop** so you can amend or split the commit; `git rebase --continue` afterwards |
| `squash` | `s` | meld into the previous commit; combine messages (editor opens) |
| `fixup` | `f` | like squash but discard this commit's message |
| `drop` | `d` | delete the commit (or delete the line; configure `rebase.missingCommitsCheck=error` to be warned) |
| `exec` | `x` | run a shell command (e.g. tests) after the previous commit |
| `label`/`reset`/`merge` | | recreate merge topology (`--rebase-merges`) |
Reorder commits by **reordering lines**. Delete **all** lines (or save an empty list) to abort the whole rebase.

Handy flags:
- `git commit --fixup=<commit>` creates a commit named `fixup! <subject>`; later `git rebase -i --autosquash <base>` auto-places and marks it `fixup`. Set `git config --global rebase.autoSquash true`. (`--squash=<commit>` for squash with a message.)
- `git rebase -x "make test" <base>` (= insert `exec` after each commit): verify every commit builds.
- Conflicts mid-rebase: fix files, `git add`, `git rebase --continue`; or `--skip` (drop this commit) / `--abort` (restore everything).
- Reordering commits that touch the same lines will conflict: that's inherent, not a bug.
- 💡 `git rebase -i --autostash` stashes dirty work for you.

**Splitting a commit:** mark it `edit`; when the rebase stops, `git reset HEAD^` (mixed: un-commit but keep changes in the tree), then stage and commit in pieces (`git add -p`), then `git rebase --continue`.

### 4.4 The "nuclear option": `git filter-branch`
Runs a script against **every commit** in a range, rewriting the whole history. Use for project-wide changes: removing a file from all history, changing an email, extracting a subdirectory as a new repo root.

| Filter | Use |
|--------|-----|
| `--tree-filter 'cmd'` | check out each commit, run `cmd`, recommit (slow: checks out every commit) |
| `--index-filter 'cmd'` | edit the index only (fast): `git rm --cached --ignore-unmatch file` |
| `--env-filter` | change `GIT_AUTHOR_*/GIT_COMMITTER_*` env vars |
| `--msg-filter` | rewrite messages |
| `--subdirectory-filter dir` | make `dir` the new root, discarding everything else |
| `--tag-name-filter cat` | carry tags over to rewritten commits |
| `-- --all` | rewrite all branches and tags |
- A backup of the old refs is kept in `refs/original/`. To truly delete old data: `rm -rf .git/refs/original; git reflog expire --expire=now --all; git gc --prune=now`.
- 💡 **Modern note:** Git itself now says `filter-branch` is deprecated, slow and error-prone. Prefer **`git filter-repo`** (separate Python tool; `git filter-repo --path secrets.txt --invert-paths`) or BFG Repo-Cleaner for secrets. (Not installed here, so untested.)
- **Secrets:** if a password/key was *ever pushed*, treat it as compromised: **rotate it first**, then clean history. Rewriting doesn't un-leak it, and every clone/fork/PR cache keeps the old objects.
- After rewriting a shared repo, **everyone** must re-clone or reset to the new history.

### 4.5 Reset demystified: the three trees
Git manages three "trees" (collections of files):

| Tree | Role |
|------|------|
| **HEAD** | last commit's snapshot; the *parent of the next commit* (via the current branch ref) |
| **Index** | the *proposed next commit* (the staging area) |
| **Working directory** | your sandbox; real files on disk |

Workflow: `checkout`/`clone` fills all three from a commit; you edit the working directory; `git add` copies working → index; `git commit` turns the index into a commit and moves the branch (and HEAD) to it.

### 4.6 What `git reset` does (three steps)
`git reset [--soft|--mixed|--hard] <commit>` performs steps in order and stops at the flag's level:
1. **Move the branch HEAD points to** to `<commit>` (and set `ORIG_HEAD`). *`--soft` stops here.* (This is effectively undoing the last `git commit`s while keeping the changes staged.)
2. **Update the index** to look like HEAD. *`--mixed` (default) stops here.* (Undoes the commits **and** the staging, i.e. `git add`.)
3. **Update the working directory** to look like the index. *`--hard`.* **The only dangerous form:** uncommitted changes to tracked files are overwritten and unrecoverable (except staged ones via `git fsck --lost-found`, since their blobs still exist).

Also `--keep` (like hard but aborts if it would lose local changes) and `--merge`.

**With a path:** `git reset [<commit>] -- <path>` **skips step 1** (can't move part of a branch), and does step 2 only for that path: it copies the file from `<commit>` (default HEAD) into the **index**. So `git reset file` = **unstage** (💡 `git restore --staged file`). `git reset <commit> -- file` stages the old version of the file; the working copy is untouched.

**Squashing with reset:** to combine the last N commits into one, `git reset --soft HEAD~N && git commit` (simpler than interactive rebase for "everything since X").

### 4.7 `checkout` vs `reset` (and `restore`/`switch`)
| Command | HEAD | Index | Workdir | Safe for workdir? |
|---------|:----:|:-----:|:-------:|:-----------------:|
| **Commit level** | | | | |
| `reset --soft <c>` | moves **branch** | no | no | yes |
| `reset [--mixed] <c>` | moves **branch** | yes | no | yes |
| `reset --hard <c>` | moves **branch** | yes | yes | **NO** |
| `checkout <c>` / `switch --detach <c>` | moves **HEAD** itself | yes | yes | yes (aborts if it'd lose changes) |
| **File level** | | | | |
| `reset [<c>] <path>` / `restore --staged` | no | yes | no | yes |
| `checkout [<c>] <path>` / `restore --source=<c>` | no | yes (with `[<c>]`) | yes | **NO** (overwrites) |

Key distinction: `git checkout branch` moves **HEAD** to point at another branch (the current branch is untouched); `git reset branch` moves **the current branch** to point where `branch` points (HEAD still points at the current branch). `checkout` is "working-directory safe" (it merges trivially or refuses); `reset --hard` isn't.

### 4.8 `reset` vs `revert` (undoing safely)
- `git reset` **rewrites** history: fine locally, wrong for shared branches.
- `git revert <commit>` adds a **new commit** that applies the inverse change. Safe on shared branches. For a merge commit: `git revert -m 1 <merge>` (keep parent 1's side).
- Reverting a merge means Git considers those changes "already merged"; to re-merge the branch later you must first revert the revert.

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git commit --amend [--no-edit]` | Replace last commit | Typo / forgotten file |
| `git rebase -i HEAD~N` | Edit last N commits | Tidy before PR |
| `git commit --fixup=<c>` + `rebase -i --autosquash` | Auto-fold fixes | Small follow-ups |
| `git rebase -x "cmd" <base>` | Run `cmd` after each commit | Verify each commit |
| `git rebase --continue/--skip/--abort` | Control a rebase | Conflicts |
| `git filter-branch --tree/index/env/…-filter` | Rewrite all history | Remove files, change emails |
| `git filter-repo` | Modern replacement | Secrets/large files |
| `git reset --soft/--mixed/--hard <c>` | Move branch (+index/+workdir) | Undo commits |
| `git reset <path>` / `git restore --staged` | Unstage | Fix staging |
| `git reset --soft HEAD~N && git commit` | Squash N commits | Quick squash |
| `git revert [-m 1] <c>` | Inverse commit | Undo on shared branches |
| `git reflog`, `ORIG_HEAD` | Find pre-rewrite state | Recovery |
| `git push --force-with-lease` | Safe force-push | After rewriting your branch |

## 6. Hands-on labs
Setup:
```bash
mkdir -p ~/git-labs/08 && cd ~/git-labs/08
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
export FILTER_BRANCH_SQUELCH_WARNING=1       # silence filter-branch's deprecation pause
```
A helper that makes a 4-commit repo with **independent files** (so reordering doesn't conflict):
```bash
mk() { cd ~/git-labs/08 && rm -rf "$1" && git init -q "$1" && cd "$1" \
       && for i in one two three four; do echo $i > $i.txt; git add .; git commit -qm "$i"; done; }
```

### Lab 1 · Amend
```bash
mk amend
git commit --amend -m "four (fixed message)"
git log --oneline -1
echo extra > five.txt && git add five.txt
git commit --amend --no-edit
git show --stat --oneline HEAD            # five.txt is part of the "four" commit
git commit --amend --reset-author --no-edit --date="2020-01-01T10:00:00"
git log -1 --format='%h %an %ad'
git reflog | head -4                       # old commits are still in the reflog
```
**Expected:** same number of commits throughout; the tip's hash changes every time.

### Lab 2 · Interactive rebase: reword, reorder, drop, squash
All of these use `git rebase -i HEAD~3` on a fresh `mk` repo. The editor shows (oldest first):
```
pick 1111111 two
pick 2222222 three
pick 3333333 four
```
**a) Reword**: `mk rw && git rebase -i HEAD~3`; change `pick` → `reword` on `two`; when the editor opens, change the message to `two (reworded)`; save.
`git log --oneline` → shows the new message; `three` and `four` got new hashes too.

**b) Reorder**: `mk ro && git rebase -i HEAD~3`; swap the `two` and `three` lines (move one line below the other); save.
`git log --format=%s` → `four two three one` (read newest first: `two` now comes after `three`).

**c) Drop**: `mk dr && git rebase -i HEAD~3`; change `pick … two` to `drop` (or delete the line).
`git log --format=%s` → `four three one`; `ls` shows no `two.txt`.

**d) Squash**: `mk sq && git rebase -i HEAD~3`; leave `two` as `pick`, change `three` and `four` to `squash` (or `s`). An editor opens with all three messages: rewrite into one.
`git log --format=%s` → just your squashed message and `one`: **2 commits**; the squashed commit contains `two.txt`, `three.txt`, `four.txt`. (Use `fixup` instead to discard the folded messages automatically.)

**e) Abort and recover**
```bash
git rebase -i HEAD~2        # …start something…
git rebase --abort          # everything returns to the pre-rebase state
```
Scripted (non-interactive) form, handy for CI and for learning what the editor does:
```bash
GIT_SEQUENCE_EDITOR="sed -i '1s/^pick/drop/'" git rebase -i HEAD~3
```

### Lab 3 · Split a commit
```bash
cd ~/git-labs/08 && rm -rf split && git init -q split && cd split
echo base > base && git add . && git commit -qm base
echo a > pa && echo b > pb && git add . && git commit -qm "big commit"
git rebase -i HEAD~1                       # change pick → edit for "big commit"
git reset HEAD^                            # un-commit, keep files; status: ?? pa ?? pb
git add pa && git commit -m "split a"
git add pb && git commit -m "split b"
git rebase --continue
git log --oneline
```
**Expected:** `split b`, `split a`, `base`: the "big commit" became two. (Real life: use `git add -p` to split inside files.)

### Lab 4 · `--fixup`/`--autosquash` and `--exec`
```bash
mk fix
echo fix >> two.txt && git add two.txt
git commit --fixup=HEAD~2                  # creates "fixup! two"  (HEAD~2 = "two")
git log --format=%s | head -2              # fixup! two / four
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash HEAD~4   # `:` accepts the todo as generated
git log --format=%s                        # four three two one (fixup folded into two)
tail -1 two.txt                            # fix
git rebase -i -x "test -f one.txt && echo EXEC-OK" HEAD~2 </dev/null
```
**Expected:** the fixup commit moved right under `two` and was folded in; the `-x` form prints `EXEC-OK` after each replayed commit. (Interactively you'd just save the editor.)

### Lab 5 · `filter-branch`: scrub a file from all history
```bash
cd ~/git-labs/08 && rm -rf fb && git init -q fb && cd fb
for i in 1 2 3; do echo $i > f$i; echo "s3cr3t" > passwords.txt; git add .; git commit -qm "c$i"; done
git log --stat --oneline | grep -c passwords        # 3
git filter-branch --tree-filter 'rm -f passwords.txt' HEAD
git log --stat --oneline | grep -c passwords        # 0 : gone from every commit
git for-each-ref refs/original                       # the backup of the old history
# Really delete the old objects:
rm -rf .git/refs/original
git reflog expire --expire=now --all && git gc -q --prune=now
```
More filters on the same repo:
```bash
git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch f1' HEAD   # fast: index only
git ls-files                                                                    # f2 f3
git filter-branch -f --env-filter '
  if [ "$GIT_AUTHOR_EMAIL" = "jane@example.com" ]; then
    export GIT_AUTHOR_EMAIL=new@example.com GIT_COMMITTER_EMAIL=new@example.com
  fi' HEAD
git log --format=%ae | sort -u                                                  # new@example.com
# Extract a subdirectory as the new project root:
cd .. && rm -rf sd && git init -q sd && cd sd && mkdir trunk && echo a > trunk/a && echo o > other
git add . && git commit -qm t
git filter-branch -f --subdirectory-filter trunk HEAD && ls                     # a
```
**Expected:** comments in the code blocks. All commit hashes differ afterwards. `filter-branch` prints "Ref 'refs/heads/main' was rewritten".
🌐 Modern alternative (untested here, needs `pip install git-filter-repo`): `git filter-repo --invert-paths --path passwords.txt`.

### Lab 6 · Reset: the three trees in action
Helper that recreates a clean state for each experiment:
```bash
demo() { cd ~/git-labs/08 && rm -rf reset-demo && git init -q reset-demo && cd reset-demo
  for v in v1 v2 v3; do echo $v > file.txt; git add .; git commit -qm $v; done
  echo "work in progress" > file.txt; git add file.txt     # STAGED version
  echo "unstaged extra" >> file.txt; }                     # extra working-tree edit
```
**Before any reset** `git status -s` → `MM file.txt`. Index holds "work in progress", the working file also has "unstaged extra".

```bash
# --soft: move the branch only
demo; git reset --soft HEAD~1
git log --format=%s | tr '\n' ' '         # v2 v1   (v3 commit undone)
git status -s                             # MM file.txt (index & workdir untouched)
git diff --staged                         # -v2 +work in progress
git reset --soft ORIG_HEAD                # go back: ORIG_HEAD remembers where we were
git log --format=%s | head -1             # v3

# --mixed (default): move branch + reset index
demo; git reset HEAD~1
git status -s                             #  M file.txt  (staged work discarded from index, file content kept)
cat file.txt                              # work in progress / unstaged extra

# --hard: move branch + index + working directory   (DANGEROUS)
demo; git reset --hard HEAD~1
cat file.txt                              # v2 ← your uncommitted work is GONE
git reset --hard ORIG_HEAD                # brings back commit v3…
cat file.txt                              # v3  …but NOT the lost uncommitted edits
```
**Recovering the staged part** (its blob still exists in the object database even though nothing points to it):
```bash
demo; B=$(git ls-files -s file.txt | awk '{print $2}')     # remember the blob id (here we cheat; normally: git fsck --lost-found)
git reset --hard HEAD~1
git cat-file -p $B                        # work in progress
```
The unstaged "extra" is unrecoverable. This is why `reset --hard` is the dangerous mode, and why you should `git stash` first.

**With paths:**
```bash
demo; git reset file.txt                  # = unstage: index ← HEAD for that path
git status -s                             #  M file.txt
git reset -q --hard; git reset HEAD~2 -- file.txt     # index ← v1 version, workdir untouched
git status -s                             # MM file.txt
git diff --staged                         # -v3 +v1
git reset -q --hard; git checkout HEAD~2 -- file.txt  # index AND working directory ← v1
git status -s; cat file.txt               # M  file.txt / v1
```
**Squash with reset:**
```bash
demo; git reset -q --hard
git reset --soft HEAD~2 && git commit -m "v2+v3"
git log --format=%s | tr '\n' ' '         # v2+v3 v1
```
**`--keep` safety:**
```bash
demo; git stash -q; echo dirty >> file.txt
git reset --keep HEAD~1                   # error: Entry 'file.txt' not uptodate. Cannot merge. (nothing lost)
```

### Lab 7 · `reset` vs `checkout`: who moves?
```bash
demo; git reset -q --hard
git branch dev HEAD~1                      # dev points at v2, main at v3
git branch -v                              # compare hashes
git switch dev && git branch --show-current     # HEAD itself moved to dev; main untouched
git switch main
git reset --hard dev                       # now MAIN moves to dev's commit; HEAD still → main
git branch -v                              # main and dev same hash; you're still on main
git reset --hard ORIG_HEAD                 # undo
```
**Expected:** `switch` changes *which branch* HEAD points to; `reset` changes *where the current branch* points.

### Lab 8 · `revert` (safe undo for shared history)
```bash
demo; git reset -q --hard
git revert --no-edit HEAD                  # adds: Revert "v3"
git log --format=%s | tr '\n' '|'          # Revert "v3"|v3|v2|v1|
cat file.txt                               # v2
```
**Expected:** history is preserved; a new commit undoes the change. Compare with Lab 6's `reset --hard HEAD~1`.

### Lab 9 · Force-push safety (local simulation)
```bash
mk pub && git init -q --bare ../pub.git && git remote add origin ../pub.git && git push -q origin main
git commit --amend -m "four (amended)"
git push origin main                       # rejected (non-fast-forward)
git push --force-with-lease origin main    # allowed: remote hasn't moved since our last fetch
```
**Expected:** first push rejected; the second succeeds. If a teammate had pushed in between, `--force-with-lease` would refuse (try it from a second clone).

## 7. Practice challenges
1. You committed `config.yml` with a password three commits ago and *haven't pushed*. Remove it from all three commits with `rebase -i` (hint: `edit` + `git rm --cached`), then do it again with `filter-branch --index-filter`.
2. Reword the message of the *first* commit in a repository.
3. Take 6 commits and turn them into 3 logical ones with reorder + squash.
4. Run `git reset --hard HEAD~3` on purpose and restore all three commits two different ways.
5. Without `rebase -i`, combine the last 4 commits into one commit.
6. Use `git rebase -x` so that each commit in a 5-commit branch is verified by a test script that fails on commit 3. Observe where the rebase stops, fix and continue.
7. Explain, with the three-trees table, why `git checkout -- file` loses work but `git checkout branch` refuses to.
8. Revert a merge commit with `-m 1`, then explain what happens if you merge the same branch again.
9. Change the author email for all commits by `old@x.com` in a repo (env-filter).

<details><summary>Solutions</summary>

1. `git rebase -i HEAD~3` → mark each commit that touches it `edit`; at each stop `git rm --cached config.yml; git commit --amend --no-edit; git rebase --continue`; add `config.yml` to `.gitignore`. Or: `git filter-branch --index-filter 'git rm --cached --ignore-unmatch config.yml' HEAD~3..HEAD`. Rotate the password anyway if it left your machine.
2. `git rebase -i --root`, then `reword` the first line.
3. `git rebase -i HEAD~6`; move related lines together; `squash`/`fixup` the followers.
4. `git reset --hard ORIG_HEAD` and `git reset --hard HEAD@{1}` (or `git branch rescue <sha>` from `git reflog`).
5. `git reset --soft HEAD~4 && git commit -m "combined"`.
6. `git rebase -x ./test.sh <base>`; it stops after the failing commit with the command's output; amend/fix, `git rebase --continue`.
7. `checkout -- file` (file level) writes index + working directory with no safety check, so uncommitted edits vanish; branch-level checkout updates all three trees but aborts if local changes would be overwritten.
8. `git revert -m 1 <merge>`. Merging the branch again does nothing for the reverted changes (Git thinks they're already merged); first `git revert <the revert commit>`.
9. `git filter-branch --env-filter 'if [ "$GIT_AUTHOR_EMAIL" = old@x.com ]; then export GIT_AUTHOR_EMAIL=new@x.com; fi' -- --all`.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Amended/rebased a pushed commit, push rejected | `git push --force-with-lease` **only on your own branch**; otherwise create a new commit/revert |
| Rebase went wrong | `git rebase --abort`; after finishing: `git reset --hard ORIG_HEAD` or `git reflog` → `git reset --hard HEAD@{n}` |
| Deleted a line in the todo list and lost a commit | Same: reflog; set `rebase.missingCommitsCheck=error` |
| `git reset --hard` destroyed uncommitted edits | Staged blobs: `git fsck --lost-found` ([13-git-internals-plumbing-and-objects.md](13-git-internals-plumbing-and-objects.md)); unstaged: gone. Stash/commit before resets |
| Typed `git reset HEAD~1` and thought it deleted work | `--mixed` keeps the files; use `git status`, re-add and commit |
| Squashed commits and lost the good messages | `reflog`, redo with `fixup`/edited message |
| Secrets still present after `filter-branch` | `refs/original`, reflog and other clones still hold them: delete refs/original, `reflog expire`, `gc --prune=now`; rotate secrets; re-clone elsewhere |
| `rebase -i` stopped on `edit` and you're confused | `git status` says what to do; `git rebase --continue` after amending |
| Rebase of a branch containing merges flattened them | Use `git rebase --rebase-merges` |
| Empty commit after squashing/dropping | `git rebase --continue` after `git commit --allow-empty`, or `--skip` |
| Signed commits lose signatures when rebased | Re-sign: `git rebase --gpg-sign` or `-S` |

## 9. Real-world use cases
- **Before opening a PR:** squash "wip", "fix typo", "oops" commits into a story reviewers can follow.
- **Security incident:** remove a leaked credential from history (after rotating it) with `filter-repo`/`filter-branch`.
- **Repo restructuring:** `--subdirectory-filter` to split a monorepo folder into its own repo.
- **Bisect-friendly history:** `rebase -x` so every commit builds and tests (see `git bisect` in [09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md)).
- **Undo on `main`:** `git revert`, never `reset`, on shared branches.

## 10. Self-check quiz
1. Why do all commits after an amended one change hash?
2. In `rebase -i`, which commit appears first: oldest or newest?
3. What's the difference between `squash` and `fixup`?
4. What are the three steps of `git reset`, and which flag stops at which?
5. What does `git reset file.txt` do?
6. Why is `reset --hard` dangerous but `checkout <branch>` is not?
7. What's the difference between `git checkout dev` and `git reset dev`?
8. When should you use `revert` instead of `reset`?
9. What does `--force-with-lease` do differently from `--force`?
10. After `filter-branch`, how do you actually free the old data?

<details><summary>Answers</summary>

1. Each commit hash includes its parent's hash, so a changed parent changes every descendant.
2. Oldest first (reverse of `git log`).
3. `squash` keeps and lets you edit the folded commit's message; `fixup` discards it.
4. Move the branch (`--soft` stops); update the index (`--mixed`, default, stops); update the working directory (`--hard`).
5. Copies the HEAD version of the file into the index (unstages it); working copy untouched.
6. `reset --hard` overwrites tracked working files with no safety; `checkout <branch>` refuses if it would lose uncommitted changes.
7. `checkout dev` moves HEAD to branch `dev`; `reset dev` moves the *current* branch to where `dev` points.
8. On shared/pushed history (including merge commits), because it adds a new inverse commit.
9. It fails if the remote branch has commits you haven't fetched, protecting others' work.
10. Remove `refs/original`, expire the reflog, run `git gc --prune=now`.
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Tidy a messy 6-commit branch into logical commits with `rebase -i`.
- [ ] Split, reorder, squash, drop, fixup/autosquash and run commands between commits.
- [ ] Explain HEAD / index / working directory and what each reset mode touches.
- [ ] Choose `reset`, `revert`, `restore` or `amend` for a given mistake.
- [ ] Remove a file from all history and know what remains to clean (and why secrets must be rotated).
- [ ] Recover from any rewrite with `ORIG_HEAD` or the reflog.

**Next:** [09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md): merge strategies, conflict tooling, rerere, blame and bisect.
