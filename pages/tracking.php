<?php
/**
 * Live Tracking Page - Interactive Map with Leaflet.js
 * Chennai Region - Near Saveetha University
 * Shows: Accidents, Ambulances, Hospitals
 */
require_once __DIR__ . '/../config.php';

$drivers = getDummyDrivers();
$hospitals = getDummyHospitals();
$requests = getDummyRequests();

// Get active accidents (pending/in-progress requests)
$accidents = array_filter($requests, fn($r) => in_array($r['status'], ['pending', 'accepted', 'in_progress']));

// Prepare data for JavaScript
$mapDrivers = array_map(function($d, $index) {
    return [
        'id' => $d['id'] ?? 'driver_' . $index,
        'name' => $d['name'] ?? 'Unknown Driver',
        'vehicle' => $d['vehicle_number'] ?? '',
        'phone' => $d['phone'] ?? '',
        'status' => $d['status'] ?? 'offline',
        'lat' => $d['current_location']['lat'] ?? (13.0674 + (rand(-50, 50) / 1000)),
        'lng' => $d['current_location']['lng'] ?? (80.1452 + (rand(-50, 50) / 1000)),
    ];
}, $drivers, array_keys($drivers));

$mapHospitals = array_map(function($h, $index) {
    return [
        'id' => $h['id'] ?? 'hospital_' . $index,
        'name' => $h['name'] ?? 'Unknown Hospital',
        'type' => $h['type'] ?? 'General',
        'address' => $h['address'] ?? '',
        'phone' => $h['phone'] ?? '',
        'lat' => $h['location']['lat'] ?? (13.0674 + (rand(-40, 40) / 1000)),
        'lng' => $h['location']['lng'] ?? (80.1452 + (rand(-40, 40) / 1000)),
        'beds_available' => $h['beds_available'] ?? rand(5, 30),
    ];
}, $hospitals, array_keys($hospitals));

$mapAccidents = array_map(function($a, $index) {
    return [
        'id' => $a['id'] ?? 'accident_' . $index,
        'user_name' => $a['user_name'] ?? 'Unknown',
        'emergency_type' => $a['emergency_type'] ?? 'Emergency',
        'severity' => $a['severity'] ?? 'medium',
        'status' => $a['status'] ?? 'pending',
        'phone' => $a['user_phone'] ?? '',
        'lat' => $a['location']['lat'] ?? (13.0674 + (rand(-30, 30) / 1000)),
        'lng' => $a['location']['lng'] ?? (80.1452 + (rand(-30, 30) / 1000)),
        'location_name' => $a['location']['name'] ?? ($a['pickup_location'] ?? 'Chennai'),
        'created_at' => $a['created_at'] ?? date('Y-m-d H:i:s'),
    ];
}, $accidents, array_keys($accidents));
?>

