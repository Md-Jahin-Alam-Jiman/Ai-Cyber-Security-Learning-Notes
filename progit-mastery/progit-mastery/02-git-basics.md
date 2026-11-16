# 02 · Git Basics
> Book reference: Pro Git, Chapter 2, "Getting a Git Repository", "Recording Changes to the Repository", "Viewing the Commit History", "Undoing Things", "Working with Remotes", "Tagging", "Git Aliases" (book pp. 26–62)
> Level: Beginner · Est. time: 5 h

## 1. Why this matters
This chapter is the 90% of Git you will type every day: create a repo, stage, commit, inspect history, undo mistakes, sync with a remote, mark releases. Everything in later chapters (branching, rebasing, GitHub workflows) is built on this loop.

## 2. Prerequisites
- [01-getting-started.md](01-getting-started.md): the three states/areas, and identity configured.

## 3. Learning objectives
- [ ] Create a repository with `git init` and `git clone`.
- [ ] Read `git status` (long and `-s` form) and know tracked vs untracked, staged vs unstaged.
- [ ] Use `.gitignore` patterns correctly.
- [ ] Compare changes with `git diff` and `git diff --staged`.
- [ ] Commit, skip staging (`-a`), remove and move files.
- [ ] Filter and format history with `git log`.
- [ ] Undo: amend a commit, unstage, discard changes.
- [ ] Add, fetch, pull, push, inspect, rename and remove remotes.
- [ ] Create, list, share and delete lightweight and annotated tags.
- [ ] Create aliases.

## 4. Core concepts

### 4.1 Getting a repository
Two ways:
```bash
git init                       # turn the current folder into a repo (creates .git/)
git clone <url> [dir]          # copy an existing repo with ALL history
```
`clone` downloads every version of every file; if the server disk died, any clone could restore it. URL schemes: `https://`, `git://`, `user@host:path` (SSH), or a local path.
`git init` alone tracks nothing; you must `add` then `commit`.

### 4.2 The file lifecycle
```
Untracked ──add──▶ Staged ──commit──▶ Unmodified (tracked)
                      ▲                     │ edit
                      └──────add────── Modified
Unmodified ──remove──▶ Untracked/deleted
```
- **Tracked** = was in the last snapshot or is staged. **Untracked** = everything else.
- `git status` is your dashboard. Run it constantly.

### 4.3 `git status` and short status
Long form tells you the branch, "Changes to be committed" (staged), "Changes not staged for commit", "Untracked files", and gives hints for the next command.
`git status -s` gives two columns:

| Output | Meaning |
|--------|---------|
| `??` | untracked |
| `A ` | new file, staged |
| `M ` | modified, staged |
| ` M` | modified, **not** staged |
| `MM` | staged, then modified again |
| `D ` / ` D` | deleted (staged / not) |
| `R ` | renamed (staged) |

Left column = index vs HEAD. Right column = working tree vs index.

### 4.4 `git add` is multipurpose
It means "start tracking this file", "stage this change", and "mark merge conflict resolved". Crucially, `git add` stages the file **as it is right now**. Edit it again afterwards and you must `add` again, otherwise the commit contains the older version.

### 4.5 Ignoring files: `.gitignore`
Lists patterns of files Git should never show as untracked (logs, build output, secrets, editor files). Rules:
- Blank lines and `#` comments ignored.
- `*.log` glob; `?` one char; `[abc]` set; `**` matches nested dirs (`a/**/z`).
- Trailing `/` matches a directory (`build/`).
- Leading `/` anchors to the repo root (`/TODO` ignores only the root TODO).
- `!pattern` negates (`!keep.log`).
- Already-tracked files are **not** affected; untrack them with `git rm --cached`.
- Nested `.gitignore` files apply to their subtree. Check with `git check-ignore -v <path>`.
- 💡 Starter templates: github.com/github/gitignore. Global ignore: `git config --global core.excludesFile ~/.gitignore_global`.

