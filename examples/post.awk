BEGIN {
    headers["Content-Type"] = "application/json"
    if (!http_post(URL, "{\"message\":\"hello\"}", headers, response)) { print response["error"]; exit 1 }
    print response["status"]
    printf "%s", response["body"]
}
