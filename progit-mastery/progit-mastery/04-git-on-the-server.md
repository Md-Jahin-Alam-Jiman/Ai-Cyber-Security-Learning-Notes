# 04 · Git on the Server
> Book reference: Pro Git, Chapter 4, "The Protocols", "Getting Git on a Server", "Generating Your SSH Public Key", "Setting Up the Server", "Git Daemon", "Smart HTTP", "GitWeb", "GitLab", "Third Party Hosted Options" (book pp. 105–125)
> Level: Intermediate · Est. time: 3 h

## 1. Why this matters
Git is distributed, but teams still need a shared, always-on place to push to. Understanding bare repositories, the four transport protocols and basic access control lets you run your own Git server, debug "permission denied / hung up unexpectedly" errors, and judge when a hosted service (GitHub, GitLab, Bitbucket) is the better choice.

## 2. Prerequisites
- [02-git-basics.md](02-git-basics.md) (remotes, push/pull)
- [03-git-branching-and-merging.md](03-git-branching-and-merging.md) (remote branches)
- Comfort with Linux basics: users, groups, file permissions, SSH.

## 3. Learning objectives
- [ ] Compare the Local, HTTP(S), SSH and Git protocols (auth, read/write, speed, trade-offs).
- [ ] Explain a **bare repository** and create one (`git init --bare`, `git clone --bare`).
- [ ] Publish a repository to a server and let teammates clone/push.
- [ ] Generate an SSH key pair and set up `authorized_keys` access for a shared `git` user.
- [ ] Restrict that user to Git-only with `git-shell`.
- [ ] Serve read-only repos with `git daemon` and `git-daemon-export-ok`.
- [ ] Describe how smart HTTP works (`git-http-backend`) and its Apache setup.
- [ ] Know what GitWeb, GitLab, and hosted options provide.

## 4. Core concepts

### 4.1 The four protocols
| Protocol | URL example | Read | Write | Auth | Notes |
|----------|-------------|------|-------|------|-------|
| **Local** | `/srv/git/proj.git`, `file:///srv/git/proj.git` | ✔ | ✔ | filesystem permissions | Shared disk/NFS. Simple, but access to the mount is needed. `file://` behaves like a network clone (copies objects cleanly); a bare path may use hardlinks (fast). |
| **SSH** | `ssh://user@host/srv/git/proj.git`, `user@host:srv/git/proj.git` | ✔ | ✔ | SSH keys/passwords | Easiest to set up securely; encrypted; works behind firewalls; **no anonymous access**. |
| **HTTP(S) smart** | `https://host/proj.git` | ✔ | ✔ | HTTP auth, tokens, SSO | Works through most firewalls, same URL for read/write/anon, can be cached/proxied. Server setup is more involved. |
| **HTTP dumb** | static web server | ✔ | ✗ (needs WebDAV) | — | Legacy; requires `git update-server-info`; rarely used. |
| **Git** (`git://`) | `git://host/proj.git` | ✔ | ✗ by default | **none** | Fastest, unauthenticated, port 9418. Read-only public mirrors. Not encrypted. |

Pros and cons summary:
- **Local:** no network config; simple. Poor for remote teams; shared-filesystem access can be slow/insecure.
- **SSH:** secure, one setup. Cannot serve anonymous read-only clones.
- **Smart HTTP:** secure, standard ports, one URL; credential handling can be fiddly ([10-git-tools-submodules-bundling-replace-and-credentials.md](10-git-tools-submodules-bundling-replace-and-credentials.md) covers credential helpers).
- **Git protocol:** fastest; no auth, hard to set up on some platforms, port 9418 may be blocked.

### 4.2 Bare repositories
A normal repo has a working tree plus `.git/`. A **bare** repo is *only* the contents of `.git` (no checked-out files), conventionally named `proj.git`. Servers use bare repos because pushing into a non-bare repo's checked-out branch would conflict with the working tree (Git refuses to update the current branch of a non-bare repo by default).