### 4.6 Seeing changes: `git diff`
| Command | Compares |
|---------|----------|
| `git diff` | working tree vs **index** (what you changed but haven't staged) |
| `git diff --staged` (`--cached`) | index vs **last commit** (what you'd commit now) |
| `git diff HEAD` | working tree vs last commit (both combined) |
| `git difftool` | same, in an external tool |
Add `--stat` for a summary, `--check` for whitespace errors.

### 4.7 Committing
`git commit` opens your editor; `git commit -m "msg"` is inline; `git commit -v` shows the diff in the editor. **Only staged changes** go in.
`git commit -a` auto-stages every *tracked* modified file (never untracked ones). Convenient but easy to commit more than you intended.

Good message convention: a ≤50-char imperative summary line, blank line, then a body explaining *why*.

### 4.8 Removing and moving files
- `git rm file` removes from working tree **and** stages the deletion. 
- `git rm --cached file` stops tracking but keeps the file on disk (typical `.gitignore` fix).
- `git rm -f file` required if the file is modified/staged (safety against data loss).
- `git mv a b` = `mv a b` + `git rm a` + `git add b`. Git doesn't store renames explicitly; it detects them by content similarity.

### 4.9 Viewing history: `git log`
Default: newest first, with hash, author, date, message.

| Option | Effect |
|--------|--------|
| `-p` | show the patch each commit introduced |
| `-2` | last 2 commits |
| `--stat` | files changed summary |
| `--oneline` | one line per commit (`--pretty=oneline --abbrev-commit`) |
| `--graph` | ASCII branch graph |
| `--pretty=format:"%h %an %ar %s"` | custom format (`%H` hash, `%h` short, `%an` author, `%ae` email, `%ad` date, `%ar` relative date, `%s` subject) |
| `--since/--after`, `--until/--before` | date filters (`2.weeks`, `2008-01-15`) |
| `--author`, `--committer` | person filters |
| `--grep` | message search |
| `-S<string>` | **pickaxe**: commits that changed the number of occurrences of the string |
| `-- path` | only commits touching the path (always last, after `--`) |
| `--no-merges` | hide merge commits |
Author = who wrote the change; committer = who applied it (differ for patches/rebases).

### 4.10 Undoing things
Some undos are permanent. **Rule: anything committed is nearly always recoverable; anything uncommitted and discarded is not.**

**a) Redo the last commit** (forgot a file / typo in message):
```bash
git commit -m "msg"
git add forgotten.txt
git commit --amend            # replaces the last commit (editor opens; --no-edit keeps message)
```
Amend *replaces* the commit with a new one (new hash). Do not amend commits you have already pushed and others have pulled.

**b) Unstage a file**
```bash
git restore --staged <file>          # 💡 modern, Git ≥ 2.23
git reset HEAD <file>                # book's classic form
```
**c) Discard working-tree changes** (DANGEROUS, no undo):
```bash
git restore <file>                   # 💡 modern
git checkout -- <file>               # classic
```
If you want to keep the work but get it out of the way, use stash or a branch ([07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md), [03-git-branching-and-merging.md](03-git-branching-and-merging.md)).

### 4.11 Working with remotes
A **remote** is a named URL to another copy of the repo. `git clone` names the source `origin`.

| Command | Purpose |
|---------|---------|
| `git remote` / `-v` | list names / with URLs |
| `git remote add <name> <url>` | add one |
| `git fetch <remote>` | download new objects into `<remote>/<branch>` **without** merging |
| `git pull` | fetch + merge the tracked branch into your current branch |
| `git push <remote> <branch>` | upload your commits (rejected if remote has commits you lack: fetch/merge first) |
| `git push -u origin main` | also set upstream tracking |
| `git remote show <name>` | detailed info (tracked branches, push/pull defaults, stale refs) |
| `git remote rename old new` | renames (also renames tracking branches) |
| `git remote remove <name>` | forget it |
Clone sets up `main` to track `origin/main`. 💡 `git config --global pull.rebase false|true` picks pull's strategy; recent Git warns if it's unset.

### 4.12 Tagging
Tags permanently name a point in history (releases like `v1.0`).
- **Lightweight**: just a pointer to a commit (`git tag v1.0`).
- **Annotated**: a full object with tagger, date, message, optionally signed (`git tag -a v1.0 -m "msg"`). Use these for releases.

