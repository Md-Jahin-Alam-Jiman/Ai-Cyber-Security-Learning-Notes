# 09 · Git Tools III: Advanced Merging, Rerere, and Debugging
> Book reference: Pro Git, Chapter 7 "Git Tools", sections "Advanced Merging", "Rerere", "Debugging with Git" (book pp. 271–303)
> Level: Advanced · Est. time: 4 h

## 1. Why this matters
Merge conflicts are where most people lose confidence in Git. With the right tools (stage numbers, diff3 markers, combined diffs, `rerere`) a conflict is a mechanical puzzle, not a panic. And when something breaks and nobody knows when, `blame` and `bisect` find the culprit commit in minutes instead of days (bisect needs only about log₂(N) tests).

## 2. Prerequisites
- [03-git-branching-and-merging.md](03-git-branching-and-merging.md): merge basics, conflicts, markers.
- [07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md): ranges, `git log -L`, `-S`.
- [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md): `reset --hard`, `revert`.

## 3. Learning objectives
- [ ] Prepare for a merge and abort one safely.
- [ ] Ignore whitespace differences during a merge.
- [ ] Inspect a conflict through index stages 1/2/3, `diff3` markers, `git diff --ours/--theirs/--base`, `git log --merge`, combined diffs.
- [ ] Re-create a conflict (`checkout --merge`), re-merge a file by hand (`git merge-file`).
- [ ] Choose `-Xours/-Xtheirs` vs `-s ours`; do a subtree merge.
- [ ] Undo a merge via `reset` or `revert -m 1`, and explain the "re-merge" trap.
- [ ] Enable and use `rerere`.
- [ ] Use `git blame` (-L, -w, -M, -C, `--ignore-rev`) and `git bisect` (manual and `run`).

## 4. Core concepts

### 4.1 Preparing for a merge
- Start from a **clean working tree** (`git status`). If merge-time conflicts mix with uncommitted edits you can't cleanly back out.
- Park work first: `git stash`, a throwaway branch, or a temporary `WIP` commit (undo later with `git reset --soft HEAD~1`).
- Escape hatches during a conflicted merge:
  - `git merge --abort` (tries to return to the pre-merge state; fails to restore uncommitted pre-merge edits, which is why you start clean).
  - `git reset --hard HEAD` (nuclear; discards all uncommitted work).

### 4.2 Ignoring whitespace in merges
When one branch reindents or changes line endings, *every* line conflicts. Tell the merge to ignore it:
| Option | Ignores |
|--------|---------|
| `-Xignore-all-space` | all whitespace when comparing lines |
| `-Xignore-space-change` | changes in amount of whitespace (incl. trailing, CR) |
| `-Xignore-space-at-eol` | whitespace at end of line |
| `-Xignore-cr-at-eol` | a trailing carriage return |
Usage: `git merge -Xignore-space-change topic`. If a side changed whitespace *and* real content on the same line, Git still conflicts. Also try `-Xpatience` / `-Xhistogram` for a different diff algorithm when automatic merges look wrong.

### 4.3 Dissecting a conflict
A conflicted file is stored in the index in **three stages** instead of one:
| Stage | Contents | Access |
|-------|----------|--------|
| 1 | **base** (common ancestor) | `git show :1:file` |
| 2 | **ours** (current branch, `HEAD`) | `git show :2:file` |
| 3 | **theirs** (branch being merged) | `git show :3:file` |
`git ls-files -u` lists them; `git status` shows `UU` (both modified), `AA` (both added), `DU`/`UD` (deleted by one side).

**Conflict-marker styles**
- Default: `<<<<<<< HEAD` ours `=======` theirs `>>>>>>> branch`.
- **diff3** adds the base between `|||||||` and `=======`; you see *what each side changed* instead of two finished versions, making resolution far easier: `git config --global merge.conflictstyle diff3` (💡 `zdiff3`, Git ≥ 2.35, trims common lines). Re-render a file already in conflict: `git checkout --conflict=diff3 file` (or `--conflict=merge` for the default). `git checkout --merge file` re-creates the conflict if you botched your edits ("Recreated 1 merge conflict").

**Picking a side for a file:** `git checkout --ours file` / `--theirs file` (💡 `git restore --ours/--theirs file`), then `git add file`.
**Manual file re-merging:** `git merge-file [-p] --diff3 ours base theirs` merges three files you extracted from the stages; useful with a pre-processing step (e.g., normalize line endings with `dos2unix` first), then `git add`.

