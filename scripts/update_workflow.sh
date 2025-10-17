#!/bin/bash

# Update n8n workflow from JSON file using the API
# Usage: ./update_workflow.sh <workflow-file.json> [workflow-name]

set -e

# Configuration
N8N_HOST="http://localhost:5678"
N8N_API="${N8N_HOST}/api/v1"
N8N_API_KEY="${N8N_API_KEY:-}"  # Set via: export N8N_API_KEY="your-key"

# Get workflow file from argument
WORKFLOW_FILE="${1:-workflows/Master-Book-Processor-JSON.json}"
WORKFLOW_NAME="${2:-}"

if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ Error: Workflow file not found: $WORKFLOW_FILE"
    echo ""
    echo "Usage: $0 <workflow-file.json> [workflow-name]"
    echo ""
    echo "Examples:"
    echo "  $0 workflows/Master-Book-Processor-JSON.json"
    echo "  $0 workflows/Master-Book-Processor-JSON.json \"Master Book Processor\""
    exit 1
fi

echo "🔄 Updating n8n workflow from file"
echo "================================================"
echo "📁 File: $WORKFLOW_FILE"

# Check if n8n is running
if ! curl -s "$N8N_HOST" > /dev/null 2>&1; then
    echo "❌ Error: n8n is not running at $N8N_HOST"
    echo ""
    echo "Please start n8n first:"
    echo "  ./scripts/start_n8n.sh"
    echo ""
    exit 1
fi

echo "✅ n8n is running at $N8N_HOST"

# Check for API key
if [ -z "$N8N_API_KEY" ]; then
    echo "⚠️  Warning: N8N_API_KEY not set"
    echo ""
    echo "The n8n API requires authentication. Options:"
    echo ""
    echo "1. Set API key (recommended):"
    echo "   export N8N_API_KEY=\"your-api-key-here\""
    echo "   Get key from: ${N8N_HOST}/settings/api"
    echo ""
    echo "2. Use manual import instead:"
    echo "   - Open ${N8N_HOST}"
    echo "   - Import workflow from file: $WORKFLOW_FILE"
    echo ""
    exit 1
fi

echo "✅ API key found"

# Read and clean workflow file
# Remove fields that the API auto-generates or doesn't accept
WORKFLOW_JSON=$(cat "$WORKFLOW_FILE" | python3 -c "
import sys, json
workflow = json.load(sys.stdin)

# Remove top-level API-generated/managed/read-only fields
fields_to_remove = ['id', 'versionId', 'createdAt', 'updatedAt', 'meta', 'tags', 'active']
for field in fields_to_remove:
    workflow.pop(field, None)

# Keep: name, nodes, connections, settings, pinData
# These are the core workflow definition fields

print(json.dumps(workflow))
")

# Extract workflow name from JSON if not provided
if [ -z "$WORKFLOW_NAME" ]; then
    WORKFLOW_NAME=$(echo "$WORKFLOW_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('name', 'Unknown Workflow'))" 2>/dev/null || echo "Unknown Workflow")
fi

echo "📋 Workflow: $WORKFLOW_NAME"
echo ""

# Try to find existing workflow by name
echo "🔍 Checking for existing workflow..."

EXISTING_ID=$(curl -s -H "X-N8N-API-KEY: $N8N_API_KEY" "${N8N_API}/workflows" 2>/dev/null | \
    python3 -c "
import sys, json
try:
    workflows = json.load(sys.stdin).get('data', [])
    for w in workflows:
        if w.get('name') == '$WORKFLOW_NAME':
            print(w.get('id', ''))
            break
except:
    pass
" 2>/dev/null || echo "")

if [ -n "$EXISTING_ID" ]; then
    echo "✅ Found existing workflow (ID: $EXISTING_ID)"
    echo ""
    echo "📤 Updating workflow..."
    
    # Update existing workflow
    RESPONSE=$(curl -s -X PUT \
        -H "Content-Type: application/json" \
        -H "X-N8N-API-KEY: $N8N_API_KEY" \
        "${N8N_API}/workflows/${EXISTING_ID}" \
        -d "$WORKFLOW_JSON")
    
    if echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); exit(0 if data.get('id') else 1)" 2>/dev/null; then
        echo "✅ Workflow updated successfully!"
        echo "   ID: $EXISTING_ID"
        echo "   Name: $WORKFLOW_NAME"
    else
        echo "❌ Failed to update workflow"
        echo ""
        echo "Response:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
        exit 1
    fi
else
    echo "ℹ️  Workflow not found in n8n"
    echo ""
    echo "📤 Creating new workflow..."
    
    # Create new workflow
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "X-N8N-API-KEY: $N8N_API_KEY" \
        "${N8N_API}/workflows" \
        -d "$WORKFLOW_JSON")
    
    NEW_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null || echo "")
    
    if [ -n "$NEW_ID" ]; then
        echo "✅ Workflow created successfully!"
        echo "   ID: $NEW_ID"
        echo "   Name: $WORKFLOW_NAME"
    else
        echo "❌ Failed to create workflow"
        echo ""
        echo "Response:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
        exit 1
    fi
fi

echo ""
echo "================================================"
echo "🎉 Done! View your workflow at:"
echo "   ${N8N_HOST}/workflow/${EXISTING_ID:-$NEW_ID}"
echo ""

