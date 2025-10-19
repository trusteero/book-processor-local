#!/usr/bin/env python3
"""
Simple script to load subgenres from SQLite and output as JSON.
Outputs to stdout in a format n8n can handle.
"""
import sqlite3
import json
import sys

def main():
    try:
        # Connect to database
        conn = sqlite3.connect('/Users/eerogetlost/book-processor-local/data/subgenres.db')
        cursor = conn.cursor()
        
        # Query all subgenres
        cursor.execute('SELECT id, parent_genre, sub_genre, prototype_text, embedding FROM subgenres')
        rows = cursor.fetchall()
        
        # Output each subgenre as a separate line (JSONL format)
        # This way n8n gets 485 separate items instead of one giant JSON
        for r in rows:
            genre = {
                'id': r[0],
                'parent_genre': r[1],
                'sub_genre': r[2],
                'prototype_text': r[3],
                'embedding': json.loads(r[4])
            }
            # Print one line per subgenre
            print(json.dumps(genre, separators=(',', ':')))
        
        conn.close()
        sys.exit(0)
        
    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

