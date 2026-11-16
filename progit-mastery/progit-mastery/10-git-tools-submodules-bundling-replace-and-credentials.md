# 10 · Git Tools IV: Submodules, Bundling, Replace, and Credential Storage
> Book reference: Pro Git, Chapter 7 "Git Tools", sections "Submodules", "Bundling", "Replace", "Credential Storage" (book pp. 304–341)
> Level: Advanced · Est. time: 4 h

## 1. Why this matters
Real projects depend on other projects, move code between air-gapped machines, need to graft or split histories, and authenticate to servers dozens of times a day. Submodules are the built-in way to nest one repository inside another (and the most common source of "my teammate's clone is broken"). Bundles move history without a server. `replace` transparently rewrites history without changing hashes. Credential helpers remove repeated password prompts safely. All four are fully testable locally.

## 2. Prerequisites
- [03-git-branching-and-merging.md](03-git-branching-and-merging.md), [04-git-on-the-server.md](04-git-on-the-server.md) (bare repos as remotes), [09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md) (conflicts; the subtree alternative).

## 3. Learning objectives
- [ ] Add, clone, update, work in, publish and remove submodules; keep teammates' clones working.
- [ ] Explain what a submodule *is* (a pinned commit + `.gitmodules`) and why it's detached by default.
- [ ] Resolve a submodule pointer conflict; avoid the "pushed a pointer to an unpushed commit" trap.
- [ ] Create, verify, clone from and incrementally update from a **bundle**.
- [ ] Use `git replace` to graft/split/edit history; share replace refs.
- [ ] Configure credential helpers (`store`, `cache`, OS keychains), call `git credential` directly, and write a custom helper.

## 4. Core concepts

### 4.1 Submodules: a repo inside a repo
A **submodule** records *another repository's URL and one specific commit* inside your repo. The superproject doesn't store the submodule's files, just a **gitlink** (tree entry mode `160000`) pointing at a commit hash.

| Piece | Where | Role |
|-------|-------|------|
| Gitlink | the superproject's tree/index (`git ls-files -s path` → mode `160000`) | which commit of the submodule is checked in |
| `.gitmodules` | tracked file in the superproject | path ↔ URL (↔ tracked branch) mapping, shared with the team |
| `.git/config` `[submodule "…"]` | local | URL actually used after `git submodule init` (can be overridden locally) |
| `.git/modules/<name>/` | superproject's `.git` | the submodule's real git directory; `path/.git` is just a file pointing there |

**Adding:** `git submodule add <url> <path>` clones it, stages `.gitmodules` and the gitlink. Relative URLs (`../lib.git`) resolve against the superproject's remote URL, handy when you mirror both repos. Commit both.
**`git status`** shows the submodule as a single path (`M`/`m` for new commits or modified content inside). `git diff --submodule` (or `git config diff.submodule log`) shows the *commits* behind a pointer change. Useful settings: `status.submoduleSummary true`.

**Cloning a project that has submodules**
```bash
git clone --recurse-submodules <url>          # all at once (also recursive)
# or, after a plain clone (submodule dirs are empty):
git submodule update --init --recursive       # = init (register URLs) + update (clone & checkout the pinned commit)
```
`git submodule update` checks out the commit **recorded in the superproject**, leaving the submodule on a **detached HEAD**. That's by design: the superproject pins *exact* commits.

**Getting upstream changes in the submodule**
- Inspect: `git submodule status`.
- Move to the newest upstream commit: `git submodule update --remote` (uses `origin/master`/`main`, or the branch set in `.gitmodules`: `git config -f .gitmodules submodule.<name>.branch stable`). The superproject then shows ` M path`; **commit it** to record the new pin and share it.
- Pull the superproject and its submodules together: `git pull --recurse-submodules`; make this default with `git config submodule.recurse true` (also makes `switch/checkout/reset` update submodules).
- 💡 Pass `--merge` or `--rebase` (`git submodule update --remote --merge`) to integrate upstream into a submodule *branch* that has your local commits, instead of detaching.

