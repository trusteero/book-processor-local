#!/usr/bin/env python3
"""
Output subgenres JSON in compact form (no whitespace) to reduce size.
This helps avoid stdout maxBuffer issues in n8n.
"""
import json
import sys

filepath = '/Users/eerogetlost/book-processor-local/data/subgenres.json'

try:
    with open(filepath, 'r') as f:
        data = json.load(f)
    
    # Output compact JSON (no whitespace)
    print(json.dumps(data, separators=(',', ':')))
    
except Exception as e:
    print(f'{{"error": "{str(e)}"}}', file=sys.stderr)
    sys.exit(1)

