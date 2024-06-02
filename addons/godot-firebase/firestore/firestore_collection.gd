## @meta-authors TODO
## @meta-authors TODO
## @meta-version 2.3
## A reference to a Firestore Collection.
## Documentation TODO.
@tool
class_name FirestoreCollection
extends Node

signal error(error_result)

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

# ----------------------- Requests

## @args document_id
## @return FirestoreTask
## used to GET a document from the collection, specify @document_id
func get_doc(document_id : String, from_cache : bool = false, update_cache : bool = false) -> FirestoreDocument:
	if from_cache:
		# for now, just return the child directly; in the future, make it smarter so there's a default, if long, polling time for this
		for child in get_children():
			if child.doc_name == document_id:
				return child
		
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_GET
	task.data = collection_name + "/" + document_id
	var url = _get_request_url() + _separator + document_id.replace(" ", "%20")

	_process_request(task, document_id, url)
	var result = await Firebase.Firestore._handle_task_finished(task)
	if result != null:
		result.collection_name = collection_name
		if result != null:
			var changes = {"added":[], "changed":[], "removed":[]}
			for child in get_children():
				if child.doc_name == document_id:
					var child_listener = result.get_child(0) if result.get_child_count() == 1 else null
					if child_listener != null:
						changes = child._changes.duplicate()
						child.remove_child(child_listener) # Transfer the listener over so it's not freed all the way through
						result.add_child(child_listener)
						child.queue_free()
						
			result._changes = changes
			add_child(result)
	else:
		print("get_document returned null for %s %s" % [collection_name, document_id])
		
	return result

## @args document_id, fields
## @arg-defaults , {}
## @return FirestoreTask
## used to SAVE/ADD a new document to the collection, specify @documentID and @fields
func add(document_id : String, data : Dictionary = {}) -> FirestoreDocument:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_POST
	task.data = collection_name + "/" + document_id
	var url = _get_request_url() + _query_tag + _documentId_tag + document_id

	_process_request(task, document_id, url, JSON.stringify(Utilities.dict2fields(data)))
	var result = await Firebase.Firestore._handle_task_finished(task)
	if result != null:
		for child in get_children():
			if child.doc_name == document_id:
				child.free() # Consider throwing an error for this since it should already exist
				break
			
		add_child(result)
		result.collection_name = collection_name
	return result
	
## @args document_id, fields
## @arg-defaults , {}
## @return FirestoreTask
# used to UPDATE a document, specify @documentID, @fields
func update(document : FirestoreDocument, update_cache := false) -> FirestoreDocument:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_PATCH
	task.data = collection_name + "/" + document.doc_name
	var url = _get_request_url() + _separator + document.doc_name.replace(" ", "%20") + "?"
	for key in document.keys():
		url+="updateMask.fieldPaths={key}&".format({key = key})
			
	url = url.rstrip("&")
	
	for key in document.keys():
		if document.get_value(key) == null and not document.is_null_value(key):
			document._erase(key)
	
	var body = JSON.stringify({"fields": document.document})
	
	_process_request(task, document.doc_name, url, body)
	return await Firebase.Firestore._handle_task_finished(task)
	
func commit(document : FirestoreDocument) -> Dictionary:
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_COMMIT
	var url = get_database_url("commit")
	
	document._transforms.set_config(
		{
		  "extended_url": _extended_url,
		  "collection_name": collection_name
		}
	) # Only place we can set this is here, oofness
	
	var body = document._transforms.serialize()
	_process_request(task, document.doc_name, url, JSON.stringify(body))
	return await Firebase.Firestore._handle_task_finished(task)

## @args document_id
## @return FirestoreTask
# used to DELETE a document, specify @document_id
func delete(document : FirestoreDocument) -> bool:
	var doc_name = document.doc_name
	var task : FirestoreTask = FirestoreTask.new()
	task.action = FirestoreTask.Task.TASK_DELETE
	task.data = document.collection_name + "/" + doc_name
	var url = _get_request_url() + _separator + doc_name.replace(" ", "%20")
	_process_request(task, doc_name, url)
	var result = await Firebase.Firestore._handle_task_finished(task)
	#if result:
		#for node in get_children():
			#if node.doc_name == doc_name:
				#node.free()
				#break
	
	return result

# ----------------- Functions
func _get_request_url() -> String:
	return _base_url + _extended_url + collection_name


func _process_request(task : FirestoreTask, document_id : String, url : String, fields := "") -> void:
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
	Firebase.Firestore._pooled_request(task)

func _add_document_listener(document : FirestoreDocument, poll_time : float = 200.0):
	var doc = document
	if doc == null:
		assert(false, "Document must be gotten at least once before listening to changes for it with a listener")
		return
		
	if doc.get_child_count() >= 1: # Only one listener per
		assert(false, "Multiple listeners not allowed for the same document yet")
		return
	
	var listener = FirestoreListener.new(doc, poll_time)
	doc.add_child(listener)
	return listener.enable_connection()

func get_database_url(append) -> String:
	return _base_url + _extended_url.rstrip("/") + ":" + append
