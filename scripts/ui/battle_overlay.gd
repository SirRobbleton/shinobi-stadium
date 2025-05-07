extends Control

var current_character: CharacterCard = null
@onready var card_detection = $OverlayLayout/PlayerFieldContainer/CardContainer/Control/DetectionArea
@onready var action_detection = $OverlayLayout/PlayerFieldContainer/CenterContainer/Control/DetectionArea
@onready var card_slot = $OverlayLayout/PlayerFieldContainer/CardContainer/Control/CardSlot
@onready var card_container = $OverlayLayout/PlayerFieldContainer/CardContainer
@onready var overlay_color = $OverlayColor  # Reference to the overlay color background
@onready var attack_button = $OverlayLayout/PlayerFieldContainer/CenterContainer/ActionContainer/Attack/Button
@onready var ability_button = $OverlayLayout/PlayerFieldContainer/CenterContainer/ActionContainer/Ability/Button
@onready var player_field_container = $OverlayLayout/PlayerFieldContainer

# References for the fill-center circle elements
var attack_fill_circle: ColorRect
var ability_fill_circle: ColorRect

var displayed_card = null

func _ready():
	# Start hidden
	visible = false
	
	# Set up z-index values for proper layering
	z_index = 10
	z_as_relative = false
	
	# Set overlay color as background (lowest z-index)
	if overlay_color:
		overlay_color.z_index = 0
		overlay_color.z_as_relative = false
	
	# Set card and action containers above the overlay color
	if card_container:
		card_container.z_index = 1
		card_container.z_as_relative = false
		
	# Enable input processing
	set_process_input(true)
	
	# Set mouse filter to stop to block input
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Style the buttons
	style_attack_button()
	style_ability_button()
	
	# Create the fill-center circles
	_create_fill_center_elements()
	
	# Connect button signals for press effects
	if attack_button:
		if !attack_button.button_down.is_connected(_on_button_pressed):
			attack_button.button_down.connect(func(): _on_button_pressed(attack_button))
		if !attack_button.button_up.is_connected(_on_button_released):
			attack_button.button_up.connect(func(): _on_button_released(attack_button))
		if !attack_button.pressed.is_connected(_on_attack_button_pressed):
			attack_button.pressed.connect(_on_attack_button_pressed)
			
	if ability_button:
		if !ability_button.button_down.is_connected(_on_button_pressed):
			ability_button.button_down.connect(func(): _on_button_pressed(ability_button))
		if !ability_button.button_up.is_connected(_on_button_released):
			ability_button.button_up.connect(func(): _on_button_released(ability_button))
		if !ability_button.pressed.is_connected(_on_ability_button_pressed):
			ability_button.pressed.connect(_on_ability_button_pressed)

func _create_fill_center_elements():
	# Create attack button fill-center circle
	if attack_button:
		# Create a clipping container
		var container = Control.new()
		container.name = "FillContainer"
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.clip_contents = true
		container.set_anchors_preset(Control.PRESET_FULL_RECT)
		attack_button.add_child(container)
		
		# Create the circular fill element
		attack_fill_circle = ColorRect.new()
		attack_fill_circle.name = "FillCircle"
		attack_fill_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Make it a large circle positioned at center
		attack_fill_circle.size = Vector2(400, 400)  # Very large to ensure full coverage
		attack_fill_circle.color = Color("#550000")  # Dark red for attack hover
		
		# Position in center
		attack_fill_circle.position = Vector2(
			attack_button.size.x / 2 - attack_fill_circle.size.x / 2,
			attack_button.size.y / 2 - attack_fill_circle.size.y / 2
		)
		
		# Start with zero scale (invisible)
		attack_fill_circle.scale = Vector2(0, 0)
		
		# Add to container with negative z_index to be behind text
		container.add_child(attack_fill_circle)
		container.z_index = -1
	
	# Create ability button fill-center circle
	if ability_button:
		# Create a clipping container
		var container = Control.new()
		container.name = "FillContainer"
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.clip_contents = true
		container.set_anchors_preset(Control.PRESET_FULL_RECT)
		ability_button.add_child(container)
		
		# Create the circular fill element
		ability_fill_circle = ColorRect.new()
		ability_fill_circle.name = "FillCircle"
		ability_fill_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Make it a large circle positioned at center
		ability_fill_circle.size = Vector2(400, 400)  # Very large to ensure full coverage
		ability_fill_circle.color = Color("#003366")  # Dark blue for ability hover
		
		# Position in center
		ability_fill_circle.position = Vector2(
			ability_button.size.x / 2 - ability_fill_circle.size.x / 2,
			ability_button.size.y / 2 - ability_fill_circle.size.y / 2
		)
		
		# Start with zero scale (invisible)
		ability_fill_circle.scale = Vector2(0, 0)
		
		# Add to container with negative z_index to be behind text
		container.add_child(ability_fill_circle)
		container.z_index = -1

