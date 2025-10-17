#!/usr/bin/env python3
"""
Simple HTTP server to serve subgenres.json file.
Run this in the background, then use HTTP Request node in n8n.
"""
from http.server import HTTPServer, SimpleHTTPRequestHandler
import json
import os

PORT = 8765

class SubgenresHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/subgenres.json' or self.path == '/':
            filepath = '/Users/eerogetlost/book-processor-local/data/subgenres.json'
            
            try:
                with open(filepath, 'r') as f:
                    data = json.load(f)
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                
                # Send compact JSON
                self.wfile.write(json.dumps(data, separators=(',', ':')).encode('utf-8'))
                
            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': str(e)}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    os.chdir('/Users/eerogetlost/book-processor-local/data')
    server = HTTPServer(('localhost', PORT), SubgenresHandler)
    print(f'🌐 Serving subgenres.json at http://localhost:{PORT}/subgenres.json')
    print('Press Ctrl+C to stop')
    server.serve_forever()

