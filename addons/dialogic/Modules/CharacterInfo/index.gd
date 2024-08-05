@tool
extends DialogicIndexer


func _get_character_editor_sections() -> Array:
	return [this_folder.path_join('char_edit_section_custom.tscn')]
