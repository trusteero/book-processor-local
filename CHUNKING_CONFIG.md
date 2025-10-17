# Overlapping Chunk Configuration

## Overview

The Master Book Processor now supports **overlapping chunks** with configurable parameters. This provides better context continuity and more accurate genre matching across chunk boundaries.

## Configuration Parameters

Edit the chunking node in `workflows/Master-Book-Processor-JSON.json` (around line 52):

```javascript
// ===== CONFIGURATION =====
const CHUNK_SIZE = 1000;        // Words per chunk
const OVERLAP_PERCENT = 0.20;   // 20% overlap (0.0 - 1.0)
const USE_FULL_BOOK = false;    // true = process entire book, false = limit chunks
const MAX_CHUNKS = 10;          // Only used if USE_FULL_BOOK = false
// =========================
```

### Parameters Explained:

#### 1. `CHUNK_SIZE` (default: 1000)
- Number of words per chunk
- **Examples:**
  - `500` = Smaller, more granular chunks
  - `1000` = Standard size (recommended)
  - `2000` = Larger chunks, fewer total chunks

#### 2. `OVERLAP_PERCENT` (default: 0.20)
- Percentage of overlap between consecutive chunks
- **Range:** 0.0 to 1.0 (0% to 100%)
- **Examples:**
  - `0.0` = No overlap (original behavior)
  - `0.20` = 20% overlap (200 words for 1000-word chunks)
  - `0.50` = 50% overlap (500 words for 1000-word chunks)

#### 3. `USE_FULL_BOOK` (default: false)
- Whether to process the entire book or limit chunks
- **Options:**
  - `false` = Process only first MAX_CHUNKS (faster, for testing)
  - `true` = Process entire book (slower, more comprehensive)

#### 4. `MAX_CHUNKS` (default: 10)
- Maximum number of chunks when USE_FULL_BOOK = false
- **Only applies** when USE_FULL_BOOK is false
- **Examples:**
  - `10` = First 10,000 words (with 1000-word chunks)
  - `20` = First 20,000 words
  - `50` = First 50,000 words

## How Overlapping Works

### Example with 1000-word chunks and 20% overlap:

```
Chunk 1: Words 0-999     (1000 words)
         [================]

Chunk 2: Words 800-1799  (1000 words)
              [================]
         ↑
         200 words overlap

Chunk 3: Words 1600-2599 (1000 words)
                   [================]
              ↑
              200 words overlap
```

### Step Size Calculation:
```
overlap_words = CHUNK_SIZE × OVERLAP_PERCENT
              = 1000 × 0.20
              = 200 words

step_size = CHUNK_SIZE - overlap_words
          = 1000 - 200
          = 800 words (advance per chunk)
```

## New Chunk Metadata

Each chunk now includes additional metadata:

```json
{
  "chunk_number": 1,
  "chunk_text": "...",
  "word_count": 1000,
  "start_word": 0,
  "end_word": 1000,
  "overlap_with_previous": 0
}
```

## Usage Examples

### Example 1: Testing (Current Default)
```javascript
const CHUNK_SIZE = 1000;
const OVERLAP_PERCENT = 0.20;
const USE_FULL_BOOK = false;
const MAX_CHUNKS = 10;
```
- Processes first 10,000 words
- 20% overlap between chunks
- Fast for testing

### Example 2: Full Book Analysis
```javascript
const CHUNK_SIZE = 1000;
const OVERLAP_PERCENT = 0.20;
const USE_FULL_BOOK = true;
const MAX_CHUNKS = 10;  // Ignored
```
- Processes entire book
- 20% overlap
- More comprehensive genre analysis

### Example 3: High Overlap for Context-Heavy Books
```javascript
const CHUNK_SIZE = 1000;
const OVERLAP_PERCENT = 0.50;  // 50% overlap!
const USE_FULL_BOOK = true;
const MAX_CHUNKS = 10;
```
- Each chunk shares 500 words with previous chunk
- Maximum context continuity
- More chunks total (2× as many)

### Example 4: Large Chunks, No Overlap
```javascript
const CHUNK_SIZE = 2000;
const OVERLAP_PERCENT = 0.0;  // No overlap
const USE_FULL_BOOK = true;
const MAX_CHUNKS = 10;
```
- Original behavior with larger chunks
- Faster processing
- Less context between chunks

## Benefits of Overlapping Chunks

1. **Context Continuity**: Narrative elements at chunk boundaries are preserved
2. **Better Genre Matching**: Scenes/themes split across boundaries are captured in both chunks
3. **Reduced Edge Effects**: Genre shifts at boundaries are smoothed out
4. **More Robust Analysis**: Important passages get analyzed multiple times

## Performance Considerations

### Processing Time:
- **No overlap (0%)**: Fastest
- **20% overlap**: ~25% more chunks (moderate increase)
- **50% overlap**: ~100% more chunks (2× processing time)

### For a 100,000-word book:

| Chunk Size | Overlap | Chunks Created | Processing Time |
|------------|---------|----------------|-----------------|
| 1000       | 0%      | 100            | Baseline        |
| 1000       | 20%     | 125            | +25%            |
| 1000       | 50%     | 200            | +100%           |
| 2000       | 20%     | 63             | -37%            |

## Recommended Settings

**For quick testing:**
```javascript
CHUNK_SIZE = 1000
OVERLAP_PERCENT = 0.20
USE_FULL_BOOK = false
MAX_CHUNKS = 10
```

**For production analysis:**
```javascript
CHUNK_SIZE = 1000
OVERLAP_PERCENT = 0.20
USE_FULL_BOOK = true
```

**For highly thematic/literary books:**
```javascript
CHUNK_SIZE = 1500
OVERLAP_PERCENT = 0.30
USE_FULL_BOOK = true
```

## Console Output

The workflow now logs helpful information:
```
Total words: 95432
Chunk size: 1000 words
Overlap: 20% (200 words)
Step size: 800 words
Created 120 chunks with 20% overlap
```

## Debugging

If you see identical genre matches across all chunks (like before), check:
1. ✅ Chunk previews are different
2. ✅ `start_word` and `end_word` are progressing
3. ✅ The embedding merge is using the correct index (we fixed this!)

