#!/usr/bin/env python3
"""
Local test script using Flask test_client to verify the complete workflow without starting the server.
"""

from app_extended import app
import json

print("\n" + "="*70)
print("TESTING COMPLETE SOS → DRIVER → HOSPITAL WORKFLOW (LOCAL TEST CLIENT)")
print("="*70 + "\n")

client = app.test_client()

# Step 1: Login as client
print("📱 Step 1: Login as client...")
resp = client.post('/api/login/client', json={
    "identifier": "client@example.com",
    "password": "Client123"
})
if resp.status_code == 200:
    data = resp.get_json()
    client_token = data['token']
    client_id = data['user_id']
    print(f"   ✅ Client logged in: {client_id}")
else:
    print(f"   ❌ Client login failed: {resp.status_code} - {resp.get_data(as_text=True)}")
    raise SystemExit(1)

# Step 2: Trigger SOS
print("\n🚨 Step 2: Triggering SOS...")
resp = client.post('/api/client/sos', json={
    "location": {"lat": 12.9716, "lng": 77.5946},
    "condition": "TEST: Heart attack",
    "severity": "high"
}, headers={"Authorization": f"Bearer {client_token}"})

if resp.status_code in (200,201):
    data = resp.get_json()
    request_id = data.get('request_id') or data.get('id') or (data.get('data') and data['data'].get('request_id'))
    print(f"   ✅ SOS triggered: {request_id}")
else:
    print(f"   ❌ SOS failed: {resp.status_code} - {resp.get_data(as_text=True)}")
    raise SystemExit(1)

# Step 3: Login as driver
print("\n🚗 Step 3: Login as driver...")
resp = client.post('/api/login/driver', json={
    "driver_id": "drive123",
    "password": "drive@123"
})
if resp.status_code == 200:
    data = resp.get_json()
    driver_token = data['token']
    driver_id = data['user_id']
    print(f"   ✅ Driver logged in: {driver_id}")
else:
    print(f"   ❌ Driver login failed: {resp.status_code} - {resp.get_data(as_text=True)}")
    raise SystemExit(1)

# Step 4: Driver updates location
print("\n📍 Step 4: Driver updates location...")
resp = client.post('/api/driver/update_location', json={
    "latitude": 12.9716,
    "longitude": 77.5946
}, headers={"Authorization": f"Bearer {driver_token}"})
print(f"   Location update: {resp.status_code}")

# Step 5: Driver accepts request
print("\n✅ Step 5: Driver accepts SOS request...")
resp = client.post('/api/driver/accept_request', json={"request_id": request_id}, headers={"Authorization": f"Bearer {driver_token}"})
if resp.status_code == 200:
    print(f"   ✅ Driver accepted request!")
else:
    print(f"   ❌ Accept failed: {resp.status_code} - {resp.get_data(as_text=True)}")
    raise SystemExit(1)

# Step 6: Driver submits assessment
print("\n🩺 Step 6: Driver submits injury assessment...")
resp = client.post('/api/driver/submit_assessment', json={
    "request_id": request_id,
    "injury_risk": "high",
    "injury_notes": "TEST: Severe chest pain, suspected cardiac arrest"
}, headers={"Authorization": f"Bearer {driver_token}"})
if resp.status_code == 200:
    print(f"   ✅ Assessment submitted!")
else:
    print(f"   ❌ Assessment failed: {resp.status_code} - {resp.get_data(as_text=True)}")
    raise SystemExit(1)

# Step 7: Login as hospital admin
print("\n🏥 Step 7: Login as hospital admin...")
resp = client.post('/api/login/admin', json={
    "hospital_code": "hospital1",
    "password": "hospital@1"
})
if resp.status_code == 200:
    data = resp.get_json()
    hospital_token = data['token']
    hospital_id = data['user_id']
    print(f"   ✅ Hospital admin logged in: {hospital_id}")
else:
    print(f"   ❌ Hospital login failed: {resp.status_code} - {resp.get_data(as_text=True)}")
    raise SystemExit(1)

# Step 8: Check hospital dashboard
print("\n📊 Step 8: Checking hospital patient requests...")
resp = client.get('/api/hospital/patient_requests', headers={"Authorization": f"Bearer {hospital_token}"})
if resp.status_code == 200:
    data = resp.get_json()
    patient_requests = data.get('requests') or data.get('data') or []
    print(f"   ✅ Hospital endpoint working!")
    print(f"   Total requests: {len(patient_requests)}")
    our_request = None
    for req in patient_requests:
        if req.get('_id') == request_id:
            our_request = req
            break
    if our_request:
        print(f"\n   🎉 SUCCESS! Test request found in hospital dashboard:")
        print(f"      Request ID: {our_request.get('_id')}")
        print(f"      Patient: {our_request.get('user_name')}")
        print(f"      Driver: {our_request.get('driver_name')}")
        print(f"      Vehicle: {our_request.get('vehicle')}")
        print(f"      Injury Risk: {our_request.get('injury_risk')}")
        print(f"      Status: {our_request.get('status')}")
        print(f"      Driver Location: {our_request.get('driver_current_location')}")
    else:
        print(f"\n   ⚠️ Test request NOT found in hospital dashboard")
        print(f"   Looking for request_id: {request_id}")
        print(f"   Available requests: {[r.get('_id') for r in patient_requests]}")
else:
    print(f"   ❌ Hospital requests failed: {resp.status_code} - {resp.get_data(as_text=True)}")
    raise SystemExit(1)

print("\n" + "="*70)
print("TEST COMPLETE!")
print("="*70 + "\n")
