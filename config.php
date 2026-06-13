<?php
/**
 * Smart Ambulance System - Configuration
 * Reva University Bangalore - Reva University Bangalore
 */

/**
 * Minimal dotenv loader for local XAMPP usage.
 * Loads key=value pairs from .env into process env/$_ENV/$_SERVER.
 */
function loadLocalEnv(string $filePath): void {
    if (!file_exists($filePath) || !is_readable($filePath)) {
        return;
    }

    $lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if (!is_array($lines)) {
        return;
    }

    foreach ($lines as $line) {
        $line = trim((string) $line);
        if ($line === '' || str_starts_with($line, '#')) {
            continue;
        }

        $parts = explode('=', $line, 2);
        if (count($parts) !== 2) {
            continue;
        }

        $name = trim($parts[0]);
        $value = trim($parts[1]);
        if ($name === '') {
            continue;
        }

        // Remove wrapping quotes if present.
        if (
            strlen($value) >= 2 &&
            (($value[0] === '"' && $value[strlen($value) - 1] === '"') || ($value[0] === "'" && $value[strlen($value) - 1] === "'"))
        ) {
            $value = substr($value, 1, -1);
        }

        putenv($name . '=' . $value);
        $_ENV[$name] = $value;
        $_SERVER[$name] = $value;
    }
}

loadLocalEnv(__DIR__ . DIRECTORY_SEPARATOR . '.env');

// =====================================
// MONGODB ATLAS CONFIGURATION
// =====================================
$mongoUri = getenv('MONGODB_URI') ?: (getenv('MONGO_URI') ?: '');
$mongoDbName = getenv('MONGODB_DB') ?: 'smart_ambulance';
define('MONGODB_URI', $mongoUri);
define('MONGODB_DB', $mongoDbName);

/**
 * Get a MongoDB Atlas database connection.
 * Returns null if connection fails (fallback to dummy data).
 */
function getMongoDb(): ?\MongoDB\Database {
    static $db = null;
    if ($db !== null) return $db;
    if (MONGODB_URI === '') return null;
    try {
        $vendorAutoload = __DIR__ . '/vendor/autoload.php';
        if (!file_exists($vendorAutoload)) return null;
        require_once $vendorAutoload;
        $client = new \MongoDB\Client(MONGODB_URI, [
            'connectTimeoutMS'       => 5000,
            'socketTimeoutMS'        => 15000,
            'serverSelectionTimeoutMS' => 5000,
        ]);
        $db = $client->selectDatabase(MONGODB_DB);
        return $db;
    } catch (\Exception $e) {
        return null;
    }
}

/**
 * Decode JSON output from Python bridge command.
 * Handles occasional extra logs by extracting the JSON payload.
 */
function decodePythonBridgeOutput(string $output): ?array {
    $output = trim($output);
    if ($output === '') return null;

    $decoded = json_decode($output, true);
    if (is_array($decoded)) return $decoded;

    $firstBrace = strpos($output, '{');
    $lastBrace = strrpos($output, '}');
    if ($firstBrace === false || $lastBrace === false || $lastBrace <= $firstBrace) {
        return null;
    }

    $jsonChunk = substr($output, $firstBrace, $lastBrace - $firstBrace + 1);
    $decoded = json_decode($jsonChunk, true);
    return is_array($decoded) ? $decoded : null;
}

/**
 * Execute Python bridge script to fetch live dashboard data.
 */
function runPythonDashboardBridge(): ?array {
    $scriptPath = __DIR__ . DIRECTORY_SEPARATOR . 'fetch_mongo.py';
    if (!file_exists($scriptPath)) return null;
    if (!function_exists('shell_exec')) return null;

    $commands = [];
    $envPython = trim((string) (getenv('PYTHON_EXECUTABLE') ?: ''));
    if ($envPython !== '') {
        $commands[] = escapeshellarg($envPython) . ' ' . escapeshellarg($scriptPath);
    }
    $commands[] = 'python ' . escapeshellarg($scriptPath);
    $commands[] = 'py -3 ' . escapeshellarg($scriptPath);
    $commands = array_values(array_unique($commands));

    foreach ($commands as $command) {
        $raw = shell_exec($command . ' 2>&1');
        if (!is_string($raw) || trim($raw) === '') continue;

        $decoded = decodePythonBridgeOutput($raw);
        if (!is_array($decoded)) continue;
        if (!empty($decoded['error'])) continue;

        return $decoded;
    }

    return null;
}

/**
 * Cached live dashboard payload from Python bridge.
 */
function getLiveDashboardData(): ?array {
    static $loaded = false;
    static $cache = null;

    if ($loaded) return $cache;

    $loaded = true;
    $cache = runPythonDashboardBridge();
    return $cache;
}

/**
 * Shared list of request statuses considered active in dashboard metrics.
 */
function getActiveRequestStatuses(): array {
    return [
        'pending',
        'accepted',
        'assigned',
        'in_progress',
        'en_route',
        'arrived',
        'picked_up',
        'detected',
        'admitted',
        'assessed',
        'accepted_by_hospital',
    ];
}

/**
 * Filter helper for endpoint query params.
 */
function filterByQueryField(array $items, string $field, ?string $value): array {
    $needle = strtolower(trim((string) ($value ?? '')));
    if ($needle === '' || $needle === 'all') return array_values($items);

    return array_values(array_filter($items, function ($item) use ($field, $needle) {
        return strtolower((string) ($item[$field] ?? '')) === $needle;
    }));
}

/**
 * Build stats object from live payload with safe defaults.
 */
function buildLiveStats(array $liveData): array {
    $requests = is_array($liveData['requests'] ?? null) ? $liveData['requests'] : [];
    $drivers = is_array($liveData['drivers'] ?? null) ? $liveData['drivers'] : [];
    $hospitals = is_array($liveData['hospitals'] ?? null) ? $liveData['hospitals'] : [];
    $users = is_array($liveData['users'] ?? null) ? $liveData['users'] : [];
    $activeStatuses = getActiveRequestStatuses();

    $activeRequests = array_values(array_filter($requests, fn($r) => in_array(strtolower((string) ($r['status'] ?? 'pending')), $activeStatuses, true)));
    $completedRequests = array_values(array_filter($requests, fn($r) => strtolower((string) ($r['status'] ?? '')) === 'completed'));
    $criticalRequests = array_values(array_filter($activeRequests, fn($r) => strtolower((string) ($r['severity'] ?? 'medium')) === 'critical'));
    $availableDrivers = array_values(array_filter($drivers, fn($d) => strtolower((string) ($d['status'] ?? 'offline')) === 'available'));
    $busyDrivers = array_values(array_filter($drivers, fn($d) => strtolower((string) ($d['status'] ?? 'offline')) === 'busy'));
    $totalPatients = array_values(array_filter($users, fn($u) => strtolower((string) ($u['role'] ?? 'user')) === 'user'));

    $totalRequests = count($requests);
    $successRate = $totalRequests > 0 ? round((count($completedRequests) / $totalRequests) * 100, 1) : 98.5;

    $defaults = [
        'total_requests' => $totalRequests,
        'active_requests' => count($activeRequests),
        'completed_requests' => count($completedRequests),
        'critical_requests' => count($criticalRequests),
        'available_drivers' => count($availableDrivers),
        'total_drivers' => count($drivers),
        'busy_drivers' => count($busyDrivers),
        'total_hospitals' => count($hospitals),
        'total_users' => count($users),
        'total_patients' => count($totalPatients),
        'avg_response_time' => '4.2',
        'success_rate' => $successRate,
        'region' => 'Reva University Bangalore',
        'center' => 'Reva University Bangalore'
    ];

    $liveStats = is_array($liveData['stats'] ?? null) ? $liveData['stats'] : [];
    return array_merge($defaults, $liveStats);
}

