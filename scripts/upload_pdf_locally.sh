#!/bin/bash

# Upload PDF by saving locally and sending path

echo "📤 Local PDF Upload for Master Workflow"
echo "================================================"
echo ""

PDF_FILE="$1"

if [ -z "$PDF_FILE" ]; then
    echo "❌ Please provide a PDF file"
    echo ""
    echo "Usage: $0 /path/to/manuscript.pdf"
    exit 1
fi

if [ ! -f "$PDF_FILE" ]; then
    echo "❌ File not found: $PDF_FILE"
    exit 1
fi

# Create upload directory
UPLOAD_DIR="/tmp/manuscript-uploads"
mkdir -p "$UPLOAD_DIR"

# Copy PDF to upload directory with unique name
FILE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
FILE_EXT="${PDF_FILE##*.}"
STORED_FILE="$UPLOAD_DIR/${FILE_ID}.${FILE_EXT}"

echo "📁 Copying PDF to: $STORED_FILE"
cp "$PDF_FILE" "$STORED_FILE"

echo "✅ File saved"
echo ""

# Get file info
FILE_SIZE=$(stat -f%z "$STORED_FILE" 2>/dev/null || stat -c%s "$STORED_FILE" 2>/dev/null)
FILENAME=$(basename "$PDF_FILE")

echo "📊 File info:"
echo "   Name: $FILENAME"
echo "   Size: $FILE_SIZE bytes"
echo "   Path: $STORED_FILE"
echo ""

WEBHOOK_URL="http://localhost:5678/webhook/master-book-processor-webhook"

echo "🔄 Sending file path to workflow..."
echo ""

# Send just the file path
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"file\": {
        \"name\": \"$FILENAME\",
        \"path\": \"$STORED_FILE\",
        \"size\": $FILE_SIZE,
        \"type\": \"application/pdf\"
      },
      \"book_title\": \"${FILENAME%.*}\"
    }
  }"

echo ""
echo ""
echo "✅ Request sent!"
echo ""
echo "📊 Check results in n8n:"
echo "   http://localhost:5678"
echo ""
echo "💡 The workflow will read the PDF from:"
echo "   $STORED_FILE"
echo ""


