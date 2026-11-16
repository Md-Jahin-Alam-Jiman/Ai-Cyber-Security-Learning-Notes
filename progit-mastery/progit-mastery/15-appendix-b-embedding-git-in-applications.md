# 15 · Appendix B: Embedding Git in Your Applications
> Book reference: Pro Git, Appendix B, "Embedding Git in your Applications" (book pp. ~507–528)
> Level: Advanced · Est. time: 2–3 h
> 🌐 libgit2/JGit/go-git/Dulwich/pygit2 are **not installed** in the sandbox used to test this file (no package installs, no network), so library code samples are **untested illustrations**. Labs 1–4 use only `git` and the Python standard library and **were run**.

## 1. Why this matters
If your product needs version history (an IDE, wiki, CMS, notes app, CI tool, data-versioning system, deployment tool), you can build on Git instead of inventing a storage format. You get content-addressed storage, history, branching, diff/merge, and a huge existing ecosystem of hosting and tooling. The question is *how* to call it.

## 2. Prerequisites
[13-git-internals-plumbing-and-objects.md](13-git-internals-plumbing-and-objects.md) (objects/refs: libraries expose exactly these), [14-appendix-a-git-in-other-environments.md](14-appendix-a-git-in-other-environments.md) (porcelain output, `-z`, env vars).

## 3. Learning objectives
- [ ] Compare three embedding strategies: shell out to `git`, link a library (libgit2/JGit), or use a native reimplementation (go-git, Dulwich).
- [ ] Choose a strategy for a given product (licence, language, deployment, performance, feature needs).
- [ ] Use `git` safely as a subprocess (no shell injection, deterministic output, concurrency/locking).
- [ ] Read and write Git objects programmatically; understand what a library does for you.
- [ ] Recognise gaps and gotchas (hooks, config, credentials, partial support).

## 4. Core concepts

### 4.1 Option A: command-line Git (subprocess)
Run the `git` executable and parse its machine-readable output (see [14-appendix-a-git-in-other-environments.md](14-appendix-a-git-in-other-environments.md)).
- **Pros:** full feature set, identical to what users run (hooks, config, credentials, LFS, submodules), always as correct as Git itself, easy to debug.
- **Cons:** requires `git` installed on the target machine (bundle it or document it); process spawn cost; output parsing; harder cross-platform edge cases (Windows paths/encodings); licence is **GPLv2** (invoking the executable is fine, linking its code is not).
**Safe subprocess rules**
1. Pass an **argument array**, never a shell string: `subprocess.run(["git", "checkout", branch])`, not `"git checkout " + branch`. User input like `--upload-pack=...` or a branch named `-x` can be interpreted as options: put `--` before paths/refs from users, and validate ref names with `git check-ref-format --branch <name>`.
2. Use machine formats (`--porcelain`, `--format`, `-z`), `LC_ALL=C`, `--no-pager`, `-c color.ui=false`.
3. `GIT_TERMINAL_PROMPT=0` (never hang for credentials), timeouts, and cap output size.
4. Pin the working location explicitly: `git -C <dir> ...` or `GIT_DIR`/`GIT_WORK_TREE`; isolate config with `GIT_CONFIG_GLOBAL=/dev/null` / `GIT_CONFIG_NOSYSTEM=1` for reproducible behaviour.
5. Serialize writers per repository: Git uses lock files (`index.lock`, `refs/...lock`); concurrent writers get "Unable to create ... .lock" errors. Reads can use `GIT_OPTIONAL_LOCKS=0`.
6. For bulk object reads use **one long-lived** `git cat-file --batch` process rather than spawning per object.

