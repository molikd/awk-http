# Flat response keys: status, reason, body, header:<lowercase name>, error.
function http_response_parse(raw,r,    k,p,head,line,n,a,i,v,key,body,size,hex,j,c,total) {
    for (k in r) delete r[k]
    while (1) {
        p = index(raw,"\r\n\r\n")
        if (!p) { r["error"] = "missing HTTP header terminator"; return 0 }
        head = substr(raw,1,p-1); body = substr(raw,p+4)
        n = split(head,a,"\r\n")
        if (a[1] !~ /^HTTP\/1\.[01] [0-9][0-9][0-9]( |$)/) { r["error"] = "invalid HTTP status line"; return 0 }
        r["status"] = substr(a[1],10,3)+0
        r["reason"] = substr(a[1],14)
        if (r["status"] >= 100 && r["status"] < 200 && r["status"] != 101) { raw = body; continue }
        break
    }
    for (i=2;i<=n;i++) {
        p = index(a[i],":")
        key = substr(a[i],1,p-1); v = http_trim(substr(a[i],p+1))
        if (!p || !http_header_valid(key,v)) { r["error"] = "invalid response header"; return 0 }
        key = "header:" tolower(key)
        if (key in r) r[key] = r[key] ", " v
        else r[key] = v
    }
    if (r["status"] == 101) { r["error"] = "protocol upgrades are unsupported"; return 0 }
    if (tolower(r["header:transfer-encoding"]) == "chunked") {
        raw = body; body = ""
        while (1) {
            p = index(raw,"\r\n")
            if (!p) { r["error"] = "truncated chunk size"; return 0 }
            hex = substr(raw,1,p-1); sub(/;.*/, "", hex)
            if (hex !~ /^[0-9a-fA-F]+$/ || length(hex)>8) { r["error"] = "invalid chunk size"; return 0 }
            size = 0
            for (j=1;j<=length(hex);j++) size = size*16 + index("0123456789abcdef",tolower(substr(hex,j,1)))-1
            raw = substr(raw,p+2)
            if (!size) {
                if (raw !~ /^\r\n/ && !index(raw,"\r\n\r\n")) { r["error"] = "truncated chunk trailers"; return 0 }
                break
            }
            if (length(raw)<size+2 || substr(raw,size+1,2)!="\r\n") { r["error"] = "truncated chunk"; return 0 }
            body = body substr(raw,1,size); raw = substr(raw,size+3)
        }
    } else if (r["header:transfer-encoding"] != "") { r["error"] = "unsupported transfer encoding"; return 0 }
    else if ("header:content-length" in r && r["status"] != 204 && r["status"] != 304) {
        v = r["header:content-length"]
        if (v !~ /^[0-9]+$/ || length(body) != v+0) { r["error"] = "content length mismatch"; return 0 }
    }
    r["body"] = body
    return 1
}
