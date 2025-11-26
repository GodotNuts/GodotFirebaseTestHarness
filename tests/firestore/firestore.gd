extends Control

# Script used for testing the Firestore functions of the plugin

# Variables
@onready var _test_running = false
@onready var console = $console
var _collection : FirestoreCollection
var _document : FirestoreDocument
var _listener

# Constants 
# Constants 
const _email : String = 'testaccount@godotnuts.test'
const _password : String = 'Password1234'

enum TestMode { NONE, STANDARD, LIVE }
var _current_test_mode = TestMode.NONE

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
	$back.disabled = true
	$test_firestore.disabled = true
	if has_node("live_listener_test"):
		$live_listener_test.disabled = true
	if has_node("live_controls"):
		$live_controls.visible = _current_test_mode == TestMode.LIVE
		
	if _current_test_mode == TestMode.LIVE:
		for box in checkboxes:
			box.visible = false

# Function called when the tests are finsihed
# Re-enables all buttons in the GUI
func _test_finished() -> void:
	_test_running = false
	$back.disabled = false
	$test_firestore.disabled = false
	if has_node("live_listener_test"):
		$live_listener_test.disabled = false
	if has_node("live_controls"):
		$live_controls.visible = false
		
	var checkboxes = get_tree().get_nodes_in_group('tests')
	for box in checkboxes:
		box.visible = true

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
	
	if _current_test_mode == TestMode.STANDARD:
		await _test_firestore()
	elif _current_test_mode == TestMode.LIVE:
		await _start_live_listener_test()

# Function called when login to Firebase has failed
# Ends the test and prints the error to the GUI console
func _on_login_failed(error_code, message):
	_print_to_console_error("error code: " + str(error_code))
	_print_to_console_error("message: " + str(message))
	_test_error("Login Failed")

# Function called when the end user presses the 'Test Auth' button
# Starts the test
func _on_test_firestore_pressed():
	_current_test_mode = TestMode.STANDARD
	_test_started()
	Firebase.Auth.login_with_email_and_password(_email, _password)

func _on_live_listener_test_pressed():
	_current_test_mode = TestMode.LIVE
	_test_started()
	Firebase.Auth.login_with_email_and_password(_email, _password)

func _start_live_listener_test() -> void:
	_print_to_console("\nSTARTING LIVE LISTENER TEST")
	_print_to_console("Connecting to collection 'Firebasetester'...")
	_collection = Firebase.Firestore.collection('Firebasetester')
	
	_print_to_console("Listening to 'LiveSyncDoc'...")
	_document = await _collection.get_doc("LiveSyncDoc")
	
	if _document == null:
		_print_to_console("Document 'LiveSyncDoc' not found, creating it...")
		_document = await _collection.add("LiveSyncDoc", {
			"status": "listening", 
			"created_at": Time.get_unix_time_from_system(),
			"last_updated": Time.get_unix_time_from_system()
		})
	
	_print_to_console("Listener attached! Waiting for changes indefinitely...")
	_print_to_console("Use the buttons on the left to modify the document.")
	
	_listener = _document.on_snapshot(func(changes):
		_print_to_console("\n[LIVE UPDATE] " + Time.get_time_string_from_system())
		if changes.has("lamport_timestamp"):
			_print_to_console("Lamport: %d" % changes.lamport_timestamp)
		
		if changes.has("updated"):
			_print_to_console("Updated: %s" % str(changes.updated))
		if changes.has("added"):
			_print_to_console("Added: %s" % str(changes.added))
		if changes.has("removed"):
			_print_to_console("Removed: %s" % str(changes.removed))
			
		_print_to_console("Current State: %s" % str(_document.get_unsafe_document()))
	)

func _on_add_field_pressed():
	if _document == null: return
	var key = "field_" + str(randi() % 1000)
	var value = "value_" + str(randi() % 1000)
	_print_to_console("Adding field: %s = %s" % [key, value])
	_document.add_or_update_field(key, value)
	await _collection.update(_document)

func _on_update_field_pressed():
	if _document == null: return
	var keys = _document.document.keys()
	if keys.size() == 0:
		_print_to_console("No fields to update!")
		return
	
	# Filter out metadata fields if you want, but for now just pick random
	var key = keys[randi() % keys.size()]
	var value = "updated_" + str(randi() % 1000)
	_print_to_console("Updating field: %s = %s" % [key, value])
	_document.add_or_update_field(key, value)
	await _collection.update(_document)

func _on_delete_field_pressed():
	if _document == null: return
	var keys = _document.document.keys()
	if keys.size() == 0:
		_print_to_console("No fields to delete!")
		return
		
	var key = keys[randi() % keys.size()]
	# Protect critical fields if needed, but for test let's allow deleting anything except maybe doc_name/id which aren't in document dict anyway
	_print_to_console("Deleting field: %s" % key)
	_document.remove_field(key)
	await _collection.update(_document)

