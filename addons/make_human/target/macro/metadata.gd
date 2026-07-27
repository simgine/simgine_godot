class_name MHMacroMetadata
extends Resource

## Maps macro attribute names to their definitions.
@export var macrotargets: Dictionary[String, MHMacroTarget]

## Maps combination names to arrays of macro attribute names.
##
## These define which macrotargets are combined to generate compound targets.
@export var combinations: Dictionary[String, PackedStringArray]
