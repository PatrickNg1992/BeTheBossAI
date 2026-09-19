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

Inside /.docmanual. Stores the raw document and idea written by humans. No need to read it during implementation. Read the related files to grasp high-level design in a grill session. 

Do *NOT* edit them unless specified. If other files contradict the manual documents, ask for clarifications.

## Glossary

Check GLOSSARY.md for meanings of domain-specific terms. Both AI and humans contribute to it.

### Domain docs

Game-wide: `CONTEXT.md` at repo root + `.docs/adr/`. Per-scene glossaries live under `.docs/contexts/` (e.g. `battlefield.md`). See /.docs/agents/domain.md`.

### Code map

`.docs/CODEMAP.md` maps the repo layout and `src/` tree — read it first to locate code. Whenever you add, remove, or move code files, update it in the same change.

Do *NOT* read all code and doc files in the project. It will be too much.

## Unit tests

inside ./tests

After editing the code, run the test cases to detect failures.

Add tests cases based on the tasks list.

## Game testing after coding

After writing code, **DON'T** test the game in a loop by the AI agent; limit the AI-triggered test to at most 2 times. Ask the human to test because only the developers know what it should feel as a whole.

## Multi-language setting

The game should be multi-language. The language setting should be put in ./scr/multiLang
Please put all the display text into this holder.
