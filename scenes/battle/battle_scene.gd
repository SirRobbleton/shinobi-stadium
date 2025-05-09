# battle_scene.gd
extends Control

# Character card scene reference for instantiating cards
@export var character_card_scene: PackedScene

# Slots for player and opponent shinobi
@onready var player_slot_active = $BattleLayout/PlayerBattleArea/ShinobiContainer/ActivePosition/Control/CardSlot
@onready var player_slot_support1 = $BattleLayout/PlayerBattleArea/ShinobiContainer/SupportPosition1/Control/CardSlot
@onready var player_slot_support2= $BattleLayout/PlayerBattleArea/ShinobiContainer/SupportPosition2/Control/CardSlot

@onready var opponent_slots = [
	$BattleLayout/OppBattleArea/ShinobiContainer/SupportPosition1/Control/CardSlot,
	$BattleLayout/OppBattleArea/ShinobiContainer/ActivePosition/Control/CardSlot,
	$BattleLayout/OppBattleArea/ShinobiContainer/SupportPosition2/Control/CardSlot
]

# Player hand containers
@onready var player_hand_container = $BattleLayout/PlayerHandContainer/HandCards
@onready var opponent_hand_container = $BattleLayout/OppHandContainer/HandCards

# UI elements
@onready var end_turn_button = $BattleControls/EndTurnButton

# Track opponent's active character
var opponent_active_shinobi: Node = null

# Game state reference
@onready var game_state = GamestateManager

# Track highlighted characters
var highlighted_characters = []

func _ready():
	# Connect signals
	end_turn_button.connect("pressed", Callable(self, "_on_end_turn_pressed"))
	game_state.connect("turn_changed", Callable(self, "_on_turn_changed"))
	#game_state.connect("switch_performed", Callable(self, "_on_switch_performed"))
	
	# Connect to battle attack signals
	game_state.target_required.connect(_on_target_required)
	game_state.attack_initiated.connect(_on_attack_initiated)
	game_state.attack_performed.connect(_on_attack_performed)
	
	# Connect to battle overlay visibility changes
	var battle_overlay = get_node_or_null("BattleOverlay")
	if battle_overlay:
		battle_overlay.connect("visibility_changed", Callable(self, "_on_battle_overlay_visibility_changed"))
	
	# Load characters from CharacterSelection
	place_player_shinobi()
	place_opponent_shinobi()
	
	# Initialize chakra display
	_initialize_chakra_system()
	
	# Initialize battle phase UI
	_initialize_battle_phase_ui()
	
	# Start the battle
	game_state.start_battle()
	
	# Log battle start
	Logger.info("BATTLE", "Battle started with:")
	for character in [CharacterSelection.active_shinobi, CharacterSelection.support_shinobi_1, CharacterSelection.support_shinobi_2]:
		Logger.info("BATTLE", "- Player: " + character.name)
	for character in CharacterSelection.opponent_shinobi:
		Logger.info("BATTLE", "- Opponent: " + character.name)

# Initialize the chakra system
func _initialize_chakra_system():
	# No need to create the ChakraDisplay script anymore as functionality is in BattleStateManager
	Logger.info("BATTLE", "Chakra system will be handled by BattleStateManager")
	
	# Force drawing initial chakra happens in BattleStateManager.start_game()
	
	# No need for additional timers to refresh the display as it's managed by BattleStateManager

# Initialize the battle phase UI
func _initialize_battle_phase_ui():
	# Create the battle phase UI script if not exists
	if !has_node("BattlePhaseUI"):
		var battle_phase_ui = Node.new()
		battle_phase_ui.name = "BattlePhaseUI"
		battle_phase_ui.set_script(load("res://scripts/ui/battle_phase_ui.gd"))
		add_child(battle_phase_ui)
		Logger.info("BATTLE", "Initialized BattlePhaseUI")
		
	# Start the battle state machine
	var battle_state = get_node_or_null("/root/BattleStateManager")
	if battle_state:
		battle_state.start_game()

# Handler for when an attack requires a target
func _on_target_required(attacker_data: CharacterData):
	Logger.info("BATTLE", "Target required for attack from: " + attacker_data.name)
	
	# Find opponent's active character
	var opponent_active = find_opponent_active_shinobi()
	if opponent_active:
		# Apply highlight effect to indicate it's the target
		highlight_character(opponent_active)
	else:
		Logger.warning("BATTLE", "Error: No opponent active character found to highlight!")

