extends Node2D

# Script used for testing the Firestore functions of the plugin

# Variables
@onready var _test_running = false
@onready var console = $console
var _collection : FirestoreCollection
var _document : FirestoreDocument

# Constants 
const _email : String = 'testaccount@godotnuts.test'
const _password : String = 'Password1234'

var listener_test_count := 0

# Function called when the scene is ready
func _ready():
	Firebase.Auth.login_succeeded.connect(_on_FirebaseAuth_login_succeeded)
	Firebase.Auth.login_failed.connect(_on_login_failed)

# Function called when the test starts 
# Clears all checkboxes to clean the GUI
# Disbales all buttons in the GUI to allow the test to run uninterupted 
func _test_started() -> void:
	_test_running = true
	var checkboxes = get_tree().get_nodes_in_group('tests')
	for box in checkboxes:
		box.button_pressed = false
	$back.disabled = true
	$test_firestore.disabled = true

# Function called when the tests are finsihed
# Re-enables all buttons in the GUI
func _test_finished() -> void:
	_test_running = false
	$back.disabled = false
	$test_firestore.disabled = false

# Function called if there is an error in the test
# Prints the error to the GUI console so the end user can see
func _test_error(data) -> void:
	_print_to_console_error(data)
	_test_finished()

func _cleanup_previous_run():
	var del_task : FirestoreTask = _collection.delete("Document1")
	var deleted = await del_task.delete_document

# Function called when login to Firebase has completed successfully
func _on_FirebaseAuth_login_succeeded(_auth) -> void:
	_print_to_console("Login with email and password has worked")
	$login_check.button_pressed = true
	_test_firestore()

# Function called when login to Firebase has failed
# Ends the test and prints the error to the GUI console
func _on_login_failed(error_code, message):
	_print_to_console_error("error code: " + str(error_code))
	_print_to_console_error("message: " + str(message))
	_test_error("Login Failed")

# Function called when the end user presses the 'Test Auth' button
# Starts the test
func _on_test_firestore_pressed():
	_test_started()
	Firebase.Auth.login_with_email_and_password(_email, _password)

# Main function that is run when testing Firestore
func _test_firestore() -> void:
	# Print to the console GUI that the test is starting
	_print_to_console("\nSTARTING FIRESTORE TESTS")
	
	# Connect to the test collection
	_print_to_console("\nConnecting to collection 'Firebasetester'")
	_collection = Firebase.Firestore.collection('Firebasetester')
	
	# Connect to signals needed for testing
	_collection.add_document.connect(on_document_add)
	_collection.get_document.connect(on_document_get)
	_collection.update_document.connect(on_document_update)
	_collection.delete_document.connect(on_document_delete)
	_collection.error.connect(on_document_error)
	#await _cleanup_previous_run()
	# Add Document1 to Firestore
	#_print_to_console("Trying to add a document")
	#var add_task : FirestoreTask = _collection.add("Document1", {'name': 'Document1', 'active': 'true', "server_timestamp_attempt": null, "increment_field": 0, "decrement_field": 0, "max_field": 5, "min_field": 2 })
	#_document = await add_task.add_document
	#$add_document.button_pressed = true
	#
	## Get Document1 (Document that has been added from the previous step)
	#_print_to_console("Trying to get Document1")
	var get_task = _collection.get_doc('Document1')
	_document = await _collection.get_document
	#if(_document == null):
		#_test_error("Failed to get document")
		#return
	#else:
		#$get_document.button_pressed = true
	#
	## Print Document1 to the console GUI
	#_print_to_console("Trying to print contents of Document1")
	#_print_to_console(_document)
	#$print_document.button_pressed = true
	#
	#var timestamp_transform = ServerTimestampTransform.new(_document.doc_name, true, "server_timestamp_attempt")
	#var increment_transform = IncrementTransform.new(_document.doc_name, true, "increment_field", 2)
	#var decrement_transform = DecrementTransform.new(_document.doc_name, true, "decrement_field", 2)
	#var max_transform = MaxTransform.new(_document.doc_name, true, "max_field", 10) # Should update
	#var min_transform = MinTransform.new(_document.doc_name, true, "min_field", -2) # Should update
	#_document.add_field_transform(timestamp_transform)
	#_document.add_field_transform(increment_transform)
	#_document.add_field_transform(decrement_transform)
	#_document.add_field_transform(max_transform)
	#_document.add_field_transform(min_transform)
	#var up_task = _collection.commit(_document)
	#var result = await up_task.commit_document
	#
	#get_task = _collection.get_doc('Document1')
	#_document = await _collection.get_document
	#
	### Print Document1 to the console GUI
	#_print_to_console("Trying to print contents of Document1 after transform")
	#_print_to_console(_document)
	#$print_document_2.button_pressed = true
	#
	#_print_to_console("Attempting to remove item from Document1")
	#var key = "name"
	#_document.remove_field(key)
	#
	#_print_to_console("Key erased: " + key)
	#_print_to_console("Document now:\n" + str(_document))
	#_print_to_console("\n")
	#
	#var previous_document_size = _document.keys().size()
	#
	#var delete_item_from_document_task : FirestoreTask = _collection.update(_document)
	#await delete_item_from_document_task.update_document
	#
	#get_task = _collection.get_doc('Document1')
	#_document = await _collection.get_document
	
	#_print_to_console("Document now:\n" + str(_document))
	#if previous_document_size == _document.keys().size():
		#_print_to_console_error("Did not properly delete item from document")
	#
	#_print_to_console("Previous document keys count: " + str(previous_document_size))
	#_print_to_console("Document keys count: " + str(_document.keys().size()))
	#
	## Delete Document1 from Firestore
	#_print_to_console("Trying to delete Document1")
	#var del_task : FirestoreTask = _collection.delete("Document1")
	#var deleted = await del_task.delete_document
	#$delete_document.button_pressed = true
	#
	## Query Collection
	#_print_to_console("\nRunning Firestore Query")
	#var query : FirestoreQuery = FirestoreQuery.new()
	#query.from("Firebasetester")
	#query.where("points", FirestoreQuery.OPERATOR.GREATER_THAN, 5)
	#query.order_by("points", FirestoreQuery.DIRECTION.DESCENDING)
	#query.limit(10)
	#var query_task : FirestoreTask = Firebase.Firestore.query(query)
	#result = await query_task.result_query
	#_print_to_console(result)
	#$run_query.button_pressed = true
	
	_print_to_console("Running listener tests")
	#await _cleanup_previous_run()
	
	await run_listener_tests()
	
	# If nothing has failed to this point, finish the test successfully
	_print_to_console("\nFINISHED FIRESTORE TESTS")
	_test_finished()

