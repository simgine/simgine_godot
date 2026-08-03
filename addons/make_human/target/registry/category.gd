class_name MHTargetCategory
extends Resource
## Category object from `target.json`.

## Internal identifier.
##
## Often includes an opposite pair suffix like `-decr-incr`, `-down-up`, `-in-out`.
@export var name: String

## Display label for the UI.
@export var label: String

## If `true`, the category has separate left (`l-`) and right (`r-`) prefixed targets.
@export var has_left_and_right: bool

## Maps opposing directions to targets.
@export var opposites: MHTargetOpposites