<div class="space-y-6">
  <!-- Page Header -->
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-white">Live Tracking</h1>
      <p class="text-slate-400 text-sm mt-1">
        <svg class="w-4 h-4 inline-block mr-1 text-red-400" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>
        </svg>
        Interactive Map - Chennai District • Saveetha University Area
      </p>
    </div>
    <div class="flex items-center gap-3">
      <span class="flex items-center gap-2 px-3 py-1.5 bg-emerald-500/20 text-emerald-400 rounded-lg text-xs font-medium">
        <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
        Live Updates
      </span>
      <button onclick="resetMapView()" class="btn-secondary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12a9 9 0 0118 0 9 9 0 01-18 0m9-9v3m0 12v3m9-9h-3M6 12H3" />
        </svg>
        Reset View
      </button>
      <button onclick="location.reload()" class="btn-primary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
        </svg>
        Refresh
      </button>
    </div>
  </div>

  <!-- Map Stats -->
  <div class="grid grid-cols-1 sm:grid-cols-4 gap-4">
    <div class="metric-card border-l-4 border-red-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-red-500/20 rounded-xl">
          <svg class="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">Active Accidents</p>
          <p class="text-2xl font-bold text-red-400"><?= count($accidents) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-cyan-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-cyan-500/20 rounded-xl">
          <svg class="w-6 h-6 text-cyan-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">Ambulances</p>
          <p class="text-2xl font-bold text-cyan-400"><?= count($drivers) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-emerald-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-emerald-500/20 rounded-xl">
          <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">Hospitals</p>
          <p class="text-2xl font-bold text-emerald-400"><?= count($hospitals) ?></p>
        </div>
      </div>
    </div>
    <div class="metric-card border-l-4 border-indigo-500">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-indigo-500/20 rounded-xl">
          <svg class="w-6 h-6 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          </svg>
        </div>
        <div>
          <p class="text-slate-400 text-xs uppercase tracking-wide">Coverage</p>
          <p class="text-2xl font-bold text-indigo-400">15<span class="text-sm">km</span></p>
        </div>
      </div>
    </div>
  </div>

  <!-- Interactive Map -->
  <div class="control-card p-0 overflow-hidden">
    <div class="p-4 border-b border-slate-700/50 flex items-center justify-between">
      <div>
        <h3 class="text-lg font-semibold text-white">Interactive Map</h3>
        <p class="text-sm text-slate-400">Click on markers for details • Zoom and pan to explore</p>
      </div>
      <!-- Map Legend -->
      <div class="flex items-center gap-4 text-xs">
        <div class="flex items-center gap-2">
          <span class="w-4 h-4 bg-red-500 rounded-full flex items-center justify-center text-white text-[8px]">⚠</span>
          <span class="text-slate-400">Accidents</span>
        </div>
        <div class="flex items-center gap-2">
          <span class="w-4 h-4 bg-cyan-500 rounded-full flex items-center justify-center text-white text-[8px]">🚑</span>
          <span class="text-slate-400">Ambulances</span>
        </div>
        <div class="flex items-center gap-2">
          <span class="w-4 h-4 bg-emerald-500 rounded-full flex items-center justify-center text-white text-[8px]">🏥</span>
          <span class="text-slate-400">Hospitals</span>
        </div>
      </div>
    </div>
    
    <!-- Leaflet Map Container -->
    <div id="trackingMap" style="height: 550px; width: 100%; z-index: 1;"></div>
  </div>

  <!-- Quick Info Panels -->
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Active Accidents List -->
    <div class="control-card">
      <h3 class="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        <span class="w-3 h-3 bg-red-500 rounded-full animate-pulse"></span>
        Active Emergencies
      </h3>
      <div class="space-y-3 max-h-64 overflow-y-auto custom-scrollbar">
        <?php foreach (array_slice($mapAccidents, 0, 5) as $accident): 
          $severityColors = ['critical' => 'red', 'high' => 'amber', 'medium' => 'cyan', 'low' => 'emerald'];
          $color = $severityColors[$accident['severity']] ?? 'cyan';
        ?>
        <div class="p-3 bg-slate-800/50 rounded-lg border border-<?= $color ?>-500/30 hover:border-<?= $color ?>-500/50 transition cursor-pointer" onclick="focusMarker('accident', '<?= $accident['id'] ?>')">
          <div class="flex items-center gap-3">
            <div class="status-indicator <?= $accident['severity'] ?>"></div>
            <div class="flex-1 min-w-0">
              <p class="text-white text-sm font-medium truncate"><?= htmlspecialchars($accident['user_name']) ?></p>
              <p class="text-slate-500 text-xs"><?= htmlspecialchars($accident['emergency_type']) ?></p>
            </div>
            <span class="status-badge <?= $accident['severity'] ?> text-[10px]"><?= ucfirst($accident['severity']) ?></span>
          </div>
        </div>
        <?php endforeach; ?>
      </div>
    </div>

    <!-- Ambulances List -->
    <div class="control-card">
      <h3 class="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        <span class="w-3 h-3 bg-cyan-500 rounded-full"></span>
        Ambulances on Map
      </h3>
      <div class="space-y-3 max-h-64 overflow-y-auto custom-scrollbar">
        <?php foreach (array_slice($mapDrivers, 0, 5) as $driver): ?>
        <div class="p-3 bg-slate-800/50 rounded-lg hover:bg-slate-800/80 transition cursor-pointer" onclick="focusMarker('ambulance', '<?= $driver['id'] ?>')">
          <div class="flex items-center gap-3">
            <div class="status-indicator <?= $driver['status'] ?>"></div>
            <div class="flex-1 min-w-0">
              <p class="text-white text-sm font-medium truncate"><?= htmlspecialchars($driver['name']) ?></p>
              <p class="text-slate-500 text-xs"><?= htmlspecialchars($driver['vehicle']) ?></p>
            </div>
            <span class="status-badge <?= $driver['status'] ?> text-[10px]"><?= ucfirst($driver['status']) ?></span>
          </div>
        </div>
        <?php endforeach; ?>
      </div>
    </div>

    <!-- Hospitals List -->
    <div class="control-card">
      <h3 class="text-lg font-semibold text-white mb-4 flex items-center gap-2">
        <span class="w-3 h-3 bg-emerald-500 rounded-full"></span>
        Nearby Hospitals
      </h3>
      <div class="space-y-3 max-h-64 overflow-y-auto custom-scrollbar">
        <?php foreach (array_slice($mapHospitals, 0, 5) as $hospital): ?>
        <div class="p-3 bg-slate-800/50 rounded-lg hover:bg-slate-800/80 transition cursor-pointer" onclick="focusMarker('hospital', '<?= $hospital['id'] ?>')">
          <div class="flex items-center gap-3">
            <div class="p-2 bg-emerald-500/20 rounded-lg">
              <svg class="w-4 h-4 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-white text-sm font-medium truncate"><?= htmlspecialchars($hospital['name']) ?></p>
              <p class="text-slate-500 text-xs"><?= $hospital['beds_available'] ?> beds available</p>
            </div>
          </div>
        </div>
        <?php endforeach; ?>
      </div>
    </div>
  </div>
