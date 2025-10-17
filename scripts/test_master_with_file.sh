#!/bin/bash

# Test master workflow by sending PDF as base64

echo "🧪 Testing Master Workflow with PDF File"
echo "================================================"
echo ""

# Check if a file was provided
PDF_FILE="${1:-}"

if [ -z "$PDF_FILE" ]; then
    # Create a simple test PDF
    echo "📄 No PDF provided, creating test PDF..."
    
    # Create a simple text file
    cat > /tmp/test_manuscript.txt << 'EOF'
SAMPLE MANUSCRIPT

Chapter 1: The Beginning

Sarah stood at the window, watching the rain cascade down the glass. 
Twenty years had passed since she left this town, and now circumstances 
had brought her back. The letter from her mother's lawyer had been brief: 
"Your presence is required for the reading of the will."

The house looked different in the fading light. Smaller somehow, as if 
her memories had inflated it beyond its actual dimensions. She clutched 
the handle of her suitcase and took a deep breath.

This was going to be harder than she thought.

Genre: Contemporary Fiction
Themes: Family, Reconciliation, Coming Home
Target Audience: Adult readers who enjoy character-driven narratives
EOF
    
    # For testing, we'll send this as text
    BASE64_DATA=$(cat /tmp/test_manuscript.txt | base64)
    FILENAME="test_manuscript.txt"
else
    echo "📄 Using provided PDF: $PDF_FILE"
    
    if [ ! -f "$PDF_FILE" ]; then
        echo "❌ File not found: $PDF_FILE"
        exit 1
    fi
    
    BASE64_DATA=$(base64 -i "$PDF_FILE")
    FILENAME=$(basename "$PDF_FILE")
fi

WEBHOOK_URL="http://localhost:5678/webhook/master-book-processor-webhook"

echo "📋 Webhook URL: $WEBHOOK_URL"
echo "📁 File: $FILENAME"
echo "📊 Data size: $(echo "$BASE64_DATA" | wc -c) bytes (base64)"
echo ""
echo "🔄 Sending to workflow..."
echo ""

# Create JSON payload
cat > /tmp/webhook_payload.json << EOF
{
  "data": {
    "file": {
      "name": "$FILENAME",
      "type": "application/pdf",
      "data": "$BASE64_DATA"
    },
    "book_title": "${FILENAME%.*}"
  }
}
EOF

# Send to webhook
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d @/tmp/webhook_payload.json

echo ""
echo ""
echo "✅ Request sent!"
echo ""
echo "📊 Check results in n8n:"
echo "   http://localhost:5678"
echo "   → Master Book Processor workflow"
echo "   → Executions tab"
echo "   → Latest execution"
echo ""
echo "💡 The PDF is now sent directly in the request"
echo "   No external URL needed!"
echo ""

# Cleanup
rm -f /tmp/webhook_payload.json /tmp/test_manuscript.txt


