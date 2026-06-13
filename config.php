<?php
/**
 * Smart Ambulance System - Configuration
 * Chennai Region - Saveetha University
 */

// =====================================
// MONGODB ATLAS CONFIGURATION
// =====================================
define('MONGODB_URI', 'mongodb+srv://Dharun:Dharun2712@cluster0.yr5quzl.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0');
define('MONGODB_DB', 'smart_ambulance');

/**
 * Get a MongoDB Atlas database connection.
 * Returns null if connection fails (fallback to dummy data).
 */
function getMongoDb(): ?\MongoDB\Database {
    static $db = null;
    if ($db !== null) return $db;
    try {
        $vendorAutoload = __DIR__ . '/vendor/autoload.php';
        if (!file_exists($vendorAutoload)) return null;
        require_once $vendorAutoload;
        $client = new \MongoDB\Client(MONGODB_URI);
        $db = $client->selectDatabase(MONGODB_DB);
        return $db;
    } catch (\Exception $e) {
        return null;
    }
}

/**
 * Fetch alerts from MongoDB Atlas → smart_ambulance.patient_requests
 * Maps real fields to the format the alerts UI expects.
 */
function getAlertsFromMongo(): array {
    $db = getMongoDb();
    if ($db === null) return [];
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
        return [];
    }
}

// API Configuration (Local dummy data - No Azure)
define('API_BASE_URL', '');
define('ADMIN_API_URL', '');

// Chennai Region Coordinates - Saveetha University
define('REGION_CENTER_LAT', 13.0674);
define('REGION_CENTER_LNG', 80.1452);
define('REGION_NAME', 'Chennai District');

// =====================================
// DUMMY DATA - CHENNAI REGION
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

// Chennai Region Hospitals
function getDummyHospitals() {
    return [
        [
            '_id' => 'HOSP001',
            'name' => 'Apollo Hospitals',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '044-28290200',
            'address' => 'Greams Road, Chennai - 600006',
            'status' => 'available',
            'capacity' => ['total' => 200, 'occupied' => 142, 'icu' => 30],
            'specialties' => ['Emergency', 'Cardiology', 'Neurology', 'ICU', 'Surgery', 'Orthopedics'],
            'location' => ['lat' => 13.0674, 'lng' => 80.1452],
            'distance' => '0.26 km',
            'rating' => 4.8
        ],
        [
            '_id' => 'HOSP002',
            'name' => 'Saveetha Medical College & Hospital',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '044-26801006',
            'address' => 'Thandalam, Chennai - 602105',
            'status' => 'available',
            'capacity' => ['total' => 60, 'occupied' => 38, 'icu' => 8],
            'specialties' => ['Emergency', 'Trauma Care', 'General Medicine', 'ICU'],
            'location' => ['lat' => 13.0720, 'lng' => 80.1380],
            'distance' => '0.26 km',
            'rating' => 4.4
        ],
        [
            '_id' => 'HOSP003',
            'name' => 'MIOT International Hospital',
            'type' => 'Private Hospital',
            'phone' => '044-42002288',
            'address' => "Peter's Road, Royapettah, Chennai - 600014",
            'status' => 'available',
            'capacity' => ['total' => 120, 'occupied' => 78, 'icu' => 15],
            'specialties' => ['General Medicine', 'Gynecology', 'Maternity', 'Pediatrics', 'Surgery'],
            'location' => ['lat' => 13.0580, 'lng' => 80.1530],
            'distance' => '0.47 km',
            'rating' => 4.5
        ],
        [
            '_id' => 'HOSP004',
            'name' => 'Fortis Malar Hospital',
            'type' => 'Private Hospital',
            'phone' => '044-42892222',
            'address' => 'Gandhi Nagar, Adyar, Chennai - 600020',
            'status' => 'available',
            'capacity' => ['total' => 100, 'occupied' => 64, 'icu' => 12],
            'specialties' => ['General Medicine', 'Orthopedics', 'Surgery', 'Pediatrics'],
            'location' => ['lat' => 13.0012, 'lng' => 80.2565],
            'distance' => '0.47 km',
            'rating' => 4.3
        ],
        [
            '_id' => 'HOSP005',
            'name' => 'Sri Ramachandra Medical Centre',
            'type' => 'Private Hospital',
            'phone' => '044-24768027',
            'address' => 'Porur, Chennai - 600116',
            'status' => 'available',
            'capacity' => ['total' => 80, 'occupied' => 51, 'icu' => 10],
            'specialties' => ['General Medicine', 'ENT', 'Dermatology', 'Surgery'],
            'location' => ['lat' => 13.0386, 'lng' => 80.1581],
            'distance' => '0.78 km',
            'rating' => 4.2
        ],
        [
            '_id' => 'HOSP006',
            'name' => 'Vijaya Health Centre',
            'type' => 'Multi-Specialty Hospital',
            'phone' => '044-24809999',
            'address' => 'NSK Salai, Vadapalani, Chennai - 600026',
            'status' => 'available',
            'capacity' => ['total' => 150, 'occupied' => 98, 'icu' => 20],
            'specialties' => ['Cardiology', 'Nephrology', 'Gastroenterology', 'Emergency', 'ICU', 'Dialysis'],
            'location' => ['lat' => 13.0524, 'lng' => 80.2120],
            'distance' => '1.44 km',
            'rating' => 4.6
        ],
        [
            '_id' => 'HOSP007',
            'name' => 'Kauvery Hospital',
            'type' => 'Private Hospital',
            'phone' => '044-40009000',
            'address' => 'Radha Krishnan Salai, Mylapore, Chennai - 600004',
            'status' => 'available',
            'capacity' => ['total' => 90, 'occupied' => 58, 'icu' => 12],
            'specialties' => ['General Medicine', 'Gynecology', 'Maternity', 'Surgery', 'Pediatrics'],
            'location' => ['lat' => 13.0358, 'lng' => 80.2687],
            'distance' => '1.88 km',
            'rating' => 4.3
        ],
        [
            '_id' => 'HOSP008',
            'name' => 'Rajiv Gandhi Govt General Hospital',
            'type' => 'Government Hospital',
            'phone' => '044-25305000',
            'address' => 'Park Town, Chennai - 600003',
            'status' => 'available',
            'capacity' => ['total' => 300, 'occupied' => 214, 'icu' => 40],
            'specialties' => ['Emergency', 'Trauma Care', 'General Medicine', 'Surgery', 'Oncology', 'Pediatrics', 'Orthopedics'],
            'location' => ['lat' => 13.0802, 'lng' => 80.2790],
            'distance' => '3.58 km',
            'rating' => 4.7
        ],
        [
            '_id' => 'HOSP009',
            'name' => 'Stanley Medical College Hospital',
            'type' => 'Government Hospital',
            'phone' => '044-25281441',
            'address' => 'Old Jail Road, Royapuram, Chennai - 600001',
            'status' => 'available',
            'capacity' => ['total' => 180, 'occupied' => 119, 'icu' => 20],
            'specialties' => ['Emergency', 'General Medicine', 'Maternity', 'Surgery', 'Pediatrics'],
            'location' => ['lat' => 13.1116, 'lng' => 80.2914],
            'distance' => '15.52 km',
            'rating' => 4.1
        ]
    ];
}

