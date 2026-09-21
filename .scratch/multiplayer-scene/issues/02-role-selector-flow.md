# 02 — Role Selector flow

**What to build:** the Role Selector sub-scene offers three choices — Host a game room, Join a game, Back to the Menu. Choosing Join shows a form: a mandatory Player Name field (32-character cap), IP + port fields, and a Join button. While connecting, an inline "Connecting…" state shows; a failed connection shows a clear localized message in place and lets the player fix IP/port and retry; a successful connect moves the player into the Waiting Room. Choosing Host moves the player into the Waiting Room as Host. All display text comes from the multiLang holder. (The in-game role — Player A / Player B / Spectator — is NOT chosen here; that happens in the Waiting Room.)

**Blocked by:** 01 — Transport seam + Multiplayer Scene manager skeleton.

**Status:** implemented (39/39 tests green — code-review fixes applied)

**Progress notes:**
- `src/multiplayer/role_selector.tscn` rebuilt as a full-rect Control (was Node3D draft): ChoiceBox (Host / Join / Back) + JoinForm (Player Name max_length=32, IP default 127.0.0.1, Port default 8910, StatusLabel, Join/Back buttons). `role_selector.gd` is a dumb view forwarding to the manager; all text via `Loc.t`.
- Localization keys added EN+ZH in `src/multiLang/localization.gd` (`role_*`, `join_*`, `wr_*`, `notif_*`).
- Success path: peer stays in "Connecting…" until the Host's first `room_state` broadcast arrives, then swaps to the Waiting Room (so a rejected Peer never flashes the room). Message format: `{"type":"room_state","host_name","capacity","port","peers":{"<id>":{"name","role"}}}`, roles `"a"/"b"/"spectator"`.
- Gotcha discovered: manager must NOT preload `menu.tscn` (menu.gd preloads the Multiplayer Scene → cyclic preload yields a pathless PackedScene). It uses `const MENU_SCENE_PATH` + `load()` at navigation time; `chosen_target` is the test seam (same pattern as menu.gd).

- [x] The player can pick Host a game room, Join a game, or Back to the Menu
- [x] Join shows a form: mandatory Player Name (32-char cap), IP + port fields, Join button
- [x] While connecting, an inline "Connecting…" state shows
- [x] A failed connection shows a localized failure message in the Role Selector and allows retry
- [x] Back returns to the Menu without attempting a connection
- [x] Choosing Host swaps the container to the Waiting Room as Host
- [x] A successful connect swaps the container to the Waiting Room
- [x] All display text comes from the multiLang holder (EN/ZH)
