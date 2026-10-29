# Deterministic POSIX adapter: arbitrary fragments, EOF, and injected failures.
function stream_open(host,port,s,    k) {
    for (k in s) delete s[k]
    mock_opens++; s["offset"] = 1
    if (mock_failure == "open") { s["error"] = "mock open failure"; return 0 }
    return 1
}
function stream_write(s,hex) {
    mock_written = hex
    if (mock_failure == "write") { s["error"] = "mock write failure"; return 0 }
    return 1
}
function stream_read(s,part,    k) {
    for (k in part) delete part[k]
    if (mock_failure == "read") { s["error"] = "mock read failure"; return -1 }
    if (mock_failure == "empty") { part["hex"] = ""; return 1 }
    if (s["offset"] > length(mock_wire)) return 0
    part["hex"] = substr(mock_wire,s["offset"],6)
    s["offset"] += 6
    return 1
}
function stream_close(s) { mock_closes++ }
