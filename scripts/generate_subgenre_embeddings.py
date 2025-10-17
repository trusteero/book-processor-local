#!/usr/bin/env python3
"""
Generate embeddings for subgenre prototype texts using Ollama.
Updates the subgenres.json file with embedding vectors.
"""

import json
import requests
import sys
from pathlib import Path

# Paths
DATA_DIR = Path(__file__).parent.parent / "data"
SUBGENRES_FILE = DATA_DIR / "subgenres.json"
OLLAMA_URL = "http://127.0.0.1:11434/api/embeddings"
#EMBEDDING_MODEL = "nomic-embed-text"
#EMBEDDING_MODEL = "mxbai-embed-large"
EMBEDDING_MODEL = "snowflake-arctic-embed"

def get_embedding(text):
    """Get embedding vector from Ollama."""
    payload = {
        "model": EMBEDDING_MODEL,
        "prompt": text
    }
    
    try:
        response = requests.post(OLLAMA_URL, json=payload)
        response.raise_for_status()
        return response.json()["embedding"]
    except Exception as e:
        print(f"Error getting embedding: {e}")
        return None

def main():
    # Load subgenres
    print(f"Loading subgenres from {SUBGENRES_FILE}...")
    with open(SUBGENRES_FILE, 'r') as f:
        subgenres = json.load(f)
    
    print(f"Found {len(subgenres)} subgenres")
    
    # Clear existing embeddings to force regeneration
    print(f"Clearing existing embeddings to regenerate with {EMBEDDING_MODEL}...")
    for genre in subgenres:
        genre["embedding"] = None
    
    # Generate embeddings
    for i, genre in enumerate(subgenres, 1):
        
        print(f"[{i}/{len(subgenres)}] Generating embedding for '{genre['sub_genre']}'...")
        
        # Create text for embedding (combine parent genre, subgenre, and prototype)
        text = f"{genre['parent_genre']} - {genre['sub_genre']}: {genre['prototype_text']}"
        
        embedding = get_embedding(text)
        if embedding:
            genre["embedding"] = embedding
            print(f"  ✓ Generated embedding with {len(embedding)} dimensions")
        else:
            print(f"  ✗ Failed to generate embedding")
            sys.exit(1)
    
    # Save updated subgenres
    print(f"\nSaving embeddings to {SUBGENRES_FILE}...")
    with open(SUBGENRES_FILE, 'w') as f:
        json.dump(subgenres, f, indent=2)
    
    print("✓ Done! All subgenres now have embeddings.")
    print(f"\nNext steps:")
    print(f"1. Your subgenres.json file is ready to use")
    print(f"2. The n8n workflow will read from this file")
    print(f"3. Run: ./scripts/test_json_workflow.sh to test")

if __name__ == "__main__":
    main()

