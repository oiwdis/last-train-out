class_name CameraZone
extends Area3D
## A volume that asks camera rigs to use a different framing while their
## target is inside (e.g. zoom in when indoors). Zones and rigs only know each
## other through the "camera_rigs" group, so buildings stay self-contained.

const PLAYER_LAYER := 1 << 1

@export var profile: CameraProfile
## Higher priority wins when several framings are requested at once.
@export var camera_priority := 10


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	get_tree().call_group(&"camera_rigs", &"on_camera_zone_entered", self, body)


func _on_body_exited(body: Node3D) -> void:
	if is_inside_tree():
		get_tree().call_group(&"camera_rigs", &"on_camera_zone_exited", self, body)
