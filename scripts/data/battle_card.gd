extends Resource
class_name BattleCard

# Common card properties
@export var id: String
@export var name: String
@export var description: String
@export var card_type: String  # "chakra", "support", "trap"
@export var image_path: String

# Chakra cost
@export var cost: Dictionary = {}  # {chakra_type: amount}

# Card effects
@export var effects: Array = []  # [{type, value, duration}]

func _init(card_id: String = "", card_name: String = ""):
	id = card_id
	name = card_name

func can_be_played(game_state, player: String) -> bool:
	# Default implementation - check if player has enough chakra
	if player == "player":
		return check_chakra_cost(game_state.player_chakra)
	else:
		return check_chakra_cost(game_state.opponent_chakra)

func check_chakra_cost(player_chakra: Dictionary) -> bool:
	# Check if player has enough chakra to play this card
	for chakra_type in cost:
		if not player_chakra.has(chakra_type) or player_chakra[chakra_type] < cost[chakra_type]:
			return false
	return true

func play(game_state, player: String, target = null) -> bool:
	# Base implementation - subtract chakra cost
	if not can_be_played(game_state, player):
		return false
		
	# Pay the chakra cost
	for chakra_type in cost:
		if player == "player":
			game_state.player_chakra[chakra_type] -= cost[chakra_type]
		else:
			game_state.opponent_chakra[chakra_type] -= cost[chakra_type]
			
	# Apply effects (to be implemented in subclasses)
	return true
	
func get_valid_targets(game_state, player: String) -> Array:
	# Base implementation - to be overridden by subclasses
	return []
