# awk-http

An HTTP client library written entirely in AWK. GNU AWK's built-in TCP sockets
provide networking; the library never starts a subprocess or invokes an external
networking program. Request construction, response parsing, chunk decoding, and
redirects all run in AWK.

The utility and public API layers use POSIX AWK syntax. Networking requires
GNU AWK, because POSIX AWK has no socket primitives. **Only plain HTTP is
supported.** HTTPS returns an explicit error: GNU AWK sockets do not implement
TLS. There is no external transport fallback.

## Usage

Use a current, network-enabled GNU AWK build. Run in the C locale
so string lengths and percent encoding operate on bytes:

```sh
LC_ALL=C gawk -v URL=http://example.com/ \
  -f src/url.awk -f src/headers.awk -f src/response.awk \
  -f src/http.awk -f src/transport/gawk.awk -f examples/get.awk
```

Load the same files before your own program:

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
value before using them. Repeated response headers are comma-joined, which does
not preserve independent Set-Cookie values.

`headers` maps header names to values. Host, Content-Length, Transfer-Encoding,
Connection, and Accept-Encoding are reserved. URLs and header names/values are
validated. Values are written directly to the socket without shell evaluation.
The examples include a JSON POST.

## Architecture

- `src/url.awk`: URL parsing, relative redirects, and component encoding.
- `src/headers.awk`: header validation.
- `src/response.awk`: status/header parsing, interim responses, chunk decoding,
  and Content-Length validation.
- `src/http.awk`: public API, redirects, and errors.
- `src/transport/gawk.awk`: HTTP/1.1 request construction and native TCP I/O.

The transport implements
`http_transport(method, url, body, headers, result)`, returning 1 with raw
HTTP/1.1 bytes in `result["raw"]`, or 0 with `result["error"]`. GNU-specific
syntax is isolated in this file. Load it with GNU AWK; other AWK implementations
can use the portable utilities independently.

The transport sends `Connection: close` and `Accept-Encoding: identity`, buffers
the response until EOF, and preserves text line endings, including a missing
final newline. Reads have a 10-second inactivity timeout; connection establishment
uses GNU AWK and OS behavior, with no overall request deadline. No temporary
files, shell commands, proxy handling, or TLS helpers are used by the library.

Redirects are limited to five hops. POST becomes GET on 301/302, and non-GET
becomes GET on 303; 307/308 preserve the method and body. Authorization, Cookie,
and Proxy-Authorization are removed when the origin changes; other custom
headers persist. A redirect to HTTPS fails explicitly.

## Limits

Bodies must be text without NUL bytes, and entire responses are buffered in
memory. Use `LC_ALL=C`. Userinfo in URLs is rejected; percent-encode non-ASCII
URL components. This is an initial implementation, without response-size limits
or hardening for hostile servers.

HTTPS, HEAD, CONNECT, protocol upgrades, compressed content, cookies, proxies,
and persistent connections are unsupported. Chunk trailers are consumed but
not exposed. A thin CLI remains future work.

## Tests

```sh
awk -f tests/run.awk
```

Requires GNU AWK. The runner uses the shell solely to launch interpreters and
clean up the fixture process; all test HTTP traffic runs in AWK, without Python
or external networking tools. Run from the repository root. The runner selects
a random high port; override with `awk -v PORT=18080 -f tests/run.awk` if needed.
The fixture listens on that port while tests run, so run it in a trusted local
environment.

Portable utility tests run under each installed `awk`, `gawk`, and `mawk`.
Native HTTP integration tests run under GNU AWK against the local AWK fixture.
They cover redirects, chunk decoding, exact textual body preservation, HTTP
errors, literal shell metacharacters, header injection rejection, invalid ports,
and explicit HTTPS rejection. System AWK and GNU AWK have been verified locally.
