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

var DefaultDocument = { 'name': 'Document1', 'points': 20, 'crud': { 'something': 'other thing', 'main': { 'info' : 8 }}, 'active': 'true', "server_timestamp_attempt": null, "increment_field": 0, "decrement_field": 0, "max_field": 5, "min_field": 2 }

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
	var previous_run = await _collection.get_doc("Document1")
	if previous_run != null:
		var deleted = await _collection.delete(previous_run)
		if deleted:
			_print_to_console("Document1 deleted")
	
# Function called when login to Firebase has completed successfully
func _on_FirebaseAuth_login_succeeded(_auth) -> void:
	_print_to_console("Login with email and password has worked")
	$login_check.button_pressed = true
	await _test_firestore()

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
	
	await _cleanup_previous_run()
	# Add Document1 to Firestore
	_print_to_console("Trying to add a document")
	_document = await _collection.add("Document1", DefaultDocument)
	$add_document.button_pressed = true
	
	_print_to_console("Printing crud")
	var value = _document.get_value('crud')
	_print_to_console(value)
	
	## Get Document1 (Document that has been added from the previous step)
	_print_to_console("Trying to get Document1")
	_document = await _collection.get_doc('Document1')
	
	if(_document == null):
		_test_error("Failed to get document")
		return
		
	_document = await _collection.get_doc('Document1', true)
	
	if(_document == null):
		_test_error("Failed to get document from cache")
		return

	#
	## Print Document1 to the console GUI
	_print_to_console("Trying to print contents of Document1")
	_print_to_console(_document)
	$print_document.button_pressed = true
	
	var timestamp_transform = ServerTimestampTransform.new(_document.doc_name, true, "server_timestamp_attempt")
	var increment_transform = IncrementTransform.new(_document.doc_name, true, "increment_field", 2)
	var decrement_transform = DecrementTransform.new(_document.doc_name, true, "decrement_field", 2)
	var max_transform = MaxTransform.new(_document.doc_name, true, "max_field", 10) # Should update
	var min_transform = MinTransform.new(_document.doc_name, true, "min_field", -2) # Should update
	_document.add_field_transform(timestamp_transform)
	_document.add_field_transform(increment_transform)
	_document.add_field_transform(decrement_transform)
	_document.add_field_transform(max_transform)
	_document.add_field_transform(min_transform)
	var commit_changes = await _collection.commit(_document)
	
	_document = await _collection.get_doc('Document1')
	
	### Print Document1 to the console GUI
	_print_to_console("Trying to print contents of Document1 after transform")
	_print_to_console(_document)
	$print_document_2.button_pressed = true
	
	_print_to_console("Attempting to remove item from Document1")
	var previous_document_size = _document.keys().size()
	_print_to_console("Current document key size: " + str(previous_document_size))
	
	var key = "name"
	_document.remove_field(key)
	
	_document = await _collection.update(_document)
	
	_print_to_console("After update, document key size is: " + str(_document.keys().size()))
	
	if previous_document_size == _document.keys().size():
		_print_to_console_error("Did not properly delete item from document")
	
	## Query Collection
	_print_to_console("\nRunning Firestore Query")
	var query : FirestoreQuery = FirestoreQuery.new()
	query.from("Firebasetester", false)
	query.order_by("points", FirestoreQuery.DIRECTION.DESCENDING)
	query.where("points", FirestoreQuery.OPERATOR.GREATER_THAN, 5)
	query.limit(1)
	var result = await Firebase.Firestore.query(query)
	_print_to_console(result)
	$run_query.button_pressed = true
		
	_print_to_console("Running listener tests")
	
	await run_listener_tests()
	
	await _cleanup_previous_run()
	# If nothing has failed to this point, finish the test successfully
	_print_to_console("\nFINISHED FIRESTORE TESTS")
	_test_finished()

func run_listener_tests() -> void:
	_document = await _collection.get_doc("Document1")
	await get_tree().create_timer(0.3).timeout
	
	var listener = _document.on_snapshot(
		func(result):
			if result.is_listener:
				print(JSON.stringify(result, "  "))
				, 0.1
	)
	
	print("Doc child count: ", _document.get_child_count(true))
	
	const new_doc_name = 'NewDocument'
	
	_document.add_or_update_field("name", new_doc_name)
	print("Changed name locally")
	
	await get_tree().create_timer(2.0).timeout	
	_document.add_or_update_field("name", new_doc_name + "2")
	print("Changed name locally again")
	
	await get_tree().create_timer(2.0).timeout
	
	_document.add_or_update_field("name", "Document1")
	_document.remove_field("active")
	
	_document = await _collection.update(_document)
	
	var deleted = await _collection.delete(_document)
	if deleted:
		print("Deleted document")
	await get_tree().create_timer(1.0).timeout
	
	listener.stop()
	print("Listener stopped")
	
	_document = await _collection.add("Document1", DefaultDocument)
	print("Document re-added")
	
	_document.add_or_update_field("name", new_doc_name + "2")
	_document = await _collection.update(_document)

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
