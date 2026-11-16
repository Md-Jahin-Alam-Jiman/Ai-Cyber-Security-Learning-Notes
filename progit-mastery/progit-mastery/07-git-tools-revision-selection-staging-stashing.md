# 07 · Git Tools I: Revision Selection, Interactive Staging, Stashing, Signing, Searching
> Book reference: Pro Git, Chapter 7 "Git Tools", sections "Revision Selection", "Interactive Staging", "Stashing and Cleaning", "Signing Your Work", "Searching" (book pp. 218–242)
> Level: Intermediate · Est. time: 4 h

## 1. Why this matters
Daily Git is `add/commit/push`, but professionals constantly need to *point at* exact commits, craft clean commits from a messy working tree, park unfinished work, prove who authored something, and find "where did this line come from?". These tools are the difference between fighting Git and driving it. All labs here are local and fully testable.

## 2. Prerequisites
- [02-git-basics.md](02-git-basics.md), [03-git-branching-and-merging.md](03-git-branching-and-merging.md) (commit graph, ranges `..`/`...` were introduced in [05-distributed-git-workflows.md](05-distributed-git-workflows.md)).
- `gpg` installed for the signing lab (optional).

## 3. Learning objectives
- [ ] Name any commit: short SHA, `HEAD~n`, `^n`, `branch@{n}`, `:/text`, `rev:path`.
- [ ] Use ranges: `A..B`, `^A B`, `--not`, `A...B`, `--left-right`.
- [ ] Use the reflog to find and recover "lost" commits.
- [ ] Stage selectively with `git add -p` and `git add -i`; unstage/discard hunks interactively.
- [ ] Stash, list, apply, pop, drop, branch from a stash; include untracked files; keep the index.
- [ ] Clean untracked files safely (`git clean -n/-f/-d/-x`).
- [ ] Create and verify GPG-signed tags and commits.
- [ ] Search with `git grep`, `git log -S`, `-G`, `-L`, `--grep`.

## 4. Core concepts

### 4.1 Revision selection: naming commits
| Form | Meaning | Example |
|------|---------|---------|
| Full / short SHA-1 | 40 hex / ≥4 unambiguous hex chars | `git show 8d1ed46` (Git picks length automatically; large repos like Linux need 12+; `core.abbrev`, `git rev-parse --short=10 HEAD`) |
| Branch/tag name | Tip commit the ref points to | `git show topic`, `git rev-parse main` |
| `HEAD`, `@` | Current commit (`@` alone is a shortcut for `HEAD`) | `git rev-parse @` |
| `ref@{n}` | Where `ref` pointed *n moves ago* (reflog; **local only**) | `HEAD@{2}`, `main@{1}` |
| `ref@{time}` | Where it pointed then | `main@{yesterday}`, `HEAD@{2.weeks.ago}` |
| `@{-1}` | The previously checked-out branch | `git show @{-1}` |
| `@{u}` / `@{upstream}` | Upstream tracking branch | `git log @{u}..` (unpushed commits) |
| `rev^` | First parent | `HEAD^` |
| `rev^n` | n-th parent (merge commits have 2) | `HEAD^2` = the merged-in side |
| `rev~n` | n-th **first-parent** ancestor (`~3` = `^^^`) | `HEAD~3` |
| `rev^{tree}` / `^{commit}` | Peel to type | `git rev-parse HEAD^{tree}` |
| `:/text` | Youngest commit whose message matches regex | `git show :/"fix login"` |
| `rev:path` | File as of that commit | `git show HEAD~3:f.txt` |
| `:path` / `:0:path` | File in the index | `git show :0:f.txt` |
| `git describe` | Name from nearest tag | `v1.1-4-g43d68b2` |

Combine freely: `HEAD~3^2`, `HEAD^^2~1`. Note `~` follows first parents (linear), `^2` jumps to the second parent.
`git rev-parse <anything>` shows what a name resolves to (great for learning).

