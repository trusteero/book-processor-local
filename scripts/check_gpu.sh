#!/bin/bash

# Check GPU availability and usage

echo "🔍 GPU/Accelerator Check"
echo "================================================"
echo ""

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "❌ Virtual environment not found"
    exit 1
fi

echo "📊 PyTorch Device Information:"
echo ""

python3 << 'EOF'
import torch
import platform

print(f"System: {platform.system()} {platform.machine()}")
print(f"PyTorch version: {torch.__version__}")
print("")

print("GPU Availability:")
print(f"  CUDA (NVIDIA): {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"  CUDA devices: {torch.cuda.device_count()}")
    for i in range(torch.cuda.device_count()):
        print(f"    Device {i}: {torch.cuda.get_device_name(i)}")

if hasattr(torch.backends, 'mps'):
    print(f"  MPS (Apple Silicon): {torch.backends.mps.is_available()}")
    if torch.backends.mps.is_available():
        print("    ✅ Apple GPU acceleration available!")
else:
    print(f"  MPS (Apple Silicon): Not supported in this PyTorch version")

print("")
print("Recommended device:", end=" ")
if torch.cuda.is_available():
    print("cuda (NVIDIA GPU)")
elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
    print("mps (Apple Silicon GPU)")
else:
    print("cpu (No GPU acceleration)")
EOF

echo ""
echo "================================================"
echo ""

# Check if server is running and what device it's using
if curl -s http://localhost:8000/current_model > /dev/null 2>&1; then
    echo "📋 HF Model Server Status:"
    echo ""
    curl -s http://localhost:8000/current_model | python3 -m json.tool
    echo ""
else
    echo "⚠️  HF Model Server is not running"
    echo ""
    echo "Start it with: ./scripts/start_hf_server.sh phi3"
fi

echo ""