```bash
git init --bare proj.git                     # new, empty, bare
git clone --bare existing_proj proj.git      # bare copy of existing repo
git clone --bare existing_proj.git/.git ...  # same idea
```
Publish an existing repo to a server (SSH example, 🌐 untested here):
```bash
git clone --bare my_project my_project.git
scp -r my_project.git user@git.example.com:/srv/git
# anyone with SSH + read access:
git clone user@git.example.com:/srv/git/my_project.git
```
If users have **write access on that directory**, they can push. A simple way to add a project: `ssh user@host "cd /srv/git && mkdir proj.git && cd proj.git && git init --bare"` then `git remote add origin user@host:/srv/git/proj.git` and `git push origin main`.

Shared access via **groups**: `git init --bare --shared` sets group-writable permissions and `core.sharedRepository`, so several users in one Unix group can push to the same repo.

### 4.3 Small setups
- **Simple setup:** a Linux host with SSH and a directory of bare repos, plus Unix accounts in a group. Fine for small teams.
- **Shared-account model:** one `git` user; each developer's **public** key is appended to `~git/.ssh/authorized_keys`. Everyone connects as `git@host`; commits still record each person's own name/email (identity comes from commit metadata, not the SSH user). Remove access by deleting their key line.
- **Lock it down:** change the `git` user's shell to `git-shell` (listed in `/etc/shells`) so SSH can run only Git commands (no interactive login): `sudo chsh git -s $(which git-shell)`. Optionally add scripts in `~git/git-shell-commands/` (e.g., `help`, `list`) to offer limited interactive commands. Port forwarding and X11 are also commonly disabled with `no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty` options on each key line.
- Central auth: use LDAP/PAM to avoid managing local users.

### 4.4 SSH keys
SSH uses a key pair: **private** key stays on your machine; **public** key goes on servers.
```bash
cd ~/.ssh && ls                        # id_ed25519 (private) and id_ed25519.pub (public)
ssh-keygen -t ed25519 -C "you@example.com"     # 💡 modern default; book shows RSA (id_rsa)
cat ~/.ssh/id_ed25519.pub              # this is what you hand to the admin
ssh-add ~/.ssh/id_ed25519              # load into ssh-agent to avoid retyping the passphrase
```
Always set a passphrase. Never share the file without `.pub`.

### 4.5 Server setup walk-through (🌐 untested here: needs sshd and root)
```bash
sudo adduser git
su git
cd ~
mkdir .ssh && chmod 700 .ssh
touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys
cat /tmp/id_ed25519.john.pub >> ~/.ssh/authorized_keys     # one per developer
mkdir -p /srv/git/project.git && cd /srv/git/project.git && git init --bare
# on developer machine:
git init; git add .; git commit -m "Initial"
git remote add origin git@gitserver:/srv/git/project.git
git push origin main
```
Then everyone can `git clone git@gitserver:/srv/git/project.git`. Use `chsh` to git-shell afterwards.

### 4.6 Git daemon (the `git://` protocol)
```bash
git daemon --reuseaddr --base-path=/srv/git/ /srv/git/
```
- `--base-path`: lets clients write `git://host/proj.git` rather than the full path.
- Only repos containing a file named `git-daemon-export-ok` are served (unless `--export-all`).
- Port **9418** must be open. Writes are off by default; `--enable=receive-pack` allows anonymous pushes (**dangerous**).
- Run under systemd (unit file with `ExecStart=/usr/bin/git daemon ...`, `User=git`, `Restart=always`) or xinetd, so it's supervised and starts on boot.
- Use for fast read-only access (CI servers, public mirrors on a trusted network).

### 4.7 Smart HTTP
Smart HTTP runs the same protocol as SSH/Git but over HTTP(S) via **`git-http-backend`** (a CGI program installed with Git). Clients need only a URL: `https://host/git/project.git`. 
Minimal Apache configuration (🌐 untested here):
```apache
SetEnv GIT_PROJECT_ROOT /srv/git
SetEnv GIT_HTTP_EXPORT_ALL
ScriptAlias /git/ /usr/lib/git-core/git-http-backend/

<Files "git-http-backend">
    AuthType Basic
    AuthName "Git Access"
    AuthUserFile /srv/git/.htpasswd
    Require expr !(%{QUERY_STRING} -strmatch '*service=git-receive-pack*' || %{REQUEST_URI} =~ m#/git-receive-pack$#)
    Require valid-user
</Files>
```
Meaning: reads (fetch/clone) are open; writes (`git-receive-pack`) need a valid user. Needed modules: `cgi`, `alias`, `env`, `rewrite`, plus `htpasswd -c /srv/git/.htpasswd user`. Ensure the web server user owns/can write the repos. Enable pushes where no auth user is set via `git config http.receivepack true` in the repo. Always use HTTPS in production.

