#!/usr/bin/env python
"""
MediConnect Backend Startup Script
Loads .env file and starts Uvicorn server with Groq AI services enabled
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
    
    # Verify Groq configuration
    groq_key = os.environ.get("GROQ_API_KEY", "")
    groq_model = os.environ.get("GROQ_MODEL", "mixtral-8x7b-32768")
    
    if groq_key:
        print(f"✅ GROQ_API_KEY loaded ({len(groq_key[:10])}...{groq_key[-5:]})")
        print(f"✅ GROQ_MODEL: {groq_model}")
    else:
        print("⚠️  GROQ_API_KEY not found in .env")
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