func _on_commit_increment_pressed():
	if not _listener:
		print("Listener not initialized!")
		return
		
	var document = await _collection.get_doc("LiveSyncDoc", true)
	
	var transform = IncrementTransform.new(document.doc_name, true, "counter", 1)
	
	document.add_field_transform(transform)
	
	print("Committing increment transform...")
	var result = await _collection.commit(document)
	print("Commit result: %s" % str(result))
	
	# Fetch the latest document state from Firestore to get the calculated value
	# This will trigger the listener automatically via replace() -> _emit_changes() -> listener.send_change()
	# document = await _collection.get_doc("LiveSyncDoc", false)
	# var new_value = document.get_value("counter")
	# print("New counter value from server: %s" % str(new_value))


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
	
	_print_to_console("Printing crud with dictionary getter")
	var value2 = _document['crud']
	_print_to_console(value2)
	
	_print_to_console("Setting crud value with dictionary setter")
	_document['crud'] = "new crud"
	_print_to_console("New crud: " + _document['crud'])
		
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
	_print_to_console("Trying to print unsafe contents of Document1")
	_print_to_console(_document.get_unsafe_document())
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
	query.from("Firebasetester")
	query.where("points", FirestoreQuery.OPERATOR.GREATER_THAN, 5)
	query.order_by("points", FirestoreQuery.DIRECTION.DESCENDING)
	query.limit(10)
	var result = await Firebase.Firestore.query(query)
	_print_to_console(result)
	
	## Agg Query: Count
	_print_to_console("\nRunning Firestore Aggregation Queries")
	_print_to_console("\nAgg Query: Count")
	var agg_query : FirestoreQuery = FirestoreQuery.new()
	agg_query.from("Firebasetester")
	agg_query.where("points", FirestoreQuery.OPERATOR.NOT_EQUAL, 5)
	agg_query.aggregate().count(10) # Should return something like "count": "1"
	var agg_result = await Firebase.Firestore.aggregation_query(agg_query)
	_print_to_console("Result from Count query: " + str(agg_result))
	
	## AggQuery: Average
	_print_to_console("\nAgg Query: Average")
	agg_query = FirestoreQuery.new()
	agg_query.from("Firebasetester")
	agg_query.where("points", FirestoreQuery.OPERATOR.NOT_EQUAL, 5)
	agg_query.aggregate().average("points") # Should return "points": "1" I think
	agg_result = await Firebase.Firestore.aggregation_query(agg_query)
	_print_to_console("Result from Average query: " + str(agg_result))
	
	## AggQuery: sum
	_print_to_console("\nAgg Query: Sum")
	agg_query = FirestoreQuery.new()
	agg_query.from("Firebasetester")
	agg_query.where("points", FirestoreQuery.OPERATOR.NOT_EQUAL, 5)
	agg_query.aggregate().sum("points") # Should return "points": "1" ... I think.
	agg_result = await Firebase.Firestore.aggregation_query(agg_query)
	_print_to_console("Result from Sum query: " + str(agg_result))
	$run_query.button_pressed = true
	
	## AggQuery: sum and count for testing purposes
	_print_to_console("\nAgg Query: Sum and Count")
	agg_query = FirestoreQuery.new()
	agg_query.from("Firebasetester")
	agg_query.where("points", FirestoreQuery.OPERATOR.NOT_EQUAL, 5)
	agg_query.aggregate().sum("points").aggregate().count(10) # Should return "points":"1", "counts":"1" ... I think.
	agg_result = await Firebase.Firestore.aggregation_query(agg_query)
	_print_to_console("Result from Sum/Count query: " + str(agg_result))
	
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
		func(changes):
			_print_to_console("=== Listener Change Received ===")
			if changes.has("lamport_timestamp"):
				_print_to_console("Lamport Timestamp: %d" % changes.lamport_timestamp)
			if changes.has("update_time"):
				_print_to_console("Update Time: %.3f" % changes.update_time)
			if changes.has("added") and changes.added and changes.added.size() > 0:
				_print_to_console("Added: %s" % str(changes.added))
			if changes.has("updated") and changes.updated and changes.updated.size() > 0:
				_print_to_console("Updated: %s" % str(changes.updated))
			if changes.has("removed") and changes.removed and changes.removed.size() > 0:
				_print_to_console("Removed: %s" % str(changes.removed))
			_print_to_console("Document state: %s" % str(_document.get_unsafe_document()))
			_print_to_console("================================")
	)

		
	const new_doc_name = 'NewDocument'
	
	_document.add_or_update_field("name", new_doc_name)
	print("Changed name locally")
	
	await get_tree().create_timer(2.0).timeout	
	_document.add_or_update_field("name", new_doc_name + "2")
	print("Changed name locally again")
	
	await get_tree().create_timer(2.0).timeout
	
	_document.add_or_update_field("name", "Document1")
	_document.remove_field("active")
	print("Changed name locally and removed active")
	
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
