# 05 — Authoritative Card Sync & Role-Based Hand Visibility (`sync_cards` & `action_play_card`)

**What to build:** Manage authoritative card zones (Deck, Hand, Casting Area + cooldown, Discard Pile) on the Host for `Player A` and (if seated) `Player B`, wire `sync_cards()` (`RELIABLE`) and `action_play_card` (`RELIABLE`, restricted to `active_player` in `Play Time`), render face-up Hand cards only to their owner (`Player A` sees Hand A, `Player B` sees Hand B, `Spectator` sees neither face-up hand; hand counts, Casting Area, and Discard Pile are visible to all), and keep camera settings and local inspection popups strictly self-owned.

**Blocked by:** 01 — Transport Unreliable-Ordered Support, Single-Player Loopback & Battlefield Sync Scaffold, 03 — `sync_timing`, Two-Player `Prepare Time` Readiness & Competing for the Playing Right

**Status:** ready-for-agent

- [ ] The Host manages authoritative card state (Deck order/count, Hand cards, Casting Area card + remaining cooldown, Discard Pile) for `Player A` and, when seated, for `Player B`.
- [ ] `sync_cards()` broadcasts (`RELIABLE`) the authoritative card state to all Peers (per ADR-0003, deck/hand secrecy is visibility-only at the UI layer).
- [ ] On a Peer seated as `Player A`, the card HUD displays only `Player A`'s Hand cards face-up; on a Peer seated as `Player B`, the card HUD displays only `Player B`'s Hand cards face-up; on a `Spectator` Peer, no face-up Hand cards are displayed.
- [ ] Hand counts, the active Casting Area card and its cooldown, and the Discard Pile are visible to all Peers (`Player A`, `Player B`, and `Spectator`s).
- [ ] During `Play Time`, the `active_player` holding the Playing Right can send `action_play_card` (`RELIABLE`, with `hand_index` and target position/unit); the Host validates that the sender is `active_player`, `hand_index` is valid, and their Casting Area is empty, then moves the card to the Casting Area, applies the effect, calls `sync_cards()`, and transitions Timing via `sync_timing()`.
- [ ] Non-active players and Spectators cannot play a card (`action_play_card` is rejected by the Host).
- [ ] Self-owned local data — rotating/moving the camera view, opening/closing the Discard Pile or Deck inspection windows, and hovering cards in hand outside `Play Time` — stays strictly local and never triggers network messages or affects other Peers' screens.
