# 01 — Time Board view (look and feel first)

**What to build:** the visible Time Board on the battlefield canvas as a dumb view driven by placeholder/crafted state (the real model lands next): the serpentine layout of two 10-slot bars with the goal at the upper-left, the energy fill growing from the lower-left, tag arrows above the upper bar / below the lower bar, and per-tag count + Turns-to-goal integers. Animations exist in the three kinds the spec distinguishes — smooth one-slot glide, the 9→10 fade-out/fade-in teleport wrap, and the spend-energy rewind — invoked from crafted placeholder states so the look and feel can be tuned in the editor before any rules exist. No game logic inside the view.

**Blocked by:** None — can start immediately.

**Status:** implemented (70/70 tests green — UI approved by the user over 3 iterations)

**Progress notes:**
- New view: `src/canvas/time_board.tscn` + `time_board.gd` (`class_name TimeBoard`), instanced under `Canvas` in `demo_bettlefield.tscn` with `demo_mode = true` (crafted-state preview loop; **ticket 02 must remove demo_mode** and drive the view from the model).
- Medieval theme v3 (user-approved): semi-transparent wooden panel frame, big red flag standalone at the far left (goal side), rectangle slots 32×12, pennant arrows 32×18 with the count printed ON the arrow (dark red on bone), Turns integer outside in parchment. Assets: `src/resource/battlefield/{wood_panel,arrow_up,arrow_down,goal_flag,sword}.png` (sword.png unused after v3 — kept as spare). Generator: `tests/_gen_assets.gd/.tscn` (rerun to regenerate; NOT a test suite).
- Motion: smooth charging (tweened fill), charge-complete pop, tag glides lasting one Turn, 9→10 fade-teleport, spend rewind. Tags rest ON the leading slot edge; integers count down when the arrow lands on the next edge (user requirement).
- View API (the model→view seam for ticket 02): `render_state(state)` / `apply_state(state)` with state `{"energy": int, "charge": float, "tags": {slot: {"count","turns"}}}`; observable outputs `slot_bar/slot_column/slot_fill_ratio/tag_info` + `last_animation_kind`. Tests: `tests/test_time_board_view.gd` (11 tests).

- [x] The board renders two bars of 10 slots in the serpentine layout with the goal at the upper-left
- [x] An energy fill renders along the path from the lower-left
- [x] Tag arrows render pointing into the bar (above the upper bar, below the lower bar), each showing unit count and Turns-to-goal integers
- [x] Glide, fade-teleport wrap, and spend-rewind animations can be triggered from crafted states
- [x] The view contains no board rules — it renders and animates whatever state it is fed
- [x] No text other than the integers appears on the board
