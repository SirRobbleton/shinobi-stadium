extends Node

# Define game phases enum
enum Phases {DRAW, CHAKRA, MAIN, END}

# Basic turn tracking
var current_player: String = "player" # "player" or "opponent"

# Attack ID tracking system
var last_attack_id: int = 0

# Signal for communication
signal turn_changed(new_player)

# Battle state tracking
var has_switched_this_turn: bool = false
var in_battle_phase: bool = false
signal switch_performed(source, target)

# Battle attack signals
signal attack_initiated(attacker_data)
signal target_required(attacker_data)
signal attack_performed(attacker, target, is_defeated)

# Battle overlay management
var battle_overlay = null

# Game state variables
var current_phase = Phases.CHAKRA
var opponent_shinobi = []
var attack_in_progress = false  # Track when an attack is currently happening

func _ready():
	Logger.info("GAMESTATE", "Initialized")

func change_turn():
	current_player = "player" if current_player == "opponent" else "opponent"
	Logger.info("GAMESTATE", "Turn changed to: " + current_player)
	
	# Reset switching state for the new turn - make sure these are always reset
	has_switched_this_turn = false
	in_battle_phase = false
	Logger.info("GAMESTATE", "Reset turn state: has_switched_this_turn = false, in_battle_phase = false")
	
	emit_signal("turn_changed", current_player)

# This is just a placeholder for future functionality
func start_battle():
	Logger.info("GAMESTATE", "Starting battle")
	current_player = "player"
	has_switched_this_turn = false
	in_battle_phase = false
	emit_signal("turn_changed", current_player)

func perform_switch(source_card, target_card) -> bool:
	Logger.log_message("GAMESTATE", "Checking if switch is allowed...")
	Logger.log_message("GAMESTATE", "Current player: " + current_player)
	Logger.log_message("GAMESTATE", "Has switched this turn: " + str(has_switched_this_turn))
	Logger.log_message("GAMESTATE", "In battle phase: " + str(in_battle_phase))
	
	if current_player == "player" and !has_switched_this_turn and !in_battle_phase:
		Logger.log_message("GAMESTATE", "Approving switch: " + source_card.character_data.name + " <-> " + target_card.character_data.name)
		has_switched_this_turn = true
		
		# Emit signal immediately to trigger the UI update
		emit_signal("switch_performed", source_card, target_card)
		Logger.log_message("GAMESTATE", "Emitted switch_performed signal")
		return true
	else:
		Logger.log_message("GAMESTATE", "Rejecting switch - not player's turn ("+current_player+"), already switched ("+str(has_switched_this_turn)+"), or in battle phase ("+str(in_battle_phase)+")")
		return false

func enter_battle_phase():
	Logger.log_message("GAMESTATE", "Entering battle phase")
	in_battle_phase = true

# Begin an attack from a character
func begin_attack(character):
	Logger.log_message("GAMESTATE", "Beginning attack from: " + character.name)
	
	# Ensure we have a reference to the battle overlay
	var battle_scene = get_tree().current_scene
	var battle_overlay = battle_scene.get_node_or_null("BattleOverlay")
	
	if !battle_overlay:
		Logger.log_message("GAMESTATE", "Error: Battle overlay not found!")
		return
	
	# Highlight valid targets for attack
	if battle_overlay.has_method("show_highlighted_targets"):
		battle_overlay.show_highlighted_targets()
	
	Logger.info("BATTLE", "Hiding overlay after attack")
	hide_battle_overlay(true)
		
	Logger.log_message("GAMESTATE", "Attack setup complete - waiting for target selection")

