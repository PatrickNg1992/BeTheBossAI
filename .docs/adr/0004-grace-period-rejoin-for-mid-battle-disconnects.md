# Grace-period rejoin for mid-battle disconnects

When Player A or Player B drops mid-battle, the battle freezes for all Peers and a grace period opens. If the Peer rejoins within the grace period, the Host restores a full battle-state snapshot and the battle resumes; if not, the game ends — still-connected Peers return to the Waiting Room, the dropped Peer lands on the Menu. All Peers see a "Connecting…" message (with a Leave button that ends the grace early) during the freeze.

Chosen over "waiting-room-only rejoin" (Option A) because a mid-battle disconnect in PvP shouldn't kill the game outright — players deserve a chance to recover from a dropped connection. Chosen over "no rejoin" (v1) similarly — a frozen battle that can be resumed is a better experience. Hard to reverse: snapshot/restoration plumbing has to be built into every subsystem (physics, timing, cards) up front.

## Considered Options

- **Waiting-room-only rejoin (Option A)** — rejected: a dropped connection in PvP is common; killing the match every time is the wrong player experience.
- **Peer-to-peer reconciliation (no snapshot)** — rejected: violates the Host-authoritative model (ADR-0003); only the Host can restore.

## Consequences

- All battle subsystems (physics, timing, cards, canvas) must expose a serializable snapshot and a restore path.
- The grace period applies to **Player A / Player B drops in either direction**. The link is symmetric: when it drops, each side only knows "the other is gone" — so both sides freeze and the rejoin flow applies. (If the Host's connection resumes, the other player rejoins; a truly dead Host process simply never comes back and the grace expires.) A Spectator disconnect never freezes the game — the game tries to reconnect and shows a "Connecting…" message only to the disconnected Spectator. The only *clean* session end is the Host's explicit **Close Room** command, sent while the connection is alive — Peers receive the signal, get kicked to the Menu with a Notification.
- v1 grace period length: **30 seconds**, configurable later.
- All Peers see a frozen "Connecting…" state with a **Leave** button that ends the grace immediately (still-connected Peers → Waiting Room; dropped Peer → Menu). On rejoin (Role Selector → Version Check → straight into the frozen battle, skipping the Waiting Room), resume from snapshot; on expiry, game ends — still-connected Peers return to the Waiting Room, the dropped Peer lands on the Menu, and late joiners are rejected with a Notification.

*(Amended 2026-09-19: the "Opponent" role is retired in favour of Player A / Player B, per the updated multiplayer manual. The frozen state now shows "Connecting…" to everyone in the room instead of "Opponent disconnected, waiting…". A Spectator disconnect is no longer silent — the game tries to reconnect and shows "Connecting…" only to the disconnected Spectator.)*