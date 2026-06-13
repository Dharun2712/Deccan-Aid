<?php
/**
 * Requests API - Returns SOS request data directly from MongoDB (patient_requests)
 *
 * Performance-optimised PHP-only version:
 *   • Direct MongoDB find() with proper indexing hints
 *   • Single-pass counting instead of 4x array_filter
 *   • No Python subprocess fallback — pure PHP with ext-mongodb
 *   • Increased socket timeout for large result sets from Atlas
 */
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');
require_once __DIR__ . '/../config.php';

/**
 * Convert BSON values recursively so JSON encoding is safe.
 *
 * @param mixed $value
 * @return mixed
 */
function bsonToNative($value) {
    if ($value instanceof \MongoDB\BSON\ObjectId) {
        return (string) $value;
    }

    if ($value instanceof \MongoDB\BSON\UTCDateTime) {
        return $value->toDateTime()->format('Y-m-d\TH:i:s\Z');
    }

    if ($value instanceof \MongoDB\BSON\Decimal128) {
        return (string) $value;
    }

    if ($value instanceof \MongoDB\Model\BSONDocument || $value instanceof \MongoDB\Model\BSONArray) {
        $value = $value->getArrayCopy();
    }

    if (is_array($value)) {
        foreach ($value as $key => $item) {
            $value[$key] = bsonToNative($item);
        }
        return $value;
    }

    return $value;
}

/**
 * Normalize severity values from request fields.
 */
function normalizeRequestSeverity(array $request): string {
    $raw = strtolower(trim((string) ($request['preliminary_severity'] ?? $request['injury_level'] ?? $request['severity'] ?? 'medium')));
    $map = [
        'critical' => 'critical',
        'severe' => 'critical',
        'high' => 'high',
        'medium' => 'medium',
        'moderate' => 'medium',
        'mid' => 'medium',
        'low' => 'low',
        'minor' => 'low',
    ];

    return $map[$raw] ?? 'medium';
}

/**
 * Decode request payload JSON body.
 */
function decodeJsonRequestBody(): array {
    $rawBody = file_get_contents('php://input');
    if (!is_string($rawBody) || trim($rawBody) === '') {
        return [];
    }

    $decoded = json_decode($rawBody, true);
    return is_array($decoded) ? $decoded : [];
}

