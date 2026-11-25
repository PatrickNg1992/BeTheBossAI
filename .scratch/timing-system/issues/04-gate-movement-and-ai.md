# 04 — Gate existing movement and AI behind Timing signals

**What to build:** the existing free-running behaviours are wired to the clock — `dragon_player.gd`'s free movement and `base_enemy.gd`'s always-on AI subscribe to the TimingManager signals and enable/disable themselves per the current Timing, following the signal-first precedent of `card_manager.gd`. The behaviours themselves are not redesigned; only their gating.

**Blocked by:** 01 — TimingManager core cycle.

**Status:** implemented

- [x] Dragon-player movement is frozen outside the Timings where it should act
- [x] Enemy AI state machines run only when their Timing allows (gated to `Action Time` via `TimingManager` signals in `base_enemy.gd`, superseded by `AutoFightManager`)
- [x] Aiming-game input (drag-to-aim) is gated by Play Time (`CueShotManager`)
- [x] Remove the temporary `Space`-key transition from `Play Time` to `Puck-puck Time!` (`KEY_SPACE` in `demo_battlefield.gd`) and the 5-second `Puck-puck Time!` placeholder timer (`PUCK_PUCK_PLACEHOLDER_SECONDS`), replacing them with real Cue-Shot launch and all-pucks-at-rest detection
- [x] All gating happens through Timing-change signals, not by checking manager internals
