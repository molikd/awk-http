# Contract: return raw HTTP/1.1 bytes in result["raw"] or an error.
function http_transport(method,url,body,headers,result,    cmd,k,line,wire,rc,p,oldrs) {
    for (k in result) delete result[k]
    cmd = "printf '%s' " http_shell_quote(body) " | curl --disable --silent --show-error --http1.1 --include --raw --globoff --path-as-is --noproxy '*' --proto '=http,https' --connect-timeout 10 --max-time 30 --request " http_shell_quote(method)
    cmd = cmd " --header 'Connection: close' --header 'Accept-Encoding: identity'"
    for (k in headers) cmd = cmd " --header " http_shell_quote(k ": " headers[k])
    if (method != "GET" || body != "") cmd = cmd " --data-binary @-"
    cmd = cmd " --url " http_shell_quote(url) "; rc=$?; printf '\\nAWK_HTTP_EXIT:%s\\n' \"$rc\""
    oldrs = RS; RS = "\n"; wire = ""
    while ((cmd | getline line)>0) wire = wire line "\n"
    close(cmd); RS = oldrs
    p = match(wire,/\nAWK_HTTP_EXIT:[0-9]+\n$/)
    if (!p) { result["error"] = "transport did not return an exit status"; return 0 }
    rc = substr(wire,p+15)+0
    if (rc) { result["error"] = "curl exited with status " rc; return 0 }
    result["raw"] = substr(wire,1,p-1)
    return 1
}
