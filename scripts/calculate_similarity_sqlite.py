#!/usr/bin/env python3
"""
Calculate genre similarity directly in SQLite.
Takes book chunk embeddings via stdin (JSONL format).
Outputs similarity results via stdout (JSONL format).
"""
import sqlite3
import json
import sys
import math

def cosine_similarity(vec1, vec2):
    """Calculate cosine similarity between two vectors (pure Python)."""
    if len(vec1) != len(vec2):
        raise ValueError(f"Vector length mismatch: {len(vec1)} vs {len(vec2)}")
    
    dot_product = sum(a * b for a, b in zip(vec1, vec2))
    norm1 = math.sqrt(sum(a * a for a in vec1))
    norm2 = math.sqrt(sum(b * b for b in vec2))
    
    if norm1 == 0 or norm2 == 0:
        return 0.0
    
    return dot_product / (norm1 * norm2)

def calculate_similarity_for_chunk(conn, chunk_data):
    """Calculate similarity for one book chunk against all genres."""
    cursor = conn.cursor()
    
    # Get all genres
    cursor.execute('SELECT id, parent_genre, sub_genre, prototype_text, embedding FROM subgenres')
    genres = cursor.fetchall()
    
    # Calculate similarities
    book_embedding = chunk_data['embedding']
    similarities = []
    
    for genre_row in genres:
        genre_id, parent, subgenre, prototype, genre_embedding_json = genre_row
        genre_embedding = json.loads(genre_embedding_json)
        
        similarity = cosine_similarity(book_embedding, genre_embedding)
        
        similarities.append({
            'subgenre': subgenre,
            'parent_genre': parent,
            'prototype_text': prototype,
            'similarity': similarity
        })
    
    # Sort and get top 20
    similarities.sort(key=lambda x: x['similarity'], reverse=True)
    top_20 = similarities[:20]
    
    # Return result
    return {
        'book_title': chunk_data.get('book_title', 'Unknown'),
        'chunk_number': chunk_data.get('chunk_number', 0),
        'chunk_text': chunk_data.get('chunk_text', '')[:500],
        'top_genres': top_20
    }

def main():
    try:
        # Connect to database
        conn = sqlite3.connect('/Users/eerogetlost/book-processor-local/data/subgenres.db')
        
        # Read chunks from stdin (JSONL format)
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
                
            chunk_data = json.loads(line)
            
            # Calculate similarity
            result = calculate_similarity_for_chunk(conn, chunk_data)
            
            # Output as JSONL
            print(json.dumps(result, separators=(',', ':')))
            sys.stdout.flush()
        
        conn.close()
        sys.exit(0)
        
    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

