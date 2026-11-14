class_name LootTable
extends Resource
## Uses its own RNG. Searching/cancelling and unrelated random calls cannot change a cache.

@export var entries: Array[LootEntry] = []
@export_range(1, 12) var rolls := 3


func generate(seed_value: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var total_weight := 0.0
	for entry in entries:
		if entry.item != null:
			total_weight += maxf(entry.weight, 0)
	var result: Array[Dictionary] = []
	if total_weight <= 0:
		return result
	for roll in rolls:
		var cursor := rng.randf() * total_weight
		for entry in entries:
			if entry.item == null or entry.weight <= 0:
				continue
			cursor -= entry.weight
			if cursor <= 0:
				result.append({"item": entry.item, "amount": rng.randi_range(maxi(entry.minimum, 1), maxi(entry.maximum, entry.minimum))})
				break
	return result
