#!/usr/bin/env python3
"""
All-in-one similarity calculator for n8n.
Reads chunks from environment variable N8N_CHUNKS (base64 encoded JSON).
"""
import sqlite3
import json
import sys
import os
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
        # Read chunks from temp file
        chunks_file = '/tmp/n8n_chunks.json'
        
        if not os.path.exists(chunks_file):
            raise ValueError(f"Chunks file not found at {chunks_file}")
        
        with open(chunks_file, 'r') as f:
            chunks_json = f.read()
        
        # Parse chunks
        chunks = json.loads(chunks_json)
        if not isinstance(chunks, list):
            chunks = [chunks]  # Wrap single item
        
        # Connect to database
        conn = sqlite3.connect('/Users/eerogetlost/book-processor-local/data/subgenres.db')
        
        # Process each chunk and write to output file
        output_file = '/tmp/n8n_similarity_results.jsonl'
        with open(output_file, 'w') as out:
            for i, chunk_data in enumerate(chunks):
                result = calculate_similarity_for_chunk(conn, chunk_data)
                out.write(json.dumps(result, separators=(',', ':')) + '\n')
                if (i + 1) % 10 == 0:
                    print(f"Processed {i + 1}/{len(chunks)} chunks", file=sys.stderr)
        
        conn.close()
        
        # Output just the file path
        print(output_file)
        sys.exit(0)
        
    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

