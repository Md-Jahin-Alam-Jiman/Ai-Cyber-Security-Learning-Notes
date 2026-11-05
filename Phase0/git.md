# Git: Setup, Everyday Workflow, and Recovery

Git is a distributed version-control system. It records snapshots of files so
you can inspect changes, work on separate lines of development, collaborate,
and recover from many mistakes. Git is the tool; GitHub, GitLab, and similar
services host repositories and add collaboration features.

This guide uses `main` as the primary branch and `feature-name` as an example
work branch. Replace those names and example URLs with your own.

## 1. Install Git and check it

Install Git with your operating system's package manager or from
[git-scm.com](https://git-scm.com/downloads), then check that it is available:

```bash
git --version
```

Git commands are run in a terminal. To see the built-in help:

```bash
git help
git help commit
git commit --help
```

## 2. Configure your identity and defaults

Set the name and email that Git records on your commits. Use an email address
associated with your hosting account, or its provided private/no-reply address
if you do not want your personal email visible in public commits.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

`--global` applies these settings to your user account. To configure only the
current repository, run the same settings inside it and omit `--global`.

Inspect the effective configuration and where values came from:

```bash
git config --list --show-origin
git config user.name
git config user.email
```

Git does not include your hosting-site password in these settings. For
operations with GitHub, GitLab, or another host, authenticate using the
provider's recommended method (commonly SSH keys or a credential manager and
access token). Do not put passwords, tokens, private keys, or other secrets in
repository files or commit history.

## 3. Create or get a repository

### Start tracking an existing directory

```bash
cd path/to/project
git init
git status
```

`git init` creates a `.git` directory containing the repository data. It does
not automatically add or commit your project files.

### Copy an existing hosted repository

```bash
git clone https://host.example/owner/project.git
cd project
```

`clone` downloads the repository and its history, sets up a remote usually
named `origin`, and checks out its default branch.

### Check the current repository

```bash
git status
git rev-parse --show-toplevel
git remote -v
```

`git status` is the best first command when you are unsure what state the
repository is in. It shows the current branch and changes that are staged,
unstaged, or untracked.

## 4. The basic change-and-commit workflow

Git's everyday workflow has three important places:

1. **Working tree**: the files you are editing.
2. **Staging area (index)**: the exact changes selected for the next commit.
3. **Repository history**: committed snapshots.

Inspect what changed:

```bash
git status
git diff                 # Unstaged changes
git diff --staged        # Staged changes
```

Stage a file, or stage all current changes:

```bash
git add path/to/file
git add .
```

`git add .` stages additions, modifications, and deletions under the current
directory. Review `git status` and `git diff --staged` before committing,
especially when the repository contains generated files or secrets.

Commit the staged snapshot:

```bash
git commit -m "Describe the change"
```

A useful commit message says what the commit changes. Keep commits focused so
they are easier to review and, if necessary, undo.

Repeat the inspect, stage, review, and commit steps as you make progress:

```bash
git status
git add path/to/file
git diff --staged
git commit -m "Add input validation"
```

### Stop unwanted files from being tracked

Create a `.gitignore` file in the repository to list files Git should ignore.
For example:

```gitignore
# Operating system and editor files
.DS_Store
.vscode/

# Python-generated files
__pycache__/
*.py[cod]
.venv/

# Local environment settings and secrets
.env
.env.*
!.env.example
```

Patterns depend on the project; do not blindly ignore files the project needs.
Commit the `.gitignore` file so collaborators share the same rules:

```bash
git add .gitignore
git commit -m "Add project ignore rules"
```

`.gitignore` only prevents *untracked* matching files from being added
automatically. If a file is already tracked, remove it from the index while
keeping your local copy:

```bash
git rm --cached path/to/file
```

Then add an appropriate ignore rule and commit that change. If a secret was
committed, removing it in a later commit does not erase it from history: revoke
or rotate the exposed secret immediately.

## 5. See changes: `diff`

`git diff` compares versions of files. It does not change them.

```bash
git diff                         # Working tree vs. staging area
git diff --staged                # Staging area vs. last commit
git diff HEAD                    # Working tree and staging area vs. last commit
git diff main..feature-name      # Compare two branch tips
git diff -- path/to/file         # Limit a diff to one path
git diff --stat                  # Summary of changed files
```

In the output, lines beginning with `-` were removed and lines beginning with
`+` were added. Review staged changes with `git diff --staged` before every
commit.

## 6. Read history: `log`

```bash
git log
git log --oneline
git log --oneline --graph --decorate --all
git log -5
git log -- path/to/file
git show
git show <commit-id>
```

