class_name MHRigWeights
extends Resource
## Assigns deformation weights from bones (or special groups) to
## individual mesh vertices.
##
## Used to skin the MakeHuman base mesh to an armature.
##
## Imported from `weights.game_engine.json`.

## Maps bone names to their weighted base mesh vertices.
@export_storage var bones: Dictionary[StringName, MHBoneWeights]
