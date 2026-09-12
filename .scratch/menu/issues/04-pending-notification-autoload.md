# 04 — Pending-Notification autoload

**What to build:** a new autoload (separate from the localization autoload) that holds at most one pending Notification, stored as a localization key. When the Menu becomes the current scene, it checks the slot, shows the generic Notification popup with that message, and clears the slot, so kicked or disconnected players are told exactly once why they landed on the Menu.

**Blocked by:** 02 — Menu scene as the project's main scene.

**Status:** ready-for-agent

- [ ] The autoload holds at most one pending Notification (a localization key)
- [ ] Entering the Menu with a pending Notification shows the generic popup with that message
- [ ] The slot is cleared after being shown, so re-entering the Menu shows nothing
- [ ] Entering the Menu with an empty slot shows no popup
- [ ] The localization autoload stays purely about text (the new autoload does not touch it)