</div>

<style>
/* Custom Leaflet Styles */
.leaflet-container {
  background: #0f172a;
  font-family: 'Poppins', sans-serif;
}
.leaflet-popup-content-wrapper {
  background: linear-gradient(135deg, rgba(15,23,42,0.95) 0%, rgba(30,41,59,0.95) 100%);
  border: 1px solid rgba(148,163,184,0.2);
  border-radius: 12px;
  box-shadow: 0 20px 40px rgba(0,0,0,0.5);
}
.leaflet-popup-content {
  color: #e2e8f0;
  margin: 12px 16px;
}
.leaflet-popup-tip {
  background: rgba(30,41,59,0.95);
  border: 1px solid rgba(148,163,184,0.2);
}
.leaflet-control-zoom a {
  background: rgba(15,23,42,0.9) !important;
  color: #e2e8f0 !important;
  border-color: rgba(148,163,184,0.2) !important;
}
.leaflet-control-zoom a:hover {
  background: rgba(99,102,241,0.3) !important;
}

/* Custom Marker Styles */
.accident-marker {
  background: linear-gradient(135deg, #ef4444, #dc2626);
  border: 3px solid #fff;
  border-radius: 50%;
  box-shadow: 0 0 20px rgba(239,68,68,0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 14px;
  animation: pulse-marker 2s infinite;
}
.ambulance-marker {
  background: linear-gradient(135deg, #06b6d4, #0891b2);
  border: 3px solid #fff;
  border-radius: 50%;
  box-shadow: 0 0 15px rgba(6,182,212,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 14px;
}
.ambulance-marker.available {
  background: linear-gradient(135deg, #10b981, #059669);
  box-shadow: 0 0 15px rgba(16,185,129,0.5);
}
.ambulance-marker.busy {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  box-shadow: 0 0 15px rgba(245,158,11,0.5);
}
.hospital-marker {
  background: linear-gradient(135deg, #10b981, #059669);
  border: 3px solid #fff;
  border-radius: 8px;
  box-shadow: 0 0 15px rgba(16,185,129,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 14px;
}
.kec-marker {
  background: linear-gradient(135deg, #6366f1, #8b5cf6);
  border: 3px solid #fff;
  border-radius: 50%;
  box-shadow: 0 0 25px rgba(99,102,241,0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 16px;
}

@keyframes pulse-marker {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

/* Popup Styles */
.popup-header {
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 8px;
  padding-bottom: 8px;
  border-bottom: 1px solid rgba(148,163,184,0.2);
}
.popup-row {
  display: flex;
  justify-content: space-between;
  margin: 4px 0;
  font-size: 12px;
}
.popup-label {
  color: #94a3b8;
}
.popup-value {
  color: #e2e8f0;
  font-weight: 500;
}
.popup-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
}
.popup-badge.critical { background: rgba(239,68,68,0.2); color: #f87171; }
.popup-badge.high { background: rgba(245,158,11,0.2); color: #fbbf24; }
.popup-badge.medium { background: rgba(6,182,212,0.2); color: #22d3ee; }
.popup-badge.low { background: rgba(16,185,129,0.2); color: #34d399; }
.popup-badge.available { background: rgba(16,185,129,0.2); color: #34d399; }
.popup-badge.busy { background: rgba(245,158,11,0.2); color: #fbbf24; }
.popup-badge.offline { background: rgba(100,116,139,0.2); color: #94a3b8; }
</style>

<script>
// Map Data from PHP
const mapData = {
  drivers: <?= json_encode(array_values($mapDrivers)) ?>,
  hospitals: <?= json_encode(array_values($mapHospitals)) ?>,
  accidents: <?= json_encode(array_values($mapAccidents)) ?>,
  center: { lat: 13.0674, lng: 80.1452 } // Saveetha University, Chennai
};

// Marker storage for focus functionality
const markers = {
  accident: {},
  ambulance: {},
  hospital: {}
};

// Initialize Map
let map;

document.addEventListener('DOMContentLoaded', function() {
  initMap();
});

function initMap() {
  // Create map centered on Saveetha University, Chennai
  map = L.map('trackingMap', {
    center: [mapData.center.lat, mapData.center.lng],
    zoom: 13,
    zoomControl: true,
    scrollWheelZoom: true
  });

  // Add dark theme tile layer
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
    subdomains: 'abcd',
    maxZoom: 19
  }).addTo(map);

  // Add Saveetha University Center Marker
  const kecIcon = L.divIcon({
    className: 'custom-marker',
    html: '<div class="kec-marker" style="width:40px;height:40px;">🎓</div>',
    iconSize: [40, 40],
    iconAnchor: [20, 20],
    popupAnchor: [0, -20]
  });

  L.marker([mapData.center.lat, mapData.center.lng], { icon: kecIcon })
    .addTo(map)
    .bindPopup(`
      <div class="popup-header" style="color:#a5b4fc;">📍 Saveetha University</div>
      <div class="popup-row"><span class="popup-label">Location:</span><span class="popup-value">Thandalam, Chennai</span></div>
      <div class="popup-row"><span class="popup-label">Coordinates:</span><span class="popup-value">13.0674° N, 80.1452° E</span></div>
      <div class="popup-row"><span class="popup-label">Coverage:</span><span class="popup-value">15 km radius</span></div>
    `);

  // Add Accident Markers
  mapData.accidents.forEach(accident => {
    const severityColors = {
      critical: '#ef4444',
      high: '#f59e0b',
      medium: '#06b6d4',
      low: '#10b981'
    };

    const accidentIcon = L.divIcon({
      className: 'custom-marker',
      html: `<div class="accident-marker" style="width:36px;height:36px;">⚠️</div>`,
      iconSize: [36, 36],
      iconAnchor: [18, 18],
      popupAnchor: [0, -18]
    });

    const marker = L.marker([accident.lat, accident.lng], { icon: accidentIcon })
      .addTo(map)
      .bindPopup(`
        <div class="popup-header" style="color:#f87171;">🚨 Emergency Alert</div>
        <div class="popup-row"><span class="popup-label">Patient:</span><span class="popup-value">${accident.user_name}</span></div>
        <div class="popup-row"><span class="popup-label">Type:</span><span class="popup-value">${accident.emergency_type}</span></div>
        <div class="popup-row"><span class="popup-label">Location:</span><span class="popup-value">${accident.location_name}</span></div>
        <div class="popup-row"><span class="popup-label">Severity:</span><span class="popup-badge ${accident.severity}">${accident.severity}</span></div>
        <div class="popup-row"><span class="popup-label">Status:</span><span class="popup-value">${accident.status}</span></div>
        <div class="popup-row"><span class="popup-label">Contact:</span><span class="popup-value">${accident.phone}</span></div>
      `);
    
    markers.accident[accident.id] = marker;
  });

  // Add Ambulance Markers
  mapData.drivers.forEach(driver => {
    const statusClass = driver.status === 'available' ? 'available' : (driver.status === 'busy' ? 'busy' : '');
    
    const ambulanceIcon = L.divIcon({
      className: 'custom-marker',
      html: `<div class="ambulance-marker ${statusClass}" style="width:36px;height:36px;">🚑</div>`,
      iconSize: [36, 36],
      iconAnchor: [18, 18],
      popupAnchor: [0, -18]
    });

    const marker = L.marker([driver.lat, driver.lng], { icon: ambulanceIcon })
      .addTo(map)
      .bindPopup(`
        <div class="popup-header" style="color:#22d3ee;">🚑 Ambulance</div>
        <div class="popup-row"><span class="popup-label">Driver:</span><span class="popup-value">${driver.name}</span></div>
        <div class="popup-row"><span class="popup-label">Vehicle:</span><span class="popup-value">${driver.vehicle}</span></div>
        <div class="popup-row"><span class="popup-label">Status:</span><span class="popup-badge ${driver.status}">${driver.status}</span></div>
        <div class="popup-row"><span class="popup-label">Contact:</span><span class="popup-value">${driver.phone}</span></div>
      `);
    
    markers.ambulance[driver.id] = marker;
  });

  // Add Hospital Markers
  mapData.hospitals.forEach(hospital => {
    const hospitalIcon = L.divIcon({
      className: 'custom-marker',
      html: '<div class="hospital-marker" style="width:36px;height:36px;">🏥</div>',
      iconSize: [36, 36],
      iconAnchor: [18, 18],
      popupAnchor: [0, -18]
    });

    const marker = L.marker([hospital.lat, hospital.lng], { icon: hospitalIcon })
      .addTo(map)
      .bindPopup(`
        <div class="popup-header" style="color:#34d399;">🏥 ${hospital.name}</div>
        <div class="popup-row"><span class="popup-label">Type:</span><span class="popup-value">${hospital.type}</span></div>
        <div class="popup-row"><span class="popup-label">Beds Available:</span><span class="popup-value" style="color:#34d399;">${hospital.beds_available}</span></div>
        <div class="popup-row"><span class="popup-label">Contact:</span><span class="popup-value">${hospital.phone}</span></div>
      `);
    
    markers.hospital[hospital.id] = marker;
  });

  // Add coverage circle around KEC
  L.circle([mapData.center.lat, mapData.center.lng], {
    color: '#6366f1',
    fillColor: '#6366f1',
    fillOpacity: 0.05,
    radius: 15000, // 15km radius
    weight: 2,
    dashArray: '10, 10'
  }).addTo(map);
}

// Focus on specific marker
function focusMarker(type, id) {
  const marker = markers[type][id];
  if (marker) {
    map.setView(marker.getLatLng(), 15, { animate: true });
    marker.openPopup();
  }
}

// Reset map view to center
function resetMapView() {
  if (map) {
    map.setView([mapData.center.lat, mapData.center.lng], 13, { animate: true });
  }
}

// Simulate real-time updates (optional - moves ambulance markers slightly)
setInterval(() => {
  Object.keys(markers.ambulance).forEach(id => {
    const marker = markers.ambulance[id];
    const currentPos = marker.getLatLng();
    const newLat = currentPos.lat + (Math.random() - 0.5) * 0.001;
    const newLng = currentPos.lng + (Math.random() - 0.5) * 0.001;
    marker.setLatLng([newLat, newLng]);
  });
}, 5000);
</script>
