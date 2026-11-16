# 03 · Git Branching and Merging
> Book reference: Pro Git, Chapter 3, "Branches in a Nutshell", "Basic Branching and Merging", "Branch Management", "Branching Workflows", "Remote Branches", "Rebasing" (book pp. 63–104)
> Level: Beginner–Intermediate · Est. time: 5 h

## 1. Why this matters
Branching is Git's "killer feature". Because a branch is just a 41-byte pointer, you can create one per task, experiment freely, and merge when ready. Almost every team workflow (feature branches, pull requests, hotfixes, releases) is built on what you learn here.

## 2. Prerequisites
- [02-git-basics.md](02-git-basics.md): add/commit/log/remotes.

## 3. Learning objectives
- [ ] Explain commits, trees, blobs, branches and `HEAD` as a data model.
- [ ] Create, switch, rename, delete branches.
- [ ] Perform fast-forward and three-way merges; resolve conflicts.
- [ ] Use `git branch -v/--merged/--no-merged`.
- [ ] Describe long-running, topic-branch and "graduation" workflows.
- [ ] Work with remote-tracking branches: fetch, push, track, delete.
- [ ] Rebase, including `--onto`, and know the golden rule of rebasing.
- [ ] Choose between merge and rebase.

## 4. Core concepts

### 4.1 The data model in a nutshell
A commit stores a pointer to a **snapshot** (a *tree* of *blobs*), author/message metadata, and pointer(s) to its **parent** commit(s) (0 for the first, 1 normal, 2+ for merges).

