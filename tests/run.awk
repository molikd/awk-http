# Run from the repository root: awk -f tests/run.awk
BEGIN {
    if (system("command -v gawk >/dev/null 2>&1") != 0) {
        print "Tests require GNU AWK for native TCP networking" > "/dev/stderr"
        exit 1
    }
    if (PORT == "") { srand(); PORT = 20000 + int(rand() * 40000) }
    if (PORT !~ /^[0-9]+$/ || PORT < 1024 || PORT > 65535) {
        print "PORT must be an integer between 1024 and 65535" > "/dev/stderr"
        exit 1
    }
    sources = " -f src/url.awk -f src/headers.awk -f src/response.awk -f src/http.awk -f src/bytes.awk -f src/tls/policy.awk -f src/transport/stream.awk"
    script = "export LC_ALL=C\n"
    split("awk gawk mawk", interpreters, " ")
    for (i = 1; i <= 3; i++) {
        interpreter = interpreters[i]
        script = script "if command -v " interpreter " >/dev/null 2>&1; then\n"
        script = script "  echo 'Testing " interpreter " portable core'\n  " interpreter sources " -f src/stream/unavailable.awk -f tests/test.awk || exit 1\n"
        script = script "  " interpreter sources " -f tests/stream-mock.awk -f tests/stream-test.awk || exit 1\nfi\n"
    }
    # The shell only manages process lifetime; HTTP runs entirely in GNU AWK.
    script = script "export GAWK_SOCK_RETRIES=100 GAWK_MSEC_SLEEP=20\n"
    script = script "gawk -v PORT=" PORT " -f tests/server.awk &\nserver=$!\n"
    script = script "trap 'kill \"$server\" 2>/dev/null; wait \"$server\" 2>/dev/null' 0\ntrap 'exit 1' 1 2 3 15\n"
    script = script "echo 'Testing GNU AWK native HTTP'\n"
    script = script "gawk -v BASE=http://127.0.0.1:" PORT sources " -f src/stream/gawk.awk -f tests/test.awk || exit 1\n"
    exit (system(script) != 0)
}