# Triggered when an attack is initiated
func _on_attack_initiated(attacker_data: CharacterData):
	Logger.info("BATTLE", "Attack initiated by: " + attacker_data.name)
	# Additional attack initialization can be added here

# Triggered when an attack is performed
func _on_attack_performed(attacker_data: CharacterData, target_data: CharacterData, target_defeated: bool):
	Logger.info("BATTLE", "Attack performed: " + attacker_data.name + " -> " + target_data.name)
	
	# Add visual effects for the attack
	# Here we could add animations, particles, etc.
	
	# Handle defeated character if necessary
	if target_defeated:
		Logger.info("BATTLE", "Character defeated: " + target_data.name)
		
		# Find the character card associated with this data
		var target_character = null
		var character_cards = get_tree().get_nodes_in_group("character")
		for card in character_cards:
			if card.character_data == target_data:
				target_character = card
				break
		
		if target_character:
			# Apply visual effect for defeated character
			var defeat_tween = create_tween()
			defeat_tween.tween_property(target_character, "modulate", Color(0.5, 0.5, 0.5, 0.7), 0.5)
			
			# Disable interaction with defeated character
			if target_character.has_method("disable_card"):
				target_character.disable_card()

# Find the opponent's active character
func find_opponent_active_shinobi():
	# If already cached, return it
	if opponent_active_shinobi and is_instance_valid(opponent_active_shinobi):
		# Card enabling will be handled in the highlight_character function
		return opponent_active_shinobi
		
	# Otherwise, find the opponent's active slot
	var active_slot = opponent_slots[1]  # Active slot is in middle position
	if active_slot and active_slot.held_card:
		opponent_active_shinobi = active_slot.held_card
		return opponent_active_shinobi
	
	# If not found, try to find any opponent character
	for slot in opponent_slots:
		if slot.held_card:
			opponent_active_shinobi = slot.held_card
			return opponent_active_shinobi
			
	return null

# Highlight a character as targetable (for attack)
func highlight_character(character):
	Logger.info("HIGHLIGHT_DEBUG", "Highlighting character: " + character.get_character_name())
	
	# Set card as a target using both the meta tag and property if available
	character.set_meta("is_target", true)
	if character.has_method("set_targetable"):
		character.set_targetable(true)
		Logger.info("HIGHLIGHT_DEBUG", "Set as targetable using property")
		
	# Create target panel for targeting UI if it doesn't exist
	if !character.has_node("RigidBody2D/CharacterVisuals/Portrait/TargetPanel"):
		Logger.warning("HIGHLIGHT_DEBUG", "ERROR: CharacterVisuals not found, could not add TargetPanel")
	else:
		var target_panel = character.get_node("RigidBody2D/CharacterVisuals/Portrait/TargetPanel")
		target_panel.visible = true
		Logger.info("HIGHLIGHT_DEBUG", "Made existing TargetPanel visible")
	
	# Set the BacklightPanel color for hover effect (but don't make it visible yet)
	#var backlight = character.get_node_or_null("RigidBody2D/CharacterVisuals/Portrait/BacklightPanel")
	#if backlight:
	#	backlight.modulate = Color(1.0, 0.3, 0.3, 0.7)  # Red tint for hover over targetable cards
	#	print("[HIGHLIGHT_DEBUG] Set BacklightPanel color for hover effect")
	#else:
	#	print("[HIGHLIGHT_DEBUG] WARNING: BacklightPanel not found")
	
	# Enable hover detection
	if character.has_method("set_hover_detection"):
		character.set_hover_detection(true)
		Logger.info("HIGHLIGHT_DEBUG", "Enabled hover detection")
	else:
		Logger.warning("HIGHLIGHT_DEBUG", "WARNING: No set_hover_detection method available")
	
	# Make sure RigidBody2D is pickable
	if character.has_node("RigidBody2D"):
		character.get_node("RigidBody2D").input_pickable = true
		Logger.info("HIGHLIGHT_DEBUG", "Set RigidBody2D.input_pickable = true")
	
	# Connect to target_clicked signal if available and not already connected
	if character.has_signal("target_clicked"):
		if !character.is_connected("target_clicked", Callable(self, "_on_target_clicked")):
			character.connect("target_clicked", Callable(self, "_on_target_clicked"))
			Logger.info("HIGHLIGHT_DEBUG", "Connected to target_clicked signal")
		else:
			Logger.info("HIGHLIGHT_DEBUG", "Already connected to target_clicked signal")
	else:
		Logger.warning("HIGHLIGHT_DEBUG", "WARNING: target_clicked signal not available")
	
	# Create pulsating scale effect for target
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.tween_property(character, "scale", character.scale * 1.1, 2.0)
	scale_tween.tween_property(character, "scale", character.scale, 0.5)
	Logger.info("HIGHLIGHT_DEBUG", "Created pulsating scale effect")
	
	Logger.info("HIGHLIGHT_DEBUG", "Character highlighted successfully")

