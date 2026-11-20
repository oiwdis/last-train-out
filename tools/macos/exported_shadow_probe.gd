extends "res://scripts/diagnostics/startup_probe.gd"
## External diagnostic over the original signed app/pack. Each covered view
## keeps the production camera, lights, materials, MSAA, SSAO and frame count.
var treatment := "control"
var job: Node
var shadow_viewport: Viewport
var normal_positional_size := 0
var normal_directional_size := 0
var journal: FileAccess
var applied := false

func _initialize() -> void:
	super._initialize()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--treatment="): treatment = arg.trim_prefix("--treatment=")
	journal = FileAccess.open(destination + ".shadow.jsonl", FileAccess.WRITE)
	node_added.connect(observe)

func observe(node: Node) -> void:
	if node.name != &"RenderPreparation" or not node.get_parent() is Game: return
	job = node
	shadow_viewport = node.get_viewport()
	var game := node.get_parent() as Game
	normal_positional_size = shadow_viewport.positional_shadow_atlas_size
	normal_directional_size = GraphicsSettings.PRESETS[game.graphics.current_index].shadow_atlas_size * 2
	if treatment in ["local", "both"]: shadow_viewport.positional_shadow_atlas_size = 512
	if treatment in ["directional", "both"]: RenderingServer.directional_shadow_atlas_set_size(1024,true)
	applied = true
	mark_shadow("begin")
	RenderingServer.frame_pre_draw.connect(check_drain)
	job.tree_exiting.connect(restore,CONNECT_ONE_SHOT)

func check_drain() -> void:
	if job.get("_draining"): restore()

func restore() -> void:
	if not applied: return
	applied = false
	if treatment in ["local", "both"]: shadow_viewport.positional_shadow_atlas_size = normal_positional_size
	if treatment in ["directional", "both"]: RenderingServer.directional_shadow_atlas_set_size(normal_directional_size,true)
	mark_shadow("restored")
	RenderingServer.frame_pre_draw.disconnect(check_drain)

func mark_shadow(label: String) -> void:
	journal.store_line(JSON.stringify({"phase":label,"treatment":treatment,"ms":Time.get_ticks_msec(),
		"positional_atlas":shadow_viewport.positional_shadow_atlas_size,
		"normal_directional":normal_directional_size,"normal_positional":normal_positional_size}))
	journal.flush()