### 4.8 GitWeb
A simple CGI web viewer for repositories (browse commits, trees, diffs). Quick local preview: `git instaweb --httpd=webrick` (needs a web server like lighttpd/apache/webrick/mongoose; run `git instaweb --stop`). For production, configure via your web server. It's basic and read-only.

### 4.9 GitLab and other platforms
- **GitLab** (self-hosted or SaaS): full web UI with users, groups, projects, access levels, merge requests, CI, issue tracking, hooks (project-level and system-level), wikis. Installation: Omnibus package (Linux), Docker, Helm. Admin area: users (accounts, blocking), groups (namespaces, permissions), projects (visibility, members, protected branches), hooks.
- Others self-hosted: Gitea/Forgejo, Gogs, Bitbucket Data Center, GitHub Enterprise Server.
- **Third-party hosting** (GitHub, GitLab.com, Bitbucket, Azure DevOps, SourceHut): no server upkeep, collaboration features, backups; trade-offs: cost for private/large use, data governance, vendor dependency. [06-github-collaboration.md](06-github-collaboration.md) is next after workflows.
- Decision hints: tiny/private team → SSH + bare repos; open-source/public → hosted; compliance/air-gapped → self-hosted GitLab/Gitea.

## 5. Command cheat sheet
| Command | What it does | When to use |
|---------|--------------|-------------|
| `git init --bare proj.git` | Empty bare repo | Create a server repo |
| `git init --bare --shared=group` | Bare repo with group-write perms | Multi-user shared dir |
| `git clone --bare src proj.git` | Bare copy of a repo | Publish an existing project |
| `git remote add origin user@host:/srv/git/proj.git` | Point at server | After creating repo |
| `scp -r proj.git user@host:/srv/git` | Copy to server | Quick publish |
| `ssh-keygen -t ed25519 -C "mail"` | New key pair | Before asking for access |
| `git daemon --base-path=... [--export-all]` | Serve `git://` | Read-only fast access |
| `touch git-daemon-export-ok` | Mark repo exportable | Per repo, for the daemon |
| `git-shell` (as login shell) | Git-only SSH | Lock down the `git` user |
| `git ls-remote <url>` | Check connectivity/refs | Debug URL/auth |
| `git update-server-info` | Prepare dumb HTTP | Static hosting only |
| `git instaweb` | Launch GitWeb locally | Quick browsing |

## 6. Hands-on labs
Everything below runs on one machine with no root. Setup:
```bash
mkdir -p ~/git-labs/04 && cd ~/git-labs/04
export GIT_CONFIG_GLOBAL="$PWD/gitconfig"            # sandbox config; skip if identity set globally
git config --global user.name "Jane Doe"; git config --global user.email jane@example.com
git config --global init.defaultBranch main
mkdir -p srv/git                                      # our pretend /srv/git
```

### Lab 1 · Bare repo + local protocol
```bash
git init --bare srv/git/my_project.git
git init proj && cd proj
echo "hello" > a.txt && git add . && git commit -m "init"
git remote add origin "$HOME/git-labs/04/srv/git/my_project.git"   # or the absolute path of srv/git
git push -u origin main
cd ..
git clone srv/git/my_project.git c_path               # plain path
git clone file://"$PWD"/srv/git/my_project.git c_file # file:// URL
ls c_path c_file
```
**Expected:** both clones contain `a.txt`. Explore the bare repo: `ls srv/git/my_project.git` shows `HEAD branches config hooks objects refs …` and **no** `a.txt`.
Try pushing into a *non-bare* repo's checked-out branch to see why servers use bare repos:
```bash
git clone proj nonbare_test 2>/dev/null; cd proj && echo x>>a.txt && git commit -am x
git remote add nb ../nonbare_test && git push nb main      # refused: "[remote rejected] main -> main (branch is currently checked out)"
cd ..
```

