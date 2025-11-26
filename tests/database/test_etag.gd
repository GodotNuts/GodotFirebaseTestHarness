extends Control

var _ref: FirebaseOnceDatabaseReference
var _collection_name = "EtagTest"

func _ready():
	_run_test()

func _run_test():
	print("Starting ETag Test")
	_ref = Firebase.Database.get_once_database_reference(_collection_name)
	_ref.once_successful.connect(_on_once_successful)
	_ref.once_failed.connect(_on_once_failed)
	
	var push_ref = Firebase.Database.get_database_reference(_collection_name)
	push_ref.push({"test": "data"})
	await push_ref.push_successful
	print("Data pushed")
	
	_ref.once("")

func _on_once_successful(data):
	print("Once successful")
	print("Data: ", data)
	
	if "last_etag" in _ref and _ref.last_etag != "":
		print("ETag received: ", _ref.last_etag)
		var etag = _ref.last_etag
		
		print("Attempting update with CORRECT ETag...")
		_ref.update("", {"test": "updated_with_etag"}, etag)
		await _ref.push_successful
		print("Update with correct ETag successful!")
		
		print("Attempting update with INCORRECT ETag...")
		_ref.update("", {"test": "should_fail"}, "invalid_etag")
		var failed = await _wait_for_failure()
		if failed:
			print("Update with incorrect ETag failed as expected!")
		else:
			print("ERROR: Update with incorrect ETag succeeded unexpectedly!")
			
	else:
		print("ERROR: No ETag received!")

func _wait_for_failure() -> bool:
	var result = await _ref.push_failed
	return true

func _on_once_failed():
	print("Once failed")
