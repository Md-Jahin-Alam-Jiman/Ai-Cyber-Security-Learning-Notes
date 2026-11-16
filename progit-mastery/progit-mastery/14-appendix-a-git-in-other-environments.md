# 14 · Appendix A: Git in Other Environments (GUIs, IDEs, Shells, Scripting)
> Book reference: Pro Git, Appendix A, "Git in Other Environments" (book pp. ~481–506)
> Level: Beginner–Intermediate · Est. time: 1.5–2 h
> 🌐 GUI and IDE sections can't be run in a terminal sandbox: they are described, not lab-tested. The bash prompt, aliases and machine-readable output labs **were tested** on Git 2.43.

## 1. Why this matters
You will rarely use only the command line. Teammates use VS Code, JetBrains IDEs, Visual Studio or GitHub Desktop, and you will want a good shell prompt and tab completion. Knowing what each tool actually does (it is always running the same Git commands) lets you move between them and fix problems when a GUI misbehaves.

## 2. Prerequisites
[01-getting-started.md](01-getting-started.md), [02-git-basics.md](02-git-basics.md), [11-customizing-git-config-attributes-and-hooks.md](11-customizing-git-config-attributes-and-hooks.md) (config, aliases).

## 3. Learning objectives
- [ ] Choose a GUI/IDE integration for the tasks it does best (visual history, partial staging, merge resolution).
- [ ] Set up a Git-aware prompt and tab completion in bash, zsh or PowerShell.
- [ ] Use Git's **stable machine-readable output** in scripts safely.
- [ ] Know the limits: what GUIs hide and when to drop to the CLI.

## 4. Core concepts

### 4.1 Graphical interfaces
Two tiers exist:
- **Bundled tools:** `gitk` (history browser) and `git gui` (commit tool: stage hunks/lines, amend, commit). Launch from a repo. Often a separate package (`git-gui`, `gitk`) on Linux.
- **Third-party and integrated:** GitHub Desktop (clone/branch/PR flow, simple, hides rebase and staging details), Sourcetree, GitKraken, Fork, Tower, Git Extensions, SmartGit, lazygit/tig (terminal UIs).
Strengths of GUIs: **visual commit graph**, hunk/line staging, drag-and-drop interactive rebase, three-pane merge editors, blame/history per line. Weaknesses: they hide commands, differ in defaults (e.g. auto-fetch, auto-stash, rebase vs merge on pull), and can make "undo" harder to reason about. Rule: *know the CLI equivalent of what you click.* The reflog ([07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md)) recovers GUI mistakes too.

### 4.2 IDE and editor integrations
| Tool | Highlights |
|------|-----------|
| **Visual Studio Code** | Source Control view (stage hunks/lines, commit, branch), inline blame/diff gutter, 3-way merge editor, timeline per file; extensions (GitLens, Git Graph). Uses your installed `git` |
| **JetBrains IDEs** (IntelliJ, PyCharm, WebStorm…) | Commit tool window with partial commits and changelists, Git Log view, interactive rebase UI, shelve, integrated conflict resolver |
| **Visual Studio** | Git Changes window, branch/PR integration, Team Explorer replaced by Git menu |
| **Sublime Text / Sublime Merge, Vim (fugitive), Emacs (Magit)** | Editor-native workflows; Magit is a very complete Git UI |
All of them respect your `~/.gitconfig` (identity, aliases, hooks, `.gitattributes`). Hooks run when the IDE commits (so `pre-commit` failures show in its output panel). Set the IDE's integrated terminal and external tools consistently ([11-customizing-git-config-attributes-and-hooks.md](11-customizing-git-config-attributes-and-hooks.md) for `difftool`/`mergetool`).