func style_attack_button():
	if !attack_button:
		return
		
	# Apply fill-center style with solid black and hover to dark red
	
	# Normal state - black with rounded corners
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#111111")  # Black background
	normal_style.border_width_left = 1
	normal_style.border_width_right = 1
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color("#333333")  # Slight border
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
	# Hover state - transparent to let the fill circle show through
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0, 0, 0, 0)  # Transparent background
	hover_style.border_width_left = 1
	hover_style.border_width_right = 1
	hover_style.border_width_top = 1
	hover_style.border_width_bottom = 1
	hover_style.border_color = Color("#333333")  # Slight border
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	
	# Pressed state - enhanced with inset shadow and glow
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color("#550000")  # Dark red background
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = Color("#ff3333")  # Brighter red border for pop
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.corner_radius_bottom_right = 8
	
	# Add inset shadow effect when pressed
	pressed_style.shadow_size = 4
	pressed_style.shadow_color = Color("#000000", 0.5)
	pressed_style.shadow_offset = Vector2(0, 0)  # Centered shadow for inset effect
	
	# Add some margin to simulate pressing inward
	pressed_style.expand_margin_bottom = 2
	pressed_style.expand_margin_left = 2
	pressed_style.expand_margin_right = 2
	pressed_style.expand_margin_top = 2
	
	# Apply styles
	attack_button.add_theme_stylebox_override("normal", normal_style)
	attack_button.add_theme_stylebox_override("hover", hover_style)
	attack_button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Font overrides - white text always
	attack_button.add_theme_font_size_override("font_size", 30)  # Larger text
	attack_button.add_theme_color_override("font_color", Color("#ffffff"))  # White text
	attack_button.add_theme_color_override("font_hover_color", Color("#ffffff"))  # White text on hover
	attack_button.add_theme_color_override("font_pressed_color", Color("#ffdddd"))  # Slightly different text when pressed
	
	# Make button text uppercase but preserve linebreaks
	var original_text = attack_button.text
	attack_button.text = original_text
	
	# Connect hover signals
	if !attack_button.mouse_entered.is_connected(_on_button_hover_in):
		attack_button.mouse_entered.connect(func(): _on_button_hover_in(attack_button))
	if !attack_button.mouse_exited.is_connected(_on_button_hover_out):
		attack_button.mouse_exited.connect(func(): _on_button_hover_out(attack_button))

func style_ability_button():
	if !ability_button:
		return
		
	# Apply fill-center style with dark grey and hover to dark blue
	
	# Normal state - dark grey with rounded corners
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#333333")  # Dark grey background
	normal_style.border_width_left = 1
	normal_style.border_width_right = 1
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color("#555555")  # Slight border
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
	# Hover state - transparent to let the fill circle show through
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0, 0, 0, 0)  # Transparent background
	hover_style.border_width_left = 1
	hover_style.border_width_right = 1
	hover_style.border_width_top = 1
	hover_style.border_width_bottom = 1
	hover_style.border_color = Color("#555555")  # Slight border
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	
	# Pressed state - enhanced with inset shadow and glow 
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color("#003366")  # Dark blue background
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = Color("#3399ff")  # Brighter blue border for pop
	pressed_style.corner_radius_top_left = 8
	pressed_style.corner_radius_top_right = 8
	pressed_style.corner_radius_bottom_left = 8
	pressed_style.corner_radius_bottom_right = 8
	
	# Add inset shadow effect when pressed
	pressed_style.shadow_size = 4
	pressed_style.shadow_color = Color("#000000", 0.5)
	pressed_style.shadow_offset = Vector2(0, 0)  # Centered shadow for inset effect
	
	# Add some margin to simulate pressing inward
	pressed_style.expand_margin_bottom = 2
	pressed_style.expand_margin_left = 2
	pressed_style.expand_margin_right = 2
	pressed_style.expand_margin_top = 2
	
	# Apply styles
	ability_button.add_theme_stylebox_override("normal", normal_style)
	ability_button.add_theme_stylebox_override("hover", hover_style)
	ability_button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Font overrides - white text always
	ability_button.add_theme_font_size_override("font_size", 30)  # Larger text
	ability_button.add_theme_color_override("font_color", Color("#ffffff"))  # White text
	ability_button.add_theme_color_override("font_hover_color", Color("#ffffff"))  # White text on hover
	ability_button.add_theme_color_override("font_pressed_color", Color("#ddddff"))  # Slightly different text when pressed
	
	# Make button text uppercase but preserve linebreaks
	var original_text = ability_button.text
	ability_button.text = original_text.strip_edges().to_upper()
	
	# Connect hover signals
	if !ability_button.mouse_entered.is_connected(_on_button_hover_in):
		ability_button.mouse_entered.connect(func(): _on_button_hover_in(ability_button))
	if !ability_button.mouse_exited.is_connected(_on_button_hover_out):
		ability_button.mouse_exited.connect(func(): _on_button_hover_out(ability_button))

