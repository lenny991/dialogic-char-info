@tool
extends Control

## Could be expanded to fit anything but I think
## most people will be using strings.
var key: String 
var value: Variant
var type: StringName

var _editor
var _type_button : Button

func init():
	if not _type_button:
		_type_button = Button.new()
		add_child(_type_button)
		_type_button.pressed.connect(_change_type)
	
	if "value_changed" in _editor:
		_editor.value_changed.connect(update_field)


func update_field(property_name, value):
	update(value)


func update(new_value: Variant):
	value = new_value


func get_property() -> Variant:
	return value


func update_editor(type_name:String):
	if _editor:
		_editor.queue_free()
	
	type = type_name
	
	var map = DialogicCharacterEditorCustomSection.property_map[type_name]
	assert(map!=null, "Type %s was invalid. Probably a developer issue."%type_name)
	
	# Attempts to convert it's type
	var conversion = DialogicCharacterEditorCustomSection.convert_types(get_property(), type_name)
	_editor = map["get_editor"].instantiate()
	_editor._set_value(conversion \
		if conversion \
		else map["get_default_editor"])
	if "modify_editor" in map:
		map["modify_editor"].call(_editor)
	
		
	value = conversion
	
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_child(_editor)
	move_child(_editor, -1)
	
	init()
	
	move_child(_type_button, -2)
	(func(): _type_button.icon = get_theme_icon(type_name, "EditorIcons")).call_deferred()


func _change_type():
	var type_menu = get_parent().get_node("%TypeMenu")
	type_menu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))
	type_menu.set_meta("pressed", self)