**Understanding what's conflicting**
```bash
git log --oneline --left-right HEAD...MERGE_HEAD   # commits on each side not on the other (< ours  > theirs)
git log --merge -p                                  # only commits that touch conflicted files, with patches
git diff --ours   |  --theirs  |  --base            # working file vs stage 2 / 3 / 1
git diff                                            # combined diff (see below)
```
**Combined diff format** (`diff --cc`) is what `git diff` prints during a conflict and what `git show` prints for a merge commit. Two columns before each line: left column = difference vs. **first parent** (ours), right = vs. **second parent** (theirs). `+` in a column means the line was added relative to that parent, `-` removed. `git show <merge>` shows only what the *merge itself* changed beyond what either parent had (`--cc`, hiding trivial lines), `-m` splits into one diff per parent, `git diff HEAD^1 HEAD` is "what the merge changed relative to my side".

After resolving: `git add file`, `git commit`. Verify with `git show` / `git diff HEAD^1`. Leftover `*.orig`/`.rej` files? `git clean -n` then `-f`.

### 4.4 Undoing merges
| Situation | Do | Result |
|-----------|----|--------|
| Merge is **local/unpushed** | `git reset --hard HEAD~1` (or `ORIG_HEAD`) | History rewritten; merge disappears |
| Merge is **pushed/shared** | `git revert -m 1 <merge>` | New commit that undoes the merge's *changes* relative to parent 1 (`-m 1` = "mainline is parent 1") |
**The re-merge trap:** after `revert -m 1`, Git still records the branch commits as merged. Merging the branch again brings in *only commits added after the first merge*; the originally reverted changes stay out. Fix: first **revert the revert** (`git revert <revert-commit>`; modern Git titles it `Reapply "…"`), then merge again. (Book alternative: after fixing the topic, merge it again and you get fixed code only for new changes.)

### 4.5 Other kinds of merges
- **`-Xours` / `-Xtheirs`** (strategy *options*): still merge normally, but where there is a **conflict**, auto-pick that side's lines. Non-conflicting changes from both sides are kept.
- **`-s ours`** (a **strategy**): create a merge commit that records the other branch as merged but **keeps your tree exactly as is**: "pretend I merged it". Used to mark an abandoned branch as merged, or to avoid re-merging old work.
- **Subtree merging**: nest another project under a subdirectory of yours (e.g. `rack/`) while still pulling its updates, without submodules ([10-git-tools-submodules-bundling-replace-and-credentials.md](10-git-tools-submodules-bundling-replace-and-credentials.md) covers the alternative).
  💡 **Modern recipe** (Git ≥ 2.9 refuses unrelated histories unless you say so):
```bash
git remote add rack_remote <url>; git fetch rack_remote
git branch rack_branch rack_remote/main
git merge -s ours --no-commit --allow-unrelated-histories rack_branch   # join the histories
git read-tree --prefix=rack/ -u rack_branch                              # put its tree under rack/
git commit -m "Add rack as subtree"
# later updates:
git fetch rack_remote; git branch -f rack_branch rack_remote/main
git merge -s subtree rack_branch            # or: git merge -Xsubtree=rack rack_remote/main
```
  `-s subtree` works out the prefix automatically; `-Xsubtree=<prefix>` states it. The `git subtree add/pull/push --prefix=rack <url> <ref> [--squash]` contrib command wraps all this (installed with most Git packages). `git diff-tree -p rack_branch` compares your subtree with upstream.

### 4.6 Rerere: "reuse recorded resolution"
When you resolve a conflict, `rerere` remembers *the conflict (preimage) and your resolution (postimage)*; next time it sees the **same conflict**, it resolves automatically. It pays off for long-lived topic branches that are merged/rebased repeatedly, for rebuilding integration branches, and for "merge, test, throw away, merge again" workflows.
```bash
git config --global rerere.enabled true       # or: mkdir .git/rr-cache
git merge topic            # CONFLICT … "Recorded preimage for 'f'"
# resolve, git add, git commit   → "Recorded resolution for 'f'."
git reset --hard HEAD~1; git merge topic      # "Resolved 'f' using previous resolution."
git add f                                      # you still stage the file yourself (and review it!)
```
Commands: `git rerere status` (files being tracked), `git rerere diff` (current state of the resolution), `git rerere remaining`, `git rerere forget <path>` (discard a wrong recorded resolution), `git rerere gc`. The cache lives in `.git/rr-cache/` (local; not shared). Works for `merge`, `rebase`, `cherry-pick`, `checkout -m`.