# Clear all highlighted characters
func clear_highlights():
	Logger.info("HIGHLIGHT_DEBUG", "Clearing all target highlights")
	var character_cards = get_tree().get_nodes_in_group("character")
	var highlight_count = 0
	
	for card in character_cards:
		# Remove target flag
		if card.has_meta("is_target"):
			card.remove_meta("is_target")
			highlight_count += 1
			
		# Set targetable to false if method exists
		if card.has_method("set_targetable"):
			card.set_targetable(false)
		
		# Hide target panel if it exists
		var target_panel = card.get_node_or_null("RigidBody2D/CharacterVisuals/TargetPanel")
		if target_panel:
			target_panel.visible = false
		
		# Stop any running tweens (scale effects)
		if card.scale != Vector2(1,1):
			var reset_tween = create_tween()
			reset_tween.tween_property(card, "scale", Vector2(1,1), 0.2)
		
		# Disconnect target_clicked signal
		if card.has_signal("target_clicked") and card.is_connected("target_clicked", Callable(self, "_on_target_clicked")):
			card.disconnect("target_clicked", Callable(self, "_on_target_clicked"))
	
	Logger.info("HIGHLIGHT_DEBUG", "Cleared highlights from " + str(highlight_count) + " cards")

# Find the player's active character
func get_active_character():
	# First check the active slot
	if player_slot_active.held_card:
		Logger.info("BATTLE_SCENE", "Found active character: " + player_slot_active.held_card.get_character_name())
		return player_slot_active.held_card
	
	# If not found, look through all character cards
	var character_cards = get_tree().get_nodes_in_group("character")
	for card in character_cards:
		if card.player_owned and card.is_active:
			Logger.info("BATTLE_SCENE", "Found active character through search: " + card.get_character_name())
			return card
	
	# If still not found, get the battle overlay's current character
	var battle_overlay = get_node_or_null("BattleOverlay")
	if battle_overlay and battle_overlay.current_character:
		Logger.info("BATTLE_SCENE", "Using battle overlay's current character")
		var all_character_cards = get_tree().get_nodes_in_group("character")
		for card in all_character_cards:
			if card.character_data == battle_overlay.current_character:
				Logger.info("BATTLE_SCENE", "Found card matching battle overlay character: " + card.get_character_name())
				return card
			
	Logger.warning("BATTLE_SCENE", "WARNING: Could not find active character")
	return null

# Handle target clicked signal from character card
func _on_target_clicked(character):
	Logger.info("BATTLE_SCENE", "Target clicked: " + character.get_character_name())
	
	# Process the attack with this target
	process_attack(character)

