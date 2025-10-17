#!/bin/bash

# Test the master workflow

echo "🧪 Testing Master Book Processor Workflow"
echo "================================================"
echo ""

WEBHOOK_URL="http://localhost:5678/webhook/master-book-processor-webhook"

echo "📋 Webhook URL: $WEBHOOK_URL"
echo ""
echo "🔄 Sending test request..."
echo ""

# Send test with correct data structure (no double body)
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "fields": [
        {
          "label": "Upload your manuscript here",
          "value": [
            {
              "url": "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
              "name": "test-manuscript.pdf",
              "type": "application/pdf"
            }
          ]
        }
      ]
    }
  }'

echo ""
echo ""
echo "✅ Request sent!"
echo ""
echo "📊 Check results in n8n:"
echo "   http://localhost:5678"
echo "   → Open workflow"
echo "   → Click 'Executions' tab"
echo "   → Click the newest execution"
echo ""
echo "📝 You should see:"
echo "   1. PDF downloaded ✅"
echo "   2. Text extracted ✅"
echo "   3. Text chunked ✅"
echo "   4. AI analysis per chunk ✅"
echo "   5. Embeddings generated ✅"
echo "   6. Genre matching ✅"
echo "   7. Final report ✅"
echo ""