### 4.7 Debugging with Git: `blame`
`git blame file` annotates each line with the commit, author and date that **last changed it**.
| Option | Purpose |
|--------|---------|
| `-L 69,82` / `-L '/regex/,+10'` / `-L :funcname` | restrict to lines / a regex range / a function |
| `-w` | ignore whitespace changes |
| `-e` | show author emails |
| `-s` | suppress author and date |
| `-M[<num>]` | detect lines **moved within the file** (≥ `num` alphanumeric chars, default 20) |
| `-C[<num>]` | detect lines **copied/moved from other files in the same commit** (default 40 chars); `-C -C` also looks in the commit that created the file; `-C -C -C` any commit |
| `--ignore-rev <commit>` / `--ignore-revs-file` | skip mass-reformat commits (💡 `git config blame.ignoreRevsFile .git-blame-ignore-revs`; GitHub honours that filename) |
| `<rev> -- file` | blame as of an older revision (a `^` prefix on the hash means "boundary: introduced by the first commit of the range") |
Workflow: find a suspicious line → `git blame` → `git show <commit>` for the *why* → `git blame <commit>^ -- file` to dig deeper. Blame says who last touched the line, not necessarily who wrote it. `-M`/`-C` often show the true origin after refactors.

### 4.8 Debugging with Git: `bisect`
Binary search through history for the commit that introduced a bug. Needs a known **good** commit and a **bad** one; Git checks out the midpoint, you test and mark it, repeat: ~log₂(N) steps.
```bash
git bisect start                 # begin (or: git bisect start <bad> <good>)
git bisect bad                   # current commit is broken
git bisect good v1.0             # this one worked
# Git checks out a midpoint; test it, then:
git bisect good | bad | skip     # skip = can't test this commit
git bisect log                   # what you've told Git so far
git bisect visualize             # see the remaining range (gitk/log)
git bisect reset                 # finish; return to where you started
```
**Automate**: `git bisect run <command>`; exit code **0 = good**, **1–127 except 125 = bad**, **125 = skip**, ≥128 aborts. Example: `git bisect start HEAD v1 && git bisect run sh -c '! grep -q broken status.txt'` (or `make test`, `pytest -x`, `./check.sh`). Put the test script *outside* the repo or untracked, because checkouts replace files.
Custom terms (Git ≥ 2.7): `git bisect start --term-old=fast --term-new=slow`, then `git bisect fast` / `git bisect slow` (e.g. for performance regressions). When it finishes: "`<hash>` is the first bad commit".
Tips: keep commits small and buildable (see `rebase -x` in [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md)); a merge-heavy history still bisects.

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git merge --abort` | Cancel merge | Conflicts too messy |
| `git merge -Xignore-space-change b` | Merge ignoring whitespace | Reindent/line-ending conflicts |
| `git ls-files -u` / `git show :1/2/3:f` | List/read conflict stages | Understand a conflict |
| `git checkout --conflict=diff3 f` | Show base in markers | Hard conflicts |
| `git checkout --merge f` | Re-create conflict | Messed up resolution |
| `git checkout --ours/--theirs f` | Take one side | Whole-file decisions |
| `git merge-file -p ours base theirs` | 3-way merge files | Custom pre-processing |
| `git log --merge -p` / `--left-right HEAD...MERGE_HEAD` | Context for the conflict | Who changed what |
| `git diff --ours/--theirs/--base` | Compare to a stage | Check resolution |
| `git show <merge>` (`--cc`) | Combined diff | Review a merge |
| `git revert -m 1 <merge>` | Undo a pushed merge | Shared history |
| `git merge -Xours/-Xtheirs b` | Auto-pick side on conflict | Bulk resolution |
| `git merge -s ours b` | Mark as merged, keep tree | Retire a branch |
| `git merge -s subtree` / `git subtree` | Nested project | Vendoring |
| `git config rerere.enabled true`; `git rerere status/diff/forget` | Remember resolutions | Repeated merges |
| `git blame -L -w -M -C` | Line origins | "Who/why changed this?" |
| `git bisect start/good/bad/skip/run/reset` | Find the bad commit | Regressions |

## 6. Hands-on labs
Setup:
```bash
mkdir -p ~/git-labs/09 && cd ~/git-labs/09
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
```

### Lab 1 · Whitespace and line-ending conflicts
```bash
git init ws && cd ws
printf '#!/usr/bin/env ruby\n\ndef hello\n  puts "hello world"\nend\n\nhello\n' > hello.rb
git add . && git commit -m "init"
git switch -c whitespace
sed -i 's/$/\r/' hello.rb && git commit -am "convert to CRLF"        # macOS: sed -i '' $'s/$/\r/' hello.rb
git switch main
sed -i 's/hello world/hola world/' hello.rb && git commit -am "main: hola"
git merge whitespace            # CONFLICT: every line differs
git merge --abort
git status -s                   # (empty: clean again)
git merge -Xignore-space-change whitespace     # merges cleanly
git log --oneline -1
git reset --hard HEAD~1         # undo for the next lab
```
**Expected:** the plain merge conflicts; with `-Xignore-space-change` it succeeds ("Merge made by the 'ort' strategy").

### Lab 2 · Anatomy of a real conflict
```bash
git switch -c mundo main~1
sed -i 's/hello world/hello mundo/' hello.rb && git commit -am "mundo"
git switch main
git merge mundo                                 # CONFLICT
git status -s                                   # UU hello.rb
git ls-files -u                                 # three entries: stages 1, 2, 3
git show :1:hello.rb | sed -n 4p                # base:   puts "hello world"
git show :2:hello.rb | sed -n 4p                # ours:   puts "hola world"
git show :3:hello.rb | sed -n 4p                # theirs: puts "hello mundo"
git checkout --conflict=diff3 hello.rb          # re-render with the base included
sed -n 3,12p hello.rb
git log --oneline --left-right HEAD...MERGE_HEAD
git log --oneline --merge -p | head
git diff --stat                                 # combined diff header (diff --cc)
git diff | head -14
```
Resolve by hand (e.g. `puts "hola mundo"`) or, as a shortcut for this lab:
```bash
git checkout --merge hello.rb                   # "Recreated 1 merge conflict" (undo the diff3 render)
git checkout --ours hello.rb
sed -i 's/hola world/hola mundo/' hello.rb
git add hello.rb && git commit -m "Merge mundo"
git show --stat --oneline HEAD                  # merge commit; combined diff shows only the resolution
git diff HEAD^1 HEAD --stat                     # what the merge changed relative to main
```
**Expected:** three stage entries, diff3 markers `<<<<<<< ours / ||||||| base / ======= / >>>>>>> theirs`, and a `--cc` diff with two columns. Try `git config merge.conflictstyle diff3` and re-run the merge to see base markers by default.

### Lab 3 · `-Xours`, `-Xtheirs`, and `-s ours`
```bash
cd .. && git init strat && cd strat
printf 'a\nb\nc\n' > f && git add . && git commit -m base
git switch -c topic && printf 'a\nTOPIC\nc\nd-topic\n' > f && git commit -am topic
git switch main && printf 'a\nMAIN\nc\n' > f && git commit -am main
git merge -Xours topic -m xours   && cat f | tr '\n' ' '; echo; git reset -q --hard HEAD~1
git merge -Xtheirs topic -m xt    && cat f | tr '\n' ' '; echo; git reset -q --hard HEAD~1
git merge -s ours topic -m fake   && cat f | tr '\n' ' '; echo
git log --oneline --graph | head -3
git diff HEAD~1 --stat | wc -l                  # 0 : the "merge" changed nothing
```
**Expected output lines:** `a MAIN c d-topic` (only the conflicting line took our side; the non-conflicting `d-topic` addition still merged), `a TOPIC c d-topic`, then `a MAIN c` for `-s ours` (topic is recorded as merged but contributes nothing).

### Lab 4 · Undoing merges: reset vs revert, and the re-merge trap
```bash
cd .. && git init undo && cd undo
echo base > f && git add . && git commit -m base
git switch -c feature && echo f1 > feat.txt && git add . && git commit -m "feature 1" && git switch main
echo m1 > main.txt && git add . && git commit -m "main 1"
git merge feature -m "Merge feature"
ls                                              # feat.txt main.txt f
git revert -m 1 --no-edit HEAD                  # safe undo for a shared branch
ls                                              # feat.txt gone
git switch feature && echo f2 > feat2.txt && git add . && git commit -m "feature 2" && git switch main
git merge feature -m "Merge feature again"
ls                                              # only feat2.txt came back; feat.txt did NOT (the trap)
```
**Fix the trap** (history is now: …, Merge feature, Revert "Merge feature", Merge feature again):
```bash
git reset --hard HEAD~1                         # drop the second merge; HEAD is the Revert commit again
git revert --no-edit HEAD                       # revert the revert (message: Reapply "Merge feature")
git merge feature -m "Merge feature (2nd try)"  # now brings feature 2 on top of the restored feature 1
ls                                              # feat.txt AND feat2.txt both present
git log --oneline | head -5
```
**Expected:** the plain re-merge restores only `feat2.txt`; after reverting the revert and merging again you have both. (The reset is safe here because the bad second merge was never pushed.)

### Lab 5 · Subtree merge
```bash
cd .. && git init rack_upstream && (cd rack_upstream && echo "rack v1" > rack.rb && git add . && git commit -m "rack init")
git init proj && cd proj && echo app > app.rb && git add . && git commit -m app
git remote add rack_remote ../rack_upstream && git fetch rack_remote
git branch rack_branch rack_remote/main
git merge -s ours --no-commit --allow-unrelated-histories rack_branch
git read-tree --prefix=rack/ -u rack_branch
git commit -m "Add rack as subtree"
git ls-files                                    # app.rb rack/rack.rb
git log --oneline --graph | head -4             # note: a merge joining two root histories
(cd ../rack_upstream && echo "rack v2" > rack.rb && git commit -am "rack v2")
git fetch rack_remote && git branch -f rack_branch rack_remote/main
git merge -s subtree rack_branch -m "Update rack subtree"
cat rack/rack.rb                                # rack v2
git diff-tree -p rack_branch | head -1          # shows the tree compare against upstream
```
Variation with the helper: `git subtree add --prefix=vendor/rack ../rack_upstream main --squash` and later `git subtree pull ...` (also tested; installed as `git-subtree`).
**Expected:** `rack/rack.rb` contains `rack v2` after the subtree merge, without any conflict.

### Lab 6 · Rerere
```bash
cd .. && git init rr && cd rr
git config rerere.enabled true
printf 'l1\nbase\nl3\n' > f && git add . && git commit -m base
git switch -c feat && echo feat > g && printf 'l1\nFEAT\nl3\n' > f && git add . && git commit -m feat
git switch main && printf 'l1\nMAIN\nl3\n' > f && git commit -am main
git merge feat                                  # CONFLICT … Recorded preimage for 'f'
git rerere status                               # f
printf 'l1\nRESOLVED\nl3\n' > f
git add f && git commit -m "Merge feat"         # Recorded resolution for 'f'.
git reset --hard HEAD~1                         # throw the merge away…
git merge feat                                  # CONFLICT … Resolved 'f' using previous resolution.
cat f                                           # l1 RESOLVED l3 (already applied)
git status -s                                   # UU f: still needs git add
git diff | head -5
git add f && git commit -m "Merge feat (again)"
git rerere forget f 2>&1 | head -1              # drop a bad recorded resolution if needed
ls .git/rr-cache
```
**Expected:** the second merge prints "Resolved 'f' using previous resolution" and the file already contains your resolution. Rerere resolves but you still `git add` after reviewing it.

### Lab 7 · Blame and its detective options
```bash
cd .. && git init bl && cd bl
S='def helper_function_name():
    return compute_the_answer()'
