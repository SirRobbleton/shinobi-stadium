extends Node

# Define game phases enum
enum Phases {DRAW, CHAKRA, MAIN, END}

# Basic turn tracking
var current_player: String = "player" # "player" or "opponent"

# Attack ID tracking system
var last_attack_id: int = 0

# Signal for communication
signal turn_changed(new_player)

# Game state variables
var current_phase = Phases.CHAKRA
var opponent_shinobi = []
var attack_in_progress = false  # Track when an attack is currently happening

func _ready():
	Logger.info("GAMESTATE", "Initialized")

# This is just a placeholder for future functionality
func start_battle():
	Logger.info("GAMESTATE", "Starting battle")
	current_player = "player"
	emit_signal("turn_changed", current_player)

func perform_switch(source_card, target_card) -> bool:
	Logger.log_message("GAMESTATE", "Checking if switch is allowed...")
	Logger.log_message("GAMESTATE", "Current player: " + current_player)
	
	if current_player == "player":
		Logger.log_message("GAMESTATE", "Approving switch: " + source_card.character_data.name + " <-> " + target_card.character_data.name)
		return true
	else:
		Logger.log_message("GAMESTATE", "Rejecting switch - not player's turn ("+current_player+")")
		return false

func enter_battle_phase():
	Logger.log_message("GAMESTATE", "Entering battle phase")

func show_battle_overlay(character: CharacterCard) -> void:
	# Forward to BattleStateManager
	BattleStateManager.show_battle_overlay(character)

func is_in_battle_scene() -> bool:
	var scene_manager = get_node_or_null("/root/SceneManager")
	return scene_manager and scene_manager.is_in_battle_scene()

func hide_battle_overlay(after_attack: bool = false):
	# Forward to BattleStateManager
	BattleStateManager.hide_battle_overlay(after_attack)

# Generate a unique attack ID
func _generate_attack_id(attacker_name):
	last_attack_id += 1
	return str(attacker_name) + "_attack_" + str(last_attack_id)
