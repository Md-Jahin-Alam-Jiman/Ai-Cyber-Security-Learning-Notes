# 16 · Appendix C: Git Command Reference (grouped by task)
> Book reference: Pro Git, Appendix C, "Git Commands" (book pp. ~529–501+; the book lists commands by chapter, this file groups them by **what you want to do** and links to the lesson that teaches each one)
> Level: Reference · Est. time: use as a lookup; ~1 h to skim and run the verification lab
> The command names below were checked against Git 2.43 by Lab 1. Newer commands are marked 💡.

## 1. How to use this file
Look up a task ("undo my last commit"), find the command, then open the linked lesson for the explanation and labs. Every command also has `git help <cmd>` and `git <cmd> -h` (short usage).

## 2. Setup and configuration → [01](01-getting-started.md), [11](11-customizing-git-config-attributes-and-hooks.md)
| Task | Command |
|------|---------|
| Set identity / editor / default branch | `git config --global user.name "…"`, `user.email`, `core.editor`, `init.defaultBranch main` |
| See settings and where they come from | `git config --list --show-origin` |
| Create a repo / clone one | `git init`, `git clone <url> [dir]` (`--depth 1`, `--bare`, `--mirror`, `--recurse-submodules`) |
| Aliases | `git config --global alias.st "status -sb"` |
| Help | `git help <cmd>`, `git <cmd> -h`, `git help -a` |

## 3. Everyday snapshots → [02](02-git-basics.md)
| Task | Command |
|------|---------|
| See state | `git status [-sb]` |
| Stage | `git add <path>`, `git add -p` (hunks), `git add -u` (tracked only) |
| Commit | `git commit -m "msg"`, `-a` (tracked files), `--amend` |
| Diff | `git diff` (unstaged), `--staged`, `<a>..<b>`, `--stat`, `--word-diff` |
| Move/delete | `git mv a b`, `git rm [--cached] f` |
| Ignore | `.gitignore`, `.git/info/exclude`, `core.excludesFile` |
| History | `git log [--oneline --graph --decorate --all]`, `-p`, `--stat`, `--author`, `--since`, `-S"text"`, `-G<regex>`, `-L :func:file` |
| Show one object | `git show <rev>[:path]` |

## 4. Undoing things → [02](02-git-basics.md), [07](07-git-tools-revision-selection-staging-stashing.md), [08](08-git-tools-rewriting-history-and-reset.md)
| Situation | Command |
|-----------|---------|
| Discard unstaged changes in a file | 💡 `git restore <file>` (older: `git checkout -- <file>`) |
| Unstage a file | 💡 `git restore --staged <file>` (older: `git reset HEAD <file>`) |
| Fix the last commit | `git commit --amend [--no-edit]` |
| Undo a **published** commit safely | `git revert <sha>` (`-m 1` for a merge) |
| Move branch back, keep changes | `git reset --soft <rev>` / `--mixed` (default) |
| Move branch back, discard changes | `git reset --hard <rev>` (**destructive**) |
| Recover "lost" work | `git reflog`, then `git branch rescue <sha>`; `git fsck --lost-found` ([13](13-git-internals-plumbing-and-objects.md)) |
| Shelve work temporarily | `git stash [push -u -m msg]`, `stash list/pop/apply/drop/branch` |
| Remove untracked files | `git clean -n` (preview!) then `git clean -fd` |

## 5. Branching and merging → [03](03-git-branching-and-merging.md), [09](09-git-tools-advanced-merging-rerere-and-debugging.md)
| Task | Command |
|------|---------|
| List / create / delete branch | `git branch [-a -vv]`, `git branch <n>`, `git branch -d <n>` (`-D` force) |
| Switch | 💡 `git switch <n>`, `git switch -c <n>` (older: `git checkout [-b]`) |
| Merge | `git merge <n>` (`--no-ff`, `--squash`, `--abort`) |
| Resolve conflicts | edit files → `git add` → `git commit`; `git mergetool`; `git checkout --ours/--theirs <f>`; `git diff --diff-filter=U` |
| Rebase | `git rebase <base>`, `-i` (interactive), `--onto`, `--continue/--abort/--skip` |
| Pick a commit | `git cherry-pick <sha>` (`-x`, ranges) |
| Remember resolutions | `git config rerere.enabled true` |
| Working trees for parallel branches | `git worktree add ../dir <branch>` |
| Tags | `git tag`, `git tag -a v1 -m msg`, `git push origin v1`/`--tags`, `git tag -d`, `git tag -s` (signed) |

