## @meta-authors TODO
## @meta-version 2.2
## A reference to a Firestore Document.
## Documentation TODO.
@tool
class_name FirestoreDocument
extends RefCounted

# A FirestoreDocument objects that holds all important values for a Firestore Document,
# @doc_name = name of the Firestore Document, which is the request PATH
# @doc_fields = fields held by Firestore Document, in APIs format
# created when requested from a `collection().get()` call

var document : Dictionary       # the Document itself
var doc_name : String           # only .name
var create_time : String        # createTime
var collection_name : String    # Name of the collection to which it belongs
var _transforms : FieldTransformArray     # The transforms to apply

func _init(doc : Dictionary = {}):
	_transforms = FieldTransformArray.new()
	
	document = doc.fields
	doc_name = doc.name
	if doc_name.count("/") > 2:
		doc_name = (doc_name.split("/") as Array).back()
		
	self.create_time = doc.createTime

func add_field_transform(transform : FieldTransform) -> void:
	_transforms.push_back(transform)

func remove_field(field_path : String) -> void:
	if document.has(field_path):
		document[field_path] = null

func _erase(field_path : String) -> void:
	document.erase(field_path)

func add_or_update_field(field_path : String, value : Variant) -> void:
	document[field_path] = Utilities.to_firebase_type(value)

func on_snapshot(listener : Callable):
	var collection = Firebase.Firestore.collection(collection_name)
	var result = collection._add_document_listener(doc_name, listener)
	return result

func get_listener_request(config, _extended_url, _collection_name) -> Dictionary:
	var _separator = "/"
	return \
	{
		"addTarget": {
				"documents": [_extended_url + _collection_name + _separator + doc_name]
			}
	}

# Call print(document) to return directly this document formatted
func _to_string() -> String:
	return ("doc_name: {doc_name}, \ndata: {data}, \ncreate_time: {create_time}\n").format(
		{doc_name = self.doc_name,
		data = document,
		create_time = self.create_time})

func get_value(property : StringName) -> Variant:
	if property == "doc_name":
		return doc_name
	elif property == "collection_name":
		return collection_name
	elif property == "create_time":
		return create_time
	
	if document.has(property):
		var result = Utilities.from_firebase_type(document[property])
		
		return result
	
	return null

func _set(property: StringName, value: Variant) -> bool:
	document[property] = Utilities.to_firebase_type(value)
	return true

func keys():
	return document.keys()