**Working inside a submodule**
1. `cd` into it, `git switch <branch>` first (otherwise commits on a detached HEAD are easy to lose).
2. If its local branch is stale, bring it up to date (`git merge origin/main` or `update --remote --merge`) **before** committing, or your push will be rejected (non-fast-forward).
3. Commit/push **inside** the submodule; then commit the new pointer in the superproject.
4. Publish in the **right order**: submodule first, superproject second. If the superproject's pointer references a submodule commit nobody can fetch, every teammate's `update` fails with `not our ref …`. Guard with:
```bash
git push --recurse-submodules=check        # refuses to push the superproject if submodule commits aren't on a remote
git push --recurse-submodules=on-demand    # pushes the submodule first, then the superproject
git config push.recurseSubmodules on-demand
```
**Merge conflicts in submodules:** if two people moved the pointer to different commits, Git can't merge them automatically ("Failed to merge submodule … CONFLICT (submodule)"). Fix: go into the submodule, fetch and **merge** (or pick one) so there is a commit containing both, then in the superproject `git add <path>` and commit (fast-forward cases resolve themselves).

**Tips**
- `git submodule foreach '<cmd>'` runs a command in every submodule (variables `$name`, `$sha1`, `$toplevel`, `$path`): `git submodule foreach 'git stash'`, `git submodule foreach 'git switch main'`.
- Aliases: `git config alias.sdiff '!git diff && git submodule foreach "git diff"'`; `alias.spush 'push --recurse-submodules=on-demand'`; `alias.supdate 'submodule update --remote --merge'`.
- `git submodule sync` re-reads URLs from `.gitmodules` if they changed.
- `git diff --submodule=diff` shows file-level diffs inside submodules.

**Gotchas**
- **Detached HEAD** edits get lost on the next `update`; always switch to a branch first.
- **Switching branches** where one branch has the path as a submodule and another as plain files/dir can fail or leave leftovers ("unable to rmdir", directory in the way). With `submodule.recurse=true`/`--recurse-submodules` it's smoother; otherwise `git submodule update --init` after switching back. In the worst case: move/clean the directory (`git clean -ffd` *(destructive)*) and re-run update.
- **Removing a submodule** (modern recipe):
```bash
git submodule deinit -f libs/lib      # unregister (removes working files, keeps .git/modules cache)
git rm libs/lib                       # remove gitlink and its .gitmodules entry
rm -rf .git/modules/libs/lib          # remove the leftover cache so you can re-add it later
git commit -m "Remove lib submodule"
```
- 💡 **Security note (modern Git):** since 2.38.1 `protocol.file.allow` defaults to `user`, which **blocks `file://`/local-path submodule clones**. For local learning labs we set `git config --global protocol.file.allow always` (in the sandbox config). Don't set it globally on machines that clone untrusted repos.
- **When not to use:** if the dependency is just a library, a package manager (npm/pip/cargo/go modules) is better; subtree ([09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md)) avoids extra steps for consumers at the cost of bigger history.

### 4.2 Bundling: Git without a server
`git bundle` packs objects *and refs* into **one binary file** that behaves like a remote. Use it when there's no network path (air-gapped sites, USB sneakernet, email attachments, flaky links), and for single-file backups.
| Command | Purpose |
|---------|---------|
| `git bundle create repo.bundle HEAD main` | include history reachable from these refs (`--all` for everything). **You must name refs** or the bundle is empty. |
| `git bundle create inc.bundle main ^v1` / `v1..main` | **incremental**: only commits after `v1`. Needs the recipient to already have `v1` (a *prerequisite*). |
| `git bundle verify file.bundle` | check validity; reports missing prerequisites |
| `git bundle list-heads file.bundle` | show the refs inside |
| `git clone repo.bundle dir -b main` | clone from it (origin = the file) |
| `git fetch/pull file.bundle main` | update from an incremental bundle |
Workflow: send the full bundle once; thereafter send incrementals (`git bundle create ../x.bundle main ^<last-sent-tag>`; tag what you sent so you know the next base).

