# 11 · Customizing Git: Configuration, Attributes, and Hooks
> Book reference: Pro Git, Chapter 8, "Git Configuration", "Git Attributes", "Git Hooks", "An Example Git-Enforced Policy" (book pp. 336–366)
> Level: Advanced · Est. time: 4 h

## 1. Why this matters
Git's defaults suit nobody perfectly. Configuration tunes the tool to you; **attributes** tune how Git treats particular files (binary diffs, line endings, keyword expansion, export rules); **hooks** let a team *enforce* policy (commit-message formats, no direct pushes to `main`, ACLs, deployments) automatically. This is where you turn "we agreed to do X" into "Git won't let you skip X".

## 2. Prerequisites
- [01-getting-started.md](01-getting-started.md) (config levels), [04-git-on-the-server.md](04-git-on-the-server.md) (bare repos, pushing to a server), [09-git-tools-advanced-merging-rerere-and-debugging.md](09-git-tools-advanced-merging-rerere-and-debugging.md) (merge tools, conflicts).
- Basic shell scripting (all hooks here are `sh` or Python; Ruby also works if installed).

## 3. Learning objectives
- [ ] Choose and set the settings that matter (editor, pager, colors, autocorrect, ignore file, line endings, whitespace, pull/push defaults).
- [ ] Wire up external diff/merge tools.
- [ ] Use `.gitattributes`: binary detection, text-conversion diffs, line endings, `clean`/`smudge` filters, `ident`, `export-ignore`/`export-subst`, merge drivers.
- [ ] Write client-side hooks (`pre-commit`, `prepare-commit-msg`, `commit-msg`, `post-*`, `pre-rebase`, `pre-push`).
- [ ] Share hooks with a team (`core.hooksPath`, template directories).
- [ ] Write server-side hooks (`pre-receive`, `update`, `post-receive`) to enforce message format, per-user/per-path ACLs and deploy.
- [ ] Explain why client hooks are advisory and server hooks are authoritative.

## 4. Core concepts

### 4.1 Configuration
Levels (later wins): system `/etc/gitconfig` → global `~/.gitconfig` → local `.git/config` → worktree. Environment/CLI override: `git -c key=value <cmd>`. Inspect with `git config --list --show-origin`, `git config --get-regexp '^core\.'`, edit with `git config -e [--global]`.
**Conditional includes** (different identity per folder):
```ini
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work         # contains [user] email = me@company.example
```
(`gitdir:` must end with `/`; also `onbranch:` and, in newer Git, `hasconfig:remote.*.url:`.)

**Settings worth knowing**
| Setting | Effect |
|---------|--------|
| `core.editor` | editor for messages (else `$GIT_EDITOR`, `$VISUAL`, `$EDITOR`); GUI editors need a wait flag: `code --wait` |
| `commit.template <file>` | pre-fills the commit message (lines starting `#` are stripped) → consistent messages |
| `core.pager` | pager for long output (`less -FRX`; `cat` or `--no-pager` to disable; `git -p cmd` forces) |
| `user.signingkey`, `commit.gpgsign` | signing ([07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md)) |
| `core.excludesFile` | global ignore list (editor files, OS junk) |
| `help.autocorrect` | `0` off; `1`/`immediate` run the suggested command; `prompt`; `never`; or deciseconds to wait |
| `color.ui` (`auto`/`always`/`false`), `color.diff.new`, `color.status.*` … | colours; `auto` = only on a terminal |
| `diff.tool`/`difftool.<t>.cmd`, `merge.tool`/`mergetool.<t>.cmd`, `mergetool.keepBackup`, `.trustExitCode` | external diff/merge tools (see §4.2) |
| `core.autocrlf` | `true` (Windows: CRLF in worktree, LF in repo), `input` (Linux/macOS: convert CRLF→LF on commit), `false` |
| `core.whitespace` | which whitespace problems `git diff --check`/`apply` complain about (`trailing-space,space-before-tab,cr-at-eol`, …) |
| `pull.rebase`, `pull.ff only` | what `git pull` does when branches diverge (modern Git errors until you choose) |
| `push.default simple`, `push.autoSetupRemote true` | safe default push; first push sets upstream automatically |
| `fetch.prune true` | drop stale remote-tracking branches on fetch |
| `merge.conflictStyle diff3` / `zdiff3`, `diff.algorithm histogram`, `rerere.enabled`, `init.defaultBranch`, `commit.verbose`, `column.ui`, `branch.sort -committerdate` | quality-of-life |
| `alias.*` | shortcuts ([02-git-basics.md](02-git-basics.md)) |

**External diff and merge tools:** `git difftool` and `git mergetool` launch whichever tool you configure. A tool is a command receiving file paths in variables `$LOCAL` (ours), `$REMOTE` (theirs), `$BASE` (common ancestor), `$MERGED` (output file). Set `mergetool.<name>.trustExitCode true` if the tool's exit status reliably says "resolved". `git difftool --tool-help` lists known tools (vimdiff, meld, kdiff3, p4merge, VS Code via `cmd`, …).

**Formatting and whitespace:** line endings are the #1 cross-platform annoyance. Prefer a **committed `.gitattributes`** (`* text=auto`, `*.sh text eol=lf`) over per-developer `autocrlf`, so the repo, not each machine, decides.

