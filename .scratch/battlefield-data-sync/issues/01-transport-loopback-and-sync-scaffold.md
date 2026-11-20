# 01 — Transport Unreliable-Ordered Support, Single-Player Loopback & Battlefield Sync Scaffold

**What to build:** Extend the network transport seam with `RELIABLE` vs. `UNRELIABLE_ORDERED` transfer flags, replace `OfflineMultiplayerPeer` in the Single-Player Scene with a local loopback transport (`is_host = true`, `Player A = 1`, `Player B = empty`), wire the Multiplayer Scene manager to pass its transport and room seat assignments (`Player A`, `Player B`, `Spectator`) into the Battlefield on Start Game, and establish the Host-authoritative command-to-sync scaffold on the Battlefield (even when the Host is a Spectator while two other Peers occupy `Player A` and `Player B`).

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [x] The transport interface supports specifying transfer reliability (`RELIABLE` vs. `UNRELIABLE_ORDERED`) on `broadcast`, `send_to_host`, and `send_to_peer` (defaulting to `RELIABLE` so existing callers remain unchanged).
- [x] The Dev ENet transport maps `RELIABLE` and `UNRELIABLE_ORDERED` to the corresponding ENet packet flags, and the in-memory fake transport records the transfer flag used so tests can assert whether a message was sent reliably or unreliably.
- [x] A local loopback transport implementation of the transport seam delivers messages in-memory with `is_host = true` and local peer ID `1`.
- [x] Entering the Single-Player Scene mounts the Battlefield with the local loopback transport, assigning local peer `1` to `Player A` and leaving the `Player B` seat empty (replacing `OfflineMultiplayerPeer`).
- [x] Starting a battle from the Multiplayer Scene passes the active transport, `is_host`, local peer ID, and the room's seat assignments (`Player A`, `Player B`, `Spectator`s) to the Battlefield instance on every Peer.
- [x] The Host's Battlefield instance acts as the single source of truth regardless of whether the Host is seated as `Player A`, `Player B`, or a `Spectator`, while non-Host Peers act as synced views that send player action messages to the Host.
- [x] Even on the Host (and in Single-Player), local player actions go through the command → Host authority → sync callback pipeline rather than mutating display state directly.
