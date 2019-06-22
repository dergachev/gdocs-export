<?php

class Message {
  protected $code;
  protected $message;
  protected $data;

  function __construct($code, $message, $errors = array(), $data = array()) {
    $this->code = $code;
    $this->message = $message;
    $this->errors = $errors;
    $this->data = $data;
  }

  function render() {
    http_response_code($this->code);
    $response = array(
      'code' => $this->code,
      'message' => $this->message,
      'errors' => $this->errors,
      'data' => $this->data,
    );
    print json_encode($response);
    exit();
  }
}
