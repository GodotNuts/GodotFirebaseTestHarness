extends Node2D

# Script used for testing the Realtime Database functions of the plugin

# Variables
onready var _test_running = false
onready var console = $console
var database_reference  : FirebaseDatabaseReference
var added_data_key

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
	$login_check.pressed = true
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
	_print_to_console("\nGetting the Databse Reference...")
	database_reference = Firebase.Database.get_database_reference("FirebaseTester/data", { })
	$get_ref_check.pressed = true
	
	# Connect to signals needed for testing
	_print_to_console("\nConnecting signals for the RTD...")
	database_reference.connect("new_data_update", self, "_on_new_data_update") # for new data
	database_reference.connect("patch_data_update", self, "_on_patch_data_update") # for patch data
	database_reference.connect("push_failed", self, "_on_push_failed")
	database_reference.connect("push_successful", self, "_on_push_successful")
	
	# Push data to the RTDB
	_print_to_console("\nTrying to push data to the RTD...")
	database_reference.push({'user_name':'username', 'message':'Hello world!'})
	$push_data_check.pressed = true
	yield(get_tree().create_timer(3), "timeout")
	
	# Update data in the RTDB
	_print_to_console("\nTrying to update the DB")
	database_reference.update(added_data_key, {'user_name':'username', 'message':'Hello world123!'})
	$update_data_check.pressed = true
	
	# If nothing has failed to this point, finish the test successfully
	_print_to_console("\nFINISHED DATABASE TESTS")
	_test_finished()

# Function called when new data has been added to the RTDB
func _on_new_data_update(new_data : FirebaseResource):
	_print_to_console(new_data)
	_print_to_console(new_data.key)
	_print_to_console(new_data.data)
	added_data_key = new_data.key

# Function called when data is patched in the RTDB
func _on_patch_data_update(patch_data : FirebaseResource):
	_print_to_console(patch_data)
	_print_to_console(patch_data.key)
	_print_to_console(patch_data.data)
	added_data_key = patch_data.key

# Function called when pushing data to the RTDB has failed
func _on_push_failed():
	_print_to_console_error("Push failed")

# Function called when pushing data to the RTDB is successful
func _on_push_successful():
	_print_to_console("Push Successful")

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
