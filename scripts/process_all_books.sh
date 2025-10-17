#!/bin/bash

# Process all books in a directory through the genre classification workflow

BOOKS_DIR="${1:-/Users/eerogetlost/GetLostBooks/text}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPLOAD_SCRIPT="$SCRIPT_DIR/upload_text.sh"

echo "📚 Batch Process All Books"
echo "================================================"
echo ""
echo "📁 Directory: $BOOKS_DIR"
echo ""

if [ ! -d "$BOOKS_DIR" ]; then
    echo "❌ Directory not found: $BOOKS_DIR"
    exit 1
fi

# Count files
TOTAL=$(find "$BOOKS_DIR" -type f \( -name "*.txt" -o -name "*.md" \) | wc -l | tr -d ' ')
echo "📊 Found $TOTAL text files"
echo ""

if [ $TOTAL -eq 0 ]; then
    echo "❌ No text files found in $BOOKS_DIR"
    exit 1
fi

echo "⏱️  Estimated total time: $(($TOTAL * 20)) - $(($TOTAL * 30)) minutes"
echo ""

# Ask for confirmation
read -p "🤔 Process all $TOTAL books? (y/n) " -n 1 -r
echo ""
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 0
fi

# Process each file
CURRENT=0
SUCCEEDED=0
FAILED=0
FAILED_FILES=()

for FILE in "$BOOKS_DIR"/*.txt "$BOOKS_DIR"/*.md; do
    # Skip if glob didn't match
    [ -e "$FILE" ] || continue
    
    CURRENT=$((CURRENT + 1))
    FILENAME=$(basename "$FILE")
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📖 [$CURRENT/$TOTAL] Processing: $FILENAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⏳ Processing... (this will take 20-30 minutes)"
    echo ""
    
    # Record start time
    START_TIME=$(date +%s)
    
    # Run upload script and capture response
    RESPONSE=$("$UPLOAD_SCRIPT" "$FILE" 2>&1)
    UPLOAD_EXIT=$?
    
    # Calculate duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    echo "$RESPONSE"
    echo ""
    
    if [ $UPLOAD_EXIT -eq 0 ]; then
        # Try to extract top genre from response
        TOP_GENRE=$(echo "$RESPONSE" | grep -o '"top_genre":"[^"]*"' | cut -d'"' -f4)
        
        SUCCEEDED=$((SUCCEEDED + 1))
        echo "✅ Completed in ${MINUTES}m ${SECONDS}s"
        
        if [ -n "$TOP_GENRE" ]; then
            echo "🎯 Top Genre: $TOP_GENRE"
        fi
        
        echo ""
    else
        FAILED=$((FAILED + 1))
        FAILED_FILES+=("$FILENAME")
        echo "❌ Failed after ${MINUTES}m ${SECONDS}s"
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 BATCH PROCESSING SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Succeeded: $SUCCEEDED"
echo "❌ Failed:    $FAILED"
echo "📚 Total:     $TOTAL"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "Failed files:"
    for FILE in "${FAILED_FILES[@]}"; do
        echo "  • $FILE"
    done
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 WHAT'S NEXT?"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "All books are queued for processing in n8n."
echo "Each book takes 20-30 minutes to process."
echo ""
echo "📊 Monitor progress:"
echo "   http://localhost:5678"
echo ""
echo "⏱️  Processing will take approximately:"
echo "   $(($TOTAL * 20)) - $(($TOTAL * 30)) minutes total"
echo ""
echo "   Books are processed ONE AT A TIME by n8n."
echo "   You can see the queue in the n8n UI."
echo ""
echo "📁 View reports when complete:"
echo "   ls -lrt $SCRIPT_DIR/../reports/"
echo ""
echo "   Or use:"
echo "   $SCRIPT_DIR/open_latest_report.sh"
echo ""
echo "💡 TIP: Reports auto-save to:"
echo "   /Users/eerogetlost/book-processor-local/reports/"
echo ""