### 4.3 Replace: swap an object without changing hashes
`git replace <object> <replacement>` creates a ref in `refs/replace/<sha-of-object>` that tells Git: *whenever you'd read `<object>`, use `<replacement>` instead*, everywhere (log, checkout, cat-file, …) — without rewriting any commit hashes.
- **Splitting a large history** into a recent part and an archive: create a **new base commit** for recent history with `git commit-tree <tree> -m "Get history from here"`, rebase the recent commits onto it (`git rebase --onto <base> <old-commit> main`), keep the old history on a branch (`history`). Anyone who only wants recent history clones the short one; if they need the past, they `git replace <base> <history-tip>` (or `git replace --graft <base> <history-tip>`) and `git log` shows the whole thing. Hashes of the recent commits do **not** change.
- **Grafting/joining** histories: same idea, `--graft <commit> [<new-parent>…]` creates a replacement commit with new parents.
- **Editing a commit** without rewriting its descendants: `git replace --edit <commit>`.
- Manage: `git replace -l` (list), `git replace -d <object>` (delete), `git --no-replace-objects log` (ignore replacements), `GIT_NO_REPLACE_OBJECTS=1`.
- **Sharing:** replace refs are **not** fetched/pushed by default. Share with `git push origin 'refs/replace/*'` and `git fetch origin 'refs/replace/*:refs/replace/*'`.
- Caveat: `git gc`, fsck and some tools see the *original* objects; replacing is local magic unless shared. Don't use it to hide secrets.

### 4.4 Credential storage
With HTTPS remotes Git needs a username and password/token. Without help it asks every time. Git delegates to **credential helpers**:
| Helper | Behaviour |
|--------|-----------|
| (none) | prompts each time |
| `cache` | keeps credentials **in memory** for `--timeout <sec>` (default 900) via a small daemon; nothing written to disk |
| `store` | writes **plaintext** to `~/.git-credentials` (or `--file <path>`); protect with file permissions (600) |
| `osxkeychain` (macOS), `libsecret`/`gnome-keyring` (Linux), `wincred` | OS secure storage (💡 and **Git Credential Manager**, the cross-platform default on Windows and good for GitHub/Azure DevOps OAuth/2FA) |
Configure by naming the helper, with options inside one quoted string: `git config --global credential.helper "cache --timeout=3600"`. Multiple helpers run in order (first answer wins; store/erase go to all). Reset the list: `git config credential.helper ""`.
**Per-host settings:** `credential.https://github.com.username alice`; `credential.useHttpPath true` (distinguish paths on one host).
💡 Hosts like GitHub need a **personal access token** or OAuth login, not your account password (see [06-github-collaboration.md](06-github-collaboration.md)); for servers you control SSH keys avoid the problem ([04-git-on-the-server.md](04-git-on-the-server.md)).

