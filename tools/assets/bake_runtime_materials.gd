extends SceneTree
## Export-only material inventory: the shader baker cannot execute gameplay scripts.
## Rebuild after changing generated art or preset material features. Never instanced in play.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := load("res://scenes/main/main.tscn").instantiate() as Game
	root.add_child(game)
	await process_frame
	await process_frame
	var library := Node3D.new()
	library.name = "RuntimeMaterialLibrary"
	var count := 0
	# Texture pixels do not affect shader variants. Use one tiny placeholder so
	# embedded GLB images cannot be duplicated into this export-only inventory.
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var placeholder := ImageTexture.create_from_image(image)
	image.resource_scene_unique_id = "ShaderImage"
	placeholder.resource_scene_unique_id = "ShaderTexture"
	for preset in 3:
		game.graphics.set_preset(preset)
		for material: StandardMaterial3D in game.graphics._materials:
			var instance := MeshInstance3D.new()
			instance.name = "Preset%dMaterial%d" % [preset,count]
			var mesh := QuadMesh.new()
			mesh.material = _feature_material(material, placeholder)
			mesh.material.resource_scene_unique_id = "Material%d" % count
			mesh.resource_scene_unique_id = "Mesh%d" % count
			instance.mesh = mesh
			library.add_child(instance)
			instance.owner = library
			count += 1
	for label: Label3D in game.find_children("*", "Label3D", true, false):
		var copy := label.duplicate(0)
		copy.text = "_"
		copy.name = "GeneratedLabel%d" % count
		library.add_child(copy)
		copy.owner = library
		count += 1
	for particles: CPUParticles3D in game.find_children("*", "CPUParticles3D", true, false):
		var mesh := particles.mesh
		if mesh == null:
			continue
		var copy := MeshInstance3D.new()
		copy.name = "ParticleMaterial%d" % count
		var quad := QuadMesh.new()
		quad.material = _feature_material(mesh.surface_get_material(0), placeholder)
		quad.material.resource_scene_unique_id = "Material%d" % count
		quad.resource_scene_unique_id = "Mesh%d" % count
		copy.mesh = quad
		library.add_child(copy)
		copy.owner = library
		count += 1
	var packed := PackedScene.new()
	var error := packed.pack(library)
	if error == OK:
		error = ResourceSaver.save(packed, "res://resources/graphics/runtime_material_library.tscn")
	print("[shader-library] ",count," authored preset/material/label entries: ",error_string(error))
	library.free()
	game.queue_free()
	await process_frame
	await process_frame
	FabricatedMesh.clear_cache()
	quit(0 if error == OK else 1)

func _feature_material(material: Material, placeholder: Texture2D) -> Material:
	var copy := material.duplicate() as Material
	for property in copy.get_property_list():
		if copy.get(property.name) is Texture2D:
			copy.set(property.name, placeholder)
	return copy