# Properly handle character clicks for targets
func process_attack(character):
	# Log card position and slot information
	Logger.info("CLICK_DEBUG", "Character position: " + str(character.global_position))
	
	if character.has_meta("slot_reference"):
		var slot = character.get_meta("slot_reference")
		Logger.info("CLICK_DEBUG", "Character slot position: " + str(slot.global_position))
	else:
		Logger.warning("CLICK_DEBUG", "WARNING: Character has no slot reference!")
	
	# Check if character is targetable properly
	var is_target_by_meta = character.has_meta("is_target")
	var is_targetable_property = false
	if "is_targetable" in character:
		is_targetable_property = character.is_targetable
	
	Logger.info("CLICK_DEBUG", "Targetable status - By meta: " + str(is_target_by_meta) + 
		", By property: " + str(is_targetable_property))
	
	# Ignore clicks if this isn't marked as a target
	if !is_target_by_meta and !is_targetable_property:
		Logger.info("CLICK_DEBUG", "Character is not marked as a target, ignoring click")
		return
	
	# Get the character data for the target
	var target_data = character.character_data
	Logger.info("CLICK_DEBUG", "Target data: " + target_data.name + ", HP: " + str(target_data.current_hp) + "/" + str(target_data.hp))
	
	# Get the current attacker from the battle overlay
	var battle_overlay = get_node_or_null("BattleOverlay")
	if !battle_overlay or !battle_overlay.current_character:
		Logger.warning("CLICK_DEBUG", "ERROR: No active attacker found in battle overlay")
		return
	
	# Get the attacker data
	var attacker_data = battle_overlay.current_character
	Logger.info("CLICK_DEBUG", "Attacker data: " + attacker_data.name)
	
	Logger.info("CLICK_DEBUG", "Processing attack: " + attacker_data.name + " -> " + target_data.name)
	
	# Perform the attack
	var result = GamestateManager.perform_attack(attacker_data, target_data)
	Logger.info("CLICK_DEBUG", "Attack result: " + str(result))
	
	# Hide the battle overlay after attack
	GamestateManager.hide_battle_overlay(true)
	Logger.info("CLICK_DEBUG", "Battle overlay hidden")
	
	# Clear highlight
	clear_highlights()
	Logger.info("CLICK_DEBUG", "Highlights cleared")
	Logger.info("CLICK_DEBUG", "========== ATTACK COMPLETE ==========")

func place_player_shinobi():
		
	#Initialise characters
	var active_character = character_card_scene.instantiate()
	active_character.setup(CharacterSelection.active_shinobi)
	var support_1_character = character_card_scene.instantiate()
	support_1_character.setup(CharacterSelection.support_shinobi_1)
	#await support_1_character.setup(CharacterSelection.support_shinobi_1)
	var support_2_character = character_card_scene.instantiate()
	support_2_character.setup(CharacterSelection.support_shinobi_2)
	#await support_2_character.setup(CharacterSelection.support_shinobi_2)
	
	# Place player selected shinobi on their slots
	await place_character_on_slot(active_character, player_slot_active)
	await place_character_on_slot(support_1_character, player_slot_support1)
	await place_character_on_slot(support_2_character, player_slot_support2)
	
	active_character.place_character_on_slot.connect(place_character_on_slot)
	support_1_character.place_character_on_slot.connect(place_character_on_slot)
	support_2_character.place_character_on_slot.connect(place_character_on_slot)
	
func place_opponent_shinobi():
	# Place opponent shinobi on their slots
	for i in range(min(CharacterSelection.opponent_shinobi.size(), opponent_slots.size())):
		var character_data = CharacterSelection.opponent_shinobi[i]
		var character = character_card_scene.instantiate()
		await character.setup(character_data)
		await place_character_on_slot(character, opponent_slots[i])
		
	# Cache the opponent's active character
	opponent_active_shinobi = find_opponent_active_shinobi()

