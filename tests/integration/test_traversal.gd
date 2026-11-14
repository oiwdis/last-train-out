extends TestSuite
## Contextual interactions: vaulting, climbing, ladders and railings - on
## static geometry and on the moving train.

const SANDBOX := "res://scenes/main/movement_sandbox.tscn"

var game: Game
var player: Player
var train: Train
var flat_car: TrainCar
var crew_car: TrainCar
var grab_failures: Array[String] = []


func before_each() -> void:
	game = await spawn_scene(SANDBOX) as Game
	player = game.player
	train = game.train
	flat_car = train.get_node("FlatCar") as TrainCar
	crew_car = train.get_node("CrewCar") as TrainCar
	player.input.scripted = true
	player.input.clear()
	grab_failures.clear()
	player.grab_failed.connect(func(reason: String) -> void: grab_failures.append(reason))


func after_each() -> void:
	await free_spawned()


func _place(position: Vector3, facing: Vector3 = Vector3.RIGHT) -> void:
	player.teleport_to(position, facing)
	await physics_frames(20)


## Waits until the player is in normal movement again (not vaulting/mounting).
func _wait_for_state(wanted: Array[Player.State], limit_ticks: int = 240) -> bool:
	for i in limit_ticks:
		if player.state in wanted:
			return true
		await physics_frames(1)
	return player.state in wanted


# --- Vaulting on static geometry ---------------------------------------------

func test_vault_over_low_crate() -> void:
	await _place(Vector3(34.2, 0.05, 0.4))
	player.input.script_move(1.0)
	for i in 120:
		await physics_frames(1)
		if player.global_position.x > 34.95:
			break
	player.input.script_interact()
	await physics_frames(2)
	check_eq(player.state, Player.State.VAULT, "interact in front of a low crate starts a vault")
	check(await _wait_for_state([Player.State.IDLE, Player.State.WALK]), "vault finishes")
	check_greater(player.global_position.x, 36.5, "player ends up on the far side of the crate")
	check_near(player.global_position.y, 0.0, 0.05, "player is back on the ground")
	check(player.is_grounded(), "player is grounded after the vault")
	player.input.script_move(0.0)


func test_climb_onto_deep_obstacle() -> void:
	await _place(Vector3(38.6, 0.05, 0.4))
	player.input.script_move(1.0)
	for i in 120:
		await physics_frames(1)
		if player.global_position.x > 39.2:
			break
	player.input.script_interact()
	await physics_frames(2)
	check_eq(player.state, Player.State.VAULT, "interact in front of a wide crate starts a climb")
	player.input.script_move(0.0)
	check(await _wait_for_state([Player.State.IDLE]), "climb finishes")
	check_near(player.global_position.y, 1.1, 0.05, "player stands on top of the crate")
	check_greater(player.global_position.x, 39.8, "player is over the crate")
	check(player.is_grounded(), "player is grounded on the crate")


func test_tall_wall_cannot_be_vaulted() -> void:
	await _place(Vector3(45.3, 0.05, 0.0))
	player.input.script_move(1.0)
	await seconds(0.5)
	player.input.script_interact()
	await physics_frames(20)
	check(player.state != Player.State.VAULT, "a 3 m wall is not vaultable")
	check_near(player.global_position.y, 0.0, 0.05, "player stays on the ground")
	check_less(player.global_position.x, 46.0, "player is blocked by the wall")
	player.input.script_move(0.0)


func test_interact_with_nothing_nearby_does_nothing() -> void:
	await _place(Vector3(60.0, 0.05, 0.5))
	var before := player.global_position
	player.input.script_interact()
	await physics_frames(30)
	check_eq(player.state, Player.State.IDLE, "nothing happens without a target")
	check_less(player.global_position.distance_to(before), 0.01, "player did not move")


# --- Static ladder -------------------------------------------------------------

func test_climb_static_ladder_to_the_top() -> void:
	await _place(Vector3(47.0, 0.05, 1.7), Vector3.FORWARD)
	player.input.script_interact()
	check(await _wait_for_state([Player.State.CLIMB]), "interact grabs the ladder")
	check_near(player.global_position.x, 47.0, 0.02, "player is centred on the ladder")
	player.input.script_move(0.0, -1.0)  # W climbs.
	var saw_mount := false
	for i in 240:
		await physics_frames(1)
		if player.state == Player.State.MOUNT:
			saw_mount = true
		if saw_mount and player.is_grounded():
			break
	player.input.script_move(0.0)
	await physics_frames(10)
	check(saw_mount, "player climbed off the top of the ladder")
	check_near(player.global_position.y, 3.0, 0.06, "player stands on the tower")
	check_less(player.global_position.z, 0.95, "player moved onto the tower top")
	check(player.is_grounded(), "player is grounded on the tower")


