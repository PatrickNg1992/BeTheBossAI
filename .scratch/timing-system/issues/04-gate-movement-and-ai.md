# 04 — Gate existing movement and AI behind Timing signals

**What to build:** the existing free-running behaviours are wired to the clock — `dragon_player.gd`'s free movement and `base_enemy.gd`'s always-on AI subscribe to the TimingManager signals and enable/disable themselves per the current Timing, following the signal-first precedent of `card_manager.gd`. The behaviours themselves are not redesigned; only their gating.

**Blocked by:** 01 — TimingManager core cycle.

**Status:** ready-for-agent

- [ ] Dragon-player movement is frozen outside the Timings where it should act
- [ ] Enemy AI state machines run only when their Timing allows
- [ ] Aiming-game input (drag-to-aim) is gated by Play Time
- [ ] All gating happens through Timing-change signals, not by checking manager internals
