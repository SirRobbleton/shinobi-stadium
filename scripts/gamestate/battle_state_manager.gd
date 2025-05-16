extends Node

#Players
enum PlayerId { PLAYER1, PLAYER2 }

# Game phases
enum Phase {DRAW, CHAKRA, MAIN, END}

# Current game state
var current_phase: int = Phase.DRAW
var current_player: PlayerId = PlayerId.PLAYER1
var current_character: CharacterCard = null
var current_ability: AbilityData = null

# Whether certain actions are allowed
var can_play_cards: bool = false
var can_attack: bool = false
var can_use_abilities: bool = false

# Initialization flag
var is_initialized = false

# Chakra display references
var overlay_chakra_container = null
var battle_chakra_container = null
var overlay_chakra_labels = {}
var battle_chakra_labels = {}

# Signals
signal phase_changed(player_id, old_phase, new_phase)
signal turn_changed(player_id)

# Battle-specific state
var has_switched_this_turn: bool = false
var in_battle_phase: bool = false

# Battle-related signals
signal switch_performed(source, target)
signal target_required(attacker_data)
signal attack_initiated(attacker_data)
signal attack_performed(attacker_data, target_data, is_defeated)

func _ready():
	print("[BATTLE_STATE_MANAGER] Registered, waiting for battle scene")
	
	# Only connect to SceneManager, do nothing else
	if get_node("/root/SceneManager"):
		get_node("/root/SceneManager").connect("scene_changed", Callable(self, "_on_scene_changed"))

# Initialize only when battle scene is loaded
func _on_scene_changed(scene_path):
	if scene_path == "res://scenes/battle/battle_scene.tscn":
		call_deferred("_initialize_manager")
	else:
		_cleanup_resources()

# Full initialization - only called when battle scene is active
func _initialize_manager():
	if is_initialized:
		return
		
	print("[BATTLE_STATE_MANAGER] Initializing manager for battle scene")
	
	# Connect to ChakraManager signals
	if get_node("/root/ChakraManager"):
		get_node("/root/ChakraManager").connect("chakra_updated", _on_chakra_updated)
		get_node("/root/ChakraManager").connect("chakra_drawn", _on_chakra_drawn)
	
	# Find chakra containers with short delay to ensure scene is fully ready
	get_tree().create_timer(0.2).timeout.connect(_find_chakra_containers)
	
	is_initialized = true

# Clean up resources when leaving battle scene
func _cleanup_resources():
	print("[BATTLE_STATE_MANAGER] Cleaning up resources")
	
	# Clear references
	overlay_chakra_container = null
	battle_chakra_container = null
	overlay_chakra_labels.clear()
	battle_chakra_labels.clear()
	
	# Reset state
	is_initialized = false

# Find the chakra containers and labels in the battle scene
func _find_chakra_containers():
	# Only proceed if initialized
	if !is_initialized:
		return
		
	# Get the current scene (which should be the battle scene)
	var current_scene = get_tree().current_scene
	if !current_scene:
		print("[BATTLE_STATE_MANAGER] Current scene not found")
		return
		
	# Find the overlay chakra container
	var battle_overlay = current_scene.get_node_or_null("BattleOverlay")

	if battle_overlay:
		overlay_chakra_container = battle_overlay.get_node_or_null("OverlayLayout/PlayerHandContainer/ChakraContainer")

		if overlay_chakra_container:
			print("[BATTLE_STATE_MANAGER] Found overlay chakra container at: " + str(overlay_chakra_container.get_path()))
		else:
			print("[BATTLE_STATE_MANAGER] Overlay chakra container not found!")
	else:
		print("[BATTLE_STATE_MANAGER] BattleOverlay not found, will try again later")
		get_tree().create_timer(0.5).timeout.connect(_find_chakra_containers)
		return
	
	# Find the battle layout chakra container
	battle_chakra_container = current_scene.get_node_or_null("BattleLayout/PlayerHandContainer/HandCards/ChakraContainer")
		
	if battle_chakra_container:
		print("[BATTLE_STATE_MANAGER] Found battle chakra container at: " + str(battle_chakra_container.get_path()))
	else:
		print("[BATTLE_STATE_MANAGER] Battle chakra container not found! Available nodes:")
	_print_node_tree(current_scene.get_node_or_null("BattleLayout/PlayerHandContainer/HandCards"), 2)
	
	# If we found at least one container, set up the labels
	if overlay_chakra_container or battle_chakra_container:
		_setup_chakra_labels()
	else:
		# Try again later
		get_tree().create_timer(0.5).timeout.connect(_find_chakra_containers)

