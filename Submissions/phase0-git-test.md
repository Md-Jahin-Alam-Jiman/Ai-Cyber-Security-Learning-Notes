# Git Test

## Part A: Concepts

### 1. What are the three areas in Git, and what moves a change from one to the next?

**Answer:**

1. Working area
2. Staged area
3. Committed area

```text
git add .             # working area --> staged area
git commit -m "Message"  # staged area --> committed area
```

### 2. What is a commit, really? What does it store, and what identifies it?

**Answer:**  
A commit is a snapshot of the project at a specific point in time. It stores a
reference to the project’s file tree, its parent commit(s), author and committer
information, timestamps, and the commit message. A commit is identified by its
hash, which is calculated from the commit’s contents and metadata.

### 3. What is HEAD? What does “detached HEAD” mean and how do you get into it?

**Answer:**  
HEAD shows the commit/branch I am currently working from. Normally, HEAD points
to the current branch, and the branch points to the latest commit.

A detached HEAD means HEAD points directly to a commit instead of a branch. I
can enter detached HEAD with:

```sh
git switch --detach 03ae4819628686842b3e062192542164ac72dcc0
```

or:

```sh
git checkout 03ae4819628686842b3e062192542164ac72dcc0
```

### 4. What is a branch technically? Why is creating one so cheap?

**Answer:**  
A branch is a movable reference (pointer) to a commit. Creating a branch is
cheap because Git only creates a small reference to a commit; it does not copy
the whole project.

### 5. What is the difference between merge and rebase? When is rebasing dangerous?

**Answer:**  
Merge combines two histories and normally creates a merge commit. It keeps the
existing commit history unchanged.

Rebase takes my commits and replays them on top of another base commit. This
creates new commit IDs and rewrites history.

Rebasing is dangerous when the commits have already been shared with other
people because rewriting shared history can cause conflicts and can make other
people’s history inconsistent.

### 6. `reset --soft`, `reset --mixed`, `reset --hard`: what does each change, and which can lose work?

**Answer:**  
`git reset` mainly moves HEAD to another commit. Depending on the option, it can
also change the Staging Area and Working Directory:

- `--soft` moves only HEAD.
- `--mixed` moves HEAD and resets the Staging Area.
- `--hard` moves HEAD, resets the Staging Area, and resets the Working
  Directory.

## Part B: Practical Tasks

### B1: Restore a deleted file

**Goal:** Restore a file deleted in commit 2 without copying it from outside the
repository.

**Commands:**
```sh
mkdir git-test
cd git-test
git init
echo "Commit 1" > test.txt
git add . && git commit -m "Commit 1"


echo "Commit 2" > test.txt
git add . && git commit -m "Commit 2"

rm test.txt
git add . && git commit -m "Commit 3"

git restore --source=HEAD~1 test.txt

```

**Output:**
```sh
❯ git log --graph --all
* commit 3d826bfb9b05924960949efaf139eb61c46e80b7 (HEAD -> main)
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
| Date:   Fri Nov 13 03:55:08 2026 -0500
| 
|     test.txt restored
| 
* commit 5bcb6d2f9995cb4bda7e7f4d0df50c72f113ef15
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
| Date:   Fri Nov 13 03:53:28 2026 -0500
| 
|     Commit 3
| 
* commit 4cd36722b410b868a4d1b118d8dcd52e28b6cc17
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
| Date:   Fri Nov 13 03:48:34 2026 -0500
| 
|     Commit 2
| 
* commit 69c8a4bd0e2933e8431ed016b5204c54675d72c6
  Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
  Date:   Fri Nov 13 03:38:06 2026 -0500
  
      Commit 1
```

**Observation:**  
``` 
For restoring the `test.txt` file I need to use restore. I can also copy paste or recreate the file but it is efficient way to restore deleted file because it ensure the date of the file.
```

**Why it works:** 
```
Because `--restore` is designed for recovering data from deleted git histroy.
```

**Additional clarification:**  
Your commands successfully restored `test.txt` from Git history, but the
timeline differs slightly from the task: commit 2 changes the file's contents,
and commit 3 deletes it. The restore source `HEAD~1` is commit 2, so the file
content you recovered is the version from commit 2. To match the task exactly,
make commit 2 the deletion and restore from the commit before it. Git stores
each committed version, so `git restore --source=<commit> -- <file>` can restore
that version without an external copy. The command is `git restore`; `--source`
is its option. Git restores the file contents, not its original filesystem
modification time.

### B2: Undo a pushed commit without rewriting history

