@tool
extends Control

@onready var add = $Add
var _editor : Control

func _ready():
	_editor = $LineEdit

func update_editor(object):
	if _editor:
		_editor.queue_free()
	_editor = object
	add_child(object)
	
	## Moves the add button as last
	move_child(add, get_child_count()-1)

func get_editor_value() -> Variant:
	if "text" in _editor:
		return _editor.text
	if "value" in _editor:
		return _editor.value
	## Other checks can be added here.
	return null
