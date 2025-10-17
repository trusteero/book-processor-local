#!/bin/bash

# Start the upload server

echo "📤 Starting Manuscript Upload Server"
echo "================================================"
echo ""

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "⚠️  No virtual environment. Installing dependencies globally..."
fi

# Check if dependencies are installed
python3 -c "import fastapi, uvicorn, requests" 2>/dev/null || {
    echo "📦 Installing dependencies..."
    pip install fastapi uvicorn requests python-multipart
}

echo ""
echo "🚀 Starting upload server..."
echo ""
echo "📤 Upload interface: http://localhost:3000"
echo "📊 Server status: http://localhost:3000/status"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start the server
python3 scripts/upload_server.py --port 3000