# Button hover animation - expand the fill circle from center
func _on_button_hover_in(button):
	# Get the correct fill circle
	var fill_circle = null
	if button == attack_button:
		fill_circle = attack_fill_circle
	else:
		fill_circle = ability_fill_circle
		
	if !fill_circle:
		return
	
	# Reset to center position if needed
	fill_circle.position = Vector2(
		button.size.x / 2 - fill_circle.size.x / 2,
		button.size.y / 2 - fill_circle.size.y / 2
	)
	
	# Animate the expansion
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	scale_tween.tween_property(fill_circle, "scale", Vector2(1, 1), 0.5)
	
	# Animate text color with a slight delay
	var text_tween = create_tween()
	text_tween.set_ease(Tween.EASE_OUT)
	text_tween.tween_interval(0.1) # 0.1s delay
	text_tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.3)
	
	# Play hover sound
	if Engine.has_singleton("SfxManager") or get_node_or_null("/root/SfxManager"):
		SfxManager.play_sfx("hover")

# Button hover animation - shrink the fill circle back to nothing
func _on_button_hover_out(button):
	# Get the correct fill circle
	var fill_circle = null
	if button == attack_button:
		fill_circle = attack_fill_circle
	else:
		fill_circle = ability_fill_circle
		
	if !fill_circle:
		return
	
	# Animate the shrinking
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	scale_tween.tween_property(fill_circle, "scale", Vector2(0, 0), 0.5)
	
	# Reset text color
	var text_tween = create_tween()
	text_tween.set_ease(Tween.EASE_IN)
	text_tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.3)

# Button press animation - add scale and flash effects
func _on_button_pressed(button):
	# Create a scale down animation
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	
	# Create a brightness flash effect
	var flash_tween = create_tween()
	flash_tween.set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1), 0.05)
	flash_tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.05)
	
	# Play press sound if available
	if Engine.has_singleton("SfxManager") or get_node_or_null("/root/SfxManager"):
		SfxManager.play_sfx("click")

# Button release animation - restore scale
func _on_button_released(button):
	# Create a scale up animation (restore normal size)
	var scale_tween = create_tween()
	scale_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	scale_tween.tween_property(button, "scale", Vector2(1, 1), 0.2)

# Handle attack button press
func _on_attack_button_pressed():
	print("[BATTLE_OVERLAY] Attack button pressed")
	if current_character:
		print("[BATTLE_OVERLAY] Initiating attack with: " + current_character.character_data.name)
		GamestateManager.begin_attack(current_character.character_data)
		
		# Show valid targets for this attack
		#show_highlighted_targets()

# Handle ability button press
func _on_ability_button_pressed():
	print("[BATTLE_OVERLAY] Ability button pressed")
	if current_character:
		print("[BATTLE_OVERLAY] Activating ability for: " + current_character.character_data.name)
		# This will be implemented later
		pass

# Disable all battle cards (cards in play)
func clear_after_attack():
	print("[BATTLE_OVERLAY] Clearing overlay after attack completion")
	
	# Clean up the displayed card
	if displayed_card:
		displayed_card.queue_free()
		displayed_card = null
	
	# Re-enable all character cards
	var overlay_character_cards = get_tree().get_nodes_in_group("character")
	print("[BATTLE_OVERLAY] Re-enabling " + str(overlay_character_cards.size()) + " character cards")
	
	for card in overlay_character_cards:
		if card.has_method("enable_card"):
			card.enable_card()
	
	# Hide the overlay
	visible = false