**Commands:**
```sh
❯ echo "Wrong Commit">test.txt                                                                                
                                                                                                              
❯ git add . && git commit -m "Wrong commit"                                                                   
[main 55dd29a] Wrong commit                                                                                   
 1 file changed, 1 insertion(+), 1 deletion(-)                                                                
                                                                                                              
❯ ls                                                                                                          
test.txt                     

❯ git log --graph --all                                                                                       
* commit 55dd29aab19240fa613f7b32c4a9ac36f4bd06f8 (HEAD -> main)                                              
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>                                                         
| Date:   Fri Nov 13 04:03:38 2026 -0500                                                                      
|                                                                                                             
|     Wrong commit                                                                                            
|                                                                                                             
* commit 3d826bfb9b05924960949efaf139eb61c46e80b7                                                             
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>                                                         
| Date:   Fri Nov 13 03:55:08 2026 -0500                                                                      
|                                                                                                             
|     test.txt restored                                                                                       
|                                                                                                             
* commit 5bcb6d2f9995cb4bda7e7f4d0df50c72f113ef15                                                             
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>                                                         
| Date:   Fri Nov 13 03:53:28 2026 -0500                                                                      
|                                                                                                             
|     Commit 3                                                                                                
|                                                                                                             
* commit 4cd36722b410b868a4d1b118d8dcd52e28b6cc17                                                             
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>                                                         
| Date:   Fri Nov 13 03:48:34 2026 -0500                                                                      
|                                                                                                             
|     Commit 2                                                                                                
|                                                                                                             
* commit 69c8a4bd0e2933e8431ed016b5204c54675d72c6                                                             
  Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
  Date:   Fri Nov 13 03:38:06 2026 -0500

      Commit 1

❯ git revert 3d826bfb9b05924960949efaf139eb61c46e80b7                                                         
CONFLICT (modify/delete): test.txt deleted in parent of 3d826bf (test.txt restored) and modified in HEAD.  Ver
sion HEAD of test.txt left in tree.                                                                           
error: could not revert 3d826bf... test.txt restored                                                          
hint: After resolving the conflicts, mark them with                                                           
hint: "git add/rm <pathspec>", then run                                                                       
hint: "git revert --continue".                                                                                
hint: You can instead skip this commit with "git revert --skip".
hint: To abort and get back to the state before "git revert",
hint: run "git revert --abort".
hint: Disable this message with "git config set advice.mergeConflict false"

❯ vim test.txt

❯ git rm test.txt
rm 'test.txt'

❯ git revert --continue
[main 8f49072] Revert "test.txt restored"
 1 file changed, 1 deletion(-)
 delete mode 100644 test.txt

❯ ls                                                                                             04:10 [4/215]
                                                                                                              
❯ git log --graph --all                                                                                       
* commit 8f49072ecc75ec1d1a5778a3055dff9fb6727d57 (HEAD -> main)                                              
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>                                                         
| Date:   Fri Nov 13 04:09:43 2026 -0500
| 
|     Revert "test.txt restored"
|     
|     This reverts commit 3d826bfb9b05924960949efaf139eb61c46e80b7.
| 
* commit 55dd29aab19240fa613f7b32c4a9ac36f4bd06f8
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
| Date:   Fri Nov 13 04:03:38 2026 -0500
| 
|     Wrong commit
| 
* commit 3d826bfb9b05924960949efaf139eb61c46e80b7
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
| Date:   Fri Nov 13 03:55:08 2026 -0500
| 
|     test.txt restored
| 
* commit 5bcb6d2f9995cb4bda7e7f4d0df50c72f113ef15
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
| Date:   Fri Nov 13 03:53:28 2026 -0500
| 
|     Commit 3
| 
* commit 4cd36722b410b868a4d1b118d8dcd52e28b6cc17
| Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
| Date:   Fri Nov 13 03:48:34 2026 -0500
| 
|     Commit 2
| 
* commit 69c8a4bd0e2933e8431ed016b5204c54675d72c6
  Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
  Date:   Fri Nov 13 03:38:06 2026 -0500

      Commit 1


```

**Observation:**  
```text
First it was seen simple that I will use revert command and it will provide me the desire output.But it can create confict sometimes.
```

**Why it works:** 
```text
It works after solving the conflict.
```



**Additional clarification:**  
The commit you tried to revert, `3d826bf` (`test.txt restored`), is not the
mistake commit. The mistake is `55dd29a` (`Wrong commit`), so in a
straightforward case the command should target that commit:

```sh
git revert 55dd29a
```

