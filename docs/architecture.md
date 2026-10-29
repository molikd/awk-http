# Direction: POSIX AWK protocols over environment-provided bytes

The goal is to explore HTTP and eventually TLS implemented in POSIX AWK, with
an explicit environment boundary for operations the language cannot supply.
This is a framework and research plan, not an implemented TLS client.

## Layers

```text
http_get / http_post / http_request                  implemented, POSIX syntax
    HTTP request builder / response parser          implemented, textual bodies
    connection orchestration                        implemented for plain HTTP
    TLS secure channel                              PLANNED, HTTPS fails closed
    byte-stream interface (hexadecimal chunks)       implemented contract
    environment adapter                             GNU AWK TCP works today
                                                    POSIX host bridge planned
```

HTTP construction no longer belongs to the GNU AWK adapter. The same protocol
code can run against a mock or a future externally supplied stream. The current
adapter is text-only and is not sufficient for TLS ciphertext; byte-safe
interchange is an interface commitment, not a claim that all adapters implement
arbitrary binary I/O today.

## Stream contract

Load exactly one file implementing these functions. Arrays are flat and mutable;
there are no global connection handles or nested arrays in the portable layers.
Run in `LC_ALL=C`.

| Function | Contract |
| --- | --- |
| `stream_open(host, port, session)` | Return 1 after preparing a connection, or 0 with `session["error"]`. Adapter cleans up its own failed open. Connections may be lazy; first I/O can report connection failure. |
| `stream_write(session, hex)` | Consume all decoded bytes, in order, and flush; return 1, or 0 with `session["error"]`. No partial-write success. |
| `stream_read(session, part)` | Return 1 with nonempty `part["hex"]`, 0 on EOF, or -1 with `session["error"]`. Clear old part fields. Chunk boundaries have no protocol meaning. |
| `stream_close(session)` | Release adapter resources after every successful open, including I/O failures. Preserve any reported error. |

`hex` is an even-length lowercase ASCII string with digits `0-9a-f`. It can
represent all 256 byte values, including zero. No framing delimiter is part of
the decoded stream. Adapters own OS partial reads/writes, deadlines, and buffering.
The current synchronous interface has no multiplexing or asynchronous progress.
Timeouts must produce errors rather than pretend to be EOF.

`bytes_from_text` and `bytes_to_text` bridge the existing textual HTTP API.
`bytes_to_text` rejects NUL explicitly. A future TLS layer must operate on hex or
numeric octets directly; ciphertext must never pass through these text helpers.
The GNU AWK adapter uses the helpers today and supports only non-NUL text.

The unavailable adapter makes missing environment support an explicit error.
The mock demonstrates the interface in POSIX syntax without a socket API.

## Supplying a stream to POSIX AWK

A future host bridge could connect TCP and exchange ASCII-framed hex messages
with AWK through supplied files, FIFOs, or descriptors. That bridge would provide
connect/read/write/close and bounded I/O; it would not implement HTTP or TLS.
No bridge is implemented here. Do not treat `/dev/tcp`, GNU `|&`, or special
file descriptors as portable POSIX AWK features.

Before choosing a concrete bridge, specify framing, full-duplex progress,
flushing without portable `fflush`, EOF, errors, backpressure, cancellation,
connection ownership, and deadlock-free startup/cleanup. Two redirected AWK
pipes alone are not a portable bidirectional connection. The host remains an
explicit dependency even if all protocol algorithms are written in AWK.

## Future TLS boundary

The proposed secure-channel layer will consume and produce hex stream chunks.
HTTP will write application plaintext to the channel; the channel will own
handshake state and authenticated record processing before returning plaintext.
It must support incremental reads, buffered records, fragmentation, alerts,
clean shutdown, and truncation detection. Redirects require a fresh channel
bound to the new hostname. Never fall back to plaintext after a TLS failure.

`src/tls/policy.awk` currently exposes only `tls_supported() == 0`. The HTTP
transport rejects HTTPS before opening any stream. There are deliberately no
fake handshake, encryption, or certificate-verification implementations.

The environment will also need two capabilities beyond a TCP stream:

- Cryptographically secure random bytes, with explicit failure. AWK `rand()` is
  not an acceptable source. Define a separate entropy-provider interface.
- Trust anchors and trustworthy current time for certificate/path and hostname
  verification. Trust policy and provisioning must be explicit, not guessed.

These dependencies do not disappear through Turing completeness. They supply
external observations and authority, not protocol computation.
