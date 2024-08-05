@tool
extends Control


var _editor: Control

var type: StringName


func _ready():
	$Type.pressed.connect(_change_type)
	
	$Add.pressed.connect(_add_property)
	$Add.icon = get_theme_icon("Add", "EditorIcons")
	
	update_editor("String")

	
func update_editor(type_name:String, force_reload:=false):
	if _editor:
		_editor.queue_free()
	
	var map = DialogicCharacterEditorCustomSection.property_map[type_name]
	assert(map!=null, "Type %s was invalid. Probably a developer issue."%type_name)
	
	var conversion = DialogicCharacterEditorCustomSection.convert_types(get_editor_value(), type_name)
	var object
	if conversion and not force_reload: object = map["get_editor"].call(conversion)
	else: object = map["get_default_editor"].call()
	type = type_name
	
	_editor = object
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_child(_editor)
	move_child(_editor, 1)
	
	$Type.text = ""
	# Without deferring, this won't work on creating a new property
	(func(): $Type.icon = get_theme_icon(type_name, "EditorIcons")).call_deferred()


func _change_type():
	var type_menu = get_parent().get_node("%TypeMenu")
	type_menu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))
	type_menu.set_meta("pressed", self)


func get_editor_value() -> Variant:
	if not _editor:
		return null
	
	if "color" in _editor: ## COLOR PICKER BUTTON
		return _editor.color # (should be first as it has a 'value' property too which is null)
	if "button_pressed" in _editor: ## TOGGLE
		return _editor.button_pressed
	if "text" in _editor: ## TEXT FIELDS
		return _editor.text
	if "value" in _editor: ## SPINBOX
		return _editor.value
	if "current_value" in _editor: ## FILE PATH THING
		return _editor.current_value
	## Other checks can be added here.
	assert(false, "Editor does not have a value. This is a developer issue.")
	return null


func _add_property():
	if $LineEdit.text in [null, ""]:
		push_error("Can't add a property without a name.")
		return
		
	if not get_parent().is_unique_key($LineEdit.text):
		push_error("Property key is not unique.")
		return
	
	var value = get_editor_value() 
	#if value == null:
		#push_error("Can't add a property with a null value.")
		#return
	
	get_parent().create_property($LineEdit.text, value, type)
	
	# Resets the fields
	$LineEdit.text = ""
	update_editor(type,true)