try {
    $requestMethod = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

    if ($requestMethod === 'POST') {
        $payload = decodeJsonRequestBody();
        $action = strtolower(trim((string) ($payload['action'] ?? $_POST['action'] ?? '')));

        if ($action !== 'delete_all') {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Unsupported action.',
            ]);
            return;
        }

        $confirmationToken = (string) ($payload['confirm'] ?? $_POST['confirm'] ?? '');
        if ($confirmationToken !== 'DELETE_ALL') {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error' => 'Delete confirmation failed.',
            ]);
            return;
        }

        $db = getMongoDb();
        if ($db === null) {
            throw new RuntimeException('MongoDB connection unavailable. Ensure ext-mongodb is installed and vendor/autoload.php exists.');
        }

        $collection = $db->selectCollection('patient_requests');
        $result = $collection->deleteMany([]);

        echo json_encode([
            'success' => true,
            'deleted_count' => $result->getDeletedCount(),
            'message' => 'All SOS requests deleted.',
            'fetched_at' => gmdate('Y-m-d\TH:i:s\Z'),
        ], JSON_UNESCAPED_SLASHES);
        return;
    }

    $severityFilter = strtolower(trim((string) ($_GET['severity'] ?? 'all')));
    $statusFilter = strtolower(trim((string) ($_GET['status'] ?? 'all')));

    $db = getMongoDb();
    if ($db === null) {
        throw new RuntimeException('MongoDB connection unavailable. Ensure ext-mongodb is installed and vendor/autoload.php exists.');
    }

    $activeStatuses = getActiveRequestStatuses();

    $mongoFilter = [];
    if ($statusFilter === 'active') {
        $mongoFilter['status'] = ['$in' => $activeStatuses];
    } elseif ($statusFilter !== '' && $statusFilter !== 'all') {
        $mongoFilter['status'] = $statusFilter;
    }

    $collection = $db->selectCollection('patient_requests');

    // Use a generous socket timeout for the find query (Atlas can be slow for large collections)
    $cursor = $collection->find(
        $mongoFilter,
        [
            'sort' => ['timestamp' => -1],
            'limit' => 200,
            'projection' => [
                '_id' => 1,
                'request_id' => 1,
                'user_name' => 1,
                'name' => 1,
                'user_phone' => 1,
                'user_contact' => 1,
                'contact' => 1,
                'emergency_type' => 1,
                'condition' => 1,
                'severity' => 1,
                'preliminary_severity' => 1,
                'injury_level' => 1,
                'status' => 1,
                'location' => 1,
                'pickup_location' => 1,
                'latitude' => 1,
                'longitude' => 1,
                'created_at' => 1,
                'timestamp' => 1,
            ],
            'typeMap' => ['root' => 'array', 'document' => 'array', 'array' => 'array'],
            'maxTimeMS' => 10000,
        ]
    );

    // Single-pass: normalise docs AND count severities simultaneously
    $requests = [];
    $counts = ['critical' => 0, 'high' => 0, 'medium' => 0, 'low' => 0, 'total' => 0];

    foreach ($cursor as $rawDoc) {
        $doc = bsonToNative($rawDoc);
        if (!is_array($doc)) {
            continue;
        }

        $severity = normalizeRequestSeverity($doc);

        // Count in single pass
        $counts['total']++;
        if (isset($counts[$severity])) {
            $counts[$severity]++;
        }

        // Normalise fields for the UI
        if (!isset($doc['user_phone']) && isset($doc['user_contact'])) {
            $doc['user_phone'] = $doc['user_contact'];
        }

        if (!isset($doc['emergency_type']) && isset($doc['condition'])) {
            $doc['emergency_type'] = ucwords(str_replace('_', ' ', (string) $doc['condition']));
        }

        if (!isset($doc['created_at']) && isset($doc['timestamp'])) {
            $doc['created_at'] = $doc['timestamp'];
        }

        $coordinates = is_array($doc['location']['coordinates'] ?? null) ? $doc['location']['coordinates'] : null;
        $lat = $coordinates[1] ?? ($doc['latitude'] ?? null);
        $lng = $coordinates[0] ?? ($doc['longitude'] ?? null);
        $locationName = '';
        if ($lat !== null && $lng !== null) {
            $locationName = round((float) $lat, 4) . ', ' . round((float) $lng, 4);
        }

        if (!isset($doc['location']) || !is_array($doc['location'])) {
            $doc['location'] = [];
        }
        if (!isset($doc['location']['name']) || $doc['location']['name'] === '') {
            $doc['location']['name'] = $locationName;
        }
        if (!isset($doc['location']['lat'])) {
            $doc['location']['lat'] = $lat;
        }
        if (!isset($doc['location']['lng'])) {
            $doc['location']['lng'] = $lng;
        }

        // Keep the original fields and add normalized severity for UI filtering.
        $doc['severity'] = $severity;
        $requests[] = $doc;
    }

    // Apply severity filter client-side (filtering after counting to keep accurate totals)
    $filtered = $requests;
    if (in_array($severityFilter, ['critical', 'high', 'medium', 'low'], true)) {
        $filtered = array_values(array_filter(
            $requests,
            fn($r) => strtolower((string) ($r['severity'] ?? '')) === $severityFilter
        ));
    }

    echo json_encode([
        'success' => true,
        'source' => 'mongodb',
        'counts' => $counts,
        'requests' => $filtered,
        'fetched_at' => gmdate('Y-m-d\TH:i:s\Z'),
    ], JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Failed to fetch SOS requests from MongoDB.',
        'detail' => $e->getMessage(),
    ]);
}
