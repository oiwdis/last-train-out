class_name FogExposure
extends Node
## One component per survivor. Health is deliberately minimal and combat-free.
signal died
var exposure := 0.0
var health := 100.0
var dead := false
var protection := 0.0
var shelter := "OUTDOORS"
var progress := 0.0

func tick(delta: float, depth: float, cover: float, config: FogConfig) -> void:
	if dead or delta <= 0:
		return
	protection = clampf(cover, 0, 0.95)
	if depth >= 0:
		var intensity := (1.0 + clampf(depth / config.depth_scale, 0, 2)) * config.difficulty
		exposure = minf(100, exposure + delta * config.exposure_per_second * intensity * (1 - protection))
		if exposure > config.damage_threshold:
			var dose := (exposure - config.damage_threshold) / (100 - config.damage_threshold)
			health = maxf(0, health - config.damage_per_second * delta * (0.25 + dose) * intensity * (1 - protection))
	else:
		exposure = maxf(0, exposure - delta * config.recovery_per_second)
	if health <= 0:
		dead = true
		died.emit()

func reset() -> void:
	exposure = 0
	health = 100
	dead = false

func snapshot() -> Dictionary:
	return {"health": health, "exposure": exposure}

func restore(data: Dictionary) -> bool:
	for key in ["health", "exposure"]:
		if not data.has(key) or not (data[key] is float or data[key] is int) or not is_finite(float(data[key])) or data[key] < 0 or data[key] > 100:
			return false
	health = data.health
	exposure = data.exposure
	dead = health <= 0
	return true
