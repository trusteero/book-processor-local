#!/bin/bash

# Check embedding generation progress

LOG_FILE="/Users/eerogetlost/book-processor-local/embedding_generation.log"
JSON_FILE="/Users/eerogetlost/book-processor-local/data/subgenres.json"

echo "📊 Embedding Generation Progress"
echo "=================================="

# Check if process is running
if pgrep -f "generate_subgenre_embeddings.py" > /dev/null; then
    echo "Status: ✅ Running"
    
    # Get current progress from log
    CURRENT=$(tail -1 "$LOG_FILE" | grep -oE '\[[0-9]+/485\]' | grep -oE '[0-9]+' | head -1)
    if [ -n "$CURRENT" ]; then
        PERCENT=$((CURRENT * 100 / 485))
        echo "Progress: $CURRENT/485 ($PERCENT%)"
        
        # Estimate time remaining (assuming ~2 seconds per embedding)
        REMAINING=$((485 - CURRENT))
        TIME_LEFT=$((REMAINING * 2))
        MINUTES=$((TIME_LEFT / 60))
        echo "Estimated time left: ~$MINUTES minutes"
    fi
    
    echo ""
    echo "Recent output:"
    tail -5 "$LOG_FILE"
    
else
    echo "Status: ⏹️  Not running"
    
    # Check if completed
    if grep -q "✓ Done! All subgenres now have embeddings." "$LOG_FILE" 2>/dev/null; then
        echo "Result: ✅ COMPLETED!"
        
        # Verify in JSON
        COUNT=$(python3 -c "import json; data = json.load(open('$JSON_FILE')); print(sum(1 for g in data if g.get('embedding')))" 2>/dev/null)
        echo "Embeddings in JSON: $COUNT/485"
        
        if [ "$COUNT" = "485" ]; then
            echo ""
            echo "🎉 All embeddings generated successfully!"
            echo ""
            echo "Next steps:"
            echo "1. Import workflow: workflows/Master-Book-Processor-JSON.json"
            echo "2. Test: ./scripts/upload_text.sh ~/Downloads/Clown.pdf"
        fi
    else
        echo "Result: ❌ Error or interrupted"
        echo ""
        echo "Last 10 lines of log:"
        tail -10 "$LOG_FILE"
    fi
fi

echo ""
echo "Full log: $LOG_FILE"