**Server configuration (run on the server's bare repo)**
| Setting | Effect |
|---------|--------|
| `receive.fsckObjects true` (also `transfer.fsckObjects`) | verify every pushed object; protects against corruption/bad tools |
| `receive.denyNonFastForwards true` | reject force-pushes (history rewrites) |
| `receive.denyDeletes true` | reject branch/tag deletions |
| `receive.denyCurrentBranch` | what to do on pushes to the checked-out branch of a non-bare repo |

### 4.2 Git attributes
A **`.gitattributes`** file (committed, applies to the team) or `.git/info/attributes` (local only; or `core.attributesFile`) maps **path patterns → attributes**. Inspect with `git check-attr -a <path>`.

| Attribute | Use |
|-----------|-----|
| `binary` (macro = `-diff -merge -text`) | never textual diff/merge/convert (`*.png binary`). Git already guesses; use to force. `-diff` alone: don't show a text diff |
| `diff=<driver>` + `diff.<driver>.textconv <cmd>` | show a **text rendition** of binary/structured files in `git diff`/`log -p`: `.docx` via `docx2txt`, images via `exiftool`, JSON via a pretty-printer, binaries via `strings`. `diff.<d>.cachetextconv true` caches results |
| `text`, `-text`, `text=auto`, `eol=lf|crlf` | line-ending normalisation (applies on add/checkout); `git add --renormalize .` after changing rules |
| `ident` | expands `$Id$` into `$Id: <blob-sha> $` on checkout (replaces keyword tricks of CVS/SVN) |
| `filter=<name>` + `filter.<name>.clean`/`.smudge`/`.required` | run commands when **adding** (clean: working → repo) and **checking out** (smudge: repo → working). Use for keyword expansion (`$Date$`), code formatting, stripping secrets/notebook outputs, Git LFS |
| `export-ignore` | exclude from `git archive` (tests, CI config, secrets) |
| `export-subst` | expand `$Format:<pretty-format>$` placeholders in files when archiving (version/hash stamps) |
| `merge=<driver>` + `merge.<driver>.driver <cmd>` | custom merge: `merge.ours.driver true` makes `merge=ours` files always keep *our* version |
| `linguist-generated`, `linguist-vendored`, `linguist-language=…` | GitHub language statistics / diff collapsing (hosting-service hint) |
**Clean/smudge filters** must be **idempotent and reversible in spirit**: `smudge(clean(x))` should be stable, and `clean` must produce the same bytes each time or every file looks modified. Mark `filter.<n>.required true` so a missing tool errors out instead of silently committing unfiltered content.

### 4.3 Hooks
**Hooks** are executable scripts Git runs at certain points. They live in `.git/hooks/` (local) or in the bare repo's `hooks/` (server). Name = event (`pre-commit`, `commit-msg`, …), no extension, **must be executable**, any language with a shebang. Git ships `*.sample` files. Exit **0** = proceed; **non-zero aborts** for the "pre-" style hooks; post-hooks cannot abort anything.
- **Hooks are not cloned** (they aren't versioned). Share them with: a tracked directory + `git config core.hooksPath .githooks` (set by a bootstrap script/`make setup`), `init.templateDir`/`git init --template`, or frameworks (`pre-commit`, Husky, lefthook).
- **Client-side hooks are advisory:** `git commit --no-verify` / `git push --no-verify` skips `pre-commit`, `commit-msg`, `pre-push`; developers can also just delete them. **Server-side hooks are the enforcement point** (they can't be bypassed by the pusher). Do both: client hooks for fast feedback, server hooks for guarantees (and CI as the third layer).
- 💡 `git hook run <name> [-- args]` runs a configured hook manually (useful to test); `--ignore-missing` avoids errors if absent.

**Client-side hooks**
| Hook | Runs | Args / stdin | Typical use |
|------|------|--------------|-------------|
| `pre-commit` | before the commit message is requested | none | lint, tests, block TODO/secrets/whitespace errors |
| `prepare-commit-msg` | after default message created, before editor | `$1` msg file, `$2` source (`message`, `template`, `merge`, `squash`, `commit`), `$3` sha | insert ticket ID from branch name, templates |
| `commit-msg` | after you write the message | `$1` msg file | validate format (`ABC-123: …`), length |
| `post-commit` | after commit | none | notifications, local logging |
| `applypatch-msg`, `pre-applypatch`, `post-applypatch` | around `git am` | | email-patch workflows |
| `pre-rebase` | before a rebase *actually happens* | upstream, branch | forbid rebasing published branches |
| `post-rewrite` | after amend/rebase | command; stdin `old new` pairs | notes/cache fix-ups |
| `post-checkout` | after `checkout/switch/clone` | prev HEAD, new HEAD, `1`=branch checkout | set up work tree, generated files, show warnings |
| `post-merge` | after a successful merge/pull | squash flag | reinstall dependencies when lockfile changes |
| `pre-push` | during `git push`, before sending | remote name, URL; stdin `<local ref> <local sha> <remote ref> <remote sha>` | run tests, block pushes to `main` |
| `pre-auto-gc`, `reference-transaction`, `fsmonitor-watchman` | specialised | | |

**Server-side hooks (run in the bare repo, on `git push`)**
| Hook | Runs | Input | Can abort? |
|------|------|-------|------------|
| `pre-receive` | once, before any ref is updated | stdin: `<old> <new> <ref>` per pushed ref | yes (rejects the **whole** push) |
| `update` | once **per ref** | args: `<ref> <old> <new>` | yes (rejects that ref only) |
| `post-receive` | after all refs updated | stdin like `pre-receive` | no (notify, CI trigger, deploy, mirror, email) |
| `post-update`, `push-to-checkout`, `proc-receive` | specialised | | |
All-zero SHA (`000…0`) as `<old>` = branch **creation**; as `<new>` = **deletion**. During `pre-receive`/`update`, pushed objects sit in a **quarantine** directory (`GIT_QUARANTINE_PATH`) and become permanent only if hooks pass, so rejecting is clean. Output to stderr appears to the pusher prefixed with `remote:`.
Hosting services: GitHub.com doesn't allow custom server hooks (use branch protection/rulesets, required status checks, Actions); GitHub Enterprise Server and self-managed GitLab support pre-receive/server hooks.

### 4.4 An example Git-enforced policy
The book builds a policy with Ruby hooks; the same ideas in shell:
1. **Commit-message format** ("every commit must reference a ticket"): `commit-msg` (client, friendly) + `pre-receive` (server, authoritative): iterate commits in each pushed range (`git rev-list $old..$new`, or `$new --not --all` for a new branch) and check each subject with a regex.
2. **User ACL:** an `update` hook maps the pushing user (from the SSH key/`$GL_USER`/`$REMOTE_USER`; here simulated by an env var) to allowed refs, e.g. only admins write `main`.
3. **Path ACL:** the same hook lists files touched in the pushed range (`git diff-tree -r --name-only --no-commit-id <commits>`) and allows e.g. a "docs writer" to modify only `docs/`.
4. **No history rewriting/deletion:** `receive.denyNonFastForwards`, `receive.denyDeletes` (config, no code needed).
5. **Client-side counterpart for fast feedback:** `pre-commit` (lint/whitespace), `commit-msg`, `pre-push`.
6. **Deploy on push:** `post-receive` checks out `main` into a web root (`GIT_WORK_TREE=/var/www git checkout -f main`), or triggers CI.
Principle: *make the right thing the easy thing locally, make the wrong thing impossible on the server.*

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git config [--global] key val` / `-e` | Set/edit config | Always |
| `git config --list --show-origin` | See effective settings and sources | Debug |
| `git difftool` / `git mergetool` (`--tool-help`) | Launch external tools | Visual diff/merge |
| `git check-attr -a <path>` | Show attributes for a path | Debug attributes |
| `git add --renormalize .` | Re-apply text/eol/filter rules | After editing `.gitattributes` |
| `git ls-files --eol` | Show index/worktree line endings | Line-ending debugging |
| `git archive [--prefix=p/] -o f.zip HEAD` | Export tree (honours `export-*`) | Releases |
| `chmod +x .git/hooks/<name>` | Enable a hook | After writing it |
| `git config core.hooksPath .githooks` | Use versioned hooks | Team-shared hooks |
| `git commit/push --no-verify` | Skip client hooks | Emergencies (not policy!) |
| `git hook run <name>` | Run a hook by hand | Testing |
| `git init --template=<dir>` / `init.templateDir` | Seed new repos | Org defaults |
| `git config receive.denyNonFastForwards true` | Server policy | On the bare repo |

## 6. Hands-on labs
All local; no network, root, or extra tools beyond `sh`, `python3`, `sed`, `tar`.
Setup:
```bash
mkdir -p ~/git-labs/11 && cd ~/git-labs/11
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"          # sandbox config; also keeps ~ untouched
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
LAB="$PWD"                                          # remember the lab root for later labs
```

### Lab 1 · Configuration tour
```bash
cd "$LAB" && rm -rf c && git init c && cd c
# commit.template
printf 'Subject line here\n\n# Why:\n# What:\n# Ticket:\n' > "$LAB/tmpl.txt"
git config commit.template "$LAB/tmpl.txt"
echo a > a && git add .
GIT_EDITOR='sed -n 1,3p' git commit            # editor sees the template (aborts with empty message)
git config --unset commit.template && git commit -m init
# pager, global ignore, autocorrect, colour
git config --global core.pager 'less -FRX'
echo '*.swp' > "$LAB/gitignore_global" && git config --global core.excludesFile "$LAB/gitignore_global"
touch x.swp && git status -s                    # x.swp is hidden
git config --global help.autocorrect 0
git stauts 2>&1 | head -2                       # "git: 'stauts' is not a git command."
git config --global color.ui auto
git config color.diff.new "green bold" && git config --get color.diff.new
# includeIf: per-folder identity
mkdir -p "$LAB/work/proj" && git init -q "$LAB/work/proj"
printf '[user]\n\temail = me@work.example\n' > "$LAB/work.gitconfig"
git config --global includeIf."gitdir:$LAB/work/".path "$LAB/work.gitconfig"
git -C "$LAB/work/proj" config user.email       # me@work.example
git config user.email                           # jane@example.com
git config --list --show-origin | grep -c "file:"
```
**Expected:** template first lines printed; `x.swp` not listed; autocorrect error for `stauts`; work repo uses the work email, the other repo the global one.

### Lab 2 · Custom diff and merge tools
```bash
cd "$LAB/c"
cat > "$LAB/mydiff.sh" <<'EOF'
#!/bin/sh
echo "MYDIFF compare: $(basename "$1") vs $(basename "$2")"
EOF
chmod +x "$LAB/mydiff.sh"
git config diff.tool mydiff
git config difftool.mydiff.cmd "$LAB/mydiff.sh \"\$LOCAL\" \"\$REMOTE\""
git config difftool.prompt false
echo b >> a && git difftool | head -2          # MYDIFF compare: … (runs your script, not the built-in diff)
git commit -qam "b"
# a scripted "merge tool" that always writes a resolution
git switch -qc br && echo br > a && git commit -qam br && git switch -q main
echo m > a && git commit -qam m && git merge br        # CONFLICT
cat > "$LAB/mymerge.sh" <<'EOF'
#!/bin/sh
# $1=LOCAL $2=REMOTE $3=BASE $4=MERGED
printf 'resolved by mymerge\n' > "$4"
EOF
chmod +x "$LAB/mymerge.sh"
git config merge.tool mymerge
git config mergetool.mymerge.cmd "$LAB/mymerge.sh \"\$LOCAL\" \"\$REMOTE\" \"\$BASE\" \"\$MERGED\""
git config mergetool.mymerge.trustExitCode true
git config mergetool.keepBackup false
git mergetool                                   # runs your script for each conflicted file
cat a; git status -s                            # resolved by mymerge / M  a
git commit -qam "merged"
git difftool --tool-help | head -3             # tools Git knows about
```
**Expected:** `git difftool` prints your script's line; `git mergetool` resolves the conflict via your script. Real-world: `git config merge.tool vimdiff` / `meld` / `p4merge`.

### Lab 3 · Server-side config: block force-push and deletion
```bash
cd "$LAB" && rm -rf s.git && git init --bare s.git
git -C s.git config receive.denyNonFastForwards true
git -C s.git config receive.denyDeletes true
git -C s.git config receive.fsckObjects true
cd c && git remote add origin ../s.git && git push -q origin main
git commit -q --amend -m "amended"
git push origin main 2>&1 | grep -E "rejected"            # non-fast-forward (client-side check)
git push origin +main 2>&1 | grep -E "denying|rejected"   # remote error: denying non-fast-forward
git push origin :main 2>&1 | grep -E "denying|rejected"   # remote error: denying ref deletion
```
**Expected:** all three attempts rejected; the forced ones by the **server**, which the client cannot override.

### Lab 4 · Attributes
```bash
cd "$LAB" && rm -rf at && git init at && cd at
# 4a: binary, check-attr
printf '*.png binary\n*.dat -diff\n*.txt text eol=lf\n' > .gitattributes && git add . && git commit -qm attrs
git check-attr -a logo.png                         # binary: set, diff: unset, merge: unset, text: unset
git check-attr diff text -- logo.png notes.txt
head -c 20 /dev/urandom > blob.dat && git add blob.dat && git commit -qm blob
echo x >> blob.dat && git diff | tail -1           # Binary files … differ
# 4b: textconv — readable diffs of JSON (or any structured/binary file)
printf '*.json diff=pretty\n' >> .gitattributes
git config diff.pretty.textconv "python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1])),indent=2,sort_keys=True))'"
echo '{"b":1,"a":[1,2]}' > d.json && git add . && git commit -qm json
echo '{"b":2,"a":[1,2]}' > d.json && git diff d.json | tail -4      # -  "b": 1  / +  "b": 2 (pretty-printed)
printf '*.bin diff=strings\n' >> .gitattributes && git config diff.strings.textconv strings
printf 'hello\0\0world\n' > a.bin && git add . && git commit -qm bin
printf 'hello\0\0brave world\n' > a.bin && git diff a.bin | tail -3  # text diff of strings in a binary
# 4c: ident
printf '*.ver ident\n' >> .gitattributes && echo '$Id$' > f.ver && git add . && git commit -qm ver
rm f.ver && git checkout -- f.ver && cat f.ver     # $Id: <blob sha> $
# 4d: clean/smudge — keyword expansion
printf '*.html filter=dater\n' >> .gitattributes
git config filter.dater.smudge 'sed "s/\$Date[^\$]*\$/\$Date: $(date +%Y-%m-%d) \$/"'
git config filter.dater.clean  'sed "s/\$Date[^\$]*\$/\$Date\$/"'
git config filter.dater.required true
printf '<p>Updated: $Date$</p>\n' > page.html && git add page.html && git commit -qm html
git show HEAD:page.html                            # repository content keeps the bare keyword
rm page.html && git checkout -- page.html && cat page.html   # working file has today's date
# 4e: export-ignore / export-subst
printf 'secret.txt export-ignore\ntests/ export-ignore\nVERSION export-subst\n' >> .gitattributes
echo s > secret.txt; mkdir -p tests && echo t > tests/t; echo 'Version: $Format:%h (%cd)$' > VERSION
git add . && git commit -qm exp
git archive HEAD --prefix=rel/ | tar -t | grep -E "secret|tests"   # (no output: both excluded)
git archive HEAD VERSION | tar -xO                 # Version: <short sha> (<date>)
# 4f: a merge driver that always keeps our version
git config merge.ours.driver true && printf 'db.xml merge=ours\n' >> .gitattributes
echo base > db.xml && git add . && git commit -qm db
git switch -qc feat && echo feat > db.xml && git commit -qam f && git switch -q main
echo main > db.xml && git commit -qam m && git merge feat | tail -1 && cat db.xml   # main (no conflict)
# 4g: line endings
printf 'a\r\nb\r\n' > crlf.txt && git add crlf.txt     # warning: CRLF will be replaced by LF
git ls-files --eol crlf.txt                        # i/lf  w/crlf  attr/text eol=lf
```
**Expected:** each comment shows the result. Pitfall to try: change a `filter` command so `clean` is non-deterministic and watch every file show as modified; then `git add --renormalize .` after fixing rules.

### Lab 5 · Client-side hooks
```bash
cd "$LAB" && rm -rf h && git init h && cd h
ls .git/hooks | head -3                             # *.sample files ship by default
# pre-commit: block TODO/FIXME/conflict markers, check whitespace
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/sh
if git diff --cached -U0 | grep -E '^\+.*(TODO|FIXME|<<<<<<<|>>>>>>>)' >/dev/null; then
  echo "pre-commit: remove TODO/FIXME/conflict markers before committing" >&2; exit 1
fi
git diff --cached --check || { echo "pre-commit: whitespace errors" >&2; exit 1; }
EOF
chmod +x .git/hooks/pre-commit
echo ok > a.txt && git add a.txt && git commit -m first                 # passes
echo "TODO: fix me" >> a.txt && git add a.txt && git commit -m "has todo"  # blocked (exit 1)
git commit -m "has todo" --no-verify                                      # bypass (client hooks are advisory)
sed -i '/TODO/d' a.txt && git commit -qam "remove todo" --no-verify

# commit-msg: require "ABC-123: description"
cat > .git/hooks/commit-msg <<'EOF'
#!/bin/sh
# $1 = file holding the proposed message
if ! head -1 "$1" | grep -qE '^[A-Z]+-[0-9]+: .{5,}'; then
  echo "commit-msg: subject must look like 'ABC-123: description' (got: $(head -1 "$1"))" >&2; exit 1
fi
EOF
chmod +x .git/hooks/commit-msg
echo more >> a.txt && git add a.txt
git commit -m "bad message"                                               # blocked
git commit -m "ABC-1: good message here"                                  # ok

# prepare-commit-msg: prefix the ticket found in the branch name
cat > .git/hooks/prepare-commit-msg <<'EOF'
#!/bin/sh
# $1=msg file  $2=source (message|template|merge|squash|commit)  $3=sha
ticket=$(git symbolic-ref --short HEAD 2>/dev/null | grep -oE '[A-Z]+-[0-9]+')
[ -n "$ticket" ] && [ "$2" != "merge" ] && ! grep -q "$ticket" "$1" && sed -i.bak "1s/^/$ticket: /" "$1" && rm -f "$1.bak"
exit 0
EOF
chmod +x .git/hooks/prepare-commit-msg
git switch -c ABC-42-login && echo x >> a.txt && git add a.txt
git commit -m "add login form"; git log -1 --format=%s                    # ABC-42: add login form
```
Post-* hooks and `pre-rebase`/`pre-push`:
```bash
cat > .git/hooks/post-commit <<'EOF'
#!/bin/sh
echo "post-commit: committed $(git rev-parse --short HEAD) on $(git branch --show-current)"
EOF
cat > .git/hooks/post-checkout <<'EOF'
#!/bin/sh
# $1=prev HEAD  $2=new HEAD  $3=1 for a branch checkout, 0 for a file checkout
[ "$3" = 1 ] && echo "post-checkout: now on $(git branch --show-current)"
exit 0
EOF
cat > .git/hooks/post-merge <<'EOF'
#!/bin/sh
echo "post-merge: merge finished (squash flag=$1)"
EOF
chmod +x .git/hooks/post-*
echo y >> a.txt && git commit -am "ABC-42: second change"                  # prints post-commit line
git switch main                                                           # prints post-checkout line
git merge ABC-42-login -m "ABC-99: merge login branch"                    # fast-forward → post-merge line
# pre-rebase: forbid rebasing (only fires when a rebase would really rewrite something)
cat > .git/hooks/pre-rebase <<'EOF'
#!/bin/sh
echo "pre-rebase: rebasing is disabled in this repo" >&2; exit 1
EOF
chmod +x .git/hooks/pre-rebase
git reset -q --hard                                                       # drop the staged leftovers from the blocked commits
git switch -q -c divergent && echo d > d.txt && git add . && git commit -qm "ABC-5: divergent work" && git switch -q main
echo m > m.txt && git add . && git commit -qm "ABC-6: main moved on" && git switch -q divergent
git rebase main                                                           # fatal: The pre-rebase hook refused to rebase.
# pre-push: protect main
git init -q --bare ../hs.git && git remote add origin ../hs.git
cat > .git/hooks/pre-push <<'EOF'
#!/bin/sh
# $1=remote $2=url; stdin: <local ref> <local sha> <remote ref> <remote sha>
while read local_ref local_sha remote_ref remote_sha; do
  if [ "$remote_ref" = "refs/heads/main" ] && [ "$(git config user.allowmain)" != "true" ]; then
    echo "pre-push: direct pushes to main are blocked (git config user.allowmain true to override)" >&2; exit 1
  fi
done
EOF
chmod +x .git/hooks/pre-push
git push origin main                                                      # blocked
git push origin divergent                                                 # allowed
```
**Sharing hooks, templates and manual runs**
```bash
mkdir -p .githooks && cp .git/hooks/commit-msg .githooks/ && git config core.hooksPath .githooks
git switch -q main && echo q >> a.txt && git commit -am "nope"; git checkout -q -- a.txt            # blocked by the versioned hook
git config --unset core.hooksPath
# New repos pre-seeded with your hooks:
mkdir -p "$LAB/tmpl/hooks" "$LAB/tmpl/info"
printf '#!/bin/sh\necho "[template pre-commit] running"\n' > "$LAB/tmpl/hooks/pre-commit" && chmod +x "$LAB/tmpl/hooks/pre-commit"
printf '*.log\n' > "$LAB/tmpl/info/exclude"
git -c init.templateDir="$LAB/tmpl" init -q "$LAB/fresh" && ls "$LAB/fresh/.git/hooks"   # pre-commit
cd "$LAB/fresh" && git hook run pre-commit; echo "exit=$?"                # [template pre-commit] running / exit=0
# post-* hooks cannot abort: exit 1 here does not stop the commit
printf '#!/bin/sh\nexit 1\n' > .git/hooks/post-commit && chmod +x .git/hooks/post-commit
echo z > z && git add z && git commit -qm "ok subject"; echo "commit exit=$?"   # 0
```
**Expected:** each hook behaves as annotated; the `pre-rebase` and `pre-push` hooks print their messages and abort; `core.hooksPath` makes a tracked directory the hook source; template hooks appear in new repos.

### Lab 6 · Server-side hooks: policy, ACLs, deploy
```bash
cd "$LAB" && rm -rf srv.git dev www push.log
git init --bare srv.git && git clone srv.git dev && cd dev
echo base > f && git add . && git commit -qm "TICKET-1: base commit" && git push -q origin main
# 6a pre-receive: every pushed commit must have a "TICKET-n: " subject
cat > "$LAB/srv.git/hooks/pre-receive" <<'EOF'
#!/bin/sh
zero=0000000000000000000000000000000000000000
while read old new ref; do
  [ "$new" = "$zero" ] && continue                              # deleting a branch: nothing to check
  if [ "$old" = "$zero" ]; then range="$new --not --all"; else range="$old..$new"; fi
  for c in $(git rev-list $range); do
    subj=$(git log -1 --format=%s "$c")
    if ! printf '%s' "$subj" | grep -qE '^[A-Z]+-[0-9]+: .+'; then
      echo "pre-receive: REJECTED $(git rev-parse --short "$c"): '$subj' (need 'TICKET-n: message')" >&2
      exit 1
    fi
  done
done
EOF
chmod +x "$LAB/srv.git/hooks/pre-receive"
echo x >> f && git commit -qam "quick fix"
git push origin main 2>&1 | grep -E "remote:|rejected"           # REJECTED … (pre-receive hook declined)
git commit -q --amend -m "TICKET-2: proper message" && git push origin main 2>&1 | tail -1   # accepted
# 6b update hook: user ACL on refs (user simulated by $PUSH_USER; real servers use the SSH identity)
cat > "$LAB/srv.git/hooks/update" <<'EOF'
#!/bin/sh
ref="$1"; user="${PUSH_USER:-anonymous}"
if [ "$ref" = "refs/heads/main" ] && [ "$user" != "admin" ]; then
  echo "update: $user may not push to main" >&2; exit 1
fi
exit 0
EOF
chmod +x "$LAB/srv.git/hooks/update"
echo y >> f && git commit -qam "TICKET-3: change"
PUSH_USER=bob   git push origin main 2>&1 | grep -E "update:|rejected"    # denied
PUSH_USER=admin git push origin main 2>&1 | tail -1                      # allowed
git switch -qc topic && PUSH_USER=bob git push -q origin topic           # bob may push other branches
git switch -q main
# 6c post-receive: log + deploy main to a directory
mkdir "$LAB/www"
cat > "$LAB/srv.git/hooks/post-receive" <<EOF
#!/bin/sh
while read old new ref; do
  echo "post-receive: \$ref \$(echo \$old|cut -c1-7)..\$(echo \$new|cut -c1-7)" >> "$LAB/push.log"
  if [ "\$ref" = "refs/heads/main" ]; then
    GIT_WORK_TREE="$LAB/www" git checkout -f main
    echo "post-receive: deployed \$(echo \$new|cut -c1-7)"
  fi
done
EOF
chmod +x "$LAB/srv.git/hooks/post-receive"
echo z >> f && git commit -qam "TICKET-4: deploy me"
PUSH_USER=admin git push origin main 2>&1 | grep "remote:"               # remote: post-receive: deployed …
cat "$LAB/push.log"; ls "$LAB/www"                                        # f appears in the web root
# 6d the pusher cannot bypass server hooks
echo q >> f && git commit -qam "no ticket"
PUSH_USER=admin git push --no-verify origin main 2>&1 | grep -E "REJECTED|rejected"
```
**Expected:** annotated lines. `--no-verify` doesn't help against `pre-receive`. (A real server would run `post-receive` as the repo owner with `GIT_DIR` set; here the hook inherits it from Git.)

### Lab 7 · Path-based ACL
```bash
cd "$LAB" && rm -rf acl.git acl && git init --bare acl.git && git clone acl.git acl && cd acl
mkdir docs src && echo d > docs/a.md && echo s > src/a.c && git add . && git commit -qm "TICKET-1: init" && git push -q origin main
cat > "$LAB/acl.git/hooks/update" <<'EOF'
#!/bin/sh
# update <ref> <old> <new>: "dev" may change anything; anyone else only docs/
ref="$1"; old="$2"; new="$3"; user="${PUSH_USER:-anonymous}"
zero=0000000000000000000000000000000000000000
[ "$old" = "$zero" ] && range="$new" || range="$old..$new"
[ "$user" = "dev" ] && exit 0
for f in $(git diff-tree -r --name-only --no-commit-id $(git rev-list $range) 2>/dev/null | sort -u); do
  case "$f" in docs/*) ;; *) echo "update: $user may not modify '$f'" >&2; exit 1 ;; esac
done
EOF
chmod +x "$LAB/acl.git/hooks/update"
echo doc >> docs/a.md && git commit -qam "TICKET-2: docs"; PUSH_USER=writer git push origin main 2>&1 | tail -1      # ok
echo code >> src/a.c && git commit -qam "TICKET-3: code"
PUSH_USER=writer git push origin main 2>&1 | grep -E "update:|rejected"   # may not modify 'src/a.c'
PUSH_USER=dev    git push origin main 2>&1 | tail -1                      # ok
```
**Expected:** the docs-only change passes for `writer`, the `src/` change is refused for `writer` and allowed for `dev`.

### Lab 8 · Capstone: a team "policy kit"
Create a repo `kit/` containing `.githooks/{pre-commit,commit-msg,pre-push}`, a `scripts/install-hooks.sh` that runs `git config core.hooksPath .githooks`, a `.gitattributes` (`* text=auto`, `*.sh text eol=lf`, `*.png binary`), a `commit.template` and a README. Publish it to a bare repo with `pre-receive` (message format) and `receive.denyNonFastForwards`. Clone it fresh, run the installer, and demonstrate three blocked actions (bad message, TODO commit, forced push) and one allowed flow. Write 5 lines on which layer (client hook, server hook, config) enforced each rule and why.

## 7. Practice challenges
1. Make `git lg` an alias, set `push.autoSetupRemote`, `pull.rebase`, `fetch.prune` and verify each with `git config --get`.
2. Configure `includeIf` so repos under `~/oss/` use a personal email and repos under `~/work/` use a work email. Prove it with `git config user.email` in each.
3. Write a `pre-commit` hook that refuses to commit files larger than 1 MB (hint: `git diff --cached --name-only --diff-filter=AM` and `wc -c`).
4. Write a `commit-msg` hook in **Python** that enforces a 50-char subject limit, a blank second line, and body lines ≤ 72 characters.
5. Add an attribute so `.docx`-like (or `.csv`) files show a readable diff using `textconv` (for CSV, `column -s, -t`).
6. Configure a `clean` filter that strips trailing whitespace on `*.md` files and a `smudge` filter of `cat`; show that the repo copy has no trailing space but the working file is unchanged.
7. Write a `post-merge` hook that prints a warning when `package-lock.json` (or any file you choose) changed in the merge (hint: `git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD`).
8. Extend Lab 6's `pre-receive` to forbid pushing any commit that adds a file matching `*.pem` or containing the string `BEGIN PRIVATE KEY`.
9. Make `post-receive` send a one-line summary (author, subject) for each pushed commit into a log file.

<details><summary>Solutions</summary>

1. `git config --global alias.lg "log --oneline --graph --decorate --all"; git config --global push.autoSetupRemote true; git config --global pull.rebase true; git config --global fetch.prune true`; check each with `git config --get <key>`.
2. `[includeIf "gitdir:~/oss/"] path = ~/.gitconfig-oss`, `[includeIf "gitdir:~/work/"] path = ~/.gitconfig-work` (trailing `/` matters).
3. ```sh
   for f in $(git diff --cached --name-only --diff-filter=AM); do
     [ "$(git show :"$f" | wc -c)" -gt 1048576 ] && { echo "pre-commit: $f is larger than 1 MB" >&2; exit 1; }
   done
   ```
4. Read `sys.argv[1]`; `lines = open(...).read().splitlines()`; check `len(lines[0]) <= 50`, `len(lines) < 2 or lines[1] == ""`, and `all(len(l) <= 72 for l in lines[2:] if not l.startswith('#'))`; `sys.exit("message")` on failure.
5. `.gitattributes`: `*.csv diff=csv`; `git config diff.csv.textconv "column -s, -t"`.
6. `*.md filter=trim`; `git config filter.trim.clean "sed 's/[ \t]*$//'"`; `git config filter.trim.smudge cat`; compare `git show :file | cat -A` with `cat -A file`.
7. `if git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD | grep -q '^package-lock.json$'; then echo "lockfile changed: run npm ci"; fi`.
8. Inside the commit loop: `git diff-tree -r --no-commit-id --name-only --diff-filter=A "$c" | grep -qE '\.pem$'` and `git show "$c" | grep -q 'BEGIN PRIVATE KEY'`; print a message and `exit 1`.
9. In `post-receive` loop: `git log --format='%an: %s' $old..$new >> push.log` (handle the all-zero `old` for new branches).
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Hook doesn't run | Not executable (`chmod +x`), wrong name/extension, bad shebang, or `core.hooksPath` points elsewhere (`git config core.hooksPath`) |
| Hook "works for me" but not teammates | Hooks aren't cloned: version them under `.githooks/` + `core.hooksPath` bootstrap |
| Commit blocked by hook in an emergency | `git commit --no-verify` (then fix); never make that your standard workflow |
| Relying only on client hooks for policy | They can be skipped; enforce on the server (or via CI/branch protection) |
| `pre-receive` rejects a brand-new branch with huge history | Use `$new --not --all` for creation so you only check *new* commits |
| Hook reads the wrong files in `pre-commit` | Check the **index** (`git diff --cached`, `git show :path`), not the working tree |
| `post-receive` deploy fails with "not a git repository" or wrong dir | Set `GIT_WORK_TREE` and use `git checkout -f`; unset a stray `GIT_DIR` when calling other repos |
| Every file shows modified after adding a filter | `clean` isn't deterministic/idempotent; fix it then `git add --renormalize .` |
| Line-ending warnings forever | Commit a `.gitattributes` (`* text=auto`), run `git add --renormalize .`, commit once |
| `textconv` diff missing | `diff=<driver>` attribute on the path *and* `diff.<driver>.textconv` configured; check with `git check-attr diff -- file` |
| `merge=ours` driver ignored | Driver must be defined (`git config merge.ours.driver true`) on each clone: it's config, not committed |
| Custom filter missing tool on CI | Set `filter.<n>.required true` so it fails loudly |
| `git hook list` not found | Added in newer Git than 2.43; use `ls .git/hooks` or `git config core.hooksPath` |
| Server hook output invisible | Print to **stderr** (shown as `remote:` lines); stdout may be swallowed by some transports |

## 9. Real-world use cases
- **Engineering standards:** commit-message conventions (Conventional Commits, ticket IDs), lint/format on commit, secret scanning (pre-commit frameworks, `gitleaks`).
- **Cross-platform teams:** `.gitattributes` for line endings and binary assets; Git LFS is implemented with exactly this `filter=lfs` mechanism.
- **Releases:** `export-ignore`/`export-subst` keep tarballs clean and stamped with the commit hash.
- **Self-hosted governance:** pre-receive hooks enforcing ACLs, blocking force-pushes/large files/secrets, triggering CI and deployments from `post-receive`.
- **Data/notebooks/docs:** textconv diffs for Jupyter, Word, images, CSV in code review.

## 10. Self-check quiz
1. Which config level wins when a key is set at global and local levels?
2. How do you make files under `~/work/` use a different email automatically?
3. What do `$LOCAL`, `$REMOTE`, `$BASE`, `$MERGED` mean in a mergetool command?
4. What's the difference between `clean` and `smudge` filters?
5. How does `export-subst` differ from `export-ignore`?
6. What makes a hook run, and what exit code aborts a commit?
7. Why are client hooks not a security control?
8. Difference between `pre-receive` and `update`? Which can reject only one ref of a multi-ref push?
9. How do you share hooks with a team?
10. What does an all-zero SHA in `<old>`/`<new>` mean?

<details><summary>Answers</summary>

1. Local (`.git/config`).
2. `[includeIf "gitdir:~/work/"] path = ~/.gitconfig-work`.
3. Your side, the other branch's version, the common ancestor, and the output file to write.
4. `clean` runs when adding (worktree → repo); `smudge` runs on checkout (repo → worktree).
5. `export-ignore` omits paths from archives; `export-subst` expands `$Format:…$` placeholders in the exported files.
6. Executable file named for the event in `.git/hooks`; any non-zero exit aborts (for pre-* hooks).
7. The developer can skip them (`--no-verify`) or delete them; the server never has to run them.
8. `pre-receive` runs once and rejects the entire push; `update` runs per ref and can reject individual refs.
9. Track them in a repo directory and set `core.hooksPath` (via bootstrap script), use templates, or a hook framework.
10. `old` zeros = ref is being created; `new` zeros = ref is being deleted.
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Set up a machine's config (identity per folder, editor, pager, tools, pull/push defaults) in minutes.
- [ ] Write `.gitattributes` for line endings, binaries, readable diffs, filters and clean exports; debug with `check-attr`.
- [ ] Write and test client hooks and share them via `core.hooksPath`.
- [ ] Write server hooks that enforce message format and per-user/per-path ACLs, and deploy on push.
- [ ] Explain the layers: client hooks (feedback), server hooks/config (enforcement), CI (verification).

**Next:** [12-git-and-other-systems-svn-migration.md](12-git-and-other-systems-svn-migration.md): using Git alongside Subversion, and migrating other VCSs to Git.
