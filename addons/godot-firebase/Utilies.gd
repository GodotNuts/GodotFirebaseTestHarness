extends Node
class_name Utilities

static func get_json_data(value):
    Firebase._print(value)
    if value is PackedByteArray:
        value = value.get_string_from_utf8()
    var json = JSON.new()
    var json_parse_result = json.parse(value)
    Firebase._print(json_parse_result)
    if json_parse_result == OK:
        Firebase._print(json.data)
        return json.data
    else:
        json["data"]["error"] = json_parse_result
        Firebase._print(json)
    
    return json
    
static func is_web() -> bool:
    return OS.get_name() in ["HTML5", "Web"]
