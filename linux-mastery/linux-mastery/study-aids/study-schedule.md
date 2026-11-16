# 10-Week Study Schedule with Spaced Review

Assumes about 5 sessions per week, 60–90 minutes each. Adjust freely, but keep the order.

## How each chapter session works
1. **Read** the book chapter (20–30 min)
2. **Type along** the chapter file's walkthrough (20 min)
3. **Do the labs** (easy → medium → hard) (30 min)
4. **Quiz yourself** without peeking; tick the mastery checklist only for things you can do from memory
5. **Journal 3 lines:** learned / confused / want to try

## Spaced-review rhythm (do this for every chapter)
| When | What (10 min) |
|---|---|
| Next day | Re-run the chapter's flashcards (`flashcards.tsv`, tag `chNN`) |
| +3 days | Redo one *medium* lab from memory |
| +7 days | Redo one *hard (cyber)* lab without the file open |
| +14 days | Explain the chapter aloud in 2 minutes; fix gaps |
| +30 days | Random 10 flashcards + one command you forgot |

Tip: import the flashcards into Anki (File → Import, tab-separated, fields: Front, Back, Tags) and let it schedule reviews.

## The plan
| Week | Focus | Chapters | Deliverable |
|---|---|---|---|
| 1 | Shell foundations | 00 setup, 1, 2, 3, 4 | Playground built; journal started |
| 2 | Commands and plumbing | 5, 6, 7, 8 | Pipelines on real logs |
| 3 | Security core | 9, 10 + **Checkpoint 1** | Host triage report |
| 4 | Environment | 11, 12, 13 + **Checkpoint 2** | Your hardened `.bashrc` |
| 5 | System tasks | 14, 15, 16 | SSH hardened in a lab VM |
| 6 | Search and backup | 17, 18, 19 | IOC regexes; verified backup |
| 7 | Text processing and wrap-up | 20, 21, 22, 23 + **Checkpoint 3** | Incident report |
| 8 | Scripting basics | 24, 25, 26, 27, 28 | `triage.sh`, `perm-audit.sh`, `menu.sh` |
| 9 | Control flow and tools | 29, 30, 31, 32, 33 | `brute-detect.sh`, `triage2.sh` |
| 10 | Advanced scripting + capstone | 34, 35, 36 + **Capstone** | `seckit.sh` passing all tests |

## Weekly rhythm (example)
- **Mon–Thu:** one or two chapters (new material) plus the day's spaced reviews
- **Fri:** labs you skipped; flashcard session
- **Weekend:** checkpoint or project work; weekly review (30 min): list the 5 commands you still look up and drill them

## Measuring progress
- Mastery checklists ticked **from memory only**
- Checkpoint scores: aim for 85+ before moving on
- Timed drill (monthly): redo the "first minute recon" and a log-triage pipeline in under 5 minutes on a fresh VM
- Keep one growing file, `my-commands.md`, of commands you had to look up twice

## If you fall behind
Prioritize in this order: chapters **6, 7, 9, 10, 17, 19, 20, 27, 28, 32** and the three checkpoints. Skim chapters 15, 21, 22, 23 and return later.
