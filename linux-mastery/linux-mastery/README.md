# Linux Command Line Mastery
Based on *The Linux Command Line* (William Shotts). Primary platform: Ubuntu/Debian, with RHEL, Arch, Alpine, Kali and macOS equivalents.

## How to use this course
1. Do chapters **in order**. Each builds on the last.
2. Read the book chapter first, then open the matching chapter file.
3. Type every command yourself. Never copy-paste in the labs.
4. Don't tick the mastery checklist until you can do it **without looking**.
5. Finish each part's checkpoint project before moving on.

> Start with `00-setup-practice-environment.md`. Chapter files are named `NN-topic-name.md`.

## Roadmap & progress tracker

### Part 1: Learning the Shell
- [ ] 01 What Is the Shell? → `part1-learning-the-shell/01-what-is-the-shell.md`
- [ ] 02 Navigation → `part1-learning-the-shell/02-navigation.md`
- [ ] 03 Exploring the System → `part1-learning-the-shell/03-exploring-the-system.md`
- [ ] 04 Manipulating Files and Directories → `part1-learning-the-shell/04-manipulating-files-and-directories.md`
- [ ] 05 Working with Commands → `part1-learning-the-shell/05-working-with-commands.md`
- [ ] 06 Redirection → `part1-learning-the-shell/06-redirection.md`
- [ ] 07 Seeing the World as the Shell Sees It → `part1-learning-the-shell/07-seeing-the-world-as-the-shell-sees-it.md`
- [ ] 08 Advanced Keyboard Tricks → `part1-learning-the-shell/08-advanced-keyboard-tricks.md`
- [ ] 09 Permissions → `part1-learning-the-shell/09-permissions.md`
- [ ] 10 Processes → `part1-learning-the-shell/10-processes.md`
- [ ] **Checkpoint 1:** File-system playground project → `part1-learning-the-shell/checkpoint-1-filesystem-playground-project.md`

### Part 2: Configuration and the Environment
- [ ] 11 The Environment → `part2-configuration-environment/11-the-environment.md`
- [ ] 12 A Gentle Introduction to vi → `part2-configuration-environment/12-a-gentle-introduction-to-vi.md`
- [ ] 13 Customizing the Prompt → `part2-configuration-environment/13-customizing-the-prompt.md`
- [ ] **Checkpoint 2:** Build your own `.bashrc` → `part2-configuration-environment/checkpoint-2-build-your-own-bashrc.md`

### Part 3: Common Tasks and Essential Tools
- [ ] 14 Package Management → `part3-common-tasks-tools/14-package-management.md`
- [ ] 15 Storage Media (lighter) → `part3-common-tasks-tools/15-storage-media.md`
- [ ] 16 Networking → `part3-common-tasks-tools/16-networking.md`
- [ ] 17 Searching for Files → `part3-common-tasks-tools/17-searching-for-files.md`
- [ ] 18 Archiving and Backup → `part3-common-tasks-tools/18-archiving-and-backup.md`
- [ ] 19 Regular Expressions → `part3-common-tasks-tools/19-regular-expressions.md`
- [ ] 20 Text Processing → `part3-common-tasks-tools/20-text-processing.md`
- [ ] 21 Formatting Output → `part3-common-tasks-tools/21-formatting-output.md`
- [ ] 22 Printing (lighter) → `part3-common-tasks-tools/22-printing.md`
- [ ] 23 Compiling Programs (lighter) → `part3-common-tasks-tools/23-compiling-programs.md`
- [ ] **Checkpoint 3:** Log analysis + backup project → `part3-common-tasks-tools/checkpoint-3-log-analysis-and-backup-project.md`

### Part 4: Writing Shell Scripts
- [ ] 24 Writing Your First Script → `part4-shell-scripting/24-writing-your-first-script.md`
- [ ] 25 Starting a Project → `part4-shell-scripting/25-starting-a-project.md`
- [ ] 26 Top-Down Design → `part4-shell-scripting/26-top-down-design.md`
- [ ] 27 Flow Control: if → `part4-shell-scripting/27-flow-control-branching-with-if.md`
- [ ] 28 Reading Keyboard Input → `part4-shell-scripting/28-reading-keyboard-input.md`
- [ ] 29 Flow Control: while/until → `part4-shell-scripting/29-flow-control-looping-with-while-and-until.md`
- [ ] 30 Troubleshooting → `part4-shell-scripting/30-troubleshooting.md`
- [ ] 31 Flow Control: case → `part4-shell-scripting/31-flow-control-branching-with-case.md`
- [ ] 32 Positional Parameters → `part4-shell-scripting/32-positional-parameters.md`
- [ ] 33 Flow Control: for → `part4-shell-scripting/33-flow-control-looping-with-for.md`
- [ ] 34 Strings and Numbers → `part4-shell-scripting/34-strings-and-numbers.md`
- [ ] 35 Arrays → `part4-shell-scripting/35-arrays.md`
- [ ] 36 Exotica → `part4-shell-scripting/36-exotica.md`
- [ ] **Capstone:** a full system-report / backup tool script → `part4-shell-scripting/capstone-security-toolkit.md`

Suggested pace: ~8–10 weeks, 4–5 sessions per week.

## Study aids
- `study-aids/cheat-sheet.md`: task-based command reference with distro and security sections
- `study-aids/flashcards.tsv`: 139 flashcards (tab-separated: front, back, tag) for Anki import
- `study-aids/study-schedule.md`: 10-week plan with a spaced-review rhythm

## After the course
- Reference solution for the capstone: `part4-shell-scripting/capstone/seckit.sh` (open only after you try each stage yourself)
- Career path and next steps: `next-steps-cyber-career-path.md`

## Notes
- Scripts in Part 4 need **bash 4+** for associative arrays (chapter 35, capstone). macOS ships bash 3.2: `brew install bash`. Alpine: `apk add bash`.
- Never run destructive labs on a machine you care about. Use a VM with snapshots.
- Test only systems you own or are authorized to test.
