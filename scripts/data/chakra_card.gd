# chakra_card.gd
extends "res://scripts/data/battle_card.gd"
class_name ChakraCard

@export var chakra_type: int  # Using the GameStateManager.ChakraType enum
@export var chakra_amount: int = 1

func _init(card_id: String = "", card_name: String = ""):
	super(card_id, card_name)
	card_type = "chakra"

func play(game_state, player: String, target = null) -> bool:
	# Chakra cards don't have a cost, so no need to check or pay
	
	print("[CHAKRA_CARD| Playing chakra card: " + name)
	
	# Add chakra of the card's type to the player's pool
	if player == "player":
		game_state.add_chakra(player, chakra_type, chakra_amount)
	else:
		game_state.add_chakra(player, chakra_type, chakra_amount)
	
	return true

# Chakra cards don't need targets
func get_valid_targets(game_state, player: String) -> Array:
	return [] 
