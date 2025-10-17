#!/bin/bash

# Verify the book processor setup

echo "🔍 Verifying Book Processor Setup"
echo "=================================="
echo ""

# Check data files
echo "📊 Data Files:"
if [ -f "data/subgenres.json" ]; then
    COUNT=$(python3 -c "import json; print(len(json.load(open('data/subgenres.json'))))" 2>/dev/null)
    WITH_EMB=$(python3 -c "import json; print(sum(1 for g in json.load(open('data/subgenres.json')) if g.get('embedding')))" 2>/dev/null)
    DIM=$(python3 -c "import json; data = json.load(open('data/subgenres.json')); print(len(data[0]['embedding']) if data[0].get('embedding') else 0)" 2>/dev/null)
    SIZE=$(ls -lh data/subgenres.json | awk '{print $5}')
    
    echo "   ✅ subgenres.json: $COUNT subgenres ($SIZE)"
    echo "      • With embeddings: $WITH_EMB/$COUNT"
    echo "      • Dimensions: $DIM (should be 768)"
    
    if [ "$WITH_EMB" -eq "$COUNT" ] && [ "$DIM" -eq "768" ]; then
        echo "      ✅ All embeddings ready!"
    else
        echo "      ⚠️  Embeddings incomplete or wrong dimension"
    fi
else
    echo "   ❌ subgenres.json not found"
fi
echo ""

# Check workflows
echo "🔧 Workflows:"
if [ -f "workflows/Master-Book-Processor-JSON.json" ]; then
    SIZE=$(ls -lh workflows/Master-Book-Processor-JSON.json | awk '{print $5}')
    echo "   ✅ Master-Book-Processor-JSON.json ($SIZE)"
else
    echo "   ❌ Master-Book-Processor-JSON.json not found"
fi
echo ""

# Check Ollama
echo "🤖 Ollama Services:"
if command -v ollama &> /dev/null; then
    if pgrep -x "ollama" > /dev/null; then
        echo "   ✅ Ollama is running"
        
        # Check for required models
        if ollama list | grep -q "llama3.2"; then
            echo "   ✅ llama3.2 model available"
        else
            echo "   ⚠️  llama3.2 model not found (run: ollama pull llama3.2)"
        fi
        
        if ollama list | grep -q "nomic-embed-text"; then
            echo "   ✅ nomic-embed-text model available"
        else
            echo "   ⚠️  nomic-embed-text not found (run: ollama pull nomic-embed-text)"
        fi
    else
        echo "   ⚠️  Ollama not running (run: ollama serve)"
    fi
else
    echo "   ❌ Ollama not installed"
fi
echo ""

# Check n8n
echo "🌐 n8n:"
if curl -s http://localhost:5678 > /dev/null 2>&1; then
    echo "   ✅ n8n is running on http://localhost:5678"
else
    echo "   ⚠️  n8n not running (run: npx n8n)"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

READY=true

if [ ! -f "data/subgenres.json" ] || [ "$WITH_EMB" -ne "$COUNT" ] || [ "$DIM" -ne "768" ]; then
    echo "❌ Data files need attention"
    READY=false
fi

if [ ! -f "workflows/Master-Book-Processor-JSON.json" ]; then
    echo "❌ Workflow file missing"
    READY=false
fi

if ! pgrep -x "ollama" > /dev/null; then
    echo "⚠️  Ollama needs to be started"
    READY=false
fi

if ! curl -s http://localhost:5678 > /dev/null 2>&1; then
    echo "⚠️  n8n needs to be started"
    READY=false
fi

if [ "$READY" = true ]; then
    echo "✅ Everything is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Import workflow in n8n (http://localhost:5678)"
    echo "2. Test: ./scripts/upload_text.sh ~/Downloads/Clown.pdf"
else
    echo ""
    echo "Please fix the issues above before proceeding."
fi

echo ""


