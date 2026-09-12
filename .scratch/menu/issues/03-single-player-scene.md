# 03 — Single-Player Scene via the Play button

**What to build:** pressing Play on the Menu takes the player into battle through a new invisible Single-Player Scene — a loader with no UI that sets up an `OfflineMultiplayerPeer` and instantiates the Battlefield as its child — so single-player and multiplayer share one Battlefield load path. The player lands in the existing test-scene battlefield.

**Blocked by:** 02 — Menu scene as the project's main scene.

**Status:** ready-for-agent

- [ ] Pressing Play on the Menu routes to the Single-Player Scene
- [ ] The Single-Player Scene sets up an `OfflineMultiplayerPeer` on entry
- [ ] The Single-Player Scene loads the battlefield (the existing test scene) as its child
- [ ] The Single-Player Scene has no visible UI of its own
- [ ] The battle plays as it did when booting directly into the test scene