### Lab 2 · Make a bare repo from an existing one, and shared permissions
```bash
git clone --bare proj/.git bare_copy.git
ls bare_copy.git | head
git init --bare --shared=group shared.git
git config -f shared.git/config core.sharedRepository     # prints: 1 (group)
ls -ld shared.git                                          # drwxrwsr-x (setgid + group-write)
```
**Expected:** `core.sharedRepository` is set; directory mode has group write and the `s` bit.

### Lab 3 · Git protocol with `git daemon`
```bash
git daemon --reuseaddr --base-path="$PWD/srv/git" --port=9419 \
  --detach --pid-file="$PWD/daemon.pid" "$PWD/srv/git"
git clone git://localhost:9419/my_project.git c_git       # fails: not exported yet
touch srv/git/my_project.git/git-daemon-export-ok
git clone git://localhost:9419/my_project.git c_git       # works
git ls-remote git://localhost:9419/my_project.git
cd c_git && echo y>>a.txt && git commit -am y && git push  # fails: daemon is read-only by default
cd ..
kill "$(cat daemon.pid)"
```
**Expected:** first clone: `access denied or repository not exported`; after the marker file it works; push fails with "access denied or repository not exported" / "service not enabled". Note: `--port=9419` avoids needing the default 9418. To experiment with anonymous writes (never in production): add `--enable=receive-pack` and re-run.

### Lab 4 · Smart HTTP with a tiny dev server (tested)
`git-http-backend` is a CGI program, so any web server can host it. This ~30-line Python script bridges HTTP to it for **local learning only** (no TLS, no real auth):
```bash
cat > smart_http.py <<'EOF'
#!/usr/bin/env python3
"""Dev-only bridge: serves bare repos under ROOT over smart HTTP using git-http-backend."""
import os, subprocess, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.abspath(sys.argv[1]); PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
BACKEND = subprocess.check_output(["git", "--exec-path"], text=True).strip() + "/git-http-backend"

class H(BaseHTTPRequestHandler):
    def handle_any(self):
        path, _, query = self.path.partition("?")
        n = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(n) if n else b""
        env = {**os.environ, "GIT_PROJECT_ROOT": ROOT, "GIT_HTTP_EXPORT_ALL": "1",
               "REQUEST_METHOD": self.command, "PATH_INFO": path, "QUERY_STRING": query,
               "CONTENT_TYPE": self.headers.get("Content-Type", ""), "CONTENT_LENGTH": str(len(body)),
               "REMOTE_USER": "dev", "REMOTE_ADDR": self.client_address[0]}
        if self.headers.get("Content-Encoding"): env["HTTP_CONTENT_ENCODING"] = self.headers["Content-Encoding"]
        out = subprocess.run([BACKEND], input=body, env=env, capture_output=True).stdout
        head, _, payload = out.partition(b"\r\n\r\n")
        status, headers = 200, []
        for line in head.decode().split("\r\n"):
            k, _, v = line.partition(": ")
            if k.lower() == "status": status = int(v.split()[0])
            elif k: headers.append((k, v))
        self.send_response(status)
        for k, v in headers: self.send_header(k, v)
        self.send_header("Content-Length", str(len(payload))); self.end_headers(); self.wfile.write(payload)
    do_GET = do_POST = handle_any
    def log_message(self, *a): pass

ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
EOF
python3 smart_http.py srv/git 8082 &          # leave running in the background
sleep 1
git clone http://127.0.0.1:8082/my_project.git c_http
cd c_http && echo http >> a.txt && git commit -am "via http" && git push
cd .. && git -C srv/git/my_project.git log --oneline -2
kill %1                                         # stop the server
```
**Expected:** clone and push both succeed over `http://`; the bare repo's log shows "via http". The server worked because `REMOTE_USER` is set (git-http-backend only allows pushes for authenticated users, or when `http.receivepack=true`). The script is a teaching aid; real servers use Apache/nginx with `git-http-backend` plus TLS and auth as in §4.7.

