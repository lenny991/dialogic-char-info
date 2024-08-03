@tool
extends Control

##TODO: listen for changes on base

## Could be expanded to fit anything but I think
## most people will be using strings.
var key : String 
var value : Variant

func get_property() -> Variant:
	return value