### 4.2 Option B: libgit2 and bindings
**libgit2** is a portable, linkable C implementation of core Git, with a **GPLv2 + linking exception** (so closed-source apps may link it). Bindings: **pygit2** (Python), **Rugged** (Ruby), **NodeGit** (Node), **LibGit2Sharp** (.NET), **git2-rs** (Rust), **libgit2go / git2go**, PHP, Java, Swift, etc. Used by many GUI clients and hosting services.
- **Pros:** in-process (fast, no subprocess), typed API for objects/refs/index/diff/merge, thread-aware, works where installing `git` isn't possible.
- **Cons:** not 100% of Git: historically weaker/absent support for some features (hooks are *not* run automatically, some merge/rebase/worktree/shallow/partial-clone features, config include rules, credential helper integration differ). Bindings lag behind libgit2 releases. Behaviours can differ subtly from `git`.
Typical API shape (pseudo-Python/pygit2, **untested here**):
```python
import pygit2
repo = pygit2.init_repository("/tmp/r", bare=False)
blob_id = repo.create_blob(b"hello\n")                       # == git hash-object -w
tb = repo.TreeBuilder(); tb.insert("hello.txt", blob_id, pygit2.GIT_FILEMODE_BLOB)
tree_id = tb.write()                                         # == write-tree
sig = pygit2.Signature("Jane Doe", "jane@example.com")
commit_id = repo.create_commit("refs/heads/main", sig, sig, "first", tree_id, [])  # == commit-tree + update-ref
for c in repo.walk(commit_id, pygit2.GIT_SORT_TIME): print(c.short_id, c.message)
```
Notice it is the same four-step recipe as Lab 3 in [13-git-internals-plumbing-and-objects.md](13-git-internals-plumbing-and-objects.md).

### 4.3 Option C: native reimplementations
- **JGit** (Java; **Eclipse Distribution License**, BSD-style): pure Java, used by Eclipse, Gerrit, Jenkins, many JVM tools. Offers both **plumbing** (`Repository`, `ObjectInserter`, `RevWalk`, `TreeWalk`, `RefUpdate`) and **porcelain** (`Git.init()…commit().call()`).
- **go-git** (Go; Apache-2.0): pure Go, no cgo, used by Go tooling and Kubernetes-adjacent apps (Argo/Flux-style tools).
- **Dulwich** (Python; Apache-2/GPL dual): pure Python; has plumbing (`repo.object_store`, `Blob`, `Tree`, `Commit`) and porcelain (`dulwich.porcelain.add/commit/clone`). Easy to install anywhere Python runs.
- Others: **isomorphic-git** (JavaScript for browser/Node: Git in the browser!), **gitoxide/gix** (Rust), **libgit2**-based **SwiftGit2**.
- **Pros:** no native dependency, embed easily, friendly licences, language-idiomatic APIs. **Cons:** feature gaps relative to Git; performance varies; must test against real `git` for interoperability.

### 4.4 How to choose
| Situation | Usually best |
|-----------|--------------|
| Need exact Git behaviour (hooks, LFS, submodules, credentials, rebase) and can ship/require `git` | **Command-line** |
| Desktop/mobile app that can't depend on a `git` install; need speed for many repo reads | **libgit2** binding |
| JVM service | **JGit** |
| Go service/CLI, want static binary | **go-git** (or shell out for rare features) |
| Python script/service, simple operations | **Dulwich** or subprocess; **pygit2** for performance |
| Browser/Electron | **isomorphic-git** |
| Hosting server needing push/pull protocol | real `git` (`receive-pack`/`upload-pack`) or a library that implements the protocol |
A pragmatic pattern: a library for reads and simple writes (fast, in-process) and a **subprocess fallback** for advanced operations.

### 4.5 Design patterns for "Git as a database"
- Store each record as a file (JSON/Markdown) in a repo; each change = a commit with author = the user; history, audit, undo come free.
- **Bare repo + no working tree**: write with plumbing (`hash-object`, `update-index` with `GIT_INDEX_FILE` set to a temp file, `write-tree`, `commit-tree`, `update-ref`), so concurrent app requests don't need a checkout. Use `update-ref <ref> <new> <old>` for **compare-and-swap**: it fails if someone else moved the branch (optimistic concurrency).
- Garbage/size: schedule `git gc`; avoid huge binaries (use LFS or external storage).
- Security: never run hooks from untrusted repos; treat repo content and config as untrusted (e.g. `core.fsmonitor`, `core.sshCommand`, filters, submodule URLs, and `safe.directory` exist because of this).

