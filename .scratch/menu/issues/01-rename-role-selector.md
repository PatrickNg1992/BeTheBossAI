# 01 — Rename the multiplayer stub's "Menu" nodes to "RoleSelector"

**What to build:** the existing multiplayer role-selector stub no longer uses the name "Menu" anywhere — its root node and its instance inside the multiplayer scene are renamed to "RoleSelector" — so that "Menu" unambiguously means the game's first page. The stub's behaviour is unchanged; nothing the player can do changes yet.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The role-selector stub's root node is named "RoleSelector"
- [ ] The stub's instance inside the multiplayer scene is named "RoleSelector"
- [ ] No node or reference in the game still uses the name "Menu" for that stub
- [ ] The stub behaves exactly as before the rename
