BEGIN {
    if (!http_get(URL, response)) { print response["error"]; exit 1 }
    print response["status"]
    printf "%s", response["body"]
}
