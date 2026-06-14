<?php

$userId = "8pip2a2e";
$userToken = "lEEuNf9x65zOD76yPSl6wqWl";

$contacts = [
    [
        "mobile" => "9514544541",
        "studentname" => "SOS ALERT FROM LIFE LINK - ARUN",
        "startdate" => "7 March 2026",
        "enddate" => "Chennai Saveetha University"
    ]
];

$ivrData = [
    "#4" => [
        "LANGUAGE" => "TA",
        "VALUE" => "{#studentname#}",
        "TYPE" => "T"
    ],
    "#10" => [
        "LANGUAGE" => "TA",
        "VALUE" => "{#startdate#}",
        "TYPE" => "T"
    ],
    "#11" => [
        "LANGUAGE" => "TA",
        "VALUE" => "{#enddate#}",
        "TYPE" => "T"
    ]
];

$params = [
    "userId" => $userId,
    "userToken" => $userToken,
    "includesCountryCode" => "N",
    "apiType" => "dynamicIvr",
    "cli" => "[]",
    "ivrId" => "1976",
    "planId" => "12",
    "planType" => "C",
    "inputWaitTime" => 0,
    "ivrData" => json_encode($ivrData),
    "route" => "transactional",
    "contacts" => json_encode($contacts),
    "callback_url" => "",
    "extraParameters" => "{}",
    "extraParametersIndex" => "N"
];

$url = "https://voice.mydreamstechnology.in/vb-api/v2/broadcasting?" . http_build_query($params);

$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "session-token: $userToken"
]);

$response = curl_exec($ch);

curl_close($ch);

echo $response;

?>