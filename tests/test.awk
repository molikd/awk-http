function check(ok,label) { if (!ok) { print "FAIL: " label; failures++ } }
BEGIN {
    check(url_encode("a b/'") == "a%20b%2F%27", "encoding")
    check(url_resolve("http://example.com/a/b", "../c?q=1") == "http://example.com/c?q=1", "relative URL")
    check(!url_parse("http://example.com\nInjected",u), "URL injection")
    check(http_response_parse("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\na\nb\r\n0\r\n\r\n",r) && r["body"] == "a\nb", "chunked body")
    check(!http_response_parse("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nx",r), "truncation")
    if (BASE != "") {
        check(http_get(BASE "/redirect",r) && r["body"] == "hello\n" && r["redirects"] == 1, "GET redirect and trailing newline")
        check(http_get(BASE "/chunked",r) && r["body"] == "a\nb", "wire chunk decoding")
        h["Content-Type"] = "text/plain"
        check(http_post(BASE "/echo", "quote' $HOME `id`\nlast",h,r) && r["body"] == "quote' $HOME `id`\nlast", "POST literal bytes and no final newline")
        check(http_get(BASE "/missing",r) && r["status"] == 404, "HTTP error is response")
        check(!http_get(BASE "/loop",r) && r["error"] == "redirect limit exceeded", "redirect bound")
        check(!http_get("https://127.0.0.1/",r) && r["error"] ~ /TLS/, "explicit HTTPS rejection")
        check(!http_get("http://127.0.0.1:99999/",r) && r["error"] == "invalid TCP port", "invalid port")
        h["Bad\nHeader"] = "value"
        check(!http_post(BASE, "", h,r), "header injection")
    }
    if (!failures) print "All checks passed"
    exit (failures != 0)
}
