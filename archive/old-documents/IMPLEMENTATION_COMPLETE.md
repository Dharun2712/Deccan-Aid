# Complete Implementation Details: Deccan-Aid

This document covers the intricate implementation logic behind Deccan-Aid's core features.

## 1. AI Accident Detection Logic

The accident detection model resides within the Flutter application in `lib/services/accident_detector_service.dart`. It uses a heuristic-based sensor fusion algorithm to detect potential crashes.

### Sensor Utilization
The system continuously listens to the device's **Accelerometer** (measuring linear forces) and **Gyroscope** (measuring angular rotation).

```dart
// Conceptual snippet of sensor monitoring
accelerometerEvents.listen((AccelerometerEvent event) {
  _processAccelerometerData(event);
});
gyroscopeEvents.listen((GyroscopeEvent event) {
  _processGyroscopeData(event);
});
```

### The Algorithm
1. **Data Buffering:** The service keeps a rolling buffer of the last 2 seconds of sensor data.
2. **Threshold Calculation:** It calculates the magnitude of the vectors:
   - `accel_magnitude = sqrt(x^2 + y^2 + z^2)`
   - `gyro_magnitude = sqrt(x^2 + y^2 + z^2)`
3. **Trigger:** If `accel_magnitude` exceeds `25.0 m/s^2` OR `gyro_magnitude` exceeds `5.0 rad/s`, an accident event is suspected.
4. **Severity Classification:**
   - **HIGH:** `accel > 40` OR `gyro > 8`
   - **MEDIUM:** `accel > 30` OR `gyro > 6`
   - **LOW:** Detection above baseline threshold but below medium.

### Auto-SOS Cooldown
To prevent spamming the backend during a tumbling event, once an Auto-SOS is triggered, the sensor service implements a strict 5-second cooldown via a boolean flag `_isCooldownActive`, during which subsequent triggers are ignored.

## 2. Geospatial Dispatch System

The backend matches patients with the nearest available ambulance using MongoDB's `$near` geospatial queries.

### Database Index
The `ambulance_drivers` collection uses a `2dsphere` index on the `location` field.

```json
{
  "location": {
    "type": "Point",
    "coordinates": [77.5946, 12.9716] 
  }
}
```

### The Dispatch Query
When a patient triggers an SOS, the backend performs the following query in FastAPI:

```python
async def find_nearby_ambulances(db, lng, lat, max_distance_meters=20000):
    query = {
        "status": "available",
        "location": {
            "$near": {
                "$geometry": {
                    "type": "Point",
                    "coordinates": [lng, lat]
                },
                "$maxDistance": max_distance_meters
            }
        }
    }
    return await db.ambulance_drivers.find(query).to_list(length=10)
```

This returns a list of up to 10 available drivers within a 20km radius, sorted directly by MongoDB from nearest to furthest.

## 3. Real-Time Communication (Socket.IO)

Deccan-Aid relies on Socket.IO for pushing instant updates rather than relying on inefficient HTTP polling.

### Room Architecture
When users connect via WebSocket, they are placed in specific "rooms" based on their role and ID:
- **`clients` room:** Used for system-wide broadcasts to patients.
- **`drivers` room:** Used to instantly broadcast new SOS requests to all active drivers.
- **`[user_id]` room:** A private room for the specific user to receive targeted events (e.g., driver acceptance confirmation).

### Event Lifecycle for SOS Acceptance
1. **Patient:** Triggers HTTP POST `/api/client/sos`.
2. **FastAPI Backend:** Saves request to DB, then uses Socket.IO to `emit('sos_alert', data)` to the `drivers` room.
3. **Driver(s):** Receive the `sos_alert`. Driver A presses "Accept".
4. **Driver A:** Triggers HTTP POST `/api/driver/accept_request`.
5. **FastAPI Backend:** Updates DB. Emits `driver_accepted` event directly to the `[patient_id]` room.
6. **Patient App:** UI updates instantly to show the assigned driver's details and active tracking view.
