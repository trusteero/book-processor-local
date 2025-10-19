#!/usr/bin/env python3
"""
Save chunks from stdin to a temp file.
Usage: echo 'JSON' | python3 save_chunks.py
"""
import sys
import json

try:
    # Read from stdin
    data = sys.stdin.read()
    
    # Write to temp file
    with open('/tmp/n8n_chunks.json', 'w') as f:
        f.write(data)
    
    print(f"Saved {len(data)} bytes to /tmp/n8n_chunks.json")
    sys.exit(0)
except Exception as e:
    print(json.dumps({'error': str(e)}), file=sys.stderr)
    sys.exit(1)

