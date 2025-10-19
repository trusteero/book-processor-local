#!/usr/bin/env python3
"""
Read chunks from n8n (via a JSON file path) and write to JSONL.
"""
import sys
import json

# n8n will pass the previous node's output
# We expect a file path or JSON data
try:
    # Write empty file first
    with open('/tmp/n8n_chunks.jsonl', 'w') as f:
        f.write('')
    
    print('Chunks file prepared at /tmp/n8n_chunks.jsonl')
    sys.exit(0)
except Exception as e:
    print(json.dumps({'error': str(e)}), file=sys.stderr)
    sys.exit(1)

