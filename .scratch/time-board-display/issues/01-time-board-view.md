# 01 — Time Board view (look and feel first)

**What to build:** the visible Time Board on the battlefield canvas as a dumb view driven by placeholder/crafted state (the real model lands next): the serpentine layout of two 10-slot bars with the goal at the upper-left, the energy fill growing from the lower-left, tag arrows above the upper bar / below the lower bar, and per-tag count + Turns-to-goal integers. Animations exist in the three kinds the spec distinguishes — smooth one-slot glide, the 9→10 fade-out/fade-in teleport wrap, and the spend-energy rewind — invoked from crafted placeholder states so the look and feel can be tuned in the editor before any rules exist. No game logic inside the view.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The board renders two bars of 10 slots in the serpentine layout with the goal at the upper-left
- [ ] An energy fill renders along the path from the lower-left
- [ ] Tag arrows render pointing into the bar (above the upper bar, below the lower bar), each showing unit count and Turns-to-goal integers
- [ ] Glide, fade-teleport wrap, and spend-rewind animations can be triggered from crafted states
- [ ] The view contains no board rules — it renders and animates whatever state it is fed
- [ ] No text other than the integers appears on the board
