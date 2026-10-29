# Research roadmap

## 1. Establish the environment boundary

Current: portable HTTP framing, a hex stream contract, deterministic mock tests,
a working GNU AWK text adapter, and an explicit unsupported-TLS gate.

Next: write a host-bridge protocol specification; prove binary round trips for
all octets and arbitrary chunk boundaries across target AWK implementations.
Exercise partial writes, EOF, timeout, cleanup, backpressure, and failures. Add
response-size limits and bounded buffering before broadening network use.

## 2. Establish binary and arithmetic foundations

Design octet buffers and fixed-width arithmetic using POSIX arithmetic only;
measure exactness and cost across interpreters. Define entropy, clock, and trust
provider contracts. Specify size limits and erase/retention limitations. Use
published test vectors and differential checks before considering cryptography.
The current HTTP text API need not become a binary-body API to do this work.

## 3. Specify a deliberately narrow TLS profile

Choose a TLS version and interoperable algorithm suite based on standards and
implementation feasibility. Specify the full handshake, record, alert, and
certificate-validation requirements before choosing modules. Do not promise a
working HTTPS client from encryption primitives alone.

## 4. Implement only after the design is reviewable

In a future project phase: primitives with known-answer tests, record protection,
handshake state, authenticated certificate validation, then the channel facade.
Use deterministic entropy only in tests. Require malformed-input tests, protocol
vectors, independent interoperability checks, and security review. Do not label
experimental crypto production-safe; investigate timing and secret-handling
limits of interpreters before any security claim.

No cryptography or TLS implementation is part of the present framework work.
