function http_header_valid(name, value) {
    return name ~ /^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/ && value !~ /[\r\n]/
}
function http_trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function http_shell_quote(s) { gsub(/'/, "'\\''", s); return "'" s "'" }
