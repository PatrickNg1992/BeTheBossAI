# 04 — Version Check on connect

**What to build:** the Host checks a joining Peer's version string against its own during connect. On mismatch the join is rejected and both sides receive a localized "version mismatch" Notification, so incompatible builds can't silently desync. On match the join proceeds into the Waiting Room as normal.

**Blocked by:** 02 — Role Selector flow.

**Status:** ready-for-agent

- [ ] A version string constant exists and is compared on every connect
- [ ] A mismatching Peer is rejected and never lands in the Waiting Room
- [ ] Both the Host and the rejected Peer get a localized "version mismatch" message
- [ ] A matching Peer connects and lands in the Waiting Room exactly as before this check