# Helper function to print node tree for debugging
func _print_node_tree(node, depth = 0):
	if node == null:
		print("Node is null")
		return
		
	if depth > 5:  # Limit recursion depth
		return
		
	var indent = ""
	for i in range(depth):
		indent += "  "
		
	for child in node.get_children():
		print(indent + "- " + child.name + " [" + child.get_class() + "]")
		_print_node_tree(child, depth + 1)

# Setup chakra label references
func _setup_chakra_labels():
	# Get references to all chakra type labels
	var chakra_types = get_node("/root/ChakraManager").ChakraType
	
	# Setup overlay labels
	if overlay_chakra_container:
		for type in chakra_types.values():
			var type_name = chakra_types.keys()[type]
			# Convert to title case for container name
			var container_name = type_name.substr(0, 1) + type_name.substr(1).to_lower() + "Container"
			var label_path = "VBoxContainer/" + container_name + "/Label"
			
			print("[BATTLE_STATE_MANAGER] Looking for overlay label at path: " + label_path)
			
			var label = overlay_chakra_container.get_node_or_null(label_path)
			if label:
				overlay_chakra_labels[type] = label
				print("[BATTLE_STATE_MANAGER] Found overlay label for " + type_name)
			else:
				# Try direct search
				print("[BATTLE_STATE_MANAGER] Overlay label not found at path: " + label_path)
				label = _find_label_by_partial_name(overlay_chakra_container, type_name.to_lower())
				if label:
					overlay_chakra_labels[type] = label
					print("[BATTLE_STATE_MANAGER] Found overlay label for " + type_name + " using direct search")
				else:
					print("[BATTLE_STATE_MANAGER] Warning: Overlay label for " + type_name + " not found")
	
	# Setup battle layout labels
	if battle_chakra_container:
		for type in chakra_types.values():
			var type_name = chakra_types.keys()[type]
			# Convert to title case for container name
			var container_name = type_name.substr(0, 1) + type_name.substr(1).to_lower() + "Container"
			var label_path = "VBoxContainer/" + container_name + "/Label"
			
			print("[BATTLE_STATE_MANAGER] Looking for battle label at path: " + label_path)
			
			var label = battle_chakra_container.get_node_or_null(label_path)
			if label:
				battle_chakra_labels[type] = label
				print("[BATTLE_STATE_MANAGER] Found battle label for " + type_name)
			else:
				# Try direct search
				print("[BATTLE_STATE_MANAGER] Battle label not found at path: " + label_path)
				label = _find_label_by_partial_name(battle_chakra_container, type_name.to_lower())
				if label:
					battle_chakra_labels[type] = label
					print("[BATTLE_STATE_MANAGER] Found battle label for " + type_name + " using direct search")
				else:
					print("[BATTLE_STATE_MANAGER] Warning: Battle label for " + type_name + " not found")
	
	# Initial refresh of display
	refresh_chakra_display()

# Helper function to find a label by partial name match
func _find_label_by_partial_name(parent_node, partial_name):
	for child in parent_node.get_children():
		if child is Label and partial_name.to_lower() in child.name.to_lower():
			return child
		
		if child.get_child_count() > 0:
			var result = _find_label_by_partial_name(child, partial_name)
			if result:
				return result
	
	return null

# Handler for chakra update signal
func _on_chakra_updated(player_id, chakra_data):
	# Only proceed if initialized
	if !is_initialized:
		return
		
	if player_id == BattleStateManager.PlayerId.PLAYER1:
		print("[BATTLE_STATE_MANAGER] Chakra updated for player")
		refresh_chakra_display()

# Handler for chakra drawn signal
func _on_chakra_drawn(player_id, new_chakra):
	# Only proceed if initialized
	if !is_initialized:
		return
		
	if player_id == BattleStateManager.PlayerId.PLAYER1:
		print("[BATTLE_STATE_MANAGER] New chakra drawn for player")
		_animate_new_chakra(new_chakra)
		refresh_chakra_display()

