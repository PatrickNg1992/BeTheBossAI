# 01 — Transport seam + Multiplayer Scene manager skeleton

**What to build:** an invisible Multiplayer Scene whose manager script swaps sub-scenes (Role Selector, Waiting Room, later the Battlefield) inside a container, one visible at a time. The manager talks to a network-transport abstraction (host / join / leave / close room; peer joined / left / connection succeeded / failed / link lost events). Tests inject a fake in-memory transport, so the whole flow is testable without real sockets. The Connection Mode picks which transport is constructed; the Dev ENet transport lands in a later ticket.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The transport interface declares the host/join/leave/close operations and peer-event notifications above
- [ ] A fake in-memory transport implements the interface and can simulate peers joining, dropping and rejoining deterministically
- [ ] The manager swaps sub-scenes inside the container, with exactly one visible at a time
- [ ] The Connection Mode selects which transport implementation is constructed
- [ ] Manager tests run against the fake transport with no real sockets
