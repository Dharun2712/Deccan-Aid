#!/usr/bin/env python3
"""
Test script to verify the complete workflow:
1. Create SOS request
2. Driver accepts
3. Driver submits assessment
4. Check hospital dashboard receives it
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:5000"

print("\n" + "="*70)
print("TESTING COMPLETE SOS → DRIVER → HOSPITAL WORKFLOW")
print("="*70 + "\n")

# Step 1: Login as client
print("📱 Step 1: Login as client...")
client_response = requests.post(f"{BASE_URL}/api/login/client", json={
    "identifier": "client@example.com",
    "password": "Client123"
})
if client_response.status_code == 200:
    client_data = client_response.json()
    client_token = client_data['token']
    client_id = client_data['user_id']
    print(f"   ✅ Client logged in: {client_id}")
else:
    print(f"   ❌ Client login failed: {client_response.status_code} - {client_response.text}")
    exit(1)

# Step 2: Trigger SOS
print("\n🚨 Step 2: Triggering SOS...")
sos_response = requests.post(f"{BASE_URL}/api/client/sos", 
    headers={"Authorization": f"Bearer {client_token}"},
    json={
        "latitude": 12.9716,
        "longitude": 77.5946,
        "condition": "TEST: Heart attack",
        "severity": "high"
    }
)
if sos_response.status_code == 201:
    sos_data = sos_response.json()
    request_id = sos_data['request_id']
    print(f"   ✅ SOS triggered: {request_id}")
else:
    print(f"   ❌ SOS failed: {sos_response.status_code} - {sos_response.text}")
    exit(1)

# Step 3: Login as driver
print("\n🚗 Step 3: Login as driver...")
driver_response = requests.post(f"{BASE_URL}/api/login/driver", json={
    "driver_id": "drive123",
    "password": "drive@123"
})
if driver_response.status_code == 200:
    driver_data = driver_response.json()
    driver_token = driver_data['token']
    driver_id = driver_data['user_id']
    print(f"   ✅ Driver logged in: {driver_id}")
else:
    print(f"   ❌ Driver login failed: {driver_response.status_code} - {driver_response.text}")
    exit(1)

# Step 4: Driver updates location
print("\n📍 Step 4: Driver updates location...")
location_response = requests.post(f"{BASE_URL}/api/driver/update_location",
    headers={"Authorization": f"Bearer {driver_token}"},
    json={
        "latitude": 12.9716,
        "longitude": 77.5946
    }
)
print(f"   Location update: {location_response.status_code}")

# Step 5: Driver accepts request
print("\n✅ Step 5: Driver accepts SOS request...")
accept_response = requests.post(f"{BASE_URL}/api/driver/accept_request",
    headers={"Authorization": f"Bearer {driver_token}"},
    json={"request_id": request_id}
)
if accept_response.status_code == 200:
    accept_data = accept_response.json()
    print(f"   ✅ Driver accepted request!")
    print(f"   Message: {accept_data.get('message', 'N/A')}")
else:
    print(f"   ❌ Accept failed: {accept_response.status_code} - {accept_response.text}")
    exit(1)

# Step 6: Driver submits assessment
print("\n🩺 Step 6: Driver submits injury assessment...")
assessment_response = requests.post(f"{BASE_URL}/api/driver/submit_assessment",
    headers={"Authorization": f"Bearer {driver_token}"},
    json={
        "request_id": request_id,
        "injury_risk": "high",
        "injury_notes": "TEST: Severe chest pain, suspected cardiac arrest"
    }
)
if assessment_response.status_code == 200:
    assessment_data = assessment_response.json()
    print(f"   ✅ Assessment submitted!")
    print(f"   Message: {assessment_data.get('message', 'N/A')}")
else:
    print(f"   ❌ Assessment failed: {assessment_response.status_code} - {assessment_response.text}")
    exit(1)

# Step 7: Login as hospital admin
print("\n🏥 Step 7: Login as hospital admin...")
hospital_response = requests.post(f"{BASE_URL}/api/login/admin", json={
    "hospital_code": "hospital1",
    "password": "hospital@1"
})
if hospital_response.status_code == 200:
    hospital_data = hospital_response.json()
    hospital_token = hospital_data['token']
    hospital_id = hospital_data['user_id']
    print(f"   ✅ Hospital admin logged in: {hospital_id}")
else:
    print(f"   ❌ Hospital login failed: {hospital_response.status_code} - {hospital_response.text}")
    exit(1)

# Step 8: Check hospital dashboard
print("\n📊 Step 8: Checking hospital patient requests...")
requests_response = requests.get(f"{BASE_URL}/api/hospital/patient_requests",
    headers={"Authorization": f"Bearer {hospital_token}"}
)
if requests_response.status_code == 200:
    requests_data = requests_response.json()
    patient_requests = requests_data.get('requests', [])
    print(f"   ✅ Hospital endpoint working!")
    print(f"   Total requests: {len(patient_requests)}")
    
    # Find our test request
    our_request = None
    for req in patient_requests:
        if req['_id'] == request_id:
            our_request = req
            break
    
    if our_request:
        print(f"\n   🎉 SUCCESS! Test request found in hospital dashboard:")
        print(f"      Request ID: {our_request['_id']}")
        print(f"      Patient: {our_request.get('user_name', 'N/A')}")
        print(f"      Driver: {our_request.get('driver_name', 'N/A')}")
        print(f"      Vehicle: {our_request.get('vehicle', 'N/A')}")
        print(f"      Injury Risk: {our_request.get('injury_risk', 'N/A')}")
        print(f"      Status: {our_request.get('status', 'N/A')}")
        print(f"      Driver Location: {our_request.get('driver_current_location', 'N/A')}")
    else:
        print(f"\n   ⚠️ Test request NOT found in hospital dashboard")
        print(f"   Looking for request_id: {request_id}")
        print(f"   Available requests: {[r['_id'] for r in patient_requests]}")
else:
    print(f"   ❌ Hospital requests failed: {requests_response.status_code}")
    print(f"   Error: {requests_response.text}")
    exit(1)

print("\n" + "="*70)
print("TEST COMPLETE!")
print("="*70 + "\n")
