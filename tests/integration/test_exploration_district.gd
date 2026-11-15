extends TestSuite

var game: Game


func before_each() -> void:
	game = await spawn_scene("res://scenes/main/main.tscn", 8) as Game
	game.player.input.scripted = true


func after_each() -> void:
	await free_spawned()


func test_service_and_trackside_routes_connect_freight_to_platform() -> void:
	game.player.teleport_to(Vector3(30, 0.05, 7.3))
	await seconds(0.3)
	var bot := RouteBot.new(game.player)
	var ok := await bot.run([
		{"to": Vector3(65, 0, 7.3)}, {"to": Vector3(100, 0, 7.3)},
		{"to": Vector3(123, 0, 7.3)}, {"to": Vector3(123, 0, -7)},
		{"to": Vector3(82, 0, -7)}, {"to": Vector3(40, 0, -7)},
		{"to": Vector3(34, 0, -7)}, {"to": Vector3(34, 0, 5)}])
	check(ok, "complete exterior circuit uses both routes: %s" % bot.failure)
	check(game.player.is_grounded(), "exterior route has continuous ground")


func test_waiting_hall_and_platform_approach_are_walkable() -> void:
	game.player.teleport_to(Vector3(15, 0.05, 6))
	await seconds(0.3)
	var bot := RouteBot.new(game.player)
	check(await bot.run([{"to": Vector3(15, 0, 12)}, {"to": Vector3(17, 0, 12)}, {"to": Vector3(15, 0, 9)}, {"to": Vector3(15, 0, 6)}, {"to": Vector3(22.5, 0, 6.7)}, {"to": Vector3(22.5, 1, 2.4)}]), "walk through waiting hall and climb platform steps: %s" % bot.failure)
	check_near(game.player.global_position.y, 1, 0.06, "approach reaches platform height")


func test_added_container_ladder_reaches_roof() -> void:
	var district := game.station.get_node("ExplorationDistrict")
	var ladder := district.get_node("ContainerLadder") as Ladder
	game.player.teleport_to(ladder.global_position + Vector3(0, 0.05, 0.65), Vector3.FORWARD)
	await seconds(0.3)
	game.camera_rig.exploration.aim_at(ladder.global_position + Vector3.UP * 1.4)
	game.player.input.script_interact()
	await seconds(0.4)
	check(game.player.is_attached(), "new yard ladder can be grabbed through camera targeting")
	var bot := RouteBot.new(game.player)
	check(await bot.run([{"to": game.player.global_position, "then": "climb_up"}]), "climb finishes on the roof")
	check_near(game.player.global_position.y, 2.7, 0.06, "new cargo roof is traversable")


func test_station_reset_restores_door_states_and_preserves_camera() -> void:
	var district := game.station.get_node("ExplorationDistrict") as ExplorationDistrict
	var door := district.doors[1]
	game.player.teleport_to(door.global_position + Vector3(0.8, 0.05, 0))
	await seconds(0.3)
	check(door.interact(game.player), "warehouse door closes")
	game.camera_rig.exploration.request_perspective(0)
	game.reset_station()
	await seconds(0.5)
	check(door.is_open, "reset restores authored open entrance")
	check_near(door._panel.rotation.y, -PI / 2, 0.01, "reset cancels an in-flight close animation")
	check(door._collider.disabled, "reset door collider agrees with visible open panel")
	check_eq(game.camera_rig.exploration.perspective, 0, "reset preserves selected camera")
