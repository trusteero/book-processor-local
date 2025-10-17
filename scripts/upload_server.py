#!/usr/bin/env python3
"""
Simple upload server for testing manuscript workflows.
Provides a web interface to upload PDFs and automatically triggers the n8n webhook.
"""

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import uvicorn
import os
import requests
from pathlib import Path
import uuid

app = FastAPI(title="Manuscript Upload Server")

# Directory to store uploaded files
UPLOAD_DIR = Path("/tmp/manuscript-uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

# n8n webhook URL (will be configurable)
N8N_WEBHOOK_URL = os.getenv("N8N_WEBHOOK_URL", "http://localhost:5678/webhook/master-book-processor-webhook")

@app.get("/", response_class=HTMLResponse)
async def upload_form():
    """Serve the upload form."""
    return """
<!DOCTYPE html>
<html>
<head>
    <title>Manuscript Upload</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            margin-bottom: 30px;
        }
        .upload-area {
            border: 2px dashed #3498db;
            border-radius: 8px;
            padding: 40px;
            text-align: center;
            margin: 20px 0;
            background: #ecf0f1;
        }
        input[type="file"] {
            margin: 20px 0;
        }
        button {
            background: #3498db;
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
            margin-top: 20px;
        }
        button:hover {
            background: #2980b9;
        }
        .status {
            margin-top: 20px;
            padding: 15px;
            border-radius: 6px;
            display: none;
        }
        .status.success {
            background: #d4edda;
            color: #155724;
            display: block;
        }
        .status.error {
            background: #f8d7da;
            color: #721c24;
            display: block;
        }
        .status.processing {
            background: #fff3cd;
            color: #856404;
            display: block;
        }
        .webhook-config {
            margin: 20px 0;
            padding: 15px;
            background: #e8f4f8;
            border-radius: 6px;
        }
        .webhook-config input {
            width: 100%;
            padding: 8px;
            border: 1px solid #ccc;
            border-radius: 4px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📚 Manuscript Upload</h1>
        <p>Upload your manuscript PDF for AI-powered analysis</p>
        
        <div class="webhook-config">
            <label><strong>n8n Webhook URL:</strong></label>
            <input type="text" id="webhookUrl" value="http://localhost:5678/webhook/master-book-processor-webhook">
            <small>Update this if your webhook URL is different</small>
        </div>
        
        <form id="uploadForm" enctype="multipart/form-data">
            <div class="upload-area">
                <p>📄 Choose your manuscript PDF</p>
                <input type="file" id="fileInput" name="file" accept=".pdf" required>
            </div>
            <button type="submit">Upload & Process</button>
        </form>
        
        <div id="status" class="status"></div>
    </div>
    
    <script>
        document.getElementById('uploadForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const statusDiv = document.getElementById('status');
            const fileInput = document.getElementById('fileInput');
            const webhookUrl = document.getElementById('webhookUrl').value;
            const file = fileInput.files[0];
            
            if (!file) {
                statusDiv.className = 'status error';
                statusDiv.textContent = '❌ Please select a file';
                return;
            }
            
            // Show processing status
            statusDiv.className = 'status processing';
            statusDiv.textContent = '⏳ Uploading and processing...';
            
            try {
                // Upload file
                const formData = new FormData();
                formData.append('file', file);
                formData.append('webhook_url', webhookUrl);
                
                const response = await fetch('/upload', {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                
                if (result.success) {
                    statusDiv.className = 'status success';
                    statusDiv.innerHTML = `
                        ✅ <strong>Upload successful!</strong><br><br>
                        File: ${file.name}<br>
                        Stored at: ${result.file_url}<br><br>
                        <strong>Webhook triggered!</strong><br>
                        Processing in n8n...<br><br>
                        Check results at: <a href="http://localhost:5678" target="_blank">n8n Dashboard</a>
                    `;
                } else {
                    statusDiv.className = 'status error';
                    statusDiv.textContent = '❌ Upload failed: ' + result.error;
                }
            } catch (error) {
                statusDiv.className = 'status error';
                statusDiv.textContent = '❌ Error: ' + error.message;
            }
        });
    </script>
</body>
</html>
"""

@app.post("/upload")
async def upload_file(file: UploadFile = File(...), webhook_url: str = Form(...)):
    """Handle file upload and trigger webhook."""
    
    try:
        # Generate unique filename
        file_id = str(uuid.uuid4())
        file_ext = Path(file.filename).suffix
        stored_filename = f"{file_id}{file_ext}"
        file_path = UPLOAD_DIR / stored_filename
        
        # Read file contents
        contents = await file.read()
        
        # Save the file locally as backup
        with open(file_path, 'wb') as f:
            f.write(contents)
        
        # Convert to base64 for sending in webhook
        import base64
        base64_data = base64.b64encode(contents).decode('utf-8')
        
        # Trigger the n8n webhook with base64 PDF data
        webhook_data = {
            "data": {
                "file": {
                    "name": file.filename,
                    "type": "application/pdf",
                    "data": base64_data,
                    "size": len(contents)
                },
                "book_title": Path(file.filename).stem
            }
        }
        
        # Call the webhook
        try:
            webhook_response = requests.post(webhook_url, json=webhook_data, timeout=10)
            webhook_success = webhook_response.status_code in [200, 201, 202]
        except Exception as e:
            webhook_success = False
            print(f"Webhook call failed: {e}")
        
        return JSONResponse({
            "success": True,
            "filename": file.filename,
            "file_url": file_url,
            "file_path": str(file_path),
            "webhook_triggered": webhook_success,
            "message": "File uploaded successfully! Processing started in n8n."
        })
        
    except Exception as e:
        return JSONResponse({
            "success": False,
            "error": str(e)
        }, status_code=500)

@app.get("/files/{filename}")
async def serve_file(filename: str):
    """Serve uploaded files."""
    file_path = UPLOAD_DIR / filename
    
    if not file_path.exists():
        return JSONResponse({"error": "File not found"}, status_code=404)
    
    from fastapi.responses import FileResponse
    return FileResponse(file_path, media_type="application/pdf", filename=filename)

@app.get("/status")
async def status():
    """Server status."""
    files = list(UPLOAD_DIR.glob("*"))
    return {
        "status": "running",
        "upload_dir": str(UPLOAD_DIR),
        "files_stored": len(files),
        "n8n_webhook": N8N_WEBHOOK_URL
    }

@app.delete("/cleanup")
async def cleanup():
    """Clean up old uploaded files."""
    import time
    deleted = 0
    
    for file_path in UPLOAD_DIR.glob("*"):
        # Delete files older than 1 hour
        if time.time() - file_path.stat().st_mtime > 3600:
            file_path.unlink()
            deleted += 1
    
    return {"deleted": deleted, "message": f"Cleaned up {deleted} old files"}

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Manuscript Upload Server")
    parser.add_argument("--port", type=int, default=3000, help="Port to run on")
    parser.add_argument("--webhook", type=str, help="n8n webhook URL")
    
    args = parser.parse_args()
    
    if args.webhook:
        N8N_WEBHOOK_URL = args.webhook
    
    print("=" * 60)
    print("📚 Manuscript Upload Server")
    print("=" * 60)
    print(f"🌐 Web interface: http://localhost:{args.port}")
    print(f"📁 Upload directory: {UPLOAD_DIR}")
    print(f"🔗 n8n webhook: {N8N_WEBHOOK_URL}")
    print("=" * 60)
    print("")
    print("📤 Upload PDFs at: http://localhost:{args.port}")
    print("📊 Check status at: http://localhost:{args.port}/status")
    print("")
    print("Press Ctrl+C to stop")
    print("")
    
    uvicorn.run(app, host="0.0.0.0", port=args.port)

