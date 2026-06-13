<?php
require __DIR__ . '/config.php';

$db = getMongoDb();

// Check accidents collection for recent entries
echo "=== accidents collection (latest 5) ===\n";
$accidents = $db->selectCollection('accidents');
$cursor = $accidents->find([], ['sort' => ['timestamp' => -1], 'limit' => 5, 'typeMap' => ['root' => 'array', 'document' => 'array', 'array' => 'array']]);
foreach ($cursor as $doc) {
    $ts = $doc['timestamp'] instanceof MongoDB\BSON\UTCDateTime ? $doc['timestamp']->toDateTime()->format('Y-m-d H:i:s Z') : ($doc['timestamp'] ?? '?');
    echo "  Status: {$doc['status']} | Event: {$doc['event']} | Force: " . ($doc['impact_force'] ?? '?') . " | Time: $ts\n";
}

// Check patient_requests for very recent entries (any status)
echo "\n=== patient_requests (latest 5, any status) ===\n";
$pr = $db->selectCollection('patient_requests');
$cursor2 = $pr->find([], ['sort' => ['timestamp' => -1], 'limit' => 5, 'typeMap' => ['root' => 'array', 'document' => 'array', 'array' => 'array']]);
foreach ($cursor2 as $doc) {
    $ts = $doc['timestamp'] instanceof MongoDB\BSON\UTCDateTime ? $doc['timestamp']->toDateTime()->format('Y-m-d H:i:s Z') : ($doc['timestamp'] ?? '?');
    echo "  Status: {$doc['status']} | Condition: " . ($doc['condition'] ?? '?') . " | Severity: " . ($doc['preliminary_severity'] ?? '?') . " | Name: " . ($doc['user_name'] ?? '?') . " | Time: $ts\n";
}

// Check distinct statuses in patient_requests
echo "\n=== All distinct statuses in patient_requests ===\n";
$statuses = $pr->distinct('status');
echo implode(', ', $statuses) . "\n";

echo "\n=== Total docs by status ===\n";
foreach ($statuses as $s) {
    $c = $pr->countDocuments(['status' => $s]);
    echo "  $s: $c\n";
}
