@tool
extends DialogicCharacterEditorMainSection
class_name DialogicCharacterEditorCustomSection

## This is very ugly, but it does the job very well
## though it could be somehow reworked into something smarter maybe.

## Also by the way if you're editing this you'll have to reload the editor
## if you make a change as this is assigned on startup only.
#region PROPERTIES
static var property_map = {
	"String": {
		"check": func(x) -> bool: return x is String,
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_text_multiline.tscn"),
		"get_default_editor": "Value",
	},
	"StringName": {
		"check": func(x) -> bool: return x is StringName,
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_text_singleline.tscn"),
		"get_default_editor": "Value",
	},
	"int": {
		"check": func(x) -> bool: return x is int,
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_number.tscn"),
		"modify_editor": (func(editor):
			editor.step = 1),
		"get_default_editor": 0,
	},
	"float": {
		"check": func(x) -> bool: return x is float,
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_number.tscn"),
		"modify_editor": (func(editor):
			editor.step = .001),
		"get_default_editor": 0.0,
	},
	"Color": {
		"check": func(x) -> bool: return x is Color,
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_color.tscn"),
		"get_default_editor": Color.WHITE,
	},
	"bool": {
		"check": func(x) -> bool: return x is bool, 
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_bool_check.tscn"),
		"get_default_editor": false,
	},
	"Vector2": {
		"check": func(x) -> bool: return x is Vector2, 
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_vector2.tscn"),
		"get_default_editor": Vector2.ZERO,
	},
	"Vector3": {
		"check": func(x) -> bool: return x is Vector3, 
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_vector3.tscn"),
		"get_default_editor": Vector3(0,0,0),
	},
	"File": {
		"check": func(x) -> bool: return false, ## A file path default to string if messed with :|
		"get_editor": preload("res://addons/dialogic/Editor/Events/Fields/field_file.tscn"),
		"get_default_editor": "res://",
	}
}
#endregion PROPERTIES

static func convert_types(value_from:Variant, type_to:String):
	
	if null in [value_from, type_to]:
		return null
	
	var value_type = type_string(typeof(value_from))
	
	if value_type == type_to:
		return value_from
	
	if value_type in ["String", "StringName", "File"] \
			and type_to in ["String", "StringName", "File"]:
		return value_from
	
	if value_type == "int" \
			and type_to == "float":
		return value_from
	
	if value_type == "float" \
			and type_to == "int":
		return roundi(value_from)
	
	return null


var min_width := 200

const _loaded_property_path = \
	"res://addons/dialogic/Modules/CharacterInfo/Properties/character_property_edit.gd"


## Holds all property objects (labels and property editors),
## so if iterated upon, a type check is in order
var _property_editors: Array[Control] = []

@onready var _base_resource_properties = DialogicCharacter.new().get_property_list()


#region OVERRIDES

func _get_title() -> String:
	return "Custom"


func _start_opened() -> bool:
	return false


func _ready() -> void:
	min_width = get_minimum_size().x
	
	%RightClickMenu.clear()
	%RightClickMenu.add_icon_item(get_theme_icon("Remove", "EditorIcons"), "Remove", 1)
	%RightClickMenu.add_separator()
	%RightClickMenu.add_icon_item(get_theme_icon("ActionCopy", "EditorIcons"), "Copy Key", 4)
	%RightClickMenu.add_icon_item(get_theme_icon("ActionCopy", "EditorIcons"), "Copy Value", 4)
	%RightClickMenu.add_separator()
	%RightClickMenu.add_icon_item(get_theme_icon("UndoRedo", "EditorIcons"), "Change Type", 4)
	
	%RightClickMenu.index_pressed.connect(_right_click_menu_index_pressed)
	
	%TypeMenu.clear()
	var idx := 0
	for type in property_map:
		%TypeMenu.add_icon_item(get_theme_icon(type, "EditorIcons"), type, 1)
		%TypeMenu.set_meta("index%s" % idx, type)
		idx += 1
	
	%TypeMenu.index_pressed.connect(_type_menu_index_pressed)
	
	$Add.icon = get_theme_icon("Add", "EditorIcons")
	$Add.pressed.connect(func():
		create_property("", "", "String"))


