extends Node2D

# Script used for testing the Dynamic Link functions of the plugin

# Signals
signal link_printed

# Variables
onready var _test_running = false
onready var console = $console
var link_to_test = 'https://google.com'

# Constants
const _email : String = 'testaccount@godotnuts.test'
const _password : String = 'Password1234'

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
	$test_links.disabled = true

# Function called when the tests are finsihed
# Re-enables all buttons in the GUI
func _test_finished() -> void:
	_test_running = false
	$back.disabled = false
	$test_links.disabled = false

# Function called when login to Firebase has completed successfully
func _on_FirebaseAuth_login_succeeded(_auth) -> void:
	_print_to_console("Login with email and password has worked")
	$login_check.pressed = true
	_test_links()

# Function called when login to Firebase has failed
# Ends the test and prints the error to the GUI console
func _on_login_failed(error_code, message):
	_print_to_console_error("error code: " + str(error_code))
	_print_to_console_error("message: " + str(message))
	_test_error("Login Failed")

# Function called if there is an error in the test
# Prints the error to the GUI console so the end user can see
func _test_error(data) -> void:
	_print_to_console_error(data)
	_test_finished()

# Function called when the end user presses the 'Test Links' button
# Starts the test
func _on_test_links_pressed():
	_test_started()
	Firebase.Auth.login_with_email_and_password(_email, _password)

# Main function that is run when testing Dynamic Links
func _test_links():
	# Print to the console GUI that the test is starting
	_print_to_console("STARTING LINKS TESTS")
	
	# Connect to signals needed for testing
	Firebase.DynamicLinks.connect("dynamic_link_generated", self, "print_link")
	
	# Generate 'Unguessable Link'
	_print_to_console("\nTrying to generate an unguessable link...")
	Firebase.DynamicLinks.generate_dynamic_link(link_to_test, "", "", true)
	yield(self, 'link_printed')
	$unguessable_link_check.pressed = true
	
	# Generate 'Guessable Link'
	_print_to_console("\nTrying to generate an guessable link...")
	Firebase.DynamicLinks.generate_dynamic_link(link_to_test, "", "", false)
	yield(self, 'link_printed')
	$guessable_link_check.pressed = true
	
	# If nothing has failed to this point, finish the test successfully
	_print_to_console("\nFINISHED LINKS TESTS")
	_test_finished()

# Function used to print the link data to the console GUI
func print_link(link_data):
	_print_to_console(link_data)
	emit_signal('link_printed')

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
