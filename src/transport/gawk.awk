# GNU AWK native TCP transport. No subprocesses or external networking tools.
# Contract: raw HTTP/1.1 bytes in result["raw"], or result["error"].
function http_transport(method,url,body,headers,result,    u,k,host,port,p,socket,request,line,wire,rc,oldrs) {
    for (k in result) delete result[k]
    if (!url_parse(url,u)) { result["error"] = "invalid URL"; return 0 }
    if (u["scheme"] != "http") {
        result["error"] = "HTTPS requires TLS, which native GNU AWK sockets do not provide"
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
    socket = (index(host,":") ? "/inet6/tcp/0/" : "/inet/tcp/0/") host "/" port
    PROCINFO[socket, "NONFATAL"] = 1
    PROCINFO[socket, "READ_TIMEOUT"] = 10000
    request = method " " u["target"] " HTTP/1.1\r\nHost: " u["authority"] "\r\nConnection: close\r\nAccept-Encoding: identity\r\n"
    for (k in headers) request = request k ": " headers[k] "\r\n"
    if (method != "GET" || body != "") request = request "Content-Length: " length(body) "\r\n"
    request = request "\r\n" body
    ERRNO = ""
    printf "%s", request |& socket
    if (ERRNO != "" || fflush(socket) != 0) {
        result["error"] = "TCP write failed: " ERRNO
        close(socket)
        delete PROCINFO[socket, "NONFATAL"]; delete PROCINFO[socket, "READ_TIMEOUT"]
        return 0
    }
    oldrs = RS; RS = "\n"; wire = ""
    while ((rc = (socket |& getline line)) > 0) wire = wire line RT
    RS = oldrs
    if (rc < 0) result["error"] = "TCP read failed: " ERRNO
    close(socket)
    delete PROCINFO[socket, "NONFATAL"]; delete PROCINFO[socket, "READ_TIMEOUT"]
    if (rc < 0) return 0
    result["raw"] = wire
    return 1
}
