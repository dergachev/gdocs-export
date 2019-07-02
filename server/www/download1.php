<?php

// echo date('Y-m');
// exit();

require __DIR__ . '/vendor/autoload.php';

$client = new Google_Client();
$client->setApplicationName('Google Drive API PHP Quickstart');
$client->setScopes(Google_Service_Drive::DRIVE_READONLY);
$client->setAuthConfig('credentials.json');
$client->setAccessType('offline');
//

if(file_exists('token.json')) {
  $token = json_decode(file_get_contents('token.json'));
  $client->setAccessToken($token->access_token);
}

// Build service
$service = new Google_Service_Drive($client);

$doc_id = $_GET['doc_id'];
$doc_name = date('Ymd') . '--' . $_GET['doc_name'];
$theme = (isset($_GET['theme'])) ? $_GET['theme'] : 'default';

$response = $service->files->export($doc_id, 'text/html');
$content = $response->getBody();

$input_folder = date('Y-m');

$file = "/var/gdocs-export/input/{$input_folder}/{$doc_name}.html";
$fp = fopen($file, 'wb');
fwrite($fp, $content);
fclose($fp);

$command = "cd /var/gdocs-export && make convert FILE_NAME={$doc_name} THEME=ew";
shell_exec($command);

echo 'Done';
