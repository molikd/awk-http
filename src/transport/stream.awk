# POSIX HTTP orchestration over a separately loaded environment stream adapter.
function http_transport(method,url,body,headers,result,    u,k,host,port,p,session,request,part,decoded,wire,rc) {
    for (k in result) delete result[k]
    if (!url_parse(url,u)) { result["error"] = "invalid URL"; return 0 }
    if (u["scheme"] == "https") {
        result["error"] = "TLS is not implemented; HTTPS is unavailable"
        return 0
    }
    host = u["authority"]; port = 80
    if (host ~ /^\[/) {
        p = index(host,"]")
        if (substr(host,p+1,1) == ":") port = substr(host,p+2)
        host = substr(host,2,p-2)
    } else if (index(host,":")) {
        p = index(host,":"); port = substr(host,p+1); host = substr(host,1,p-1)
    }
    if (port !~ /^[0-9]+$/ || port < 1 || port > 65535) {
        result["error"] = "invalid TCP port"; return 0
    }
    if (!stream_open(host,port,session)) { result["error"] = session["error"]; return 0 }
    request = method " " u["target"] " HTTP/1.1\r\nHost: " u["authority"] "\r\nConnection: close\r\nAccept-Encoding: identity\r\n"
    for (k in headers) request = request k ": " headers[k] "\r\n"
    if (method != "GET" || body != "") request = request "Content-Length: " length(body) "\r\n"
    request = request "\r\n" body
    if (!stream_write(session,bytes_from_text(request))) {
        result["error"] = session["error"]; stream_close(session); return 0
    }
    wire = ""
    while ((rc = stream_read(session,part)) > 0) {
        if (part["hex"] == "" || !bytes_to_text(part["hex"],decoded)) {
            result["error"] = (part["hex"] == "" ? "empty stream read" : decoded["error"])
            stream_close(session); return 0
        }
        wire = wire decoded["text"]
    }
    if (rc < 0) result["error"] = session["error"]
    stream_close(session)
    if (rc < 0) return 0
    result["raw"] = wire
    return 1
}