// Chennai Region Drivers/Ambulances
function getDummyDrivers() {
    $drivers = [
        [
            '_id' => 'DRV001',
            'name' => 'Aswanth Vijay',
            'phone' => '9876543214',
            'vehicle_number' => 'TN 01 AM 1234',
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
            'vehicle_number' => 'TN 01 AM 2345',
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
            'vehicle_number' => 'TN 01 AM 3456',
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
            'vehicle_number' => 'TN 01 AM 4567',
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
            'vehicle_number' => 'TN 01 AM 5678',
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
            'vehicle_number' => 'TN 01 AM 6789',
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
            'vehicle_number' => 'TN 01 AM 7890',
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
            'vehicle_number' => 'TN 01 AM 8901',
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
            'vehicle_number' => 'TN 01 AM 9012',
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
            'vehicle_number' => 'TN 01 AM 0123',
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
            'vehicle_number' => 'TN 01 AM 1357',
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
            'vehicle_number' => 'TN 01 AM 2468',
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
    
    return $drivers;
}

// Active SOS Requests - All in Chennai Region
function getDummyRequests() {
    $users = getDummyUsers();
    $drivers = getDummyDrivers();
    $hospitals = getDummyHospitals();
    
    // Locations in Chennai District
    $locations = [
        ['name' => 'Saveetha University, Thandalam', 'lat' => 13.0674, 'lng' => 80.1452],
        ['name' => 'Chennai Central Railway Station', 'lat' => 13.0827, 'lng' => 80.2707],
        ['name' => 'Anna Nagar', 'lat' => 13.0700, 'lng' => 80.2100],
        ['name' => 'Koyambedu Bus Stand', 'lat' => 13.0695, 'lng' => 80.1947],
        ['name' => 'Adyar', 'lat' => 13.0012, 'lng' => 80.2565],
        ['name' => 'Mylapore', 'lat' => 13.0358, 'lng' => 80.2687],
        ['name' => 'Vadapalani', 'lat' => 13.0524, 'lng' => 80.2120],
        ['name' => 'Porur', 'lat' => 13.0386, 'lng' => 80.1581],
        ['name' => 'Royapettah', 'lat' => 13.0580, 'lng' => 80.1530],
        ['name' => 'Perambur', 'lat' => 13.1116, 'lng' => 80.2350],
        ['name' => 'T. Nagar', 'lat' => 13.0418, 'lng' => 80.2341],
        ['name' => 'Tambaram', 'lat' => 12.9249, 'lng' => 80.1000],
        ['name' => 'Velachery', 'lat' => 12.9814, 'lng' => 80.2180],
        ['name' => 'Sholinganallur', 'lat' => 12.9010, 'lng' => 80.2279],
        ['name' => 'Ambattur', 'lat' => 13.1143, 'lng' => 80.1548]
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
            'pickup_location' => $location['name'] . ', Chennai District',
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
    
    $activeRequests = array_filter($requests, fn($r) => in_array($r['status'], ['pending', 'accepted', 'in_progress', 'picked_up']));
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
        'region' => 'Karur District',
        'center' => 'Karur Town Center'
    ];
}

// Dummy API call function (replaces Azure API)
function adminApiCall($endpoint) {
    $endpoint = ltrim($endpoint, '/');
    
    switch ($endpoint) {
        case 'stats':
            return ['success' => true, 'stats' => getDummyStats(), 'data' => getDummyStats()];
        case 'users':
            return ['success' => true, 'users' => getDummyUsers(), 'data' => getDummyUsers()];
        case 'hospitals':
            return ['success' => true, 'hospitals' => getDummyHospitals(), 'data' => getDummyHospitals()];
        case 'drivers':
            return ['success' => true, 'drivers' => getDummyDrivers(), 'data' => getDummyDrivers()];
        case 'requests':
            return ['success' => true, 'requests' => getDummyRequests(), 'data' => getDummyRequests()];
        default:
            return ['success' => true, 'data' => []];
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
