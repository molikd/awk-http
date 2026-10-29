"""Offline integration tests against a loopback HTTP server."""
import os
import shutil
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

class Handler(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.path in ('/redirect', '/loop'):
            self.send_response(302)
            self.send_header('Location', '/body' if self.path == '/redirect' else '/loop')
            self.send_header('Content-Length', '0')
            self.end_headers()
        elif self.path == '/chunked':
            self.send_response(200)
            self.send_header('Transfer-Encoding', 'chunked')
            self.end_headers()
            self.wfile.write(b'3\r\na\nb\r\n0\r\n\r\n')
        else:
            self.reply(200 if self.path == '/body' else 404, b'hello\n')

    def do_POST(self):
        self.reply(201, self.rfile.read(int(self.headers.get('Content-Length', 0))))

    def reply(self, status, body):
        self.send_response(status)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

os.chdir(Path(__file__).resolve().parent.parent)
server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
try:
    for awk in ('awk', 'gawk', 'mawk'):
        if not shutil.which(awk):
            continue
        print(f'Testing {awk}', flush=True)
        command = [awk, '-v', f'BASE=http://127.0.0.1:{server.server_port}']
        for source in ('url', 'headers', 'response', 'http', 'transport/curl'):
            command += ['-f', f'src/{source}.awk']
        subprocess.run(command + ['-f', 'tests/test.awk'], check=True,
                       env={**os.environ, 'LC_ALL': 'C'}, timeout=30)
finally:
    server.shutdown()
    server.server_close()