`git log` lists commits; `--oneline` makes a compact list. The graph form
visualizes branches and merges. `git show` displays a commit and its changes.
A commit ID can be copied from `git log`; many commands accept its short form
when it is unambiguous.

## 7. Branches

A branch is a movable name for a line of commits. Branches let you work on a
change without directly changing another branch.

```bash
git branch                         # List local branches
git branch --all                   # List local and remote-tracking branches
git switch -c feature-name         # Create and switch to a new branch
git switch main                    # Switch to an existing local branch
git branch feature-name            # Create a branch without switching
git branch -m new-name             # Rename the current branch
```

Older tutorials may use `git checkout` to switch or create branches.
`git switch` is the newer, more specific command for branch switching.

Commit changes on the feature branch as usual. To publish a new branch to
`origin` and configure its upstream:

```bash
git push -u origin feature-name
```

After that, `git push` and `git pull` can usually infer the upstream branch.
When the work is finished and merged, switch away from the branch and delete
the local branch if it is no longer needed:

```bash
git switch main
git branch -d feature-name
```

`-d` refuses to delete a branch Git considers unmerged. `-D` forces deletion
and can make commits harder to find; do not use it just to silence that
warning. A remote branch can be deleted with:

```bash
git push origin --delete feature-name
```

## 8. Remotes: share work with a host

A remote is a named reference to another repository. `origin` is the
conventional name for the repository you cloned from.

```bash
git remote -v
git remote add origin https://host.example/owner/project.git
git fetch origin
git push -u origin main
```

Only add `origin` if there is not already a remote with that name. A `fetch`
downloads remote commits and updates remote-tracking references, but does not
merge those changes into your current branch.

Bring remote changes into the current branch:

```bash
git pull --ff-only
```

`pull` fetches and then integrates changes. `--ff-only` updates your branch
only when Git can do so without creating a merge commit; if local and remote
work have diverged, it stops so you can inspect and choose how to integrate.
Do not force-push to a shared branch to resolve an ordinary pull or merge
problem.

## 9. Merge branches

To merge a completed feature branch into `main`:

```bash
git switch main
git pull --ff-only
git merge feature-name
```

The branch you are currently on is the destination. The named branch is
merged into it. If Git can combine the changes automatically, the merge
completes. Depending on history and settings, Git may create a merge commit or
fast-forward the destination.

### Resolve a merge conflict

If changes conflict, Git pauses the merge and marks conflicted files:

```bash
git status
```

Open each conflicted file. Conflict markers look like this:

```text
<<<<<<< HEAD
content from the current branch
=======
content from the branch being merged
>>>>>>> feature-name
```

Edit the file to the intended final content and remove all conflict markers.
Then stage the resolved files and finish the merge:

```bash
git add path/to/resolved-file
git status
git commit
```

For a normal merge, `git commit` opens the prepared merge message. Save and
close the editor to complete it. To abandon an unfinished merge and return to
the pre-merge state:

```bash
git merge --abort
```

Use `git merge --abort` only while a merge is in progress. Inspect `git status`
before and after resolving conflicts so you do not accidentally omit files.

## 10. Undo mistakes safely

First inspect the repository state and history:

```bash
git status
git diff
git diff --staged
git log --oneline --decorate -5
```

Choose an undo command based on *where the change is*. The commands below have
different effects; in particular, `restore`, `reset`, and `revert` are not
interchangeable.

### Unstage a file but keep its edits

```bash
git restore --staged path/to/file
```

This removes the file's changes from the staging area. It does not discard the
working-tree edits.

### Discard unstaged edits to a tracked file

```bash
git restore path/to/file
```

This replaces the file's unstaged working-tree content with the staged
version (or the last committed version if nothing is staged). **The discarded
edits may be unrecoverable.** Review `git diff -- path/to/file` first.

To discard all unstaged changes in tracked files:

```bash
git restore .
```

This is broad and destructive. Make sure you do not need any of those edits
before running it. It does not remove untracked files.

### Unstage everything but keep edits

```bash
git reset
```

With no commit specified, this resets the staging area to the current commit
and leaves working-tree content in place.

### Undo the latest local commit

If the commit is local and you want to keep its changes staged:

```bash
git reset --soft HEAD~1
```

To keep the changes but unstage them:

```bash
git reset --mixed HEAD~1
```

`--mixed` is the default mode for `git reset`, so `git reset HEAD~1` has the
same effect. These move the current branch tip back one commit. They are
usually appropriate only for commits that have **not** been shared.

