extends "res://tools/record_milestone26.gd"
## Short continuation tour. Cuts are labelled; E/V and climbing use real gameplay.

func _run() -> void:
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	game.player.input.scripted = true
	view = game.camera_rig.exploration
	game.graphics.set_preset(quality)
	await _cut(Vector3(16,.05,11),Vector3(9,2.0,8),0,"Tour cut / Harlow waiting hall")
	await _seconds(1.8)
	await _search(&"a_toolbox", "")
	await _cut(Vector3(74,.05,3),Vector3(83,1.6,2),1,"Tour cut / weathered Warehouse B")
	game.player.input.script_move(1)
	await _seconds(1.8)
	game.player.input.clear()
	await _cut(Vector3(104.5,.05,4.5),Vector3(104.5,2.1,.2),1,"Tour cut / timber freight van")
	await _seconds(1.3)
	await _switch()
	await _seconds(.6)
	if not _check(view.perspective == 0,"V switches to first person beside the rebuilt van"):
		return
	var ladder := game.station.get_node("ExplorationDistrict/ContainerLadder") as Ladder
	await _cut(ladder.global_position+Vector3(0,.05,.65),ladder.global_position+Vector3.UP*1.4,0,"Tour cut / climb the replacement container")
	game.player.input.script_interact()
	await _seconds(.4)
	if not _check(game.player.is_attached(),"E grabs the original container ladder"):
		return
	game.player.input.script_move(0,-1)
	var mounted := false
	for frame in 480:
		await get_tree().physics_frame
		if game.player.state == Player.State.MOUNT:
			mounted = true
		if mounted and game.player.is_grounded():
			break
	game.player.input.clear()
	await _seconds(.4)
	if not _check(absf(game.player.global_position.y-2.7)<.1,"container roof remains traversable at 2.7 m"):
		return
	view.aim_at(Vector3(103,2,3))
	await _switch()
	await _seconds(1.5)
	print("[tour26] complete: environment continuation; search, perspective switching and container climb")
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	FabricatedMesh.clear_cache()
	get_tree().quit()
