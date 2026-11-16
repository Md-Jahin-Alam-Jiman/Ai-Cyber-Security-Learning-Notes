# 06 · GitHub: Collaboration at Scale
> Book reference: Pro Git, Chapter 6, "Account Setup and Configuration", "Contributing to a Project", "Maintaining a Project", "Managing an organization", "Scripting GitHub" (book pp. 166–217)
> Level: Intermediate · Est. time: 4 h
> ⚠️ GitHub's web interface changes often. The *concepts* and the Git commands are stable; button names may differ. Steps marked 🌐 need github.com and were **not testable in this sandbox**. Parts that are plain Git (pull-request refs, webhook handling) are tested.

## 1. Why this matters
GitHub is the largest Git host and the default place where open-source and many company projects live. Knowing its model (forks, pull requests, issues, reviews, organizations, API/webhooks) is what lets you contribute to any project and run a team repository. Everything rests on the Git skills from [05-distributed-git-workflows.md](05-distributed-git-workflows.md).

## 2. Prerequisites
- [05-distributed-git-workflows.md](05-distributed-git-workflows.md) (fork + topic branch + pull request model)
- [04-git-on-the-server.md](04-git-on-the-server.md) (SSH keys, protocols)
- A free GitHub account for the 🌐 labs.

## 3. Learning objectives
- [ ] Create and secure an account: SSH key (or HTTPS token), verified email, 2FA.
- [ ] Fork, clone, branch, push, and open a pull request (the **GitHub flow**).
- [ ] Iterate on a PR, use cross-references, mentions, Markdown, task lists.
- [ ] Keep a fork in sync with upstream.
- [ ] As a maintainer: create repos, add collaborators, manage/merge PRs, check PRs out locally via `refs/pull/*`.
- [ ] Use special files (README, CONTRIBUTING, LICENSE, templates, CODEOWNERS).
- [ ] Manage an organization: teams, permissions, audit log.
- [ ] Automate with webhooks, the REST API, and `gh`.

## 4. Core concepts

### 4.1 Account setup and configuration
- **Sign up**, then **verify your email**. Commits are attributed to you on GitHub if the commit's `user.email` matches a verified email on your account. Privacy: use the `ID+username@users.noreply.github.com` address (Settings → Emails) as `user.email` and enable "Block command line pushes that expose my email".
- **Authentication for Git** (💡 modern note: GitHub no longer accepts account passwords for Git over HTTPS):
  - **SSH** (recommended): `ssh-keygen -t ed25519 -C "you@example.com"` → paste `~/.ssh/id_ed25519.pub` into *Settings → SSH and GPG keys* → test with `ssh -T git@github.com` ("Hi username! You've successfully authenticated…"). Remote form: `git@github.com:owner/repo.git`.
  - **HTTPS**: use a **Personal Access Token (PAT)** or a credential helper/Git Credential Manager (see credential storage in [10-git-tools-submodules-bundling-replace-and-credentials.md](10-git-tools-submodules-bundling-replace-and-credentials.md)); `gh auth login` sets this up for you.
- **Two-factor authentication (2FA)**: Settings → Password and authentication. Use an authenticator app, security key or passkey; save recovery codes. Required for contributors on many accounts.
- **Avatar/profile**: cosmetic, but helps collaborators recognize you.
- **Signed commits** show a "Verified" badge (GPG/SSH/S/MIME signing; see [07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md)).

### 4.2 Forking and the GitHub flow
A **fork** is a server-side copy of a repo under your account, linked to the original ("upstream"). You can't push upstream, but you can push to your fork and ask upstream to pull.

**The GitHub flow** (centered on pull requests; works for open source and teams):
1. Fork (or, with write access, just branch) → clone.
2. Create a **topic branch** from `main`.
3. Commit your changes (one logical change per PR).
4. Push the branch to your fork.
5. Open a **Pull Request (PR)** into the upstream's `main` (the page shows a diff against the merge-base, like `git diff main...topic`).
6. Discuss and iterate with commits to the same branch; the PR updates automatically.
7. Maintainer merges (or closes). Delete the branch.