**Under the hood**: a helper is just an executable named `git-credential-<name>` on `PATH`; Git runs it as `git credential-<name> get|store|erase` and talks via `key=value` lines ending with a blank line (`protocol`, `host`, `path`, `username`, `password`).
- `get`: Git sends what it knows (protocol/host); helper prints `username=…`/`password=…` or nothing.
- `store`: after a successful login, Git sends the credentials to save.
- `erase`: after a failed login, Git sends the bad ones to forget.
You can drive this yourself: `git credential fill | approve | reject` (stdin as above) which is exactly what Git does internally, and how you test helpers.

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git submodule add <url> <path>` | Add a submodule | Start depending on a repo |
| `git clone --recurse-submodules` | Clone with submodules | New checkout |
| `git submodule update --init --recursive` | Fetch pinned commits | After plain clone/pull |
| `git submodule update --remote [--merge/--rebase]` | Move to upstream tip | Bump dependency |
| `git submodule status/foreach/sync` | Inspect/run/refresh | Maintenance |
| `git push --recurse-submodules=check/on-demand` | Safe publish | Always for submodule users |
| `git config submodule.recurse true` | Recurse in pull/switch/etc. | Fewer surprises |
| `git submodule deinit -f p && git rm p` | Remove submodule | Cleanup |
| `git bundle create/verify/list-heads` | Make/inspect bundle | Offline transfer |
| `git clone/fetch/pull file.bundle` | Use bundle | Receiving side |
| `git replace [--graft/--edit] / -l / -d` | Object substitution | Splice/split history |
| `git config credential.helper <h>` | Choose a helper | Stop re-typing passwords |
| `git credential fill/approve/reject` | Drive helpers manually | Test/debug |

## 6. Hands-on labs
Setup (sandboxed config; the `file` protocol is allowed **only for this lab config**):
```bash
mkdir -p ~/git-labs/10 && cd ~/git-labs/10
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
git config --global protocol.file.allow always      # needed for local submodule clones (Git ≥ 2.38.1)
git config --global pull.rebase false
```

### Lab 1 · Create the two repos and add a submodule
```bash
cd ~/git-labs/10
git init --bare lib.git && git clone lib.git libw        # libw = a working copy of the library
(cd libw && echo "lib v1" > lib.txt && git add . && git commit -m "lib v1" && git push origin main)
git init --bare app.git && git clone app.git app && cd app
echo app > app.txt && git add . && git commit -m "app" && git push origin main
git submodule add ../lib.git libs/lib         # relative URL, resolved against app.git's location
git status -s                                 # A  .gitmodules / A  libs/lib
cat .gitmodules
git diff --cached --submodule                 # shows "Submodule libs/lib 0000000...<sha> (new submodule)"
git ls-files -s libs/lib                      # mode 160000: the gitlink
git commit -m "Add lib submodule" && git push origin main
```
**Expected:** `.gitmodules` contains `path = libs/lib` and `url = ../lib.git`; the gitlink has mode `160000`.

### Lab 2 · Cloning: the empty directory surprise
```bash
cd ~/git-labs/10 && git clone app.git clone1 && cd clone1
ls libs/lib | wc -l                           # 0 : directory exists but is empty
git submodule status                          # leading "-" = not initialized
git submodule init && git submodule update
ls libs/lib                                   # lib.txt
git submodule status                          # leading space + (heads/main)
cd .. && git clone --recurse-submodules app.git clone2 && ls clone2/libs/lib
```
**Expected:** `clone1` needs `init`+`update`; `clone2` has the files straight away.

### Lab 3 · Upstream moves: bump the pin
```bash
cd ~/git-labs/10
(cd libw && echo "lib v2" >> lib.txt && git commit -am "lib v2" && git push origin main)
cd clone2
git submodule update --remote                 # fetch + checkout origin/main in the submodule
git status -s                                 #  M libs/lib  (pointer changed)
git diff --submodule                          # Submodule libs/lib <old>..<new>:  > lib v2
git commit -am "Bump lib to v2" && git push origin main
```
**Expected:** the superproject records the new pointer only after you commit it; others get it via `pull --recurse-submodules`.

### Lab 4 · Work inside the submodule, publish in the right order
```bash
cd ~/git-labs/10/clone2/libs/lib && git switch main && cd ../..    # leave detached HEAD
git submodule update --remote --merge         # make local main current (fast-forward/merge)
cd libs/lib && git branch --show-current      # main
echo "lib v3" >> lib.txt && git commit -am "lib v3"
cd ../..
git status -s                                 #  M libs/lib
git commit -am "Bump lib to v3"
git push --recurse-submodules=check           # REFUSED: "submodule paths contain changes that can not be found on any remote"
git push --recurse-submodules=on-demand       # pushes lib first, then app
git -C ../lib.git log --oneline | head -1     # lib v3
```
**Expected:** `check` aborts, `on-demand` succeeds. (Skipping the `update --remote --merge` step and committing on a stale local `main` instead makes the submodule push fail with "rejected … fetch first": the stale-branch gotcha.)

### Lab 5 · A submodule pointer conflict
```bash
cd ~/git-labs/10 && rm -rf ma mb
git clone --recurse-submodules app.git ma && git clone --recurse-submodules app.git mb
( cd ma/libs/lib && git switch main && echo A > a.txt && git add . && git commit -m "A" \
  && cd ../.. && git commit -am "pointer A" && git push --recurse-submodules=on-demand )
( cd mb/libs/lib && git switch main && echo B > b.txt && git add . && git commit -m "B" \
  && cd ../.. && git commit -am "pointer B" )
