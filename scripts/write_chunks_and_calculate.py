#!/usr/bin/env python3
"""
Wrapper script to get chunk data from n8n temp file and calculate similarity.
This reads from /tmp/n8n_chunks.jsonl written by n8n.
"""
import sys
import os

# Read chunks from temp file (written by n8n)
chunks_file = '/tmp/n8n_chunks.jsonl'

if not os.path.exists(chunks_file):
    print(json.dumps({'error': 'No chunks file found at /tmp/n8n_chunks.jsonl'}), file=sys.stderr)
    sys.exit(1)

# Pipe chunks to similarity calculator
import subprocess
result = subprocess.run(
    ['python3', '/Users/eerogetlost/book-processor-local/scripts/calculate_similarity_sqlite.py'],
    stdin=open(chunks_file, 'r'),
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

# Output results
print(result.stdout, end='')
if result.stderr:
    print(result.stderr, file=sys.stderr)

sys.exit(result.returncode)