## 5. Command cheat sheet
| Command / API | Purpose |
|---------------|---------|
| `git cat-file --batch` / `--batch-check` | Long-lived object reader process |
| `git -C <dir> <cmd>` | Run in a specific repo |
| `git check-ref-format --branch <n>` | Validate names from users |
| `git update-ref <ref> <new> <old>` | Compare-and-swap ref update |
| `GIT_INDEX_FILE=<tmp> git update-index/write-tree` | Build trees without touching a real index |
| `git hash-object -w --stdin` | Store content, get id |
| `git commit-tree <tree> -p <parent> -m msg` | Create commit with no working tree |
| `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` | Hermetic config |
| `GIT_TERMINAL_PROMPT=0` | Never prompt |

## 6. Hands-on labs
Setup:
```bash
mkdir -p ~/git-labs/15 && cd ~/git-labs/15
export GIT_CONFIG_GLOBAL="$PWD/gitconfig" GIT_CONFIG_NOSYSTEM=1
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
LAB="$PWD"
```

### Lab 1 · Subprocess wrapper with safe patterns (tested)
```bash
cd "$LAB" && cat > gitwrap.py <<'PY'
import os, subprocess

class GitError(Exception): pass

def git(repo, *args, input=None, env=None, check=True):
    e = {**os.environ, "LC_ALL": "C", "GIT_TERMINAL_PROMPT": "0", **(env or {})}
    p = subprocess.run(["git", "-C", repo, "--no-pager", "-c", "color.ui=false", *args],
                       input=input, capture_output=True, env=e, timeout=30)
    if check and p.returncode:
        raise GitError(p.stderr.decode(errors="replace").strip())
    return p.stdout

def valid_branch(name):
    return subprocess.run(["git", "check-ref-format", "--branch", name], capture_output=True).returncode == 0

if __name__ == "__main__":
    import tempfile
    d = tempfile.mkdtemp()
    subprocess.run(["git", "init", "-q", d], check=True)
    git(d, "commit", "--allow-empty", "-qm", "root")
    print("branch:", git(d, "rev-parse", "--abbrev-ref", "HEAD").decode().strip())
    for name in ["feature/x", "-evil", "a..b", "ok_name", "sp ace"]:
        print(f"{name!r:14} valid={valid_branch(name)}")
    try:
        git(d, "checkout", "nope")                       # args are never interpreted by a shell
    except GitError as err:
        print("GitError:", err)
    # injection attempt: "--help" stays one literal ref argument after '--'
    try: git(d, "rev-parse", "--verify", "--end-of-options", "--help")
    except GitError as err: print("treated as a ref name:", str(err)[:40])
PY
python3 gitwrap.py
```
**Expected:** `branch: main`; `-evil`, `a..b`, `sp ace` invalid; `feature/x` and `ok_name` valid; a `GitError` for the missing branch; and `--help` is rejected as an unknown revision (`Needed a single revision`) instead of printing the help page.

### Lab 2 · Read objects with a long-lived `cat-file --batch` (tested)
```bash
cd "$LAB" && rm -rf db && git init -q db && cd db
for i in 1 2 3; do echo "version $i" > f.txt; git add f.txt; git commit -qm "c$i"; done
cat > ../batch.py <<'PY'
import subprocess, sys
p = subprocess.Popen(["git", "cat-file", "--batch"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
def read(obj):
    p.stdin.write(obj.encode() + b"\n"); p.stdin.flush()
    sha, typ, size = p.stdout.readline().split()
    data = p.stdout.read(int(size)); p.stdout.read(1)   # trailing newline
    return typ.decode(), data
for rev in ["HEAD", "HEAD~1", "HEAD~2", "HEAD:f.txt", "HEAD^{tree}"]:
    t, d = read(rev); print(f"{rev:12} {t:6} {len(d):4}B  {d[:30]!r}")
p.stdin.close(); p.wait()
PY
python3 ../batch.py
```
**Expected:** three commits, a blob `b'version 3\n'`, and a tree, all read through **one** process.

