# Real-Time Map Tracking Architecture: Deccan-Aid

Deccan-Aid features an advanced real-time geospatial tracking integration to allow the citizen to monitor the assigned ambulance's approach.

## How It Works

### 1. The Location Service (Flutter)
The ambulance app utilizes the `geolocator` package. A background worker periodically queries the native OS for the high-accuracy GPS position.

```dart
// Location broadcast interval is 5 seconds
Timer.periodic(Duration(seconds: 5), (timer) async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );
    _pushLocationToServer(position.latitude, position.longitude);
});
```

### 2. The Relay (FastAPI to Socket.IO)
When the driver's device pushes the location using the `POST /api/driver/update_location` endpoint, the FastAPI backend does two things:
1. Updates the `ambulance_drivers` collection with the new standard GeoJSON Point.
2. Emits a WebSocket payload to any client watching the `[patient_room]`.

### 3. Rendering the Update (Flutter Google Maps)
On the Citizen Dashboard, the `google_maps_flutter` package is used to render the ambulance marker.

When the Socket.IO client in the patient app receives the `driver_location_update` event:
1. The LatLng state is updated.
2. The UI rebuilds the map.
3. The `Marker` widget instance is relocated. If `google_maps_flutter` detects coordinate changes for an existing marker ID, it natively animates the pin dropping to the new location smoothly, avoiding jumpy visual artifacts.

### 4. ETA & Distance Calculation
To calculate ETA, we use the Haversine formula (or the Google Maps Directions API, if an API key is provided) to get the distance between the patient's stationary pin and the driver's moving pin. 

Distance is converted to ETA using basic speed assumptions (e.g., urban average 40km/h) combined with traffic factors.
