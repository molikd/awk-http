# awk-http

A small HTTP client library with a POSIX AWK core and a replaceable networking
transport. This is an initial implementation for textual HTTP/1.1 responses.
POSIX AWK provides no sockets or TLS; the included transport requires `curl`.

## Usage

Run in the C locale so string lengths and percent encoding operate on bytes:

```sh
LC_ALL=C awk -v URL=https://example.com/ \
  -f src/url.awk -f src/headers.awk -f src/response.awk \
  -f src/http.awk -f src/transport/curl.awk -f examples/get.awk
```

Load the same library files before your own program:

```awk
BEGIN {
    if (!http_get("https://example.com/", response)) {
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
- `url_encode(text)` encodes a single URL component, including spaces as `%20`.

Requests return **1 for a complete response**, including HTTP 4xx and 5xx, or
**0 on an error**. Response arrays are cleared on every request and use flat keys:
`status`, `reason`, `body`, `url`, `redirects`, `header:<lowercase-name>`, and
`error` when unsuccessful. On failure, partial response fields may remain; check
the return value before using them. Repeated response headers are comma-joined;
this representation does not preserve independent Set-Cookie values.

`headers` maps header names to values. Host, Content-Length, Transfer-Encoding,
Connection, and Accept-Encoding are reserved. URLs and headers are validated,
and all values passed through the shell are single-quoted. The examples include
a JSON POST. HTTP statuses are numeric, while bodies are strings.

## Architecture

- `src/url.awk`: URL parsing, relative redirect resolution, component encoding.
- `src/headers.awk`: header validation and shell quoting.
- `src/response.awk`: status/header parsing, interim responses, chunk decoding,
  and Content-Length validation.
- `src/http.awk`: public API, redirects, and error handling.
- `src/transport/curl.awk`: TLS/networking through curl.

The transport implements
`http_transport(method, url, body, headers, result)`, returning 1 and placing a
raw HTTP/1.1 response in `result["raw"]`, or returning 0 with `result["error"]`.
Load exactly one transport. The core uses POSIX syntax, with no nested arrays,
whole-array deletion, or GNU-specific operators.

Curl constructs the outgoing wire request, handles TCP/TLS, and verifies server
certificates. AWK validates request inputs and implements response parsing and
redirect policy. Curl is invoked with raw transfer output and without automatic
redirects or decompression. User curl configuration and proxies are disabled so
the transport has predictable framing and routing. Shell and curl diagnostics go
to stderr. No temporary files are used. Connect and total timeouts are currently
fixed at 10 and 30 seconds per request.

Redirects are limited to five hops. POST becomes GET on 301/302, and non-GET
becomes GET on 303; 307/308 preserve the method and body. Authorization, Cookie,
and Proxy-Authorization are removed when the origin changes; other custom
headers persist. HTTPS-to-HTTP redirects are refused.

## Limits and next steps

This is a starting library, not a complete replacement for curl. Bodies must be
text without NUL bytes, and the entire response is buffered in memory. Use
`LC_ALL=C`; arbitrary binary data is not portable across AWK implementations.
Only HTTP/HTTPS URLs are accepted, userinfo is rejected, and callers should
percent-encode non-ASCII URL components. This is not a hardened parser for
hostile servers and does not impose response-size limits.

HEAD, CONNECT, protocol upgrades, compressed content, proxy configuration,
cookie management, and persistent connections are unsupported. Chunk trailers
are consumed but not exposed. A separately loaded GNU AWK socket transport for
plain HTTP and a thin CLI are planned; neither is implemented yet.

## Tests

```sh
python3 tests/run.py
```

Requires Python 3 and curl. Tests use only an ephemeral loopback server and run
against each installed `awk`, `gawk`, and `mawk`. They exercise response parsing,
redirects, chunked bodies, byte preservation for text, HTTP errors, and shell and
header injection inputs. System AWK and GNU AWK have been verified locally.
