# 01 — Time Board half-slot Energy and bottom-left consume/over-drag preview

**What to build:** Extend the Time Board view to render half-slot (`0.5`) Energy amounts (`0.0..20.0`) and an aiming `preview_cost` (`1.0..9.0` in `0.5`-slot steps). When `preview_cost > 0`, the Time Board highlights the required Energy starting from the bottom-left (`slot 0`) along the serpentine path in a distinct consume-preview colour up to the player's owned Energy; if `preview_cost` exceeds owned Energy, the over-dragged excess continues past the filled Energy slots in **red**. Remaining owned Energy beyond `preview_cost` stays in the normal gold Energy colour.

**Blocked by:** None — can start immediately.

**Status:** implemented (90/90 tests green)

- [x] The Time Board renders half-slot (`0.5`) Energy values (`0.0..20.0`) accurately along the serpentine path
- [x] Feeding an affordable `preview_cost` (`<= owned_energy`) highlights slots starting from `slot 0` (bottom-left) up to `preview_cost` in the consume-preview colour while leaving the rest of `owned_energy` in the normal Energy colour
- [x] Feeding an over-dragged `preview_cost` (`> owned_energy`) highlights `0..owned_energy` in the consume-preview colour and continues from `owned_energy..preview_cost` in red
- [x] Clearing `preview_cost` (`0.0`) restores the normal owned Energy fill display
- [x] View-seam tests verify half-slot fills, affordable consume preview from `slot 0`, and red over-drag preview past owned Energy
