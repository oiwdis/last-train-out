class_name ItemVisual
extends Node3D
## Small, distinct primitive models sharing the inventory icon palette.


func configure(item: ItemDefinition) -> void:
	var d := DetailBuilder.new(self, "SupplyModel")
	var tint := item.tint
	match item.id:
		&"coal_sack":
			add_child(preload("res://assets/models/coal_sack.glb").instantiate())
			d.box(Vector3(0, 0.33, 0.195), Vector3(0.29, 0.25, 0.015), DetailBuilder.INK)
			d.lettering(Vector3(0, 0.33, 0.21), "COAL", 0.08)
		&"fuel_drum":
			d.cylinder(Vector3(0, 0.38, 0), 0.28, 0.76, tint)
			for y in [0.07, 0.62]:
				d.cylinder(Vector3(0, y, 0), 0.29, 0.045, DetailBuilder.INK)
			d.lettering(Vector3(0, 0.36, 0.285), "FUEL", 0.085)
		&"machine_component":
			d.box(Vector3(0, 0.3, 0), Vector3(0.5, 0.54, 0.42), DetailBuilder.INK)
			for x in [-0.23, 0.23]:
				d.box(Vector3(x, 0.3, 0), Vector3(0.08, 0.6, 0.46), tint)
			d.cylinder(Vector3(0, 0.33, 0.26), 0.18, 0.15, tint, Vector3(PI / 2, 0, 0))
			d.box(Vector3(0, 0.62, 0), Vector3(0.24, 0.1, 0.12), DetailBuilder.AMBER)
		&"canned_food", &"medicine", &"lantern_oil":
			d.cylinder(Vector3(0, 0.18, 0), 0.13, 0.36, tint)
			d.cylinder(Vector3(0, 0.38, 0), 0.08, 0.05, DetailBuilder.PALE)
			d.box(Vector3(0, 0.2, 0.13), Vector3(0.14, 0.13, 0.015), DetailBuilder.INK)
		_:
			d.box(Vector3(0, 0.13, 0), Vector3(0.36, 0.26, 0.25), tint)
			d.box(Vector3(0, 0.14, 0.13), Vector3(0.08, 0.26, 0.02), DetailBuilder.INK)
	d.finish()
