# URL utilities. Run with LC_ALL=C for byte-oriented percent encoding.
function url_encode(s,    i,c,n,out) {
    out = ""
    for (i = 1; i <= length(s); i++) {
        c = substr(s,i,1)
        if (c ~ /^[A-Za-z0-9_.~-]$/) out = out c
        else {
            for (n = 1; n < 256; n++) if (sprintf("%c",n) == c) break
            out = out sprintf("%%%02X",n)
        }
    }
    return out
}
function url_parse(s, u,    k,p,a) {
    for (k in u) delete u[k]
    sub(/#.*/, "", s)
    if (s !~ /^https?:\/\// || s ~ /[[:space:][:cntrl:]]/) return 0
    p = index(s, "://")
    u["scheme"] = substr(s,1,p-1)
    s = substr(s,p+3)
    p = match(s, /[\/?]/)
    a = p ? substr(s,1,p-1) : s
    s = p ? substr(s,p) : "/"
    if (a == "" || a ~ /@/ || a !~ /^(\[[0-9A-Fa-f:.]+\]|[A-Za-z0-9._-]+)(:[0-9]+)?$/) return 0
    if (s ~ /^\?/) s = "/" s
    u["authority"] = a
    u["origin"] = u["scheme"] "://" a
    u["target"] = s
    u["url"] = u["origin"] s
    return 1
}
function url_resolve(base, ref,    u,p,path,q,n,a,i,out) {
    if (!url_parse(base,u)) return ""
    sub(/#.*/, "", ref)
    if (ref ~ /^[A-Za-z][A-Za-z0-9+.-]*:/) return ref
    if (ref ~ /^\/\//) return u["scheme"] ":" ref
    if (ref == "") return u["url"]
    path = u["target"]
    sub(/\?.*/, "", path)
    if (ref ~ /^\?/) return u["origin"] path ref
    if (ref !~ /^\//) { sub(/[^\/]*$/, "", path); ref = path ref }
    q = ""
    p = index(ref,"?")
    if (p) { q = substr(ref,p); ref = substr(ref,1,p-1) }
    n = split(ref,a,"/"); p = 0
    for (i=1;i<=n;i++) {
        if (a[i] == "..") { if (p) p-- }
        else if (a[i] != "." && a[i] != "") out[++p] = a[i]
    }
    path = ""
    for (i=1;i<=p;i++) path = path "/" out[i]
    if (path == "" || ref ~ /\/$/ || ref ~ /\/(\.|\.\.)$/) path = path "/"
    return u["origin"] path q
}