cd mb
git pull                                      # CONFLICT (submodule): Failed to merge submodule libs/lib
git status -s                                 # UU libs/lib
cd libs/lib && git fetch origin && git merge origin/main -m "merge A and B"   # a commit containing both
cd ../.. && git add libs/lib && git commit -m "Resolve submodule merge"
git push --recurse-submodules=on-demand
git -C ../lib.git log --oneline | head -1     # merge A and B
```
**Expected:** Git says it can't merge submodule pointers automatically and tells you to merge inside the submodule. After the manual merge, both `a.txt` and `b.txt` exist in `libs/lib`.

### Lab 6 · The classic trap: pointer to an unpushed commit
```bash
cd ~/git-labs/10 && rm -rf bad victim
git clone --recurse-submodules app.git bad
cd bad/libs/lib && git switch main && echo oops > oops.txt && git add . && git commit -m "unpushed submodule commit"
cd ../.. && git commit -am "pointer to unpushed" && git push origin main      # plain push: no check!
cd .. && git clone --recurse-submodules app.git victim    # fatal: … not our ref <sha>   (teammate's clone is broken)
# Fix: publish the missing submodule commit
cd bad/libs/lib && git push origin main && cd ../../..
rm -rf victim && git clone --recurse-submodules app.git victim && ls victim/libs/lib
```
**Expected:** the first `victim` clone errors with `not our ref`, the second works. Prevent forever with `git config push.recurseSubmodules check`.

### Lab 7 · `foreach`, aliases, and `submodule.recurse`
```bash
cd ~/git-labs/10/mb
git submodule foreach 'echo "$name @ $(git rev-parse --short HEAD) ($sha1)"'
git config --global alias.sdiff '!git diff && git submodule foreach "git diff"'
git config --global alias.spush 'push --recurse-submodules=on-demand'
git config --global alias.supdate 'submodule update --remote --merge'
git supdate
git config submodule.recurse true
git config --get submodule.recurse            # true
```

### Lab 8 · Branch switching and removing a submodule
```bash
cd ~/git-labs/10 && rm -rf sw && git clone --recurse-submodules app.git sw && cd sw
git switch -c nolib && git rm -f libs/lib && git commit -m "remove submodule"
git switch main && ls libs/lib | wc -l       # 0: empty dir (no recursion)
git submodule update --init && ls libs/lib | wc -l      # files back
# With recursion enabled, switching does it for you:
git config submodule.recurse true
git switch nolib && ls libs 2>&1 | head -1   # No such file or directory
git switch main && ls libs/lib | wc -l       # files present again
# Full removal recipe:
cd ~/git-labs/10 && rm -rf rm1 && git clone --recurse-submodules app.git rm1 && cd rm1
git submodule deinit -f libs/lib
git rm libs/lib && git commit -m "Remove lib submodule"
ls -A .git/modules                            # leftover cache: libs
rm -rf .git/modules/libs/lib
git status -s                                 # clean
```
**Expected:** after the manual `rm`, re-adding the same submodule path works (no "already exists in the index/.git/modules").

### Lab 9 · Bundles: a "remote" in one file
```bash
cd ~/git-labs/10 && rm -rf bund bundclone *.bundle && git init bund && cd bund
for i in 1 2 3; do echo "$i" > f; git add .; git commit -m "c$i"; done
git tag v1
git bundle create ../repo.bundle HEAD main    # refs must be named
git bundle verify ../repo.bundle
git bundle list-heads ../repo.bundle
cd .. && git clone repo.bundle bundclone -b main && cd bundclone
git log --oneline | wc -l                      # 3
git remote -v                                  # origin = the bundle file
# new work on the source side, sent as an INCREMENTAL bundle:
cd ../bund && echo "4" > f && git commit -am c4 && echo "5" > f && git commit -am c5
git bundle create ../incr.bundle main ^v1      # only what's after v1
git bundle verify ../incr.bundle
cd ../bundclone && git pull ../incr.bundle main
git log --oneline | wc -l                      # 5
# A recipient lacking the prerequisites:
cd .. && git init empty && cd empty && git bundle verify ../incr.bundle   # error: Repository lacks these prerequisite commits
```
**Expected:** full bundle verifies ("The bundle records a complete history"); the clone has 3 commits; after the incremental pull 5; the empty repository reports missing prerequisites.

### Lab 10 · Replace: split a history and re-join it
```bash
cd ~/git-labs/10 && rm -rf rep && git init rep && cd rep
for i in 1 2 3 4 5; do echo $i > f; git add .; git commit -m "c$i"; done
git branch history HEAD~2                            # archive branch: c1..c3
BASE=$(git commit-tree 'HEAD~2^{tree}' -m "Get history from here")   # new root with c3's snapshot
git rebase --onto $BASE HEAD~2 main                  # recent commits (c4, c5) now sit on the new root
git log --oneline                                    # c5, c4, "Get history from here"   (3 commits)
git replace --graft $BASE history                    # splice the archive back in
git log --oneline                                    # c5, c4, Get history…, c3, c2, c1   (6 commits)
git replace -l                                       # one replacement (the BASE sha)
git --no-replace-objects log --oneline | wc -l       # 3: replacements ignored
git replace -d $BASE                                 # remove the replacement
git log --oneline | wc -l                            # 3
# edit a commit's message without rewriting its descendants:
GIT_EDITOR="sed -i 's/^c5/c5 EDITED/'" git replace --edit HEAD
git log --oneline -1                                 # c5 EDITED
git --no-replace-objects log --oneline -1            # c5 (original)
# sharing replace refs is explicit:
git init --bare ../rep.git && git remote add origin ../rep.git
git push origin main 'refs/replace/*'
git clone ../rep.git ../repc && cd ../repc
git log --oneline -1                                 # c5 (no replacement yet)
git fetch origin 'refs/replace/*:refs/replace/*'
git log --oneline -1                                 # c5 EDITED
```
**Expected:** the commented line counts/messages. The recent commits' hashes never changed; only the base commit's parents were swapped *virtually*.

### Lab 11 · Credential helpers (offline, with the `git credential` plumbing)
Everything is kept inside the lab directory (nothing touches `~/.git-credentials`).
```bash
cd ~/git-labs/10 && rm -rf creds cache && mkdir -m 700 cache      # the cache socket directory must be private (700)
# store helper → plaintext file
git config --global credential.helper "store --file $PWD/creds"
printf 'protocol=https\nhost=example.com\nusername=alice\npassword=s3cret\n\n' | git credential approve
cat creds                                            # https://alice:s3cret@example.com
stat -c %a creds                                     # 600 (macOS: stat -f %Lp creds)
printf 'protocol=https\nhost=example.com\n\n' | git credential fill     # prints username=alice password=s3cret
printf 'protocol=https\nhost=example.com\nusername=alice\npassword=s3cret\n\n' | git credential reject
wc -c < creds                                        # 0 : erased
# cache helper → memory only
git config --global credential.helper "cache --timeout=60 --socket=$PWD/cache/sock"
printf 'protocol=https\nhost=cache.example.com\nusername=carol\npassword=pw3\n\n' | git credential approve
printf 'protocol=https\nhost=cache.example.com\n\n' | git credential fill   # served from memory
git credential-cache --socket "$PWD/cache/sock" exit                        # forget everything
printf 'protocol=https\nhost=cache.example.com\n\n' | GIT_TERMINAL_PROMPT=0 git credential fill   # fatal: terminal prompts disabled
```
Now write your own helper (this is exactly the protocol Git speaks):
```bash
mkdir -p bin && cat > bin/git-credential-demo <<'EOF'
#!/bin/sh
# Minimal credential helper: `git credential-demo get|store|erase`
DB="${DEMO_CRED_DB:-$HOME/.demo-creds}"
action="$1"
while IFS='=' read -r k v; do [ -z "$k" ] && break; eval "in_$k=\$v"; done
case "$action" in
  get)   [ -f "$DB" ] && grep "^$in_host " "$DB" | tail -1 | { read -r h u p; [ -n "$u" ] && printf 'username=%s\npassword=%s\n' "$u" "$p"; } ;;
  store) printf '%s %s %s\n' "$in_host" "$in_username" "$in_password" >> "$DB" ;;
  erase) [ -f "$DB" ] && { grep -v "^$in_host " "$DB" > "$DB.tmp"; mv "$DB.tmp" "$DB"; } ;;   # (grep -v exits 1 when nothing is left, so no && chain)