/**
 * Alerts fallback using the Python bridge payload.
 */
function getAlertsFromPythonBridge(): array {
    $liveData = getLiveDashboardData();
    if (!is_array($liveData)) return [];

    $requests = is_array($liveData['requests'] ?? null) ? $liveData['requests'] : [];
    $activeStatuses = getActiveRequestStatuses();
    $alerts = [];

    foreach ($requests as $request) {
        $status = strtolower((string) ($request['status'] ?? 'pending'));
        if (!in_array($status, $activeStatuses, true)) continue;

        $location = $request['location'] ?? [];
        $alerts[] = [
            '_id' => $request['_id'] ?? ($request['request_id'] ?? uniqid('req_', true)),
            'user_name' => $request['user_name'] ?? 'Unknown',
            'user_phone' => $request['user_phone'] ?? '',
            'emergency_type' => $request['emergency_type'] ?? 'Emergency',
            'severity' => strtolower((string) ($request['severity'] ?? 'medium')),
            'status' => $status,
            'location' => [
                'name' => $location['name'] ?? ($request['pickup_location'] ?? 'Bangalore'),
                'lat' => $location['lat'] ?? ($request['latitude'] ?? null),
                'lng' => $location['lng'] ?? ($request['longitude'] ?? null),
            ],
            'driver_name' => $request['driver_name'] ?? null,
            'hospital_id' => $request['hospital_id'] ?? null,
            'auto_triggered' => stripos((string) ($request['emergency_type'] ?? ''), 'accident') !== false,
            'impact_force' => $request['impact_force'] ?? null,
            'vitals' => $request['vitals'] ?? null,
            'created_at' => $request['created_at'] ?? null,
        ];
    }

    return $alerts;
}

/**
 * Fetch alerts from MongoDB Atlas -> smart_ambulance.patient_requests
 * Maps real fields to the format the alerts UI expects.
 */
function getAlertsFromMongo(): array {
    $db = getMongoDb();
    if ($db === null) return getAlertsFromPythonBridge();
    try {
        // Map severity from preliminary_severity / injury_level
        $severityMap = [
            'critical' => 'critical', 'severe' => 'critical',
            'high' => 'high',
            'medium' => 'medium', 'moderate' => 'medium', 'mid' => 'medium',
            'low' => 'low', 'minor' => 'low',
        ];

        $alerts = [];

        // ---- 1. Patient Requests ----
        $collection = $db->selectCollection('patient_requests');
        $cursor = $collection->find(
            ['status' => ['$in' => ['pending', 'accepted', 'in_progress', 'assigned', 'picked_up', 'detected', 'admitted', 'assessed', 'accepted_by_hospital']]],
            [
                'sort' => ['timestamp' => -1],
                'limit' => 200,
                'typeMap' => ['root' => 'array', 'document' => 'array', 'array' => 'array']
            ]
        );

        foreach ($cursor as $doc) {
            // Normalize ObjectId fields
            foreach (['_id', 'client_id', 'driver_id', 'hospital_id'] as $field) {
                if (isset($doc[$field]) && $doc[$field] instanceof \MongoDB\BSON\ObjectId) {
                    $doc[$field] = (string) $doc[$field];
                }
            }
            // Normalize timestamp — append Z so JS knows it's UTC
            if (isset($doc['timestamp']) && $doc['timestamp'] instanceof \MongoDB\BSON\UTCDateTime) {
                $doc['timestamp'] = $doc['timestamp']->toDateTime()->format('Y-m-d\TH:i:s\Z');
            }
            foreach (['picked_up_at','accepted_at','assigned_at','admission_time'] as $tf) {
                if (isset($doc[$tf]) && $doc[$tf] instanceof \MongoDB\BSON\UTCDateTime) {
                    $doc[$tf] = $doc[$tf]->toDateTime()->format('Y-m-d\TH:i:s\Z');
                }
            }

            // Build location object the UI expects
            $lat = $doc['location']['coordinates'][1] ?? $doc['latitude'] ?? null;
            $lng = $doc['location']['coordinates'][0] ?? $doc['longitude'] ?? null;
            $locationName = '';
            if ($lat && $lng) $locationName = round($lat, 4) . ', ' . round($lng, 4);

            // Map to the UI alert format
            $rawSev = strtolower($doc['preliminary_severity'] ?? $doc['injury_level'] ?? 'medium');
            $alerts[] = [
                '_id'            => $doc['_id'],
                'user_name'      => $doc['user_name'] ?? 'Unknown',
                'user_phone'     => $doc['user_contact'] ?? '',
                'emergency_type' => ucfirst($doc['condition'] ?? 'Emergency'),
                'severity'       => $severityMap[$rawSev] ?? 'medium',
                'status'         => $doc['status'] ?? 'pending',
                'location'       => ['name' => $locationName, 'lat' => $lat, 'lng' => $lng],
                'driver_name'    => $doc['driver_id'] ?? null,
                'hospital_id'    => $doc['hospital_id'] ?? null,
                'auto_triggered' => $doc['auto_triggered'] ?? false,
                'impact_force'   => $doc['sensor_data']['impact_force'] ?? null,
                'vitals'         => $doc['vitals'] ?? null,
                'created_at'     => $doc['timestamp'] ?? null,
            ];
        }

        // ---- 2. Accidents (device-triggered, may not have a patient_request) ----
        $accCursor = $db->selectCollection('accidents')->find(
            ['status' => ['$in' => ['detected', 'pending', 'alerted']]],
            [
                'sort' => ['timestamp' => -1],
                'limit' => 50,
                'typeMap' => ['root' => 'array', 'document' => 'array', 'array' => 'array']
            ]
        );

        // Collect existing patient_request IDs to avoid duplicates
        $existingIds = array_column($alerts, '_id');

        foreach ($accCursor as $acc) {
            $accId = $acc['_id'] instanceof \MongoDB\BSON\ObjectId ? (string) $acc['_id'] : $acc['_id'];
            // Skip if we already have this ID from patient_requests
            if (in_array($accId, $existingIds)) continue;

            if (isset($acc['timestamp']) && $acc['timestamp'] instanceof \MongoDB\BSON\UTCDateTime) {
                $acc['timestamp'] = $acc['timestamp']->toDateTime()->format('Y-m-d\TH:i:s\Z');
            }

            $lat = $acc['location']['coordinates'][1] ?? $acc['latitude'] ?? null;
            $lng = $acc['location']['coordinates'][0] ?? $acc['longitude'] ?? null;
            $locationName = '';
            if ($lat && $lng) $locationName = round($lat, 4) . ', ' . round($lng, 4);

            // Map impact force to severity
            $force = floatval($acc['impact_force'] ?? 0);
            if ($force >= 7) $sev = 'critical';
            elseif ($force >= 4) $sev = 'high';
            elseif ($force >= 1) $sev = 'medium';
            else $sev = 'low';

            $alerts[] = [
                '_id'            => 'acc_' . $accId,
                'user_name'      => 'Bhavanithi (Swift Desire)',
                'user_phone'     => $acc['device_id'] ?? '',
                'emergency_type' => 'Accident Detected (IoT) — Force: ' . ($acc['impact_force'] ?? '?'),
                'severity'       => $sev,
                'status'         => $acc['status'] ?? 'detected',
                'location'       => ['name' => $locationName, 'lat' => $lat, 'lng' => $lng],
                'driver_name'    => null,
                'hospital_id'    => null,
                'auto_triggered' => true,
                'impact_force'   => $acc['impact_force'] ?? null,
                'vitals'         => null,
                'created_at'     => $acc['timestamp'] ?? null,
            ];
        }

        return $alerts;
    } catch (\Exception $e) {
        return getAlertsFromPythonBridge();
    }
}

