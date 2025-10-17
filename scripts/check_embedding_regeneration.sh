#!/bin/bash

LOG_FILE="/Users/eerogetlost/book-processor-local/embedding_regeneration.log"
TOTAL=485

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file not found: $LOG_FILE"
    echo "   Has the regeneration started?"
    exit 1
fi

COMPLETED=$(grep -c '✓' "$LOG_FILE" 2>/dev/null || echo "0")
FAILED=$(grep -c '✗' "$LOG_FILE" 2>/dev/null || echo "0")
PERCENT=$((COMPLETED * 100 / TOTAL))

clear
echo "🔄 Embedding Regeneration Progress"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  Progress: $COMPLETED / $TOTAL ($PERCENT%)"
echo ""
echo "  ✅ Completed: $COMPLETED"
echo "  ❌ Failed:    $FAILED"
echo "  ⏳ Remaining: $((TOTAL - COMPLETED))"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""

if [ $COMPLETED -ge $TOTAL ]; then
    echo "✅ COMPLETE!"
    echo ""
    echo "Check the final summary:"
    echo "  tail -30 $LOG_FILE"
    echo ""
elif grep -q "✅ SUCCESS" "$LOG_FILE" 2>/dev/null; then
    echo "✅ COMPLETE!"
    echo ""
    echo "View summary:"
    echo "  tail -30 $LOG_FILE"
    echo ""
else
    echo "⏳ Still processing..."
    echo ""
    echo "Latest entries:"
    tail -5 "$LOG_FILE" | grep '\[' || echo "  (generating...)"
    echo ""
    echo "Monitor live:"
    echo "  tail -f $LOG_FILE"
    echo ""
    echo "Run this script again:"
    echo "  ./scripts/check_embedding_regeneration.sh"
fi