### 4.3 Git in Bash
- **Tab completion:** the `git-completion.bash` script completes commands, branches, remotes, tags, options. Packages install it automatically (`/usr/share/bash-completion/completions/git`); otherwise source it from your `~/.bashrc`. After sourcing, `git ch<TAB>` → `checkout`/`cherry-pick`…, `git switch <TAB>` lists branches. It also completes for aliases and for `git-<custom>` subcommands.
- **Prompt:** `git-prompt.sh` (here `/usr/lib/git-core/git-sh-prompt`) provides `__git_ps1`. Use it in `PS1`:
```bash
source /usr/lib/git-core/git-sh-prompt            # path varies: also ~/.git-prompt.sh from the Git source
GIT_PS1_SHOWDIRTYSTATE=1          # * unstaged changes, + staged changes
GIT_PS1_SHOWUNTRACKEDFILES=1      # % untracked files
GIT_PS1_SHOWSTASHSTATE=1          # $ stash exists
GIT_PS1_SHOWUPSTREAM=auto         # < behind, > ahead, <> diverged, = in sync
GIT_PS1_SHOWCOLORHINTS=1          # colours (use with PROMPT_COMMAND)
PS1='\u@\h:\w$(__git_ps1 " (%s)")\$ '
```
Branch name appears in the prompt, plus symbols and special states (`|REBASE-i 2/5`, `|MERGING`, `|BISECTING`) that tell you at a glance that you're mid-operation. Note the single quotes: `$(…)` must be evaluated at **each prompt**, not once.

