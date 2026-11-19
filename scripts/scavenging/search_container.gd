class_name SearchContainer
extends SupplyInteractable

signal searched(container: SearchContainer)

@export var cache_id: StringName
@export var title := "Supply crate"
@export var loot_table: LootTable
@export_range(1.0, 4.0) var search_seconds := 2.0
@export_enum("Crate", "Locker", "Toolbox", "Luggage", "Cabinet") var style := 0

var contents := InventoryModel.new(36, true)
var is_searched := false
var _indicator: MeshInstance3D
var _flash := 0.0
var _label: Label3D


func _ready() -> void:
	super._ready()
	_build_visual()
	refresh_prompt()
	set_process(false)


func reset_loot(seed_value: int) -> void:
	is_searched = false
	var generated: Array[Dictionary] = []
	if loot_table != null:
		generated = loot_table.generate(seed_value ^ String(cache_id).hash())
	var slots_needed := 1
	for entry in generated:
		slots_needed += ceili(float(entry.amount) / maxi((entry.item as ItemDefinition).stack_limit, 1))
	contents = InventoryModel.new(slots_needed, true)
	for entry in generated:
		contents.add(entry.item, entry.amount)
	refresh_prompt()


func complete() -> bool:
	if is_searched:
		return false
	is_searched = true
	_flash = 0.6
	set_process(true)
	refresh_prompt()
	searched.emit(self)
	return true


func refresh_prompt(searching: bool = false) -> void:
	if searching:
		prompt = "Cancel search · %s" % title
	elif not is_searched:
		prompt = "Search %s · %.1f s" % [title, search_seconds]
	elif contents.used_slots() > 0:
		prompt = "Collect remaining supplies · %s" % title
	else:
		prompt = "Empty · %s" % title
	if _indicator != null:
		var material := _indicator.material_override as StandardMaterial3D
		material.albedo_color = Color("e9b568") if not is_searched else Color("5e8d80")
		material.emission = material.albedo_color
	if _label != null:
		_label.text = "SUPPLIES" if not is_searched else ("SUPPLIES REMAIN" if contents.used_slots() > 0 else "SEARCHED")


func _process(delta: float) -> void:
	_flash = maxf(0, _flash - delta)
	(_indicator.material_override as StandardMaterial3D).emission_energy_multiplier = 0.5 + _flash * 2
	if _flash == 0:
		set_process(false)


func _build_visual() -> void:
	var height := 1.15 if style == 1 or style == 4 else 0.55
	match style:
		0:
			AssetDressing.place(self,"crate",Vector3.ZERO,Vector3(.72/.82527,.55/.34962,.45/.40895)).name = "SearchableProp"
		1:
			EnvironmentArt.place(self,preload("res://assets/environment/supply_locker.glb"),Vector3.ZERO,"SearchableProp")
		2:
			EnvironmentArt.place(self,preload("res://assets/environment/supply_toolbox.glb"),Vector3.ZERO,"SearchableProp")
		3:
			AssetDressing.place(self,"suitcase",Vector3.ZERO,Vector3.ONE*.85).name = "SearchableProp"
		4:
			EnvironmentArt.place(self,preload("res://assets/environment/medical_cabinet.glb"),Vector3.ZERO,"SearchableProp")
	_indicator = MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(0.5, 0.065, 0.025)
	_indicator.mesh = plate
	_indicator.position = Vector3(0, height - 0.12, 0.25)
	_indicator.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	_indicator.material_override = mat
	add_child(_indicator)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, height + 0.28, 0)
	_label.font_size = 32
	_label.pixel_size = 0.005
	_label.modulate = Color("e9b568")
	_label.outline_size = 6
	_label.no_depth_test = false
	add_child(_label)
