extends TextureButton
@export var label : String = ''

func _ready() -> void:
	$label.text = "[center]" + label + "[/center]"