B='def very_long_function_name(items):
    subtotal = sum(item.price * item.quantity for item in items)
    tax = subtotal * 0.0825
    discount = lookup_discount(items)
    shipping = estimate_shipping(items)
    return round(subtotal + tax - discount + shipping, 2)'
printf '%s\n\n%s\n' "$S" "$B" > c.py && git add . && git commit -m "create c.py"
printf '%s\n\n%s\n' "$B" "$S" > c.py && git commit -am "reorder in c.py"
L=$(grep -n "def helper_function_name" c.py | cut -d: -f1)
git blame -L $L,$L c.py                          # blames "reorder in c.py"
git blame -M -L $L,$L c.py                       # detects the move: blames "create c.py" (^hash = root commit)
git blame -L :very_long_function_name c.py | head -3
git blame -w -e -L 1,1 c.py
# -C: code moved to another file in the same commit
printf 'import os\n\n%s\n' "$B" > a.py; printf 'x = 1\n' > b.py; git add . && git commit -m "add a.py and b.py"
printf 'import os\n' > a.py; printf 'x = 1\n\n%s\n' "$B" > b.py; git commit -am "move code a.py → b.py"
git blame -L 4,4 b.py                            # blames the move commit
git blame -C -L 4,4 b.py                         # follows it back to "add a.py and b.py"
# --ignore-rev: skip a formatting commit
sed -i 's/subtotal \* 0.0825/subtotal*0.0825/' b.py && git commit -am "reformat"
git blame -L 5,5 b.py                            # blames "reformat" (the `tax = …` line)
git blame --ignore-rev HEAD -L 5,5 b.py          # skips it: blames the earlier "move code a.py → b.py" commit
```
**Expected:** `-M` and `-C` both change the blamed commit/hash (a leading `^` means boundary/root commit). Detection needs minimum block sizes (20 / 40 alphanumeric characters), which is why the sample blocks are longer than a line or two.

### Lab 8 · Bisect, manual then automated
```bash
cd .. && git init bis && cd bis
for i in $(seq 1 12); do
  echo "ok $i" > status.txt
  [ $i -ge 7 ] && echo broken >> status.txt         # regression introduced at commit 7
  echo $i > n; git add .; git commit -qm "commit $i"
