#!/bin/bash

# Setup script for using Ollama with your workflow

echo "🤖 Ollama Local LLM Setup"
echo "================================================"
echo ""

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed!"
    echo ""
    echo "To install Ollama:"
    echo "  brew install ollama"
    echo "  # OR download from: https://ollama.com"
    echo ""
    exit 1
fi

echo "✅ Ollama is installed"
echo ""

# Check available models
echo "📋 Available models:"
ollama list
echo ""

# Check if Ollama is running
echo "🔍 Checking if Ollama is running..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama is running on port 11434"
else
    echo "⚠️  Ollama is not running"
    echo ""
    echo "Starting Ollama..."
    ollama serve > /dev/null 2>&1 &
    sleep 3
    
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama started successfully"
    else
        echo "❌ Failed to start Ollama"
        echo "Try running manually: ollama serve"
        exit 1
    fi
fi

echo ""
echo "🧪 Testing Ollama with llama3.1..."
echo ""

RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{
  "model": "llama3.1",
  "prompt": "Say hello in one sentence.",
  "stream": false
}')

if echo "$RESPONSE" | grep -q "response"; then
    echo "✅ Ollama is working!"
    echo ""
    echo "Response from llama3.1:"
    echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])"
else
    echo "⚠️  Test failed. Response:"
    echo "$RESPONSE"
fi

echo ""
echo "================================================"
echo ""
echo "📝 Next Steps to Update Your Workflow:"
echo ""
echo "1. Open n8n: http://localhost:5678"
echo ""
echo "2. Open your Manuscripter V2 workflow"
echo ""
echo "3. For each OpenAI node:"
echo "   a. Note the prompt used"
echo "   b. Add an HTTP Request node"
echo "   c. Configure it with:"
echo ""
echo "      Method: POST"
echo "      URL: http://localhost:11434/api/generate"
echo "      Body (JSON):"
echo '      {
        "model": "llama3.1",
        "prompt": "YOUR_PROMPT_HERE",
        "stream": false
      }'
echo ""
echo "   d. To use the response: {{ \$json.response }}"
echo ""
echo "4. Save and test the workflow"
echo ""
echo "💡 Pro tip: Use 'deepseek-r1:8b' for more detailed analysis"
echo "💡 Pro tip: Use 'llama3.1' for faster processing"
echo ""
echo "📚 Full guide: See LOCAL_LLM_SETUP.md"
echo ""


