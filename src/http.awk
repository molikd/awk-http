# Returns 1 for a complete HTTP response (including 4xx/5xx), 0 on error.
function http_request(method,url,body,headers,response,    u,v,h,t,k,i,location,nexturl,limit) {
    for (k in response) delete response[k]
    if (method !~ /^[A-Z]+$/ || method == "HEAD" || method == "CONNECT") { response["error"] = "unsupported request method"; return 0 }
    for (k in headers) {
        if (!http_header_valid(k,headers[k]) || tolower(k) ~ /^(host|content-length|transfer-encoding|connection|accept-encoding)$/) {
            response["error"] = "invalid or reserved request header: " k; return 0
        }
        h[k] = headers[k]
    }
    limit = 5
    for (i=0;i<=limit;i++) {
        if (!url_parse(url,u)) { response["error"] = "invalid or unsupported URL"; return 0 }
        if (!http_transport(method,u["url"],body,h,t)) { response["error"] = t["error"]; return 0 }
        if (!http_response_parse(t["raw"],response)) return 0
        response["url"] = u["url"]; response["redirects"] = i
        if (response["status"] !~ /^(301|302|303|307|308)$/ || !("header:location" in response)) return 1
        if (i == limit) { response["error"] = "redirect limit exceeded"; return 0 }
        nexturl = url_resolve(url,response["header:location"])
        if (!url_parse(nexturl,v)) { response["error"] = "invalid redirect URL"; return 0 }
        if (u["scheme"] == "https" && v["scheme"] == "http") { response["error"] = "HTTPS downgrade redirect refused"; return 0 }
        if (u["origin"] != v["origin"]) for (k in h) if (tolower(k) ~ /^(authorization|cookie|proxy-authorization)$/) delete h[k]
        if ((response["status"] == 303 && method != "GET") || ((response["status"] == 301 || response["status"] == 302) && method == "POST")) {
            method = "GET"; body = ""
            for (k in h) if (tolower(k) ~ /^content-/) delete h[k]
        }
        url = nexturl
    }
    return 0
}
function http_get(url,response,    headers) { return http_request("GET",url,"",headers,response) }
function http_post(url,body,headers,response) { return http_request("POST",url,body,headers,response) }
