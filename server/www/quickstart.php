<?php
require __DIR__ . '/vendor/autoload.php';

if (php_sapi_name() != 'cli') {
    throw new Exception('This application must be run on the command line.');
}

/**
 * Returns an authorized API client.
 * @return Google_Client the authorized client object
 */
function getClient()
{
    $client = new Google_Client();
    $client->setApplicationName('Google Drive API PHP Quickstart');
    $client->setScopes(Google_Service_Drive::DRIVE_READONLY);
    $client->setAuthConfig('credentials.json');
    $client->setAccessType('offline');

    // Load previously authorized credentials from a file.
    $credentialsPath = 'token.json';
    if (file_exists($credentialsPath)) {
        $accessToken = json_decode(file_get_contents($credentialsPath), true);
    } else {
        // Request authorization from the user.
        $authUrl = $client->createAuthUrl();
        printf("Open the following link in your browser:\n%s\n", $authUrl);
        print 'Enter verification code: ';
        $authCode = trim(fgets(STDIN));

        // Exchange authorization code for an access token.
        $accessToken = $client->fetchAccessTokenWithAuthCode($authCode);

        // Store the credentials to disk.
        if (!file_exists(dirname($credentialsPath))) {
            mkdir(dirname($credentialsPath), 0700, true);
        }
        file_put_contents($credentialsPath, json_encode($accessToken));
        printf("Credentials saved to %s\n", $credentialsPath);
    }
    $client->setAccessToken($accessToken);

    // Refresh the token if it's expired.
    if ($client->isAccessTokenExpired()) {
        $client->fetchAccessTokenWithRefreshToken($client->getRefreshToken());
        file_put_contents($credentialsPath, json_encode($client->getAccessToken()));
    }
    return $client;
}


// Get the API client and construct the service object.
$client = getClient();
$service = new Google_Service_Drive($client);

// $fileId = '1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds';
$fileId = '1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds';
$response = $service->files->export($fileId, 'text/html');

$content = $response->getBody();

$file = '/var/gdocs-export/input/test.html';
$fp = fopen($file, 'wb');
fwrite($fp, $content);
fclose($fp);


//print $content;

// $content = $response->getBody()->getContents();
// print $content;


// $results = $service->files->listFiles($optParams);
//
// if (count($results->getFiles()) == 0) {
//     print "No files found.\n";
// } else {
//     print "Files:\n";
//     foreach ($results->getFiles() as $file) {
//         printf("%s (%s)\n", $file->getName(), $file->getId());
//     }
// }