Why it's good: reviewers see the whole change, CI runs on it, discussion lives next to the code, and nothing touches `main` until approved. Drafts (**Draft PR**) signal "not ready for review".

### 4.3 Creating and iterating on a pull request
- After pushing, GitHub offers a "Compare & pull request" banner; or use *Pull requests → New*. Fill in a **title** and a **description** (what/why, how tested, link to issue). Pull request templates (`.github/PULL_REQUEST_TEMPLATE.md`) prefill this.
- **Mergeability:** GitHub shows if there are conflicts. If main moved, update your branch (`git fetch upstream; git rebase upstream/main` then `git push --force-with-lease`, or merge `upstream/main` into the topic). The book recommends merging or rebasing so the PR "merges cleanly".
- **Iteration:** push more commits to the same branch. Reviewers can comment on lines, request changes, approve. Maintainers often ask you to squash; do it locally with interactive rebase ([08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md)) and force-push your own branch only.
- **Pull requests on pull requests:** you can open a PR targeting someone else's PR branch (change the *base* to their branch) to propose edits to their change.
- **Cross-references and mentions:**

| Syntax | Effect |
|--------|--------|
| `#123` | link to issue/PR 123 in this repo |
| `owner/repo#123` | link to another repo's issue |
| `a5c3785` (7+ chars of SHA) | link to a commit |
| `@username` | notifies the person; `@org/team` notifies a team |
| `Fixes #123`, `Closes #123`, `Resolves #123` in a PR/commit message | auto-closes issue when merged into the default branch |

- **GitHub Flavored Markdown:** task lists `- [ ] item` (checkboxes with progress), fenced code blocks with language, `> quoted reply` (select text and press `r` to quote), `:emoji:`, images (drag and drop), tables, `` ```suggestion `` blocks (reviewer proposes a one-click change).
- **Keeping your fork up to date:**
```bash
git remote add upstream https://github.com/ORIGINAL/repo.git
git fetch upstream
git switch main && git merge --ff-only upstream/main   # or: git rebase upstream/main
git push origin main
```
  (or "Sync fork" on GitHub.) Never commit directly to your fork's `main`; branch per change.

### 4.4 Maintaining a project
- **Create a repo:** New repository → name, visibility (public/private), optional README, `.gitignore`, license. Push an existing repo: `git remote add origin git@github.com:you/proj.git && git push -u origin main`.
- **Collaborators:** Settings → Collaborators (personal repo: read/write access by invitation). For organizations use teams (§4.5).
- **Managing pull requests:**
  - Notifications arrive by email/web: reply to the email to comment. Email headers help filtering. Web notifications page; *Watch* settings (all activity / participating / ignore).
  - **Merge options:** *Merge commit* (keeps full history), *Squash and merge* (one commit, clean history), *Rebase and merge* (linear, rewrites commits). Choose per repo/PR; a team should agree.
  - **Branch protection / rulesets** (💡 modern): require reviews, status checks (CI), signed commits; block force pushes to `main`.
- **Pull request refs:** GitHub advertises each PR as pseudo-branches in the repo:
  - `refs/pull/<n>/head`: the tip of the PR branch as pushed.
  - `refs/pull/<n>/merge`: the result of merging it into the base (tested merge commit).
  You can fetch a PR **without adding the contributor's fork as a remote**:
```bash
git fetch origin pull/958/head:pr-958          # one PR into local branch pr-958
git switch pr-958                              # review/test locally
# or fetch ALL PRs as remote-tracking branches:
git config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pr/*'
git fetch                                      # now origin/pr/958 etc.
git ls-remote origin                           # lists refs/pull/*/head and /merge
```
  This is exactly the "refspec" mechanism explained in [13-git-internals-plumbing-and-objects.md](13-git-internals-plumbing-and-objects.md).
- **Special files** (root, `docs/` or `.github/`): 
  - `README.md` is rendered on the project page; say what it is, how to install/use/contribute.
  - `CONTRIBUTING.md` is linked when someone opens a PR or issue: coding style, tests, process.
  - 💡 `LICENSE`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CODEOWNERS` (auto-request reviewers), issue/PR templates, `.github/workflows/*.yml` (GitHub Actions CI).
