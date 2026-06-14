"""
Reset a driver's password to a known value
"""
from pymongo import MongoClient
import bcrypt

# MongoDB connection
MONGODB_URI = "mongodb+srv://Dharun:Dharun2712@cluster0.yr5quzl.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
client = MongoClient(MONGODB_URI)
db = client["smart_aid"]

def reset_driver_password(driver_id: str, new_password: str):
    """Reset a driver's password"""
    # Find the driver
    driver = db.ambulance_drivers.find_one({"driver_id": driver_id})
    if not driver:
        print(f"❌ Driver with ID '{driver_id}' not found")
        return False
    
    # Find the user
    user = db.users.find_one({"_id": driver["user_id"]})
    if not user:
        print(f"❌ User record not found for driver '{driver_id}'")
        return False
    
    # Hash the new password
    hashed_password = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt())
    
    # Update the password
    db.users.update_one(
        {"_id": driver["user_id"]},
        {"$set": {"password": hashed_password}}
    )
    
    print(f"✅ Password reset successfully for driver '{driver_id}'")
    print(f"   New password: {new_password}")
    print(f"   Driver Name: {driver.get('name', 'N/A')}")
    print(f"   Vehicle: {driver.get('vehicle_type', 'N/A')} - {driver.get('vehicle_plate', 'N/A')}")
    return True

if __name__ == "__main__":
    # Reset password for drive123
    driver_id = "drive123"
    new_password = "drive@123"
    
    print(f"Resetting password for driver: {driver_id}")
    print(f"New password will be: {new_password}")
    print()
    
    reset_driver_password(driver_id, new_password)
    
    print()
    print("=" * 70)
    print("You can now login with:")
    print(f"  Driver ID: {driver_id}")
    print(f"  Password: {new_password}")
    print("=" * 70)