// API Configuration (Local dummy data - No Azure)
define('API_BASE_URL', '');
define('ADMIN_API_URL', '');

// Reva University Bangalore Coordinates - Reva University Bangalore
define('REGION_CENTER_LAT', 13.1165);
define('REGION_CENTER_LNG', 77.6341);
define('REGION_NAME', 'Reva University Bangalore');

// =====================================
// DUMMY DATA - Reva University Bangalore
// =====================================


// Tamil Names for Users (Below 200 users)
function getDummyUsers() {
    $tamilNames = [
        // Main requested names
        ['name' => 'Arun Kumar', 'phone' => '9876543210', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Sanjeev Rajan', 'phone' => '9876543211', 'role' => 'user', 'area' => 'Kulithalai'],
        ['name' => 'Dharun Prasad', 'phone' => '9876543212', 'role' => 'user', 'area' => 'Krishnarayapuram'],
        ['name' => 'Kishore Balaji', 'phone' => '9876543213', 'role' => 'user', 'area' => 'Pugalur'],
        ['name' => 'Aswanth Vijay', 'phone' => '9876543214', 'role' => 'driver', 'area' => 'Karur Town'],
        
        // More Tamil names - Drivers
        ['name' => 'Karthik Selvam', 'phone' => '9876543215', 'role' => 'driver', 'area' => 'Thogamalai'],
        ['name' => 'Pradeep Kumar', 'phone' => '9876543216', 'role' => 'driver', 'area' => 'Manmangalam'],
        ['name' => 'Vignesh Raja', 'phone' => '9876543217', 'role' => 'driver', 'area' => 'Velur'],
        ['name' => 'Surya Narayanan', 'phone' => '9876543218', 'role' => 'driver', 'area' => 'Aravakurichi'],
        ['name' => 'Dinesh Kannan', 'phone' => '9876543219', 'role' => 'driver', 'area' => 'Kadavur'],
        ['name' => 'Manoj Pandian', 'phone' => '9876543220', 'role' => 'driver', 'area' => 'Pallapatti'],
        ['name' => 'Rajesh Murugan', 'phone' => '9876543221', 'role' => 'driver', 'area' => 'Paramathi'],
        ['name' => 'Ganesh Subramani', 'phone' => '9876543222', 'role' => 'driver', 'area' => 'Karur North'],
        ['name' => 'Senthil Nathan', 'phone' => '9876543223', 'role' => 'driver', 'area' => 'Karur Town'],
        ['name' => 'Bala Murugan', 'phone' => '9876543224', 'role' => 'driver', 'area' => 'Kulithalai'],
        
        // More Tamil names - Users
        ['name' => 'Lakshmi Devi', 'phone' => '9876543225', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Meena Kumari', 'phone' => '9876543226', 'role' => 'user', 'area' => 'Karur Town'],
        ['name' => 'Saranya Priya', 'phone' => '9876543227', 'role' => 'user', 'area' => 'Kulithalai'],
        ['name' => 'Kavitha Sundari', 'phone' => '9876543228', 'role' => 'user', 'area' => 'Krishnarayapuram'],
        ['name' => 'Deepika Rani', 'phone' => '9876543229', 'role' => 'user', 'area' => 'Pugalur'],
        ['name' => 'Revathi Malar', 'phone' => '9876543230', 'role' => 'user', 'area' => 'Thogamalai'],
        ['name' => 'Anitha Lakshmi', 'phone' => '9876543231', 'role' => 'user', 'area' => 'Manmangalam'],
        ['name' => 'Priya Dharshini', 'phone' => '9876543232', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Divya Bharathi', 'phone' => '9876543233', 'role' => 'user', 'area' => 'Kadavur'],
        ['name' => 'Nandhini Selvi', 'phone' => '9876543234', 'role' => 'user', 'area' => 'Pallapatti'],
        ['name' => 'Ramesh Babu', 'phone' => '9876543235', 'role' => 'user', 'area' => 'Paramathi'],
        ['name' => 'Suresh Kumar', 'phone' => '9876543236', 'role' => 'user', 'area' => 'Karur North'],
        ['name' => 'Mohan Raj', 'phone' => '9876543237', 'role' => 'user', 'area' => 'Karur Town'],
        ['name' => 'Vijay Anand', 'phone' => '9876543238', 'role' => 'user', 'area' => 'Kulithalai'],
        ['name' => 'Kumar Samy', 'phone' => '9876543239', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Selvam Raja', 'phone' => '9876543240', 'role' => 'user', 'area' => 'Krishnarayapuram'],
        ['name' => 'Pandian Mani', 'phone' => '9876543241', 'role' => 'user', 'area' => 'Pugalur'],
        ['name' => 'Murugan Vel', 'phone' => '9876543242', 'role' => 'user', 'area' => 'Thogamalai'],
        ['name' => 'Kannan Pillai', 'phone' => '9876543243', 'role' => 'user', 'area' => 'Manmangalam'],
        ['name' => 'Nathan Kumar', 'phone' => '9876543244', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Arjun Prakash', 'phone' => '9876543245', 'role' => 'user', 'area' => 'Kadavur'],
        ['name' => 'Prakash Raj', 'phone' => '9876543246', 'role' => 'user', 'area' => 'Pallapatti'],
        ['name' => 'Ravi Shankar', 'phone' => '9876543247', 'role' => 'user', 'area' => 'Paramathi'],
        ['name' => 'Shankar Ganesh', 'phone' => '9876543248', 'role' => 'user', 'area' => 'Karur North'],
        ['name' => 'Ganesh Kumar', 'phone' => '9876543249', 'role' => 'user', 'area' => 'Karur Town'],
        ['name' => 'Karthikeyan M', 'phone' => '9876543250', 'role' => 'user', 'area' => 'Kulithalai'],
        ['name' => 'Manikandan S', 'phone' => '9876543251', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Saravanan K', 'phone' => '9876543252', 'role' => 'user', 'area' => 'Krishnarayapuram'],
        ['name' => 'Venkatesh R', 'phone' => '9876543253', 'role' => 'user', 'area' => 'Pugalur'],
        ['name' => 'Anand Kumar', 'phone' => '9876543254', 'role' => 'user', 'area' => 'Thogamalai'],
        ['name' => 'Balaji N', 'phone' => '9876543255', 'role' => 'user', 'area' => 'Manmangalam'],
        ['name' => 'Chandran P', 'phone' => '9876543256', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Dhanush K', 'phone' => '9876543257', 'role' => 'user', 'area' => 'Kadavur'],
        ['name' => 'Ezhil Raja', 'phone' => '9876543258', 'role' => 'user', 'area' => 'Pallapatti'],
        ['name' => 'Fathima Bee', 'phone' => '9876543259', 'role' => 'user', 'area' => 'Paramathi'],
        ['name' => 'Gopal Krishnan', 'phone' => '9876543260', 'role' => 'user', 'area' => 'Karur North'],
        ['name' => 'Hari Prasad', 'phone' => '9876543261', 'role' => 'user', 'area' => 'Karur Town'],
        ['name' => 'Ilango M', 'phone' => '9876543262', 'role' => 'user', 'area' => 'Kulithalai'],
        ['name' => 'Jayakumar S', 'phone' => '9876543263', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Kalaivani R', 'phone' => '9876543264', 'role' => 'user', 'area' => 'Krishnarayapuram'],
        ['name' => 'Lalitha M', 'phone' => '9876543265', 'role' => 'user', 'area' => 'Pugalur'],
        ['name' => 'Muthulakshmi S', 'phone' => '9876543266', 'role' => 'user', 'area' => 'Thogamalai'],
        ['name' => 'Nithya Priya', 'phone' => '9876543267', 'role' => 'user', 'area' => 'Manmangalam'],
        ['name' => 'Oviya B', 'phone' => '9876543268', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Padmavathi K', 'phone' => '9876543269', 'role' => 'user', 'area' => 'Kadavur'],
        ['name' => 'Rajalakshmi T', 'phone' => '9876543270', 'role' => 'user', 'area' => 'Pallapatti'],
        ['name' => 'Saraswathi N', 'phone' => '9876543271', 'role' => 'user', 'area' => 'Paramathi'],
        ['name' => 'Tamilselvi R', 'phone' => '9876543272', 'role' => 'user', 'area' => 'Karur North'],
        ['name' => 'Uma Maheswari', 'phone' => '9876543273', 'role' => 'user', 'area' => 'Karur Town'],
        ['name' => 'Vasuki P', 'phone' => '9876543274', 'role' => 'user', 'area' => 'Kulithalai'],
        ['name' => 'Yamini S', 'phone' => '9876543275', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Arun Sanjeev', 'phone' => '9876543276', 'role' => 'user', 'area' => 'Krishnarayapuram'],
        ['name' => 'Bharath Kumar', 'phone' => '9876543277', 'role' => 'user', 'area' => 'Pugalur'],
        ['name' => 'Chitra Devi', 'phone' => '9876543278', 'role' => 'user', 'area' => 'Thogamalai'],
        ['name' => 'Durga Prasad', 'phone' => '9876543279', 'role' => 'user', 'area' => 'Manmangalam'],
        ['name' => 'Elango Vel', 'phone' => '9876543280', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Gowri Shankar', 'phone' => '9876543281', 'role' => 'user', 'area' => 'Kadavur'],
        ['name' => 'Hemalatha S', 'phone' => '9876543282', 'role' => 'user', 'area' => 'Pallapatti'],
        ['name' => 'Indira Kumari', 'phone' => '9876543283', 'role' => 'user', 'area' => 'Paramathi'],
        ['name' => 'Jeyarani M', 'phone' => '9876543284', 'role' => 'user', 'area' => 'Karur North'],
        ['name' => 'Kalaiselvan R', 'phone' => '9876543285', 'role' => 'user', 'area' => 'Karur Town'],
        ['name' => 'Loganathan K', 'phone' => '9876543286', 'role' => 'user', 'area' => 'Kulithalai'],
        ['name' => 'Mariappan S', 'phone' => '9876543287', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Nagarajan P', 'phone' => '9876543288', 'role' => 'user', 'area' => 'Krishnarayapuram'],
        ['name' => 'Palani Samy', 'phone' => '9876543289', 'role' => 'user', 'area' => 'Pugalur'],
        ['name' => 'Ramamoorthy K', 'phone' => '9876543290', 'role' => 'user', 'area' => 'Thogamalai'],
        ['name' => 'Sankar Narayanan', 'phone' => '9876543291', 'role' => 'user', 'area' => 'Manmangalam'],
        ['name' => 'Thirumalai M', 'phone' => '9876543292', 'role' => 'user', 'area' => 'Aravakurichi'],
        ['name' => 'Udayakumar S', 'phone' => '9876543293', 'role' => 'user', 'area' => 'Kadavur'],
        ['name' => 'Velmurugan R', 'phone' => '9876543294', 'role' => 'user', 'area' => 'Pallapatti'],
        ['name' => 'Yazhini K', 'phone' => '9876543295', 'role' => 'user', 'area' => 'Paramathi'],
        ['name' => 'Aravind Kumar', 'phone' => '9876543296', 'role' => 'admin', 'area' => 'Karur Town'],
        ['name' => 'Bhuvaneshwari S', 'phone' => '9876543297', 'role' => 'admin', 'area' => 'Aravakurichi'],
        ['name' => 'Chellammal R', 'phone' => '9876543298', 'role' => 'hospital', 'area' => 'Kulithalai'],
        ['name' => 'Deivanai M', 'phone' => '9876543299', 'role' => 'hospital', 'area' => 'Krishnarayapuram'],
        ['name' => 'Eswari Lakshmi', 'phone' => '9876543300', 'role' => 'hospital', 'area' => 'Karur Town'],
    ];
    
    // Generate more users to reach ~175 total
    $firstNames = ['Kumaran', 'Selvakumar', 'Thangavel', 'Periyasamy', 'Chinnakannu', 'Muthusamy', 'Arumugam', 'Sivakami', 'Parvathi', 'Angamma', 'Velamma', 'Chinnamma', 'Poongodi', 'Mallika', 'Sundari', 'Chellammal', 'Pappathi', 'Karuppan', 'Ayyanar', 'Muniyandi', 'Thangamani', 'Ramasamy', 'Govindan', 'Perumal', 'Subramani', 'Kannappan', 'Murugappan', 'Vellaisamy', 'Chinnapillai', 'Nagammal'];
    $lastNames = ['K', 'S', 'M', 'R', 'P', 'N', 'V', 'B', 'T', 'L'];
    $areas = ['Karur Town', 'Aravakurichi', 'Kulithalai', 'Krishnarayapuram', 'Pugalur', 'Thogamalai', 'Manmangalam', 'Velur', 'Kadavur', 'Pallapatti', 'Paramathi', 'Karur North'];
    
    $basePhone = 9876543300;
    for ($i = 0; $i < 90; $i++) {
        $tamilNames[] = [
            'name' => $firstNames[array_rand($firstNames)] . ' ' . $lastNames[array_rand($lastNames)],
            'phone' => strval($basePhone + $i + 1),
            'role' => 'user',
            'area' => $areas[array_rand($areas)]
        ];
    }
    
    $users = [];
    foreach ($tamilNames as $idx => $data) {
        $users[] = [
            '_id' => 'USR' . str_pad($idx + 1, 5, '0', STR_PAD_LEFT),
            'user_id' => 'USR' . str_pad($idx + 1, 5, '0', STR_PAD_LEFT),
            'name' => $data['name'],
            'email' => strtolower(str_replace(' ', '.', $data['name'])) . '@gmail.com',
            'phone' => $data['phone'],
            'role' => $data['role'],
            'area' => $data['area'],
            'is_active' => rand(0, 10) > 1,
            'created_at' => date('Y-m-d H:i:s', strtotime('-' . rand(1, 365) . ' days'))
        ];
    }
    
    return $users;
}

// Reva University Bengaluru Hospitals
function getDummyHospitals() {
    return [
        [
            '_id' => 'HOSP001',
            'name' => 'Aster CMI Hospital',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '080 4342 0100',
            'address' => '43/2, New Airport Road, NH 44, Sahakara Nagar, Hebbal, Bengaluru - 560092',
            'status' => 'available',
            'capacity' => ['total' => 500, 'occupied' => 352, 'icu' => 72],
            'specialties' => ['Emergency', 'Trauma Care', 'Cardiology', 'Neurology', 'Orthopedics', 'ICU'],
            'location' => ['lat' => 13.0468, 'lng' => 77.5926],
            'distance' => '11.3 km',
            'rating' => 4.8
        ],
        [
            '_id' => 'HOSP002',
            'name' => 'Manipal Hospital, Yelahanka',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '080 2216 3333',
            'address' => 'Doddaballapur Main Road, Kogilu Cross, Yelahanka, Bengaluru - 560064',
            'status' => 'available',
            'capacity' => ['total' => 350, 'occupied' => 241, 'icu' => 45],
            'specialties' => ['Emergency', 'Cardiology', 'Neurology', 'Nephrology', 'Orthopedics', 'ICU'],
            'location' => ['lat' => 13.1005, 'lng' => 77.5963],
            'distance' => '5.2 km',
            'rating' => 4.6
        ],
        [
            '_id' => 'HOSP003',
            'name' => 'Prolife Hospital',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '080 2809 4444',
            'address' => 'Venkatala Village, Yelahanka, Bengaluru - 560064',
            'status' => 'available',
            'capacity' => ['total' => 180, 'occupied' => 112, 'icu' => 20],
            'specialties' => ['Emergency', 'General Medicine', 'Orthopedics', 'Pediatrics', 'Surgery'],
            'location' => ['lat' => 13.1002, 'lng' => 77.5908],
            'distance' => '5.8 km',
            'rating' => 4.2
        ],
        [
            '_id' => 'HOSP004',
            'name' => 'Omega Multispeciality Hospital',
            'type' => 'Private Hospital',
            'phone' => '080 4249 9999',
            'address' => 'Yelahanka New Town, Bengaluru - 560064',
            'status' => 'available',
            'capacity' => ['total' => 140, 'occupied' => 89, 'icu' => 16],
            'specialties' => ['General Medicine', 'Orthopedics', 'ENT', 'Pediatrics', 'Emergency'],
            'location' => ['lat' => 13.1059, 'lng' => 77.5969],
            'distance' => '4.9 km',
            'rating' => 4.1
        ],
        [
            '_id' => 'HOSP005',
            'name' => 'Navachethana Hospital',
            'type' => 'General Hospital',
            'phone' => '080 2846 0000',
            'address' => 'Sector B, Yelahanka New Town, Bengaluru - 560064',
            'status' => 'available',
            'capacity' => ['total' => 120, 'occupied' => 74, 'icu' => 12],
            'specialties' => ['General Medicine', 'ENT', 'Dermatology', 'Surgery'],
            'location' => ['lat' => 13.1015, 'lng' => 77.5942],
            'distance' => '5.4 km',
            'rating' => 4.2
        ],
        [
            '_id' => 'HOSP006',
            'name' => 'Bangalore Baptist Hospital',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '080 2202 4700',
            'address' => 'Bellary Road, Hebbal, Bengaluru - 560024',
            'status' => 'available',
            'capacity' => ['total' => 340, 'occupied' => 236, 'icu' => 40],
            'specialties' => ['Emergency', 'General Medicine', 'Cardiology', 'Oncology', 'Orthopedics', 'ICU'],
            'location' => ['lat' => 13.0379, 'lng' => 77.5945],
            'distance' => '12.2 km',
            'rating' => 4.5
        ],
        [
            '_id' => 'HOSP007',
            'name' => 'Motherhood Hospital, Hebbal',
            'type' => 'Specialty Hospital',
            'phone' => '080 6723 8888',
            'address' => 'Sahakara Nagar, Hebbal, Bengaluru - 560092',
            'status' => 'available',
            'capacity' => ['total' => 110, 'occupied' => 66, 'icu' => 12],
            'specialties' => ['Maternity', 'Neonatology', 'Pediatrics', 'Gynecology', 'Emergency'],
            'location' => ['lat' => 13.0489, 'lng' => 77.5917],
            'distance' => '10.9 km',
            'rating' => 4.3
        ],
        [
            '_id' => 'HOSP008',
            'name' => 'Ramaiah Memorial Hospital',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '080 4050 3000',
            'address' => 'MSR Nagar, New BEL Road, Bengaluru - 560054',
            'status' => 'available',
            'capacity' => ['total' => 420, 'occupied' => 295, 'icu' => 60],
            'specialties' => ['Emergency', 'Trauma Care', 'General Medicine', 'Surgery', 'Oncology', 'Neurology', 'Orthopedics'],
            'location' => ['lat' => 13.0292, 'lng' => 77.5547],
            'distance' => '16.8 km',
            'rating' => 4.7
        ],
        [
            '_id' => 'HOSP009',
            'name' => 'Akash Hospital, Devanahalli',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '080 4346 0000',
            'address' => 'Prasannahalli Main Road, Devanahalli, Bengaluru - 562110',
            'status' => 'available',
            'capacity' => ['total' => 220, 'occupied' => 143, 'icu' => 24],
            'specialties' => ['Emergency', 'General Medicine', 'Cardiology', 'Orthopedics', 'Pediatrics'],
            'location' => ['lat' => 13.2443, 'lng' => 77.7138],
            'distance' => '18.7 km',
            'rating' => 4.1
        ]
    ];
}

// Reva University Bangalore Drivers/Ambulances
function getDummyDrivers() {
    $drivers = [
        [
            '_id' => 'DRV001',
            'name' => 'Aswanth Vijay',
            'phone' => '9876543214',
            'vehicle_number' => 'KA 01 AM 1234',
            'vehicle_type' => 'Advanced Life Support',
            'ambulance_category' => 'ALS',
            'status' => 'available',
            'current_location' => ['lat' => 13.0674, 'lng' => 80.1452],
            'area' => 'Saveetha University, Thandalam',
            'rating' => 4.8,
            'trips_completed' => 156,
            'avg_arrival_min' => 8.2,
            'avg_speed_kmh' => 62,
            'efficiency_pct' => 94,
            'last_active' => date('Y-m-d H:i:s', strtotime('-5 minutes'))
        ],
        [
            '_id' => 'DRV002',
            'name' => 'Karthik Selvam',
            'phone' => '9876543215',
            'vehicle_number' => 'KA 01 AM 2345',
            'vehicle_type' => 'Basic Life Support',
            'ambulance_category' => 'BLS',
            'status' => 'busy',
            'current_location' => ['lat' => 13.0680, 'lng' => 80.1460],
            'area' => 'Thandalam, Chennai',
            'rating' => 4.6,
            'trips_completed' => 203,
            'avg_arrival_min' => 11.5,
            'avg_speed_kmh' => 54,
            'efficiency_pct' => 87,
            'last_active' => date('Y-m-d H:i:s', strtotime('-2 minutes'))
        ],
        [
            '_id' => 'DRV003',
            'name' => 'Pradeep Kumar',
            'phone' => '9876543216',
            'vehicle_number' => 'KA 01 AM 3456',
            'vehicle_type' => 'Advanced Life Support',
            'ambulance_category' => 'ALS',
            'status' => 'available',
            'current_location' => ['lat' => 13.0386, 'lng' => 80.1581],
            'area' => 'Porur, Chennai',
            'rating' => 4.9,
            'trips_completed' => 189,
            'avg_arrival_min' => 7.8,
            'avg_speed_kmh' => 68,
            'efficiency_pct' => 97,
            'last_active' => date('Y-m-d H:i:s', strtotime('-1 minute'))
        ],
        [
            '_id' => 'DRV004',
            'name' => 'Vignesh Raja',
            'phone' => '9876543217',
            'vehicle_number' => 'KA 01 AM 4567',
            'vehicle_type' => 'Basic Life Support',
            'ambulance_category' => 'BLS',
            'status' => 'available',
            'current_location' => ['lat' => 13.0524, 'lng' => 80.2120],
            'area' => 'Vadapalani, Chennai',
            'rating' => 4.7,
            'trips_completed' => 145,
            'avg_arrival_min' => 10.3,
            'avg_speed_kmh' => 56,
            'efficiency_pct' => 89,
            'last_active' => date('Y-m-d H:i:s', strtotime('-8 minutes'))
        ],
        [
            '_id' => 'DRV005',
            'name' => 'Surya Narayanan',
            'phone' => '9876543218',
            'vehicle_number' => 'KA 01 AM 5678',
            'vehicle_type' => 'Advanced Life Support',
            'ambulance_category' => 'ALS',
            'status' => 'busy',
            'current_location' => ['lat' => 13.0358, 'lng' => 80.2687],
            'area' => 'Mylapore, Chennai',
            'rating' => 4.5,
            'trips_completed' => 178,
            'avg_arrival_min' => 12.1,
            'avg_speed_kmh' => 51,
            'efficiency_pct' => 83,
            'last_active' => date('Y-m-d H:i:s')
        ],
        [
            '_id' => 'DRV006',
            'name' => 'Dinesh Kannan',
            'phone' => '9876543219',
            'vehicle_number' => 'KA 01 AM 6789',
            'vehicle_type' => 'Neonatal Ambulance',
            'ambulance_category' => 'Mobile ICU',
            'status' => 'available',
            'current_location' => ['lat' => 13.0802, 'lng' => 80.2790],
            'area' => 'Park Town, Chennai',
            'rating' => 4.8,
            'trips_completed' => 92,
            'avg_arrival_min' => 9.4,
            'avg_speed_kmh' => 58,
            'efficiency_pct' => 95,
            'last_active' => date('Y-m-d H:i:s', strtotime('-3 minutes'))
        ],
        [
            '_id' => 'DRV007',
            'name' => 'Manoj Pandian',
            'phone' => '9876543220',
            'vehicle_number' => 'KA 01 AM 7890',
            'vehicle_type' => 'Basic Life Support',
            'ambulance_category' => 'BLS',
            'status' => 'offline',
            'current_location' => ['lat' => 13.1116, 'lng' => 80.2914],
            'area' => 'Royapuram, Chennai',
            'rating' => 4.4,
            'trips_completed' => 134,
            'avg_arrival_min' => 14.2,
            'avg_speed_kmh' => 47,
            'efficiency_pct' => 78,
            'last_active' => date('Y-m-d H:i:s', strtotime('-2 hours'))
        ],
        [
            '_id' => 'DRV008',
            'name' => 'Rajesh Murugan',
            'phone' => '9876543221',
            'vehicle_number' => 'KA 01 AM 8901',
            'vehicle_type' => 'Advanced Life Support',
            'ambulance_category' => 'ALS',
            'status' => 'available',
            'current_location' => ['lat' => 13.0012, 'lng' => 80.2565],
            'area' => 'Adyar, Chennai',
            'rating' => 4.7,
            'trips_completed' => 167,
            'avg_arrival_min' => 9.1,
            'avg_speed_kmh' => 63,
            'efficiency_pct' => 92,
            'last_active' => date('Y-m-d H:i:s', strtotime('-6 minutes'))
        ],
        [
            '_id' => 'DRV009',
            'name' => 'Ganesh Subramani',
            'phone' => '9876543222',
            'vehicle_number' => 'KA 01 AM 9012',
            'vehicle_type' => 'Cardiac Ambulance',
            'ambulance_category' => 'Mobile ICU',
            'status' => 'available',
            'current_location' => ['lat' => 13.0580, 'lng' => 80.1530],
            'area' => 'Royapettah, Chennai',
            'rating' => 4.9,
            'trips_completed' => 78,
            'avg_arrival_min' => 7.5,
            'avg_speed_kmh' => 71,
            'efficiency_pct' => 98,
            'last_active' => date('Y-m-d H:i:s', strtotime('-4 minutes'))
        ],
        [
            '_id' => 'DRV010',
            'name' => 'Senthil Nathan',
            'phone' => '9876543223',
            'vehicle_number' => 'KA 01 AM 0123',
            'vehicle_type' => 'Basic Life Support',
            'ambulance_category' => 'BLS',
            'status' => 'busy',
            'current_location' => ['lat' => 13.0450, 'lng' => 80.1700],
            'area' => 'Koyambedu, Chennai',
            'rating' => 4.6,
            'trips_completed' => 198,
            'avg_arrival_min' => 10.8,
            'avg_speed_kmh' => 53,
            'efficiency_pct' => 86,
            'last_active' => date('Y-m-d H:i:s')
        ],
        [
            '_id' => 'DRV011',
            'name' => 'Bala Murugan',
            'phone' => '9876543224',
            'vehicle_number' => 'KA 01 AM 1357',
            'vehicle_type' => 'Advanced Life Support',
            'ambulance_category' => 'ALS',
            'status' => 'available',
            'current_location' => ['lat' => 13.0700, 'lng' => 80.2100],
            'area' => 'Anna Nagar, Chennai',
            'rating' => 4.8,
            'trips_completed' => 143,
            'avg_arrival_min' => 8.6,
            'avg_speed_kmh' => 65,
            'efficiency_pct' => 93,
            'last_active' => date('Y-m-d H:i:s', strtotime('-7 minutes'))
        ],
        [
            '_id' => 'DRV012',
            'name' => 'Murugesan K',
            'phone' => '9876543315',
            'vehicle_number' => 'KA 01 AM 2468',
            'vehicle_type' => 'Basic Life Support',
            'ambulance_category' => 'BLS',
            'status' => 'available',
            'current_location' => ['lat' => 13.0827, 'lng' => 80.2707],
            'area' => 'Perambur, Chennai',
            'rating' => 4.5,
            'trips_completed' => 112,
            'avg_arrival_min' => 13.0,
            'avg_speed_kmh' => 49,
            'efficiency_pct' => 82,
            'last_active' => date('Y-m-d H:i:s', strtotime('-12 minutes'))
        ]
    ];
    
    $BangaloreZones = [
        ['area' => 'Bangalore Bus Stand', 'lat' => 13.1165, 'lng' => 77.6341],
        ['area' => 'Mohanur Road, Bangalore', 'lat' => 11.2147, 'lng' => 78.1734],
        ['area' => 'Paramathi Road, Bangalore', 'lat' => 11.2108, 'lng' => 78.1810],
        ['area' => 'Senthamangalam', 'lat' => 11.3010, 'lng' => 78.2264],
        ['area' => 'Tiruchengode', 'lat' => 11.3807, 'lng' => 77.8947],
        ['area' => 'Rasipuram', 'lat' => 11.4600, 'lng' => 78.1858],
        ['area' => 'Komarapalayam', 'lat' => 11.4382, 'lng' => 77.6948],
        ['area' => 'Velur', 'lat' => 11.1092, 'lng' => 78.0023],
        ['area' => 'Puduchatram', 'lat' => 11.4975, 'lng' => 78.1892],
        ['area' => 'Nallipalayam', 'lat' => 11.1985, 'lng' => 78.1545],
        ['area' => 'Kabilarmalai', 'lat' => 11.1564, 'lng' => 77.9291],
        ['area' => 'Mallasamudram', 'lat' => 11.4906, 'lng' => 77.9014]
    ];

    foreach ($drivers as $i => &$driver) {
        $zone = $BangaloreZones[$i % count($BangaloreZones)];
        $driver['area'] = $zone['area'];
        $driver['current_location'] = ['lat' => $zone['lat'], 'lng' => $zone['lng']];
    }
    unset($driver);

    return $drivers;
}

// Active SOS Requests - All in Reva University Bangalore
function getDummyRequests() {
    $users = getDummyUsers();
    $drivers = getDummyDrivers();
    $hospitals = getDummyHospitals();
    
    // Locations in Reva University Bangalore
    $locations = [
        ['name' => 'Bangalore Bus Stand', 'lat' => 13.1165, 'lng' => 77.6341],
        ['name' => 'Bangalore Railway Station', 'lat' => 11.2222, 'lng' => 78.1601],
        ['name' => 'Mohanur Road', 'lat' => 11.2147, 'lng' => 78.1734],
        ['name' => 'Paramathi Road', 'lat' => 11.2108, 'lng' => 78.1810],
        ['name' => 'Senthamangalam', 'lat' => 11.3010, 'lng' => 78.2264],
        ['name' => 'Tiruchengode Old Bus Stand', 'lat' => 11.3807, 'lng' => 77.8947],
        ['name' => 'Rasipuram Market', 'lat' => 11.4600, 'lng' => 78.1858],
        ['name' => 'Komarapalayam Junction', 'lat' => 11.4382, 'lng' => 77.6948],
        ['name' => 'Velur', 'lat' => 11.1092, 'lng' => 78.0023],
        ['name' => 'Puduchatram', 'lat' => 11.4975, 'lng' => 78.1892],
        ['name' => 'Nallipalayam', 'lat' => 11.1985, 'lng' => 78.1545],
        ['name' => 'Kabilarmalai', 'lat' => 11.1564, 'lng' => 77.9291],
        ['name' => 'Mallasamudram', 'lat' => 11.4906, 'lng' => 77.9014],
        ['name' => 'Mohanur', 'lat' => 11.0588, 'lng' => 78.1402],
        ['name' => 'Pallipalayam', 'lat' => 11.3383, 'lng' => 77.7330]
    ];
    
    $severities = ['critical', 'high', 'medium', 'low'];
    $statuses = ['pending', 'accepted', 'in_progress', 'picked_up', 'completed', 'completed', 'completed'];
    $emergencyTypes = ['Cardiac Arrest', 'Accident Trauma', 'Breathing Difficulty', 'Chest Pain', 'Pregnancy Emergency', 'Burns', 'Fracture', 'Unconscious', 'Bleeding', 'Fever Emergency'];
    
    $requests = [];
    $patientUsers = array_filter($users, fn($u) => $u['role'] === 'user');
    $patientUsers = array_values($patientUsers);
    
    // Generate 35 requests
    for ($i = 0; $i < 35; $i++) {
        $user = $patientUsers[array_rand($patientUsers)];
        $location = $locations[array_rand($locations)];
        $status = $statuses[array_rand($statuses)];
        $severity = $severities[array_rand($severities)];
        
        // Assign driver if status is not pending
        $assignedDriver = null;
        if ($status !== 'pending') {
            $availableDrivers = array_filter($drivers, fn($d) => $d['status'] !== 'offline');
            $driverList = array_values($availableDrivers);
            if (!empty($driverList)) {
                $assignedDriver = $driverList[array_rand($driverList)];
            }
        }
        
        // Assign hospital
        $hospital = $hospitals[array_rand($hospitals)];
        
        $createdMinutesAgo = rand(5, 1440);
        
        $requests[] = [
            '_id' => 'REQ' . str_pad($i + 1, 6, '0', STR_PAD_LEFT),
            'request_id' => 'SOS' . date('Ymd') . str_pad($i + 1, 4, '0', STR_PAD_LEFT),
            'user_id' => $user['_id'],
            'user_name' => $user['name'],
            'user_phone' => $user['phone'],
            'location' => $location,
            'pickup_location' => $location['name'] . ', Reva University Bangalore',
            'latitude' => $location['lat'],
            'longitude' => $location['lng'],
            'severity' => $severity,
            'status' => $status,
            'emergency_type' => $emergencyTypes[array_rand($emergencyTypes)],
            'driver_id' => $assignedDriver ? $assignedDriver['_id'] : null,
            'driver_name' => $assignedDriver ? $assignedDriver['name'] : null,
            'driver_phone' => $assignedDriver ? $assignedDriver['phone'] : null,
            'vehicle_number' => $assignedDriver ? $assignedDriver['vehicle_number'] : null,
            'hospital_id' => $hospital['_id'],
            'hospital_name' => $hospital['name'],
            'estimated_time' => rand(3, 15) . ' min',
            'distance' => number_format(rand(5, 150) / 10, 1) . ' km',
            'notes' => 'Emergency reported from ' . $location['name'],
            'created_at' => date('Y-m-d H:i:s', strtotime("-{$createdMinutesAgo} minutes")),
            'updated_at' => date('Y-m-d H:i:s', strtotime('-' . max(0, $createdMinutesAgo - rand(1, 30)) . ' minutes'))
        ];
    }
    
    // Sort by created_at descending
    usort($requests, fn($a, $b) => strtotime($b['created_at']) - strtotime($a['created_at']));
    
    return $requests;
}

// Get Dashboard Stats
function getDummyStats() {
    $requests = getDummyRequests();
    $drivers = getDummyDrivers();
    $hospitals = getDummyHospitals();
    $users = getDummyUsers();
    $activeStatuses = getActiveRequestStatuses();
    
    $activeRequests = array_filter($requests, fn($r) => in_array(strtolower((string) ($r['status'] ?? 'pending')), $activeStatuses, true));
    $completedRequests = array_filter($requests, fn($r) => $r['status'] === 'completed');
    $criticalRequests = array_filter($activeRequests, fn($r) => $r['severity'] === 'critical');
    $availableDrivers = array_filter($drivers, fn($d) => $d['status'] === 'available');
    
    return [
        'total_requests' => count($requests),
        'active_requests' => count($activeRequests),
        'completed_requests' => count($completedRequests),
        'critical_requests' => count($criticalRequests),
        'available_drivers' => count($availableDrivers),
        'total_drivers' => count($drivers),
        'busy_drivers' => count(array_filter($drivers, fn($d) => $d['status'] === 'busy')),
        'total_hospitals' => count($hospitals),
        'total_users' => count($users),
        'total_patients' => count(array_filter($users, fn($u) => $u['role'] === 'user')),
        'avg_response_time' => '4.2',
        'success_rate' => 98.5,
        'region' => 'Reva University Bangalore',
        'center' => 'Reva University Bangalore'
    ];
}

// API call wrapper with live Mongo bridge + dummy fallback
function adminApiCall($endpoint) {
    $endpoint = trim((string) $endpoint);
    $endpoint = ltrim($endpoint, '/');

    $parsed = parse_url('/' . $endpoint);
    $path = trim((string) ($parsed['path'] ?? ''), '/');
    $query = [];
    if (!empty($parsed['query'])) {
        parse_str($parsed['query'], $query);
    }

    // Prefer live data via Python bridge when available.
    $liveData = getLiveDashboardData();
    if (is_array($liveData)) {
        $users = is_array($liveData['users'] ?? null) ? $liveData['users'] : [];
        $hospitals = is_array($liveData['hospitals'] ?? null) ? $liveData['hospitals'] : [];
        $drivers = is_array($liveData['drivers'] ?? null) ? $liveData['drivers'] : [];
        $requests = is_array($liveData['requests'] ?? null) ? $liveData['requests'] : [];
        $stats = buildLiveStats($liveData);
        $activeStatuses = getActiveRequestStatuses();

        switch ($path) {
            case 'stats':
                return ['success' => true, 'source' => 'mongo-python', 'stats' => $stats, 'data' => $stats];

            case 'users':
                $filteredUsers = filterByQueryField($users, 'role', $query['role'] ?? null);
                return ['success' => true, 'source' => 'mongo-python', 'users' => $filteredUsers, 'data' => $filteredUsers];

            case 'hospitals':
                return ['success' => true, 'source' => 'mongo-python', 'hospitals' => $hospitals, 'data' => $hospitals];

            case 'drivers':
                $filteredDrivers = filterByQueryField($drivers, 'status', $query['status'] ?? null);
                return ['success' => true, 'source' => 'mongo-python', 'drivers' => $filteredDrivers, 'data' => $filteredDrivers];

            case 'requests':
                $statusFilter = strtolower(trim((string) ($query['status'] ?? '')));
                if ($statusFilter === 'active') {
                    $requests = array_values(array_filter($requests, fn($r) => in_array(strtolower((string) ($r['status'] ?? 'pending')), $activeStatuses, true)));
                } elseif ($statusFilter !== '' && $statusFilter !== 'all') {
                    $requests = array_values(array_filter($requests, fn($r) => strtolower((string) ($r['status'] ?? '')) === $statusFilter));
                }
                return ['success' => true, 'source' => 'mongo-python', 'requests' => $requests, 'data' => $requests];

            case 'sos/active':
                $activeRequests = array_values(array_filter($requests, fn($r) => in_array(strtolower((string) ($r['status'] ?? 'pending')), $activeStatuses, true)));
                return ['success' => true, 'source' => 'mongo-python', 'requests' => $activeRequests, 'data' => $activeRequests];
        }
    }

    // Fallback to local dummy payloads.
    switch ($path) {
        case 'stats':
            $stats = getDummyStats();
            return ['success' => true, 'source' => 'dummy', 'stats' => $stats, 'data' => $stats];

        case 'users':
            $users = filterByQueryField(getDummyUsers(), 'role', $query['role'] ?? null);
            return ['success' => true, 'source' => 'dummy', 'users' => $users, 'data' => $users];

        case 'hospitals':
            $hospitals = getDummyHospitals();
            return ['success' => true, 'source' => 'dummy', 'hospitals' => $hospitals, 'data' => $hospitals];

        case 'drivers':
            $drivers = filterByQueryField(getDummyDrivers(), 'status', $query['status'] ?? null);
            return ['success' => true, 'source' => 'dummy', 'drivers' => $drivers, 'data' => $drivers];

        case 'requests':
            $requests = getDummyRequests();
            $statusFilter = strtolower(trim((string) ($query['status'] ?? '')));
            if ($statusFilter === 'active') {
                $requests = array_values(array_filter($requests, fn($r) => in_array(strtolower((string) ($r['status'] ?? 'pending')), getActiveRequestStatuses(), true)));
            } elseif ($statusFilter !== '' && $statusFilter !== 'all') {
                $requests = array_values(array_filter($requests, fn($r) => strtolower((string) ($r['status'] ?? '')) === $statusFilter));
            }
            return ['success' => true, 'source' => 'dummy', 'requests' => $requests, 'data' => $requests];

        case 'sos/active':
            $requests = getDummyRequests();
            $activeRequests = array_values(array_filter($requests, fn($r) => in_array(strtolower((string) ($r['status'] ?? 'pending')), getActiveRequestStatuses(), true)));
            return ['success' => true, 'source' => 'dummy', 'requests' => $activeRequests, 'data' => $activeRequests];

        default:
            return ['success' => true, 'source' => 'dummy', 'data' => []];
    }
}

function apiCall($endpoint) {
    return adminApiCall($endpoint);
}

// Helper Functions
function formatDate($dateStr) {
    if (empty($dateStr)) return 'N/A';
    $date = strtotime($dateStr);
    return date('M d, Y', $date);
}

function timeAgo($dateStr) {
    if (empty($dateStr)) return 'N/A';
    $date = strtotime($dateStr);
    $now = time();
    $diff = $now - $date;
    
    if ($diff < 60) return 'Just now';
    if ($diff < 3600) return floor($diff / 60) . ' min ago';
    if ($diff < 86400) return floor($diff / 3600) . ' hours ago';
    if ($diff < 604800) return floor($diff / 86400) . ' days ago';
    return date('M d, Y', $date);
}

