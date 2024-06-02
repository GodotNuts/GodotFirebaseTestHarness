class_name FirestoreListener
extends Node
#
##var http_client = HTTPClient.new()
#
#var tcp_stream = StreamPeerTCP.new()
#var tls_stream = StreamPeerTLS.new()
#
#var project_id = "roundtable-5c241"
#var collection_path = "Firebasetester"
#var document_id = "Document1"
#var connected = false
#var api_key
#
#var response_body = PackedByteArray()
#
#var host
#
#var request_to_send : Callable
#var request_sent := false
#
#func _ready():
	#set_process(false)
#
#func connect_to_firestore(config):
	#
	#
	#project_id = config.projectId.uri_encode()
	#api_key = config.apiKey
	#host = "firestore.googleapis.com"
	#var port = 443  # Use port 443 for HTTPS
	#var tlsoptions = TLSOptions.client_unsafe()
	#
	#var err = tcp_stream.connect_to_host(host, port)
	##var err = http_client.connect_to_host(host, port, tlsoptions)
	#if err != OK:
		#print("Failed to connect to host: ", err)
	#else:
		#print("Connected to host")
		#
		#err = tls_stream.connect_to_stream(tcp_stream, "", tlsoptions)
		#if err != OK:
			#print("Something went wrong with the TLS handshake")
			#print("Error: ", err)
			#return
			#
		#if tls_stream.get_status() != StreamPeerTLS.STATUS_CONNECTED:
			#print("TLS handshake failed")
			#return		
				#
		#var path = "/google.firestore.v1.Firestore/Listen/channel" + "?VER=8&database=projects%2Froundtable-5c241%2Fdatabases%2F(default)&RID=97627&CVER=22&X-HTTP-Session-Id=gsessionid&zx=cjl2twashomb&t=1"
		#var body = {
				#"addTarget":
				#{
					#"documents":
					#{
						#"documents": ["projects/%s/databases/(default)/documents/%s/%s" % [project_id, collection_path, document_id]]
					#}
				#}
			#}
				#
		#var encoded_body = encode_body(body)
		#encoded_body = "&req0___data__=" + encoded_body
		#
		#var headers = [
			#"Authorization: Bearer %s" % Firebase.Auth.auth.idtoken,
			#"Content-Type: x-www-form-urlencoded",
			#"Content-Length: " + str(encoded_body.length()),
			#":authority: firestore.googleapis.com",
			#":method: POST",
			#":path: /google.firestore.v1.Firestore/Listen/channel?VER=8&database=projects%2Froundtable-5c241%2Fdatabases%2F(default)&RID=97627&CVER=22&X-HTTP-Session-Id=gsessionid&zx=cjl2twashomb&t=1",
			#":scheme: https",
		#]
		#
		#var request = "POST %s HTTP/2.0\r\n" % path
		#request += "\r\n".join(headers)
		#request += encoded_body
		#
		#print("Final path: ", path)
		#set_process(true)
		#send_request(request)
		#
	#return self
#
#func _process(delta: float) -> void:
	#if not request_sent:
		#return
	#
	#if tls_stream.get_available_bytes() > 0:
		#var chunk = tls_stream.read(tls_stream.get_available_bytes())
		#response_body += chunk.get_utf8_string()
		#print("Response body: ", response_body)
	#
#func send_request(request : String):
	#var err = tls_stream.put_data(request.to_utf8_buffer())
	#if err != OK:
		#print("Error sending: ", request)
	#else:
		#request_sent = true
#
#func encode_body(body : Dictionary) -> String:
	#var query_string = []
	#for key in body.keys():
		#var value = body[key]
		#if typeof(value) == TYPE_DICTIONARY:
			#value = JSON.stringify(value)
		#
		#value = value.replace("\"", "")
		#key = key.replace("\"", "")
		#query_string.append(key.uri_encode() + "=".uri_encode() + value.uri_encode())
	#return "&".join(query_string)
#
#func handle_response(chunk):
	#var response_text = chunk.get_string_from_utf8()
	#print("Received chunk: ", response_text)
	#var response_json = Utilities.get_json_data(response_text)
	#if response_json.error == OK:
		#print("Parsed JSON: ", response_json.result)
	#else:
		#print("Failed to parse JSON: ", response_json.error_string())

signal document_updated(snapshot : Dictionary)

const MinPollTime = 60 # seconds

var _doc_name : String
var _tracked_changes : Dictionary
var _poll_time : float
var _collection : FirestoreCollection

var _timer = Timer.new()
var _total_time = 0.0

var _is_requesting_update := false

func _init(document : FirestoreDocument, poll_time : float) -> void:
	_poll_time = max(poll_time, MinPollTime)
	_tracked_changes = document._changes.duplicate()
	_doc_name = document.doc_name
	_collection = Firebase.Firestore.collection(document.collection_name)
	
	add_child(_timer)
	
func enable_connection() -> FirestoreListenerConnection:
	_timer.wait_time = 1
	_timer.timeout.connect(_update_document, CONNECT_REFERENCE_COUNTED)
	_timer.start()
	return FirestoreListenerConnection.new(self)

func _update_document():
	_total_time += _timer.wait_time
	var stored_doc = await _collection.get_doc(_doc_name, _total_time <= _poll_time)
	if stored_doc != null:
		var result = stored_doc._changes
		
		if _tracked_changes != result:
			document_updated.emit(_tracked_changes)
			_tracked_changes = result.duplicate()
	else:
		var result = {
			"deleted": { _doc_name: "" } # Not sure if this works, find out what happens when you delete a document and attempt to get it
		}
		
		document_updated.emit(result)
		_timer.stop()
	
	if _total_time > _poll_time:
		_total_time = 0.0
	
class FirestoreListenerConnection extends RefCounted:
	var connection
	
	func _init(connection_node):
		connection = connection_node
	
	func stop():
		if connection != null and is_instance_valid(connection):
			connection.free()