esac
EOF
chmod +x bin/git-credential-demo
export PATH="$PWD/bin:$PATH" DEMO_CRED_DB="$PWD/demo-creds"
git config --global credential.helper demo
printf 'protocol=https\nhost=h.example.com\nusername=dave\npassword=pw4\n\n' | git credential approve
cat demo-creds                                       # h.example.com dave pw4
printf 'protocol=https\nhost=h.example.com\n\n' | git credential fill
printf 'protocol=https\nhost=h.example.com\nusername=dave\npassword=pw4\n\n' | git credential reject
wc -c < demo-creds                                   # 0
# per-host config:
git config --global credential.https://example.com.username alice
git config --global --get credential.https://example.com.username
```
**Expected:** each `fill` prints the four key=value lines; `reject` empties the store; after `cache exit` the lookup fails because prompts are disabled. 🌐 With a real remote you'd just set `git config --global credential.helper osxkeychain` (macOS), `libsecret` (Linux, if built) or Git Credential Manager (Windows/any) and push once; it will remember.

## 7. Practice challenges
1. Add two submodules (`libs/a`, `libs/b`) and make a script that clones the superproject and initializes only `libs/a`.
2. Make a submodule track the `stable` branch (`.gitmodules` `branch = stable`) and update to it with one command.
3. Break a teammate's clone on purpose by pushing a pointer to an unpushed submodule commit, then repair it. Then add the config that prevents it.
4. Move a submodule's URL to another server (change `.gitmodules`) and make existing clones follow it (`git submodule sync`).
5. Build a 3-bundle chain: full bundle, incremental 1, incremental 2, and replay them in a fresh repository in order.
6. Make a "recent-only" repository (last 3 commits) of a 10-commit history and re-attach the archive locally with `git replace`; verify with `git blame` or `git log` that the full history is visible.
7. Write a credential helper that reads a token from an environment variable (`GIT_DEMO_TOKEN`) for any host, and test it with `git credential fill`.
8. Compare submodule vs subtree for a vendored library: write down 3 trade-offs for consumers, 3 for maintainers.

<details><summary>Solutions</summary>

1. `git clone <url> p && cd p && git submodule update --init libs/a` (path argument limits init/update).
2. `git config -f .gitmodules submodule.libs/lib.branch stable && git add .gitmodules && git commit`; then `git submodule update --remote libs/lib`.
3. Lab 6. Prevention: `git config --global push.recurseSubmodules check` (or `on-demand`).
4. Edit `.gitmodules`, commit; teammates run `git submodule sync --recursive && git submodule update --init`.
5. `git bundle create full.bundle main`, tag `b1`; `git bundle create inc1.bundle main ^b1`, tag `b2`; `inc2.bundle main ^b2`. In a fresh repo: `git pull full.bundle main`, then `inc1`, then `inc2`.
6. As Lab 10 with `git rebase --onto`; `git replace --graft <base> history`; `git log --oneline` shows all; `git --no-replace-objects log` shows 3.
7. In the script's `get` branch: `printf 'username=token\npassword=%s\n' "$GIT_DEMO_TOKEN"`; test with `GIT_DEMO_TOKEN=abc git credential fill`.
8. Submodule: consumers must `--recurse-submodules`/`init`; exact pins are explicit; small history; push order discipline. Subtree: one clone, history grows, harder to push changes back upstream, no detached HEAD problems.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Cloned and `libs/` is empty | `git submodule update --init --recursive` (or clone with `--recurse-submodules`) |
| `fatal: transport 'file' not allowed` on local submodule clone | Modern Git security default; lab-only fix: `git config --global protocol.file.allow always` (or `git -c protocol.file.allow=always …`) |
| Commits made on detached HEAD inside a submodule "vanished" | `git reflog` inside the submodule; `git branch rescue <sha>`; next time `git switch <branch>` first |
| Submodule push rejected "fetch first" | The submodule's local branch was stale: `git merge origin/main` (or `update --remote --merge`) then push |
| Teammates get `not our ref <sha>` | You pushed the superproject but not the submodule. Push the submodule commit now; use `push.recurseSubmodules=check` |
| Pointer conflict on merge/pull | Merge inside the submodule, `git add` the path, commit (Lab 5) |
| `git status` always shows `m`/`M` for a submodule | New commits (`M`) → commit the pointer or `git submodule update`; modified/untracked content (`m`/`?`) → commit or clean inside the submodule |
| Re-adding a removed submodule fails ("already exists in the index"/".git/modules") | Follow the removal recipe including `rm -rf .git/modules/<path>` |
| `bundle create` produced an empty/“refusing to create empty bundle” | Name refs: `git bundle create f.bundle main` / `--all` |
| Incremental bundle won't apply | Missing prerequisite commits; apply earlier bundles first (`git bundle verify`) |
| `git replace` "works on my machine" only | Replace refs aren't shared; `git push origin 'refs/replace/*'` and fetch them |
| Credentials saved in plaintext | `store` is plaintext by design; use keychain/GCM, or `cache` |
| Wrong/old password keeps being used | `git credential reject` (or edit/delete the entry in the helper's store) and retry |
| Token committed in a URL (`https://user:token@…`) | Rotate the token; use helpers instead ([08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md) for history cleanup) |

