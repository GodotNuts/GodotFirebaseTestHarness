extends TextureButton
export var label : String = ''

func _ready() -> void:
	$label.bbcode_text = "[center]" + label + "[/center]"
