class_name FogFuel
extends Node
## Supply adapter: consumes stored coal and calls existing start/stop APIs.
var amount := 0.0
var train: Train
var game: Game
var config: FogConfig
var bunker: SupplyInteractable

func bind(owner_game: Game, tuning: FogConfig) -> void:
	game = owner_game
	train = game.train
	config = tuning
	amount = config.initial_fuel
	train.departure_allowed = func() -> bool: return amount > 0
	bunker = SupplyInteractable.new()
	bunker.name = "StokeBoiler"
	bunker.position = Vector3(-3.3, 1.3, -0.55)
	bunker.prompt = "Stoke boiler · one stored coal sack"
	bunker.reach = 1.7
	bunker.action = func(_who: Player) -> bool:
		var added := refuel()
		game.hud.show_message("Boiler stoked · +45 fuel" if added else "Deposit a coal sack in train storage first · boiler must have room", 4)
		return true
	train.get_node("Locomotive").add_child(bunker)

func tick(delta: float) -> void:
	if train.state != Train.State.STOPPED:
		amount = maxf(0, amount - config.fuel_per_second * delta)
	if amount <= 0:
		train.stop()

func refuel() -> bool:
	if amount > config.fuel_capacity - config.fuel_per_sack:
		return false
	var inventory := game.inventory_system.storage
	for i in inventory.slot_count:
		var slot := inventory.get_slot(i)
		if not slot.is_empty() and slot.item.id == &"coal_sack":
			if inventory.remove_at(i, 1) == 1:
				amount += config.fuel_per_sack
				return true
	return false
