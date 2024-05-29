## @meta-authors TODO
## @meta-authors TODO
## @meta-version 2.3
## A reference to a Firestore Collection.
## Documentation TODO.
@tool
class_name FirestoreCollection
extends Node

signal add_document(doc)
signal get_document(doc)
signal update_document(doc)
signal commit_document(result)
signal delete_document(deleted)
signal error(code,status,message)

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "

const _separator : String = "/"
const _query_tag : String = "?"
const _documentId_tag : String = "documentId="

var auth : Dictionary
var collection_name : String

var _base_url : String
var _extended_url : String
var _config : Dictionary

var _documents := {}
var _request_queues := {}

# ----------------------- Requests

## @args document_id
## @return FirestoreTask
## used to GET a document from the collection, specify @document_id
func get_doc(document_id : String) -> FirestoreTask:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_GET
	task.data = collection_name + "/" + document_id
	var url = _get_request_url() + _separator + document_id.replace(" ", "%20")

	task.get_document.connect(_on_get_document)
	task.task_finished.connect(_on_task_finished.bind(document_id), CONNECT_DEFERRED)
	_process_request(task, document_id, url)
	return task

## @args document_id, fields
## @arg-defaults , {}
## @return FirestoreTask
## used to SAVE/ADD a new document to the collection, specify @documentID and @fields
func add(document_id : String, data : Dictionary = {}) -> FirestoreTask:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_POST
	task.data = collection_name + "/" + document_id
	var url = _get_request_url() + _query_tag + _documentId_tag + document_id

	task.add_document.connect(_on_add_document)
	task.task_finished.connect(_on_task_finished.bind(document_id), CONNECT_DEFERRED)
	_process_request(task, document_id, url, JSON.stringify(Utilities.dict2fields(data)))
	return task

## @args document_id, fields
## @arg-defaults , {}
## @return FirestoreTask
# used to UPDATE a document, specify @documentID, @fields
func update(document : FirestoreDocument) -> FirestoreTask:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_PATCH
	task.data = collection_name + "/" + document.doc_name
	var url = _get_request_url() + _separator + document.doc_name.replace(" ", "%20") + "?"
	for key in document.keys():
		url+="updateMask.fieldPaths={key}&".format({key = key})
			
	url = url.rstrip("&")
	
	for key in document.keys():
		if document.get_value(key) == null:
			document._erase(key)
	
	task.update_document.connect(_on_update_document)
	task.task_finished.connect(_on_task_finished.bind(document.doc_name), CONNECT_DEFERRED)
	
	var body = JSON.stringify({"fields": document.document}, " ")
	
	_process_request(task, document.doc_name, url, body)
	return task
	
func commit(document : FirestoreDocument) -> FirestoreTask:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_COMMIT
	var url = get_database_url("commit")
	task.commit_document.connect(_on_commit_document)
	task.task_finished.connect(_on_task_finished.bind(document.doc_name), CONNECT_DEFERRED)

	document._transforms.set_config(
		{
		  "extended_url": _extended_url,
		  "collection_name": collection_name
		}
	) # Only place we can set this is here, oofness
	
	var body = document._transforms.serialize()
	_process_request(task, document.doc_name, url, JSON.stringify(body))
	return task

## @args document_id
## @return FirestoreTask
# used to DELETE a document, specify @document_id
func delete(document_id : String) -> FirestoreTask:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_DELETE
	task.data = collection_name + "/" + document_id
	var url = _get_request_url() + _separator + document_id.replace(" ", "%20")

	task.delete_document.connect(_on_delete_document)
	task.task_finished.connect(_on_task_finished.bind(document_id), CONNECT_DEFERRED)
	_process_request(task, document_id, url)
	return task

# ----------------- Functions
func _get_request_url() -> String:
	return _base_url + _extended_url + collection_name


func _process_request(task : FirestoreTask, document_id : String, url : String, fields := "") -> void:
	if not task.task_error.is_connected(_on_error):
		task.task_error.connect(_on_error)

	if auth == null or auth.is_empty():
		Firebase._print("Unauthenticated request issued...")
		Firebase.Auth.login_anonymous()
		var result : Array = await Firebase.Auth.auth_request
		if result[0] != 1:
			Firebase.Firestore._check_auth_error(result[0], result[1])
			return
		Firebase._print("Client authenticated as Anonymous User.")

	task._url = url
	task._fields = fields
	task._headers = PackedStringArray([_AUTHORIZATION_HEADER + auth.idtoken])
	if _request_queues.has(document_id) and not _request_queues[document_id].is_empty():
		_request_queues[document_id].append(task)
	else:
		_request_queues[document_id] = []
		Firebase.Firestore._pooled_request(task)

func _on_task_finished(task : FirestoreTask, document_id : String) -> void:
	if not _request_queues[document_id].is_empty():
		task._push_request(task._url, _AUTHORIZATION_HEADER + auth.idtoken, task._fields)

# -------------------- Higher level of communication with signals
func _on_get_document(document : FirestoreDocument):
	get_document.emit(document)

func _on_add_document(document : FirestoreDocument):
	document.collection_name = collection_name
	add_document.emit(document)

func _on_update_document(document : FirestoreDocument):
	update_document.emit(document)

func _on_delete_document(deleted):
	delete_document.emit(deleted)

func _on_error(code, status, message, task):
	error.emit(code, status, message)
	Firebase._printerr(message)

func _on_commit_document(result):
	commit_document.emit(result)

func _add_document_listener(document_path : String, with_func : Callable):
	var listener = preload("res://addons/godot-firebase/firestore/firestore_listener.tscn").instantiate()
	add_child(listener)
	return listener.connect_to_firestore(_config) 

func get_database_url(append) -> String:
	return _base_url + _extended_url.rstrip("/") + ":" + append
