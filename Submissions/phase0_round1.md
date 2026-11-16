# Round 1

## **Table of contents**
+ [Git (Fix a Failure)](#git-fix-a-failure)


### Git (Fix a Failure)
**Questions:** B1: Restore a deleted file
```sh
ubuntu@ubuntu:~$ mkdir gittest 
ubuntu@ubuntu:~$ cd gittest/  
ubuntu@ubuntu:~/gittest$ git init 
Initialized empty Git repository in /home/ubuntu/gittest/.git/              
ubuntu@ubuntu:~/gittest$ echo "First Commit">file.txt                       
ubuntu@ubuntu:~/gittest$ git status                                                                  
On branch main                            
No commits yet                                                       
                             
Untracked files:                                                                                                                          
  (use "git add <file>..." to include in what will be committed)                                                                          
        file.txt                                                                                                                          
                                                                                                                                          
ubuntu@ubuntu:~/gittest$ git add . && git commit -m "file.txt created"           
[main (root-commit) 41dd445] file.txt created                                                                                             
 1 file changed, 1 insertion(+)                                                                                                           
 create mode 100644 file.txt  
ubuntu@ubuntu:~/gittest$ git status   
On branch main    
nothing to commit, working tree clean  
ubuntu@ubuntu:~/gittest$ rm file.txt 
ubuntu@ubuntu:~/gittest$ git status
On branch main   
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        deleted:    file.txt

no changes added to commit (use "git add" and/or "git commit -a")
ubuntu@ubuntu:~/gittest$ git add . && git commit -m "file.txt deleted"
[main ee09d46] file.txt deleted
 1 file changed, 1 deletion(-)
 delete mode 100644 file.txt
ubuntu@ubuntu:~/gittest$ echo "New File" > newfile.txt
ubuntu@ubuntu:~/gittest$ git status
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        newfile.txt

nothing added to commit but untracked files present (use "git add" to track)
ubuntu@ubuntu:~/gittest$ git add . && git commit -m "newfile.txt added"
[main 69fa584] newfile.txt added
 1 file changed, 1 insertion(+)
 create mode 100644 newfile.txt
ubuntu@ubuntu:~/gittest$ git log --oneline --graph --all
* 69fa584 (HEAD -> main) newfile.txt added
* ee09d46 file.txt deleted
* 41dd445 file.txt created
ubuntu@ubuntu:~/gittest$ git status
On branch main
nothing to commit, working tree clean
ubuntu@ubuntu:~/gittest$ git restore --source=41dd445 file.txt
ubuntu@ubuntu:~/gittest$ ls
file.txt  newfile.txt
ubuntu@ubuntu:~/gittest$ git status
On branch main
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        file.txt

nothing added to commit but untracked files present (use "git add" to track)
ubuntu@ubuntu:~/gittest$
```
**Linux VM (read and decode):**
** V1: ** SnapShort has taken.

**V3 Decode permissions: **
