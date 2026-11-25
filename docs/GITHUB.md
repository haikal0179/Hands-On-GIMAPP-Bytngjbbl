# GitHub steps

## A. One-time setup (the person who owns the repo, ~10 minutes)

1. Install Git (https://git-scm.com) and tell it who you are:
   ```
   git config --global user.name  "Your Name"
   git config --global user.email "you@example.com"
   ```
2. On github.com click **New repository**. Name it e.g. `ultimate-utbk`. Choose Private.
   Do **not** tick "Add README / .gitignore / license" (the project already has them).
3. Extract the zip, open a terminal **inside the project folder** (the one with `project.godot`).
4. Make the first commits. The script creates 13 small commits so history is readable:
   ```
   git init -b main
   bash tools/stepwise_commits.sh
   ```
   (Windows: run it in Git Bash. Or skip the script and use B below.)
5. Connect and push (copy the URL from the GitHub page you just created):
   ```
   git remote add origin https://github.com/YOUR-NAME/ultimate-utbk.git
   git push -u origin main
   ```
6. Invite teammates: repo -> **Settings -> Collaborators -> Add people**.
7. Optional but recommended: **Settings -> Branches -> Add rule** for `main`, tick
   "Require a pull request before merging". Nobody breaks `main` by accident.

## B. Committing step by step by hand (instead of the script)
Commit one idea at a time. Small commits are easy to review and easy to undo.
```
git add core
git commit -m "feat(core): add config, levels, audio, question bank, game state"
git add features/upgrades
git commit -m "feat(upgrades): add base class and registry"
git push
```
Message format: `type(area): what`. Types: `feat` new thing, `fix` bug, `chore` setup,
`docs`, `data` for questions, `art` for assets. Examples:
`feat(upgrades): add typo spotted`, `data(level2): add 6 logic questions`,
`fix(battle): dodge no longer skips enemy turn`.

## C. Daily workflow for everyone

First time on your computer:
```
git clone https://github.com/YOUR-NAME/ultimate-utbk.git
```
Then open `project.godot` in Godot once (it creates a local `.godot/` folder; it is ignored by git).

Every task:
```
git checkout main
git pull                                   # get everybody's latest work
git checkout -b feature/short-name         # your own branch
# ... work, press F5 to test ...
python3 tools/check_project.py             # before committing
git add features/upgrades/items/my_upgrade.gd
git commit -m "feat(upgrades): add my upgrade"
git push -u origin feature/short-name
```
Then on GitHub press **Compare & pull request**, fill the checklist, ask a teammate to
look, and **Merge**. After merging: `git checkout main && git pull`.

Branch names: `feature/<thing>`, `fix/<thing>`, `data/level2-questions`, `art/battle-sprites`.

## D. Stay out of each other's way (important for Godot)
- **One owner per folder** (table in README). Edit only your own files.
- **Never both edit the same `.tscn` at once.** Scene files are text but merge badly.
  `battle_ui.tscn` belongs to the battle/visual dev; others ask before touching it.
- Adding an upgrade or a question file touches **no shared file**, so those never conflict.
- Commit pixel art / audio **together with their `.import` files** (Godot creates them next to the asset).
- Do not commit the `.godot/` folder or exported builds (already in `.gitignore`).
- Empty `DEBUG_START_UPGRADES` in `core/config.gd` before you commit.

## E. When something goes wrong
| Problem | Fix |
|---|---|
| `git push` rejected | `git pull --rebase`, then push again |
| Merge conflict in a `.gd` file | open the file, keep both sides' intent, delete the `<<<<`/`====`/`>>>>` lines, `git add` it, `git rebase --continue` (or `git commit`) |
| Conflict in a `.tscn` | ask the owner; easiest is to take one version: `git checkout --theirs path` or `--ours`, then redo the other person's small change in the editor |
| Committed to `main` by mistake (not pushed) | `git branch feature/oops` then `git reset --hard origin/main`, then `git checkout feature/oops` |
| Want to undo last commit but keep files | `git reset --soft HEAD~1` |
| "Which files did I change?" | `git status` and `git diff` |

## F. Suggested first branches for the team
| Who | Branch | First task |
|---|---|---|
| Battle / visuals dev | `art/battle-sprites` | replace colored boxes in `battle_ui.tscn` with pixel art |
| Upgrade teammates | `feature/upgrade-<name>` | polish their own file in `items/` |
| Question writers | `data/level1-questions` ... | fill `data/questions/level_N.json` |
| Story / art | `feature/story-intro` | build `features/story/intro.tscn` |