### Lab 5 · `git-shell`: restrict an account to Git (command level, tested)
You can't `chsh` here, but you can see exactly what `git-shell` allows by invoking it as SSH would:
```bash
# What sshd runs when a client does `git clone user@host:path`:
git shell -c "git-upload-pack '$PWD/srv/git/my_project.git'" < /dev/null | head -c 60; echo
# Any other command is refused:
git shell -c "ls"
# Custom limited commands:
mkdir -p gsh/git-shell-commands
printf '#!/bin/sh\necho "Only git commands are allowed. Try: list"\n' > gsh/git-shell-commands/help
printf '#!/bin/sh\nls "%s/srv/git"\n' "$PWD" > gsh/git-shell-commands/list
chmod +x gsh/git-shell-commands/*
HOME="$PWD/gsh" git shell -c list
```
**Expected:** first command prints the start of the Git advertisement (`…HEAD multi_ack…`); `ls` gives `fatal: unrecognized command 'ls'`; `list` prints `my_project.git`.
Real server steps: add `$(which git-shell)` to `/etc/shells`, then `sudo chsh git -s $(which git-shell)`.

### Lab 6 · SSH-based setup (🌐 real-world task; needs a Linux box you control, e.g., a VM, Raspberry Pi, or cheap VPS)
1. On your laptop: `ssh-keygen -t ed25519 -C "you@example.com"`; `cat ~/.ssh/id_ed25519.pub`.
2. On the server, create the `git` user and `authorized_keys` as in §4.5; paste your public key.
3. Test: `ssh git@server` (should connect; after the `git-shell` change it should refuse an interactive shell).
4. `ssh git@server "mkdir -p /srv/git/demo.git && git init --bare /srv/git/demo.git"` (before `git-shell`, or via an admin account).
5. Locally: `git remote add origin git@server:/srv/git/demo.git && git push -u origin main`.
6. Add a second person's key; both clone and push; confirm `git log --format='%an'` shows each person's own name.
7. Remove that key line and confirm access is revoked.
8. Debug aid: `GIT_SSH_COMMAND="ssh -v" git ls-remote git@server:/srv/git/demo.git`.

### Lab 7 · Hosted vs self-hosted decision (🌐 thinking exercise)
Pick a real scenario (a 5-person startup, a university class, an air-gapped defense contractor). Write one paragraph choosing a protocol and a host from §4.1 and §4.9, including auth, backup and cost.

## 7. Practice challenges
1. Create three bare repos under `srv/git`, expose only two to `git daemon`, and prove the third is refused.
2. Make a repo writable by two different Unix users through a group (describe the exact `groupadd`/`usermod`/`init --bare --shared` steps; test the permission bits locally).
3. Show that `git clone /path/repo.git` and `git clone file:///path/repo.git` produce identical working trees, and find a difference in how objects are transferred (hint: `du`/inode counts of `.git/objects`).
4. Extend the Lab 4 server so that pushes are rejected for anonymous clients (set `REMOTE_USER` empty, enable/disable `http.receivepack`).
5. Write a `git-shell-commands/new-repo` script that creates a bare repository given a name, and run it via `git shell -c`.
6. Explain, with a diagram, what happens on the wire during `git clone git@host:repo.git` (client `git-upload-pack` via SSH).

<details><summary>Solutions</summary>

1. `touch srv/git/a.git/git-daemon-export-ok` and same for `b.git`; clone `c.git` fails with `repository not exported`.
2. `sudo groupadd gitusers; sudo usermod -aG gitusers alice; sudo usermod -aG gitusers bob; sudo mkdir /srv/git; sudo chgrp gitusers /srv/git; sudo chmod g+ws /srv/git; git init --bare --shared=group /srv/git/p.git`. Locally verify `ls -ld` shows `rwxrwsr-x`.
3. A plain path may hardlink object files (same inode counts, near-zero extra disk); `file://` forces the normal transport and copies/packs objects (new inodes). `ls -li` or `stat -c %h` on an object file shows link count >1 with hardlinks.
4. In `smart_http.py`, remove `REMOTE_USER` (or set it to ""); pushes get 403 unless `git -C srv/git/x.git config http.receivepack true`.
5. Script: `#!/bin/sh` / `git init --bare "/srv/git/$1.git"` then `chmod +x`; call `git shell -c "new-repo demo"`.
6. Client runs `ssh git@host "git-upload-pack 'repo.git'"`; server lists refs; client sends wants/haves; server sends a pack; connection closes.
</details>

