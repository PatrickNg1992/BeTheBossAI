# 02 — Menu scene as the project's main scene

**What to build:** launching the game opens a Menu — the game's first page — showing the title placeholder "Be The Boss" and two buttons, Play and Multiplayer, with button labels coming from the multiLang holder (EN/ZH). Pressing Multiplayer takes the player to the existing multiplayer scene stub, unchanged. The old battlefield test scene stays in the repo but is no longer the main scene.

**Blocked by:** 01 — Rename the multiplayer stub's "Menu" nodes to "RoleSelector" (the name "Menu" must be free).

**Status:** ready-for-agent

- [ ] The project's main-scene setting points to the Menu scene; the game boots into it
- [ ] The Menu shows the "Be The Boss" title placeholder and Play / Multiplayer buttons
- [ ] Button labels resolve through the multiLang holder in both EN and ZH
- [ ] Pressing Multiplayer makes the multiplayer scene stub the current scene
- [ ] Play does not need to navigate anywhere yet (the Single-Player Scene is the next ticket)
- [ ] The old battlefield test scene still exists and loads, but is no longer the main scene
