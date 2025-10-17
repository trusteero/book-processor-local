#!/bin/bash

# Upload text file or convert PDF to text and upload

echo "📤 Upload Manuscript Text"
echo "================================================"
echo ""

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 <file.txt|file.pdf>"
    echo ""
    echo "Examples:"
    echo "  $0 manuscript.txt          # Upload text file"
    echo "  $0 manuscript.pdf          # Convert PDF to text, then upload"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "❌ File not found: $FILE"
    exit 1
fi

WEBHOOK_URL="http://localhost:5678/webhook/master-book-processor-webhook"
FILENAME=$(basename "$FILE")
BOOK_TITLE="${FILENAME%.*}"

# Check file type
if [[ "$FILE" == *.pdf ]]; then
    echo "📄 PDF file detected - converting to text..."
    
    # Check if pdftotext is available
    if ! command -v pdftotext &> /dev/null; then
        echo "❌ pdftotext not found. Install with: brew install poppler"
        exit 1
    fi
    
    # Extract text
    TEXT=$(pdftotext "$FILE" - 2>&1)
    
    if [ $? -ne 0 ]; then
        echo "❌ PDF extraction failed"
        echo "$TEXT"
        exit 1
    fi
    
    echo "✅ Extracted $(echo "$TEXT" | wc -w) words from PDF"
    
elif [[ "$FILE" == *.txt ]] || [[ "$FILE" == *.md ]]; then
    echo "📝 Text file detected - reading..."
    TEXT=$(cat "$FILE")
    echo "✅ Read $(echo "$TEXT" | wc -w) words"
else
    echo "⚠️  Unknown file type, trying to read as text..."
    TEXT=$(cat "$FILE")
fi

echo ""
echo "📊 Manuscript info:"
echo "   Title: $BOOK_TITLE"
echo "   Length: $(echo "$TEXT" | wc -w) words"
echo "   Characters: $(echo "$TEXT" | wc -c) characters"
echo ""

echo "🔄 Sending to workflow and waiting for completion..."
echo ""
echo "⏳ This will take 20-30 minutes. Please wait..."
echo ""

# Create JSON using a temporary file (avoids "Argument list too long")
TEMP_JSON=$(mktemp)
echo "$TEXT" | jq -R -s --arg title "$BOOK_TITLE" '{
  text: .,
  book_title: $title
}' > "$TEMP_JSON"

# Send as JSON and wait for response (with timeout)
# The workflow will now wait until processing is complete before responding
RESPONSE=$(curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d @"$TEMP_JSON" \
  --max-time 3600 \
  -s -w "\n%{http_code}" 2>&1)

# Cleanup
rm -f "$TEMP_JSON"

# Parse response
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo ""
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Processing complete!"
    echo ""
    
    # Try to extract top genre
    TOP_GENRE=$(echo "$BODY" | grep -o '"top_genre":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$TOP_GENRE" ]; then
        echo "🎯 Top Genre Classification: $TOP_GENRE"
        echo ""
    fi
    
    # Show response
    echo "📊 Response:"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
else
    echo "⚠️  Request completed but returned HTTP $HTTP_CODE"
    echo ""
    echo "Response:"
    echo "$BODY"
fi
echo ""
echo "📊 Check processing in n8n:"
echo "   http://localhost:5678"
echo ""
echo "⏱️  Expected processing time:"
echo "   - Small (<50K words): 5-10 minutes"
echo "   - Medium (50-100K words): 10-20 minutes"  
echo "   - Large (100K+ words): 20-40 minutes"
echo ""