`git revert` creates a new commit that applies the inverse of the selected
commit; it does not erase or move the existing history. If Git reports a
conflict, resolve the affected file to the intended final content, stage it,
and run `git revert --continue`. Since this exercise is about a shared branch,
push the resulting revert commit after confirming the change. Your transcript
does not show a push, and the conflict shown happened because a different
commit was selected.

### B3: Create branches, cause a conflict, merge, and resolve it

**Commands:**
```sh
❯ git branch branch_a
                                                                                                              
❯ git switch branch_a
Switched to branch 'branch_a'
                                                                                                              

❯ echo "Edit on Branch a">file.txt

                                                                                                              
❯ cat file.txt
Edit on Branch a
                                                                                                              
❯ git add . && git commit -m "Branch a edit"
[branch_a 4b6a437] Branch a edit
 1 file changed, 1 insertion(+)
 create mode 100644 file.txt

                     
❯ git switch main
Switched to branch 'main'
                                                                                                              
❯ echo "Edit on Branch Main">file.txt
                                                                                                              
❯ git add . && git commit -m "Branch main edit"
[main e0a7959] Branch main edit
 1 file changed, 1 insertion(+)
 create mode 100644 file.txt

❯ git log --graph --all --oneline
* e0a7959 (HEAD -> main) Branch main edit
| * 4b6a437 (branch_a) Branch a edit
|/  
* 8f49072 Revert "test.txt restored"
* 55dd29a Wrong commit
* 3d826bf test.txt restored
* 5bcb6d2 Commit 3
* 4cd3672 Commit 2
* 69c8a4b Commit 1

❯ git merge main branch_a
Auto-merging file.txt
CONFLICT (add/add): Merge conflict in file.txt
Automatic merge failed; fix conflicts and then commit the result.
                                                                                                                                                                                                                                            
❯ vim file.txt
                                                                                                                                                                                                                                            
❯ cat file.txt
Edit on Branch Main
Edit on Branch a
                                                                                                                                                                                                                                            
❯ git add . && git commit
[main d84da08] Merge branch 'branch_a'
                                                                                                                                                                                                                                            
❯ git log --graph --all --oneline
*   d84da08 (HEAD -> main) Merge branch 'branch_a'
|\  
| * 4b6a437 (branch_a) Branch a edit
* | e0a7959 Branch main edit
|/  
* 8f49072 Revert "test.txt restored"
* 55dd29a Wrong commit
* 3d826bf test.txt restored
* 5bcb6d2 Commit 3
* 4cd3672 Commit 2
* 69c8a4b Commit 1
                                                                        
                                            
```

**Additional clarification:**  
The transcript shows an `add/add` conflict: each branch added a new
`file.txt`. To meet the task's “same line” requirement, first commit a file
containing a common line on the original branch, then create both branches and
edit that existing line differently on each branch. While on the branch that
will receive the merge, merge the other branch (for example, `git merge
branch_a`).

For a content conflict, Git marks the competing changes like this:

```text
<<<<<<< HEAD
the version from the branch currently checked out
=======
the version from the branch being merged
>>>>>>> branch_a
```

The lines between `<<<<<<<` and `=======` are the current branch's version; the
lines between `=======` and `>>>>>>>` are the incoming branch's version. Choose
or combine the intended content, remove all marker lines, then stage the
resolved file and complete the merge commit. The two plain lines in your
resolved output show the result, but the transcript does not include the
conflict markers themselves.

### B4: Remove a secret from the latest state and inspect history

