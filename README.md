# awk-http

An AWK HTTP library moving toward POSIX AWK protocol implementations over an
environment-provided bidirectional byte stream. HTTP works today through a GNU
AWK socket adapter. A future TLS layer could sit above that same stream; **TLS
and HTTPS are not implemented**.

All library code except `src/stream/gawk.awk` uses POSIX AWK syntax. POSIX AWK
cannot open sockets itself: an environment must supply networking. The current
GNU adapter is one such environment; a portable host bridge is planned. The
library invokes no external networking programs or shell commands.

## Usage today

Use a current, network-enabled GNU AWK build. Run in the C locale:

```sh
LC_ALL=C gawk -v URL=http://example.com/ \
  -f src/url.awk -f src/headers.awk -f src/response.awk \
  -f src/http.awk -f src/bytes.awk -f src/tls/policy.awk \
  -f src/transport/stream.awk -f src/stream/gawk.awk -f examples/get.awk
```

Load those same files before your own program:

```awk
BEGIN {
    if (!http_get("http://example.com/", response)) {
        print response["error"]
        exit 1
    }
    print response["status"]
    print response["header:content-type"]
    printf "%s", response["body"]
}
```

The public functions are:

- `http_get(url, response)`
- `http_post(url, body, headers, response)`
- `http_request(method, url, body, headers, response)`
- `url_encode(text)` encodes a URL component, including spaces as `%20`.

Requests return **1 for a complete response**, including HTTP 4xx and 5xx, or
**0 on an error**. Response arrays are cleared on every request and use flat keys:
`status`, `reason`, `body`, `url`, `redirects`, `header:<lowercase-name>`, and
`error` when unsuccessful. Partial fields may remain on failure; check the return
value before using them. Repeated headers are comma-joined, which does not
preserve independent Set-Cookie values.

`headers` maps names to values. Host, Content-Length, Transfer-Encoding,
Connection, and Accept-Encoding are reserved. Values are sent without shell
evaluation. See `examples/post.awk` for a JSON POST.

## Layout and direction

```text
src/
  http.awk                public API and redirects
  url.awk                 URL parsing, resolution, and encoding
  headers.awk             header validation
  response.awk            HTTP status, headers, chunks, and textual body
  bytes.awk               hex interchange and text conversion
  transport/stream.awk    portable HTTP construction and stream orchestration
  stream/gawk.awk         GNU-only TCP adapter, text support today
  stream/unavailable.awk  portable explicit error when no adapter is supplied
  tls/policy.awk          capability gate: TLS unavailable
  tls/README.md           planned TLS responsibilities
examples/                 reusable library examples
tests/                    portable mock and native HTTP integration tests
docs/architecture.md      byte-stream contract and environment responsibilities
docs/roadmap.md           staged research plan, no crypto implementation
```

Load exactly one stream adapter. Replace `src/stream/gawk.awk` with
`src/stream/unavailable.awk` to load the complete portable framework under a
POSIX AWK interpreter; requests then report the missing environment adapter.

The stream interface exchanges lowercase hexadecimal chunks so every byte value
can be represented portably, including NUL. The current GNU adapter and HTTP API
remain **text-only**; they reject NUL. A binary-capable host adapter and future
TLS algorithms will need to operate on hex or numeric octets directly.

The [architecture](docs/architecture.md) defines open/write/read/close behavior,
error handling, and the proposed TLS boundary. The [roadmap](docs/roadmap.md)
covers binary I/O, arithmetic, entropy, trust, and a future TLS profile. No
cryptographic algorithms, TLS handshake, certificate verifier, or POSIX host
bridge are supplied. HTTPS fails before any stream is opened.

## Current behavior and limits

Requests use HTTP/1.1, `Connection: close`, and `Accept-Encoding: identity`.
Responses are buffered until EOF. The GNU adapter has a 10-second read inactivity
timeout; connection establishment uses GNU AWK and OS behavior. There is no
overall request deadline or response-size limit.

Redirects stop after five hops. POST becomes GET on 301/302, and non-GET becomes
GET on 303; 307/308 preserve method and body. Authorization, Cookie, and
Proxy-Authorization are removed on origin changes; other custom headers persist.
Redirects to HTTPS fail explicitly.

Use `LC_ALL=C`. Userinfo is rejected; percent-encode non-ASCII URL components.
HTTPS, HEAD, CONNECT, upgrades, compressed content, cookie management, proxies,
and persistent connections are unsupported. Chunk trailers are consumed but not
exposed. The parser is an initial implementation without hostile-server hardening.

## Tests

```sh
awk -f tests/run.awk
```

Run from the repository root. GNU AWK is required for the local HTTP fixture.
The runner uses the shell only for process orchestration; networking and fixture
responses run in AWK. Override the random high port with `-v PORT=18080` if
needed. The fixture listens on that port while tests run; use a trusted local
environment.

Portable utilities and mock stream tests run under each installed `awk`, `gawk`,
and `mawk`. They exercise fragmented reads, request framing, byte conversion,
cleanup after I/O failures, and HTTPS rejection before opening a stream. Native
HTTP tests run under GNU AWK and cover redirects, chunk decoding, textual byte
preservation, HTTP errors, and input validation. System AWK and GNU AWK have
been verified locally.
