class_name FirestoreListener
extends Node

var http_client = HTTPClient.new()

var project_id = "roundtable-5c241"
var collection_path = "Firebasetester"
var document_id = "Document1"
var connected = false
var api_key

var response_body = PackedByteArray()

var host

var request_to_send : Callable
var request_sent := false

func _ready():
	set_process(false)

func connect_to_firestore(config):
	project_id = config.projectId.uri_encode()
	api_key = config.apiKey
	host = "firestore.googleapis.com"
	var port = 443  # Use port 443 for HTTPS
	var tlsoptions = TLSOptions.client(null, "")
	
	var err = http_client.connect_to_host(host, port, tlsoptions)
	if err != OK:
		print("Failed to connect to host: ", err)
	else:
		print("Connected to host")
		set_process(true)  # Start polling
		
		var path = "/google.firestore.v1.Firestore/Listen/channel" + "?VER=8&database=projects%2Froundtable-5c241%2Fdatabases%2F(default)&RID=97627&CVER=22&X-HTTP-Session-Id=gsessionid&zx=cjl2twashomb&t=1"
		var body = {
				"addTarget":
				{
					"documents":
					{
						"documents": ["projects/%s/databases/(default)/documents/%s/%s" % [project_id, collection_path, document_id]]
					}
				}
			}
				
		var encoded_body = encode_body(body)
		encoded_body = "&req0___data__=" + encoded_body
		
		var headers = [
			"Authorization: Bearer %s" % Firebase.Auth.auth.idtoken,
			"Content-Type: x-www-form-urlencoded",
			"Content-Length: " + str(encoded_body.length()),
			":authority: firestore.googleapis.com",
			":method: POST",
			":path: /google.firestore.v1.Firestore/Listen/channel?VER=8&database=projects%2Froundtable-5c241%2Fdatabases%2F(default)&RID=97627&CVER=22&X-HTTP-Session-Id=gsessionid&zx=cjl2twashomb&t=1",
			":scheme: https",
		]
		
		print("Final path: ", path)
		set_process(true)
		request_to_send = func(): send_request(path, headers, encoded_body)
		
	return self

func _process(delta: float) -> void:
	var status = http_client.get_status()
	if status in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_REQUESTING]:
		http_client.poll()
		return
	
	if http_client.get_status() == HTTPClient.STATUS_BODY:
		http_client.poll()
		response_body += http_client.read_response_body_chunk()
		OS.delay_msec(50)

	if http_client.has_response():
		var response_code = http_client.get_response_code()
		var response_headers = http_client.get_response_headers_as_dictionary()
		var response_body = PackedByteArray()
		
		if response_code == 200:
			print("Response code: ", response_code)
			print("Response headers: ", response_headers)
			if response_body.size() == 0:
				print("Request returned size zero")
			else:
				var response_json = Utilities.get_json_data(response_body)
				if response_json.error == OK:
					var response_data = response_json.result
					print("Request successful: %s" % response_data)
				else:
					print("JSON parse error: %s" % response_json.error_string)
		else:
			print("Request failed with status code: %s" % response_code)
			print("Response body: %s" % Utilities.get_json_data(response_body))
		
		return
	
	if status != HTTPClient.STATUS_CONNECTED:
		print("Failed to connect")
		set_process(false)
		return
	
	if not request_sent:
		request_to_send.call()
		request_sent = true
	
func send_request(url, headers, body):
	http_client.request(HTTPClient.METHOD_POST, url, headers, body)

func encode_body(body : Dictionary) -> String:
	var query_string = []
	for key in body.keys():
		var value = body[key]
		if typeof(value) == TYPE_DICTIONARY:
			value = JSON.stringify(value)
		
		value = value.replace("\"", "")
		key = key.replace("\"", "")
		query_string.append(key.uri_encode() + "=".uri_encode() + value.uri_encode())
	return "&".join(query_string)

func handle_response(chunk):
	var response_text = chunk.get_string_from_utf8()
	print("Received chunk: ", response_text)
	var response_json = Utilities.get_json_data(response_text)
	if response_json.error == OK:
		print("Parsed JSON: ", response_json.result)
	else:
		print("Failed to parse JSON: ", response_json.error_string())

class FirestoreListenerConnection extends RefCounted:
	var connection
	
	func _init(connection_node):
		connection = connection_node
	
	func stop():
		connection.tcp_client.disconnect_from_host()
		connection.free()
