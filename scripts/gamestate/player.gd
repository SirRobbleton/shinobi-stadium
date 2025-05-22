class_name Player
extends Node

# Signals
signal chakra_changed(type, old_amount, new_amount)
signal effect_added(effect)
signal effect_removed(effect)
signal card_added_to_team(card)
signal card_removed_from_team(card)

# Player identification
var player_id: int
var player_name: String = "Player"

# Card collections
var owned_cards: Array[CharacterCard] = []
var owned_support_cards: Array = []
var current_team: Array[CharacterCard] = []
var support_deck: Array = []

# Battle state
var effects: Array = []
var chakra_pool: Dictionary = {}
var is_active: bool = false
var has_switched_this_turn: bool = false

# Initialization
func _init(id: int, name: String = ""):
	player_id = id
	if name:
		player_name = name
	
	# Initialize empty chakra pool
	for type in ChakraManager.ChakraType.values():
		chakra_pool[type] = 0

# Team management
func add_card_to_team(card: CharacterCard) -> bool:
	if current_team.size() < 3 and not current_team.has(card):
		current_team.append(card)
		emit_signal("card_added_to_team", card)
		return true
	return false
		
func remove_card_from_team(card: CharacterCard) -> bool:
	if current_team.has(card):
		current_team.erase(card)
		emit_signal("card_removed_from_team", card)
		return true
	return false
	
# Chakra management
func add_chakra(type: int, amount: int) -> void:
	if chakra_pool.has(type):
		var old_amount = chakra_pool[type]
		chakra_pool[type] += amount
		emit_signal("chakra_changed", type, old_amount, chakra_pool[type])
		
func use_chakra(type: int, amount: int) -> bool:
	if chakra_pool.has(type) and chakra_pool[type] >= amount:
		var old_amount = chakra_pool[type]
		chakra_pool[type] -= amount
		emit_signal("chakra_changed", type, old_amount, chakra_pool[type])
		return true
	return false

func get_total_chakra() -> int:
	var total = 0
	for type in chakra_pool:
		total += chakra_pool[type]
	return total

# Effect management
func add_effect(effect) -> void:
	effects.append(effect)
	emit_signal("effect_added", effect)
	
func remove_effect(effect) -> void:
	if effects.has(effect):
		effects.erase(effect)
		emit_signal("effect_removed", effect)
	
func has_effect(effect_type: String) -> bool:
	for effect in effects:
		if effect.type == effect_type:
			return true
	return false

# Turn management
func start_turn() -> void:
	has_switched_this_turn = false
	is_active = true
	
func end_turn() -> void:
	is_active = false
	
	# Process end-of-turn effects
	var effects_to_remove = []
	for effect in effects:
		if effect.has_method("process_turn_end"):
			if effect.process_turn_end():
				effects_to_remove.append(effect)
	
	# Remove expired effects
	for effect in effects_to_remove:
		remove_effect(effect)

# Chakra pool management 
func get_chakra_amount(type: int) -> int:
	if chakra_pool.has(type):
		return chakra_pool[type]
	return 0

func set_chakra(type: int, amount: int) -> void:
	if chakra_pool.has(type):
		var old_amount = chakra_pool[type]
		chakra_pool[type] = amount
		emit_signal("chakra_changed", type, old_amount, amount)

func get_all_chakra() -> Dictionary:
	return chakra_pool.duplicate()
	
# Helper method to check if this player can perform a switch
func can_switch() -> bool:
	return is_active and not has_switched_this_turn
	
# Helper method to perform a switch and update state
func perform_switch() -> void:
	has_switched_this_turn = true 
