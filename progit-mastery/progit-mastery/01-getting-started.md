# 01 · Getting Started
> Book reference: Pro Git, Chapter 1, "About Version Control", "A Short History of Git", "What is Git?", "The Command Line", "Installing Git", "First-Time Git Setup", "Getting Help" (book pp. 10–25)
> Level: Beginner · Est. time: 2 h

## 1. Why this matters
Every later chapter assumes you understand how Git *thinks* (snapshots, local operations, three states) and that Git is installed with your identity set. A wrong mental model here causes confusion for years; a missing identity config causes your commits to carry the wrong name forever.

## 2. Prerequisites
- Comfort opening a terminal and running commands (`cd`, `ls`, `mkdir`).
- First file in the path: nothing before it. Next: [02-git-basics.md](02-git-basics.md).

## 3. Learning objectives
- [ ] Explain local, centralized and distributed version control and the weakness of each.
- [ ] Explain "snapshots, not differences" and why most Git operations are local.
- [ ] Describe the three states (modified, staged, committed) and the three areas (working tree, staging area, repository).
- [ ] Install Git, and set `user.name`, `user.email`, editor and default branch.
- [ ] Read config from the system, global and local levels and know which wins.
- [ ] Find help with `git help`, `--help`, `-h`.

## 4. Core concepts

### 4.1 Version control systems (VCS)
A VCS records changes to files over time so you can recall versions, compare, and see who changed what.

| Kind | Example | How it works | Weakness |
|------|---------|--------------|----------|
| Local | RCS, "copy folder to `final_v2`" | Database of changes on your own disk | No collaboration; one disk failure loses everything |
| Centralized (CVCS) | CVS, Subversion, Perforce | One server holds all versions; clients check out files | Single point of failure; no offline commits |
| Distributed (DVCS) | **Git**, Mercurial | Every clone is a *full* copy of the history | Larger initial concept load |

In a DVCS, if any server dies, any client's clone can restore it. You can also run several remotes and mix workflows (see [05-distributed-git-workflows.md](05-distributed-git-workflows.md)).

### 4.2 Short history
Linux kernel developers used the proprietary BitKeeper from 2002. In 2005 that relationship ended, and Linus Torvalds and the community built Git with goals: speed, simple design, strong support for non-linear development (thousands of parallel branches), fully distributed, able to handle huge projects like the kernel.

### 4.3 Snapshots, not differences
Most older VCSs store *a base file plus a list of changes per file* (delta-based).
Git thinks of data as a **stream of snapshots**: at each commit it records what all files look like and stores a reference to that snapshot. Unchanged files are not stored again; the commit just points to the previous identical object.

```
Delta-based:   file A:  v1 ──Δ1──Δ2──Δ3
               file B:  v1 ───────Δ1

Snapshot-based (Git):
 commit 1       commit 2        commit 3
 [A1][B1][C1]   [A2][B1*][C2]   [A2*][B2][C2*]     (* = link to unchanged identical object)
```
This is why branching is cheap and why Git feels like "a tiny filesystem with powerful tools".

### 4.4 Nearly every operation is local
`log`, `diff`, `commit`, `branch`, `checkout` read the full history on your disk. You can work on a plane and push later. Only `clone`, `fetch`, `pull`, `push` touch the network.

### 4.5 Integrity
Everything is checksummed (SHA-1, 40 hex chars; SHA-256 repos exist too) before being stored and is addressed *by* its checksum. Git cannot lose or corrupt content without noticing. Example: `24b9da6552252987aa493b52f8696cd6d3b00373`. You will mostly see the first 7 characters.

### 4.6 Git (almost) only adds data
Once committed, data is very hard to lose. You can experiment freely. (Uncommitted work *can* be lost, so commit often.)

### 4.7 The three states and three areas
A file is in one of three states:

| State | Meaning |
|-------|---------|
| **Modified** | Changed in the working directory, not yet marked for commit |
| **Staged** | Marked to go into your next commit snapshot |
| **Committed** | Safely stored in the local database |

```
 Working Directory ──git add──▶ Staging Area (index) ──git commit──▶ .git directory (repository)
        ▲                                                                   │
        └──────────────────────── git checkout / switch ◀───────────────────┘
```
- **Working directory/tree**: a single checkout of one version, pulled from the compressed database in `.git`.
- **Staging area (index)**: a file in `.git` recording what goes into the next commit.
- **`.git` directory**: the repository database and metadata. This is what gets copied by `git clone`.

Basic workflow: edit files → stage only the changes you want → commit (which stores the staged snapshot permanently).

