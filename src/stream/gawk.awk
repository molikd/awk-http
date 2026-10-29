# GNU-specific environment adapter. All protocol logic lives outside this file.
function stream_open(host,port,s,    k,socket) {
    for (k in s) delete s[k]
    socket = (index(host,":") ? "/inet6/tcp/0/" : "/inet/tcp/0/") host "/" port
    s["socket"] = socket
    PROCINFO[socket,"NONFATAL"] = 1
    PROCINFO[socket,"READ_TIMEOUT"] = 10000
    # GNU AWK connects lazily on first I/O.
    return 1
}
function stream_write(s,hex,    decoded,socket) {
    if (!bytes_to_text(hex,decoded)) { s["error"] = decoded["error"]; return 0 }
    socket = s["socket"]; ERRNO = ""
    printf "%s", decoded["text"] |& socket
    if (ERRNO != "" || fflush(socket) != 0) { s["error"] = "TCP write failed: " ERRNO; return 0 }
    return 1
}
function stream_read(s,part,    k,oldrs,line,rc,socket) {
    for (k in part) delete part[k]
    socket = s["socket"]; oldrs = RS; RS = "\n"
    rc = (socket |& getline line)
    RS = oldrs
    if (rc < 0) { s["error"] = "TCP read failed: " ERRNO; return -1 }
    if (rc == 0) return 0
    part["hex"] = bytes_from_text(line RT)
    return 1
}
function stream_close(s,    socket) {
    socket = s["socket"]
    close(socket)
    delete PROCINFO[socket,"NONFATAL"]; delete PROCINFO[socket,"READ_TIMEOUT"]
    delete s["socket"]
}
