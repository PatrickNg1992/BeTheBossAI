# 02 — Prepare Time entry

**What to build:** on entering Prepare Time, the clock shapes the Time Board to the coming Wave's opening state — Energy set to exactly 10, old Action Tags removed, the incoming team's initial Action Tags placed — then freezes for the rest of the phase, so the player can read the board and plan before pressing Start Wave. Energy does not regenerate while preparing.

**Blocked by:** 01 — TimingManager core cycle.

**Status:** ready-for-agent

- [ ] Entering Prepare animates the board to the opening state, then freezes
- [ ] Opening state: Energy exactly 10, old tags cleared, incoming team's initial tags placed
- [ ] No charging or tag movement happens during the rest of Prepare
