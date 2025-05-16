extends Node

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
	for player_id in ["player", "opponent"]:
		player_chakra[player_id] = {}
		for type in ChakraType.values():
			player_chakra[player_id][type] = 0
	Logger.info("CHAKRA", "Reset chakra pools")
	
func draw_chakra(player_id, amount=DEFAULT_CHAKRA_DRAW):
	Logger.info("CHAKRA", "Drawing " + str(amount) + " chakra for Player" + str(player_id))
	var new_chakra = []
	
	# Generate random chakra for the player
	for i in range(amount):
		var random_type = randi() % ChakraType.size()
		add_chakra(player_id, random_type)
		new_chakra.append(random_type)
	
	emit_signal("chakra_updated", player_id, player_chakra[players[player_id]])
	emit_signal("chakra_drawn", player_id, new_chakra)
	
	Logger.info("CHAKRA", "Drew chakra: " + str(new_chakra))
	return new_chakra

func add_chakra(player_id, chakra_type, amount=1):
	var player = players[player_id]
	if not player_chakra[player].has(chakra_type):
		player_chakra[player][chakra_type] = 0
	
	player_chakra[player][chakra_type] += amount
	Logger.info("CHAKRA", "Added " + str(amount) + " " + 
		  ChakraType.keys()[chakra_type] + " chakra to " + player)
	
# Get chakra count for a specific type
func get_chakra_count(player_id, chakra_type):
	if player_chakra[player_id].has(chakra_type):
		return player_chakra[player_id][chakra_type]
	return 0
	
# Check if player can afford a cost
func can_afford(player_id, cost_dict):
	for type in cost_dict:
		var required = cost_dict[type]
		if get_chakra_count(player_id, type) < required:
			return false
	return true
	
# Spend chakra if player can afford it
func spend_chakra(player_id, cost_dict):
	if can_afford(player_id, cost_dict):
		Logger.info("CHAKRA", "Spending chakra for " + player_id + ": " + str(cost_dict))
		
		for type in cost_dict:
			player_chakra[player_id][type] -= cost_dict[type]
		
		emit_signal("chakra_updated", player_id, player_chakra[player_id])
		emit_signal("chakra_spent", player_id, cost_dict)
		return true
	
	Logger.warning("CHAKRA", "Cannot afford chakra cost: " + str(cost_dict))
	return false

# Get the type name as a string
func get_type_name(chakra_type):
	return ChakraType.keys()[chakra_type]

# Returns all chakra data for a player
func get_all_chakra(player_id):
	return player_chakra[player_id] 
