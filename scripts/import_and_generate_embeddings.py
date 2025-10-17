#!/usr/bin/env python3
"""
Import subgenres from Excel and generate fresh embeddings using Ollama.
Reads from 'subgenres2.0_extendedv3' sheet.
"""

import json
import requests
import sys
import pandas as pd
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR.parent / "data"
EXCEL_FILE = SCRIPT_DIR.parent / "Master Subgenre List 2.1 16th Sept 2025.xlsx"
SUBGENRES_FILE = DATA_DIR / "subgenres.json"
OLLAMA_URL = "http://127.0.0.1:11434/api/embeddings"
EMBEDDING_MODEL = "snowflake-arctic-embed"
SHEET_NAME = "subgenres2.0_extendedv3"

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

def create_prototype_text(row):
    """Create a rich prototype text from all available columns."""
    parts = []
    
    # Add parent and subgenre
    parts.append(f"{row['Parent Genre']} - {row['Sub Genre']}")
    
    # Add short description if available
    if pd.notna(row.get('Short Description')):
        parts.append(str(row['Short Description']))
    
    # Add key themes if available
    if pd.notna(row.get('Key Themes/Motifs')):
        parts.append(f"Key themes: {row['Key Themes/Motifs']}")
    
    # Add common tropes if available
    if pd.notna(row.get('Common Tropes')):
        parts.append(f"Common tropes: {row['Common Tropes']}")
    
    # Add synonyms if available
    if pd.notna(row.get('Synonyms')):
        parts.append(f"Also known as: {row['Synonyms']}")
    
    # Add exemplar prose if available
    if pd.notna(row.get('Exemplar Prose')):
        parts.append(f"Example: {row['Exemplar Prose']}")
    
    return ". ".join(parts)

def main():
    print(f"📚 Import Subgenres and Generate Embeddings")
    print("=" * 60)
    print()
    
    # Check if Excel file exists
    if not EXCEL_FILE.exists():
        print(f"❌ Excel file not found: {EXCEL_FILE}")
        sys.exit(1)
    
    # Load Excel sheet
    print(f"📖 Loading sheet '{SHEET_NAME}' from Excel...")
    try:
        df = pd.read_excel(EXCEL_FILE, sheet_name=SHEET_NAME)
        print(f"✅ Loaded {len(df)} subgenres")
        print()
    except Exception as e:
        print(f"❌ Error loading Excel: {e}")
        sys.exit(1)
    
    # Verify required columns
    required_columns = ['Parent Genre', 'Sub Genre']
    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        print(f"❌ Missing required columns: {missing}")
        sys.exit(1)
    
    # Show available columns
    print(f"📊 Available columns:")
    for col in df.columns:
        print(f"   • {col}")
    print()
    
    # Convert to our JSON format
    print(f"🔄 Converting to JSON format...")
    subgenres = []
    
    for idx, row in df.iterrows():
        # Create rich prototype text
        prototype_text = create_prototype_text(row)
        
        subgenre = {
            "parent_genre": str(row['Parent Genre']),
            "sub_genre": str(row['Sub Genre']),
            "prototype_text": prototype_text,
            "embedding": None  # Will generate below
        }
        subgenres.append(subgenre)
    
    print(f"✅ Converted {len(subgenres)} subgenres")
    print()
    
    # Show example of first subgenre
    print("📝 Example subgenre (first entry):")
    print(f"   Parent: {subgenres[0]['parent_genre']}")
    print(f"   Sub: {subgenres[0]['sub_genre']}")
    print(f"   Prototype: {subgenres[0]['prototype_text'][:150]}...")
    print()
    
    # Generate embeddings
    print(f"🤖 Generating embeddings with {EMBEDDING_MODEL}...")
    print(f"   This will take ~5-10 minutes for {len(subgenres)} subgenres")
    print()
    
    failed = []
    for i, genre in enumerate(subgenres, 1):
        print(f"[{i}/{len(subgenres)}] {genre['sub_genre'][:40]:40s}", end=" ", flush=True)
        
        embedding = get_embedding(genre['prototype_text'])
        if embedding:
            genre["embedding"] = embedding
            print(f"✓ ({len(embedding)} dims)")
        else:
            print(f"✗ FAILED")
            failed.append(genre['sub_genre'])
    
    print()
    
    if failed:
        print(f"⚠️  Failed to generate embeddings for {len(failed)} subgenres:")
        for name in failed[:10]:
            print(f"   • {name}")
        if len(failed) > 10:
            print(f"   ... and {len(failed) - 10} more")
        print()
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            print("❌ Aborted")
            sys.exit(1)
    
    # Save to JSON
    print(f"💾 Saving to {SUBGENRES_FILE}...")
    SUBGENRES_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(SUBGENRES_FILE, 'w') as f:
        json.dump(subgenres, f, indent=2)
    
    print()
    print("=" * 60)
    print("✅ SUCCESS!")
    print("=" * 60)
    print()
    print(f"📊 Summary:")
    print(f"   • Total subgenres: {len(subgenres)}")
    print(f"   • Successfully embedded: {len(subgenres) - len(failed)}")
    print(f"   • Failed: {len(failed)}")
    print(f"   • Model: {EMBEDDING_MODEL}")
    print(f"   • Dimensions: {len(subgenres[0]['embedding']) if subgenres[0]['embedding'] else 'N/A'}")
    print()
    print(f"📁 Output file: {SUBGENRES_FILE}")
    print()
    print("🚀 Next steps:")
    print("   1. Re-import workflow in n8n (if not already done)")
    print("   2. Test with: ./scripts/upload_text.sh <book.txt>")
    print()

if __name__ == "__main__":
    main()


