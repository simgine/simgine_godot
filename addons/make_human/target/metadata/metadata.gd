class_name MHTargetMetadata
extends Resource
## Data from `target.json`.
##
## Categorizes all individual morph targets by body region,
## with left/right flags and opposite-direction pairing.

## Body sections.
@export var sections: Dictionary[String, MHTargetSection]