### 4.8 Command line vs GUI
The CLI is the only place where *all* Git commands are available; GUIs implement subsets. If you know the CLI you can use any GUI, not necessarily the reverse. Book examples use the CLI (Bash on Linux/macOS, Git Bash/PowerShell on Windows).

### 4.9 Installing Git
| OS | How |
|----|-----|
| Fedora/RHEL | `sudo dnf install git-all` |
| Debian/Ubuntu | `sudo apt install git-all` (or `git`) |
| macOS | `git --version` (prompts to install Xcode CLT), or `brew install git` |
| Windows | Download Git for Windows (includes Git Bash), or `winget install Git.Git` |
| Source | Download tarball, `make prefix=/usr/local all`, `sudo make prefix=/usr/local install` |

During Windows setup, pick sensible defaults: editor of your choice, `main` as initial branch, line-ending conversion "checkout Windows-style, commit Unix-style" (`core.autocrlf=true`).

### 4.10 First-time setup: `git config`
Config lives at three levels; **later (more specific) levels override earlier**:

| Level | Flag | File | Scope |
|-------|------|------|-------|
| System | `--system` | `/etc/gitconfig` | all users on the machine |
| Global | `--global` | `~/.gitconfig` or `~/.config/git/config` | you, all repos |
| Local | `--local` (default) | `.git/config` in repo | that repo only |

Priority: **local > global > system**.

Essentials:
```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
git config --global core.editor "code --wait"      # or vim, nano, emacs
git config --global init.defaultBranch main        # 💡 Modern note: book says master
```
Your name/email are baked into every commit and cannot be changed without rewriting history. Use `--global` once; use local config for repos needing a different identity (e.g. work vs personal).

Inspect: `git config --list`, `git config --list --show-origin`, `git config user.name`.

### 4.11 Getting help
```bash
git help <verb>      # opens man page, e.g. git help config
git <verb> --help    # same thing
man git-<verb>       # same
git <verb> -h        # concise option list in terminal
git help -a          # all commands;   git help -g   # concept guides
```
If you don't know a command's name, `git help -a` then read the man page. Also useful: `git help tutorial`, `git help everyday`, `git help glossary`.

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git --version` | Show installed version | After install, when reporting bugs |
| `git config --global user.name "X"` | Set identity name | Once per machine |
| `git config --global user.email "x@y"` | Set identity email | Once per machine |
| `git config --global core.editor ED` | Editor for commit messages | Once |
| `git config --global init.defaultBranch main` | Name of first branch in new repos | Once |
| `git config --list --show-origin` | Show every setting and the file it came from | Debugging config |
| `git config <key>` | Show effective value | Quick check |
| `git config --global --unset <key>` | Remove a setting | Cleanup |
| `git config --global -e` | Open global config in editor | Bulk edits |
| `git help <verb>` / `-h` | Manual / short usage | Any time |

## 6. Hands-on labs
All labs use a temporary config so your real setup is untouched. (On your own machine you may just use the plain commands with `--global`.)

### Lab 1 · Check installation
```bash
git --version
which git        # Windows Git Bash: also works; PowerShell: Get-Command git
```
**Expected:** `git version 2.x.y` and a path. If "command not found", install per §4.9.

### Lab 2 · Configure your identity (safely)
```bash
mkdir -p ~/git-labs/01 && cd ~/git-labs/01
export GIT_CONFIG_GLOBAL="$PWD/lab-gitconfig"   # sandbox: lab uses this file instead of ~/.gitconfig
git config --global user.name  "Jane Doe"
git config --global user.email "jane@example.com"
git config --global init.defaultBranch main
git config --global core.editor nano
cat lab-gitconfig
git config user.name
```
**Expected:**
```
[user]
	name = Jane Doe
	email = jane@example.com
[init]
	defaultBranch = main
[core]
	editor = nano
