#!/bin/bash

# Start n8n locally for book processor workflow
# This script starts n8n with a local data directory

set -e

echo "🚀 Starting n8n locally for Book Processor..."
echo "================================================"

# Configuration
export N8N_PORT=5678
export N8N_HOST="0.0.0.0"
export N8N_PROTOCOL="http"
export WEBHOOK_URL="http://localhost:5678/"

# Use a local n8n directory to keep data separate
export N8N_USER_FOLDER="$HOME/.n8n-local"

# Create the directory if it doesn't exist
mkdir -p "$N8N_USER_FOLDER"

echo "✅ Configuration:"
echo "   📍 Port: $N8N_PORT"
echo "   📁 Data folder: $N8N_USER_FOLDER"
echo "   🔗 Access URL: http://localhost:$N8N_PORT"
echo "   🪝 Webhook base: $WEBHOOK_URL"
echo ""

# Check if n8n is installed
if ! command -v n8n &> /dev/null; then
    echo "❌ n8n is not installed!"
    echo ""
    echo "To install n8n, run:"
    echo "  npm install -g n8n"
    echo ""
    exit 1
fi

echo "✅ n8n version: $(n8n --version)"
echo ""

# Check if port is already in use
if lsof -Pi :$N8N_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Warning: Port $N8N_PORT is already in use!"
    echo ""
    echo "To find what's using it:"
    echo "  lsof -i :$N8N_PORT"
    echo ""
    echo "To kill the process:"
    echo "  kill -9 \$(lsof -t -i:$N8N_PORT)"
    echo ""
    read -p "Do you want to kill the process and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Killing process on port $N8N_PORT..."
        kill -9 $(lsof -t -i:$N8N_PORT) 2>/dev/null || true
        sleep 2
    else
        echo "Exiting..."
        exit 1
    fi
fi

echo "🌐 Starting n8n..."
echo "   Press Ctrl+C to stop"
echo ""
echo "================================================"
echo ""

# Open browser after a delay
(sleep 3 && open "http://localhost:$N8N_PORT" 2>/dev/null) &

# Start n8n
n8n start

# This line will only execute if n8n exits
echo ""
echo "================================================"
echo "👋 n8n stopped"