### 4.4 Git in Zsh and PowerShell
- **Zsh:** ships completion (`compinit`, enabled by default in many setups; smarter than bash's: descriptions, menu). For the prompt use `vcs_info` (built in, `precmd` hook) or a framework (**Oh My Zsh** themes, Powerlevel10k, Starship).
- **PowerShell:** install **posh-git** (`Install-Module posh-git -Scope CurrentUser`; add `Import-Module posh-git` to `$PROFILE`). Gives tab completion and a prompt showing branch and counts (e.g. `[main +1 ~2 -0 | +0 ~1 -0]`). Cross-shell prompts: **Starship** works in bash/zsh/fish/PowerShell.
- 🌐 Not run in the sandbox (no zsh/PowerShell).

### 4.5 Git from scripts and other languages
Two approaches:
1. **Shell out** to `git` and parse stable output (simple, matches CLI exactly). Use:
   - `--porcelain` / `--porcelain=v2` (`status`), `-z` (NUL-separated, safe for odd filenames), `--format` (`log`, `for-each-ref`, `branch`), `rev-parse`, `ls-files`, `diff --name-status`, `cat-file --batch`. **Avoid parsing default human output**; it changes between versions and with locale/config. Set `LC_ALL=C` and `git -c color.ui=false -c core.pager=cat` or `--no-pager` for determinism.
2. **Libraries:** libgit2 bindings (**pygit2** for Python, **Rugged** for Ruby, **NodeGit**, **LibGit2Sharp** for .NET, **git2-rs** for Rust, **go-git** pure Go, **JGit** pure Java, **Dulwich** pure Python, **GitPython** (wraps the CLI)). Faster and typed; may lag in features; they don't run hooks or read every config the same way. Details: [15-appendix-b-embedding-git-in-applications.md](15-appendix-b-embedding-git-in-applications.md).

### 4.6 Useful environment/config for tool authors
`GIT_DIR`, `GIT_WORK_TREE`, `GIT_PAGER`, `GIT_TERMINAL_PROMPT=0` (never prompt for credentials: fail instead, important in CI), `GIT_SSH_COMMAND`, `GIT_OPTIONAL_LOCKS=0` (read-only commands like `status` skip index refresh writes: use in prompts/watchers so they don't fight with a running command), `GIT_TRACE`.

## 5. Command cheat sheet
| Command | Purpose |
|---------|---------|
| `gitk [--all]`, `git gui` | Bundled history viewer / commit tool |
| `git status --porcelain=v2 -b [-z]` | Stable status output for scripts |
| `git for-each-ref --format='%(refname:short) %(objectname:short)' refs/heads` | Scriptable branch list |
| `git log --format='%H%x00%an%x00%s' -z` | NUL-delimited fields/records |
| `git rev-parse --abbrev-ref HEAD` / `--show-toplevel` / `--git-dir` | Current branch / repo root |
| `git diff --name-status -z A B` | Changed paths with status |
| `git -c key=val cmd` | One-off config for a script |
| `git config alias.<n> '<cmd>'` | Shortcuts |

## 6. Hands-on labs
Setup:
```bash
mkdir -p ~/git-labs/14 && cd ~/git-labs/14
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
LAB="$PWD"; git init -q demo && cd demo && git commit -q --allow-empty -m first
```

### Lab 1 · A Git-aware prompt (tested)
```bash
PROMPT_SRC=/usr/lib/git-core/git-sh-prompt; [ -r "$PROMPT_SRC" ] || PROMPT_SRC=/usr/share/git-core/contrib/completion/git-prompt.sh
. "$PROMPT_SRC"
GIT_PS1_SHOWDIRTYSTATE=1 GIT_PS1_SHOWUNTRACKEDFILES=1 GIT_PS1_SHOWUPSTREAM=auto
echo "[$(__git_ps1 ' (%s)')]"                  # [ (main)]
echo x > f; echo "[$(__git_ps1 ' (%s)')]"      # [ (main %)]   untracked
git add f;  echo "[$(__git_ps1 ' (%s)')]"      # [ (main +)]   staged
echo y >> f; echo "[$(__git_ps1 ' (%s)')]"     # [ (main *+)]  staged + unstaged
git commit -qam second; git switch -qc feat; echo "[$(__git_ps1 ' (%s)')]"   # [ (feat)]
```
To use it permanently add to `~/.bashrc`: the `source` line, the `GIT_PS1_*` variables and `PS1='\w$(__git_ps1 " (%s)")\$ '`. **Expected:** the branch and the symbols above change as you work.
Try: during a conflicting `git rebase -i`, watch the prompt show `|REBASE-i 1/2`.

### Lab 2 · Aliases and shell helpers (tested)
```bash
git config --global alias.st 'status -sb'
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.last 'log -1 --stat'
git config --global alias.br 'for-each-ref --sort=-committerdate --format="%(committerdate:relative) %(refname:short)" refs/heads'
git config --global alias.unstage 'restore --staged'
git st; git lg | head -3; git br
# a shell-command alias (prefix with !) and a custom subcommand
git config --global alias.root '!pwd'; git root
printf '#!/bin/sh\ngit for-each-ref --format="%%(refname:short)" refs/heads | grep -v "^main$"\n' > "$LAB/git-others"
chmod +x "$LAB/git-others"; PATH="$LAB:$PATH" git others    # `git others` runs your git-others
```
**Expected:** each alias runs; `git others` (a script named `git-<name>` on PATH) lists non-main branches.

### Lab 3 · Machine-readable output for scripts (tested)
```bash
echo z > z.txt; git status --porcelain=v2 --branch          # stable, documented format
git status --porcelain -z | tr '\0' '\n'
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/heads
git log -3 --format='%h|%an|%s'
git log -1 --pretty=format:'{"sha":"%h","subject":"%s"}'; echo     # beware: subjects containing quotes need escaping!
python3 - <<'PY'
import subprocess
def git(*a): return subprocess.run(["git", "-c", "color.ui=false", "--no-pager", *a], capture_output=True, text=True, check=True).stdout
branch = git("rev-parse", "--abbrev-ref", "HEAD").strip()
dirty = [l[3:] for l in git("status", "--porcelain=v1").splitlines()]
sha, author, subject = git("log", "-1", "--format=%H%x00%an%x00%s").rstrip("\n").split("\0")
print(branch, "| dirty:", dirty, "| last:", sha[:7], author, subject)
PY
git ls-files -z | tr '\0' '\n'; git diff --name-status -z HEAD~1 HEAD | tr '\0' ' '; echo
```
**Expected:** consistent output regardless of your locale or colour config. In the Python part you see the branch, dirty files and last commit parsed reliably using `%x00` delimiters instead of spaces or `|`.

### Lab 4 · Prove the CLI is the engine (tested)
```bash
GIT_TRACE=1 git status -sb 2>&1 | grep -E "trace: (built-in|run_command)" | head -3
GIT_TRACE=1 git commit --allow-empty -qm traced 2>&1 | grep trace | head -4
GIT_TRACE=1 git st 2>&1 | grep -i "alias"                  # trace shows alias expansion
```
**Expected:** trace lines showing the actual commands. IDEs run these same commands; many have an "output" or "Git log" panel to see them.

### Lab 5 · GUI/IDE exercises (🌐 on your own machine)
1. Open `demo/` in VS Code. Stage *one hunk* of a two-hunk edit from the Source Control view; confirm with `git diff --cached`.
2. Open the same repo in `git gui` or GitHub Desktop; create a branch and compare with `git branch`.
3. Cause a merge conflict (see [03-git-branching-and-merging.md](03-git-branching-and-merging.md)) and resolve it in your editor's merge tool; check `git status` shows it resolved.
4. In your IDE, find the equivalent of `git blame`, `git stash`, `git log -p -- <file>` and write the CLI form next to each.

## 7. Practice challenges
1. Build a prompt that shows only branch name and a `!` if the repo has any uncommitted changes, without using `__git_ps1` (use `git branch --show-current` and `git status --porcelain`).
2. Write `git-recent` (a script on PATH) listing the 5 most recently committed branches with relative dates.
3. Write a Python function returning `(ahead, behind)` for the current branch using `git rev-list --left-right --count @{u}...HEAD`.
4. Write a `bash` function `gcd <branch>` that switches to a branch, pulls with `--ff-only`, and prints `git st`.
5. Make `git lg` colourful by adding `--format` with `%C(auto)` placeholders.
6. Use `GIT_TERMINAL_PROMPT=0 git ls-remote https://example.invalid/x.git` to show a non-interactive failure.

<details><summary>Hints</summary>

1. `PS1='$(b=$(git branch --show-current 2>/dev/null); [ -n "$b" ] && echo "($b$([ -n "$(git status --porcelain)" ] && echo !))") \$ '`.
2. `git for-each-ref --sort=-committerdate --count=5 --format='%(committerdate:relative)  %(refname:short)' refs/heads`.
3. Output of rev-list is `behind<TAB>ahead` when you use `@{u}...HEAD --left-right`; handle "no upstream" with try/except.
4. `gcd(){ git switch "$1" && git pull --ff-only && git st; }`.
5. `--format='%C(yellow)%h%C(reset) %C(auto)%d%C(reset) %s %C(blue)(%an)'`.
6. It fails immediately instead of waiting for a password prompt.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Prompt shows no branch | `__git_ps1` not sourced or `PS1` uses double quotes (evaluated once). Use single quotes |
| Prompt is slow in huge repos | Disable `GIT_PS1_SHOWUNTRACKEDFILES`/`SHOWDIRTYSTATE`, or `git config bash.showDirtyState false` for that repo; enable `core.fsmonitor`/untracked cache |
| GUI and CLI disagree | Different `git` binary or config (check `git --version`, `git config --list --show-origin` in each). Refresh the GUI |
| GUI auto-fetch/auto-stash surprises | Review its settings; it is running ordinary `fetch`/`stash` commands |
| Script breaks for filenames with spaces/newlines | Use `-z` and NUL-delimited parsing |
| Script output changes after Git upgrade | You parsed human output; switch to `--porcelain`/`--format` |
| Script hangs in CI | Set `GIT_TERMINAL_PROMPT=0`, use tokens/SSH keys, add timeouts |
| Prompt/watcher causes `index.lock` errors | Set `GIT_OPTIONAL_LOCKS=0` for read-only polling |

## 9. Real-world use cases
- Team-wide shell setup (completion, prompt, aliases) in a dotfiles repo.
- Using a GUI for visual history/partial staging while scripting releases in the CLI.
- Tooling (status bars, CI checks, release scripts) built on porcelain/`--format` output or libgit2.

## 10. Self-check quiz
1. What do the `*`, `+`, `%` markers in `__git_ps1` mean?
2. Why must `PS1` use single quotes with `$(__git_ps1)`?
3. Why prefer `--porcelain` over default `git status` output in scripts?
4. What does `-z` change and why does it matter?
5. How can you see what commands a GUI is really running?
6. What does `GIT_TERMINAL_PROMPT=0` do?
7. How do you create a custom `git foo` subcommand?

<details><summary>Answers</summary>

1. Unstaged changes (`*`), staged changes (`+`), untracked files (`%`).
2. So the command substitution is evaluated every time the prompt is drawn.
3. It's a documented, stable format independent of locale/config/version.
4. Fields/records are NUL-separated, so spaces, quotes and newlines in names can't break parsing.
5. `GIT_TRACE=1` (or the tool's own output/log panel).
6. Git fails instead of asking for credentials interactively.
7. Put an executable named `git-foo` on `PATH`.
</details>

## 11. Mastery checklist & next step
- [ ] Your shell has completion and a Git-aware prompt.
- [ ] You can name the CLI equivalent of every GUI action you use.
- [ ] Your scripts use porcelain/`--format`/`-z` rather than parsing human output.

**Next:** [15-appendix-b-embedding-git-in-applications.md](15-appendix-b-embedding-git-in-applications.md): command-line Git vs libgit2/JGit/go-git/Dulwich.
