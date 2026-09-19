# 02 — Role Selector flow

**What to build:** the Role Selector sub-scene offers three choices — Host a game room, Join a game, Back to the Menu. Choosing Join shows a form: a mandatory Player Name field (32-character cap), IP + port fields, and a Join button. While connecting, an inline "Connecting…" state shows; a failed connection shows a clear localized message in place and lets the player fix IP/port and retry; a successful connect moves the player into the Waiting Room. Choosing Host moves the player into the Waiting Room as Host. All display text comes from the multiLang holder. (The in-game role — Player A / Player B / Spectator — is NOT chosen here; that happens in the Waiting Room.)

**Blocked by:** 01 — Transport seam + Multiplayer Scene manager skeleton.

**Status:** ready-for-agent

- [ ] The player can pick Host a game room, Join a game, or Back to the Menu
- [ ] Join shows a form: mandatory Player Name (32-char cap), IP + port fields, Join button
- [ ] While connecting, an inline "Connecting…" state shows
- [ ] A failed connection shows a localized failure message in the Role Selector and allows retry
- [ ] Back returns to the Menu without attempting a connection
- [ ] Choosing Host swaps the container to the Waiting Room as Host
- [ ] A successful connect swaps the container to the Waiting Room
- [ ] All display text comes from the multiLang holder (EN/ZH)
