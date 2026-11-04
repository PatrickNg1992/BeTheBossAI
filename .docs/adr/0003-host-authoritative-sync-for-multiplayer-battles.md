# Host-authoritative sync for multiplayer battles

In multiplayer battles, the Host (the Peer who opened the room and runs the server) is always the single source of truth for battle state — whether the Host is playing as Player A, Player B, or watching as a Spectator. All Peers (Player A, Player B, and Spectators) — including the Host's own display and Single-Player mode (where the local player is Host and Player A, and the Player B seat is empty) — use the same flow: player inputs send action messages to the Host, the Host updates the authoritative state, and the display renders from that synced state. Hands are visible owner-only; Spectators see neither hand.

Chosen over peer-to-peer negotiation or client-predictive sync because determinism matters little here — battle events (cue-shots, collisions, card effects) must resolve identically on every screen, and one authority avoids "two sources of truth" desyncs. Hard to reverse: the whole connection logic, battle sync, and hand-privacy model hang off this decision.

## Considered Options

- **Peer-to-peer state sharing with rollback/prediction** — rejected: the physics-driven cue-table and card effects are not rollback-friendly; two sources of truth invite desync.
- **Dedicated headless server** — rejected: out of scope; the Host is always a player (listen-server).

## Consequences

- All gameplay state changes flow through the Host's validation; unreliable RPC is fine for positions, but actions use reliable mode.
- **Deck secrecy is visibility-only, not data separation.** The Host syncs both decks to the Peers and the game logic knows both decks' full order; a card's identity is hidden from non-owners at the UI layer only. *(Amended 2026-09-11: a trust model — each player owning their deck locally — was rejected. It makes hand/deck cheating trivial: keeping the deck order intact under the Host's authority matters more than hiding data from the Host. Without a dedicated server, cheating is not fully preventable; this is the lesser evil.)*
- Spectators are excluded from hands/deck contents explicitly (UI-level, same as the other player's view of the Host's cards).

*(Amended 2026-09-19: the "Opponent" role is retired in favour of Player A / Player B, per the updated multiplayer manual. The decision itself is unchanged.)*
- Version Check and Game Config replication are also Host-to-peer, one-way.