# Spec: Multiplayer Scene (Connection Logic)

Status: ready-for-agent

Vocabulary per `GLOSSARY.md` (# Multiplayer) and `CONTEXT.md`. Governing decisions: ADR-0003 (Host-authoritative sync; deck secrecy is visibility-only) and ADR-0004 (grace-period rejoin for mid-battle disconnects). Source manual: `.docmanual/multiplayer/` (do not edit) — including `waitingRoomUI.md` for the Waiting Room layout.

## Problem Statement

A player who wants a two-player PvP game (optionally with Spectators) currently has no way to play with another person: there is no scene, no connection flow, and no shared vocabulary for roles in code. The player needs a place to host or join a game, wait for the other player, pick a side, start the battle together, and survive dropped connections without the experience silently breaking.

## Solution

A **Multiplayer Scene**, reachable from the Menu, that owns the whole multiplayer flow. It is itself invisible: a manager script swaps three sub-scenes inside a container — **Role Selector**, **Waiting Room**, and the **Battlefield** (loaded into the container when the game starts). The manager controls the **connection** (connect/disconnect, Version Check, Rejoin Grace Period, Notifications); the Battlefield controls **synchronization of objects in the field** (positions, actions, hands).

Roles: **Player A** and **Player B** (the two playing seats — each controls one Boss Monster / team) and **Spectator** (non-playing observer). **Peer** = any of the three. The **Host** is the Peer who opened the room and runs the listen-server; by default the Host takes Player A and the first joiner takes Player B. Roles are chosen **inside the Waiting Room** by clicking seats / the Spectator list — not in the Role Selector. (The "Opponent" concept is retired.)

v1 connects in **Dev Connection Mode** only: direct IP + port (default 8910). Steam mode is undecided and deferred.

## User Stories

**Entering and choosing how to connect**

1. As a player, I want to reach the Multiplayer Scene from the Menu, so that I can start or join a multiplayer game.
2. As a player, I want the Role Selector to offer Host a game room / Join a game / Back to the Menu, so that I can choose how to connect.
3. As a player, I want to go back to the Menu from the Role Selector, so that I can change my mind.
4. As a joining player, I want a Join form with a mandatory Player Name (max 32 characters), connection info (IP + port), and a Join button, so that I can reach the right room and be identified in the Waiting Room.
5. As a joining player, I want to see a "Connecting…" state inside the Role Selector while connecting, so that I know something is happening.
6. As a joining player, I want a clear localized message when the connection fails (ENet default timeout), so that I can fix the IP/port and retry.

**Hosting**

7. As a Host, I want to land in the Waiting Room after choosing to host, so that I can configure the room before anyone joins.
8. As a Host, I want to edit my name in the Room Configuration before the room opens, so that Peers can identify me.
9. As a Host, I want to edit the port in the Waiting Room (Dev mode), so that I can avoid port conflicts.
10. As a Host, I want to configure the Room Capacity (minimum 2, maximum 6) before the room opens, so that I control how many Peers the room holds.
11. As a Host, I want the Host's name and Room Capacity to lock once the room opens, so that joiners always see a stable room setup.
12. As a Host, I want to click Confirm to start waiting as a server, so that Peers can connect to me.
13. As a Host, I want to see connected Peers appear in the Waiting Room — names on the Players' Seats and in the Spectator list — so that I know who is present.
14. As a Host, I want the "Start Game" button visible only to me and enabled only when both Players' Seats are taken, so that a PvP game always starts with two players.
15. As a Host, I want the "Start Game" button to disable again if a seat empties while waiting, so that I can't start a broken game.
16. As a Host, I want my Game Config edits to replicate to all Peers' Waiting Room screens, so that everyone sees the same room state.

**Choosing a role in the Waiting Room**

17. As a Host, I want to take the Player A seat by default, so that the room has a first player immediately.
18. As the first joiner, I want to become Player B by default, so that the two seats fill in join order.
19. As a later joiner, I want to become a Spectator when both seats are taken, so that I can still watch the game.
20. As a Peer, I want to click an empty seat to take it, so that I can switch from Spectator to player.
21. As a seated player, I want to click the Spectator list to step down to Spectator, so that I can give up my seat.

**Joining**

22. As a joining Peer, I want the Host to Version Check me on connect, so that incompatible builds can't silently desync.
23. As a joining Peer, I want a localized "version mismatch" message (on both sides) when my version differs, so that I know why I was rejected.
24. As a joining Peer, I want to land in the Waiting Room on successful connect and see the Host's room state mirrored, so that I know the room configuration.
25. As a non-Host Peer, I want a "Leave" button instead of "Start Game" / "Close Room", so that I can exit the room back to the Menu.
26. As a joining Peer, I want to be rejected when the room is full (Room Capacity reached), so that rooms stay manageable.
27. As a connected Peer, I want to return to the Menu with a Notification if the Host goes offline while I'm waiting, so that I'm not stuck in a dead room.

**Starting and finishing a game**

28. As a Host, I want clicking "Start Game" to load the Battlefield into the Multiplayer Scene's container for all Peers, so that everyone enters the battle together.
29. As a Peer, I want the connection to stay open when a game ends, so that we return to the Waiting Room and can play again without reconnecting.
30. As a Host, I want to be able to start another game after returning to the Waiting Room, so that rematches are frictionless.

**Leaving and closing**

31. As a non-Host Peer, I want "Leave" to disconnect me and return me to the Menu, so that I can exit cleanly.
32. As a Host, I want a "Close Room" button that kicks all Peers (with a Notification) and returns me to the Menu, so that I can end the session cleanly.
33. As a Peer, I want a localized "host closed the room" Notification when the Host closes the room, so that I understand why I was kicked.

**Disconnects mid-battle (Rejoin Grace Period, ADR-0004)**

34. As a Peer, I want the battle to freeze with a "Connecting…" message shown to everyone in the room when Player A or Player B drops, so that the game pauses fairly for everyone.
35. As a Peer, I want a 30-second grace period during which the dropped player can rejoin, so that a momentary network blip doesn't kill the match.
36. As a dropped player, I want to rejoin via the Role Selector (Version Check applies) and land directly in the frozen battle, skipping the Waiting Room, so that rejoining is fast.
37. As a Peer, I want a "Leave" button on the frozen screen that ends the grace period immediately (still-connected Peers → Waiting Room; dropped Peer → Menu), so that nobody is stuck waiting.
38. As a Peer, I want the game to end when the grace period expires — still-connected Peers return to the Waiting Room, the dropped Peer lands on the Menu — so that a permanently lost player doesn't hang the session.
39. As a late joiner, I want to be rejected with a Notification if the grace period already expired, so that I can't join a dead game.
40. As a Peer, I want a Spectator disconnect to never freeze the game — it tries to reconnect and shows a "Connecting…" message only to the disconnected Spectator — so that observers leaving never interrupts the match.

**Localization**

41. As a player, I want all display text (roles, buttons, Notifications, frozen state) to come from the multiLang holder, so that the game stays multi-language.

## Implementation Decisions

- **New module: Multiplayer Scene + manager script.** The scene is invisible; the manager swaps Role Selector / Waiting Room / Battlefield in a container (one visible at a time) and drives them. The manager owns all connection logic: role state, connect/disconnect, Version Check, Waiting Room state replication (Host→Peers), Start gating, Notifications, and Rejoin Grace Period orchestration.
- **New seam: transport interface.** The manager talks to a network-transport abstraction (operations: host, join, leave, close room; events: peer joined/left, connection succeeded/failed, link lost). Two implementations: **Dev transport** (ENet, default port 8910) and a future **Steam transport** — the Connection Mode selects which one is constructed. Tests use a fake in-memory transport.
- **Responsibility split (per glossary):** the manager controls the connection; the Battlefield controls in-field object synchronization. During battle the manager keeps handling connection issues — it signals the Battlefield to freeze on link drop and to resume/restore on rejoin (ADR-0004). The snapshot's content is a battle-side concern (see Out of Scope).
- **Role Selector** (Control sub-scene): three choices — Host a game room, Join a game, Back → Menu. Join shows a form: mandatory Player Name (32-char cap), IP + port fields, Join button, inline "Connecting…" state (ENet default timeout), failure message in place. The in-game role is NOT chosen here.
- **Waiting Room** (Control sub-scene, layout per `.docmanual/multiplayer/waitingRoomUI.md`): two clickable **Players' Seats** in the middle (Player A left, Player B right — an empty seat can be clicked to take it), a **Spectator list** on the right (displays up to 6 names — a seated player clicks it to step down), and the **Room Configuration** at the top (Host-editable). Default assignment: Host → Player A, first joiner → Player B, later joiners → Spectator. Host sees: Game Config (Host's name + Room Capacity 2–6 — both editable only before the room opens — + Dev port), "Start Game" (Host-only, enabled iff both seats are taken; no ready flag in v1), "Close Room" (Host-only). Non-Host Peers see: "Leave". Room state replicates Host→Peers; Peers render read-only mirrors except for the role-change clicks, which are requests the Host validates. If a connected Peer detects the Host went offline while waiting, they return to the Menu with a Notification.
- **Battlefield as sub-scene** (per the settled Q3 decision — overrides `gameScenes.md`'s "loads the Battlefield" wording): loaded into the same container on Start Game; identical scene on all Peers; the Host's instance is authoritative (ADR-0003).
- **Version Check**: a version string constant (file placement: developer will add later) compared on connect; mismatch rejects with localized Notification on both sides.
- **Notification**: one generic localized popup reused for version mismatch, connection failed, connection lost, host closed the room. All text via the multiLang holder.
- **Rejoin Grace Period** (ADR-0004): 30s default (configurable later); triggers only when Player A or Player B drops (symmetric — each side just sees the other vanish); the frozen state shows a "Connecting…" message to everyone in the room; rejoin skips the Waiting Room straight into the frozen battle; expiry ends the game (connected Peers → Waiting Room, dropped Peer → Menu); Leave button ends grace early; late joins rejected with Notification. A Spectator drop never freezes the game — the game tries to reconnect and shows a "Connecting…" message only to the disconnected Spectator.
- **Close Room** is the only clean session end: an explicit Host command while the connection is alive; Peers receive the signal and are kicked to the Menu with a Notification.
- **Game Config v1**: Host's name + Room Capacity (minimum 2, maximum 6 — Player A and Player B take two slots, the rest are Spectator slots), both editable only before the room opens, + Dev-mode port; the battle always uses the demo battlefield. Stage/config details are a separate future design (not the single-player World Map list).
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
- **Emoji system** — the manual allows emoji in game (no text, no voice) and the Waiting Room UI lists an "Emoji Bar: To be Confirm"; both are TBC and deferred.
- **PvP rules** — user will design in detail later.
- **Single-player path** — already separate (OfflineMultiplayerPeer loading the Battlefield); untouched.
- **Anti-cheat beyond Host authority** — acknowledged limitation in ADR-0003.

## Further Notes

- Glossary entries to build against: `GLOSSARY.md` # Multiplayer (Host, Player A / Player B, Spectator, Peer, Multiplayer Scene, Role Selector, Connection Mode, Game Config, Waiting Room, Notification, Connecting State, Version Check, Rejoin Grace Period, Spectator Exclusion List, Room Capacity, Player Name).
- ADRs: `.docs/adr/0003-host-authoritative-sync-for-multiplayer-battles.md`, `.docs/adr/0004-grace-period-rejoin-for-mid-battle-disconnects.md`.
- Settled contradictions with the manual: Battlefield is a sub-scene inside the container (not a sibling the scene "loads"); "the room" is informal for the Waiting Room; `multiplayerScene.md`'s "Role Selector: host, peer, or spectator" is superseded by the updated `multiplayerLogic.md` — the Role Selector offers host / join / back, and roles are chosen in the Waiting Room. The "Opponent" concept is retired in favour of Player A / Player B.
- AGENTS.md rule: all display text must live in the multiLang holder (`src/multiLang/`).
