<?php
require __DIR__ . '/vendor/autoload.php';
$mongoUri = getenv('MONGODB_URI') ?: '';
if ($mongoUri === '') {
    die("MONGODB_URI is not set in environment\n");
}

$client = new MongoDB\Client($mongoUri);
$db = $client->selectDatabase('smart_ambulance');

echo "=== ambulance_drivers (all docs) ===\n";
$drivers = $db->selectCollection('ambulance_drivers')->find(
    [],
    ['typeMap'=>['root'=>'array','document'=>'array','array'=>'array']]
);
foreach ($drivers as $d) {
    echo "---\n";
    print_r($d);
}

echo "\n=== Total drivers: ".$db->selectCollection('ambulance_drivers')->countDocuments()." ===\n";
