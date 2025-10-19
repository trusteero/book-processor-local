#!/usr/bin/env python3
"""
Calculate similarity and aggregate results in one step.
Outputs compact aggregated JSON instead of full JSONL.
"""
import sqlite3
import json
import sys
import os
import math
from collections import defaultdict

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

def main():
    try:
        # Read chunks from temp file
        chunks_file = '/tmp/n8n_chunks.json'
        
        if not os.path.exists(chunks_file):
            raise ValueError(f"Chunks file not found at {chunks_file}")
        
        with open(chunks_file, 'r') as f:
            chunks = json.load(f)
        
        if not isinstance(chunks, list):
            chunks = [chunks]
        
        print(f"Processing {len(chunks)} chunks...", file=sys.stderr)
        
        # Connect to database
        conn = sqlite3.connect('/Users/eerogetlost/book-processor-local/data/subgenres.db')
        cursor = conn.cursor()
        
        # Load all genres once
        cursor.execute('SELECT id, parent_genre, sub_genre, prototype_text, embedding FROM subgenres')
        genres = cursor.fetchall()
        
        print(f"Loaded {len(genres)} genres from database", file=sys.stderr)
        
        # Aggregate results
        genre_votes = defaultdict(lambda: {'votes': 0, 'scores': [], 'parent': '', 'prototype': ''})
        chunk_details = []
        book_title = chunks[0].get('book_title', 'Unknown') if chunks else 'Unknown'
        
        # Process each chunk
        for chunk_idx, chunk_data in enumerate(chunks):
            book_embedding = chunk_data['embedding']
            chunk_num = chunk_data.get('chunk_number', chunk_idx + 1)
            chunk_text = chunk_data.get('chunk_text', '')
            
            # Calculate similarities for this chunk
            chunk_top_genres = []
            
            for genre_row in genres:
                genre_id, parent, subgenre, prototype, genre_embedding_json = genre_row
                genre_embedding = json.loads(genre_embedding_json)
                
                similarity = cosine_similarity(book_embedding, genre_embedding)
                
                chunk_top_genres.append({
                    'subgenre': subgenre,
                    'parent_genre': parent,
                    'similarity': similarity,
                    'prototype_text': prototype
                })
            
            # Sort and get top 20 for this chunk
            chunk_top_genres.sort(key=lambda x: x['similarity'], reverse=True)
            top_20 = chunk_top_genres[:20]
            
            # Store chunk details (top 5 for display)
            chunk_details.append({
                'chunk_number': chunk_num,
                'chunk_preview': chunk_text[:150],
                'top_5_genres': [
                    {
                        'subgenre': g['subgenre'],
                        'parent': g['parent_genre'],
                        'similarity': g['similarity']
                    } for g in top_20[:5]
                ]
            })
            
            # Aggregate votes for top 20
            for genre in top_20:
                key = genre['subgenre']
                genre_votes[key]['votes'] += 1
                genre_votes[key]['scores'].append(genre['similarity'])
                genre_votes[key]['parent'] = genre['parent_genre']
                genre_votes[key]['prototype'] = genre['prototype_text']
            
            if (chunk_idx + 1) % 10 == 0:
                print(f"Processed {chunk_idx + 1}/{len(chunks)} chunks", file=sys.stderr)
        
        conn.close()
        
        # Calculate averages and prepare final output
        genre_matches = {}
        for subgenre, data in genre_votes.items():
            genre_matches[subgenre] = {
                'subgenre': subgenre,
                'parent': data['parent'],
                'prototype_text': data['prototype'],
                'votes': data['votes'],
                'avg_similarity': sum(data['scores']) / len(data['scores'])
            }
        
        # Sort by votes and similarity
        sorted_genres = sorted(
            genre_matches.values(),
            key=lambda x: (x['votes'], x['avg_similarity']),
            reverse=True
        )
        
        # Sort chunk details
        chunk_details.sort(key=lambda x: x['chunk_number'])
        
        # Output compact aggregated result
        result = {
            'book_title': book_title,
            'total_chunks': len(chunks),
            'top_20_genres': sorted_genres[:20],
            'chunk_details': chunk_details,
            'processing_complete': True
        }
        
        print(json.dumps(result, separators=(',', ':')))
        sys.exit(0)
        
    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

