# 05 · Distributed Git Workflows
> Book reference: Pro Git, Chapter 5, "Distributed Workflows", "Contributing to a Project", "Maintaining a Project" (book pp. 126–165)
> Level: Intermediate · Est. time: 4 h

## 1. Why this matters
Knowing the commands is not enough. Teams succeed or fail by their *workflow*: who may push where, how changes are reviewed, how releases are cut. This chapter teaches the common patterns (centralized, integration-manager, dictator/lieutenants), both sides of collaboration (contributor and maintainer) and how to work by email patches, which is still how the Linux kernel works.

## 2. Prerequisites
- [03-git-branching-and-merging.md](03-git-branching-and-merging.md): topic branches, merge, rebase, remote-tracking branches.
- [04-git-on-the-server.md](04-git-on-the-server.md): bare repos as shared remotes.

## 3. Learning objectives
- [ ] Describe the three distributed workflows and pick one for a situation.
- [ ] Write commits that follow good-practice guidelines (small, logical, clean whitespace, good messages).
- [ ] Contribute in a small private team, a managed team, a forked public project, and by email.
- [ ] Use ranges: `A..B`, `A...B`, `--not`, `--left-right`.
- [ ] Apply patches with `git apply` and `git am`.
- [ ] As maintainer: review topic branches, merge, rebase or cherry-pick, tag, build numbers, archive, shortlog.

## 4. Core concepts

### 4.1 The three workflows
Distributed means every developer is *both* a contributor and potentially a server. Many topologies are possible.

| Workflow | Shape | Who pushes where | Good for |
|----------|-------|------------------|----------|
| **Centralized** | one shared repo, everyone pushes | everybody → `central` | small teams migrating from SVN. First to push wins; others must fetch/merge. |
| **Integration-manager** | each dev has a public fork; one maintainer merges | devs → own fork; maintainer pulls and pushes to the blessed repo | open source, GitHub-style forks + pull requests |
| **Dictator & lieutenants** | hierarchy; lieutenants merge subsystems; dictator (Linus) merges lieutenants | contributors → lieutenant → dictator | huge projects (Linux kernel) |

Benefits of distributed: flexibility (any structure), offline work, no dependence on one server's permissions.

### 4.2 Commit guidelines (do these before sharing)
- **Whitespace:** `git diff --check` finds trailing whitespace/conflict markers before you commit. Fix them.
- **Logical commits:** each commit = one coherent change, buildable, with tests. Use `git add -p` to split a messy working tree into several commits. Don't pile a week of work into one commit; don't split artificially.
- **Messages:** short (≤50 char) imperative summary, blank line, detailed body (~72 col wrap) answering *why*. Conventions: "Add X", not "Added X". Reviewers read these via `git log`, `git blame`, and patch emails.
- Commit early locally, **tidy before sharing** (amend, interactive rebase: [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md)).

### 4.3 Private small team (centralized)
Two devs push to `origin/main`:
1. John commits locally, Jessica commits locally.
2. Jessica pushes first. John's push is **rejected (fetch first)**.
3. John `git fetch`es and merges (or rebases) `origin/main`, then pushes.
Using a topic branch per feature keeps this tidy; a merge shows up as a diamond in `git log --graph`.
Tip: `git log --no-merges origin/main..HEAD` shows only the commits you are about to share; `git merge origin/main` vs `git pull --rebase` produces merge-vs-linear history.

