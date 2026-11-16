# Pro Git Mastery Path

A step-by-step study path for *Pro Git* (2nd ed., Scott Chacon & Ben Straub). Each file covers one chapter or topic with concepts, a command cheat sheet, tested hands-on labs, practice challenges, a quiz and a mastery checklist. Work through them **in order**; every file links back to what it assumes.

## Sequence

| # | File | Book chapter | Level | Est. time |
|---|------|--------------|-------|-----------|
| 01 | [01-getting-started.md](01-getting-started.md) | Ch 1 Getting Started | Beginner | 2 h |
| 02 | 02-git-basics.md | Ch 2 Git Basics | Beginner | 5 h |
| 03 | 03-git-branching-and-merging.md | Ch 3 Git Branching | Beginner–Int. | 5 h |
| 04 | 04-git-on-the-server.md | Ch 4 Git on the Server | Intermediate | 3 h |
| 05 | 05-distributed-git-workflows.md | Ch 5 Distributed Git | Intermediate | 4 h |
| 06 | 06-github-collaboration.md | Ch 6 GitHub | Intermediate | 4 h |
| 07 | 07-git-tools-revision-selection-staging-stashing.md | Ch 7 Git Tools (part 1) | Intermediate | 4 h |
| 08 | 08-git-tools-rewriting-history-and-reset.md | Ch 7 Git Tools (part 2) | Int.–Advanced | 5 h |
| 09 | 09-git-tools-advanced-merging-rerere-and-debugging.md | Ch 7 Git Tools (part 3) | Advanced | 4 h |
| 10 | 10-git-tools-submodules-bundling-replace-and-credentials.md | Ch 7 Git Tools (part 4) | Advanced | 4 h |
| 11 | 11-customizing-git-config-attributes-and-hooks.md | Ch 8 Customizing Git | Advanced | 4 h |
| 12 | 12-git-and-other-systems-svn-migration.md | Ch 9 Git and Other Systems | Advanced | 3 h |
| 13 | 13-git-internals-plumbing-and-objects.md | Ch 10 Git Internals | Advanced | 5 h |
| 14 | 14-appendix-a-git-in-other-environments.md | Appendix A | Optional | 1 h |
| 15 | 15-appendix-b-embedding-git-in-applications.md | Appendix B | Optional | 1 h |
| 16 | 16-appendix-c-git-command-reference.md | Appendix C | Reference | — |

## Why this order
1. **01–02** give you the mental model (snapshots, three states) and the daily loop.
2. **03** is Git's superpower: cheap branches and merging.
3. **04–06** are collaboration: servers, team workflows, GitHub.
4. **07–10** are the power tools, ordered by risk: reading/staging → rewriting history → merge and debug → submodules and misc.
5. **11–13** are customization and internals; 13 explains *why* everything before it works.
6. **14–16** are reference material.

## How to use each file
1. Read **Core concepts**, then do the **Labs** by typing commands yourself.
2. Attempt the **Practice challenges** before opening the solutions.
3. Take the **Quiz**; tick the **Mastery checklist**. Move on only when you can do each item without notes.

## Conventions
- Labs run in throwaway folders under `~/git-labs/`. Commit hashes in your output will differ from the examples.
- 💡 **Modern note** marks things newer than the book (e.g. `git switch`, `main` as default branch).
- 🌐 marks steps that need internet/GitHub.
- Tested with Git 2.43.

## Progress tracker
- [ ] 01 · [ ] 02 · [ ] 03 · [ ] 04 · [ ] 05 · [ ] 06 · [ ] 07 · [ ] 08
- [ ] 09 · [ ] 10 · [ ] 11 · [ ] 12 · [ ] 13 · [ ] 14 · [ ] 15 · [ ] 16
