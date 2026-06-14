"""
Initialize hospitals near Lords Institute of Engineering and Technology in the database
Reference Point: Lords Institute of Engineering and Technology, Hyderabad
Coordinates: 17.3293, 78.3514
"""

from models import db, hospitals
from datetime import datetime
import math

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two coordinates using Haversine formula (in km)"""
    R = 6371  # Earth's radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    
    a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c

# Reference point: Lords Institute of Engineering and Technology, Hyderabad
REFERENCE_LAT = 17.3293
REFERENCE_LNG = 78.3514

# Hospital data
hospitals_data = [
    {
        'id': 'shadan_hospital',
        'name': 'Shadan Hospital',
        'lat': 17.3177,
        'lng': 78.3527,
        'rating': 4.5,
        'beds': 150,
        'icu': 20,
        'doctors': 50,
        'address': 'Himayath Sagar Rd, Hyderabad, Telangana 500008',
        'phone': '+91-40-29805111',
        'specializations': ['Emergency Care', 'Trauma Center', 'General Medicine', 'Surgery']
    },
    {
        'id': 'renova_hospital',
        'name': 'Renova Hospitals Langar Houz',
        'lat': 17.3865,
        'lng': 78.4085,
        'rating': 4.3,
        'beds': 100,
        'icu': 15,
        'doctors': 35,
        'address': 'Langar Houz, Hyderabad, Telangana 500008',
        'phone': '+91-40-22223333',
        'specializations': ['Emergency Care', 'Multi-specialty', 'Orthopedics', 'Cardiology']
    },
    {
        'id': 'germanten_hospital',
        'name': 'Germanten Hospitals',
        'lat': 17.3667,
        'lng': 78.4288,
        'rating': 4.6,
        'beds': 180,
        'icu': 25,
        'doctors': 60,
        'address': 'Attapur, Hyderabad, Telangana 500048',
        'phone': '+91-40-44445555',
        'specializations': ['Emergency Care', 'Orthopedics', 'Neurology', 'Multi-specialty']
    },
    {
        'id': 'olive_hospital',
        'name': 'Olive Hospital',
        'lat': 17.3690,
        'lng': 78.4330,
        'rating': 4.4,
        'beds': 120,
        'icu': 18,
        'doctors': 45,
        'address': 'Nanal Nagar, Hyderabad, Telangana 500028',
        'phone': '+91-40-66667777',
        'specializations': ['Emergency Care', 'Internal Medicine', 'ICU Care', 'General Surgery']
    },
    {
        'id': 'premier_hospital',
        'name': 'Premier Hospital',
        'lat': 17.3610,
        'lng': 78.4440,
        'rating': 4.5,
        'beds': 130,
        'icu': 20,
        'doctors': 50,
        'address': 'Humayun Nagar, Hyderabad, Telangana 500028',
        'phone': '+91-40-88889999',
        'specializations': ['Emergency Care', '24x7 Service', 'Multi-specialty', 'Critical Care']
    },
    {
        'id': 'care_hospital',
        'name': 'CARE Hospitals Banjara Hills',
        'lat': 17.4147,
        'lng': 78.4347,
        'rating': 4.7,
        'beds': 250,
        'icu': 35,
        'doctors': 90,
        'address': 'Road No 1, Banjara Hills, Hyderabad, Telangana 500034',
        'phone': '+91-40-30417777',
        'specializations': ['Emergency Care', 'Cardiology', 'Neurology', 'ICU Care', 'Multi-specialty']
    },
    {
        'id': 'star_hospital',
        'name': 'Star Hospitals - Block A & C',
        'lat': 17.4178,
        'lng': 78.4386,
        'rating': 4.6,
        'beds': 220,
        'icu': 30,
        'doctors': 80,
        'address': 'Road No 10, Banjara Hills, Hyderabad, Telangana 500034',
        'phone': '+91-40-44777777',
        'specializations': ['Emergency Care', 'Cardiothoracic Surgery', 'Nephrology', 'Multi-specialty']
    },
    {
        'id': 'tx_hospital',
        'name': 'TX Hospitals Banjara Hills',
        'lat': 17.4077701,
        'lng': 78.4446554,
        'rating': 4.5,
        'beds': 160,
        'icu': 22,
        'doctors': 55,
        'address': 'Road No 4, Banjara Hills, Hyderabad, Telangana 500034',
        'phone': '+91-40-48111111',
        'specializations': ['Emergency Care', 'Gastroenterology', 'Pulmonology', 'Multi-specialty']
    },
    {
        'id': 'aster_hospital',
        'name': 'Aster Prime Hospital',
        'lat': 17.4372,
        'lng': 78.4486,
        'rating': 4.6,
        'beds': 200,
        'icu': 28,
        'doctors': 75,
        'address': 'Ameerpet, Hyderabad, Telangana 500038',
        'phone': '+91-40-49494949',
        'specializations': ['Emergency Care', 'Orthopedics', '24x7 Emergency', 'Neurology']
    },
    {
        'id': 'continental_hospital',
        'name': 'Continental Hospitals',
        'lat': 17.4129,
        'lng': 78.3418,
        'rating': 4.8,
        'beds': 300,
        'icu': 40,
        'doctors': 110,
        'address': 'Gachibowli, Hyderabad, Telangana 500032',
        'phone': '+91-40-67000000',
        'specializations': ['Emergency Care', 'Trauma Center', 'Multi-specialty', 'JCI Accredited']
    }
]

def init_kongu_hospitals():
    """Initialize hospitals near Lords Institute of Engineering and Technology, Hyderabad"""
    print("\n" + "="*70)
    print("🏥 INITIALIZING HOSPITALS NEAR LORDS INSTITUTE OF ENG & TECH, HYDERABAD")
    print("="*70)
    print(f"\n📍 Reference Point: Lords College, Hyderabad")
    print(f"   Coordinates: {REFERENCE_LAT}, {REFERENCE_LNG}")
    print("\n")
    
    # Clear existing hospitals
    hospitals.delete_many({})
    print("🗑️  Cleared existing hospitals\n")
    
    inserted_count = 0
    updated_count = 0
    
    for hosp_data in hospitals_data:
        # Calculate distance from reference point
        distance = calculate_distance(
            REFERENCE_LAT, REFERENCE_LNG,
            hosp_data['lat'], hosp_data['lng']
        )
        
        # Determine color based on distance
        if distance < 5.0:
            color_tag = "🟢 Green (Very Close)"
        elif distance < 10.0:
            color_tag = "🟡 Yellow (Close)"
        elif distance < 13.0:
            color_tag = "orange (Moderate)"
        else:
            color_tag = "🔴 Red (Far)"
        
        # Check if hospital already exists
        existing = hospitals.find_one({"hospital_code": hosp_data['id']})
        
        hospital_doc = {
            "hospital_code": hosp_data['id'],
            "name": hosp_data['name'],
            "location": {
                "type": "Point",
                "coordinates": [hosp_data['lng'], hosp_data['lat']]  # MongoDB uses [lng, lat]
            },
            "address": hosp_data['address'],
            "phone": hosp_data['phone'],
            "emergency_phone": hosp_data['phone'],
            "specializations": hosp_data['specializations'],
            "capacity": {
                "icu_beds": hosp_data['icu'],
                "general_beds": hosp_data['beds'],
                "doctors_available": hosp_data['doctors']
            },
            "available_beds": hosp_data['beds'] - 10,  # Some beds occupied
            "rating": hosp_data['rating'],
            "distance_from_kongu": round(distance, 2),
            "status": "active",
            "verified": True,
            "updated_at": datetime.utcnow()
        }
        
        if not existing:
            hospital_doc["created_at"] = datetime.utcnow()
            hospitals.insert_one(hospital_doc)
            inserted_count += 1
            print(f"✅ Added: {hosp_data['name']}")
        else:
            hospitals.update_one(
                {"hospital_code": hosp_data['id']},
                {"$set": hospital_doc}
            )
            updated_count += 1
            print(f"🔄 Updated: {hosp_data['name']}")
        
        print(f"   📍 Location: {hosp_data['lat']}, {hosp_data['lng']}")
        print(f"   📏 Distance: {distance:.2f} km from Lords College")
        print(f"   🎨 Color Tag: {color_tag}")
        print(f"   ⭐ Rating: {hosp_data['rating']}")
        print(f"   🛏️  Beds: {hosp_data['beds']} | ICU: {hosp_data['icu']} | Doctors: {hosp_data['doctors']}")
        print(f"   📞 Phone: {hosp_data['phone']}")
        print()
    
    print("="*70)
    print(f"✅ Hospital Initialization Complete!")
    print(f"   📊 New hospitals added: {inserted_count}")
    print(f"   🔄 Existing hospitals updated: {updated_count}")
    print(f"   📍 Total hospitals: {len(hospitals_data)}")
    print("="*70)
    
    # Print sorted by distance
    print("\n📊 HOSPITALS SORTED BY DISTANCE FROM LORDS COLLEGE:")
    print("="*70)
    
    sorted_hospitals = sorted(hospitals_data, key=lambda x: calculate_distance(
        REFERENCE_LAT, REFERENCE_LNG, x['lat'], x['lng']
    ))
    
    for i, hosp in enumerate(sorted_hospitals, 1):
        distance = calculate_distance(REFERENCE_LAT, REFERENCE_LNG, hosp['lat'], hosp['lng'])
        print(f"{i}. {hosp['name']}: {distance:.2f} km")
    
    print("="*70)

if __name__ == "__main__":
    init_kongu_hospitals()
