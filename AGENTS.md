## 

## High-Level Project Idea

read /README.md

## Agent skills

Inside .agents/skills

### Issue tracker

Issues live as markdown files under `.scratch/<feature>/` in this repo. See `.docs/agents/issue-tracker.md`.

### Triage labels

Default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `.docs/agents/triage-labels.md`.

## Raw Manual documents

Inside /.docmanual. Stores the raw document and ideas written by humans. No need to read it during implementation. Read the related files to grasp the high-level design in a grill session. 

Do *NOT* edit them unless specified. If other files contradict the manual documents, ask for clarifications.

## Glossary

Check GLOSSARY.md for meanings of domain-specific terms. Both AI and humans contribute to it.

### Domain docs

Game-wide: `CONTEXT.md` at repo root + `.docs/adr/`. Per-scene glossaries live under `.docs/contexts/` (e.g. `battlefield.md`). See /.docs/agents/domain.md`.

### Code map

`.docs/CODEMAP.md` maps the repo layout and `src/` tree — read it first to locate code. Whenever you add, remove, or move code files, update it in the same change.

Do *NOT* read all code and doc files in the project. It will be too much.

## During implementation

Since I don't have a large AI token limit. Please follow the guide below to do the tasks efficiently. 

### TDD and Testing

Use TDD for development. The tests are inside ./tests

Add test cases based on the task list.

After editing the code, run the test cases to detect failures.

After coding, **DON'T** test the game in a loop by the AI agent; limit the AI-triggered test to at most 2 times. Break the loop and ask for human intercept.

### UI review

Whenever the UI changes, pause and ask for human verification. This way, the game designer can know whether your output fits the style, even though the style requirements are hard to describe in text.

If a task includes UI change, try to do it first if possible. This way, it can be stopped early if it's going wrong. 

### Update the progress

Always update the task item checklist when you finish a few items (at least once for every 5 items). This way, if you stop accidentally because of token burnout, the progress is still recorded for pickup later.

### Post code change

Skip code review unless the developers explicitly ask for it. 

Don't commit any code. Leave it to developers.

## Multi-language setting

The game should be multi-language. The language setting should be put in ./scr/multiLang
Please put all the display text into this holder.

## Physics setting

Put all physics constants in ./src/battlefield/physics_constant.gd for fine tune.

## Codex Maintenance

Codex is a feature that allow players to collect records of different kinds of object they met in the game. (TBC) So players can review them and learn the world settings. It includes Adventurer Classes, Skills, Heroes, etc.

If a task is related to collectable objects, read ./.docmanual/codexList/index.md. It explains how to manage the documents of collectable object lists.

Manage the the codex items logic inside sub-folders of ./src/codex for different types. Do **NOT** put the codex items, which inside the subfolders, into ./.docs/CodeMap.md or otherwise it would be too much. Name the script according to type + reference id so can refer to the doc. (e.g. Skill_SPA10001.gd)

