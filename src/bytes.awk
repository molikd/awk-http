# Byte interchange is lowercase hexadecimal, never raw binary in POSIX strings.
function bytes_valid(hex) { return length(hex) % 2 == 0 && hex !~ /[^0-9a-f]/ }
function bytes_from_text(text,    i,n,c,hex) {
    hex = ""
    for (i=1;i<=length(text);i++) {
        c = substr(text,i,1)
        for (n=1;n<256;n++) if (sprintf("%c",n) == c) break
        hex = hex sprintf("%02x",n)
    }
    return hex
}
# Text-only boundary: refuse NUL rather than silently corrupting it.
function bytes_to_text(hex,result,    k,i,n,a,b,text) {
    for (k in result) delete result[k]
    if (!bytes_valid(hex)) { result["error"] = "invalid hexadecimal bytes"; return 0 }
    text = ""
    for (i=1;i<=length(hex);i+=2) {
        a = index("0123456789abcdef",substr(hex,i,1))-1
        b = index("0123456789abcdef",substr(hex,i+1,1))-1
        n = a*16+b
        if (!n) { result["error"] = "NUL is unsupported by the HTTP text API"; return 0 }
        text = text sprintf("%c",n)
    }
    result["text"] = text
    return 1
}