func test_climb_down_ladder_from_the_top() -> void:
	await _place(Vector3(47.0, 3.05, 0.4), Vector3.BACK)
	check(player.is_grounded(), "player starts on the tower")
	player.input.script_interact()
	check(await _wait_for_state([Player.State.CLIMB]), "interact at the top grabs the ladder")
	player.input.script_move(0.0, 1.0)  # S climbs down.
	check(await _wait_for_state([Player.State.IDLE, Player.State.WALK, Player.State.FALL], 300), "player steps off at the bottom")
	player.input.script_move(0.0)
	await physics_frames(20)
	check_near(player.global_position.y, 0.0, 0.05, "player is back on the ground")
	check_greater(player.global_position.z, 1.1, "player is in front of the tower")


func test_jump_off_ladder() -> void:
	await _place(Vector3(47.0, 0.05, 1.7), Vector3.FORWARD)
	player.input.script_interact()
	check(await _wait_for_state([Player.State.CLIMB]), "player is on the ladder")
	player.input.script_move(0.0, -1.0)
	await seconds(0.4)
	player.input.script_move(0.0)
	var height := player.global_position.y
	check_greater(height, 0.6, "player climbed up")
	await physics_frames(5)
	check_near(player.global_position.y, height, 0.001, "player holds position on the ladder without input")
	player.input.script_jump()
	await physics_frames(3)
	check(player.state in [Player.State.JUMP, Player.State.FALL], "jump lets go of the ladder")
	check(await _wait_for_state([Player.State.IDLE], 200), "player lands")
	check_greater(player.global_position.z, 1.9, "player jumped away from the wall")
	check_near(player.global_position.y, 0.0, 0.05, "player is on the ground")


func test_regrab_is_blocked_briefly_after_letting_go() -> void:
	await _place(Vector3(47.0, 0.05, 1.7), Vector3.FORWARD)
	player.input.script_interact()
	check(await _wait_for_state([Player.State.CLIMB]), "player is on the ladder")
	await physics_frames(10)
	player.input.script_interact()  # Let go.
	await physics_frames(2)
	check(player.state != Player.State.CLIMB, "second press lets go of the ladder")
	player.input.script_interact()  # Immediate re-press: must be ignored.
	await physics_frames(4)
	check(player.state != Player.State.CLIMB and player.state != Player.State.MOUNT, "ladder cannot be re-grabbed instantly")
	await seconds(player.config.regrab_cooldown + player.config.interact_buffer_time + 0.1)
	player.input.script_interact()
	check(await _wait_for_state([Player.State.CLIMB], 60), "ladder can be grabbed again after the cooldown")


# --- Moving train ---------------------------------------------------------------

## Brings the train to a steady [param speed] by lowering its maximum speed.
func _cruise_at(speed: float) -> void:
	train.max_speed = speed
	train.set_mode_index(0)
	train.start()
	for i in 600:
		await physics_frames(1)
		if train.state == Train.State.CRUISING:
			return


func test_grab_moving_ladder_and_climb_to_roof() -> void:
	var ladder := crew_car.get_node("RoofLadder") as Ladder
	await _cruise_at(3.0)
	# Stand on the platform edge ahead of the ladder and let it come to us.
	await render_frame()
	player.teleport_to(Vector3(ladder.global_position.x + 4.0, 1.05, -1.55), Vector3.FORWARD)
	var grabbed := false
	for i in 600:
		await physics_frames(1)
		if absf(ladder.global_position.x - player.global_position.x) < 0.5:
			player.input.script_interact()
			grabbed = await _wait_for_state([Player.State.CLIMB], 40)
			break
	check(grabbed, "player grabbed the ladder of the moving train")
	check(player.is_on_train(), "clinging to the ladder counts as being on the train")
	check_near(player.get_world_velocity().x, train.speed, 0.2, "player moves with the train while holding on")
	player.input.script_move(0.0, -1.0)
	var saw_mount := false
	for i in 300:
		await physics_frames(1)
		if player.state == Player.State.MOUNT:
			saw_mount = true
		if saw_mount and player.is_grounded():
			break
	player.input.script_move(0.0)
	await physics_frames(20)
	await render_frame()
	check(saw_mount, "player climbed off the top of the moving ladder")
	check(player.is_grounded(), "player stands on the roof")
	check(player.is_on_train(), "player is riding the train")
	check_near(crew_car.to_local(player.global_position).y, 3.62, 0.06, "player is at roof height")
	var before := crew_car.to_local(player.global_position)
	await seconds(1.0)
	await render_frame()
	check_less(crew_car.to_local(player.global_position).distance_to(before), 0.02, "player rides the roof without sliding")