func _input(event):
	if !visible:
		return
		
	if event is InputEventMouseButton and event.pressed:
		# Get the mouse position in screen coordinates
		var mouse_pos = get_viewport().get_mouse_position()
		
		# First check if we clicked on a highlighted target (those have priority)
		var clicked_on_target = false
		var input_character_cards = get_tree().get_nodes_in_group("character")
		
		for card in input_character_cards:
			if card.has_meta("is_target"):
				# Try to determine if the click was on this card
				if card.has_node("RigidBody2D"):
					var rigid_body = card.get_node("RigidBody2D")
					var local_pos = rigid_body.get_global_transform().affine_inverse() * mouse_pos
					var size = Vector2(100, 150)  # Approximate card size
					var rect = Rect2(-size/2, size)
					
					if rect.has_point(local_pos):
						print("[BATTLE_OVERLAY] Click detected on highlighted target: " + card.character_data.name)
						clicked_on_target = true
						
						# Check if we need to get the attacker's attack ID
						if current_character and current_character.character_data.has_meta("current_attack_id"):
							var attack_id = current_character.character_data.get_meta("current_attack_id")
							print("[BATTLE_OVERLAY] Found attack ID " + str(attack_id) + " for current attack")
						
						# Allow event to pass through to battle scene to handle the attack
						print("[BATTLE_OVERLAY] Allowing battle scene to handle the target click")
						return
		
		# If we clicked on a target, don't process further
		if clicked_on_target:
			return
		
		# Check if click is inside the entire PlayerFieldContainer
		var clicked_in_overlay = false
		
		if player_field_container:
			# Get rect for the entire PlayerFieldContainer
			var overlay_rect = Rect2(
				player_field_container.global_position, 
				player_field_container.size
			)
			
			# Check if mouse click is within this rect
			if overlay_rect.has_point(mouse_pos):
				clicked_in_overlay = true
				print("[BATTLE_OVERLAY] Click detected within PlayerFieldContainer, keeping overlay open")
		
		# If click was outside the overlay container and not on a target, hide the overlay
		if !clicked_in_overlay:
			print("[BATTLE_OVERLAY] Click outside overlay detected, hiding")
			GamestateManager.hide_battle_overlay(false)
			get_viewport().set_input_as_handled()
			return