# Process the actual attack once target is selected
func perform_attack(attacker_data: CharacterData, target_data: CharacterData):
	Logger.log_message("ATTACK", "========== ATTACK EXECUTION START ==========")
	Logger.log_message("ATTACK", "Attacker: " + attacker_data.name + ", Target: " + target_data.name)
	
	# Find the attacker and target character cards
	var attacker_card = null
	var target_character = null
	var character_cards = get_tree().get_nodes_in_group("character")
	
	Logger.log_message("ATTACK", "Searching through " + str(character_cards.size()) + " character cards")
	
	for card in character_cards:
		# Log card details for debugging
		if card.character_data == attacker_data:
			attacker_card = card
			Logger.log_message("ATTACK", "Found attacker card: " + card.name + " at position " + str(card.global_position))
			if card.has_meta("slot_reference"):
				var slot = card.get_meta("slot_reference")
				Logger.log_message("ATTACK", "Attacker slot position: " + str(slot.global_position))
			else:
				Logger.log_message("ATTACK", "WARNING: Attacker has no slot_reference meta!")
				
		if card.character_data == target_data:
			target_character = card
			Logger.log_message("ATTACK", "Found target card: " + card.name + " at position " + str(card.global_position))
			if card.has_meta("slot_reference"):
				var slot = card.get_meta("slot_reference")
				Logger.log_message("ATTACK", "Target slot position: " + str(slot.global_position))
			else:
				Logger.log_message("ATTACK", "WARNING: Target has no slot_reference meta!")
	
	if !attacker_card:
		Logger.log_message("ATTACK", "ERROR: Could not find attacker card in scene!")
	
	if !target_character:
		Logger.log_message("ATTACK", "ERROR: Could not find target character card in scene!")
		return false
	
	# Log pre-attack health
	Logger.log_message("ATTACK", "Target pre-attack health: " + str(target_data.current_hp) + "/" + str(target_data.hp))
	
	# Determine damage based on position (support or main)
	var damage_amount = 30 # Fallback default
	var attack_name = ""
	
	if attacker_card:
		if attacker_card.is_support:
			# Use support attack damage
			damage_amount = attacker_data.support_jutsu_damage
			attack_name = attacker_data.main_jutsu_name if attacker_data.main_jutsu_name else "Support Attack"
			Logger.log_message("ATTACK", "Using SUPPORT attack: " + attack_name + " with damage: " + str(damage_amount))
		else:
			# Use main attack damage
			damage_amount = attacker_data.main_jutsu_damage
			attack_name = attacker_data.main_jutsu_name
			Logger.log_message("ATTACK", "Using MAIN attack: " + attack_name + " with damage: " + str(damage_amount))
	else:
		Logger.log_message("ATTACK", "WARNING: Using default damage value due to missing attacker card")
	
	Logger.log_message("ATTACK", "Applying " + str(damage_amount) + " damage using " + attack_name)
	var is_defeated = target_data.take_damage(damage_amount)
	
	# Log post-attack health
	Logger.log_message("ATTACK", "Target post-attack health: " + str(target_data.current_hp) + "/" + str(target_data.hp))
	
	# Update character visuals if we found the character object
	if target_character:
		var hp_label = target_character.get_node("RigidBody2D/CharacterVisuals/Portrait/HPColor/HPLabel")
		if hp_label:
			Logger.log_message("ATTACK", "Updating HP label from: " + hp_label.text + " to: " + str(target_data.current_hp))
			hp_label.text = str(target_data.current_hp)
		else:
			Logger.log_message("ATTACK", "ERROR: Could not find HP label on character card")
		
		# Create floating damage number
		show_damage_number(target_character, damage_amount)
	else:
		Logger.log_message("ATTACK", "ERROR: Could not find target character card in character group")
	
	# Emit signal with defeat information
	emit_signal("attack_performed", attacker_data, target_data, is_defeated)
	Logger.log_message("ATTACK", "Signal 'attack_performed' emitted. Defeated: " + str(is_defeated))
	
	Logger.log_message("ATTACK", "========== ATTACK EXECUTION COMPLETE ==========")
	return is_defeated

# Show floating damage number for visual feedback
func show_damage_number(character, damage_amount):
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage_amount)
	damage_label.add_theme_color_override("font_color", Color(1, 0, 0))
	damage_label.add_theme_font_size_override("font_size", 48)  # Increased from 24
	
	# Add an outline effect for better visibility instead of font weight
	damage_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	damage_label.add_theme_constant_override("outline_size", 3)  # Increased outline for bold appearance
	
	# Add to scene
	get_tree().current_scene.add_child(damage_label)
	
	# Position the label above the character
	damage_label.global_position = character.global_position + Vector2(0, -70)
	
	# Create more dramatic animation
	var tween = create_tween()
	
	# First scale up quickly
	tween.tween_property(damage_label, "scale", Vector2(1.5, 1.5), 0.3)
	
	# Then float up and fade out
	tween.tween_property(damage_label, "scale", Vector2(2.0, 2.5), 0.4)
	tween.parallel().tween_property(damage_label, "global_position:y", 
									damage_label.global_position.y - 300, 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0, 0.8)
	tween.tween_callback(damage_label.queue_free)

func show_battle_overlay(character: CharacterCard) -> void:
	if battle_overlay == null:
		# Get the battle overlay from the current scene
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.has_node("BattleOverlay"):
			battle_overlay = current_scene.get_node("BattleOverlay")
	
	if battle_overlay:
		Logger.log_message("GAMESTATE", "Showing battle overlay for character: " + character.character_data.name)
		battle_overlay.show_character(character)
		#battle_overlay.visible = true

func is_in_battle_scene() -> bool:
	var scene_manager = get_node_or_null("/root/SceneManager")
	return scene_manager and scene_manager.is_in_battle_scene()

func hide_battle_overlay(after_attack: bool = false):
	Logger.log_message("GAMESTATE", "Hiding battle overlay (after_attack=" + str(after_attack) + ")")
	
	# Find the BattleOverlay in the current scene
	var current_scene = get_tree().current_scene
	var battle_overlay = current_scene.get_node_or_null("BattleOverlay")
	
	if !battle_overlay:
		Logger.log_message("GAMESTATE", "No BattleOverlay found in current scene to hide")
		return
	
	# Always use unified clear_overlay logic
	if battle_overlay.has_method("clear_overlay"):
		battle_overlay.clear_overlay()
		Logger.log_message("GAMESTATE", "Called clear_overlay on battle overlay")
	else:
		Logger.log_message("GAMESTATE", "ERROR: BattleOverlay doesn't have clear_overlay method!")
		battle_overlay.visible = false
	
	# Clear any target highlights in the battle scene
	if is_in_battle_scene() and current_scene.has_method("clear_highlights"):
		Logger.log_message("GAMESTATE", "Clearing target highlights in battle scene")
		current_scene.clear_highlights()

# Generate a unique attack ID
func _generate_attack_id(attacker_name):
	last_attack_id += 1
	return str(attacker_name) + "_attack_" + str(last_attack_id)
