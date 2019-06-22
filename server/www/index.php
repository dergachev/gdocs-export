<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);

define('GDOCS_DIR', "/var/gdocs-export");
define('KEY', "ThisIsASuperSecrectKey");

include('includes/Message.php');

$errors = array();
// Check for security key
if(!isset($_GET['key']) ||
  !(isset($_GET['key']) && $_GET['key'] === KEY)) {
    $errors[] = 'Key not found';
}
if(!isset($_GET['doc_id'])) $errors[] = 'Doc ID not found';
if(!isset($_GET['doc_name'])) $errors[] = 'Doc name not found';

if(!empty($errors)) {
  $message = new Message(400, 'Bad Request', $errors);
  $message->render();
}

// All good, move on to generate the fancy PDF
$doc_id = $_GET['doc_id'];
$doc_name = time() . '--' . $_GET['doc_name'];
$theme = (isset($_GET['theme'])) ? $_GET['theme'] : 'default';

$command = GDOCS_DIR . "/server/scripts/web-convert-gdoc.sh {$doc_id} {$doc_name} {$theme}";
$output = system($command);


if(file_exists(GDOCS_DIR . '/server/www/output/' . $doc_name . '.pdf')) {
  $url = $_SERVER['REQUEST_SCHEME'] . '://' . $_SERVER['HTTP_HOST'] . '/output/' . $doc_name . '.pdf';
  $message = new Message(200, 'Success', array(), array('file' => $url));
  $message->render();
} else {
  $text = "File {$doc_name}.pdf failed to generate";
  $message = new Message(403, 'Error', array($text));
  $message->render();
}