## 9. Real-world use cases
- **Shared libraries/themes/protobuf definitions** pinned across several apps (submodules), with CI doing `git submodule update --init --recursive`.
- **Air-gapped transfers:** weekly incremental bundles on a USB stick between a secure network and a build server.
- **Huge history migrations:** shipping a "shallow" repository to new hires with the archive available via `replace`, after an SVN/CVS import ([12-git-and-other-systems-svn-migration.md](12-git-and-other-systems-svn-migration.md)).
- **Developer experience:** one-time keychain/GCM setup so HTTPS pushes never prompt; custom helpers that fetch short-lived tokens from a secrets manager (Vault/AWS) in CI.

## 10. Self-check quiz
1. What exactly does the superproject store for a submodule?
2. Why is a submodule on a detached HEAD after `git submodule update`?
3. Which two commands get submodule content after a plain `git clone`?
4. What does `git push --recurse-submodules=check` do, and what error does it prevent?
5. How do you remove a submodule completely?
6. What is the difference between a full and an incremental bundle? What's a prerequisite?
7. What does `git replace A B` do, and does it change any commit hashes?
8. Are replace refs pushed/fetched by default?
9. `cache` vs `store` credential helpers?
10. What are the three actions of a credential helper?

<details><summary>Answers</summary>

1. A gitlink (mode 160000 + commit SHA) in the tree, and the URL/path in `.gitmodules`.
2. Because the superproject pins an exact commit, not a branch.
3. `git submodule init` and `git submodule update` (or `git submodule update --init --recursive`).
4. Refuses to push the superproject if a referenced submodule commit isn't on a remote, preventing `not our ref` breakage for teammates.
5. `git submodule deinit -f path`, `git rm path`, `rm -rf .git/modules/path`, commit.
6. Full contains complete history of named refs; incremental contains only commits after a base, requiring the recipient to already have that base (prerequisites).
7. Makes Git read object B whenever A is requested (via `refs/replace/A`); no hashes change.
8. No; push/fetch `refs/replace/*` explicitly.
9. `cache` holds credentials in memory for a timeout; `store` saves them in plaintext on disk.
10. `get`, `store`, `erase`.
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Add, clone, bump, work in, publish and remove a submodule without breaking teammates.
- [ ] Diagnose `not our ref`, detached HEAD loss and pointer conflicts.
- [ ] Transfer a repository (and later updates) with bundles.
- [ ] Splice or edit history with `git replace` and share it.
- [ ] Configure and debug credential helpers; explain the helper protocol.

**Next:** [11-customizing-git-config-attributes-and-hooks.md](11-customizing-git-config-attributes-and-hooks.md): configuration, attributes, hooks and policy enforcement.