## 6. Remotes and collaboration → [02](02-git-basics.md), [05](05-distributed-git-workflows.md), [06](06-github-collaboration.md)
| Task | Command |
|------|---------|
| Manage remotes | `git remote -v`, `add`, `rename`, `remove`, `set-url`, `show origin`, `prune origin` |
| Download | `git fetch [--all --prune]`, `git pull [--rebase | --ff-only]` |
| Upload | `git push [-u] origin <branch>`, `--force-with-lease` (safer than `--force`), `--delete`, `--tags` |
| Track a branch | `git branch -u origin/<n>`, `git switch <n>` (auto-tracks) |
| Patches by mail | `git format-patch`, `git send-email`, `git am`, `git apply`, `git request-pull` |
| Compare branches | `git log main..feature`, `git diff main...feature`, `git cherry -v`, 💡 `git range-diff` |
| Pull requests (hosting service) | push a branch, open PR; fetch with `refs/pull/<n>/head` |
| Archive / release | `git archive`, `git describe`, `git shortlog -sn` |

## 7. Inspecting and debugging → [07](07-git-tools-revision-selection-staging-stashing.md), [09](09-git-tools-advanced-merging-rerere-and-debugging.md)
| Task | Command |
|------|---------|
| Who changed this line | `git blame [-L a,b] [-w -C] <file>` |
| Find the commit that broke it | `git bisect start`, `good`/`bad`, `run <script>`, `reset` |
| Search content | `git grep [-n -p --count] <pat>`, `git log -S/-G` |
| Name revisions | `HEAD~3`, `HEAD^2`, `@{upstream}`, `@{yesterday}`, `:/text`, `A..B`, `A...B`, `^A`, `--not` |
| Count / list objects | `git rev-list`, `git count-objects -v`, `git shortlog`, `git whatchanged` (legacy) |
| Verify signatures | `git verify-commit`, `git verify-tag`, `git log --show-signature` |

## 8. Rewriting history and large changes → [08](08-git-tools-rewriting-history-and-reset.md), [13](13-git-internals-plumbing-and-objects.md)
| Task | Command |
|------|---------|
| Squash / reorder / edit / drop | `git rebase -i <base>` |
| Autosquash fixups | `git commit --fixup <sha>`, `git rebase -i --autosquash` |
| Rewrite everything | 💡 `git filter-repo` (separate install, preferred), legacy `git filter-branch` |
| Split a subdirectory out | `git subtree split --prefix=dir -b newbranch` |
| Replace a commit without rewriting | `git replace` |
| Notes on commits | `git notes add/show` |

## 9. Submodules, subtrees, bundles → [10](10-git-tools-submodules-bundling-replace-and-credentials.md)
| Task | Command |
|------|---------|
| Add / init / update | `git submodule add <url> <path>`, `submodule update --init --recursive`, `git clone --recurse-submodules` |
| Pull newest submodule commits | `git submodule update --remote`, `git submodule foreach '<cmd>'` |
| Subtree merge | `git subtree add/pull/push --prefix=dir <url> <ref> [--squash]` |
| Offline transfer | `git bundle create f.bundle --all`, `git clone f.bundle`, `git bundle verify` |
| Credentials | `git config credential.helper cache/store/manager` |

## 10. Server administration → [04](04-git-on-the-server.md), [11](11-customizing-git-config-attributes-and-hooks.md)
| Task | Command |
|------|---------|
| Bare repo for sharing | `git init --bare repo.git`, `git clone --bare` |
| Serve | `git daemon --base-path=… --export-all`, `git http-backend` (CGI), `git-shell` (restricted login), SSH |
| Server policy | `receive.denyNonFastForwards`, `receive.denyDeletes`, hooks `pre-receive`/`update`/`post-receive` |
| Maintenance | `git gc [--prune=now]`, `git repack -a -d`, `git fsck`, 💡 `git maintenance start`, `git prune` |

## 11. Interop and migration → [12](12-git-and-other-systems-svn-migration.md)
| Task | Command |
|------|---------|
| Subversion | `git svn clone -s`, `rebase`, `dcommit` |
| Perforce | `git p4 clone/sync/submit` |
| Import/export streams | `git fast-import`, `git fast-export` |

## 12. Plumbing (scripts, tools, internals) → [13](13-git-internals-plumbing-and-objects.md), [14](14-appendix-a-git-in-other-environments.md), [15](15-appendix-b-embedding-git-in-applications.md)
| Command | Purpose |
|---------|---------|
| `hash-object`, `cat-file`, `ls-tree`, `ls-files`, `mktree` | Read/write objects |
| `update-index`, `read-tree`, `write-tree`, `commit-tree` | Index and commit construction |
| `update-ref`, `symbolic-ref`, `rev-parse`, `for-each-ref`, `show-ref`, `ls-remote` | Refs |
| `verify-pack`, `pack-objects`, `unpack-objects`, `index-pack`, `repack` | Packs |
| `check-attr`, `check-ignore`, `check-ref-format`, `diff-tree`, `diff-index`, `merge-base`, `merge-file`, `rev-list`, `name-rev` | Helpers |
| `upload-pack`, `receive-pack` | Smart protocol server ends |
| `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_TRACE`, `GIT_TERMINAL_PROMPT`, `GIT_SSH_COMMAND` | Environment control |

