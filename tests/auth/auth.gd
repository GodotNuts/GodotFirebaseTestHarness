extends Node2D

# Script used for testing the Authentication functions of the plugin

# Variables
onready var _test_running = false
onready var console = $console
var _auth_error = false

# Constants
const _email1 = 'test@fakeemail.com'
const _email2 = 'test2@fakeemail.com'
const _password1 = 'ThisPasswordIsAwesome'
const _password2 = 'ThisPasswordIsStillAwesome'
const _timer_length = 5

# Function called when the scene is ready
func _ready():
	Firebase.Auth.connect("login_succeeded", self, "_on_FirebaseAuth_login_succeeded")
	Firebase.Auth.connect("signup_succeeded", self, "_on_FirebaseAuth_signup_succeeded")
	Firebase.Auth.connect("login_failed", self, "_on_login_failed")
	Firebase.Auth.connect("userdata_received", self, "_on_userdata_received")

# Function called when the test starts
# Clears all checkboxes to clean the GUI
# Disbales all buttons in the GUI to allow the test to run uninterupted
func _test_started() -> void:
	_test_running = true
	var checkboxes = get_tree().get_nodes_in_group('tests')
	for box in checkboxes:
		box.pressed = false
	$back.disabled = true
	$test_auth.disabled = true

# Function called when the tests are finsihed
# Re-enables all buttons in the GUI
func _test_finished() -> void:
	_test_running = false
	$back.disabled = false
	$test_auth.disabled = false

# Function called when the end user presses the 'Test Auth' button
# Main function that is run when testing Authentication
func _on_test_auth_pressed() -> void:
	# Print to the console GUI that the test is starting
	_print_to_console("STARTING AUTH TESTS")
	_test_started()

	# Start signup test using the fist email
	if _auth_error != true:
		_print_to_console("\nTrying to signup...")
		Firebase.Auth.signup_with_email_and_password(_email1, _password1)
		yield(get_tree().create_timer(_timer_length), "timeout")

	# Start Login test using the first email
	if _auth_error != true:
		$signup_check.pressed = true
		_print_to_console("\nTrying to login...")
		Firebase.Auth.login_with_email_and_password(_email1, _password1)
		yield(get_tree().create_timer(_timer_length), "timeout")

	# Check Auth File
	if _auth_error != true:
		$login_check.pressed = true
		_check_auth_file()
		yield(get_tree().create_timer(_timer_length), "timeout")

	# Get User Data Test
	if _auth_error != true:
		$auth_file_check.pressed = true
		_print_to_console("\nTrying to get user data...")
		Firebase.Auth.get_user_data()
		yield(get_tree().create_timer(_timer_length), "timeout")

	# Change User Password
	if _auth_error != true:
		$user_data_check.pressed = true
		_print_to_console("\nTrying to change user password...")
		Firebase.Auth.change_user_password(_password2)
		yield(get_tree().create_timer(_timer_length), "timeout")
		Firebase.Auth.logout()
		yield(get_tree().create_timer(_timer_length), "timeout")
		Firebase.Auth.login_with_email_and_password(_email1, _password2)
		yield(get_tree().create_timer(_timer_length), "timeout")

	# Change the user email from the first email to the second email
	if _auth_error != true:
		$change_pass_check.pressed = true
		_print_to_console("\nTrying to change user email...")
		Firebase.Auth.change_user_email(_email2)
		yield(get_tree().create_timer(_timer_length), "timeout")
		Firebase.Auth.logout()
		yield(get_tree().create_timer(_timer_length), "timeout")
		Firebase.Auth.login_with_email_and_password(_email2, _password2)
		yield(get_tree().create_timer(_timer_length), "timeout")

	# Login with the new credentials
	if _auth_error != true:
		$change_email_check.pressed = true
		_print_to_console("\nTrying to login with new creds...")
		Firebase.Auth.login_with_email_and_password(_email2, _password2)
		yield(get_tree().create_timer(_timer_length), "timeout")

	# Start Delete Account test
	if _auth_error != true:
		$login_check_2.pressed = true
		_print_to_console("\nDeleting Account...")
		Firebase.Auth.delete_user_account()

	# If nothing has failed to this point, finish the test successfully
	if _auth_error != true:
		$delete_check.pressed = true
		_print_to_console("\nFINISHED AUTH TESTS")
		_test_finished()
	else:
		_auth_test_error()

func _on_FirebaseAuth_signup_succeeded(_auth) -> void:
	_print_to_console("Signup with email and password has worked")
	_print_to_console("Logging Out...")
	_print_to_console("Ignore this error if there is one, it's normal")
	Firebase.Auth.logout()
	_print_to_console("Checking for auth file (It should not be there)...")
	var dir = Directory.new()
	if (dir.file_exists("user://user.auth")):
		_print_to_console_error("Auth file exists, This is bad")
		_auth_error = true
	else:
		_print_to_console("No encrypted auth file exists, good to go")

func _on_FirebaseAuth_login_succeeded(_auth) -> void:
	_print_to_console("Login with email and password has worked")
	Firebase.Auth.save_auth(_auth)

func _check_auth_file() -> void:
	_print_to_console("Checking for auth file (It should be there)...")
	var dir = Directory.new()
	if (dir.file_exists("user://user.auth")):
		_print_to_console("Auth file exists, good to go")
	else:
		_print_to_console_error("No encrypted auth file exists")
		_auth_error = true

func _on_userdata_received(userdata) -> void:
	if userdata != null:
		_print_to_console("User data recieved")
	else:
		_print_to_console_error("Could not get user data")
		_auth_error = true

func _on_login_failed(error_code, message):
	_print_to_console_error("error code: " + str(error_code))
	_print_to_console_error("message: " + str(message))
	_auth_error = true

func _auth_test_error() -> void:
	_print_to_console_error("There has been a failure")
	emit_signal("test_finished")

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
