extends Node2D

# Script used for testing the Firestore functions of the plugin

# Variables
onready var _test_running = false
onready var console = $console
var _collection : FirestoreCollection
var _document : FirestoreDocument

# Constants 
const _email : String = 'testaccount@godotnuts.test'
const _password : String = 'Password1234'

# Function called when the scene is ready
func _ready():
	Firebase.Auth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")
	Firebase.Auth.connect("login_failed", self, "_on_login_failed")

# Function called when the test starts 
# Clears all checkboxes to clean the GUI
# Disbales all buttons in the GUI to allow the test to run uninterupted 
func _test_started() -> void:
	_test_running = true
	var checkboxes = get_tree().get_nodes_in_group('tests')
	for box in checkboxes:
		box.pressed = false
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

# Function called when login to Firebase has completed successfully
func _on_FirebaseAuth_login_succeeded(_auth) -> void:
	_print_to_console("Login with email and password has worked")
	$login_check.pressed = true
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
	_collection.connect("add_document", self, "on_document_add")
	_collection.connect("get_document", self, "on_document_get")
	_collection.connect("update_document", self, "on_document_update")
	_collection.connect("delete_document", self, "on_document_delete")
	_collection.connect("error", self, "on_document_error")
	
	# Add Document1 to Firestore
	_print_to_console("Trying to add a document")
	var add_task : FirestoreTask = _collection.add("Document1", {'name': 'Document1', 'active': 'true'})
	_document = yield(add_task, "add_document")
	$add_document.pressed = true
	
	# Get Document1 (Document that has been added from the previous step)
	_print_to_console("Trying to get 'Document1")
	_collection.get('Document1')
	_document = yield(_collection, "get_document")
	if(_document == null):
		_test_error("Failed to get document")
		return
	else:
		$get_document.pressed = true
	
	# Print Document1 to the console GUI
	_print_to_console("Trying to print contents of Document1")
	_print_to_console(_document)
	$print_document.pressed = true
	
	# Update Document1
	_print_to_console("Trying to update Document1")
	var up_task : FirestoreTask = _collection.update("Document1", {'name': 'Document1', 'active': 'true', 'updated' : 'true'})
	_document = yield(up_task, "update_document")
	$update_document.pressed = true
	
	# Get Document1 (With updated that has been added from the previous step)
	_print_to_console("Trying to get 'Document1")
	_collection.get('Document1')
	_document = yield(_collection, "get_document")
	$get_document_2.pressed = true
	
	# Print Document1 to the console GUI
	_print_to_console("Trying to print contents of Document1")
	_print_to_console(_document)
	$print_document_2.pressed = true
	
	# Delete Document1 from Firestore
	_print_to_console("Trying to delete Doucment1")
	var del_task : FirestoreTask = _collection.delete("Document1")
	_document = yield(del_task, "delete_document")
	$delete_document.pressed = true
	
	# Query Collection
	_print_to_console("\nRunning Firestore Query")
	var query : FirestoreQuery = FirestoreQuery.new()
	query.from("Firebasetester")
	query.where("points", FirestoreQuery.OPERATOR.GREATER_THAN, 5)
	query.order_by("points", FirestoreQuery.DIRECTION.DESCENDING)
	query.limit(10)
	var query_task : FirestoreTask = Firebase.Firestore.query(query)
	var result = yield(query_task, "task_finished")
	_print_to_console(result)
	$run_query.pressed = true
	
	# If nothing has failed to this point, finish the test successfully
	_print_to_console("\nFINISHED FIRESTORE TESTS")
	_test_finished()

# Function called when a document has been added to Firestore successfully
func on_document_add(document_added : FirestoreDocument) -> void:
	_print_to_console("Document added successfully")

# Function called when a document has been retrived from Firestore successfully
func on_document_get(document_got : FirestoreDocument) -> void:
	_print_to_console("Document got successfully")

# Function called when a document has been updated in Firestore successfully
func on_document_update(document_updated : FirestoreDocument) -> void:
	_print_to_console("Document Updated successfully")

# Function called when a document has been deleted in Firestore successfully
func on_document_delete() -> void:
	_print_to_console("Document deleted successfully")

# Function called when a function with Firestore has failed
func on_document_error(code, status, message) -> void:
	_print_to_console_error("error code: " + str(code))
	_print_to_console_error("message: " + str(message))
	_test_error("There was an issue")

# Function used to print data to the console GUI for the end user
func _print_to_console(data):
	data = str(data)
	print(data)
	var previous_data = console.bbcode_text
	var updated_data = previous_data + data + "\n"
	console.bbcode_text = updated_data

# Function used to print error data to the console GUI for the end user
func _print_to_console_error(data):
	data = str(data)
	printerr(data)
	var previous_data = console.bbcode_text
	var updated_data = previous_data + "[color=red]" + data + "[/color] \n"
	console.bbcode_text = updated_data

# Function called when the end user presses the 'Back' button, returns to the Main Menu
func _on_back_pressed():
	get_tree().change_scene("res://main.tscn")