func run_listener_tests() -> void:
	#var add_task : FirestoreTask = _collection.add("Document1", {'name': 'Document1', 'active': 'true', "server_timestamp_attempt": null, "increment_field": 0, "decrement_field": 0, "max_field": 5, "min_field": 2 })
	#_document = await add_task.add_document
	listener_test_count = 0
	var listener = _document.on_snapshot(func(result): print(result))
	await get_tree().create_timer(5.0).timeout
	
	const new_doc_name = 'NewDocument'
	
	_document.add_or_update_field("name", new_doc_name)
	
	var update_task : FirestoreTask = _collection.update(_document)
	_document = await update_task.update_document
	#
	#var timestamp_transform = ServerTimestampTransform.new(_document.doc_name, true, "server_timestamp_attempt")
	#var increment_transform = IncrementTransform.new(_document.doc_name, true, "increment_field", 2)
	#var decrement_transform = DecrementTransform.new(_document.doc_name, true, "decrement_field", 2)
	#var max_transform = MaxTransform.new(_document.doc_name, true, "max_field", 10) # Should update
	#var min_transform = MinTransform.new(_document.doc_name, true, "min_field", -2) # Should update
	#_document.add_field_transform(timestamp_transform)
	#_document.add_field_transform(increment_transform)
	#_document.add_field_transform(decrement_transform)
	#_document.add_field_transform(max_transform)
	#_document.add_field_transform(min_transform)
	#var up_task = _collection.commit(_document)
	#var result = await up_task.commit_document
	#
	#
	await get_tree().create_timer(10.0).timeout
	var get_task = _collection.get_doc('Document1')
	_document = await _collection.get_document
	
	
	_print_to_console("Count outside: " + str(listener_test_count))
	
	#listener.stop()
	
	
	_document.add_or_update_field("name", new_doc_name + "2")
	
	update_task = _collection.update(_document)
	_document = await update_task.update_document
	
	_print_to_console("Count: " + str(listener_test_count))
	
	

# Function called when a document has been added to Firestore successfully
func on_document_add(document_added : FirestoreDocument) -> void:
	_print_to_console("Document added successfully")

# Function called when a document has been retrived from Firestore successfully
func on_document_get(document_got : FirestoreDocument) -> void:
	_print_to_console("Document got successfully")

# Function called when a document has been updated in Firestore successfully
func on_document_update(document_updated : FirestoreDocument) -> void:
	#_print_to_console("Current document after update: " + str(document_updated))
	_print_to_console("Document Updated successfully")

# Function called when a document has been deleted in Firestore successfully
func on_document_delete(deleted) -> void:
	_print_to_console("Document deleted: " + str(deleted))

# Function called when a function with Firestore has failed
func on_document_error(code, status, message) -> void:
	_print_to_console_error("error code: " + str(code))
	_print_to_console_error("message: " + str(message))
	_test_error("There was an issue")

# Function used to print data to the console GUI for the end user
func _print_to_console(data):
	data = str(data)
	print(data)
	var previous_data = console.text
	var updated_data = previous_data + data + "\n"
	console.text = updated_data

# Function used to print error data to the console GUI for the end user
func _print_to_console_error(data):
	data = str(data)
	printerr(data)
	var previous_data = console.text
	var updated_data = previous_data + "[color=red]" + data + "[/color] \n"
	console.text = updated_data

# Function called when the end user presses the 'Back' button, returns to the Main Menu
func _on_back_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
