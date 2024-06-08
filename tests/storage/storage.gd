extends Node2D

# Script used for testing the Storage functions of the plugin

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
	$back.disabled = true
	$test_storage.disabled = true
	$image.texture = null

# Function called when the tests are finsihed
# Re-enables all buttons in the GUI
func _test_finished() -> void:
	_test_running = false
	$back.disabled = false
	$test_storage.disabled = false

# Function called when login to Firebase has completed successfully
func _on_FirebaseAuth_login_succeeded(_auth) -> void:
	_print_to_console("Login with email and password has worked")
	$login_check.button_pressed = true
	_test_storage()

# Function called when login to Firebase has failed
# Ends the test and prints the error to the GUI console
func _on_login_failed(error_code, message):
	_print_to_console_error("error code: " + str(error_code))
	_print_to_console_error("message: " + str(message))

# Function called when the end user presses the 'Test Storage' button
# Starts the test
func _on_test_storage_pressed():
	_test_started()
	Firebase.Auth.login_with_email_and_password(_email, _password)

# Main function that is run when testing Storage
func _test_storage():
	# Print to the console GUI that the test is starting
	_print_to_console("STARTING STORAGE TESTS")
	
	# Upload test image to Storage
	_print_to_console("Trying to Upload image...")
	var upload = await Firebase.Storage.ref("Firebasetester/upload/image.png").put_file("res://assets/image.png")
	$upload_image_check.button_pressed = true
	
	# Download image and display it in the GUi for the end user
	_print_to_console("\nTrying to download image and display it...")
	var image = await get_image('image.png')
	var converted_image = variant2image(image)
	$image.texture = converted_image
	$download_image_check.button_pressed = true
	
	# Get download URL for the image and display it in the GUI to the end user
	_print_to_console("\nTrying to get download URL...")
	var url = await Firebase.Storage.ref("Firebasetester/upload/image.png").get_download_url()
	_print_to_console(url)
	$image_url_check.button_pressed = true
	
	# Get the metadata for the image and display it in the GUI to the end user
	_print_to_console("\nTrying to get the metadata...")
	var meta = await Firebase.Storage.ref("Firebasetester/upload/image.png").get_metadata()
	_print_to_console(meta)
	$image_meta_check.button_pressed = true
	
	# Delete the test image from Storage
	_print_to_console("\nTrying to delete file...")
	_print_to_console("Before Delete...")
	await list_all_current()
	var delete = await Firebase.Storage.ref("Firebasetester/upload/image.png").delete()
	_print_to_console("After Delete...")
	await list_all_current()
	$image_delete_check.button_pressed = true
	
	# Upload test document to Storage
	_print_to_console("\nTrying to upload file")
	upload = await Firebase.Storage.ref("Firebasetester/upload/dummy.pdf").put_file("res://assets/dummy.pdf")
	$upload_document_check.button_pressed = true
	
	# Get the metadata for the document and display it in the GUI to the end user
	_print_to_console("\nTrying to get the metadata...")
	meta = await Firebase.Storage.ref("Firebasetester/upload/dummy.pdf").get_metadata()
	_print_to_console(meta)
	$document_meta_check.button_pressed = true
	
	# Delete the test document from Storage
	_print_to_console("\nTrying to delete file...")
	_print_to_console("Before Delete...")
	await list_all_current()
	delete = await Firebase.Storage.ref("Firebasetester/upload/dummy.pdf").delete()
	_print_to_console("After Delete...")
	await list_all_current()
	$document_delete_check.button_pressed = true
	
	# Upload string to Storage
	_print_to_console("\nTrying to write a string...")
	upload = await Firebase.Storage.ref("Firebasetester/upload/junkdata").put_string("Test", {})
	$upload_string_check.button_pressed = true
	
	# Add metadata to the string
	_print_to_console("\nTrying to add metadata to it...")
	meta = await Firebase.Storage.ref("Firebasetester/upload/junkdata").update_metadata({"Test": "This is a Test", "SillyData": "We got it"})
	$string_add_meta_check.button_pressed = true
	
	# Get the metadata for the string and display it in the GUI to the end user
	_print_to_console("\nTrying to get the metadata...")
	meta = await Firebase.Storage.ref("Firebasetester/upload/junkdata").get_metadata()
	_print_to_console(meta)
	$string_meta_check.button_pressed = true
	
	# Delete the test string from Storage
	_print_to_console("\nTrying to delete file...")
	_print_to_console("Before Delete...")
	await list_all_current()
	delete = await Firebase.Storage.ref("Firebasetester/upload/junkdata").delete()
	_print_to_console("After Delete...")
	await list_all_current()
	$string_delete_check.button_pressed = true
	
	# If nothing has failed to this point, finish the test successfully
	_print_to_console("\nFINISHED STORAGE TESTS")
	_test_finished()

func list_all_current() -> void:
	var list_all = await Firebase.Storage.ref("Firebasetester").list_all()
	_print_to_console(list_all)

# Function used to the the image data for a file an image file storage
func get_image(requested_image):
	return await Firebase.Storage.ref("Firebasetester/upload/{image}".format({image = requested_image})).get_data()

# Fucntion used to convert the data to an image
func variant2image(vari : Variant) -> ImageTexture:
	var new_image := Image.new()
	match typeof(vari):
		TYPE_PACKED_BYTE_ARRAY:
			var data : PackedByteArray = vari
			if data.size()>1:
				var image_marker = data.slice(0, 1)
				var hex = image_marker.hex_encode()
				match hex:
					"ffd8": # I do not know if this has to change as below; we could add a test for this by also uploading/deleting a jpeg
						new_image.load_jpg_from_buffer(data)
					"89": # This apparently had to change as we were getting corrupt data
						new_image.load_png_from_buffer(data)
		TYPE_DICTIONARY:
			_print_to_console_error("ERROR %s: could not find image requested" % vari)
	var new_texture := ImageTexture.new()
	new_texture.create_from_image(new_image)
	return new_texture

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