func place_character_on_slot(card: CharacterCard, slot: CardSlot):
	# Ensure character health is initialized
	#if character_data.current_hp <= 0:
	#	print("[BATTLE_SCENE] WARNING: Character " + character_data.name + " has 0 HP, resetting to max")
	#	character_data.reset_hp()
	Logger.info("BATTLE_SCENE", "Placing " + card.character_data.name + " on slot " + str(slot))

	# Create a new card instance
	
	# Add to the Control parent of the slot for proper positioning
	slot.get_parent().add_child(card)
	#slot.add_child(card)

	await get_tree().process_frame

	# Set up the card data
	card.setup(card.character_data)
	card.current_slot = slot
	
	# Verify HP label is showing current_hp not max hp
	var hp_label = card.get_node("RigidBody2D/CharacterVisuals/Portrait/HPColor/HPLabel")
	#if hp_label:
	#	print("[BATTLE_SCENE] Character " + character_data.name + " HP: " + str(character_data.current_hp) + "/" + str(character_data.hp))
	#	if hp_label.text != str(character_data.current_hp):
	#		print("[BATTLE_SCENE] Fixing HP label on card placement: " + hp_label.text + " → " + str(character_data.current_hp))
	#		hp_label.text = str(character_data.current_hp)
	
	# Set active flag based on position
	if slot == player_slot_active or slot == opponent_slots[1]:
		#card.is_active = true
		Logger.info("BATTLE_SCENE", "actuve player")
	else:
		#card.is_support = true
		Logger.info("BATTLE_SCENE", "support player")

	# Set player ownership flag
	card.player_owned = slot in [player_slot_active, player_slot_support1, player_slot_support2]
	
	# Enable dragging for player's cards
	if card.player_owned:
		card.set_process_input(true)
		card.current_state = card.CardState.IDLE
		card.current_slot != null
		# Store slot reference using set_meta instead of using current_slot directly
		card.set_meta("slot_reference", slot)
		Logger.info("BATTLE_SCENE", "Enabled dragging for player card: " + card.character_data.name)
		
		# Connect drag signals
		if not card.is_connected("drag_started", Callable(self, "_on_card_drag_started")):
			card.connect("drag_started", Callable(self, "_on_card_drag_started"))
		if not card.is_connected("drag_ended", Callable(self, "_on_card_drag_ended")):
			card.connect("drag_ended", Callable(self, "_on_card_drag_ended"))
	
	# Connect the card's switch_requested signal
	card.connect("switch_requested", Callable(self, "_on_card_switch_requested"))
	
	# Position the card on the slot
	await get_tree().process_frame
	card.global_position = slot.global_position
	card.rigid_body.global_position = slot.global_position
	
	# Mark the slot as occupied
	slot.held_card = card
	#slot.disable_collision()
	
	Logger.info("BATTLE_SCENE", "Placed " + card.character_data.name + " on a battle slot")
	
	return card

# Handle card drag starting
func _on_card_drag_started(card):
	Logger.info("DRAG_DEBUG", "====== DRAG STARTED ======")
	Logger.info("DRAG_DEBUG", "Card: " + card.character_data.name)
	Logger.info("DRAG_DEBUG", "Current Slot: " + (card.current_slot.name if card.current_slot else "None"))
	Logger.info("DRAG_DEBUG", "Slot Reference: " + (card.get_meta("slot_reference").name if card.has_meta("slot_reference") else "None"))
	Logger.info("DRAG_DEBUG", "Card Position: " + str(card.global_position))
	Logger.info("DRAG_DEBUG", "Card State: " + str(card.current_state))
	Logger.info("DRAG_DEBUG", "Is Dragging: " + str(card.is_dragging))
	
	if game_state.current_player == "player" and not game_state.in_battle_phase:
		Logger.info("DRAG_DEBUG", "Valid drag conditions met")
		# Show valid target slots by making other player cards targetable
		set_valid_switch_targets(card, true)
	else:
		Logger.info("DRAG_DEBUG", "Invalid drag conditions - Player: " + game_state.current_player + ", Battle Phase: " + str(game_state.in_battle_phase))

# Handle card drag ending
func _on_card_drag_ended(card, target):
	Logger.info("DRAG_DEBUG", "====== DRAG ENDED ======")
	Logger.info("DRAG_DEBUG", "Card: " + card.character_data.name)
	Logger.info("DRAG_DEBUG", "Target: " + (target.character_data.name if target else "None"))
	Logger.info("DRAG_DEBUG", "Current Slot: " + (card.current_slot.name if card.current_slot else "None"))
	Logger.info("DRAG_DEBUG", "Slot Reference: " + (card.get_meta("slot_reference").name if card.has_meta("slot_reference") else "None"))
	Logger.info("DRAG_DEBUG", "Card Position: " + str(card.global_position))
	Logger.info("DRAG_DEBUG", "Card State: " + str(card.current_state))
	Logger.info("DRAG_DEBUG", "Is Dragging: " + str(card.is_dragging))
	
	# Hide the target indicators
	set_valid_switch_targets(card, false)
	
	# Find other player cards that are targetable
	var other_player_cards = []
	var character_cards = get_tree().get_nodes_in_group("character")
	
	for target_card in character_cards:
		if target_card.player_owned and target_card.is_targetable == true:
			other_player_cards.append(target_card)
			Logger.info("DRAG_DEBUG", "Found targetable card: " + target_card.character_data.name)
	
	Logger.info("DRAG_DEBUG", "Found " + str(other_player_cards.size()) + " other player cards")
	
	if other_player_cards.size() > 0:
		var target_card = other_player_cards[0]  # Just take the first available card
		Logger.info("DRAG_DEBUG", "Attempting switch with: " + target_card.character_data.name)
		
		# Check switch conditions directly
		var can_switch = game_state.current_player == "player" and !game_state.has_switched_this_turn and !game_state.in_battle_phase
		
		if can_switch:
			Logger.info("DRAG_DEBUG", "Switch conditions met, executing switch")
			# Force direct swap of positions without any further checks
			_emergency_switch_positions(card, target_card)
		else:
			Logger.info("DRAG_DEBUG", "Switch rejected - Current turn: " + game_state.current_player + 
				  ", Already switched: " + str(game_state.has_switched_this_turn) + 
				  ", Battle phase: " + str(game_state.in_battle_phase))
			_return_card_to_original_position(card)
	else:
		Logger.info("DRAG_DEBUG", "No other player cards found, returning to original position")
		_return_card_to_original_position(card)