## 8. Common mistakes & how to recover
| Mistake / symptom | Fix |
|-------------------|-----|
| `Permission denied (publickey)` | Wrong key, wrong user, or `authorized_keys` perms: `~/.ssh` must be `700`, file `600`, home not group-writable. Test `ssh -v`. |
| `fatal: '/path' does not appear to be a git repository` | Wrong path, repo not bare/initialized, or user lacks read access |
| `[remote rejected] ... (branch is currently checked out)` | Pushed to a non-bare repo; use a bare repo (or `receive.denyCurrentBranch`, not recommended) |
| `fatal: remote error: access denied or repository not exported` (daemon) | Add `git-daemon-export-ok` or `--export-all` |
| `Connection refused` on 9418 | Daemon not running or port blocked by firewall |
| Pushes fail: `unable to create temporary object directory` / permission errors | Mixed file ownership; use `--shared=group` and consistent umask; `chown -R` |
| Interactive SSH login works for the `git` user | Switch to `git-shell` |
| HTTP push `403` | Auth/`http.receivepack` not configured for write |
| Clone works over `file://` but not path | Safe-directory ownership checks (`safe.directory`) |
| Leaked private key | Remove the public key from all servers, rotate, regenerate |

## 9. Real-world use cases
- Internal CI mirrors via `git://` read-only; developers push via SSH.
- Small agencies: single Linux host, `git` user, key per developer, nightly `rsync` backup of `/srv/git`.
- Enterprises: GitLab/GitHub Enterprise with SSO, protected branches and audit logs.
- Air-gapped environments: bare repos on a shared drive, or `git bundle` ([10-git-tools-submodules-bundling-replace-and-credentials.md](10-git-tools-submodules-bundling-replace-and-credentials.md)).
- Disaster recovery: any clone (`git clone --mirror`) is a full backup of a server repository.

## 10. Self-check quiz
1. What is a bare repository and why do servers use one?
2. Which protocol has no authentication, and what is it good for?
3. How is user identity in commits different from the SSH account used to push?
4. What does `git-shell` do, and how do you enable it for a user?
5. What file makes a repository eligible for `git daemon` without `--export-all`?
6. What is the advantage of smart HTTP over SSH for corporate users?
7. How do you revoke one developer's access in the shared `git` account model?
8. What does `git init --bare --shared=group` do?

<details><summary>Answers</summary>

1. Contains only the repo data (no working tree), so pushes can't clash with checked-out files.
2. The Git protocol (`git://`); fast read-only anonymous access.
3. Commits carry name/email from each author's config; the SSH user only authenticates the transport.
4. Restricts SSH login to Git commands; add it to `/etc/shells` and `chsh -s $(which git-shell) git`.
5. `git-daemon-export-ok` in the repo directory.
6. Standard ports 80/443 through firewalls and proxies, HTTP auth/SSO, one URL for read and write.
7. Delete their line from `~git/.ssh/authorized_keys`.
8. Initializes a bare repo with group-writable permissions and sets `core.sharedRepository`.
</details>

## 11. Mastery checklist & next step
Without notes you can:
- [ ] Choose a protocol for a given scenario and justify it.
- [ ] Create, populate and clone a bare repo over local, daemon and HTTP.
- [ ] Describe the shared `git` account + `authorized_keys` + `git-shell` setup.
- [ ] Debug the common errors in §8 from the message alone.

**Next:** [05-distributed-git-workflows.md](05-distributed-git-workflows.md): centralized, integration-manager and dictator workflows; contributing and maintaining a project.
