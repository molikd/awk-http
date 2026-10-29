# Reserved TLS layer

Nothing in this directory implements TLS. `policy.awk` reports that it is
unavailable, and HTTPS is rejected before network I/O.

Proposed module responsibilities, to be designed before implementation:

- `octets`: binary integers, endian conversions, and bounded byte buffers.
- `crypto`: fixed-width arithmetic, hashes, HKDF, AEAD, and key exchange.
- `records`: record framing, sequence numbers, authentication, and limits.
- `handshake`: transcript and connection state machine.
- `certificates`: DER/X.509 parsing, signatures, path validation, and hostnames.
- `channel`: authenticated application I/O above the environment stream.
- `providers`: contracts for secure entropy, time, and trust configuration.

These are planning names, not callable APIs or supplied implementations. See
[architecture](../../docs/architecture.md) and [roadmap](../../docs/roadmap.md).
