@tool
extends DialogicCharacterEditorMainSection

var min_width := 200

const _loaded_property_path = \
	"res://addons/dialogic/Modules/CharacterInfo/Properties/character_property_edit.gd"

## Holds all property objects (labels and property editors),
## so if iterated upon, a type check is in order
var _property_objects: Array[Control] = []
var _add_button : Control

@onready var _base_resource_properties = DialogicCharacter.new().get_property_list()

## The general character settings tab
func _get_title() -> String:
	return "Custom"


func _start_opened() -> bool:
	return false


func _ready() -> void:
	min_width = get_minimum_size().x
	resized.connect(_on_resized)


func _load_character(resource:DialogicCharacter) -> void:
	
	## Clears the currently loaded properties
	for loaded_property in _property_objects:
		if not is_instance_valid(loaded_property):
			continue
		loaded_property.queue_free()
	_property_objects = []
	
	if "custom-character-info" in resource.custom_info:
		var info_dict = resource.custom_info["custom-character-info"]
		for key in info_dict:
			var info = info_dict[key]
			_create_property(key, info)
	
	_create_add_button()


func _create_property(key:String, value:Variant):
	var label = Label.new()
	label.text = key+":"
	$Properties.add_child(label)
	
	var property_editor: Control = get_property_editor(value)
	property_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_editor.set_script(load("res://addons/dialogic/Modules/CharacterInfo/Properties/character_property_edit.gd"))
	
	## Sets the property values for saving
	property_editor.key = key
	property_editor.value = value
	
	$Properties.add_child(property_editor)
	
	_property_objects.push_back(label)
	_property_objects.push_back(property_editor)


func _create_property_add():
	var line := LineEdit.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_property_objects.push_back(line)
	add_child(line)
	
	var add_property: Control = load("res://addons/dialogic/Modules/CharacterInfo/Properties/add_property.tscn").instantiate()
	_property_objects.push_back(add_property)
	add_property.size_flags_stretch_ratio = 2
	add_child(add_property)
	
	add_property.add.get_node("Button").pressed.connect(func():
		
		if line.text in [null, ""]:
			push_error("Can't add a property without a name.")
			return
		
		var value = add_property.get_editor_value() 
		if not value:
			push_error("Can't add a property with a null value.")
			return
		##TODO: check for existing property keys
		
		_create_property(line.text, value)
	)


func _create_add_button():
	var add = load("res://addons/dialogic/Modules/CharacterInfo/Properties/add_button.tscn").instantiate()
	_property_objects.push_back(add)
	add_child(add)
	
	var add_button: Button = add.get_node("Button")
	add_button.pressed.connect(_add_property)
	_add_button = add


func _save_changes(resource:DialogicCharacter) -> DialogicCharacter:
	if not "custom-character-info" in resource.custom_info:
		resource.custom_info["custom-character-info"] = {}
	for property in _property_objects:
		if "get_property" not in property: continue
		
		resource.custom_info["custom-character-info"][property.key] = \
				property.get_property()
	
	return resource


func _add_property():
	## This works hopefully, but may not be safe
	_create_property_add()
	move_child(_add_button, get_child_count()-1)


func get_property_editor(property) -> Variant:
	#var hint = property["hint"]
	#print(hint)
	if property is StringName: 
		var line = LineEdit.new()
		line.text = property
		return line
	if property is String: 
		var tx = TextEdit.new()
		tx.text = property
		return tx
	if property is int: return _create_spinbox(property)
	if property is float: return _create_spinbox(property)

	return null


func _create_spinbox(for_val):
	var sb = SpinBox.new()
	if for_val is int: sb.step = 1
	if for_val is float: sb.step = 0.1 
	return sb


func _on_resized() -> void:
	if size.x > min_width+20:
		$Properties.columns = 2
	else:
		$Properties.columns = 1