```
 98ca9 ◀── 34ac2 ◀── f30ab           ← commits (each points back to its parent)
                       ▲
                     master (branch = movable pointer to a commit)
                       ▲
                      HEAD (points to the current branch)
```
- A **branch** is a movable pointer to a commit. The default is `main` (💡 older repos: `master`; nothing special about either name).
- **HEAD** is a pointer to the *current branch* (a symbolic ref, file `.git/HEAD`). Committing moves the current branch forward. 
- `git branch name` creates a pointer (doesn't switch). `git switch name` moves HEAD and updates your working files. `git switch -c name` does both. (💡 Classic: `git checkout name`, `git checkout -b name`.)
- Creating a branch is instant and costs ~41 bytes; that's why Git encourages many branches.
- Switching branches changes your working directory; Git refuses if uncommitted changes would be overwritten (commit, stash, or discard first).
- `git log --oneline --decorate --graph --all` shows where all branch pointers and HEAD are.

### 4.2 Basic branching and merging: a typical story
1. Work on `main`. 2. `git switch -c iss53` and commit. 3. Urgent bug: `git switch main`, `git switch -c hotfix`, fix, commit. 4. Merge `hotfix` into `main`, delete it. 5. Return to `iss53`, finish, merge into `main`.

**Fast-forward merge:** if the branch you merge is *directly ahead* of the current one, Git just moves the pointer ("Fast-forward"); no new commit.

**Three-way merge:** if histories have diverged, Git uses the two branch tips plus their **common ancestor** to create a new **merge commit** with two parents.
```
main:   C0─C1─C2─────────M      (M = merge commit, parents C2 and C4)
              \         /
iss53:         C3──C4──┘
```
Merge direction: you stand on the branch that should **receive** the changes: `git switch main && git merge iss53`.

**Conflicts** happen when both sides changed the same lines (or one deleted what the other edited). Git pauses:
```
<<<<<<< HEAD (your current branch)
version A
=======
version B
>>>>>>> iss53
```
Resolve: edit the file to the final content and delete markers, `git add <file>` (marks resolved), then `git commit`. Helpful: `git status`, `git diff`, `git mergetool`, `git merge --abort` (back out completely). Advanced techniques are in [09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md).

### 4.3 Branch management
| Command | Purpose |
|---------|---------|
| `git branch` | list local branches (`*` marks current) |
| `git branch -v` | + last commit on each |
| `git branch -vv` | + upstream tracking and ahead/behind |
| `git branch --merged [b]` | branches already merged into current (safe to delete; those without `*`) |
| `git branch --no-merged [b]` | branches containing unmerged work |
| `git branch -d name` | delete (refuses if unmerged) |
| `git branch -D name` | force delete (work becomes unreachable except via reflog) |
| `git branch -m old new` | rename (then push new and delete old on remote) |
| `git branch -a` / `-r` | include remote-tracking / only those |

### 4.4 Branching workflows
- **Long-running branches:** stable code on `main`, `develop`/`next` for testing; merge "up" as code stabilizes (graduation / silo model). Mix per project size.
- **Topic (feature) branches:** short-lived, one per feature/bugfix; easy to review, discard or reorder. You can make many and merge them in any order. Branch names are only local until pushed.
- All of it is local; share when ready.

### 4.5 Remote branches
- **Remote references** are pointers in the remote repo (branches, tags).
- **Remote-tracking branches** (`origin/main`) are local, read-only bookmarks of where the remote's branches were at your last network contact. Git moves them for you on `fetch/pull/push`; you cannot commit to them directly.
```
 remote (origin):   A──B──C        main
 you, after clone:  A──B──C        main, origin/main
 you commit:        A──B──C──D     main        origin/main (still C)
 someone else:      origin has E; you `git fetch` → origin/main = E (diverged)
```
- `git clone` creates `origin/*` and a local `main` that **tracks** `origin/main`.
- `git fetch origin` updates `origin/*` only. `git merge origin/main` (or `git pull`) integrates.
- `git push origin feature` is shorthand for `git push origin refs/heads/feature:refs/heads/feature`. Different remote name: `git push origin local:remote`.
- **Tracking branch** = local branch with an upstream. Create via `git switch feature` (auto-creates tracking if `origin/feature` exists and the name is unambiguous), `git switch -c b origin/b`, `git switch --track origin/b`, or set later: `git branch -u origin/b`.
- With tracking set up, plain `git pull` / `git push` know where to go; `git status -sb` and `git branch -vv` show ahead/behind. Numbers are as of your last fetch; run `git fetch --all` first.
- Delete a remote branch: `git push origin --delete feature`. Clean stale local copies: `git fetch --prune` (or `git remote prune origin`).
- 💡 `git pull` = fetch + merge. Many people prefer explicit `fetch` then `merge`/`rebase` because `pull`'s magic confuses. Config: `pull.rebase`, `pull.ff only`.

### 4.6 Rebasing
Two ways to integrate diverged work:
- **Merge:** keeps true history, adds a merge commit.
- **Rebase:** *replays* your commits on top of the target tip, producing new commits with the same changes but different parents (new hashes); history looks linear.
```
Before:      C0─C1─C2─C3 (main)             After rebase onto main, then FF merge:
                   \                         C0─C1─C2─C3 (main)
                    C4─C5 (topic)                        \
                                                          C4'─C5' (topic)
```
```bash
git switch topic
git rebase main            # replay topic's commits on main
git switch main
git merge topic            # now a fast-forward
```
- Result is identical in content to a merge; history is cleaner (good for contributing a patch to a project you don't maintain: rebase on `origin/main` before submitting).
- **Conflicts during rebase** are resolved per commit: fix, `git add`, `git rebase --continue`; or `--skip` / `--abort`.
- **`--onto`:** `git rebase --onto main server client` = "take commits on `client` that are not on `server`, and replay them onto `main`" (transplant a branch off another topic branch).
- `git rebase <base> <topic>` checks out `topic` and rebases it in one step.
- **The golden rule:** *Do not rebase commits that exist outside your repository and that others may have based work on.* Rebasing rewrites commits; the people who already have the old ones must reconcile duplicates (messy). If you rebased already-pushed work, you'll need `git push --force-with-lease` (safer than `--force`), and only on branches you own.
- Rebase vs merge, rule of thumb: rebase **your local/private** work to tidy before sharing; merge **shared** history. Some teams prefer "history as record" (merge) others "history as story" (rebase/squash). Pick and be consistent.
- 💡 `git pull --rebase` fetches then rebases your local commits on top of the upstream.
- Recover from a bad rebase with `git reflog` (the old tip is still there): `git reset --hard ORIG_HEAD` right after, or `git reset --hard HEAD@{n}`.

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git branch <n>` | Create branch at HEAD | Mark a spot |
| `git switch <n>` / `-c <n>` | Switch / create+switch | Change task |
| `git switch -` | Return to previous branch | Quick toggle |
| `git merge <n>` | Merge `<n>` into current | Integrate |
| `git merge --abort` | Cancel a conflicted merge | Back out |
| `git branch -d/-D <n>` | Delete branch | Cleanup |
| `git branch -m <old> <new>` | Rename | Fix names |
| `git branch -vv` | Show tracking status | Check sync |
| `git branch --merged/--no-merged` | Which are done | Cleanup |
| `git fetch [-p]` | Update remote-tracking refs | Before comparing/merging |
| `git push -u origin <b>` | Publish + track | First push of a branch |
| `git push origin --delete <b>` | Delete remote branch | After merge |
| `git rebase <base>` | Replay commits | Tidy private history |
| `git rebase --onto A B C` | Transplant C (since B) onto A | Move topic off another topic |
| `git rebase --continue/--skip/--abort` | Control a rebase | Conflicts |
| `git log --oneline --graph --decorate --all` | Visualize | Always |

## 6. Hands-on labs
Setup:
```bash
mkdir -p ~/git-labs/03 && cd ~/git-labs/03
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"     # sandbox config; skip if your identity is set globally
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
```

### Lab 1 · A branch is a pointer
```bash
git init p1 && cd p1
for i in 1 2 3; do echo "$i" > f$i.txt; git add .; git commit -m "c$i"; done
git branch testing
git log --oneline --decorate --graph --all
cat .git/HEAD                         # ref: refs/heads/main
cat .git/refs/heads/testing           # the commit hash testing points to
git rev-parse main testing            # identical hashes
```
**Expected:** `(HEAD -> main, testing)` on the same commit. You just created a branch without copying anything.

### Lab 2 · Switching changes files and diverges history
```bash
git switch testing
echo "t" >> f1.txt && git commit -am "t1"
git switch main
cat f1.txt                            # no "t": working tree reflects main
git log --oneline --decorate --graph --all
git switch -                          # back to testing (previous branch)
git switch main
```
**Expected:** graph shows `testing` one commit ahead of `main`. 

### Lab 3 · Fast-forward and three-way merge (the book's hotfix story)
```bash
git switch -c iss53
echo "iss53 work" >> f2.txt && git commit -am "iss53 work"
git switch main
git switch -c hotfix
echo "fixed" > hotfix.txt && git add . && git commit -m "hotfix"
git switch main
git merge hotfix                      # "Fast-forward"
git branch -d hotfix
git switch iss53
echo "more" >> f2.txt && git commit -am "iss53 more"
git switch main
git merge iss53 -m "Merge iss53"      # "Merge made by the 'ort' strategy"
git log --oneline --graph
```
**Expected:** first merge says `Fast-forward`; second creates a merge commit with two parents; graph shows a diamond. 💡 Strategy name is `ort` in Git ≥ 2.34 (`recursive` in the book).

### Lab 4 · Resolve a merge conflict
```bash
printf 'title\nbody\n' > page.txt && git add . && git commit -m "add page"
git switch -c feature
sed -i 's/body/body from FEATURE/' page.txt && git commit -am "feature edit"   # macOS: sed -i '' ...
git switch main
sed -i 's/body/body from MAIN/' page.txt && git commit -am "main edit"
git merge feature
git status -s                         # UU page.txt
cat page.txt                          # conflict markers
git diff --name-only --diff-filter=U  # list unmerged files
```
Edit `page.txt` to the final text (e.g. `body from MAIN and FEATURE`), then:
```bash
git add page.txt
git commit                            # accepts the prepared merge message
git log --oneline --graph -4
```
**Expected:** `CONFLICT (content): Merge conflict in page.txt`, `UU` in status, markers `<<<<<<< HEAD`, `=======`, `>>>>>>> feature`.
**Variation (abort):** redo with another branch, run `git merge --abort`, confirm `git status` is clean.
**Variation (pick one side):** `git checkout --ours page.txt` or `--theirs` (💡 `git restore --ours/--theirs page.txt`), then `git add`.

### Lab 5 · Branch management
```bash
git branch -v
git branch --merged                   # iss53, feature are listed (fully merged)
git switch -c scratch && echo s > s.txt && git add . && git commit -m "scratch"
git switch main
git branch --no-merged                # scratch
git branch -d scratch                 # error: not fully merged
git branch -D scratch                 # force
git branch -m iss53 issue-53          # rename
git branch -d feature issue-53
```
**Expected:** `-d` on unmerged branch is refused with a hint to use `-D`.
Recovery drill: `git reflog` finds scratch's last hash; `git branch scratch <hash>` resurrects it.

### Lab 6 · Remote branches (local bare repo as server)
```bash
cd ..
git init --bare server.git
cd p1 && git remote add origin ../server.git
git push -u origin main
git push origin issue-53 2>/dev/null || git push origin main:main    # (branch may be gone; skip if so)
cd .. && git clone server.git p2 && cd p2
git branch -a                         # remotes/origin/HEAD -> origin/main, remotes/origin/main
git config user.name Sam && git config user.email sam@example.com
git switch -c feat
echo "f" > feat.txt && git add . && git commit -m "feat"
git push -u origin feat
git branch -vv
cd ../p1
git fetch
git branch -r                         # origin/feat appears; no local 'feat' yet
git switch feat                       # auto-creates tracking branch from origin/feat
git branch -vv
```
**Expected:** after `fetch`, `origin/feat` exists but nothing in your files changed. `git switch feat` prints that the branch is set up to track `origin/feat`.
Now diverge:
```bash
echo "p1 change" >> feat.txt && git commit -am "p1 edit"
cd ../p2 && echo "p2 change" >> feat.txt && git commit -am "p2 edit" && git push
cd ../p1 && git push                  # rejected: fetch first
git fetch && git status -sb           # [ahead 1, behind 1]
git pull --no-rebase                  # conflict in feat.txt: resolve, git add, git commit, then push
```
Cleanup: `git push origin --delete feat`, then in the other clone `git fetch --prune` and watch `origin/feat` vanish.

### Lab 7 · Rebase
```bash
cd ~/git-labs/03 && git init p3 && cd p3
echo base > base.txt && git add . && git commit -m "base"
git switch -c topic
echo r1 > r1.txt && git add . && git commit -m "r1"
echo r2 > r2.txt && git add . && git commit -m "r2"
git switch main
echo m > m.txt && git add . && git commit -m "m on main"
git log --oneline --graph --all       # diverged
git switch topic
git rebase main
git log --oneline --graph --all       # linear; r1', r2' have NEW hashes
git switch main && git merge topic    # fast-forward
git branch -d topic
```
**Expected:** `Successfully rebased and updated refs/heads/topic.` Commit hashes of r1/r2 changed. Use `git reflog` to find the pre-rebase hashes.

### Lab 8 · Rebase with conflict, and `--onto`
```bash
git switch -c edit1 && echo "x" > clash.txt && git add . && git commit -m "edit1"
git switch main && echo "y" > clash.txt && git add . && git commit -m "main clash"
git switch edit1
git rebase main                       # CONFLICT (add/add): both sides created clash.txt
cat clash.txt
echo "x and y" > clash.txt
git add clash.txt
git rebase --continue                 # (editor may open: save)
git log --oneline --graph --all | head
```
**`--onto` drill:** build `main → server → client`
```bash
git switch main
git switch -c server  && echo s > srv.txt && git add . && git commit -m "server"
git switch -c client  && echo c > cli.txt && git add . && git commit -m "client"
git rebase --onto main server client  # replay client's commit onto main, skipping server's
git log --oneline --graph --all
```
**Expected:** `client` now descends from `main` directly and does **not** contain `srv.txt`.

### Lab 9 · The golden rule (see the damage in a sandbox)
```bash
cd ~/git-labs/03 && rm -rf pub.git a b && git init --bare pub.git && git clone pub.git a && cd a
git config user.name A && git config user.email a@e.com
echo 1 > f && git add . && git commit -m one && git push origin main
echo 2 >> f && git commit -am two && git push
cd .. && git clone pub.git b && cd b            # B now has "two"
cd ../a && git reset --hard HEAD~1 && echo 2b >> f && git commit -am two-prime
git push --force-with-lease                      # A rewrote published history
cd ../b && git pull                              # Git ≥ 2.27 refuses: "Need to specify how to reconcile divergent branches"
git fetch && git log --oneline --graph --all     # B's "two" and A's rewritten "two-prime" are siblings
git pull --no-rebase                             # forced merge: old and new "two" both end up in history (conflict in f)
```
**Expected:** after `fetch`, the graph shows two diverged commits on top of `one`. Merging them creates a conflict on `f` and a history containing both versions of "two". This is why you never rewrite shared history. Remedy: coordinate with the team; B runs `git fetch && git reset --hard origin/main` (losing any unpushed work unless backed up), or `git pull --rebase`, which skips commits already upstream when it can recognise them.

## 7. Practice challenges
1. Create `main` with 3 commits. Create `a` and `b` from the same commit, each editing a *different* file. Merge both into `main` and show the graph. How many merge commits? Are any fast-forward?
2. Create a conflict where branch A deletes a file and branch B edits it. Resolve by keeping the edit.
3. You started work on `main` by mistake (2 uncommitted-to-branch commits, unpushed). Move them to a new branch `feature` and put `main` back where it was.
4. Using only one command, list all branches that are already merged into `main` and delete them (excluding `main`).
5. From `main` → `topic1` → `topic2` (each with commits), transplant only `topic2`'s commits onto `main`.
6. Push a branch, delete it on the remote, then remove its stale remote-tracking branch locally in a second clone.
7. Make two commits locally, one has a typo in the message. Before pushing, rebase to fix it (interactive rebase preview: see 08 file) or simply amend the tip.

<details><summary>Solutions</summary>

1. First merge (`a`) is a fast-forward; second (`b`) is a three-way, so 1 merge commit. (If `main` hasn't moved since, the first merge fast-forwards.)
2. `git merge a` → `CONFLICT (modify/delete)`. Keep file: `git add file` then commit.
3. `git branch feature` (at current tip), `git reset --hard HEAD~2` on `main`. (If you must not lose anything, check `git log` first.) Alternative: `git switch -c feature` then `git branch -f main HEAD~2`.
4. `git branch --merged main | grep -v '\*\|main' | xargs -n 1 git branch -d`
5. `git rebase --onto main topic1 topic2`
6. `git push origin --delete b`; in the other clone `git fetch --prune`.
7. `git commit --amend` for the last commit; for older ones use `git rebase -i HEAD~2` with `reword` (see [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md)).
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Merged the wrong way (e.g. `main` into feature) | Not wrong per se; to undo an unpushed merge: `git reset --hard ORIG_HEAD` |
| Switch blocked: "local changes would be overwritten" | Commit, `git stash`, or discard |
| Committed on the wrong branch | Create the right branch at HEAD, move the wrong one back with `git branch -f` / `reset` |
| Deleted a branch with unmerged work (`-D`) | `git reflog` → `git branch name <hash>` |
| Resolved conflict but forgot `git add` | `git status` shows "Unmerged paths"; add, then commit/continue |
| Left conflict markers in a file | Search for `<<<<<<<`; consider a pre-commit hook ([11-customizing-git-config-attributes-and-hooks.md](11-customizing-git-config-attributes-and-hooks.md)) |
| Rebased a pushed branch | Coordinate with team; `--force-with-lease` only on your own branches; recover old state via `git reflog` |
| `git push` rejected (non-fast-forward) | `git fetch`, integrate (`merge` or `rebase`), push again; never default to `--force` |
| Stale `origin/*` branches | `git fetch --prune` (or `git config --global fetch.prune true`) |
| Aborted rebase state stuck | `git rebase --abort`; check `.git/rebase-merge` |

## 9. Real-world use cases
- **Feature branches + pull requests:** one branch per ticket, reviewed and merged ([06-github-collaboration.md](06-github-collaboration.md)).
- **Hotfix flow:** branch from the release tag/`main`, fix, merge to `main` and the maintenance branch.
- **Keeping a branch current:** rebase on `main` (private) or merge `main` into it (shared).
- **Release/maintenance branches:** `release/1.x` with cherry-picks from `main`.
- **Experiments:** throwaway branches, deleted with `-D` when they fail, with no impact on anything else.

## 10. Self-check quiz
1. What does a Git branch physically contain?
2. What is `HEAD`?
3. When does a merge fast-forward, and when does it create a merge commit?
4. In a conflict, what do `HEAD` and the other side represent in the markers?
5. What's the difference between `origin/main` and `main`?
6. What does `git fetch` change, and what does it not change?
7. State the golden rule of rebasing.
8. What does `git rebase --onto main server client` do?

<details><summary>Answers</summary>

1. A 40-hex SHA-1 pointing at a commit (file in `.git/refs/heads/`).
2. A pointer to the current branch (or directly to a commit when detached).
3. Fast-forward when the target is a direct descendant (no divergence); otherwise a three-way merge commit using the common ancestor.
4. Above `=======`: your current branch (`HEAD`); below: the branch being merged.
5. `origin/main` is a read-only local bookmark of the remote's `main` as of your last fetch; `main` is your own movable branch.
6. Updates remote-tracking branches and downloads objects; does not touch your working tree or local branches.
7. Don't rebase commits that exist outside your repo and others may base work on.
8. Takes the commits in `client` that aren't in `server` and replays them onto `main`.
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Draw the commit graph for any sequence of branch/merge/rebase commands.
- [ ] Resolve a conflict and know three ways to back out.
- [ ] Publish, track, update and delete remote branches; explain `fetch` vs `pull`.
- [ ] Decide between merge and rebase and state the risk of rebasing shared history.
- [ ] Recover a deleted branch or botched rebase with `git reflog`.

**Next:** [04-git-on-the-server.md](04-git-on-the-server.md) — protocols, bare repos, SSH, daemons, GitWeb/GitLab and hosted options.