done
git tag v1 HEAD~11                                   # "known good" (commit 1)
git bisect start HEAD v1                             # bad = HEAD, good = v1
# Git checks out a midpoint. Test it yourself:
grep -q broken status.txt && echo BAD || echo GOOD
git bisect bad                                       # use `git bisect good` if your check printed GOOD
# …repeat (test, then mark good/bad) ~3-4 times until: "<hash> is the first bad commit"
git bisect log | tail -4
git bisect reset
# Automated:
git bisect start HEAD v1
git bisect run sh -c '! grep -q broken status.txt'   # exit 0 = good, 1 = bad
git bisect reset
git status -sb | head -1                             # back on main
```
**Expected:** it identifies `commit 7` as the first bad commit in 3–4 steps among 12. Try a script that exits **125** for commits it cannot build (skip), and `git bisect start --term-old=fast --term-new=slow HEAD HEAD~5` for custom terms.

### Lab 9 · Mini investigation (apply it all)
Use the `bis` repo: (1) use bisect to find the bad commit, (2) `git show` it, (3) `git blame -L 2,2 status.txt` to confirm who/what introduced `broken`, (4) fix it with a new commit and verify with `git bisect` on `HEAD` as good. Write 3 lines on what you learned.

## 7. Practice challenges
1. Create a conflict where both branches *add* the same filename with different content (`AA`). Resolve by taking each side's version into two differently named files.
2. Produce a modify/delete conflict (`DU`/`UD`). Resolve once by keeping the file and once by deleting it.
3. Merge a branch that reformatted a whole file (indentation) while you changed logic. Do it with and without `-Xignore-space-change` and compare the results.
4. Use `git checkout --conflict=diff3` and `git show :1:/:2:/:3:` to resolve a conflict *without opening the conflict markers*: build the final file with `git merge-file`.
5. Merge the same two branches three times (merge, reset, merge, reset, merge) and show that only the first needs manual work (rerere).
6. Revert a merge, add a commit on the branch, merge again, observe the missing files, then fix it properly.
7. In a 30-commit repo where a test starts failing at an unknown commit, find it with `bisect run` using a real test command, and with a deliberately-unbuildable commit in the middle (exit 125).
8. Make a repo where a function was moved between files, and find the *original* author of a line with `git blame -C -C`.

<details><summary>Solutions</summary>

1. `git ls-files -u` shows stages 2 and 3 only (no base). `git show :2:f > f_ours; git show :3:f > f_theirs; git rm -f f; git add f_ours f_theirs; git commit`.
2. Keep: `git add f`; delete: `git rm f`; then commit.
3. Without the option every line conflicts (CRLF/indent); with it the merge succeeds and your logic change survives.
4. `git show :1:f > base; git show :2:f > ours; git show :3:f > theirs; git merge-file -p --diff3 ours base theirs > f` (inspect the conflict markers, edit, `git add f`). If no conflicts arise, you're done.
5. Enable rerere before the first merge; subsequent merges print "Resolved '…' using previous resolution".
6. Lab 4: `git revert <the revert commit>` before merging again.
7. `git bisect start HEAD <good>; git bisect run ./test.sh` where the script exits 125 if the build fails.
8. `git blame -C -C -L start,end file`.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Started merging with a dirty tree and `--abort` can't restore | `git stash` first next time; recover via `git reflog`/`ORIG_HEAD` |
| Committed conflict markers | Search for `<<<<<<<`; use a hook ([11-customizing-git-config-attributes-and-hooks.md](11-customizing-git-config-attributes-and-hooks.md)) or CI check |
| Took `--ours`/`--theirs` for the whole file and lost the other side's good changes | `git checkout --merge file` to re-create the conflict and redo carefully |
| Confused `ours`/`theirs` in a **rebase** | They are swapped: *ours* is the branch being rebased onto, *theirs* is your commit being replayed |
| `-Xtheirs` silently overwrote something important | Review `git diff HEAD^1 HEAD` after every `-X` merge; use sparingly |
| `-s ours` used when `-Xours` was intended | `-s ours` ignores the other branch's changes entirely; reset and redo |
| Re-merged a reverted merge and changes are missing | Revert the revert first (§4.4) |
| `rerere` applied a *wrong* recorded resolution | `git rerere forget <path>`, re-resolve |
| `blame` blames a reformat/rename commit | `-w`, `-M`, `-C`, `--ignore-rev`, or `git log -L`/`-S` |
| `bisect` marks wrong commits because test is flaky/doesn't compile | `git bisect skip`/exit 125; make the test deterministic; `git bisect log` + `replay` to redo |
| Left in bisect state | `git bisect reset` (check `git status -sb` for `HEAD detached`) |

## 9. Real-world use cases
- **Release merges:** long-lived `release` and `main` branches with repeating conflicts; `rerere` makes each re-merge painless.
- **Large refactors:** reformat commits + `blame --ignore-revs-file` keep history useful.
- **Production regression:** "it worked in v2.3": `git bisect run ./smoke-test.sh` pinpoints the commit overnight in CI.
- **Vendoring libraries:** subtree merging, so consumers clone one repo with no submodule steps.
- **Reviewing merges:** `git show --cc <merge>` to check that conflict resolutions are sane; `git revert -m 1` to roll back a bad release merge on a shared branch.

## 10. Self-check quiz
1. What are index stages 1, 2 and 3 in a conflict?
2. What does `diff3` add to conflict markers and why does it help?
3. Difference between `-Xours` and `-s ours`?
4. How do you undo a *pushed* merge, and what's the trap when merging that branch again?
5. When does `rerere` pay off, and what do you still have to do after it resolves?
6. What does `git log --merge` show?
7. What is `git blame -M` vs `-C`?
8. What exit code tells `bisect run` to skip a commit? Which means bad?
9. Why is `git bisect` efficient?

<details><summary>Answers</summary>

1. Base (common ancestor), ours, theirs.
2. The base version between `|||||||` and `=======`, so you see what each side changed relative to the original.
3. `-Xours` still merges everything and only prefers our side on conflicting hunks; `-s ours` takes none of their changes (just records the merge).
4. `git revert -m 1 <merge>`; merging again won't re-apply the reverted changes until you revert the revert.
5. Repeated merges/rebases with the same conflicts; you still `git add` (and review) the file, then continue.
6. Only the commits (from either side) that touch the conflicted files, so you see what caused the conflict.
7. `-M` detects lines moved within a file; `-C` detects lines copied/moved from other files (same commit; `-C -C` deeper).
8. 125 = skip; 1–127 (except 125) = bad; 0 = good; ≥128 aborts.
9. Binary search: ~log₂(N) tests for N commits.
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Read a conflict via stages, diff3 and combined diff and resolve it deliberately.
- [ ] Pick the right of `-Xours/-Xtheirs/-s ours/checkout --ours`.
- [ ] Undo a merge safely on private and shared branches, and explain the re-merge trap.
- [ ] Turn on `rerere` and recognise its output.
- [ ] Use `blame -L -w -M -C --ignore-rev` and `bisect run` to find who/what/when.

**Next:** [10-git-tools-submodules-bundling-replace-and-credentials.md](10-git-tools-submodules-bundling-replace-and-credentials.md): submodules, bundles, `git replace`, and credential helpers.
