# Pipeline Chunk Count Verification

## Overview

To ensure all chunks flow through the entire processing pipeline without being lost, logging has been added at each stage.

## Pipeline Stages & Logging

### 1. Chunk Text Node
**What it does:** Creates chunks from the manuscript
**Logging:**
```
✅ CHUNK TEXT: Created 10 chunks with 20% overlap
```
**Verify:** Check that the expected number of chunks is created

### 2. Preserve Chunk Data Node
**What it does:** Passes chunks through (optionally with AI analysis)
**Logging:**
```
✅ PRESERVE CHUNK DATA: Processing 10 chunks
```
**Verify:** Should match chunk count from step 1

### 3. Generate Embeddings Node
**What it does:** HTTP requests to Ollama for each chunk
**Action:** This is an HTTP Request node that processes each chunk individually
**Verify:** Check n8n execution shows 10 items processed

### 4. Merge Embedding with Chunk Data
**What it does:** Combines embedding responses with original chunk data
**Logging:**
```
✅ MERGE EMBEDDINGS: Successfully merged 10 chunks with their embeddings
```
**Verify:** Should match chunk count from steps 1-2

### 5. Merge Branches Node
**What it does:** Combines book chunks with subgenre definitions
**Action:** Built-in merge node
**Verify:** Output should be (chunks + subgenres) items

### 6. Calculate Genre Similarity Node
**What it does:** Calculates similarity scores for each chunk against all genres
**Logging:**
```
✅ CALCULATE SIMILARITY: Total inputs received: 495
  📚 Book chunks: 10
  🎭 Genre definitions: 485
```
**Verify:** Book chunks should match previous steps

### 7. Aggregate Results Node
**What it does:** Combines all chunk results into final report
**Logging:**
```
✅ AGGREGATE RESULTS: Processing 10 chunk analysis results
  📊 Final stats: 10 chunks, 245 unique genres matched
  📄 Chunk details collected: 10
```
**Verify:** All three counts should match (total_chunks, items.length, chunk_details.length)

## How to Verify Pipeline Integrity

### 1. Check n8n Execution Logs
After running a workflow:
1. Open n8n: http://localhost:5678
2. Go to "Executions" tab
3. Click on the latest execution
4. Check each node's output count

### 2. Check Console Logs
If running n8n in terminal, you'll see:
```
✅ CHUNK TEXT: Created 10 chunks with 20% overlap
✅ PRESERVE CHUNK DATA: Processing 10 chunks
✅ MERGE EMBEDDINGS: Successfully merged 10 chunks with their embeddings
✅ CALCULATE SIMILARITY: Total inputs received: 495
  📚 Book chunks: 10
  🎭 Genre definitions: 485
✅ AGGREGATE RESULTS: Processing 10 chunk analysis results
  📊 Final stats: 10 chunks, 245 unique genres matched
  📄 Chunk details collected: 10
```

### 3. Check Final Report
The report should show:
```
Chunks Analyzed: 10
```

And the chunk-by-chunk section should list all 10 chunks.

## Common Issues

### Issue: Chunks Lost After Embeddings
**Symptom:** MERGE EMBEDDINGS shows fewer chunks than PRESERVE CHUNK DATA
**Cause:** Ollama embedding request failed for some chunks
**Fix:** Check Ollama logs, increase timeout in HTTP Request node

### Issue: Wrong Total Chunks in Report
**Symptom:** Report shows different number than pipeline logs
**Cause:** Aggregate node counting incorrectly
**Fix:** Verify `items.length` matches actual chunk count

### Issue: Missing Chunks in Chunk-by-Chunk Section
**Symptom:** Some chunk numbers missing from report
**Cause:** Chunks without `top_genres` data are skipped
**Fix:** Check Calculate Genre Similarity node returns data for all chunks

### Issue: Duplicate Chunk Numbers
**Symptom:** Same chunk number appears multiple times
**Cause:** Chunking logic error
**Fix:** Verify chunk_number increments correctly in Chunk Text node

## Expected Counts

For a book with configuration:
- `CHUNK_SIZE = 1000`
- `OVERLAP_PERCENT = 0.20`
- `MAX_CHUNKS = 10`
- `USE_FULL_BOOK = false`

**Pipeline should show:**
```
Stage 1 (Chunk Text):        10 chunks
Stage 2 (Preserve):           10 chunks
Stage 3 (Generate Embeddings): 10 HTTP calls → 10 embeddings
Stage 4 (Merge):              10 chunks
Stage 5 (Merge Branches):     495 items (10 chunks + 485 genres)
Stage 6 (Calculate):          10 chunk results
Stage 7 (Aggregate):          10 chunks → 1 final report
```

## Troubleshooting Commands

### Count Items at Each Stage
In n8n execution view, each node shows item count in the connection line.

### Check for Missing Chunks
Look for gaps in chunk numbers:
```javascript
// In Aggregate Results, add:
const chunkNumbers = items.map(i => i.json.chunk_number).sort((a,b) => a-b);
console.log('Chunk numbers received:', chunkNumbers);
// Should show: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
```

### Verify No Duplicates
```javascript
const duplicates = chunkNumbers.filter((n, i, arr) => arr.indexOf(n) !== i);
if (duplicates.length > 0) {
  console.log('⚠️  Duplicate chunks:', duplicates);
}
```

## Success Criteria

✅ All console logs show same chunk count
✅ No warnings about missing chunks
✅ Final report shows correct chunk count
✅ Chunk-by-chunk section has all chunks (1 through N)
✅ No duplicate chunk numbers
✅ Each chunk has different genre scores (not identical)

