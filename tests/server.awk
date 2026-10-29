# GNU AWK only: sequential HTTP fixture, one request per connection.
BEGIN {
    socket = "/inet/tcp/" PORT "/0/0"
    while (1) {
        RS = "\r\n"
        if ((socket |& getline request) <= 0) { close(socket); exit 1 }
        split(request, parts, " ")
        method = parts[1]; path = parts[2]; size = 0
        while ((socket |& getline header) > 0 && header != "") {
            if (tolower(header) ~ /^content-length:/) {
                sub(/^[^:]*:[ \t]*/, "", header)
                size = header + 0
            }
        }
        body = ""
        # A single-character separator exposes every byte through GNU AWK's RT.
        RS = "(.)"
        for (i = 0; i < size; i++) {
            if ((socket |& getline unused) <= 0) exit 1
            body = body RT
        }
        status = "200 OK"; headers = ""; payload = "hello\n"
        if (method == "POST") { status = "201 Created"; payload = body }
        else if (path == "/redirect" || path == "/loop") {
            status = "302 Found"; payload = ""
            headers = "Location: " (path == "/redirect" ? "/body" : "/loop") "\r\n"
        } else if (path == "/chunked") {
            headers = "Transfer-Encoding: chunked\r\n"
            payload = "3\r\na\nb\r\n0\r\n\r\n"
        } else if (path != "/body" && path != "/ready") status = "404 Not Found"
        if (path != "/chunked") headers = headers "Content-Length: " length(payload) "\r\n"
        printf "HTTP/1.1 %s\r\n%sConnection: close\r\n\r\n%s", status, headers, payload |& socket
        close(socket)
    }
}
