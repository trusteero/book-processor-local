# Fix for Subgenres Loading Issue

## Problem

The "Read Binary File" node isn't properly reading `subgenres.json`. The `data` field is empty.

## Solution

Replace both "Load Subgenres JSON" and "Parse Subgenres JSON" nodes with a single Code node.

## Steps to Fix in n8n:

### 1. Delete Two Nodes
- Delete "Load Subgenres JSON" (Read Binary File node)
- Delete "Parse Subgenres JSON" (Code node)

### 2. Add New Code Node

Add a new Code node named "Load and Parse Subgenres" with this code:

```javascript
// Load subgenres directly from file
const items = $input.all();

// Read the file content directly using $(...) helper
const subgenresPath = '/Users/eerogetlost/book-processor-local/data/subgenres.json';

// Use n8n's built-in file reading
const fileContent = await this.helpers.readBinaryFile(subgenresPath);
const jsonText = fileContent.toString('utf8');
const subgenres = JSON.parse(jsonText);

console.log(`✅ Loaded ${subgenres.length} subgenres from file`);

// Filter for valid embeddings
const validGenres = subgenres.filter(g => g.embedding && Array.isArray(g.embedding));

console.log(`  Valid genres with embeddings: ${validGenres.length}`);

// Format for Calculate Genre Similarity node
return validGenres.map(genre => ({
  json: {
    'Sub Genre': genre.sub_genre,
    'Parent Genre': genre.parent_genre,
    'Prototype Text': genre.prototype_text,
    'Vector': JSON.stringify(genre.embedding)
  }
}));
```

### 3. Update Connections

Connect:
- **From:** "Preserve Chunk Data" node
- **To:** "Load and Parse Subgenres" (new node)
- **To:** "Merge Branches" node (index 1)

## Alternative: Use HTTP Request to Local File

If the above doesn't work, you can use an HTTP Request node with a local file server, or use the Execute Command node:

### Code Node with Execute Command Approach:

```javascript
const items = $input.all();

// Read file using Execute Command node (would need separate node)
// For now, hardcode the path and assume it's accessible

// Simpler: Just paste the subgenres array directly (not recommended for 485 items)
// OR: Upload subgenres.json to a Google Sheet and use Google Sheets node instead

throw new Error('Please use one of the alternative approaches documented in SUBGENRES_LOADING_FIX.md');
```

## Recommended: Change to Google Sheets

Instead of reading from a local file:

1. Upload `data/subgenres.json` to a Google Sheet
2. Use Google Sheets node to read it
3. Parse the data from the sheet

This is more reliable in n8n workflows.

## Quick Fix: Inline the Subgenres (Not Recommended)

If you need a quick solution, you could embed the subgenres directly in the Code node, but this is not maintainable for 485 genres.

## Why This Happens

n8n's Read Binary File node behavior varies by version and doesn't always properly populate the `data` field. Using `this.helpers.readBinaryFile()` in a Code node is more reliable.

