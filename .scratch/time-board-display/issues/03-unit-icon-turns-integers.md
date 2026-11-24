# 03 — Unit-icon "Turns to goal" integers on the canvas

**What to build:** each unit icon on the battlefield canvas shows the same Turns-to-goal integer as its tag on the Time Board, sourced from the model's per-unit lookup, following the existing unproject-to-screen pattern used by enemy health bars — so the board and the battlefield can never disagree.

**Blocked by:** 02 — Time Board model (the per-unit lookup lives there).

**Status:** implemented (per-unit Action Countdown driven by TimeBoardModel into UnitInformationDO / UnitDisplay)

- [x] Every unit icon shows a Turns-to-goal integer matching its tag on the board
- [x] The integer is sourced from the Time Board model, not computed in the icon
- [x] The icon follows the UnitInformationBoard UnitDisplay layout (replacing the deprecated floating 3D-to-2D enemy health bars)
