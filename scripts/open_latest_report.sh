#!/bin/bash
# Open the most recent HTML report

REPORTS_DIR="/Users/eerogetlost/book-processor-local/reports"

if [ ! -d "$REPORTS_DIR" ]; then
    echo "No reports directory found: $REPORTS_DIR"
    exit 1
fi

# Find latest HTML report
LATEST_HTML=$(ls -t "$REPORTS_DIR"/*.html 2>/dev/null | head -1)

if [ -z "$LATEST_HTML" ]; then
    echo "No HTML reports found in $REPORTS_DIR"
    echo ""
    echo "Process a book first:"
    echo "  ./scripts/upload_text.sh ~/Downloads/YourBook.pdf"
    exit 1
fi

echo "Opening latest report: $(basename "$LATEST_HTML")"
open "$LATEST_HTML"


