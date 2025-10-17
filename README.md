# Book Processor Local

Local book processing system using Ollama for embeddings and n8n workflows for genre classification.

## Overview

This system processes manuscripts and automatically classifies them into 485 subgenres using semantic embeddings and cosine similarity matching. All processing happens locally with no API costs.

## Features

- 🤖 **Local Processing**: Uses Ollama (no cloud APIs)
- 📊 **485 Subgenres**: Comprehensive genre classification
- 🔍 **Embedding-Based**: Semantic similarity using snowflake-arctic-embed
- 📝 **Chunk Analysis**: Configurable overlapping chunks for better context
- 📈 **Detailed Reports**: Text, HTML, and JSON output formats
- 🎯 **Keyword Matching**: Shows both semantic and lexical matches

## Requirements

- Python 3.12+
- Ollama with snowflake-arctic-embed model
- n8n (for workflow execution)

## Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Install and start Ollama:
```bash
./scripts/setup_ollama.sh
```

3. Generate subgenre embeddings:
```bash
python3 scripts/generate_subgenre_embeddings.py
```

4. Start n8n:
```bash
./scripts/start_n8n.sh
```

## Usage

### Process a Book

```bash
./scripts/upload_text.sh path/to/book.txt "Book Title"
```

Or use the upload server:
```bash
./scripts/start_upload_server.sh
```

### Configuration

See [CHUNKING_CONFIG.md](CHUNKING_CONFIG.md) for detailed chunking configuration options.

## Workflows

Located in `workflows/`:
- **Master-Book-Processor-JSON.json**: Main processing workflow
- **Cosine Similarity Calculator (Local).json**: Genre matching
- **SubGenre Embedding Workflow (Local).json**: Generate embeddings
- **Book Chunks into Vectors (Local).json**: Chunk vectorization

## Output

Reports are generated in `reports/` folder:
- `.txt` - Text format report
- `.html` - Formatted HTML report
- `.json` - Complete data export

## Documentation

- [CHUNKING_CONFIG.md](CHUNKING_CONFIG.md) - Overlapping chunk configuration
- [COMPLETE_WORKFLOW_GUIDE.md](COMPLETE_WORKFLOW_GUIDE.md) - Full workflow guide
- [FINAL_SETUP_SNOWFLAKE.md](FINAL_SETUP_SNOWFLAKE.md) - Snowflake embedding setup

## Data

- `data/subgenres.json` - 485 subgenres with embeddings (1024-dim vectors)
- `data/book_chunks.json` - Processed book chunks (usually empty)

## Example Reports

See `reports/` for sample analysis outputs showing:
- Top 20 genre matches
- Keyword analysis
- Chunk-by-chunk genre breakdown

## Architecture

1. **Upload**: Text file or JSON payload
2. **Chunking**: Configurable overlapping chunks
3. **Embedding**: Ollama snowflake-arctic-embed (1024-dim)
4. **Matching**: Cosine similarity against 485 subgenres
5. **Aggregation**: Vote-based genre ranking
6. **Reporting**: Multi-format output

## Recent Updates

- ✅ Added overlapping chunk support (configurable)
- ✅ Fixed embedding merge bug (chunks now have unique embeddings)
- ✅ Added chunk-by-chunk genre analysis to reports
- ✅ Enhanced keyword matching with semantic and lexical detection

## License

Private project for book genre classification.