# Animate newly drawn chakra
func _animate_new_chakra(new_chakra):
	# Only proceed if initialized
	if !is_initialized:
		return
		
	var chakra_manager = get_node("/root/ChakraManager")
	
	for chakra_type in new_chakra:
		var type_name = chakra_manager.get_type_name(chakra_type)
		print("[BATTLE_STATE_MANAGER] Animating new " + type_name + " chakra")
		
		# Animate overlay labels
		if overlay_chakra_labels.has(chakra_type):
			var label = overlay_chakra_labels[chakra_type]
			
			# Create a scale animation
			var original_scale = label.scale
			var tween = create_tween()
			tween.tween_property(label, "scale", original_scale * 1.5, 0.2)
			tween.tween_property(label, "scale", original_scale, 0.2)
		
		# Animate battle layout labels
		if battle_chakra_labels.has(chakra_type):
			var label = battle_chakra_labels[chakra_type]
			
			# Create a scale animation
			var original_scale = label.scale
			var tween = create_tween()
			tween.tween_property(label, "scale", original_scale * 1.5, 0.2)
			tween.tween_property(label, "scale", original_scale, 0.2)

# Update the chakra display UI
func refresh_chakra_display():
	# Only proceed if initialized
	if !is_initialized:
		return
		
	var chakra_manager = get_node("/root/ChakraManager")
	if not chakra_manager:
		print("[BATTLE_STATE_MANAGER] ChakraManager not found!")
		return
	
	var chakra_data = chakra_manager.get_all_chakra("player")
	
	# Update overlay labels
	for type in chakra_data.keys():
		if overlay_chakra_labels.has(type):
			var count = chakra_data[type]
			overlay_chakra_labels[type].text = "x " + str(count)
			print("[BATTLE_STATE_MANAGER] Updated overlay " + chakra_manager.get_type_name(type) + " display to: x " + str(count))
	
	# Update battle layout labels
	for type in chakra_data.keys():
		if battle_chakra_labels.has(type):
			var count = chakra_data[type]
			battle_chakra_labels[type].text = "x " + str(count)
			print("[BATTLE_STATE_MANAGER] Updated battle " + chakra_manager.get_type_name(type) + " display to: x " + str(count))

# Start a battle
func start_battle():
	# Only proceed if initialized
	if !is_initialized:
		print("[BATTLE_STATE_MANAGER] Cannot start battle - not initialized")
		return

	print("[BATTLE_STATE_MANAGER] Starting battle")
	current_player = PlayerId.PLAYER1
	emit_signal("turn_changed", current_player)
	# Begin first turn
	start_turn(current_player)

# Start a player's turn
func start_turn(player_id):
	# Only proceed if initialized
	if !is_initialized:
		return
		
	print("[BATTLE_STATE_MANAGER] Starting turn for Player" + str(player_id))
	current_player = player_id
	current_phase = Phase.DRAW
	
	# Notify about turn change
	emit_signal("turn_changed", current_player)
	
	# Automatically advance to Draw phase
	change_phase(Phase.DRAW)

# End the current turn
func end_turn():
	print("[BATTLE_STATE_MANAGER] Ending turn for " + str(current_player))
	
	# Toggle player
	current_player = PlayerId.PLAYER2 if current_player == PlayerId.PLAYER1 else PlayerId.PLAYER1
	
	# Start new turn
	start_turn(current_player)

# Change to a specific phase
func change_phase(new_phase):
	var old_phase = current_phase
	current_phase = new_phase
	
	# Reset action permissions
	can_play_cards = false
	can_attack = false
	can_use_abilities = false
	
	# Handle phase-specific logic
	match current_phase:
		Phase.DRAW:
			print("[BATTLE_STATE_MANAGER] Entering Draw phase")
			handle_draw_phase()
		Phase.CHAKRA:
			print("[BATTLE_STATE_MANAGER] Entering Chakra phase")
			handle_chakra_phase()
		Phase.MAIN:
			print("[BATTLE_STATE_MANAGER] Entering Main phase")
			handle_main_phase()
		Phase.END:
			print("[BATTLE_STATE_MANAGER] Entering End phase")
			handle_end_phase()
	
	# Emit signal that phase changed
	emit_signal("phase_changed", current_player, old_phase, new_phase)

