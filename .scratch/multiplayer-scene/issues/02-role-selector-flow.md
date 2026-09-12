# 02 — Role Selector flow

**What to build:** the Role Selector sub-scene offers Host / Opponent / Spectator, a mandatory Player Name field (32-character cap), IP + port fields for joining roles, and a Back button to the Menu. Choosing a joining role shows an inline "Connecting…" state; a failed connection shows a clear localized message in place and lets the player fix IP/port and retry; a successful connect moves the player into the Waiting Room. All display text comes from the multiLang holder.

**Blocked by:** 01 — Transport seam + Multiplayer Scene manager skeleton.

**Status:** ready-for-agent

- [ ] The player can pick Host, Opponent or Spectator
- [ ] Player Name is mandatory and capped at 32 characters
- [ ] Opponent/Spectator roles expose IP + port entry fields
- [ ] While connecting, an inline "Connecting…" state shows
- [ ] A failed connection shows a localized failure message in the Role Selector and allows retry
- [ ] Back returns to the Menu without attempting a connection
- [ ] A successful connect swaps the container to the Waiting Room
- [ ] All display text comes from the multiLang holder (EN/ZH)
