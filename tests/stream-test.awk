function check(ok,label) { if (!ok) { print "FAIL: " label; failures++ } }
BEGIN {
    check(bytes_valid("00017fff") && !bytes_valid("0") && !bytes_valid("zz"), "byte representation")
    check(bytes_from_text("a\r\nb") == "610d0a62", "text to bytes")
    check(bytes_to_text("610d0a62",v) && v["text"] == "a\r\nb", "bytes to text")
    check(!bytes_to_text("00",v), "NUL rejected at text boundary")
    check(!bytes_to_text("zz",v), "malformed bytes rejected")
    mock_wire = bytes_from_text("HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\na\nb")
    check(http_get("http://example.test/a?q=1",r) && r["body"] == "a\nb", "fragmented stream response")
    bytes_to_text(mock_written,v)
    check(index(v["text"],"GET /a?q=1 HTTP/1.1\r\nHost: example.test\r\n") == 1, "request framing")
    check(mock_opens == 1 && mock_closes == 1, "successful stream cleanup")
    mock_failure = "write"
    check(!http_get("http://example.test/",r) && r["error"] == "mock write failure" && mock_closes == 2, "write error cleanup")
    mock_failure = "read"
    check(!http_get("http://example.test/",r) && r["error"] == "mock read failure" && mock_closes == 3, "read error cleanup")
    mock_failure = "empty"
    check(!http_get("http://example.test/",r) && r["error"] == "empty stream read" && mock_closes == 4, "empty read rejected")
    mock_failure = "open"
    check(!http_get("http://example.test/",r) && r["error"] == "mock open failure" && mock_closes == 4, "open failure needs no close")
    opens = mock_opens
    check(!http_get("https://example.test/",r) && r["error"] ~ /TLS/ && mock_opens == opens && !tls_supported(), "HTTPS fails before stream I/O")
    if (!failures) print "Stream contract checks passed"
    exit (failures != 0)
}