func show_character(character: CharacterCard) -> void:
	var character_data = character.character_data
	current_character = character
	print("[BATTLE_OVERLAY] Showing character: " + character_data.name)
	
	# Make sure we're visible and on top
	visible = true
	z_index = 10
	z_as_relative = true
	#character.z_index = 10
	
	# Ensure proper layering when showing
	if overlay_color:
		overlay_color.z_index = 0
		overlay_color.z_as_relative = false
	if card_container:
		card_container.z_index = 2  # Place above overlay color
		card_container.z_as_relative = false
	
	# Find the original battle card to reference its properties
	var is_support = false
	var original_card = null
	var all_character_cards = get_tree().get_nodes_in_group("character")
	for card in all_character_cards:
		if card.character_data == character_data:
			is_support = card.is_support_character()
			original_card = card
			break
	
	# Update button text with character attack and ability information
	if attack_button and character_data:
		var attack_name = ""
		var attack_damage = 0
		
		if is_support:
			# Use support attack values but show the actual attack name
			attack_name = character_data.main_jutsu_name  # Use main attack name instead of "Support Attack"
			attack_damage = character_data.support_jutsu_damage
			print("[BATTLE_OVERLAY] Card is in support position, using support damage")
		else:
			# Use main attack values
			attack_name = character_data.main_jutsu_name
			attack_damage = character_data.main_jutsu_damage
			print("[BATTLE_OVERLAY] Card is in main position, using main damage")
		
		attack_button.text = attack_name + "\n" + str(attack_damage) + " DMG"
		print("[BATTLE_OVERLAY] Set attack button text to: " + attack_button.text)
	
	if ability_button and character_data:
		ability_button.text = character_data.ability
		print("[BATTLE_OVERLAY] Set ability button text to: " + ability_button.text)
	
	# Disable all battle cards (cards in play)
	var scene_character_cards = get_tree().get_nodes_in_group("character")
	print("[BATTLE_OVERLAY] Found " + str(scene_character_cards.size()) + " character cards")
	
	for card in scene_character_cards:
		if !card.is_preview:
			if card.has_method("disable_card"):
				card.disable_card()
	
	# Clear any existing card
	if displayed_card:
		print("[BATTLE_OVERLAY] Clearing existing displayed card")
		#displayed_card.get_parent().remove_child(displayed_card)
		displayed_card = null
	
	# Create a duplicate of the card
	#var card_scene = load("res://scenes/objects/character_card.tscn")
	#displayed_card = card_scene.instantiate()
	displayed_card = character
	print("[BATTLE_OVERLAY] Created new card instance: " + str(displayed_card))
	
	# Setup the card with character data
	if displayed_card.has_method("setup"):
		#displayed_card.setup(character_data)
		#print("[BATTLE_OVERLAY] Setup card with character data")
		displayed_card = character
		# Copy player ownership from the original card
		#if original_card:
		#	displayed_card.player_owned = original_card.player_owned
		#	print("[BATTLE_OVERLAY] Set player_owned to: " + str(displayed_card.player_owned))
		# Add to the card slot
		displayed_card.get_parent().remove_child(displayed_card)
		card_slot.get_parent().add_child(displayed_card)
		print("[BATTLE_OVERLAY] Added card to slot")
		# Scale the card
		displayed_card.scale = Vector2(2.0, 2.0)		
		# Center the card in the slot
		
		print("DISPLAY POSITION BEFORE: " + str(displayed_card.position))
		print("DISPLAY POSITION GLOBAL BEFORE: " + str(displayed_card.global_position))

		displayed_card.position = card_slot.position
		print("DISPLAY POSITION AFTER: " + str(displayed_card.position))
		print("DISPLAY GLOBAL AFTER: " + str(displayed_card.global_position))
		print("CARD SLOT GLOBAL AFTER: " + str(card_slot.global_position))
		print("CARD SLOT POSITION AFTER: " + str(card_slot.position))

		 #Freeze the card to prevent physics interactions
		if displayed_card.has_method("set_freeze"):
			displayed_card.set_freeze(true)
		elif displayed_card.has_node("RigidBody2D"):
			displayed_card.get_node("RigidBody2D").freeze = true
			
		#Disable input on the card
		displayed_card.set_process_input(false)
		if displayed_card.has_node("RigidBody2D"):
			displayed_card.get_node("RigidBody2D").input_pickable = false
			
		#Ensure the card is not disabled or modulated
		if displayed_card.has_method("enable_card"):
			displayed_card.enable_card()
		displayed_card.modulate = Color(1, 1, 1, 1)  # Reset modulation
			
		print("[BATTLE_OVERLAY] Created and displayed card for: " + character_data.name)
		print("[BATTLE_OVERLAY] Card state - is_disabled: " + str(displayed_card.is_disabled) + 
			" | modulate: " + str(displayed_card.modulate))
	else:
		push_error("Card instance does not have setup method!")

# Show character and highlight valid targets
func show_highlighted_targets():
	print("[BATTLE_OVERLAY] Highlighting valid targets for: " + current_character.character_data.name)
	
	# Get all opponent characters
	var all_characters = get_tree().get_nodes_in_group("character")
	var opponent_characters = []
	
	# Filter for opponent characters
	for character in all_characters:
		if !character.is_preview and character.has_meta("character_data"):
			var char_data = character.get_meta("character_data")
			
			# Skip if character is on the same side as the attacker
			if displayed_card && character.player_owned == displayed_card.player_owned:
				print("[BATTLE_OVERLAY] Skipping " + character.get_character_name() + " - same side as attacker (player_owned: " + str(character.player_owned) + ")")
				continue
				
			# Skip if character is already defeated
			if char_data.current_hp <= 0:
				continue
				
			opponent_characters.append(character)
			
	# Check if we found any valid targets
	if opponent_characters.size() == 0:
		print("[BATTLE_OVERLAY] No valid targets found!")
		# Just leave the overlay open, showing only the attacker's card
		return
		
	# Ask battle scene to highlight all valid targets
	var battle_scene = get_tree().current_scene
	for target in opponent_characters:
		battle_scene.highlight_character(target)
		
		# Ensure target's backlight is visible
		if target.has_node("RigidBody2D/CharacterVisuals/Portrait/BacklightPanel"):
			var backlight = target.get_node("RigidBody2D/CharacterVisuals/Portrait/BacklightPanel")
			backlight.modulate = Color(1.0, 0.3, 0.3, 0.7)  # Red tint for targetable cards
			backlight.visible = true
		
		# Make sure it's input_pickable for targeting
		if target.has_node("RigidBody2D"):
			target.get_node("RigidBody2D").input_pickable = true
		
		print("[BATTLE_OVERLAY] Highlighted target: " + target.character_data.name)
		