| Command | Purpose |
|---------|---------|
| `git tag` / `git tag -l "v1.8.5*"` | list / filter |
| `git show v1.0` | tag data + commit |
| `git tag -a v0.9 <commit>` | tag an older commit |
| `git push origin v1.0` / `git push origin --tags` | tags are **not** pushed by default |
| `git tag -d v1.0` | delete locally |
| `git push origin --delete v1.0` | delete on remote |
| `git switch --detach v1.0` / `git checkout v1.0` | look at that version (detached HEAD) |
| `git switch -c fix v1.0` | start a branch from a tag, to keep new commits |
In detached HEAD, new commits belong to no branch and can be lost; create a branch if you want to keep them.

### 4.13 Aliases
```bash
git config --global alias.co checkout
git config --global alias.st "status -sb"
git config --global alias.last "log -1 HEAD"
git config --global alias.unstage "restore --staged --"
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.visual '!gitk'        # leading ! runs an external command
```
Autocomplete in Bash/Zsh makes typing shorter too (see [14-appendix-a-git-in-other-environments.md](14-appendix-a-git-in-other-environments.md)).

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git init` | Create repo here | Start a new project |
| `git clone <url>` | Copy a repo + history | Join an existing project |
| `git status [-s]` | Show state | Constantly |
| `git add <path>` / `.` / `-p` | Stage | Before every commit |
| `git diff [--staged]` | See changes | Before staging / committing |
| `git commit [-a] [-m]` | Record snapshot | After staging |
| `git rm [--cached]` / `git mv` | Remove / rename tracked files | File housekeeping |
| `git log [options]` | History | Investigating |
| `git commit --amend` | Rewrite last commit | Typos, forgotten file |
| `git restore [--staged]` | Discard / unstage | Fix mistakes |
| `git remote ...` | Manage remotes | Connect repos |
| `git fetch` / `pull` / `push` | Sync | Share work |
| `git tag [-a]` | Name a commit | Releases |
| `git config alias.x` | Shortcut | Speed |

## 6. Hands-on labs
Setup for all labs (sandboxed config so your real one is untouched; skip the `export` line if you've set your identity globally):
```bash
mkdir -p ~/git-labs/02 && cd ~/git-labs/02
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
```

### Lab 1 · init, first commit
```bash
git init proj && cd proj
echo "# Proj" > README.md
git status                  # README.md under "Untracked files"
git add README.md
git status -s               # A  README.md
git commit -m "Initial commit"
git log --oneline
```
**Expected:** a single-line log with a 7-char hash. 

### Lab 2 · `.gitignore`
```bash
printf '*.log\nbuild/\n!keep.log\n/TODO\n' > .gitignore
touch debug.log keep.log TODO; mkdir build; touch build/x.o
git status -s
git check-ignore -v debug.log build/x.o
git add .gitignore keep.log && git commit -m "Add ignore rules and keep.log"
```
**Expected:** `status -s` shows only `?? .gitignore` and `?? keep.log` (debug.log, build/ and TODO are hidden). `check-ignore -v` prints the matching rule and line number.
Gotcha: `!keep.log` works because `keep.log` was re-included *after* the `*.log` rule. If a parent *directory* is ignored, Git never looks inside, so you can't un-ignore files within it.

### Lab 3 · staged vs unstaged diff
```bash
echo "line2" >> README.md
echo "new" > b.txt
git add b.txt README.md        # stage both
echo "line3" >> README.md      # modify README again after staging
git status -s                  # MM README.md (staged + modified again), A  b.txt
git diff                       # only line3 (unstaged part)
git diff --staged              # b.txt (new) and line2 (staged part)
```
**Expected:** `MM README.md`, `A  b.txt`. This demonstrates "`add` stages the file as of that moment".
Now stage the rest and commit: `git add README.md && git commit -m "Add b.txt and README lines"`

### Lab 4 · Skip staging, remove, move
```bash
echo "tweak" >> README.md
git commit -a -m "Tweak README"      # -a only stages tracked files
git rm b.txt                          # deleted + staged
git mv README.md Readme.md            # rename, staged
git status -s                         # D  b.txt / R  README.md -> Readme.md
git commit -m "Drop b.txt, rename README"
git log --stat -1
echo "scratch" > notes.tmp && git add notes.tmp && git rm --cached notes.tmp   # untrack, keep on disk
ls notes.tmp; git status -s           # file still exists, now untracked
```
**Expected:** `git log --stat` shows `README.md => Readme.md` and `b.txt | 1 -`.

### Lab 5 · Explore history
```bash
git log                                 # full
git log --oneline --graph --stat
git log -p -1                           # patch of latest commit
git log --pretty=format:"%h %an %ar : %s"
git log --since=2.weeks --author=Jane --oneline
git log -S"tweak" --oneline             # which commit added the word "tweak"?
git log --oneline -- Readme.md          # history of one path (follows only current name)
git log --oneline --follow -- Readme.md # follows the rename
```
**Expected:** `-S"tweak"` returns only the "Tweak README" commit. `--follow` shows history from before the rename.

### Lab 6 · Undo ladder
```bash
# 6a: amend with a forgotten file
echo a > a.txt; git add a.txt; git commit -m "Add a.txt"
echo b > b2.txt; git add b2.txt
git commit --amend -m "Add a.txt and b2.txt"
git log --oneline -2                      # one commit, not two
# 6b: unstage
echo c > c.txt; git add c.txt
git restore --staged c.txt; git status -s # ?? c.txt
# 6c: discard working change (DANGEROUS)
echo oops >> a.txt
git restore a.txt; cat a.txt              # back to "a"
```
**Expected:** after 6a the hash of the top commit changed and no extra commit exists. 6c output: `a`.

### Lab 7 · Remotes (local bare repo as the "server")
```bash
cd ..
git init --bare server.git                # a bare repo has no working tree, like a hosted remote
cd proj
git remote add origin ../server.git
git remote -v
git push -u origin main                   # upload + set upstream
cd .. && git clone server.git teammate && cd teammate
git config user.name "Sam" && git config user.email sam@example.com
echo "from sam" > sam.txt && git add sam.txt && git commit -m "Sam adds file" && git push
cd ../proj
git fetch                                  # downloads but does NOT touch your files
git log --oneline origin/main -1           # Sam's commit is visible on origin/main
git status -sb                             # "behind 1"
git pull                                   # fetch + merge (fast-forward)
git remote show origin
git remote rename origin up && git remote
git remote rename up origin
```
**Expected:** after `fetch`, `main` is "behind 1"; after `pull`, `sam.txt` exists. If `push` says "rejected (fetch first)", someone pushed before you: pull, then push.

### Lab 8 · Tags
```bash
git tag v0.1                               # lightweight
git tag -a v1.0 -m "Release 1.0"           # annotated
git tag -a v0.5 -m "Earlier" HEAD~1        # tag an older commit
git tag; git tag -l "v0.*"
git show v1.0 | head -8                    # tagger info + commit
git push origin v1.0                       # one tag
git push origin --tags                     # all tags
git ls-remote --tags origin
git tag -d v0.1
git push origin --delete v0.5
git switch --detach v1.0                   # detached HEAD
git switch -c hotfix-1.0                   # keep any new work
git switch main
```
**Expected:** `ls-remote --tags` lists `v1.0` twice (the tag object and `v1.0^{}` the commit it points to). The tag message "Release 1.0" appears in `git show`.

### Lab 9 · Aliases
```bash
git config --global alias.st "status -sb"
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.last "log -1 HEAD"
git config --global alias.unstage "restore --staged --"
git st; git lg; git last --stat
```
**Expected:** shorter commands behave like the full versions. Inspect with `git config --get-regexp alias`.

## 7. Practice challenges
1. Create a repo with a `.gitignore` that ignores all `.env` files and the `node_modules/` dir except `node_modules/keepme.txt`. Make it work, or explain why it can't.
2. You committed `secrets.txt` by mistake (locally, not pushed). Remove it from the repo but keep it on disk and prevent re-adding.
3. Find, using one command, the commit where the string `TODO` was removed from any file.
4. Show the last three commits by a given author, as `hash | subject | relative date`.
5. You staged `a.txt` and `b.txt` but only want `a.txt` in the next commit. Fix it without losing `b.txt`'s edits.
6. Clone your `server.git` twice, create a push conflict from both clones, and resolve it with `git pull`.
7. Create an annotated tag `v2.0` on a commit from 3 commits ago and push only that tag.

<details><summary>Solutions</summary>

1. `.env` + `node_modules/` cannot be partially un-ignored: if the directory is ignored, Git never looks inside. Use `node_modules/*` then `!node_modules/keepme.txt`.
2. `git rm --cached secrets.txt && echo secrets.txt >> .gitignore && git add .gitignore && git commit --amend` (amend only if you haven't pushed; if the secret was ever pushed, rotate it, since history keeps it).
3. `git log -S"TODO" --oneline` (the commit that changed the number of occurrences).
4. `git log -3 --author="Jane" --pretty=format:"%h | %s | %ar"`.
5. `git restore --staged b.txt` then commit.
6. In clone A and B edit different files and commit; push A; B's `git push` is rejected; run `git pull` (merge commit or fast-forward if rebase) then `git push`.
7. `git tag -a v2.0 -m "msg" HEAD~3 && git push origin v2.0`.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| `git add .` swept in junk or secrets | `git restore --staged <file>`; add to `.gitignore`. If committed: `git rm --cached` + amend/new commit. If pushed, rotate the secret. |
| Edited after `git add`, committed old version | `git add` again, `git commit --amend --no-edit` |
| `git commit -a` committed unrelated tweaks | `git reset --soft HEAD~1`, re-stage selectively (`git add -p`) |
| Typo in last commit message | `git commit --amend` (not if already shared) |
| `git restore <file>` threw away work | Not recoverable unless it was staged/committed once; look in editor local history. Use stash first next time. |
| Push rejected "fetch first" | `git pull` (or `git pull --rebase`), then push |
| Tags missing on remote | Tags aren't pushed by default: `git push origin --tags` |
| `.gitignore` rule not working | File already tracked: `git rm --cached file` |
| Committed in detached HEAD | `git switch -c newbranch` immediately (or find the hash in `git reflog`) |

## 9. Real-world use cases
- Everyday feature work: status → add → diff → commit → pull → push.
- Release management: annotated tags like `v2.3.1` that CI turns into packages.
- Incident debugging: `git log -S` to find when a config line vanished; `git log -- path` to see who touched a file.
- Housekeeping: `.gitignore` for build output and secrets, so repos stay small and safe.

## 10. Self-check quiz
1. What does `git diff` compare by default? What about `git diff --staged`?
2. Does `git commit -a` include untracked files?
3. What is the difference between `git rm file` and `git rm --cached file`?
4. What does `git fetch` do that `git pull` also does, and what extra does `pull` do?
5. What's the difference between lightweight and annotated tags?
6. Why doesn't `git push` send your tags?
7. Which command shows commits where a string was added or removed?
8. How do you unstage a file without losing the changes?

<details><summary>Answers</summary>

1. Working tree vs index; index vs last commit.
2. No, only tracked files.
3. First deletes the file and stages the deletion; second only untracks it, leaving it on disk.
4. Both download new commits; `pull` then merges (or rebases) them into your current branch.
5. Lightweight is a bare pointer; annotated is an object with tagger, date, message and optional signature.
6. Tags must be pushed explicitly: `git push origin <tag>` or `--tags`.
7. `git log -S"string"` (pickaxe).
8. `git restore --staged <file>` (or `git reset HEAD <file>`).
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Run the stage → commit → fetch → pull → push loop and read `git status -sb`.
- [ ] Write a correct `.gitignore` and debug it with `git check-ignore -v`.
- [ ] Choose among amend / restore --staged / restore for a given mistake.
- [ ] Filter history by author, date, message, content and path.
- [ ] Tag and share a release; delete a tag locally and remotely.

**Next:** [03-git-branching-and-merging.md](03-git-branching-and-merging.md) — branches, merges, conflict resolution, remote branches and rebasing.
