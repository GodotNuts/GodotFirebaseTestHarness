extends Control

# Script used for testing the RemoteConfig API of the plugin

# Variables
@onready var _test_running = false
@onready var console = $console

# Constants
const _email : String = 'testaccount@godotnuts.test'
const _password : String = 'Password1234'

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
	%back.disabled = true
	%test_remoteconfig.disabled = true

# Function called when the tests are finsihed
# Re-enables all buttons in the GUI
func _test_finished() -> void:
	_test_running = false
	%back.disabled = false
	%test_remoteconfig.disabled = false

# Function called when login to Firebase has completed successfully
func _on_FirebaseAuth_login_succeeded(_auth) -> void:
	_print_to_console("Login with email and password has worked")
	%login_check.button_pressed = true
	_test_remote_config()

# Function called when login to Firebase has failed
# Ends the test and prints the error to the GUI console
func _on_login_failed(error_code, message):
	_print_to_console_error("error code: " + str(error_code))
	_print_to_console_error("message: " + str(message))

# Function called when the end user presses the 'Test Database' button
# Starts the test
func _on_test_remote_config_pressed():
	_test_started()
	Firebase.Auth.login_with_email_and_password(_email, _password)

func _test_remote_config():
	# Print to the console GUI that the test is starting
	_print_to_console("STARTING REMOTE CONFIG TESTS")
	
	# Get the RemoteConfig reference that we will be working with
	_print_to_console("\nGetting the Remote Config...")
	var remote_config = Firebase.RemoteConfigAPI
	
	# Connect to signals needed for testing
	_print_to_console("\nConnecting signals for Remote Config...")
	remote_config.remote_config_received.connect(_on_remote_config_received, CONNECT_REFERENCE_COUNTED)
	remote_config.remote_config_error.connect(_on_remote_config_error, CONNECT_REFERENCE_COUNTED)
	
	var reduce_signal = Utilities.SignalReducer.new()
	reduce_signal.add_signal(remote_config.remote_config_received, 1)
	reduce_signal.add_signal(remote_config.remote_config_error, 1)
	
	_print_to_console("\nCalling to get Remote Config")
	
	remote_config.get_remote_config()
	
	await reduce_signal.completed
	# If nothing has failed to this point, finish the test successfully
	_print_to_console("\nFINISHED REMOTECONFIG TESTS")
	_test_finished()

func _on_remote_config_received(config) -> void:
	_print_to_console("Config received: ")
	_print_to_console(config)
	%get_remote_config.button_pressed = true
	
func _on_remote_config_error(error) -> void:
	_print_to_console("Error received: ")
	_print_to_console_error(error)

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
