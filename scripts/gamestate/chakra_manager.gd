extends Node

# Preload Player class (so we can use it in type annotations)
const PlayerClass = preload("res://scripts/gamestate/player.gd")

enum ChakraType {NINJUTSU, TAIJUTSU, GENJUTSU, BLOODLINE}

# Dictionary to track current chakra amounts for both players
var player_chakra = {
	"PLAYER1": {},
	"PLAYER2": {}
}

var players = BattleStateManager.PlayerId.keys()

# Default chakra draw count
const DEFAULT_CHAKRA_DRAW = 3

signal chakra_updated(player_id, chakra_data)
signal chakra_spent(player_id, cost_dict)
signal chakra_drawn(player_id, new_chakra)

func _ready():
	# Initialize empty chakra pools for both players
	reset_chakra_pools()
	Logger.info("CHAKRA", "Initialized")

func reset_chakra_pools():
	for player_id in ["PLAYER1", "PLAYER2"]:
		player_chakra[player_id] = {}
		for type in ChakraType.values():
			player_chakra[player_id][type] = 0
	Logger.info("CHAKRA", "Reset chakra pools")
	
func draw_chakra(player_id, amount=DEFAULT_CHAKRA_DRAW):
	Logger.info("CHAKRA", "Drawing " + str(amount) + " chakra for " + player_id)
	var new_chakra = []
	
	# Generate random chakra for the player
	for i in range(amount):
		var random_type = randi() % ChakraType.size()
		add_chakra(player_id, random_type)
		new_chakra.append(random_type)
	
	emit_signal("chakra_updated", player_id, player_chakra[player_id])
	emit_signal("chakra_drawn", player_id, new_chakra)
	
	Logger.info("CHAKRA", "Drew chakra: " + str(new_chakra))
	return new_chakra

# Method to draw chakra directly for a Player object
func draw_chakra_for_player(player: PlayerClass, amount=DEFAULT_CHAKRA_DRAW):
	Logger.info("CHAKRA", "Drawing " + str(amount) + " chakra for Player " + str(player.player_id))
	var new_chakra = []
	
	# Generate random chakra
	for i in range(amount):
		var random_type = randi() % ChakraType.size()
		new_chakra.append(random_type)
		player.add_chakra(random_type, 1)
	
	# For compatibility with existing code
	var player_id_str = "PLAYER" + str(player.player_id + 1)
	emit_signal("chakra_drawn", player_id_str, new_chakra)
	
	Logger.info("CHAKRA", "Drew chakra for player object: " + str(new_chakra))
	return new_chakra

func add_chakra(player_id, chakra_type, amount=1):
	if not player_chakra[player_id].has(chakra_type):
		player_chakra[player_id][chakra_type] = 0
	
	player_chakra[player_id][chakra_type] += amount
	Logger.info("CHAKRA", "Added " + str(amount) + " " + 
		  ChakraType.keys()[chakra_type] + " chakra to " + player_id)
	
	# Emit signal for UI update
	emit_signal("chakra_updated", player_id, player_chakra[player_id])
	
# Get chakra count for a specific type
func get_chakra_count(player_id, chakra_type):
	if player_chakra[player_id].has(chakra_type):
		return player_chakra[player_id][chakra_type]
	return 0
	
# Check if player can afford a cost
func can_afford_cost(player_id, cost_dict):
	for type in cost_dict:
		if get_chakra_count(player_id, type) < cost_dict[type]:
			return false
	return true

# Spend chakra for a cost
func spend_chakra(player_id, cost_dict):
	if can_afford_cost(player_id, cost_dict):
		for type in cost_dict:
			player_chakra[player_id][type] -= cost_dict[type]
		
		emit_signal("chakra_updated", player_id, player_chakra[player_id])
		emit_signal("chakra_spent", player_id, cost_dict)
		return true
	return false

# Get all chakra for a player
func get_all_chakra(player_id):
	return player_chakra[player_id].duplicate()

# Helper function to get the name of a chakra type
func get_type_name(type):
	return ChakraType.keys()[type]
	
# New method to convert from PlayerId enum to string ID
func player_id_to_string(player_id):
	if player_id is int:
		return "PLAYER" + str(player_id + 1)
	return player_id