# Show or hide targetable indicators on player cards
func set_valid_switch_targets(source_card, show):
	var character_cards = get_tree().get_nodes_in_group("character")
	for card in character_cards:
		if card.player_owned and card != source_card:
			if card.has_method("set_targetable"):
				card.set_targetable(show)
				if show:
					Logger.info("BATTLE_SCENE", "Setting " + card.character_data.name + " as targetable")

# Helper function to find the nearest player slot to a position
func find_nearest_player_slot(position):
	var player_slots = [player_slot_active, player_slot_support1, player_slot_support2]
	var closest_slot = null
	var closest_dist = 999999
	
	for slot in player_slots:
		var dist = position.distance_to(slot.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_slot = slot
	
	# Check if we're close enough to consider it valid
	if closest_dist < 100:  # Threshold in pixels
		return closest_slot
	
	return null

# Handle card switching animation after GamestateManager approves
func _on_switch_performed(source_card, target_card):
	Logger.info("BATTLE_SCENE", "Switch performed between " + source_card.character_data.name + " and " + target_card.character_data.name)
	
	# Use enhanced _switch_card_positions which handles the actual swapping
	_switch_card_positions(source_card, target_card)

# Actually switch the character positions
func _switch_card_positions(source_card, target_card):
	Logger.info("BATTLE_SCENE", "Switching positions between " + source_card.character_data.name + " and " + target_card.character_data.name)
	
	# Get the slots for both cards using meta data
	var source_slot = source_card.get_meta("slot_reference") if source_card.has_meta("slot_reference") else null
	var target_slot = target_card.get_meta("slot_reference") if target_card.has_meta("slot_reference") else null
	
	if !source_slot or !target_slot:
		# Fallback to find slots if metadata is not set
		source_slot = null
		target_slot = null
		
		for slot in [player_slot_active, player_slot_support1, player_slot_support2]:
			if slot.held_card == source_card:
				source_slot = slot
			if slot.held_card == target_card:
				target_slot = slot
				
		if !source_slot or !target_slot:
			Logger.error("BATTLE_SCENE", "Could not find slots for source or target card")
			return
	
	# Update character data state too
	#source_card.character_data.is_active = source_card.is_active
	#target_card.character_data.is_active = target_card.is_active
	
	# Update slot references using metadata
	source_card.set_meta("slot_reference", target_slot)
	target_card.set_meta("slot_reference", source_slot)
		
	# Create tween for smooth movement
	var tween = create_tween()
	
	# Switch positions
	var source_pos = source_slot.global_position
	var target_pos = target_slot.global_position
	
	tween.parallel().tween_property(source_card.rigid_body, "global_position", target_pos, 0.3)
	tween.parallel().tween_property(target_card.rigid_body, "global_position", source_pos, 0.3)
	
	# Update slot references
	target_slot.held_card = source_card
	source_slot.held_card = target_card
	source_card.current_slot = target_slot
	target_card.current_slot = source_slot
	
	# Play switch sound
	if SfxManager != null:
		SfxManager.play_sfx("switch")

func _on_end_turn_pressed():
	# Change the turn using the game state manager
	game_state.change_turn()

func _on_turn_changed(new_player):
	# Handle turn changes
	Logger.info("BATTLE_SCENE", "Turn changed to: " + new_player)
	
	# Disable the end turn button during opponent's turn
	end_turn_button.disabled = (new_player != "player")
	
	# Handle AI turn if it's the opponent's turn
	if new_player == "opponent":
		handle_opponent_turn()
		
func handle_opponent_turn():
	# Simple opponent AI
	Logger.info("BATTLE_SCENE", "Opponent is thinking...")
	
	# Wait a bit, then end the opponent's turn
	await get_tree().create_timer(1.5).timeout
	game_state.change_turn()  # Change back to player's turn

# Handle switch request from a character card
func _on_card_switch_requested(source_card, target_card):
	Logger.info("BATTLE_SCENE", "Direct switch requested from " + source_card.character_data.name + " to " + target_card.character_data.name)
	
	# Verify that both cards exist and have valid data
	if !is_instance_valid(source_card) or !is_instance_valid(target_card):
		Logger.warning("BATTLE_SCENE", "ERROR: One of the cards is invalid")
		return
		
	if !source_card.character_data or !target_card.character_data:
		Logger.warning("BATTLE_SCENE", "ERROR: One of the cards has no character data")
		return
	
	# Ensure both cards are player's cards
	if !source_card.player_owned or !target_card.player_owned:
		Logger.warning("BATTLE_SCENE", "ERROR: Both cards must be player owned")
		return
	
	# Check if switch is allowed via gamestate manager
	Logger.info("BATTLE_SCENE", "Requesting direct switch from GamestateManager")
	if game_state.perform_switch(source_card, target_card):
		Logger.info("BATTLE_SCENE", "Direct switch approved by GamestateManager")
		
		# Get the slots for both cards
		var source_slot = source_card.get_meta("slot_reference") if source_card.has_meta("slot_reference") else source_card.current_slot
		var target_slot = target_card.get_meta("slot_reference") if target_card.has_meta("slot_reference") else target_card.current_slot
		
		if source_slot and target_slot:
			Logger.info("BATTLE_SCENE", "Starting direct position swap")
			
			# Get the slot positions
			var source_slot_pos = source_slot.global_position
			var target_slot_pos = target_slot.global_position
			
			Logger.info("BATTLE_SCENE", "Switch Source Slot Position: " + str(source_slot_pos))
			Logger.info("BATTLE_SCENE", "Switch Target Slot Position: " + str(target_slot_pos))
			
			# Update slot references
			source_slot.held_card = target_card
			target_slot.held_card = source_card
			
			# Update the cards' references to slots using both methods for compatibility
			source_card.set_meta("slot_reference", target_slot)
			target_card.set_meta("slot_reference", source_slot)
			source_card.current_slot = target_slot
			target_card.current_slot = source_slot
			
			# Create tween for smooth movement
			var tween = create_tween()
			tween.parallel().tween_property(source_card.rigid_body, "global_position", target_slot_pos, 0.3)
			tween.parallel().tween_property(target_card.rigid_body, "global_position", source_slot_pos, 0.3)

			Logger.info("BATTLE_SCENE", "New Source Slot Position: " + str(source_card.position))
			Logger.info("BATTLE_SCENE", "New Source Slot Position: " + str(source_card.global_position))
			Logger.info("BATTLE_SCENE", "New Target Slot Position: " + str(target_card.global_position))
			
			# Play switch sound
			if SfxManager != null:
				SfxManager.play_sfx("switch")
			
			Logger.info("BATTLE_SCENE", "Direct card positions swapped")
		else:
			Logger.warning("BATTLE_SCENE", "ERROR: Missing slot references")
			_switch_card_positions(source_card, target_card)
	else:
		Logger.warning("BATTLE_SCENE", "Direct switch declined by GamestateManager")
		# Return cards to their original positions
		_return_card_to_original_position(source_card)

# Helper function to return a card to its original position
func _return_card_to_original_position(card):
	if card.has_meta("slot_reference"):
		var original_slot = card.get_meta("slot_reference")
		Logger.info("BATTLE_SCENE", "Returning " + card.character_data.name + " to original position")
		
		# Create tween for smooth movement
		var tween = create_tween()
		tween.tween_property(card.rigid_body, "global_position", original_slot.global_position, 0.3)
	else:
		Logger.warning("BATTLE_SCENE", "Warning: No original slot found for " + card.character_data.name)

# Emergency direct position swap without any complex logic
func _emergency_switch_positions(source_card, target_card):
	Logger.info("EMERGENCY_SWITCH", "====== EMERGENCY SWITCH ======")
	Logger.info("EMERGENCY_SWITCH", "Source: " + source_card.character_data.name)
	Logger.info("EMERGENCY_SWITCH", "Target: " + target_card.character_data.name)
	
	# Get slots using both methods for compatibility
	var source_slot = source_card.get_meta("slot_reference") if source_card.has_meta("slot_reference") else source_card.current_slot
	var target_slot = target_card.get_meta("slot_reference") if target_card.has_meta("slot_reference") else target_card.current_slot
	
	if source_slot == null or target_slot == null:
		Logger.warning("EMERGENCY_SWITCH", "ERROR: Missing slot references, canceling emergency switch")
		_return_card_to_original_position(source_card)
		return
	
	# Get the slot positions
	var source_slot_pos = source_slot.global_position
	var target_slot_pos = target_slot.global_position
	
	Logger.info("EMERGENCY_SWITCH", "Source Slot Position: " + str(source_slot_pos))
	Logger.info("EMERGENCY_SWITCH", "Target Slot Position: " + str(target_slot_pos))
	
	# First, update positions directly without tween
	source_card.global_position = target_slot_pos
	target_card.global_position = source_slot_pos
	
	# Then update slot references
	source_slot.held_card = target_card
	target_slot.held_card = source_card
	
	# Update both slot reference methods for compatibility
	source_card.set_meta("slot_reference", target_slot)
	target_card.set_meta("slot_reference", source_slot)
	source_card.current_slot = target_slot
	target_card.current_slot = source_slot
	
	# Verify positions after all updates
	Logger.info("EMERGENCY_SWITCH", "Verifying final positions:")
	Logger.info("EMERGENCY_SWITCH", "Source card position: " + str(source_card.global_position))
	Logger.info("EMERGENCY_SWITCH", "Target card position: " + str(target_card.global_position))
	Logger.info("EMERGENCY_SWITCH", "Source slot position: " + str(target_slot.global_position))
	Logger.info("EMERGENCY_SWITCH", "Target slot position: " + str(source_slot.global_position))
	
	# If positions don't match, force them to match
	if source_card.global_position != target_slot.global_position:
		Logger.info("EMERGENCY_SWITCH", "Correcting source card position")
		source_card.global_position = target_slot.global_position
	if target_card.global_position != source_slot.global_position:
		Logger.info("EMERGENCY_SWITCH", "Correcting target card position")
		target_card.global_position = source_slot.global_position
	
	# Play switch sound
	if SfxManager != null:
		SfxManager.play_sfx("switch")
	
	Logger.info("EMERGENCY_SWITCH", "Switch completed successfully")

func _on_character_clicked(character):
	Logger.info("BATTLE_SCENE", "Character clicked as regular interaction: " + character.get_character_name())
	
	# This function handles normal clicks on characters that are not targets
	# For now, we just log that the click happened
	# In the future, we might show character details or other UI
	pass

# Handle battle overlay visibility changes
func _on_battle_overlay_visibility_changed():
	var battle_overlay = get_node_or_null("BattleOverlay")
	if !battle_overlay:
		return
		
	var is_visible = battle_overlay.visible
	Logger.info("BATTLE_SCENE", "Battle overlay visibility changed to: " + str(is_visible))
	
	var character_cards = get_tree().get_nodes_in_group("character")
	
	for card in character_cards:
		# Don't disable the active card if the overlay is visible
		var is_active_card = false
		if is_visible and battle_overlay.displayed_card == card:
			is_active_card = true
		
		# Disable/enable cards based on overlay visibility
		if is_visible and !is_active_card:
			if card.has_method("disable_card"):
				card.disable_card()
		elif !is_visible:
			if card.has_method("enable_card"):
				card.enable_card()
				
	Logger.info("BATTLE_SCENE", "Updated card states for overlay visibility change")
