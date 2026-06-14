"""
Test MongoDB Atlas connection
"""
from pymongo import MongoClient
import sys

MONGODB_URI = "mongodb+srv://Dharun:Dharun2712@cluster0.yr5quzl.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"

print("="*70)
print("Testing MongoDB Atlas Connection")
print("="*70)
print()

print(f"Connection URI: {MONGODB_URI[:50]}...")
print()

try:
    print("Attempting to connect...")
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
    
    print("✅ Client created successfully")
    print()
    
    print("Testing server info...")
    info = client.server_info()
    print(f"✅ Connected to MongoDB Atlas!")
    print(f"   Server version: {info.get('version')}")
    print()
    
    print("Listing databases...")
    dbs = client.list_database_names()
    print(f"✅ Available databases: {dbs}")
    print()
    
    if "smart_ambulance" in dbs:
        db = client["smart_ambulance"]
        collections = db.list_collection_names()
        print(f"✅ Collections in 'smart_ambulance': {collections}")
        print()
        
        if "ambulance_drivers" in collections:
            driver_count = db.ambulance_drivers.count_documents({})
            print(f"✅ Found {driver_count} drivers in database")
    
    print("="*70)
    print("✅ ALL TESTS PASSED - MongoDB Atlas is accessible!")
    print("="*70)
    sys.exit(0)
    
except Exception as e:
    print(f"❌ CONNECTION FAILED")
    print(f"   Error: {str(e)}")
    print()
    print("="*70)
    print("TROUBLESHOOTING STEPS:")
    print("="*70)
    print("1. Check your firewall/antivirus settings")
    print("2. Verify MongoDB Atlas Network Access (IP Whitelist)")
    print("   - Go to: https://cloud.mongodb.com")
    print("   - Network Access → Add IP Address → Allow Access from Anywhere (0.0.0.0/0)")
    print("3. Check if your network blocks MongoDB ports (27017)")
    print("4. Try connecting from a different network")
    print("5. Verify credentials are correct")
    print("="*70)
    sys.exit(1)
