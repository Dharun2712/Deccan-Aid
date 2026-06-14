#!/usr/bin/env python3
"""Reset password for a user"""

import bcrypt
from pymongo import MongoClient
from bson import ObjectId

# MongoDB connection
client = MongoClient("mongodb+srv://Dharun:Dharun2712@cluster0.yr5quzl.mongodb.net/")
db = client["smart_ambulance"]
users = db["users"]

# User to update
user_id = "68ff86c1d8a5d6f6c028cb4f"
new_password = "123456"  # Change this to your desired password

# Hash the password
hashed = bcrypt.hashpw(new_password.encode("utf-8"), bcrypt.gensalt())

# Update the user
result = users.update_one(
    {"_id": ObjectId(user_id)},
    {"$set": {"password": hashed}}
)

if result.modified_count > 0:
    print(f"✅ Password updated successfully for user {user_id}")
    print(f"📧 Email: kishore1@gmail.com")
    print(f"📞 Phone: 9876543210")
    print(f"🔑 New Password: {new_password}")
    print(f"\n🚪 Login using:")
    print(f"   - Driver ID: (check ambulance_drivers collection)")
    print(f"   - Password: {new_password}")
else:
    print(f"❌ Failed to update password")
