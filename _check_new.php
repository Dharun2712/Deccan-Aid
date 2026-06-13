<?php
require __DIR__ . '/vendor/autoload.php';
$client = new MongoDB\Client('mongodb+srv://Dharun:Dharun2712@cluster0.yr5quzl.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0');
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
