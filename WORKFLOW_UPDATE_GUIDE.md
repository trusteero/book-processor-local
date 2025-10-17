# Updating n8n Workflows from Command Line

## Quick Method: Update Script

Use the automated update script:

```bash
# Update the main workflow
./scripts/update_workflow.sh workflows/Master-Book-Processor-JSON.json

# Update a specific workflow
./scripts/update_workflow.sh workflows/Cosine\ Similarity\ Calculator\ \(Local\).json
```

The script will:
- ✅ Find existing workflow by name
- ✅ Update it if found, or create new if not found
- ✅ Display success message with workflow ID

## Manual Method: Using n8n API

If the script doesn't work (e.g., authentication issues), use the n8n API directly:

### 1. List All Workflows
```bash
curl http://localhost:5678/api/v1/workflows
```

### 2. Get Specific Workflow ID
```bash
# Find workflow by name
curl -s http://localhost:5678/api/v1/workflows | \
  python3 -c "import sys,json; workflows=json.load(sys.stdin)['data']; [print(f'{w[\"id\"]}: {w[\"name\"]}') for w in workflows]"
```

### 3. Update Workflow by ID
```bash
# Replace WORKFLOW_ID with the actual ID
curl -X PATCH \
  -H "Content-Type: application/json" \
  http://localhost:5678/api/v1/workflows/WORKFLOW_ID \
  -d @workflows/Master-Book-Processor-JSON.json
```

### 4. Create New Workflow
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  http://localhost:5678/api/v1/workflows \
  -d @workflows/Master-Book-Processor-JSON.json
```

## Manual Import (GUI Method)

If API doesn't work or you prefer GUI:

1. Open n8n: http://localhost:5678
2. Go to "Workflows" 
3. Find the workflow you want to update
4. Click the three dots (⋮) menu
5. Select "Import from File"
6. Choose your updated JSON file
7. Click "Import"

**Note:** This creates a duplicate. Delete the old version after verifying the new one works.

## Alternative: Replace Workflow File Directly

If you know the workflow ID from n8n's database:

```bash
# This is advanced - n8n stores workflows in SQLite or PostgreSQL
# Location depends on n8n configuration
# Default: ~/.n8n/database.sqlite

# Not recommended unless you know what you're doing!
```

## Workflow Files in This Project

- `workflows/Master-Book-Processor-JSON.json` - Main processing workflow
- `workflows/Cosine Similarity Calculator (Local).json` - Similarity calculation
- `workflows/SubGenre Embedding Workflow (Local).json` - Embedding generation
- `workflows/Book Chunks into Vectors (Local).json` - Chunk vectorization

## Troubleshooting

### API Returns 401 Unauthorized
n8n requires authentication. Set up API key:

1. In n8n, go to Settings → API
2. Create an API key
3. Use it in requests:
```bash
curl -H "X-N8N-API-KEY: your-api-key-here" \
  http://localhost:5678/api/v1/workflows
```

### API Not Available
Older n8n versions might not have the API enabled. Check:
```bash
n8n --version
```

Update to latest version:
```bash
npm install -g n8n@latest
```

### Workflow Import Fails
- ✅ Check JSON is valid: `python3 -m json.tool < workflow.json`
- ✅ Check all required credentials exist in n8n
- ✅ Check node types are supported in your n8n version

## Best Practice Workflow

1. **Edit** the JSON file: `workflows/Master-Book-Processor-JSON.json`
2. **Validate** JSON syntax
3. **Update** in n8n: `./scripts/update_workflow.sh workflows/Master-Book-Processor-JSON.json`
4. **Test** the workflow in n8n
5. **Commit** changes to git if working

This keeps your workflow files version-controlled and allows easy rollback!

