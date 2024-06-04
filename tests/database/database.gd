extends Node2D

# Script used for testing the Realtime Database functions of the plugin
signal database_call_completed

# When the data key from the push is ready
signal data_key_ready


# Variables
@onready var _test_running = false
@onready var console = $console
var database_reference  : FirebaseDatabaseReference
var added_data_key

# Constants
const _email : String = 'testaccount@godotnuts.test'
const _password : String = 'Password1234'

# Function called when the scene is ready
func _ready():
	Firebase.Auth.connect("login_succeeded",Callable(self,"_on_FirebaseAuth_login_succeeded"))
	Firebase.Auth.connect("login_failed",Callable(self,"_on_login_failed"))

# Function called when the test starts 
# Clears all checkboxes to clean the GUI
# Disbales all buttons in the GUI to allow the test to run uninterupted 
func _test_started() -> void:
	_test_running = true
	var checkboxes = get_tree().get_nodes_in_group('tests')
	for box in checkboxes:
		box.button_pressed = false
	$back.disabled = true
	$test_database.disabled = true

# Function called when the tests are finsihed
# Re-enables all buttons in the GUI
func _test_finished() -> void:
	_test_running = false
	$back.disabled = false
	$test_database.disabled = false

# Function called when login to Firebase has completed successfully
func _on_FirebaseAuth_login_succeeded(_auth) -> void:
	_print_to_console("Login with email and password has worked")
	$login_check.button_pressed = true
	_test_database()

# Function called when login to Firebase has failed
# Ends the test and prints the error to the GUI console
func _on_login_failed(error_code, message):
	_print_to_console_error("error code: " + str(error_code))
	_print_to_console_error("message: " + str(message))

# Function called when the end user presses the 'Test Database' button
# Starts the test
func _on_test_database_pressed():
	_test_started()
	Firebase.Auth.login_with_email_and_password(_email, _password)

func _test_database():
	# Print to the console GUI that the test is starting
	_print_to_console("STARTING DATABASE TESTS")
	
	# Get the database reference that we will be working with
	_print_to_console("\nGetting the Databse RefCounted...")
	database_reference = Firebase.Database.get_database_reference("FirebaseTester/data", { })
	var once_database_reference = Firebase.Database.get_once_database_reference("FirebaseTester/once/data", { })
	$get_ref_check.button_pressed = true
	
	# Connect to signals needed for testing
	_print_to_console("\nConnecting signals for the RTD...")
	database_reference.connect("new_data_update", _on_new_data_update) # for new data
	database_reference.connect("patch_data_update", _on_patch_data_update) # for patch data
	database_reference.connect("push_failed", _on_push_failed)
	database_reference.connect("push_successful", _on_push_successful)
	
	once_database_reference.connect("push_failed", _on_once_push_failed)
	once_database_reference.connect("push_successful", _on_once_push_successful)
	once_database_reference.connect("once_failed", _on_once_failed)
	once_database_reference.connect("once_successful", _on_once_successful)
	
	# Push data to the RTDB
	_print_to_console("\nTrying to push data to the RTD...")
	once_database_reference.push({'user_name':'username', 'message':'Hello world!'})
	database_reference.push({'user_name':'username', 'message':'Hello world!'})
	$push_data_check.button_pressed = true
	await data_key_ready
	
	# Get data once from the RTDB
	_print_to_console("\n\nAttempting a once-off get from the RTD")
	once_database_reference.once(added_data_key + "/user_name")
	_print_to_console("Once failed")
	$once_data_check.button_pressed = true
		# Update data in the RTDB
	_print_to_console("\nTrying to update the DB")
	database_reference.update(added_data_key, {'user_name':'username', 'message':'Hello world123!'})
	
	_print_to_console("\nTrying to update the DB once")
	once_database_reference.update(added_data_key, {'user_name':'username', 'message':'Hello world123!'})
	$update_data_check.button_pressed = true
	
	# Delete data from the RTDB
	_print_to_console("\n\nAttempting to delete data from the RTD")
	database_reference.delete(added_data_key + "/user_name")
	$delete_data_check.button_pressed = true
	
	# If nothing has failed to this point, finish the test successfully
	_print_to_console("\nFINISHED DATABASE TESTS")
	_test_finished()

# Function called when new data has been added to the RTDB
func _on_new_data_update(new_data : FirebaseResource):
	added_data_key = new_data.key
	data_key_ready.emit()
	_print_to_console(new_data)
	_print_to_console(new_data.key)
	_print_to_console(new_data.data)

# Function called when data is patched in the RTDB
func _on_patch_data_update(patch_data : FirebaseResource):
	added_data_key = patch_data.key
	data_key_ready.emit()
	_print_to_console(patch_data)
	_print_to_console(patch_data.key)
	_print_to_console(patch_data.data)

# Function called when pushing data to the RTDB has failed
func _on_push_failed():
	_print_to_console_error("Push failed")
	database_call_completed.emit()

# Function called when pushing data to the RTDB is successful
func _on_push_successful():
	database_call_completed.emit()
	_print_to_console("Push Successful")
# Function called when pushing data to the RTDB has failed

func _on_once_push_failed():
	_print_to_console_error("Push failed")
	database_call_completed.emit()

# Function called when pushing data to the RTDB is successful
func _on_once_push_successful():
	database_call_completed.emit()
	_print_to_console("Push Successful")
	
# Function called when getting data from the RTDB has failed
func _on_once_failed():
	_print_to_console_error("Once failed")
	database_call_completed.emit()

# Function called when pushing data to the RTDB is successful
func _on_once_successful(data):
	database_call_completed.emit()
	_print_to_console("Once Successful:\n")
	_print_to_console(data)

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