func test_fast_ladder_cannot_be_grabbed_standing_still() -> void:
	var ladder := crew_car.get_node("RoofLadder") as Ladder
	await _place(Vector3(ladder.global_position.x + 60.0, 0.05, -1.75), Vector3.FORWARD)
	await _cruise_at(12.0)
	var tried := false
	for i in 900:
		await physics_frames(1)
		if absf(ladder.global_position.x - player.global_position.x) < 0.6:
			player.input.script_interact()
			tried = true
			break
	await physics_frames(20)
	check(tried, "the ladder passed the player")
	check(player.state != Player.State.CLIMB and player.state != Player.State.MOUNT, "a 12 m/s ladder is too fast to catch from a standstill")
	check_eq(grab_failures.size(), 1, "the failed grab is reported exactly once")


func test_sprinting_player_catches_fast_ladder() -> void:
	var ladder := crew_car.get_node("RoofLadder") as Ladder
	await _place(Vector3(ladder.global_position.x + 60.0, 0.05, -1.75), Vector3.RIGHT)
	await _cruise_at(12.0)
	var grabbed := false
	for i in 900:
		await physics_frames(1)
		var gap := player.global_position.x - ladder.global_position.x
		if gap < 6.0:
			player.input.script_move(1.0, 0.0, true)  # Run with the train as it arrives.
		if gap < 0.4:
			player.input.script_interact()
			grabbed = await _wait_for_state([Player.State.CLIMB], 40)
			break
	player.input.script_move(0.0)
	check(grabbed, "matching speed makes the fast ladder catchable")
	check_eq(grab_failures.size(), 0, "no failed grab was reported")
	await physics_frames(10)
	check_near(player.get_world_velocity().x, train.speed, 0.2, "player is carried at train speed")


func test_grab_railing_and_climb_over() -> void:
	var rail := flat_car.get_node("SideRailRear") as GrabRail
	await _place(Vector3(rail.global_position.x + 0.4, 1.05, -1.5), Vector3.FORWARD)
	player.input.script_interact()
	check(await _wait_for_state([Player.State.HANG]), "interact grabs the railing")
	check_near(player.global_position.y, 1.0, 0.03, "player clings at deck height")
	await physics_frames(10)
	player.input.script_move(0.0, -1.0)  # Push toward the car.
	var saw_mount := false
	for i in 200:
		await physics_frames(1)
		if player.state == Player.State.MOUNT:
			saw_mount = true
		if saw_mount and player.is_grounded():
			break
	player.input.script_move(0.0)
	await physics_frames(10)
	check(saw_mount, "player climbed over the railing")
	check(player.is_on_train(), "player stands on the flat car")
	check_less(flat_car.to_local(player.global_position).z, 1.0, "player is inside the railing")


func test_grab_moving_railing_from_the_ground() -> void:
	var rail := flat_car.get_node("SideRailFront") as GrabRail
	# Beyond the end of the platform there is only ground beside the track.
	await _place(Vector3(52.0, 0.05, -1.75), Vector3.FORWARD)
	await _cruise_at(4.0)
	var grabbed := false
	for i in 900:
		await physics_frames(1)
		if absf(rail.global_position.x - player.global_position.x) < 0.8:
			player.input.script_interact()
			grabbed = await _wait_for_state([Player.State.HANG], 40)
			break
	check(grabbed, "player caught the passing railing from ground level")
	check_near(player.global_position.y, 1.0, 0.05, "player is pulled up to deck height")
	player.input.script_move(0.0, -1.0)
	var aboard := false
	for i in 200:
		await physics_frames(1)
		if player.is_grounded() and player.is_on_train():
			aboard = true
			break
	player.input.script_move(0.0)
	check(aboard, "player climbed over onto the moving deck")
	await physics_frames(20)
	await render_frame()
	var before := flat_car.to_local(player.global_position)
	await seconds(1.0)
	await render_frame()
	check_less(flat_car.to_local(player.global_position).distance_to(before), 0.02, "player rides along without sliding")