# Handle logic for Draw phase
func handle_draw_phase():
	# For now, auto-progress to Chakra phase
	# In the future, can add card drawing logic here
	get_tree().create_timer(1.0).timeout.connect(func(): change_phase(Phase.CHAKRA))

# Handle logic for Chakra phase
func handle_chakra_phase():
	print("[BATTLE_STATE_MANAGER] Drawing chakra for " + str(current_player))
	
	# Draw chakra using ChakraManager
	var chakra_manager = get_node_or_null("/root/ChakraManager")
	if chakra_manager:
		chakra_manager.draw_chakra(current_player, 3)
	else:
		push_error("ChakraManager not found when trying to draw chakra!")
	
	# Auto-progress to Main phase
	get_tree().create_timer(1.5).timeout.connect(func(): change_phase(Phase.MAIN))

# Handle logic for Main phase
func handle_main_phase():
	# Enable actions
	can_play_cards = true
	can_attack = true
	can_use_abilities = true
	
	# For AI, would handle their turn here
	if current_player == PlayerId.PLAYER2:
		# TODO: Implement AI logic
		get_tree().create_timer(2.0).timeout.connect(func(): change_phase(Phase.END))

# Handle logic for End phase
func handle_end_phase():
	print("[BATTLE_STATE_MANAGER] Ending turn")
	
	# End turn after a slight delay
	get_tree().create_timer(0.5).timeout.connect(end_turn)

# Check if a specific action is allowed
func can_perform_action(action_type: String) -> bool:
	match action_type:
		"play_card":
			return can_play_cards and current_player == PlayerId.PLAYER1
		"attack":
			return can_attack and current_player == PlayerId.PLAYER1
		"ability":
			return can_use_abilities and current_player == PlayerId.PLAYER1
		_:
			return false

# Get current phase name (for UI)
func get_current_phase_name() -> String:
	return Phase.keys()[current_phase]

# For debugging, this can be called to force drawing chakra
func debug_draw_chakra(amount=3):
	print("[BATTLE_STATE_MANAGER] Debug: Drawing " + str(amount) + " chakra")
	var chakra_manager = get_node_or_null("/root/ChakraManager")
	if chakra_manager:
		chakra_manager.draw_chakra("player", amount)
	else:
		push_error("ChakraManager not found when trying to draw chakra!")

# Core battle methods migrated from GameStateManager
func perform_switch(source_card, target_card) -> bool:
	Logger.info("BATTLE_STATE", "Checking switch for: " + source_card.character_data.name + " -> " + target_card.character_data.name)
	Logger.info("BATTLE_STATE", "Has switched before: " + str(has_switched_this_turn))

	if current_player == PlayerId.PLAYER1 and !has_switched_this_turn:
		has_switched_this_turn = true
		emit_signal("switch_performed", source_card, target_card)
		return true
	Logger.info("BATTLE_STATE", "Rejecting switch for: " + source_card.character_data.name + " -> " + target_card.character_data.name)
	return false

func begin_attack(character: CharacterCard):
	Logger.info("BATTLE_STATE", "Beginning attack from: " + character.get_character_name())
	current_character = character
	current_ability = character.character_data.attack_data
	Logger.info("BATTLE_STATE", "Current Ability: " + current_ability.get_summary())
	var ov = get_tree().current_scene
	ov.highlight_targets(current_ability)

func perform_attack(attacker_data: CharacterData, target_data: CharacterData) -> bool:
	Logger.info("BATTLE_STATE", "Attack: " + attacker_data.name + " -> " + target_data.name)
	var is_defeated = target_data.take_damage(attacker_data.attack_data.damage)
	
	emit_signal("attack_performed", attacker_data, target_data, is_defeated)
	return is_defeated

func show_battle_overlay(character: CharacterCard) -> void:
	Logger.info("BATTLE_STATE", "Show Battle Overlay for: " + character.get_character_name())
	var ov = get_tree().current_scene.get_node_or_null("BattleOverlay")
	if ov and ov.has_method("show_character"):
		ov.show_character(character)

func hide_battle_overlay(after_attack: bool = false) -> void:
	var ov = get_tree().current_scene.get_node_or_null("BattleOverlay")
	if ov and ov.has_method("clear_overlay"):
		ov.clear_overlay()