### Lab 3 · "Git as a database": commit without a working tree (tested)
```bash
cd "$LAB" && rm -rf kv.git && git init -q --bare kv.git && cd kv.git
put() {  # put <key> <value> <message>   — append/replace a file in the repo using only plumbing
  export GIT_INDEX_FILE="$PWD/tmp-index"
  parent=$(git rev-parse -q --verify refs/heads/main || true)
  [ -n "$parent" ] && git read-tree "$parent" || rm -f "$GIT_INDEX_FILE"
  blob=$(printf '%s\n' "$2" | git hash-object -w --stdin)
  git update-index --add --cacheinfo 100644,"$blob","$1"
  tree=$(git write-tree)
  commit=$(printf '%s\n' "$3" | GIT_AUTHOR_NAME=app GIT_AUTHOR_EMAIL=app@example.com git commit-tree "$tree" ${parent:+-p "$parent"})
  git update-ref refs/heads/main "$commit" ${parent:-0000000000000000000000000000000000000000}   # compare-and-swap
  rm -f "$GIT_INDEX_FILE"; unset GIT_INDEX_FILE
}
put users/ann.json '{"name":"Ann"}' "add Ann"
put users/bob.json '{"name":"Bob"}' "add Bob"
put users/ann.json '{"name":"Ann","admin":true}' "make Ann admin"
git log --oneline main; git ls-tree -r --name-only main
git show main:users/ann.json; git log -p --format=%s -- users/ann.json | head -12
# optimistic concurrency: a stale writer is rejected
stale=$(git rev-parse main~1)
git update-ref refs/heads/main "$(git rev-parse main)" "$stale" 2>&1 | head -1    # fatal: ... is at <sha> but expected <stale>
```
**Expected:** three commits and two files (a repo with no working directory); the full history of `ann.json`; the last command fails because the expected old value doesn't match.

### Lab 4 · Be the library: read a loose object in pure Python (tested)
```bash
cd "$LAB" && rm -rf raw && git init -q raw && cd raw
echo 'hello embedding' | git hash-object -w --stdin           # prints the id
echo 'x' > a && git add a && git commit -qm "raw demo"
cat > ../readobj.py <<'PY'
import sys, zlib, hashlib, os
def read_loose(git_dir, sha):
    path = os.path.join(git_dir, "objects", sha[:2], sha[2:])
    raw = zlib.decompress(open(path, "rb").read())
    header, _, body = raw.partition(b"\0")
    typ, size = header.split()
    assert int(size) == len(body)
    assert hashlib.sha1(raw).hexdigest() == sha, "corrupt object!"   # integrity check
    return typ.decode(), body
def parse_tree(body):
    i, out = 0, []
    while i < len(body):
        sp = body.index(b" ", i); nul = body.index(b"\0", sp)
        mode, name = body[i:sp].decode(), body[sp+1:nul].decode()
        out.append((mode, name, body[nul+1:nul+21].hex())); i = nul + 21
    return out
git_dir = sys.argv[1]
head = open(os.path.join(git_dir, "refs/heads/main")).read().strip()
typ, body = read_loose(git_dir, head); print(typ); print(body.decode())
tree_sha = body.split(b"\n")[0].split()[1].decode()
for mode, name, sha in parse_tree(read_loose(git_dir, tree_sha)[1]): print(mode, name, sha)
PY
python3 ../readobj.py .git
```
**Expected:** the commit text, then `100644 a <sha>`. (Packed objects require the pack format, which is why real libraries exist.) Flip a byte in an object file and rerun to see the integrity assertion fail.

### Lab 5 · Library tryout (🌐 on your machine)
In a virtualenv: `pip install pygit2 dulwich`. Re-create Lab 3's repo with pygit2 using the snippet in §4.2; then do `dulwich.porcelain.init/add/commit` in a scratch dir. Compare results with `git log` and `git fsck`. Note any behaviour that differs from the CLI (e.g. no hooks run).

