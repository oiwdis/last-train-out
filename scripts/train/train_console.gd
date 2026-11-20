class_name TrainConsole
extends Interactable
## Three physical controls; each uses the same train API as the debug controls.

var train: Train
var command := 0
var _handle: Node3D


func _ready() -> void:
	super()
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.19
	collider.shape = sphere
	add_child(collider)
	var fixture := preload("res://assets/train/control_lever.glb").instantiate()
	add_child(fixture)
	_handle = fixture.find_child("Handle", true, false) as Node3D
	set_process(true)
	_refresh()


func can_interact(player: Player) -> bool:
	return enabled and global_position.distance_to(player.global_position + Vector3.UP) < 1.7


func interact(player: Player) -> bool:
	if not can_interact(player):
		return false
	match command:
		0: train.start()
		1: train.stop()
		2: train.set_mode_index((train.get_mode_index() + 1) % 3)
	_refresh()
	player.present_action(&"operate", .8, _handle.to_global(Vector3(-.19,.15,0)), _handle)
	return true


func _process(_delta: float) -> void:
	_refresh()
	if _handle != null and train != null:
		if command == 2:
			_handle.rotation.z = (train.get_mode_index() - 1) * 0.22
			return
		var engaged := train.state == Train.State.ACCELERATING if command == 0 else train.state == Train.State.BRAKING
		_handle.rotation.z = -0.35 if engaged else 0.0


func _refresh() -> void:
	if train == null:
		return
	prompt = ["Start train", "Apply brake", "Departure mode: %s · change" % train.current_mode.display_name][command]
