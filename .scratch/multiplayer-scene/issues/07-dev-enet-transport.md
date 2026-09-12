# 07 — Dev ENet transport

**What to build:** the real network transport backing the transport seam — ENet over direct IP + port (default 8910) — so an actual two-machine connection works end-to-end through the manager. Covered by at most a thin integration smoke test (two in-process instances over localhost); all behavioural testing stays behind the fake transport.

**Blocked by:** 01 — Transport seam + Multiplayer Scene manager skeleton.

**Status:** ready-for-agent

- [ ] An ENet-based transport implements the transport interface
- [ ] Dev Connection Mode constructs this transport (default port 8910)
- [ ] Two in-process instances can host and join over localhost in a smoke test
- [ ] The rest of the test suite still runs purely against the fake transport
