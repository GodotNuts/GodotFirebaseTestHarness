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
    var upload_task = Firebase.Storage.ref("Firebasetester/upload/image.png").put_file("res://assets/image.png")
    await upload_task.task_finished
    $upload_image_check.button_pressed = true
    
    # Download image and display it in the GUi for the end user
    _print_to_console("\nTrying to download image and display it...")
    var image = get_image('image.png')
    await image.task_finished
    var converted_image = task2image(image)
    $image.texture = converted_image
    $download_image_check.button_pressed = true
    
    # Get download URL for the image and display it in the GUI to the end user
    _print_to_console("\nTrying to get download URL...")
    var url_task = Firebase.Storage.ref("Firebasetester/upload/image.png").get_download_url()
    await url_task.task_finished
    _print_to_console(url_task.data)
    $image_url_check.button_pressed = true
    
    # Get the metadata for the image and display it in the GUI to the end user
    _print_to_console("\nTrying to get the metadata...")
    var meta_task = Firebase.Storage.ref("Firebasetester/upload/image.png").get_metadata()
    await meta_task.task_finished
    _print_to_console(meta_task.data)
    $image_meta_check.button_pressed = true
    
    # Delete the test image from Storage
    _print_to_console("\nTrying to delete file...")
    _print_to_console("Before Delete...")
    var list_all_task = Firebase.Storage.ref("Firebasetester").list_all()
    await list_all_task.task_finished
    _print_to_console(list_all_task.data)
    var delete_task = Firebase.Storage.ref("Firebasetester/upload/image.png").delete()
    await delete_task.task_finished
    _print_to_console("After Delete...")
    list_all_task = Firebase.Storage.ref("Firebasetester").list_all()
    await list_all_task.task_finished
    _print_to_console(list_all_task.data)
    $image_delete_check.button_pressed = true
    
    # Upload test document to Storage
    _print_to_console("\nTrying to upload file")
    upload_task = Firebase.Storage.ref("Firebasetester/upload/dummy.pdf").put_file("res://assets/dummy.pdf")
    await upload_task.task_finished
    $upload_document_check.button_pressed = true
    
    # Get the metadata for the document and display it in the GUI to the end user
    _print_to_console("\nTrying to get the metadata...")
    meta_task = Firebase.Storage.ref("Firebasetester/upload/dummy.pdf").get_metadata()
    await meta_task.task_finished
    _print_to_console(meta_task.data)
    $document_meta_check.button_pressed = true
    
    # Delete the test document from Storage
    _print_to_console("\nTrying to delete file...")
    _print_to_console("Before Delete...")
    list_all_task = Firebase.Storage.ref("Firebasetester").list_all()
    await list_all_task.task_finished
    _print_to_console(list_all_task.data)
    delete_task = Firebase.Storage.ref("Firebasetester/upload/dummy.pdf").delete()
    await delete_task.task_finished
    _print_to_console("After Delete...")
    list_all_task = Firebase.Storage.ref("Firebasetester").list_all()
    await list_all_task.task_finished
    _print_to_console(list_all_task.data)
    $document_delete_check.button_pressed = true
    
    # Upload string to Storage
    _print_to_console("\nTrying to write a string...")
    upload_task = Firebase.Storage.ref("Firebasetester/upload/junkdata").put_string("Test", {})
    await upload_task.task_finished
    $upload_string_check.button_pressed = true
    
    # Add metadata to the string
    _print_to_console("\nTrying to add metadata to it...")
    meta_task = Firebase.Storage.ref("Firebasetester/upload/junkdata").update_metadata({"Test": "This is a Test", "SillyData": "We got it"})
    await meta_task.task_finished
    $string_add_meta_check.button_pressed = true
    
    # Get the metadata for the string and display it in the GUI to the end user
    _print_to_console("\nTrying to get the metadata...")
    meta_task = Firebase.Storage.ref("Firebasetester/upload/junkdata").get_metadata()
    await meta_task.task_finished
    _print_to_console(meta_task.data)
    $string_meta_check.button_pressed = true
    
    # Delete the test string from Storage
    _print_to_console("\nTrying to delete file...")
    _print_to_console("Before Delete...")
    list_all_task = Firebase.Storage.ref("Firebasetester").list_all()
    await list_all_task.task_finished
    _print_to_console(list_all_task.data)
    delete_task = Firebase.Storage.ref("Firebasetester/upload/junkdata").delete()
    await delete_task.task_finished
    _print_to_console("After Delete...")
    list_all_task = Firebase.Storage.ref("Firebasetester").list_all()
    await list_all_task.task_finished
    _print_to_console(list_all_task.data)
    $string_delete_check.button_pressed = true
    
    # If nothing has failed to this point, finish the test successfully
    _print_to_console("\nFINISHED STORAGE TESTS")
    _test_finished()

# Function used to the the image data for a file an image file storage
func get_image(requested_image):
    return Firebase.Storage.ref("Firebasetester/upload/{image}".format({image = requested_image})).get_data()

# Fucntion used to convert the data to an image
func task2image(task : StorageTask) -> ImageTexture:
    var new_image := Image.new()
    match typeof(task.data):
        TYPE_PACKED_BYTE_ARRAY:
            var data : PackedByteArray = task.data
            if data.size()>1:
                match data.slice(0,1).hex_encode():
                    "ffd8":
                        new_image.load_jpg_from_buffer(data)
                    "8950":
                        new_image.load_png_from_buffer(data)
        TYPE_DICTIONARY:
            _print_to_console_error("ERROR %s: could not find image requested" % task.data.error.code)
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