## 7. Practice challenges
1. Extend `gitwrap.py` with a `status()` method returning `{path: code}` from `--porcelain=v1 -z`.
2. Add a per-repository lock (`fcntl.flock` on a lock file) so concurrent writers serialize.
3. Make Lab 3's `put` retry once with a fresh parent if the compare-and-swap fails.
4. Add a `delete <key>` operation to the database using `update-index --force-remove`.
5. Extend `readobj.py` to walk the whole history (follow `parent` lines) and print subjects.
6. Make `batch.py` accept a list of 1000 SHAs from `git rev-list --all` and compare time against spawning `git cat-file` 1000 times.
7. Write a one-page decision memo choosing an embedding strategy for an app of your choice (language, packaging, features needed, licence).

<details><summary>Hints</summary>

1. `git(d,"status","--porcelain=v1","-z").split(b"\0")`, with the first 2 chars as the code (renames have an extra path entry).
2. `with open(lock,"w") as f: fcntl.flock(f, fcntl.LOCK_EX); ...`.
3. Loop: re-read parent, rebuild, retry up to N times.
4. `git update-index --force-remove <path>` then `write-tree`.
5. Parse lines starting with `parent `; loop until none.
6. Use `time` around both; the batch process wins by a large factor.
7. Cover: need hooks/LFS? need a static binary? licence constraints? who installs `git`?
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| Building commands with string concatenation + `shell=True` | Argument arrays, `--`, `check-ref-format`; never trust ref/path input |
| Parsing human output | `--porcelain`, `--format`, `-z`, `LC_ALL=C` |
| Hung process waiting on credentials | `GIT_TERMINAL_PROMPT=0`, tokens or SSH keys, timeouts |
| `index.lock exists` from concurrent callers | Serialize writers; remove a stale lock only when no git process runs |
| Library "doesn't run my hooks" | Libraries don't trigger hooks; call them yourself or use the CLI |
| Behaviour differs from `git` | Compare with the CLI; pin library version; add fallback to subprocess |
| Repo from untrusted users executes code | Don't run hooks/filters/fsmonitor from untrusted repos; use `safe.directory` correctly; hermetic config |
| Writing to a non-bare repo's checked-out branch with plumbing | Working tree/index become stale: use a bare repo for app data |
| App DB repo grows forever | `git gc`, avoid big binaries, consider shallow/partial approaches or archiving |

## 9. Real-world use cases
- Wikis and CMSs (Gollum, Gitea-based docs) storing pages as files with full history.
- IDE/GUI clients (libgit2-based) with fast status/diff.
- CI/CD and GitOps controllers (go-git/JGit) cloning, diffing and committing manifests.
- Data/ML versioning, config stores, audit-logged admin tools.
- Code-review and hosting platforms driving `git` processes and libgit2/JGit for repo operations.

## 10. Self-check quiz
1. Name the three embedding approaches and one trade-off each.
2. Why use an argument array, `--` and `check-ref-format`?
3. What's special about libgit2's licence?
4. What does `update-ref <ref> <new> <old>` give you in a concurrent app?
5. Why use `cat-file --batch` instead of many `cat-file` invocations?
6. Which `git` features may be missing or different in a library?
7. Why is a bare repository the right target for an application database?

<details><summary>Answers</summary>

1. CLI (complete but needs git, process overhead), libgit2 bindings (fast, in-process, partial feature set), native reimplementation (no native deps, feature gaps).
2. Prevent shell/option injection from user-controlled names.
3. GPLv2 with a linking exception, so proprietary software may link it.
4. Compare-and-swap: fails if the ref isn't at the expected value, giving optimistic concurrency.
5. One process, no repeated start-up cost.
6. Hooks, some merge/rebase/worktree/partial-clone features, credential helper and config-include behaviours.
7. No working tree/index to drift; safe concurrent plumbing writes; no checked-out branch to protect.
</details>

## 11. Mastery checklist & next step
- [ ] Choose and defend an embedding strategy for a product.
- [ ] Wrap `git` safely (no injection, hermetic, non-interactive, locked writers).
- [ ] Commit to a bare repo using plumbing only, with compare-and-swap.
- [ ] Explain what a Git library does for you (object read/write, compression, hashing, packs, refs).

**Next:** [16-appendix-c-git-command-reference.md](16-appendix-c-git-command-reference.md): every command grouped by task, linking back to the lesson where you learned it.
