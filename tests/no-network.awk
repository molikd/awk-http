# Satisfies the core's transport reference during portable utility tests.
function http_transport(method,url,body,headers,result) {
    result["error"] = "network transport unavailable in utility tests"
    return 0
}