**Reflog** = the local journal of where `HEAD` and each branch pointed. Git records it automatically on commits, checkouts, resets, rebases, merges. 
```bash
git reflog                 # == git log -g --abbrev-commit --pretty=oneline
git show HEAD@{5}
git log -g main            # reflog of main
```
Entries expire (default ~90 days reachable / 30 days unreachable). It is *not* shared by clones. The reflog is how you recover from bad resets/rebases/deleted branches. Reflog is a safety net, not a backup.

### 4.2 Commit ranges
Ranges answer "what's in A that's not in B?"
| Syntax | Result | Equivalent |
|--------|--------|------------|
| `main..side` | commits reachable from `side`, not from `main` | `side ^main`, `side --not main` |
| `^A B C` | in B or C, not in A | `B C --not A` (use `--not` for >2 refs; e.g. "commits in either branch not in the remote") |
| `A...B` | in either but not both (symmetric difference) | `A B --not $(git merge-base --all A B)` |
| `--left-right A...B` | marks `<` (only A) and `>` (only B) | |
Useful forms: `git log origin/main..HEAD` (what I'm about to push), `git log HEAD..origin/main` (what I'm missing), `git diff A...B` (review diff since the merge base).

### 4.3 Interactive staging
Goal: build clean, *logical* commits from a messy working tree.
- **`git add -p` (patch mode)** splits changes into **hunks** and asks per hunk:
  `y` stage · `n` skip · `q` quit · `a` stage this and all remaining in file · `d` skip this and the rest of the file · `s` **split** into smaller hunks · `e` **edit** the hunk manually · `g` go to hunk · `/` search · `j/k/J/K` navigate · `?` help.
  Works on untracked files only after `git add -N file` (intent-to-add).