```
then `Jane Doe`.
(When done with the sandbox: `unset GIT_CONFIG_GLOBAL`. Then to set your real identity, rerun the `git config --global ...` lines.)

### Lab 3 · See which file each setting comes from
```bash
git config --list --show-origin
```
**Expected:** lines prefixed by `file:/etc/gitconfig` (system, may be empty), `file:.../lab-gitconfig` (global). The same key appearing twice means the last one wins.

### Lab 4 · Prove priority: local overrides global
```bash
git init demo && cd demo
git config user.name "Work Jane"           # local (no flag)
git config --show-origin user.name
git config --global user.name              # global value unchanged
echo "hello" > a.txt
git add a.txt && git commit -m "first commit"
git log -1 --format='%an <%ae>'
```
**Expected:** origin shows `file:.git/config`; global still says `Jane Doe`; the log shows `Work Jane <jane@example.com>` — the name came from local, the email fell through to global.

### Lab 5 · The three states, observed
```bash
echo "v1" > f.txt
git status -s          # ?? f.txt          (untracked)
git add f.txt
git status -s          # A  f.txt          (staged)
git commit -m "add f"
echo "v2" >> f.txt
git status -s          #  M f.txt          (modified, not staged)
git add f.txt
git status -s          # M  f.txt          (staged)
```
Note the two status columns: left = staging area vs last commit, right = working tree vs staging area.

### Lab 6 · Everything is local, and checksummed
```bash
git log --oneline                      # works with no network
git rev-parse HEAD                     # full 40-char SHA-1 of latest commit
git cat-file -p HEAD                   # see commit object: tree, author, message
```
**Expected:** a `tree <sha>` line, `author`, `committer`, then the message. This previews [13-git-internals-plumbing-and-objects.md](13-git-internals-plumbing-and-objects.md).

### Lab 7 · Get help like a pro
```bash
git add -h                    # short summary in the terminal
git help config               # full man page (press q to quit)
git help -g                   # list concept guides
git --no-pager help -a | head -20
```
(💡 `--no-pager` goes *before* the subcommand.)

## 7. Practice challenges
1. Configure a different `user.email` for one repo only, and prove with one command which file it came from.
2. Make `git st` an alias-free check: show the config key and value that sets your editor, *and* which file defines it.
3. Create a repo, make a commit, then use only `git config` to change the author name used for the **next** commit.
4. Draw the three areas and mark where a file sits after: edit, `git add`, edit again. (Hint: it is in *two* places with different content.)
5. Find, using only `git help`, which command shows the concept guide for the glossary.

<details><summary>Solutions</summary>

1. `git config user.email work@corp.com && git config --show-origin user.email` → `file:.git/config`.
2. `git config --show-origin core.editor`.
3. `git config user.name "New Name"` then `git commit --allow-empty -m x && git log -1 --format=%an`. (Past commits keep the old name.)
4. After step 2, the staged version is in the index; the newer edit exists only in the working tree. `git status` shows the file in both "Changes to be committed" and "Changes not staged".
5. `git help glossary` (or `man gitglossary`).
</details>

## 8. Common mistakes & how to recover
| Mistake | Symptom | Fix |
|---------|---------|-----|
| Forgot to set identity | `Author identity unknown` error, or commits as `user@hostname.(none)` | Set `user.name`/`user.email`; for the last commit: `git commit --amend --reset-author --no-edit` |
| Wrong email on commits | GitHub does not link commits to your account | Fix config; rewrite recent commits (see [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md)) |
| Editor opens and you cannot exit (vim) | Terminal seems stuck | `:wq` to save, `:q!` to abort; or set `core.editor` |
| Using `--system` without admin | Permission denied | Use `--global` |
| Believing Git stores diffs | Confusion about cheap branching | Re-read §4.3 |
| Config seems ignored | Unexpected value | `git config --list --show-origin` to find the overriding level |

## 9. Real-world use cases
- Onboarding a new laptop: identity, editor, default branch, line endings, and a credential helper in a 2-minute script (many teams keep a dotfiles repo).
- Contractors with two clients: global personal identity, local work identity per repo (or conditional includes `includeIf`, see [11-customizing-git-config-attributes-and-hooks.md](11-customizing-git-config-attributes-and-hooks.md)).
- Debugging "why does CI think I'm someone else?": `git config --list --show-origin`.

## 10. Self-check quiz
1. What is the key advantage of a distributed VCS over a centralized one?
2. Does Git store file differences or snapshots?
3. Name the three states a file can be in.
4. Which areas does each state correspond to?
5. Which Git commands need the network?
6. If `user.name` is set globally and locally, which is used?
7. How does Git guarantee content integrity?
8. How do you see a short usage summary for `git commit` without opening a man page?

<details><summary>Answers</summary>

1. Every clone is a full backup with complete history; no single point of failure, and you can commit offline.
2. Snapshots (with links to unchanged objects).
3. Modified, staged, committed.
4. Modified → working directory; staged → staging area/index; committed → `.git` repository.
5. `clone`, `fetch`, `pull`, `push` (anything talking to a remote).
6. Local (`.git/config`); priority is local > global > system.
7. Everything is checksummed with SHA-1 and addressed by that hash.
8. `git commit -h`.
</details>

## 11. Mastery checklist & next step
Without looking anything up, you can:
- [ ] Explain the snapshot model to a colleague in one minute.
- [ ] Draw working tree → staging area → repository and label the commands between them.
- [ ] Set up identity, editor and default branch on a fresh machine.
- [ ] Debug a config conflict with `--show-origin`.

**Next:** [02-git-basics.md](02-git-basics.md) — create repositories and run the everyday add/commit/diff/log/undo loop.
