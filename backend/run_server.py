#!/usr/bin/env python
"""
MediConnect Backend Startup Script
Loads .env file and starts Uvicorn server with Gemini & Sarvam AI services enabled
"""

import os
import sys
from pathlib import Path

# Load environment variables from .env file
env_file = Path(__file__).parent / ".env"
if env_file.exists():
    print(f"📁 Loading environment from: {env_file}")
    from dotenv import load_dotenv
    load_dotenv(env_file)
    
    # Verify Gemini configuration
    gemini_key = os.environ.get("GEMINI_API_KEY", "") or os.environ.get("GOOGLE_API_KEY", "")
    gemini_model = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")
    
    if gemini_key:
        print(f"✅ GEMINI_API_KEY loaded ({len(gemini_key[:10])}...{gemini_key[-5:]})")
        print(f"✅ GEMINI_MODEL: {gemini_model}")
    else:
        print("⚠️  GEMINI_API_KEY not found in .env")
else:
    print(f"⚠️  .env file not found at {env_file}")

# Install missing dependencies
print("\n📦 Checking dependencies...")
try:
    import dotenv
    print("✅ python-dotenv available")
except ImportError:
    print("⚠️  Installing python-dotenv...")
    os.system("pip install python-dotenv")

# Start Uvicorn server
print("\n🚀 Starting MediConnect backend server...\n")
os.system("python -m uvicorn app_fastapi:socket_app --host 0.0.0.0 --port 8000")