- **`git add -i`** shows a menu: `1 status`, `2 update` (stage tracked files), `3 revert` (unstage), `4 add untracked`, `5 patch`, `6 diff` (review what's staged), `7 quit`. Mostly you use `5` patch; the rest is easier via commands.
- The same hunk-by-hunk UI exists elsewhere: `git reset -p` (unstage hunks), `git restore -p` / `git checkout -p` (discard hunks), `git stash push -p` (stash hunks), `git commit -p`, `git add -e`.
- Before committing, inspect with `git diff --staged` and `git status` to confirm you staged what you meant.
- 💡 Many editors (VS Code, JetBrains, GitKraken) offer the same per-line staging in a GUI; see [14-appendix-a-git-in-other-environments.md](14-appendix-a-git-in-other-environments.md).

### 4.4 Stashing: park unfinished work
The stash is a stack of *temporary commits* (saved in `refs/stash`) holding your modified tracked files and staged changes, so you can switch branches with a clean tree.
| Command | Effect |
|---------|--------|
| `git stash` / `git stash push -m "msg"` | stash tracked changes (staged + unstaged), clean the tree. 💡 `git stash save` is deprecated for `push`. |
| `git stash list` | `stash@{0}: On main: my wip` (newest first) |
| `git stash show [-p] [stash@{n}]` | summary / full diff |
| `git stash apply [stash@{n}]` | re-apply, **keep** the stash. By default staged state is NOT restored; add `--index` to restore it |
| `git stash pop` | apply + drop |
| `git stash drop stash@{n}` / `git stash clear` | delete one / all |
| `git stash push -u` (`--include-untracked`) | also stash untracked files |
| `git stash push -a` (`--all`) | also ignored files |
| `git stash push -k` (`--keep-index`) | stash but keep staged changes in the tree (test only what's staged) |
| `git stash push -p` | choose hunks interactively |
| `git stash push -S` (`--staged`) | stash only staged changes (💡 Git ≥ 2.35) |
| `git stash branch newbranch [stash]` | new branch from the commit the stash was made on, apply, drop on success; solves conflicts when `apply` fails |
Stashes can conflict on apply like any merge. Stash is **local** (never pushed). Don't let it become a dumping ground; name your stashes.
Typical use: urgent bugfix interrupts a feature → `git stash push -m feat` → fix on another branch → return → `git stash pop`.

### 4.5 Cleaning the working directory
`git clean` removes **untracked** files (not committed, not staged). It cannot be undone.
| Option | Meaning |
|--------|---------|
| `-n` / `--dry-run` | show what would be deleted (**always first**) |
| `-f` | required to actually delete (config `clean.requireForce`) |
| `-d` | include untracked directories |
| `-x` | also remove ignored files (build output) |
| `-X` | remove *only* ignored files |
| `-i` | interactive |
Safer alternative: `git stash push -a` (stash everything, drop later). Full reset to pristine: `git reset --hard && git clean -fdx` (dangerous).

### 4.6 Signing your work
Git proves *who*, not *what*, unless you sign. Anyone can set `user.name` to your name; signatures make authorship verifiable.
- **GPG basics:** `gpg --gen-key`, list with `gpg --list-keys --keyid-format long` (the long ID after `ed25519/` or `rsa4096/`), export public key `gpg --armor --export <ID>` (upload to GitHub/GitLab). Tell Git: `git config --global user.signingkey <ID>`.
- **Signed tags:** `git tag -s v1.5 -m "my signed 1.5 tag"`; verify `git tag -v v1.5` (needs the signer's public key in your keyring).
- **Signed commits:** `git commit -S -m "msg"`; always: `git config --global commit.gpgsign true` (and `tag.gpgsign true`). Show: `git log --show-signature -1`, or `git log --pretty="%h %G? %GS"` where `%G?` = `G` good, `B` bad, `U` good/untrusted, `N` none, `E` can't check, `X/Y/R` expired/revoked.
- **Verify on merge:** `git merge --verify-signatures topic` (refuses unsigned/bad commits), `git pull --verify-signatures`; `git merge -S` signs the resulting merge commit; `git verify-commit <c>` / `git verify-tag <t>`.
- **Everyone must sign** only if the team agrees: otherwise contributors can hit friction with rebase/cherry-pick (which rewrite commits and need re-signing: `git rebase --gpg-sign`).
- 💡 **Modern note:** Git ≥ 2.34 can also sign with **SSH keys**: `git config gpg.format ssh; git config user.signingkey ~/.ssh/id_ed25519.pub` (verification needs `gpg.ssh.allowedSignersFile`). GitHub shows a "Verified" badge for uploaded GPG/SSH signing keys. (SSH signing untested here: needs `ssh-keygen`.)

### 4.7 Searching
**`git grep`**: search tracked files in the working tree, **or any commit/tree**, fast, without checking it out.
| Option | Purpose |
|--------|---------|
| `-n` | line numbers |
| `--count` (`-c`) | matches per file |
| `-p` | show the enclosing function/method |
| `--and -e A -e B` | both patterns on the same line |
| `--break --heading` | group output by file |
| `-i`, `-w`, `-E`/`-P` | case-insensitive, whole word, regex |
| `git grep pat v1.0` / `HEAD~3` | search a past revision |
| `git grep --untracked`, `--no-index` | include untracked / non-repo dirs |
Why use it over `grep -r`: ignores `.git`, build junk, searches history objects, faster in big repos.

**`git log` searching** (history, not just current state):
| Option | Finds |
|--------|-------|
| `--grep=text` | commit **messages** (also `--author`, `--since`) |
| `-S"string"` (pickaxe) | commits that **changed the number of occurrences** of a literal string |
| `-G"regex"` | commits whose **diff lines** match the regex (use when the count doesn't change, e.g. a value edit) |
| `-L start,end:file` / `-L :funcname:file` | **line-log**: every commit that touched those lines/function, showing the diffs (follows the function across moves) |
| `--diff-filter=A/D/M/R` | commits that Added/Deleted/Modified/Renamed files |
| `-- path` | limit to paths |
Remember: `-S` vs `-G`: changing `ZLIB_BUF 1024` to `2048` leaves the *count* of "ZLIB_BUF" unchanged, so `-S ZLIB_BUF` skips it, while `-G"ZLIB_BUF 2048"` finds it.
`git blame` (later, [09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md)) answers "who last changed this line".

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git rev-parse <name>` | Resolve a name to a SHA | Learn/verify syntax |
| `git show HEAD~3:path` | File at a past commit | Compare/restore old version |
| `git reflog` / `git log -g` | Local movement history | Recover lost commits |
| `git log A..B` / `A...B` / `--left-right` | Range queries | Review, what's unpushed |
| `git add -p` / `-i` / `-N` | Selective staging | Clean logical commits |
| `git restore -p` / `git reset -p` | Discard/unstage hunks | Fine control |
| `git stash push -m [-u/-k/-p/-S]` | Park work | Context switch |
| `git stash list/show/apply/pop/drop/branch` | Manage stashes | |
| `git clean -n` → `-fd[x]` | Remove untracked | Reset build state |
| `git tag -s` / `git tag -v` | Signed tags | Releases |
| `git commit -S` / `commit.gpgsign` | Signed commits | Verified authorship |
| `git log --show-signature` / `%G?` | Inspect signatures | Audits |
| `git merge --verify-signatures` | Enforce signatures | Strict projects |
| `git grep -n/-p/--and` | Search code | Finding usage |
| `git log -S/-G/-L/--grep` | Search history | "When did this change?" |

## 6. Hands-on labs
Setup (sandboxed identity; skip the `export` if yours is set globally):
```bash
mkdir -p ~/git-labs/07 && cd ~/git-labs/07
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
```

### Lab 1 · Naming commits and ranges
```bash
git init rev && cd rev
for i in 1 2 3 4 5; do echo "line $i" >> f.txt; git add .; git commit -m "commit $i"; done
git rev-parse HEAD                       # 40-char SHA
git rev-parse --short=10 HEAD
git log --abbrev-commit --pretty=oneline -3
git show HEAD~2 -s --oneline             # commit 3
git show HEAD~2:f.txt                    # file content at commit 3 (3 lines)
git show :/"commit 2" -s --oneline       # youngest commit whose message matches
git switch -c side HEAD~2                # branch off at commit 3
echo s1 > s1.txt && git add . && git commit -m "side 1"
echo s2 > s2.txt && git add . && git commit -m "side 2"
git switch main
git log --oneline main..side             # side 2, side 1   (what side has that main lacks)
git log --oneline side..main             # commit 5, commit 4
git log --oneline --left-right main...side
git log --oneline main side --not main~3 | wc -l      # 5: commits 3,4,5,side 1,side 2
```
Now merge and walk parents:
```bash
git merge side -m "Merge side"
git show HEAD^  -s --oneline             # first parent  → commit 5
git show HEAD^2 -s --oneline             # second parent → side 2
git show HEAD~2 -s --oneline             # first-parent chain → commit 4
git show HEAD^2~1 -s --oneline           # side 1
git rev-parse HEAD^{tree} HEAD^{commit}
```
**Expected:** `main..side` lists 2 commits, `side..main` lists 2, `--left-right` shows `<` for commit 4/5 and `>` for side 1/2. `HEAD^2` is "side 2", `HEAD^2~1` is "side 1". (Hashes differ for you.)

### Lab 2 · Reflog rescue
```bash
git reset --hard HEAD~3                  # "lose" commits (dangerous on real work)
git log --oneline                        # they're gone from the log
git reflog | head -5                     # ...but listed here
git reset --hard HEAD@{1}                # return to where HEAD was one move ago
git log --oneline | head -3
git log -g --oneline main | head -3      # reflog of the main branch itself
# A deleted, UNMERGED branch:
git switch -c scratch && echo x > x.txt && git add . && git commit -m "scratch work" && git switch main
git branch -D scratch                    # prints: Deleted branch scratch (was <sha>)
git reflog | head -4                     # the "scratch work" commit is still listed
git branch scratch-restored <sha>        # use the sha printed above (or from the reflog)
git log --oneline scratch-restored -1
```
**Expected:** after the hard reset you can restore the merge commit exactly; the deleted branch comes back with `git branch <name> <sha>`. `main@{1.hour.ago}` may warn "log only goes back to …" in a fresh repo; that's normal.

### Lab 3 · Interactive staging (do this one by hand)
```bash
cd .. && git init stage && cd stage
seq 1 40 > n.txt && echo "# notes" > NOTES.md && git add . && git commit -m "init"
sed -i 's/^3$/THREE/; s/^37$/THIRTY-SEVEN/' n.txt     # two far-apart changes → two hunks
echo "another line" >> NOTES.md
echo "brand new" > new.txt
git status -s
git add -N new.txt                       # intent-to-add so -p can see it
git add -p n.txt                         # hunk 1 (THREE): y   hunk 2 (THIRTY-SEVEN): n   (also try 's', '?', 'e')
git diff --staged                        # only THREE staged
git diff                                 # the rest unstaged
git commit -m "Change line 3"
git add -p n.txt                         # now the THIRTY-SEVEN hunk: y
git commit -m "Change line 37"
git add -p NOTES.md new.txt              # stage the rest by hunk, commit separately
git commit -m "Notes and new file"
git log --oneline --stat
```
Try the menu too: `git add -i` → `5` (patch) → pick a file → hunks; `6` diff; `7` quit. Then unstage a hunk with `git reset -p` and discard one with `git restore -p`.
**Expected:** 4 commits total (init + 3), each with one logical change; `git diff --staged` before the first commit shows only the "THREE" edit. (When you give `git add -p` several files, hunks are offered in filename order, uppercase before lowercase, so naming the file keeps the prompts predictable.)

### Lab 4 · Stash in depth
```bash
cd .. && git init stash && cd stash
printf 'int main(){\n return 0;\n}\n' > main.c; echo "# x" > README.md
printf '*.o\n' > .gitignore; git add . && git commit -m "init"
echo "// wip" >> main.c; echo "staged edit" >> README.md; git add README.md
echo "more wip" >> main.c; echo scratch > u.txt; echo obj > a.o     # unstaged, untracked, ignored
git stash push -m "feature wip"
git status -s                            # only u.txt (untracked) remains; a.o is ignored
git stash list
git stash show -p                        # patch
git stash apply                          # NOTE: README is back as unstaged
git status -s
git restore . && git stash apply --index # --index restores staged vs unstaged exactly
git status -s
git restore --staged . && git restore . && git stash drop
git stash push -u -m "with untracked"    # u.txt stashed too
git status -s                            # clean
git stash pop
echo a >> main.c && git stash push -m a  # two stashes, each from a change
echo b >> main.c && git stash push -m b
git stash list                           # stash@{0}: b   stash@{1}: a
git stash branch rescue stash@{0}        # new branch from the stash's base commit
```
**Expected:** after `apply` without `--index`, README is ` M` (unstaged); with `--index` it's `M ` again. `-u` removes `u.txt` from the tree until popped. `stash branch` leaves you on `rescue` with the changes applied.
Extras: `git stash push -k` (keep staged changes to test only them), `git stash push -p`, `git stash push -S`, `git stash clear`.

### Lab 5 · Clean
```bash
cd ~/git-labs/07 && git init clean && cd clean
echo '*.o' > .gitignore && git add . && git commit -m "init"
mkdir sub; touch sub/x.log junk.txt a.o
git clean -n                              # Would remove junk.txt   (dir and ignored files not listed)
git clean -d -n                           # + sub/
git clean -x -d -n                        # + ignored a.o
git clean -f                              # only junk.txt removed
git clean -fd; git clean -fdx; ls -A
```
**Expected:** each `-n` shows progressively more; `git clean` without `-f` refuses to delete (config `clean.requireForce`). Always dry-run first.

### Lab 6 · Signing with GPG (tested; uses a throwaway keyring)
```bash
cd ~/git-labs/07 && git init sign && cd sign
export GNUPGHOME="$PWD/../gnupg"; mkdir -m700 "$GNUPGHOME"      # isolated keyring for the lab
cat > ../gpg.batch <<'EOF'
%no-protection
Key-Type: eddsa
Key-Curve: ed25519
Name-Real: Jane Doe
Name-Email: jane@example.com
Expire-Date: 0
%commit
EOF
gpg --batch --quiet --gen-key ../gpg.batch
gpg --list-keys --keyid-format long
KEY=$(gpg --list-secret-keys --with-colons | awk -F: '/^sec/{print $5; exit}')
git config user.signingkey "$KEY"
echo hi > a && git add . && git commit -m "init"
git tag -s v1.0 -m "signed release"
git tag -v v1.0                           # gpg: Good signature from "Jane Doe <jane@example.com>"
echo more >> a && git commit -a -S -m "signed commit"
git log --show-signature -1
git log --pretty="%h %G? %GS" -2          # G for the signed commit, N for the unsigned one
git verify-commit HEAD
```
**Expected:** "Good signature", `%G?` = `G` then `N`. (A real key should have a passphrase and an expiry; `%no-protection` is for the lab only.) 
Optional: `git config commit.gpgsign true` and commit normally; try `git merge --verify-signatures` of a branch with an unsigned commit (it refuses).
Cleanup: `unset GNUPGHOME`.

### Lab 7 · Searching code and history
```bash
cd ~/git-labs/07 && git init search && cd search
cat > zlib.c <<'EOF'
#include <stdio.h>
#define ZLIB_BUF 1024
int gmtime_r_test(int x) { return x; }
int main(void) {
  int a = 1;
  return gmtime_r_test(a);
}
EOF
git add . && git commit -m "add zlib.c"
sed -i 's/ZLIB_BUF 1024/ZLIB_BUF 2048/' zlib.c && git commit -am "grow buffer"
sed -i 's/int a = 1;/int a = 2;/' zlib.c && git commit -am "tweak main"
sed -i 's/return x;/return x + 1;/' zlib.c && git commit -am "fix gmtime_r_test"

git grep -n gmtime_r_test                 # lines with numbers
git grep --count gmtime_r_test
git grep -p gmtime_r_test zlib.c          # shows enclosing function name (the "=" line)
git grep -e ZLIB_BUF --and -e 2048
git grep -n ZLIB_BUF HEAD~2               # search an old commit
git log -S ZLIB_BUF --oneline             # only "add zlib.c" (count went 0→1; the edit kept the count)
git log -G"ZLIB_BUF 2048" --oneline       # "grow buffer" (diff line matches)
git log -L :gmtime_r_test:zlib.c --oneline   # history of the function, with diffs
git log -L 5,5:zlib.c --oneline -s
git log --grep="tweak" --oneline
git log --diff-filter=A --name-only --oneline
```
**Expected:** `-S` shows one commit, `-G` another: that difference is the point. `-L :func:file` prints the commit that changed the function (and the one that added it).

## 7. Practice challenges
1. In a repo with a merge, write one command each to show: the first parent, the second parent, the grandparent through the second parent, and the tree of HEAD.
2. List commits that are in `main` but not yet in `origin/main`, and the reverse, in one command with markers.
3. You accidentally ran `git reset --hard` and lost 3 commits and one deleted branch. Recover both using only the reflog.
4. Given a file with 3 separate edits (A, B, C), make 3 commits (one per edit) without editing the file between commits.
5. Stash only the *unstaged* changes while keeping the staged ones in the tree, run tests (`echo ok`), then restore.
6. Use `git stash` + `git stash branch` to turn a half-done change into a proper feature branch.
7. Find the commit that removed the string `DEBUG_MODE` from the repo history, then the commit that introduced the function `parse_args`.
8. Make `commit.gpgsign` true locally, create an unsigned commit on a branch (`-c commit.gpgsign=false`), and show that `git merge --verify-signatures` refuses it.

<details><summary>Solutions</summary>

1. `git rev-parse HEAD^`, `HEAD^2`, `HEAD^2^`, `HEAD^{tree}`.
2. `git log --left-right --oneline main...origin/main` (`<` = local only, `>` = remote only).
3. `git reflog`; `git reset --hard HEAD@{n}`; for the branch `git branch name <sha>`.
4. `git add -p`, choose hunk A only; commit; repeat for B and C. Use `s`/`e` if hunks are adjacent.
5. `git stash push --keep-index` → test → `git stash pop` (note: staged changes are duplicated in the stash; or `git stash push -k` then `git stash pop` and resolve).
6. `git stash push -m wip; git stash branch feature/x`.
7. `git log -S"DEBUG_MODE" --oneline` (the earliest listed is introduction, the latest removal; confirm with `--diff-filter`/`-p`); `git log -S"parse_args" --oneline | tail -1` or `git log -L :parse_args:file`.
8. `git merge --verify-signatures topic` → "fatal: Commit … does not have a GPG signature."
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| `HEAD~2` vs `HEAD^2` confusion | `~` = n generations back along first parents; `^n` = pick n-th parent of a merge |
| Short SHA ambiguous | Use more characters or `git rev-parse` to check |
| `main@{yesterday}` "warning: log only goes back" | The reflog is local and young; normal |
| Reflog entry expired / `gc` ran | Not recoverable via reflog; try `git fsck --lost-found` ([13-git-internals-plumbing-and-objects.md](13-git-internals-plumbing-and-objects.md)) |
| `git add -p` ignores new files | `git add -N file` first (or `git add` the file normally) |
| Hunk too big for `y/n` | `s` to split; `e` to edit |
| Staged changes "vanished" after `stash apply` | Use `--index` |
| `stash apply` conflicts | Resolve like a merge, or `git stash branch` |
| Forgot what a stash contains | `git stash show -p stash@{n}`; name stashes with `-m` |
| Untracked files not stashed | `-u`; ignored too with `-a` |
| `git clean -fdx` deleted something precious (`.env`!) | Not recoverable; always `-n` first; keep secrets out of the tree or use `git clean -e pattern` |
| `gpg failed to sign the data` | `export GPG_TTY=$(tty)`; check `user.signingkey`, agent running |
| `%G?` shows `E`/`U` | Public key missing / untrusted: import key, set trust |
| `git log -S` seems to miss an edit | The count didn't change: use `-G` |

## 9. Real-world use cases
- **Code review hygiene:** split a messy afternoon into reviewable commits with `git add -p`.
- **Context switching:** stash while handling an incident; `git stash branch` to rescue half-built work.
- **Incident forensics:** `git log -S/-G/-L` to find when a config line, secret or function changed; `git grep` on the release tag to see what shipped.
- **Compliance/supply chain:** signed tags for releases; `--verify-signatures` in release pipelines; "Verified" badges.
- **Undo safety:** reflog saves you from `reset --hard` and botched rebases (see [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md)).

## 10. Self-check quiz
1. What does `HEAD~3^2` mean?
2. What does `git log A...B` show, and what does `--left-right` add?
3. Why can't a teammate use your `HEAD@{3}`?
4. How do you stage only part of a file?
5. Does `git stash` include untracked files? How do you change that?
6. What's the difference between `git stash apply` and `git stash pop`?
7. When does `-S` miss a change that `-G` finds?
8. What does `git clean -n` do, and why use it first?
9. What does `%G?` = `U` mean?

<details><summary>Answers</summary>

1. Go three first-parent steps back from HEAD, then take that commit's second parent.
2. Commits reachable from either but not both; `--left-right` marks which side (`<` left, `>` right).
3. The reflog is local to your repository.
4. `git add -p` (choose hunks; `s` split, `e` edit).
5. No by default; use `-u` (or `-a` for ignored too).
6. `apply` keeps the stash; `pop` applies and drops it.
7. When the number of occurrences of the string stays the same (e.g. a value changed on the same line).
8. Dry run: lists files that would be deleted; deletion is irreversible.
9. Good signature but the key isn't trusted/validated in your keyring.
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Resolve any of `~`, `^`, `@{}`, `:/`, `rev:path`, ranges and say which commits they select.
- [ ] Recover from `reset --hard` via the reflog.
- [ ] Turn a messy working tree into 3 clean commits with `add -p`.
- [ ] Stash with/without untracked and index; branch from a stash.
- [ ] Create and verify signed tags/commits.
- [ ] Choose between `grep`, `-S`, `-G`, `-L`, `--grep` for a given question.

**Next:** [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md): amend, interactive rebase, filter-branch, and the reset/checkout mechanics demystified.