### 4.4 Private managed team
Several small groups work on features, each on a topic branch, sharing them via the server (`git push -u origin featureA`) and reviewing each other's work before an integrator merges to `main`.
- Check what a branch adds: `git log origin/main..featureA`, `git diff origin/main...featureA`.
- A teammate fetches it: `git fetch origin` → `git log origin/featureA ^featureA` or `--left-right` to compare.
- If a branch already pushed was changed by a teammate, **fetch then merge** (don't force). Use `git push origin local:remote` to push to a differently named branch.
- Squash/rebase before the merge only if the team agrees and nobody else based work on it.

### 4.5 Forked public project
Used by GitHub/GitLab. You can't push to the upstream; you:
1. **Fork** (a server-side clone you own) and `git clone` your fork.
2. `git remote add upstream <original-url>` so you can track the real project.
3. Create a **topic branch** from `upstream/main` (not your `main`, so main stays a clean mirror).
4. Commit; push to your fork: `git push -u origin featureA`.
5. Ask the maintainer to pull: GitHub pull request, or `git request-pull origin/main <your-fork-url> featureA` generates the text for an email. Maintainers add your fork as a remote, fetch, review, and merge.
6. Keep updating: rebase/merge your topic on `upstream/main`; if asked, force-push your own topic branch (`--force-with-lease`).
Keeping `main` clean and working on separate topic branches means you can submit several independent changes and rebase each separately.

### 4.6 Public project over email (patches)
Used by the Linux kernel, Git itself and others.
- **Generate patches:** `git format-patch -M origin/main` creates one `.patch` file per commit (mbox format: `From`, `Subject: [PATCH 1/3] ...`, message, `---`, diffstat, diff). `-M` detects renames. `-1 HEAD --stdout` for the last commit.
- **Send:** `git send-email *.patch` (needs `[sendemail]` config: `smtpServer`, `smtpServerPort`, `smtpEncryption`, `smtpUser`, and ideally an app password), or `git imap-send` to put drafts in an IMAP Drafts folder, or paste into a mail client that doesn't mangle whitespace (use plain-text mode; mail clients often wrap lines and break patches).
- Add notes between the `---` and the diff (e.g., "v2: fixed typo"): they go below the commit message and aren't recorded.
- **Receive:** maintainer saves the mail and applies with `git am`.

### 4.7 Maintaining: applying patches
| Tool | Use | Notes |
|------|-----|-------|
| `git apply <patch>` | Applies a diff to the working tree **all-or-nothing**; no commit | Good for plain diffs (`git diff` output). `--check` tests whether it would apply cleanly. Doesn't stage. |
| `git am <mbox>` | Applies mails as **commits** with the author's name/date/message | Preserves authorship; committer = you. |
| `git am -3` / `--3way` | Falls back to 3-way merge using blob IDs recorded in the patch | helps patches made against slightly different base |
| `git am --continue / --skip / --abort` | Resolve a failed patch, skip it or give up | In a conflict resolve the file, `git add`, `git am --continue` |
| `git am -i` | Interactive prompts | |
Patches applied with `am` keep `Author:` (contributor) and `Commit:` (maintainer), visible via `git log --format=fuller`.

### 4.8 Maintaining: topic branches and ranges
Make a **temporary topic branch** per contribution from `main` (e.g., `sc/ruby_client`), apply/pull the changes there, test, then merge or discard. Branch names encode contributor/subject. Checking out someone's remote branch: `git remote add jessica <url>; git fetch jessica; git switch -c jessicas-feature jessica/feature`.

**Ranges** let you see what a branch *introduces*:
| Syntax | Meaning |
|--------|---------|
| `git log main..topic` | commits reachable from `topic` but not `main` |
| `git log topic --not main` / `^main` | same; works with many refs |
| `git log main...topic` | commits in **either**, but not both (symmetric difference) |
| `git log --left-right main...topic` | with `<` / `>` showing which side |
| `git diff main...topic` | diff since the **merge base** (what topic introduces) |
| `git diff main topic` | diff between the two tips (includes main's own progress; usually not what you want) |
| `git merge-base main topic` | the common ancestor |
Triple-dot `git diff` is the review diff. (More on revision syntax in [07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md).)

### 4.9 Integrating contributed work
- **Simple merge flow:** keep `main` stable; merge reviewed topic branches into it (`git merge --no-ff topic` to always record a merge commit, or fast-forward). Delete the topic after.
- **Big-merging workflow:** long-running branches with graduation: `main` (stable) ← `next`/`develop` (testing) ← `pu`/`proposed-updates` (experimental) and `maint` for fixes (Git's own project uses this). A topic goes into `pu`, graduates to `next`, then `main`. Topic branches that don't graduate are dropped. Merging a batch regularly (e.g. weekly) and rebuilding `pu` from scratch is common.
- **Rebase/cherry-pick workflow:** for linear history, rebase a contributor's topic onto `main`, or `git cherry-pick <commit>` to copy single commits (`-x` appends "(cherry picked from commit …)"; `-n` to not commit). Cherry-pick is the usual way to port a fix to a release branch. Rebase with `--onto` moves a topic branch.
- **Rerere** ("reuse recorded resolution"): `git config rerere.enabled true` remembers conflict resolutions so repeated merges/rebases (e.g. rebuilding `pu`) resolve automatically. Covered in [09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md).

### 4.10 Releasing
- **Tag releases:** `git tag -a v1.1 -m "msg"`; signed: `git tag -s v1.1 -m "msg"` (needs a GPG key; verify with `git tag -v v1.1`). Export your public key into the repo as a blob and tag it so others can verify. See signing in [07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md).
- **Build numbers:** `git describe` returns the nearest annotated tag + commits since + short hash, e.g. `v1.1-4-g43d68b2`. Use `--tags` to include lightweight tags. Great as a version string in builds. (Needs at least one annotated tag. Hash is abbreviated per `core.abbrev`.)
- **Source archive:** `git archive main --prefix=project-1.1/ --format=tar | gzip > project-1.1.tar.gz` or `-o file.zip`. Respects `export-ignore` in `.gitattributes`.
- **Shortlog:** `git shortlog --no-merges main --not v1.0` groups commits by author for release notes; `-sn` gives counts.

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git push origin local:remote` | Push to a differently named remote branch | Naming mismatch |
| `git fetch <remote>` + `git switch -c b <remote>/b` | Get someone's branch | Review |
| `git remote add upstream <url>` | Track original project | Fork workflow |
| `git log A..B` / `A...B` / `--left-right` | Show commit ranges | Review, compare |
| `git diff A...B` | Diff since merge-base | Review what B adds |
| `git merge-base A B` | Common ancestor | Debug divergence |
| `git request-pull <start> <url> [<end>]` | Generate a pull request message | Email PR |
| `git format-patch -M <base>` | One mbox patch per commit | Send by email |
| `git send-email` / `git imap-send` | Send patches | Email workflows |
| `git apply --check/--3way` | Test/apply a diff | Non-commit patches |
| `git am [--3way/--continue/--abort]` | Apply patches as commits | Maintain |
| `git cherry-pick [-x] <c>` | Copy a commit onto current branch | Backport |
| `git describe [--tags]` | Human-readable version | Build numbers |
| `git archive` | Tarball/zip of a tree | Release |
| `git shortlog [-sn]` | Group log by author | Release notes |

## 6. Hands-on labs
Setup (all local; bare repos play the role of GitHub/servers):
```bash
mkdir -p ~/git-labs/05 && cd ~/git-labs/05
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
```

### Lab 1 · Centralized workflow: the push race
```bash
git init --bare central.git
git clone central.git john && git clone central.git jess
(cd john && git config user.name John && git config user.email john@e.com && echo v1 > f && git add . && git commit -m init && git push origin main)
(cd jess && git config user.name Jess && git config user.email jess@e.com && git pull origin main)
(cd jess && echo j > j.txt && git add . && git commit -m "Jess adds j.txt" && git push origin main)
cd john
echo john >> f && git commit -am "John edits f"
git push origin main                  # rejected: fetch first
git fetch && git merge origin/main -m "Merge Jess's work"
git push origin main
git log --oneline --graph
```
**Expected:** first push `! [rejected] main -> main (fetch first)`; after merge, graph shows a diamond. Repeat with `git pull --rebase` instead of merge to get a linear history.

### Lab 2 · Commit hygiene
```bash
printf 'ok line\ntrailing space   \n' > style.txt
git add style.txt
git diff --cached --check            # style.txt:2: trailing whitespace.
sed -i 's/[ \t]*$//' style.txt && git add style.txt && git diff --cached --check && echo clean
git commit -m "Add style.txt"
# Splitting a messy working tree into logical commits:
printf 'a\n' > a.txt; printf 'b\n' > b.txt; git add -N a.txt b.txt
git add -p                            # (choose y for a.txt hunk, n for b.txt)
git commit -m "Add a.txt"; git add b.txt; git commit -m "Add b.txt"
```
**Expected:** `--check` flags only the trailing space; two separate commits afterwards.

### Lab 3 · Topic branches and ranges (managed team)
```bash
git switch -c featureA
echo a1 > a1.txt && git add . && git commit -m "A1"
echo a2 > a2.txt && git add . && git commit -m "A2"
git push -u origin featureA
git log origin/main..featureA --oneline        # A1, A2 (and anything not on main)
git log featureA --not origin/main --oneline   # same
git diff origin/main...featureA --stat         # what featureA introduces
git switch main && echo m > m.txt && git add . && git commit -m "M on main"
git log --left-right --oneline main...featureA # < main-only,  > featureA-only
git merge-base main featureA
git diff main featureA --stat                  # includes m.txt removal: why triple-dot is better
```
**Expected:** `--left-right` marks `M on main` with `<` and A1/A2 with `>`.

### Lab 4 · Fork + pull-request flow (simulated)
```bash
cd ..
git init --bare upstream.git
git clone upstream.git maint && (cd maint && git config user.name Maint && git config user.email m@e.com \
  && echo v0 > app.txt && git add . && git commit -m "init" && git push origin main && git tag -a v1.0 -m "1.0" && git push --tags)
git clone --bare upstream.git fork_con.git      # "fork" = server-side clone
git clone fork_con.git contrib && cd contrib
git config user.name Con && git config user.email c@e.com
git remote add upstream ../upstream.git
git fetch upstream && git switch -c featureA upstream/main
echo feature >> app.txt && git commit -am "Add feature A"
git push -u origin featureA                     # push to YOUR fork
git request-pull v1.0 ../fork_con.git featureA  # text you'd email/paste
cd ../maint
git remote add con ../fork_con.git && git fetch con
git switch -c review/featureA con/featureA      # local review branch (avoid reusing the remote's name: "ambiguous refname")
git log main..review/featureA --oneline
git diff main...review/featureA
git switch main && git merge --no-ff review/featureA -m "Merge feature A from Con"
git push origin main
git log --oneline --graph
```
**Expected:** `request-pull` prints a summary beginning "The following changes since commit …". After the merge, `git log --graph` shows the topic branch as a diamond.
Keep the fork current: in `contrib`, `git fetch upstream && git rebase upstream/main`.
🌐 On GitHub the same steps are "Fork → clone → branch → push → Pull Request"; see [06-github-collaboration.md](06-github-collaboration.md).

### Lab 5 · Email patches: `format-patch` → `am`
```bash
cd ~/git-labs/05/contrib
git switch -c patchwork upstream/main
echo p1 > p1.txt && git add . && git commit -m "Add p1"
echo p2 > p2.txt && git add . && git commit -m "Add p2"
git format-patch -M upstream/main -o ../patches
ls ../patches; head -15 ../patches/0001-*.patch
cd ../maint && git switch -c apply-test main
git apply --check ../patches/0001-Add-p1.patch && echo "would apply"
git am ../patches/*.patch
git log --format=fuller -2                      # Author=Con, Commit=Maint
```
**Expected:** two commits with `Author: Con` and `Commit: Maint`. 
**Break it on purpose** (a branch where `p1.txt` already exists with different content):
```bash
git switch main && git switch -c amc
echo other > p1.txt && git add . && git commit -m "other p1"
git am ../patches/0001-Add-p1.patch    # fails: "Patch failed at 0001 Add p1 ... When you have resolved this problem, run git am --continue"
git am --abort                         # give up cleanly; branch returns to its prior state
```
To resolve instead of aborting: fix the files, `git add` them, `git am --continue` (use `git am --3way` for patches made against a slightly different base).
🌐 Sending for real: `git config sendemail.smtpServer smtp.gmail.com` etc. and `git send-email --to=list@example.org ../patches/*.patch` (needs SMTP credentials; untested here).

### Lab 6 · Cherry-pick a fix to a release branch
```bash
cd ../maint && git switch main
git switch -c release-1 v1.0
git switch main && echo fix > fix.txt && git add . && git commit -m "Fix critical bug"
FIX=$(git rev-parse HEAD)
git switch release-1
git cherry-pick -x $FIX
git log -1 --format=%B                          # message ends "(cherry picked from commit ...)"
```
**Expected:** same change on `release-1` with a new hash and the `-x` trailer.

### Lab 7 · Release chores
```bash
git switch main
git tag -a v1.1 -m "Release 1.1"
echo more >> app.txt && git commit -am "Post-release work"
git describe                                    # v1.1-1-g<hash>
git archive main --prefix=app-1.1/ -o ../app-1.1.tar.gz && tar tzf ../app-1.1.tar.gz | head
git shortlog -sn v1.0..main
git shortlog --no-merges main --not v1.0
```
**Expected:** `describe` prints `v1.1-1-g…`; the tarball has a single top-level `app-1.1/` folder; `shortlog` groups by author.
Optional signed tag (needs GPG, untested here): `git tag -s v1.2 -m "signed"`, `git tag -v v1.2`.

## 7. Practice challenges
1. Starting from Lab 1, repeat the race but resolve it with `git pull --rebase`. Compare `git log --graph` with the merge version.
2. Three devs push to one central repo. Script all three (clones + commits) and make two pushes race. Resolve every rejection.
3. Make a topic branch with 5 commits, one of which has trailing whitespace. Find it with `git diff --check` over the whole range and fix it using `git rebase -i` (see 08) or `--fixup` and `--autosquash`.
4. Create a patch series of 3 commits, apply it with `git am` on a different clone at a slightly older base using `--3way`.
5. As maintainer, you have contributions from two forks that both modify `README`. Merge both and resolve the conflict. Then use `git rerere` so the second resolution is automatic if you redo the merges on a fresh branch.
6. Produce release notes for `v1.0..main` grouped by author, excluding merge commits.
7. Reproduce a "big-merging" workflow with branches `main`, `next` and `pu` and graduate a topic from `pu` → `next` → `main`.

<details><summary>Solutions</summary>

1. `git pull --rebase origin main` (or `git fetch && git rebase origin/main`) → linear history, no merge commit; John's commit gets a new hash.
2. Use a script with three `git clone`s; after each rejected push run `git pull --rebase && git push`.
3. `git diff --check origin/main..HEAD`; fix the commit with `git commit --fixup=<hash>` then `git rebase -i --autosquash origin/main`.
4. `git format-patch -3 -o /tmp/p`; in the other clone `git am --3way /tmp/p/*.patch`.
5. `git config rerere.enabled true` before merging; resolve once; `git reset --hard` back to before the merge, merge again, and Git reuses the recorded resolution ("Resolved 'README' using previous resolution").
6. `git shortlog --no-merges v1.0..main`.
7. `git switch -c next main; git merge topic` and so on; delete `pu` and rebuild it from `next` plus pending topics each cycle.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Push rejected "fetch first" | `git fetch` + merge/rebase, then push; never default to `--force` |
| Working on your fork's `main`, can't separate PRs | Always branch per topic from `upstream/main`; reset your `main` to `upstream/main` |
| Mail client corrupted the patch (wrapped lines) | Use `git send-email`/`imap-send` or attach; `git apply --check` first; `git am --abort` to clean up |
| `git am` stopped halfway | Fix, `git add`, `git am --continue`; or `--skip`/`--abort` |
| Used `git diff A B` to review and saw unrelated changes | Use `git diff A...B` (merge-base) |
| Committed whitespace errors | `git diff --check`, amend/fixup |
| Cherry-picked then merged the original branch and got duplicate/conflicts | Expected sometimes; resolve; prefer merging the fix branch into both targets when possible |
| Rewrote a branch others reviewed | Say so; they should `git fetch` and `git reset --hard origin/branch` (if no local work) |
| `describe` prints only a hash | No annotated tag reachable: tag a release or use `--tags` / `--always` |
| Archive includes things you don't want to ship | `.gitattributes` with `export-ignore` |

## 9. Real-world use cases
- Open source: fork → topic branch → PR; maintainers use `am`/merge and release tags.
- Linux/Git projects: email-based review, `format-patch`/`send-email`, lieutenants merging subsystem trees.
- Companies: centralized or managed-team flow with protected `main`, topic branches, and CI before merge.
- Release engineering: tags, `git describe` in build scripts, `git archive` for tarballs, `shortlog` for changelogs, cherry-picks to maintenance branches.

## 10. Self-check quiz
1. Which workflow fits GitHub-style open source projects?
2. Why make a topic branch instead of working on `main` in your fork?
3. What's the difference between `git diff main topic` and `git diff main...topic`?
4. Difference between `git apply` and `git am`?
5. What does `git cherry-pick -x` add?
6. What does `git describe` output look like, and what does each part mean?
7. When would you use `git request-pull`?
8. What does `--left-right` show in `git log main...topic`?

<details><summary>Answers</summary>

1. Integration-manager (fork + pull request).
2. You can submit independent changes, keep `main` as a clean mirror of upstream, and rebase each topic separately.
3. Two dots (space-separated) compares tips; three dots compares topic against the merge-base, showing only what topic introduced.
4. `apply` changes files only; `am` applies mailbox patches as commits preserving author, date and message.
5. A "(cherry picked from commit …)" line in the message.
6. `<tag>-<commits since tag>-g<abbrev hash>`, e.g. `v1.1-4-g43d68b2`.
7. To email a maintainer a summary asking them to pull your branch from a public URL.
8. Which side each commit belongs to: `<` left (main), `>` right (topic).
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Choose a workflow and explain trade-offs.
- [ ] Contribute via fork/branch/PR, and via email patches.
- [ ] Review a branch with ranges and triple-dot diffs.
- [ ] Apply patches with `am`, handle failures with `--3way`.
- [ ] Cut a release: tag, describe, archive, shortlog; cherry-pick fixes.

**Next:** [06-github-collaboration.md](06-github-collaboration.md): applying all of this on GitHub (accounts, forks, pull requests, organizations, API).
