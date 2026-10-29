# POSIX default for environments that have not supplied a stream adapter.
function stream_open(host,port,s,    k) {
    for (k in s) delete s[k]
    s["error"] = "environment byte-stream adapter unavailable"
    return 0
}
function stream_write(s,hex) { s["error"] = "stream is not open"; return 0 }
function stream_read(s,part) { s["error"] = "stream is not open"; return -1 }
function stream_close(s) { }