**Commands:**
```sh
❯ echo "pass=1234567890" > secret.txt
git add secret.txt
git commit -m "Add secret"
[main cc3f376] Add secret
 1 file changed, 1 insertion(+)
 create mode 100644 secret.txt
                                                                                                                                                                                                                                            
❯ echo "change 1" > file.txt
git add file.txt
git commit -m "Change 1"
[main 7dd630a] Change 1
 1 file changed, 1 insertion(+), 2 deletions(-)
                                                                                                                                                                                                                                            
❯ echo "change 2" >> file.txt
git add file.txt
git commit -m "Change 2"
[main aad2ed2] Change 2
 1 file changed, 1 insertion(+)
                                                                                                                                                                                                                                            
❯ git rm secret.txt
git commit -m "Remove secret"
rm 'secret.txt'
[main f2c8cfd] Remove secret
 1 file changed, 1 deletion(-)
 delete mode 100644 secret.txt


❯ git log --all -- secret.txt
git grep "pass=1234567890" $(git rev-list --all)
commit f2c8cfdd9f64c113ca4b2eb0a4b330a589ed3f22 (HEAD -> main)
Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
Date:   Fri Nov 13 05:34:34 2026 -0500

    Remove secret

commit cc3f376a4e36d8cc8db484c01dadf8487270d5d1
Author: Md-Jahin-Alam-Jiman <jiman905048@gmail.com>
Date:   Fri Nov 13 05:33:38 2026 -0500

    Add secret
aad2ed208233c4306748fbfd7136121d893e33b8:secret.txt:pass=1234567890
7dd630acd05f448b4c91ed7d1775c2965e85b5be:secret.txt:pass=1234567890
cc3f376a4e36d8cc8db484c01dadf8487270d5d1:secret.txt:pass=1234567890


                                                                                                                                                                                                                                          
❯ git filter-repo --path secret.txt --invert-paths --force
Parsed 13 commits
New history written in 0.03 seconds; now repacking/cleaning...
Repacking your repo and cleaning out old unneeded objects
HEAD is now at 9bafdb0 Change 2
Enumerating objects: 28, done.
Counting objects: 100% (28/28), done.
Delta compression using up to 6 threads
Compressing objects: 100% (11/11), done.
Writing objects: 100% (28/28), done.
Total 28 (delta 4), reused 0 (delta 0), pack-reused 0 (from 0)
Completely finished after 0.12 seconds.
                                                                                                                                                
```

**Observation:**  
Removing `secret.txt` creates a commit where it is absent from the latest
project state. It does **not** remove the secret from earlier commits. Your
`git grep` output confirms the fake password is still present in historical
commits.

**Why it works / what is needed to remove it:**  
Git commits are snapshots, so deleting a file in a later commit does not alter
older snapshots. Your `git filter-repo` command rewrites local history to
remove the path, but the transcript only shows the local rewrite; it does not
show that rewritten history was pushed or that other copies were cleaned up.
For a real exposed credential, revoke or rotate it immediately. To purge the
file from shared history, coordinate with collaborators, rewrite the affected
history, force-push the rewritten refs, and account for other branches, tags,
clones, backups, and hosting-provider caches. Anyone with an old clone can
still have the original commits.

## Part C: Scenarios

### 1. `git reset --hard` lost a commit

It may not be gone immediately. `git reset --hard` moves the current branch
backward and resets the index and working tree, but the old commit may remain
reachable through the reflog for a time.

I would check the reflog to find where HEAD pointed before the reset:

```sh
git reflog
```

After identifying and verifying the needed commit, I can preserve it by
creating a branch that points to it:

```sh
git branch recovered <commit-hash>
```

Then I can inspect the recovered commit and its files before deciding how to
bring it back into my current branch. I should avoid running cleanup or
additional destructive commands before recovery, because unreachable objects
can eventually be pruned.

### 2. A teammate suggests a force push

Before force-pushing, I should check which branch and commits will be
overwritten, whether teammates have pushed work, whether anyone else depends on
the current history, and whether I have fetched the latest remote changes. A
force push rewrites the branch history and can make other contributors' commits
appear lost or require them to repair their local branches.

If rewriting history is necessary and coordinated with the team, the safer
variant is:

```sh
git push --force-with-lease
```

`--force-with-lease` refuses to update the remote if it has moved beyond the
remote-tracking state I last observed. It helps avoid overwriting new work I
have not fetched, but it does not make force-pushing harmless; I should still
coordinate and review the changes first.

## Bonus

### Python `.gitignore`

```gitignore
__pycache__/
*.pyc
.venv/
.env
.pytest_cache/
build/
dist/
.vscode/
```

Line-by-line justification:

- `__pycache__/` ignores Python's bytecode cache directories.
- `*.pyc` ignores compiled Python bytecode files.
- `.venv/` ignores a project-local virtual environment, which can be recreated
  from dependency declarations.
- `.env` ignores local environment variables, which may contain secrets or
  machine-specific settings.
- `.pytest_cache/` ignores pytest's generated cache.
- `build/` ignores generated package/build output.
- `dist/` ignores generated distribution archives and files.
- `.vscode/` ignores workspace-specific VS Code settings; remove this entry if
  the project intentionally shares those settings.

### `git bisect`

`git bisect` helps identify which commit introduced a bug by using binary
search through a range of commits. For example, if the application worked in
the previous release but a bug is present in the current release, I can mark
the previous release as good and the current commit as bad. Git checks out a
commit halfway between them; I run the relevant test and mark that commit good
or bad. Git repeats this until it identifies the first bad commit. I can then
inspect that commit's changes to find the cause.