### Undo a commit that has already been shared

Use `git revert` to create a new commit that reverses an earlier commit:

```bash
git revert <commit-id>
```

This preserves existing history and is generally safer for shared branches
than rewriting it with `reset`. Reverting a merge commit requires choosing a
mainline parent; inspect `git help revert` or ask a maintainer before doing
that.

### Recover a lost commit or branch tip

`git reflog` records recent movements of local branch references:

```bash
git reflog
```

If a commit disappeared from the branch after a reset or other operation, find
its commit ID in the reflog and inspect it before recovering:

```bash
git show <commit-id>
git branch recovery-branch <commit-id>
```

Creating a recovery branch preserves the commit under a new name. Reflogs are
local and eventually expire, so they are not a substitute for backups.

### Remove a file

To remove a tracked file and stage that deletion:

```bash
git rm path/to/file
git commit -m "Remove obsolete file"
```

To stop tracking it while keeping the local file, use `git rm --cached` as
described in the `.gitignore` section.

### Do not use a hard reset casually

```bash
git reset --hard <commit-id>
```

This moves the branch and overwrites tracked files in the index and working
tree. Uncommitted tracked-file changes can be lost. Avoid it unless you have
confirmed the exact target and are certain you want to discard those changes.
It is not the normal way to undo a commit that others already have.

## 11. Temporarily put unfinished work aside

Stash saves uncommitted changes so you can switch tasks:

```bash
git stash push -m "work in progress"
git stash list
git stash show -p stash@{0}
git stash apply stash@{0}
git stash pop
```

`apply` restores a stash but keeps it in the stash list. `pop` restores it and
removes it if the application succeeds. A stash is local, not a backup or a
shared commit; commit important work and back it up.

## 12. Rename files and inspect authorship

Git detects most renames by comparing content, but `git mv` can make the
intended move explicit:

```bash
git mv old-name new-name
git status
git commit -m "Rename configuration file"
```

To see who last changed each line of a file:

```bash
git blame path/to/file
```

Use `blame` to understand history, not to assign fault; the surrounding
commits may explain why a line changed.

## 13. Tags and releases

Tags are names for specific commits, often used for releases:

```bash
git tag                         # List tags
git tag v1.0.0                  # Tag the current commit
git show v1.0.0                 # Inspect a tag
git push origin v1.0.0          # Publish one tag
git push origin --tags          # Publish all local tags
```

Coordinate release tags with your project before publishing them. Avoid
changing or deleting tags that collaborators may already rely on.

## 14. A safe collaboration routine

For a small feature, a common routine is:

```bash
git switch main
git pull --ff-only
git switch -c feature-name
# Edit files
git status
git diff
git add path/to/changed-file
git diff --staged
git commit -m "Add a clear feature description"
git push -u origin feature-name
```

Open a pull/merge request on your hosting service so the work can be reviewed.
After it is merged, update your local `main`:

```bash
git switch main
git pull --ff-only
```

Follow your team's contribution and review process if it differs.

## 15. Quick reference

| Goal | Command |
|---|---|
| Check working tree | `git status` |
| Review unstaged edits | `git diff` |
| Review staged edits | `git diff --staged` |
| Stage a file | `git add path/to/file` |
| Commit staged files | `git commit -m "Message"` |
| List branches | `git branch` |
| Create and switch branch | `git switch -c branch-name` |
| Switch branch | `git switch branch-name` |
| Merge into current branch | `git merge branch-name` |
| View compact history | `git log --oneline --graph --decorate --all` |
| Download remote updates | `git fetch origin` |
| Push current branch | `git push` |
| Safely update current branch | `git pull --ff-only` |
| Unstage a file, keep edits | `git restore --staged path/to/file` |
| Discard unstaged edits to a file | `git restore path/to/file` |
| Safely reverse a shared commit | `git revert <commit-id>` |
| Inspect recent branch movements | `git reflog` |

## 16. Good habits

- Run `git status` before and after commands you are unsure about.
- Review `git diff --staged` before committing.
- Make small, focused commits with meaningful messages.
- Work on a feature branch instead of directly on a shared primary branch.
- Fetch and inspect remote work before integrating it.
- Prefer `git revert` for reversing commits that have been shared.
- Treat `git restore`, `git reset --hard`, and force-push operations as
  potentially destructive; understand their effects before using them.
- Do not commit credentials, private keys, tokens, personal data, or
  machine-specific configuration.
- Remember that Git is not a substitute for a backup: local-only commits and
  stashes can be lost with the machine or repository.