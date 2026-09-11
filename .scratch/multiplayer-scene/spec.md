# Spec: Multiplayer Scene (Connection Logic)

Status: ready-for-agent

Vocabulary per `GLOSSARY.md` (# Multiplayer) and `CONTEXT.md`. Governing decisions: ADR-0003 (Host-authoritative sync; deck secrecy is visibility-only) and ADR-0004 (grace-period rejoin for mid-battle disconnects). Source manual: `.docmanual/multiplayer/` (do not edit).

## Problem Statement

A player who wants a two-player PvP game (optionally with Spectators) currently has no way to play with another person: there is no scene, no connection flow, and no shared vocabulary for roles in code. The player needs a place to host or join a game, wait for the other player, start the battle together, and survive dropped connections without the experience silently breaking.

## Solution

A **Multiplayer Scene**, reachable from the Menu, that owns the whole multiplayer flow. It is itself invisible: a manager script swaps three sub-scenes inside a container — **Role Selector**, **Waiting Room**, and the **Battlefield** (loaded into the container when the game starts). The manager controls the **connection** (connect/disconnect, Version Check, Rejoin Grace Period, Notifications); the Battlefield controls **synchronization of objects in the field** (positions, actions, hands).

Roles: **Host** (a player; runs the listen-server and controls one Boss Monster), **Opponent** (the second player), **Spectator** (non-playing observer, capped at 4). **Peer** = any of the three.

v1 connects in **Dev Connection Mode** only: direct IP + port (default 8910). Steam mode is undecided and deferred.

## User Stories

**Entering and choosing a role**

1. As a player, I want to reach the Multiplayer Scene from the Menu, so that I can start or join a multiplayer game.
2. As a player, I want to see a Role Selector offering Host / Opponent / Spectator, so that I can choose how to participate.
3. As a player, I want to go back to the Menu from the Role Selector, so that I can change my mind.
4. As a player, I want to enter a mandatory Player Name (max 32 characters) in the Role Selector, so that other Peers can identify me in the Waiting Room.
5. As an Opponent or Spectator, I want to enter the Host's IP and port before connecting, so that I can reach the right room (Dev mode).
6. As an Opponent or Spectator, I want to see a "Connecting…" state inside the Role Selector while connecting, so that I know something is happening.
7. As an Opponent or Spectator, I want a clear localized message when the connection fails (ENet default timeout), so that I can fix the IP/port and retry.

**Hosting**

8. As a Host, I want to land in the Waiting Room after choosing to host, so that I can configure the room before anyone joins.
9. As a Host, I want to edit the port in the Waiting Room (Dev mode), so that I can avoid port conflicts.
10. As a Host, I want to toggle whether Spectators are accepted, so that I control who watches my game.
11. As a Host, I want to click Confirm to start waiting as a server, so that Peers can connect to me.
12. As a Host, I want to see connected Peers appear in the Waiting Room — the Opponent in a seat, Spectators in a name list — so that I know who is present.
13. As a Host, I want the "Start Game" button to be enabled only when the Opponent seat is filled, so that a PvP game always starts with two players.
14. As a Host, I want the "Start Game" button to disable again if the Opponent disconnects while waiting, so that I can't start a broken game.
15. As a Host, I want my Game Config edits to replicate to all Peers' Waiting Room screens, so that everyone sees the same room state.

**Joining**

16. As an Opponent, I want the Host to Version Check me on connect, so that incompatible builds can't silently desync.
17. As an Opponent, I want a localized "version mismatch" message (on both sides) when my version differs, so that I know why I was rejected.
18. As an Opponent, I want to land in the Waiting Room on successful connect and see the Host's room state mirrored, so that I know the room configuration.
19. As an Opponent, I want a "Leave" button instead of "Start Game", so that I can exit the room back to the Menu.
20. As a Spectator, I want to be accepted only if the Host allows Spectators and the Spectator Cap (4) is not reached, so that rooms stay manageable.
21. As a Spectator, I want to see the Waiting Room with a "Leave" button, so that I can exit back to the Menu.

**Starting and finishing a game**

22. As a Host, I want clicking "Start Game" to load the Battlefield into the Multiplayer Scene's container for all Peers, so that everyone enters the battle together.
23. As a Peer, I want the connection to stay open when a game ends, so that we return to the Waiting Room and can play again without reconnecting.
24. As a Host, I want to be able to start another game after returning to the Waiting Room, so that rematches are frictionless.

**Leaving and closing**

25. As an Opponent or Spectator, I want "Leave" to disconnect me and return me to the Menu, so that I can exit cleanly.
26. As a Host, I want a "Close Room" button that kicks all Peers (with a Notification) and returns me to the Menu, so that I can end the session cleanly.
27. As a Peer, I want a localized "host closed the room" Notification when the Host closes the room, so that I understand why I was kicked.

**Disconnects mid-battle (Rejoin Grace Period, ADR-0004)**

28. As a Peer, I want the battle to freeze with an "Opponent disconnected, waiting…" state when the Host↔Opponent link drops, so that the game pauses fairly for everyone.
29. As a Peer, I want a 30-second grace period during which the dropped player can rejoin, so that a momentary network blip doesn't kill the match.
30. As a dropped player, I want to rejoin via the Role Selector (Version Check applies) and land directly in the frozen battle, skipping the Waiting Room, so that rejoining is fast.
31. As a Peer, I want a "Leave" button on the frozen screen that ends the grace period immediately (still-connected Peers → Waiting Room; dropped Peer → Menu), so that nobody is stuck waiting.
32. As a Peer, I want the game to end when the grace period expires — still-connected Peers return to the Waiting Room, the dropped Peer lands on the Menu — so that a permanently lost player doesn't hang the session.
33. As a late joiner, I want to be rejected with a Notification if the grace period already expired, so that I can't join a dead game.
34. As a Peer, I want a Spectator disconnect to do nothing (the slot just frees up), so that observers leaving never interrupts the match.

**Localization**

35. As a player, I want all display text (roles, buttons, Notifications, frozen state) to come from the multiLang holder, so that the game stays multi-language.

## Implementation Decisions

- **New module: Multiplayer Scene + manager script.** The scene is invisible; the manager swaps Role Selector / Waiting Room / Battlefield in a container (one visible at a time) and drives them. The manager owns all connection logic: role state, connect/disconnect, Version Check, Waiting Room state replication (Host→Peers), Start gating, Notifications, and Rejoin Grace Period orchestration.
- **New seam: transport interface.** The manager talks to a network-transport abstraction (operations: host, join, leave, close room; events: peer joined/left, connection succeeded/failed, link lost). Two implementations: **Dev transport** (ENet, default port 8910) and a future **Steam transport** — the Connection Mode selects which one is constructed. Tests use a fake in-memory transport.
- **Responsibility split (per glossary):** the manager controls the connection; the Battlefield controls in-field object synchronization. During battle the manager keeps handling connection issues — it signals the Battlefield to freeze on link drop and to resume/restore on rejoin (ADR-0004). The snapshot's content is a battle-side concern (see Out of Scope).
- **Role Selector** (Control sub-scene): role choice (Host / Opponent / Spectator), mandatory Player Name field (32-char cap), IP + port fields for joining roles, Back → Menu, inline "Connecting…" state (ENet default timeout), failure message in place.
- **Waiting Room** (Control sub-scene): two seats (Host seat, Opponent seat) + a simple Spectator name list (cap 4). Host sees: Game Config (Spectator toggle + Dev port), "Start Game" (enabled iff the Opponent seat is filled; no ready flag in v1), "Close Room". Opponent/Spectator sees: "Leave". Room state replicates Host→Peers; Peers render read-only mirrors.
- **Battlefield as sub-scene** (per the settled Q3 decision — overrides `gameScenes.md`'s "loads the Battlefield" wording): loaded into the same container on Start Game; identical scene on all Peers; the Host's instance is authoritative (ADR-0003).
- **Version Check**: a version string constant (file placement: developer will add later) compared on connect; mismatch rejects with localized Notification on both sides.
- **Notification**: one generic localized popup reused for version mismatch, connection failed, connection lost, host closed the room. All text via the multiLang holder.
- **Rejoin Grace Period** (ADR-0004): 30s default (configurable later); triggers only on Host↔Opponent link loss (symmetric — each side just sees the other vanish); Spectator drops are silent; rejoin skips the Waiting Room straight into the frozen battle; expiry ends the game (connected Peers → Waiting Room, dropped Peer → Menu); Leave button ends grace early; late joins rejected with Notification.
- **Close Room** is the only clean session end: an explicit Host command while the connection is alive; Peers receive the signal and are kicked to the Menu with a Notification.
- **Game Config v1**: Spectator acceptance toggle + Dev-mode port; the battle always uses the demo battlefield. Stage/config details are a separate future design (not the single-player World Map list).
- **Deck secrecy is visibility-only** (ADR-0003 amendment): the Host syncs both decks and the game logic knows both decks' full order; hiding happens at the UI layer. Hand counts and the discard pile are visible to all Peers.

## Testing Decisions

- **What makes a good test**: drive the seams, assert external behavior only — which sub-scene is visible in the container, seat/list contents, button visibility + enabled state, which Notification (localization key) was shown, freeze overlay + grace timer state, rejoin routing. Never assert manager internals, ENet details, or node paths below the container.
- **Seams (two, as agreed)**: (1) the **manager's public boundary** — tests instantiate the Multiplayer Scene and drive the manager; (2) the **transport interface** — tests inject a fake in-memory transport to simulate Peers joining, dropping, and rejoining deterministically (no real sockets, no timing flakiness beyond the grace timer).
- **Modules tested**: the manager (role flows, Start gating, Close Room, Version Check routing, grace orchestration) and the Waiting Room/Role Selector views through the manager. The dev ENet transport gets at most a thin integration smoke test (two in-process instances over localhost) — its details are below the seam.
- **Prior art**: none — this repo has no GDScript tests yet. Suites live in `res://tests/` as `test_*.gd` files with `test_*` methods, discovered by the editor's test runner; this feature establishes the pattern.

## Out of Scope

- **Steam Connection Mode** — undecided; the transport seam is where it will slot in.
- **In-field object synchronization** (positions, hands, actions RPC) — ADR-0003's domain; needs a follow-up spec once PvP rules exist.
- **Battle-state snapshot serialization content** (ADR-0004 consequence) — what goes into a snapshot depends on PvP rules, which the user will design later. This spec covers only the manager-side orchestration (freeze signal, timer, overlay, Leave, rejoin routing).
- **Stage/config design** — battle always uses the demo battlefield in v1.
- **Spectator HUD design** — placeholder only; details when the game is more prepared.
- **PvP rules** — user will design in detail later.
- **Single-player path** — already separate (OfflineMultiplayerPeer loading the Battlefield); untouched.
- **Anti-cheat beyond Host authority** — acknowledged limitation in ADR-0003.

## Further Notes

- Glossary entries to build against: `GLOSSARY.md` # Multiplayer (Host, Opponent, Spectator, Peer, Multiplayer Scene, Connection Mode, Game Config, Waiting Room, Notification, Connecting State, Version Check, Rejoin Grace Period, Spectator Exclusion List, Spectator Cap, Player Name).
- ADRs: `.docs/adr/0003-host-authoritative-sync-for-multiplayer-battles.md`, `.docs/adr/0004-grace-period-rejoin-for-mid-battle-disconnects.md`.
- Settled contradictions with the manual: Battlefield is a sub-scene inside the container (not a sibling the scene "loads"); "the room" is informal for the Waiting Room; "spectator opponent" in the manual is a typo.
- AGENTS.md rule: all display text must live in the multiLang holder (`src/multiLang/`).