## 13. Emergency card
| Oh no… | Do this |
|--------|---------|
| I committed to the wrong branch | `git branch right-branch` → `git reset --hard HEAD~1` (on the wrong one) → `git switch right-branch` |
| I need to undo my last commit but keep the work | `git reset --soft HEAD~1` |
| I reset --hard and lost commits | `git reflog` → `git reset --hard HEAD@{n}` or `git branch rescue <sha>` |
| I pushed a secret | Rotate it; purge with `filter-repo`; force-push; tell collaborators ([13](13-git-internals-plumbing-and-objects.md)) |
| Merge went wrong | `git merge --abort` (in progress) or `git reset --hard ORIG_HEAD` (finished, unpushed) |
| Rebase went wrong | `git rebase --abort`; later: `git reflog`, reset to pre-rebase entry |
| Detached HEAD with new commits | `git switch -c keep-this` |
| Push rejected (non-fast-forward) | `git pull --rebase` (or merge), then push; never force a shared branch |
| Hook blocking an urgent commit | `git commit --no-verify` (and fix after) |
| Which command did my GUI run? | `GIT_TRACE=1` ([14](14-appendix-a-git-in-other-environments.md)) |

## 14. Hands-on labs
### Lab 1 · Verify every command name against your Git (tested)
```bash
cmds="add am apply archive bisect blame branch bundle cat-file check-attr check-ignore check-ref-format cherry cherry-pick clean clone commit commit-tree config count-objects credential daemon describe diff diff-tree difftool fast-export fast-import fetch for-each-ref format-patch fsck gc grep hash-object help http-backend init log ls-files ls-remote ls-tree maintenance merge merge-base merge-file mergetool mktree mv name-rev notes p4 pack-objects prune pull push range-diff read-tree rebase receive-pack reflog remote repack replace request-pull rerere reset restore rev-list rev-parse revert rm send-email shortlog show show-ref sparse-checkout stash status submodule subtree svn switch symbolic-ref tag unpack-objects update-index update-ref upload-pack verify-commit verify-pack verify-tag whatchanged worktree write-tree index-pack"
missing=""
for c in $cmds; do
  if git help -a 2>/dev/null | grep -qE "^ +$c( |$)" || [ -x "$(git --exec-path)/git-$c" ] || git "$c" -h >/dev/null 2>&1; then :; else missing="$missing $c"; fi
done
echo "Not available in this install:${missing:- none}"
git --version
```
**Expected:** on Git 2.43 only add-ons such as `svn`, `p4`, `send-email` or `filter-repo` may be missing, depending on packaging. (`git filter-repo` and 💡 newer commands are not part of core Git 2.43.)

### Lab 2 · Emergency card drills (tested)
```bash
mkdir -p ~/git-labs/16 && cd ~/git-labs/16 && rm -rf drill
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"; git config --global user.name "Jane Doe"; git config --global user.email jane@example.com; git config --global init.defaultBranch main
git init -q drill && cd drill
echo 1 > f; git add f; git commit -qm one
# drill 1: committed on the wrong branch
echo 2 > f; git commit -qam "meant for feature"
git branch feature && git reset -q --hard HEAD~1 && git switch -q feature && git log --oneline && git switch -q main && git log --oneline
# drill 2: reset --hard lost commits
git switch -q feature; echo 3 > f; git commit -qam three; git reset -q --hard HEAD~2
git reflog | head -3; git reset -q --hard HEAD@{1}; git log --oneline
# drill 3: detached HEAD
git checkout -q --detach HEAD~1; echo d > d; git add d; git commit -qm "detached work"; git switch -q -c keep-this; git log --oneline | head -2
# drill 4: bad merge, finished but unpushed
git switch -q main; git merge -q --no-edit keep-this 2>&1 | tail -1; git reset -q --hard ORIG_HEAD; git log --oneline
```
**Expected:** each drill recovers: `feature` holds the "meant for feature" commit and `main` is back at `one`; the reflog restores the lost `three`; `keep-this` holds the detached commit; the merge is undone by `ORIG_HEAD`.

## 15. Practice challenges
1. Without looking, write the command for each row of §13, then check.
2. From memory, list the three `reset` modes and which of HEAD/index/working tree each changes.
3. Pick five commands from §7 and run each in a repo of your own.
4. Add your own 10 most-used commands as a personal cheat sheet with aliases.
5. For each of the 15 files, write one sentence: "I'd reach for this when …".

## 16. Mastery checklist & what's next
- [ ] You can find the right command for a task in under a minute using this file.
- [ ] You can recover from every row of the Emergency card.
- [ ] You have read all 16 files, run the labs, and ticked every checklist in the README tracker.

**You've finished the Pro Git sequence.** Next steps: contribute a real pull request to an open-source project; read `git help <command>` pages for commands you use daily; explore `git worktree`, `sparse-checkout`, partial clones and `git maintenance`; try tooling like `git filter-repo`, `lazygit`, `pre-commit`.