func _load_character(resource:DialogicCharacter) -> void:
	
	## Clears the currently loaded properties
	for loaded_property in _property_editors:
		if not is_instance_valid(loaded_property):
			continue
		loaded_property.queue_free()
	_property_editors = []
	
	var custom_info = resource.custom_info
	
	if DialogicCharacter.CustomInfoName in custom_info:
		var info_dict = custom_info[DialogicCharacter.CustomInfoName]
		for key in info_dict:
			var value = info_dict[key]
			var type:StringName
			if DialogicCharacter.CustomInfoHintsName in custom_info and \
					key in custom_info[DialogicCharacter.CustomInfoHintsName] and\
					custom_info[DialogicCharacter.CustomInfoHintsName][key] != null:
				type = custom_info[DialogicCharacter.CustomInfoHintsName][key]
			else:
				type = find_property_type(value)
			create_property(key, value, type)


func _save_changes(resource:DialogicCharacter) -> DialogicCharacter:
	
	var custom_info = {}
	var custom_info_hints = {}
	
	var used_names = []
	
	for property in _property_editors:
		if not is_instance_valid(property):
			continue
		
		var key = property.key
		
		while key in used_names:
			var n_key = key+str(randi())
			if not key:
				key = "(empty)"
			push_warning("Property '%s' is used twice. (Property has been renamed to '%s' to prevent erasing it)" % [key, n_key])
			key = n_key
		used_names.push_back(key)
		
		custom_info_hints[key] = property.type
		custom_info[key] = property.get_property()
	
	resource.custom_info[DialogicCharacter.CustomInfoName] = custom_info
	resource.custom_info[DialogicCharacter.CustomInfoHintsName] = custom_info_hints
	
	return resource

#endregion OVERRIDES

#region POPUP_MENUS

func _right_click_menu_index_pressed(idx: int):
	match idx:
		0: # DELETE
			%RightClickMenu.get_meta("pressed").queue_free()
		2: # COPY KEY
			DisplayServer.clipboard_set(%RightClickMenu.get_meta("pressed").key)
		3: # COPY VALUE
			DisplayServer.clipboard_set(str(%RightClickMenu.get_meta("pressed").get_property()))
		5: # CHANGE TYPE
			%TypeMenu.set_meta("pressed", %RightClickMenu.get_meta("pressed"))
			%TypeMenu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))

func _type_menu_index_pressed(idx: int):
	# Updates the pressed item's editor to the default type one
	# Could check here if the type was conversible (e.g. String -> StringName or int -> float)
	%TypeMenu.get_meta("pressed").update_editor(%TypeMenu.get_meta("index%s" % idx))

#endregion POPUP_MENUS

func create_property(key:String, value:Variant, type:StringName):
	var property_editor_parent = HBoxContainer.new()
	property_editor_parent.set_script(load("res://addons/dialogic/Modules/CharacterInfo/Properties/character_property_edit.gd"))
	property_editor_parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Properties.add_child(property_editor_parent)
	
	## Sets the property values for saving
	property_editor_parent.key = key
	property_editor_parent.value = value
	
	# Key label
	var label = LineEdit.new()
	label.text = key
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio = .2
	property_editor_parent.add_child(label)
	
	var colon_label = Label.new()
	colon_label.text = ":"
	colon_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	colon_label.custom_minimum_size = Vector2(15,0)
	
	_property_editors.push_back(property_editor_parent)
	
	property_editor_parent.update_editor(type)
	
	label.text_changed.connect(func(t): property_editor_parent.key = t)
	property_editor_parent.mouse_filter = Control.MOUSE_FILTER_PASS
	property_editor_parent.gui_input.connect(func(input): _on_item_gui_event(input, property_editor_parent))



func _on_item_gui_event(event:InputEvent, editor):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			%RightClickMenu.popup_on_parent(Rect2(get_global_mouse_position(), Vector2()))
			%RightClickMenu.set_meta("pressed", editor)


func is_unique_key(key:String):
	for editor in _property_editors:
		if not is_instance_valid(editor): continue
		if editor.key == key: return false
	return true


# Inaccurate but is here for safety
func find_property_type(property) -> StringName:
	for m in property_map:
		if property_map[m]["check"].call(property):
			return m
	return &""