func test_vault_crate_on_moving_flat_car() -> void:
	# Cargo crate A sits at x -2.45..-1.35 on the flat car; approach it from the open deck.
	await _place(flat_car.to_global(Vector3(-0.2, 1.05, -0.65)), Vector3.LEFT)
	await _cruise_at(8.0)
	player.input.script_move(-1.0)
	for i in 120:
		await physics_frames(1)
		if flat_car.to_local(player.global_position).x < -0.75:
			break
	player.input.script_interact()
	await physics_frames(2)
	check_eq(player.state, Player.State.VAULT, "vault starts on the moving car")
	player.input.script_move(0.0)
	check(await _wait_for_state([Player.State.IDLE, Player.State.WALK], 200), "vault finishes")
	await physics_frames(10)
	var local := flat_car.to_local(player.global_position)
	note("landed at car-local x %.2f, y %.2f" % [local.x, local.y])
	check_less(local.x, -2.4, "player cleared the crate relative to the car")
	check_near(local.y, 1.0, 0.05, "player is back on the deck")
	check(player.is_on_train(), "player is still riding the train")


func test_jump_from_platform_onto_moving_flat_car() -> void:
	# Wait beside the flat car, let the train pull away, then run along the
	# platform edge keeping pace with the open deck and jump diagonally onto it.
	await _place(Vector3(flat_car.global_position.x + 3.0, 1.05, -1.5))
	train.set_mode_index(1)  # Normal departure.
	train.start()
	var jumped := false
	for i in 900:
		await physics_frames(1)
		# How far the player is ahead of the middle of the deck.
		var lead := player.global_position.x - flat_car.global_position.x
		if lead > 0.4:
			player.input.script_move(0.0)
		elif lead < -0.4:
			player.input.script_move(1.0, 0.0, true)
		else:
			player.input.script_move(1.0)
		if train.speed > 4.0 and absf(lead) < 0.6 and player.is_grounded():
			player.input.script_move(1.0, -1.0, true)
			player.input.script_jump()
			jumped = true
			break
	check(jumped, "found a moment to jump")
	var speed_at_jump := train.speed
	var aboard := false
	for i in 120:
		await physics_frames(1)
		if player.is_grounded():
			aboard = player.is_on_train()
			break
	player.input.script_move(0.0)
	note("jumped at train speed %.1f m/s" % speed_at_jump)
	check(aboard, "player landed on the moving flat car")
	await seconds(0.5)
	await render_frame()
	var before := flat_car.to_local(player.global_position)
	check_near(before.y, 1.0, 0.05, "player stands on the deck")
	await seconds(2.0)
	await render_frame()
	check(player.is_on_train(), "player keeps riding")
	check_less(flat_car.to_local(player.global_position).distance_to(before), 0.02, "no sliding after boarding")


func test_walking_onto_moving_deck_carries_the_player() -> void:
	await _place(Vector3(flat_car.global_position.x + 0.6, 1.05, -1.5), Vector3.FORWARD)
	await _cruise_at(2.0)
	# The deck's open middle section is still alongside: just walk aboard.
	var target_x := flat_car.global_position.x
	player.teleport_to(Vector3(target_x + 0.8, 1.05, -1.5), Vector3.FORWARD)
	await physics_frames(6)
	player.input.script_move(0.0, -1.0)
	var aboard := false
	for i in 120:
		await physics_frames(1)
		if player.is_on_train() and flat_car.to_local(player.global_position).z < 0.8:
			aboard = true
			break
	player.input.script_move(0.0)
	check(aboard, "player walked from the platform onto the moving deck")
	await seconds(1.0)
	check(player.is_on_train(), "player is carried by the train")
	check_near(player.get_world_velocity().x, train.speed, 0.1, "player moves at train speed")


func test_obstacle_in_the_way_knocks_a_climber_off_instead_of_dragging_through() -> void:
	var ladder := crew_car.get_node("RoofLadder") as Ladder
	# Put a solid post right where a climber on the train's side would pass.
	var post := StaticBody3D.new()
	post.collision_layer = 1
	post.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 6.0, 0.4)
	shape.shape = box
	post.add_child(shape)
	game.add_child(post)
	post.global_position = Vector3(ladder.global_position.x + 14.0, 3.0, -1.7)
	await _place(Vector3(ladder.global_position.x, 1.05, -1.6), Vector3.FORWARD)
	player.input.script_interact()
	check(await _wait_for_state([Player.State.CLIMB]), "player holds the ladder")
	train.set_mode_index(0)
	train.start()
	var let_go := false
	for i in 600:
		await physics_frames(1)
		if player.state != Player.State.CLIMB:
			let_go = true
			break
	check(let_go, "the post knocked the climber off the ladder")
	check_less(player.global_position.x, post.global_position.x + 0.2, "the climber was not dragged through the post")
	check(await _wait_for_state([Player.State.IDLE], 240), "the climber lands and recovers")
	check_greater(player.global_position.y, -0.1, "the climber is on solid ground")