- **Project administration:** change default branch, transfer ownership, rename, archive, delete (type the name to confirm), manage webhooks, deploy keys, secrets.

### 4.5 Managing an organization
- **Organizations** hold repos for a company/community. Account types: **Owners** (full admin) and **members**. Org-level settings, billing and SSO live here.
- **Teams** group members (e.g. `frontend`, `docs`) and get **permissions per repo** (read / triage / write / maintain / admin). Teams can be nested, @-mentioned (`@acme/frontend`), and mapped to CODEOWNERS.
- **Two-factor requirement**, base permissions, who can create repos, fork private repos: set in org settings.
- **Audit log:** who did what and when (member added, repo deleted, permission change, hook created); filterable and exportable on paid plans.

### 4.6 Scripting GitHub
Three layers for automation:
1. **Webhooks** (the book's "Services and Hooks": Services are obsolete): GitHub sends an HTTP POST to your URL when an event happens (`push`, `pull_request`, `issues`, `issue_comment`, `release`, …). Payload is JSON; headers include `X-GitHub-Event`, `X-GitHub-Delivery` and `X-Hub-Signature-256` = `sha256=` + HMAC-SHA256(secret, raw body). **Always verify the signature** and respond quickly (2xx). Redeliver from the webhook's "Recent Deliveries" page when debugging.
2. **REST/GraphQL API** (`https://api.github.com`): authenticate with a token (`Authorization: Bearer <token>`, scope it minimally; fine-grained PATs preferred). Common calls:
```bash
curl -s -H "Authorization: Bearer $GH_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" \
     https://api.github.com/repos/OWNER/REPO/pulls?state=open | jq '.[].title'
# comment on a PR (PR comments use the issues endpoint)
curl -s -X POST -H "Authorization: Bearer $GH_TOKEN" \
     -d '{"body":"Thanks! CI looks green."}' \
     https://api.github.com/repos/OWNER/REPO/issues/7/comments
# set a commit status (what CI integrations do)
curl -s -X POST -H "Authorization: Bearer $GH_TOKEN" \
     -d '{"state":"success","description":"Tests passed","context":"ci/mytests"}' \
     https://api.github.com/repos/OWNER/REPO/statuses/<SHA>
# merge a PR
curl -s -X PUT -H "Authorization: Bearer $GH_TOKEN" -d '{"merge_method":"squash"}' \
     https://api.github.com/repos/OWNER/REPO/pulls/7/merge
```
   Statuses appear on the PR as checks and can be made **required** by branch protection. Paginate with `?per_page=100&page=N`; respect rate limits.
3. **`gh` CLI and GitHub Actions** (💡 modern): `gh auth login`, `gh repo fork --clone`, `gh pr create`, `gh pr checkout 7`, `gh pr list`, `gh pr merge 7 --squash`, `gh api repos/OWNER/REPO/pulls`. Actions run workflows (tests, deploys) on events, replacing most hook-based glue.

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `ssh -T git@github.com` | Test SSH auth | After adding your key |
| `git remote add upstream <url>` | Track original repo | Fork workflow |
| `git fetch upstream && git rebase upstream/main` | Sync your topic/fork | Before PR/after main moves |
| `git push -u origin topic` | Publish branch to your fork | Before opening PR |
| `git push --force-with-lease` | Update PR branch after rebase | Own branch only |
| `git fetch origin pull/N/head:pr-N` | Get a PR locally | Review/test |
| `git ls-remote origin` | List remote refs incl. PRs | Debug |
| `gh pr create / checkout / merge` | PR operations from the CLI | Speed |
| `gh repo fork --clone` | Fork + clone | Start contributing |
| `curl -H "Authorization: Bearer $TOKEN" https://api.github.com/...` | REST API | Scripting |

## 6. Hands-on labs

### Lab 1 · Pull-request refs, simulated locally (tested)
GitHub's `refs/pull/N/head` is just a ref on the server. We reproduce it with a bare repo to learn the mechanism:
```bash
mkdir -p ~/git-labs/06 && cd ~/git-labs/06
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main

git init --bare gh.git                     # pretend github.com/owner/repo
git clone gh.git dev && cd dev
echo a > a && git add . && git commit -m one && git push origin main
git switch -c topic && echo t > t && git add . && git commit -m "PR work"
TIP=$(git rev-parse HEAD) && git switch main
git push origin topic                      # contributor's branch arrives (GitHub would hold it in a fork)
git -C ../gh.git update-ref refs/pull/1/head "$TIP"     # what GitHub does when PR #1 is opened
git -C ../gh.git update-ref refs/pull/1/merge "$TIP"    # (GitHub stores a test-merge commit here)
cd .. && git clone gh.git reviewer && cd reviewer
git ls-remote origin | grep pull           # refs/pull/1/head and /merge
git fetch origin pull/1/head:pr-1          # one PR into a local branch
git log --oneline pr-1 -1                  # "PR work"
git config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pr/*'
git fetch && git branch -r                 # origin/pr/1 appears
git switch -c review origin/pr/1
git config --get-all remote.origin.fetch
```
**Expected:** `ls-remote` lists both pull refs; `origin/pr/1` shows up after the second fetch. This is how `gh pr checkout` and many CI systems get PR code.

### Lab 2 · A webhook receiver with signature verification (tested)
```bash
cd ~/git-labs/06
cat > receiver.py <<'EOF'
#!/usr/bin/env python3
"""Minimal GitHub-style webhook receiver (learning aid). Usage: WEBHOOK_SECRET=... python3 receiver.py [port]"""
import hashlib, hmac, json, os, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

SECRET = os.environ.get("WEBHOOK_SECRET", "s3cret").encode()

class Hook(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        expected = "sha256=" + hmac.new(SECRET, body, hashlib.sha256).hexdigest()
        given = self.headers.get("X-Hub-Signature-256", "")
        if not hmac.compare_digest(expected, given):
            self.send_response(401); self.end_headers(); self.wfile.write(b"bad signature"); return
        event = self.headers.get("X-GitHub-Event", "?")
        data = json.loads(body)
        if event == "push":
            print(f"push to {data['ref']} by {data['pusher']['name']}: {len(data['commits'])} commit(s)", flush=True)
        elif event == "pull_request":
            print(f"PR #{data['number']} {data['action']}: {data['pull_request']['title']}", flush=True)
        else:
            print(f"event {event} ignored", flush=True)
        self.send_response(204); self.end_headers()
    def log_message(self, *a): pass

HTTPServer(("127.0.0.1", int(sys.argv[1]) if len(sys.argv) > 1 else 8090), Hook).serve_forever()
EOF
python3 receiver.py 8090 &                  # leave running; prints events
sleep 1
BODY='{"ref":"refs/heads/main","pusher":{"name":"jane"},"commits":[{"id":"a1"},{"id":"b2"}]}'
SIG="sha256=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac s3cret | awk '{print $2}')"
curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8090 \
     -H "X-GitHub-Event: push" -H "X-Hub-Signature-256: $SIG" -d "$BODY"       # 204
curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8090 \
     -H "X-GitHub-Event: push" -H "X-Hub-Signature-256: sha256=bad" -d "$BODY" # 401
kill %1
```
**Expected:** `204` (and the receiver prints `push to refs/heads/main by jane: 2 commit(s)`), then `401` for the forged signature.
🌐 Real use: expose it with a tunnel (e.g. `ngrok`/`cloudflared`) and add it under *Repo → Settings → Webhooks* (content type `application/json`, same secret). Push and read *Recent Deliveries*.

### Lab 3 · 🌐 Account, SSH and 2FA (untested here)
1. Create an account; verify email. Enable 2FA and download recovery codes.
2. `ssh-keygen -t ed25519 -C "you@example.com"`, add the **public** key under *Settings → SSH and GPG keys*.
3. `ssh -T git@github.com`. Expect the "successfully authenticated" greeting. 
4. Set `git config --global user.email "ID+username@users.noreply.github.com"`.
5. Alternatively for HTTPS: `gh auth login` (or create a fine-grained PAT) and clone an HTTPS URL.

### Lab 4 · 🌐 Your first pull request (practice repo)
Use a repository made for practice (the classic is `octocat/Spoon-Knife`) or your own second account/repo.
1. **Fork** it (button, top right). Clone *your fork*: `git clone git@github.com:YOU/Spoon-Knife.git && cd Spoon-Knife`.
2. `git remote add upstream https://github.com/octocat/Spoon-Knife.git`.
3. `git switch -c fix-typo`; edit a file; commit with a clear message.
4. `git push -u origin fix-typo`.
5. Click **Compare & pull request**. Write a title and description. (Practice repos usually won't merge; the goal is the flow.) CLI equivalent: `gh pr create --fill`.
6. Add a review comment on a line (reviewer account), request a change, push a fixup commit, watch the PR update.
7. Add `Fixes #1` in the description of a PR on a repo you own with an issue #1; merge; see the issue auto-close.

### Lab 5 · 🌐 Maintaining your own repo
1. Create a repo `pro-git-lab` (public, with README). `git clone` it.
2. Add `CONTRIBUTING.md` and `.github/PULL_REQUEST_TEMPLATE.md` (what/why/how tested checklist). Push to `main`.
3. Settings → Branches (or Rulesets): protect `main` (require a PR + 1 approval). Try pushing directly to `main` and see it rejected.
4. Invite a collaborator (second account). They branch, push, and open a PR. You review with a line comment + suggestion block; they apply the suggestion.
5. Merge with each method in three separate PRs: **merge commit**, **squash**, **rebase**. Compare `git log --graph --oneline` afterwards.
6. Check a PR out locally without adding the contributor's remote: `git fetch origin pull/1/head:pr-1` (Lab 1 mechanism) or `gh pr checkout 1`.
7. Add a webhook (Lab 2) and an Actions workflow `.github/workflows/ci.yml` that runs `echo ok` on `pull_request`; make it a required status check.

### Lab 6 · 🌐 API and `gh` scripting
```bash
export GH_TOKEN=<fine-grained token with Pull requests + Issues write on your repo>
curl -s -H "Authorization: Bearer $GH_TOKEN" https://api.github.com/repos/YOU/pro-git-lab/pulls | jq '.[] | {number,title,user:.user.login}'
curl -s -X POST -H "Authorization: Bearer $GH_TOKEN" -d '{"body":"Looks good!"}' \
     https://api.github.com/repos/YOU/pro-git-lab/issues/1/comments
SHA=$(git rev-parse HEAD)
curl -s -X POST -H "Authorization: Bearer $GH_TOKEN" -d '{"state":"success","context":"lab/check","description":"ok"}' \
     https://api.github.com/repos/YOU/pro-git-lab/statuses/$SHA
gh pr list; gh api repos/YOU/pro-git-lab/pulls --jq '.[].title'
```
**Expected:** JSON listing PRs, a new comment on issue/PR 1, and a "lab/check" status visible on the commit. Reading the response headers (`curl -i`) shows `X-RateLimit-Remaining`.

### Lab 7 · Organization thought-lab (🌐 free orgs are fine)
Create an org; create teams `devs` and `docs`; give `devs` write and `docs` read on a repo; verify a `docs` member cannot push; read the audit log (or *Settings → Audit log*) for your own actions.

## 7. Practice challenges
1. Contribute a real one-line fix (typo, docs) to an open-source project that labels issues `good first issue`, following its CONTRIBUTING file.
2. Write a script that fetches all open PRs of a repo into local branches `pr/<n>` using only `git ls-remote` and `git fetch`.
3. Extend the Lab 2 receiver to run `git -C /path fetch` when a `push` event for `refs/heads/main` arrives (security: validate signature first; never shell-interpolate payload data).
4. Squash a 5-commit PR to one commit locally and update the open PR without closing it.
5. Set up `CODEOWNERS` so that changes to `docs/` automatically request review from a team.
6. Explain which merge method you would choose for (a) a library with a linear public history, (b) a monorepo with many short-lived branches, (c) a repo where release tooling relies on merge commits.

<details><summary>Solutions</summary>

1. Fork → branch → commit → PR; mention the issue (`Fixes #N`). Be polite; maintainers volunteer.
2. `git ls-remote origin 'refs/pull/*/head' | while read sha ref; do n=$(echo $ref | cut -d/ -f3); git fetch origin "$ref:pr/$n"; done`
3. After verifying HMAC and event type/ref, run a fixed command with `subprocess.run(["git","-C","/path","fetch"], check=True)`; no `shell=True`, no payload data in the command.
4. `git rebase -i origin/main` (squash), then `git push --force-with-lease` to the PR branch; the PR updates.
5. `.github/CODEOWNERS`: `/docs/ @acme/docs-team`; enable "Require review from Code Owners" in branch protection.
6. (a) Rebase and merge or squash; (b) squash; (c) merge commit.
</details>

## 8. Common mistakes & how to recover
| Mistake | Fix |
|---------|-----|
| `Permission denied (publickey)` | Add the public key to GitHub; `ssh -vT git@github.com`; check the remote uses `git@github.com:` |
| HTTPS push asks for a password and fails | Passwords aren't accepted: use a PAT, `gh auth login` or Git Credential Manager |
| Commits don't show your avatar/contribution graph | `user.email` isn't a verified email on your account |
| PR has conflicts | Rebase/merge `upstream/main` into your topic and push (`--force-with-lease` after a rebase) |
| Made the PR from your fork's `main` | Create a topic branch, reset `main` to `upstream/main` (`git switch -c topic; git switch main; git reset --hard upstream/main`) |
| Force-pushed to someone else's branch | Don't; coordinate. Use `--force-with-lease` only on your own |
| Committed a secret and pushed | Rotate it first; then clean history (see filter-repo notes in [08-git-tools-rewriting-history-and-reset.md](08-git-tools-rewriting-history-and-reset.md)); GitHub secret scanning may auto-flag |
| Webhook returns 401/timeouts | Verify the secret/HMAC over the *raw* body; reply 2xx fast, do work async |
| API 403 / rate limited | Check token scopes and `X-RateLimit-*` headers; use authenticated requests |
| Lost track of a PR's code after the branch was deleted | `refs/pull/N/head` keeps it: `git fetch origin pull/N/head` |

## 9. Real-world use cases
- Open source contribution and maintainership: forks, PR review, issue triage, release management.
- Company workflow: protected `main`, required reviews/CI, CODEOWNERS, squash merges, audit logging.
- Automation: bots that label PRs, post status checks, deploy on merge; webhook-driven mirrors or chatops.
- Careers: your GitHub profile is often part of your portfolio; consistent PR hygiene matters.

## 10. Self-check quiz
1. What is a fork, and how does it differ from a clone?
2. What is the GitHub flow in one sentence?
3. What are `refs/pull/N/head` and `refs/pull/N/merge`?
4. How do you make GitHub automatically close issue 42 when a PR merges?
5. Why must you verify `X-Hub-Signature-256` on a webhook?
6. Name the three merge methods and one trade-off each.
7. Why not commit directly to your fork's `main`?
8. What does `git push --force-with-lease` protect you from?

<details><summary>Answers</summary>

1. A server-side copy of a repo under your account (linked to the original); a clone is a local copy.
2. Branch from `main`, commit, push, open a PR, discuss, merge, delete the branch.
3. Server-side refs holding the PR branch tip and the tested merge result.
4. Put `Fixes #42` (or Closes/Resolves) in the PR description or a commit message merging into the default branch.
5. To ensure the request really came from GitHub and wasn't forged (HMAC of the raw body with the shared secret).
6. Merge commit (full history, noisy graph); squash (clean history, loses individual commits); rebase (linear, rewrites hashes).
7. It makes it hard to sync with upstream and to send separate PRs.
8. Overwriting remote commits you haven't seen: it fails if the remote ref changed unexpectedly.
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Set up SSH/2FA and push to GitHub.
- [ ] Fork, branch, PR, iterate, and keep the fork synced.
- [ ] Fetch any PR locally via `refs/pull/N/head`.
- [ ] Choose merge methods, branch protection and CODEOWNERS for a team repo.
- [ ] Verify and handle a webhook; call the API with a scoped token.

**Next:** [07-git-tools-revision-selection-staging-stashing.md](07-git-tools-revision-selection-staging-stashing.md): the power-user toolkit begins: precise revision syntax, interactive staging, stash, signing and searching.
