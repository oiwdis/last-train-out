class_name TrainConsole
extends Interactable
## Three physical controls; each uses the same train API as the debug controls.

var train: Train
var command := 0


func _ready() -> void:
	super()
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.19
	collider.shape = sphere
	add_child(collider)
	var d := DetailBuilder.new(self)
	d.cylinder(Vector3.ZERO, 0.085, 0.05, [Color("789780"), Color("a2553e"), DetailBuilder.AMBER][command], Vector3(0, 0, PI / 2))
	d.beam(Vector3.ZERO, Vector3(-0.17, 0.12, 0), 0.025, DetailBuilder.STEEL)
	d.finish()
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
	return true


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if train == null:
		return
	prompt = ["Start train", "Apply brake", "Departure mode: %s · change" % train.current_mode.display_name][command]
