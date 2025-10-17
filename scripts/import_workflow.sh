#!/bin/bash

# Import workflow into n8n using the API
# This script imports the manuscripter-v2.json workflow

set -e

echo "📥 Importing workflow into n8n..."
echo "================================================"

# Configuration
N8N_HOST="http://localhost:5678"
WORKFLOW_FILE="workflows/manuscripter-v2.json"

# Check if workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ Error: Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

echo "✅ Workflow file found: $WORKFLOW_FILE"

# Check if n8n is running
if ! curl -s "$N8N_HOST" > /dev/null 2>&1; then
    echo "❌ Error: n8n is not running at $N8N_HOST"
    echo ""
    echo "Please start n8n first:"
    echo "  ./start_n8n.sh"
    echo ""
    exit 1
fi

echo "✅ n8n is running at $N8N_HOST"
echo ""

echo "📋 Manual Import Instructions:"
echo "================================================"
echo ""
echo "To import the workflow manually:"
echo ""
echo "1. Go to: $N8N_HOST"
echo "2. Click 'Workflows' in the left sidebar"
echo "3. Click 'Add Workflow' (+ button)"
echo "4. Click the three dots (⋮) in the top right"
echo "5. Select 'Import from File'"
echo "6. Choose: $WORKFLOW_FILE"
echo "7. Click 'Save'"
echo "8. Activate the workflow (toggle switch)"
echo ""
echo "================================================"
echo ""

# Open n8n in browser
echo "🌐 Opening n8n in browser..."
if command -v open >/dev/null 2>&1; then
    open "$N8N_HOST"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$N8N_HOST"
else
    echo "   Please open $N8N_HOST in your browser"
fi

echo ""
echo "✨ Ready to import!"

