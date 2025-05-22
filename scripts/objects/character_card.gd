extends Node2D
class_name CharacterCard

# Import the InputSettings class
const InputSettings = preload("res://scripts/utils/input_settings.gd")

# Preserved signals for external compatibility
signal card_clicked(card)
signal zoom_requested(character_data)
signal card_selected(character_data, card)
signal card_deselected(character_data, card)
signal drag_started(card)
signal drag_ended(card)
signal switch_requested(source_card, target_card)
signal target_clicked(card)
signal place_character_on_slot(character: CharacterCard, slot: CardSlot)

# Node references
@onready var portrait = $RigidBody2D/CharacterVisuals/Portrait
@onready var hp_label = $RigidBody2D/CharacterVisuals/Portrait/HPColor/HPLabel
@onready var hover_panel = $RigidBody2D/CharacterVisuals/Portrait/BacklightPanel
@onready var target_panel = $RigidBody2D/CharacterVisuals/Portrait/TargetPanel
@onready var target_hover_panel = $RigidBody2D/CharacterVisuals/Portrait/TargetHoverPanel
@onready var rigid_body = $RigidBody2D
@onready var collision_shape = $RigidBody2D/CollisionShape2D

# State management
enum CardState { IDLE, CLICKED, DRAGGING, TARGETED}
enum CardInputState { DISABLED, TARGETABLE, SELECTABLE, PREVIEW }
enum SceneType { SELECTION, BATTLE }

var current_state: CardState = CardState.IDLE
signal current_state_changed(old_state, new_state)

var current_input_state: CardInputState = CardInputState.SELECTABLE
signal current_input_state_changed(old_state, new_state)

var player_id = null

func set_current_state(val: CardState) -> void:
	#if current_state == val:
	#	return
	var old_state = current_state
	current_state = val
	match val:
		CardState.IDLE:
			# TODO: logic for IDLE state
			pass
		CardState.CLICKED:
			# TODO: logic for CLICKED state
			pass
		CardState.DRAGGING:
			# TODO: logic for DRAGGING state
			pass
		CardState.TARGETED:
			target_hover_panel.visible = true
			target_panel.visible = false
			tween_pulsate_glow()
	emit_signal("current_state_changed", old_state, val)
	_on_current_state_changed(old_state, val)

func _on_current_state_changed(old_state, new_state) -> void:
	# Optional hook for state transition side effects
	pass

func set_current_input_state(val: CardInputState) -> void:
	if current_input_state == val:
		return
	var old_state = current_input_state
	current_input_state = val
	match val:
		CardInputState.DISABLED:
			# TODO: logic for DISABLED state
			pass
		CardInputState.TARGETABLE:
			# TODO: logic for TARGETABLE state
			pass
		CardInputState.SELECTABLE:
			# TODO: logic for SELECTABLE state
			pass
		CardInputState.PREVIEW:
			# TODO: logic for PREVIEW state
			pass
	emit_signal("current_input_state_changed", old_state, val)
	_on_current_input_state_changed(old_state, val)

func _on_current_input_state_changed(old_state, new_state) -> void:
	# Optional hook for input state transition side effects
	pass

var scene_type: SceneType
var click_timer: Timer
var last_click_time: float = 0

# These are now managed by InputSettings
# var double_click_threshold: float = 0.3
# var long_press_threshold: float = 0.3 

# Click handling
var pending_click: bool = false
var pending_click_timer: Timer

# Card data
var character_data: CharacterData
var is_preview: bool = false
var is_duplicate: bool = false
var is_targetable: bool = false
var original_card_reference: CharacterCard = null
var player_owned: bool = false
var is_dragging: bool = false  # Added this back as it's needed for drag state

# Visual state
var is_hovered: bool = false
var is_disabled: bool = false

# Add this with the other variable declarations at the top of the file
var current_slot: Area2D = null  # Reference to the slot this card is currently in

# Floating animation variables
var floating_tween: Tween = null
var original_position: Vector2 = Vector2.ZERO
var float_height: float = 15.0
var is_floating: bool = false

# Add these near other variable declarations at the top
var float_bob_speed: float = 1.5
var float_bob_amount: float = 5.0
var float_time: float = 0.0

# Add these new static variables
static var DRAG_Z_INDEX: int = 15
static var DEFAULT_Z_INDEX: int = 5

# Add scaling variables to control card size during drag
var normal_scale: Vector2 = Vector2(1.0, 1.0)
var drag_scale: Vector2 = Vector2(1.1, 1.1)

# Add these with other class variables at the top
var float_tween: Tween = null
var glow_tween: Tween = null

func _ready():
	# Initialize scene type
	scene_type = SceneType.SELECTION if is_in_selection_scene() else SceneType.BATTLE

	# Setup long press timer
	click_timer = Timer.new()
	click_timer.one_shot = true
	click_timer.timeout.connect(_on_long_press_timeout)
	add_child(click_timer)
	
	# Setup single click timer for distinguishing from double clicks
	pending_click_timer = Timer.new()
	pending_click_timer.one_shot = true
	pending_click_timer.timeout.connect(_on_pending_click_timeout)
	add_child(pending_click_timer)
	
	# Setup visual effects
	if hover_panel:
		hover_panel.visible = false
	if target_panel:
		target_panel.visible = false
	
	# Add to groups
	add_to_group("cards")
	if !is_preview:
		add_to_group("character")
		
	# Enable input
	set_process_input(true)
	set_process(true)

func _input(event):
	if is_disabled or _is_blocked_by_battle_overlay():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and is_hovered:
			if current_input_state != CardInputState.DISABLED:
				_handle_mouse_press()
		else:
			_handle_mouse_release()
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _process(delta):
	# Handle floating animation for targetable cards
	if is_targetable and current_input_state == CardInputState.TARGETABLE:
		float_time += delta
		if rigid_body and original_position != Vector2.ZERO:
			var bob_offset = sin(float_time * float_bob_speed) * float_bob_amount
			rigid_body.position.y = original_position.y - float_height + bob_offset
	
# Set card as targetable/not targetable
func set_targetable(targetable: bool):
	Logger.info("CARD_STATE", "Setting " + get_character_name() + " targetable: " + str(targetable), Logger.DetailLevel.MEDIUM)
	
	# Update state variables
	is_targetable = targetable
	
	if targetable:
		# Store original position for floating animation reference
		if rigid_body and original_position == Vector2.ZERO:
			original_position = rigid_body.position
		
		# Update input state
		current_input_state = CardInputState.TARGETABLE
		
		# Make sure card is enabled
		if rigid_body:
			rigid_body.input_pickable = true
		
		# Show target panel
		if target_panel:
			target_panel.visible = true
			target_panel.modulate = Color(1.0, 0.3, 0.3, 0.7)  # Red tint
		
		# Start floating animation
		_start_floating_animation()
		
		# When card becomes targetable, it should emit the target_clicked signal on click
		# Add signals if needed
		if !is_connected("card_clicked", Callable(self, "_on_targetable_card_clicked")):
			connect("card_clicked", Callable(self, "_on_targetable_card_clicked"))
	else:
		# Reset back to normal state
		current_input_state = CardInputState.SELECTABLE
		
		# Hide target panel
		if target_panel:
			target_panel.visible = false
		
		# Stop floating animation and return to original position
		_stop_floating_animation()
		
		# Disconnect targetable click handler if connected
		if is_connected("card_clicked", Callable(self, "_on_targetable_card_clicked")):
			disconnect("card_clicked", Callable(self, "_on_targetable_card_clicked"))

func _start_floating_animation():
	if is_floating or original_position == Vector2.ZERO or !rigid_body:
		return
	
	is_floating = true
	
	# Start the physics-based animation
	float_time = 0.0
	
	# Add a gentle glow to the card
	modulate = Color(1.1, 1.1, 1.3, 1.0)
	
	# Initial rise animation
	var start_tween = create_tween()
	start_tween.tween_property(rigid_body, "position:y", 
		original_position.y - float_height, 0.3).set_ease(Tween.EASE_OUT)

func _stop_floating_animation():
	is_floating = false
	
	if rigid_body and original_position != Vector2.ZERO:
		# Smoothly return to original position
		var return_tween = create_tween()
		return_tween.tween_property(rigid_body, "position", 
			original_position, 0.2).set_ease(Tween.EASE_OUT)
	
	# Reset modulate
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# Reset position tracking
	original_position = Vector2.ZERO

# Handle clicks on targetable cards
func _on_targetable_card_clicked(card):
	if card == self and is_targetable and current_input_state == CardInputState.TARGETABLE:
		Logger.info("CARD_STATE", "Targetable card clicked: " + get_character_name(), Logger.DetailLevel.MEDIUM)
		emit_signal("target_clicked", self)
		# Don't return anything, as it might cause type mismatches

func _handle_mouse_press():
	# Special handling for targetable cards - always take priority
	match current_input_state:
		CardInputState.TARGETABLE:
			Logger.info("CARD_STATE", "Click on targetable card: " + get_character_name(), Logger.DetailLevel.MEDIUM)
			#emit_signal("card_clicked", self)
			tween_damage_popup(BattleStateManager.perform_attack(BattleStateManager.current_character, self))
			tween_pop_hp_label()
			tween_shake_card()
			update_hp()
			# No need to process further for targetable cards
			return
		
	match current_state:
		CardState.IDLE:
			# Check if this is a double click
			var current_time = Time.get_ticks_msec()
			var time_since_last_click = current_time - last_click_time
			
			InputSettings.log_input_event("Click detected on " + get_character_name() + 
				", time since last click: " + str(time_since_last_click) + "ms" +
				", threshold: " + str(InputSettings.double_click_threshold * 1000) + "ms")
			
			if time_since_last_click < InputSettings.double_click_threshold * 1000:
				# This is a double click - handle it immediately
				InputSettings.log_input_event("Double click detected on " + get_character_name())
				_handle_double_click()
				last_click_time = 0  # Reset to avoid triple-click issues
				
				# Cancel any pending single click
				if pending_click:
					pending_click = false
					pending_click_timer.stop()
			else:
				# This is potentially the first click of a double click
				InputSettings.log_input_event("First click detected on " + get_character_name() + 
					", waiting for potential second click")
				last_click_time = current_time
				
				# Start long press detection
				set_current_state(CardState.CLICKED)
				click_timer.start(InputSettings.long_press_threshold)
				
				# Schedule single click action after the double click threshold
				pending_click = true
				pending_click_timer.start(InputSettings.double_click_threshold)
		
		CardState.CLICKED:
			# If we're already in CLICKED state and get another press, treat as double click
			InputSettings.log_input_event("Second click while in CLICKED state for " + get_character_name())
			_handle_double_click()

# This timeout means the user clicked once and didn't click again within the double-click threshold
func _on_pending_click_timeout():
	if pending_click:
		InputSettings.log_input_event("Single click confirmed for " + get_character_name() + 
			" (no second click detected)")
		pending_click = false
		_handle_single_click()

# Rename for clarity
func _on_long_press_timeout():
	if current_state == CardState.CLICKED:
		InputSettings.log_input_event("Long press detected for " + get_character_name())
		_handle_long_press()

func _handle_mouse_release():
	if current_state == CardState.CLICKED and click_timer.time_left > 0:
		# This was a short click - we'll let the pending_click_timer handle it
		InputSettings.log_input_event("Mouse released after short press for " + get_character_name() + 
			", waiting for pending click timer")
		
		# Make sure we didn't start dragging
		click_timer.stop()
	elif current_state == CardState.DRAGGING:
		_end_drag_operation()
		return
	set_current_state(CardState.IDLE)

# Renamed for clarity
func _handle_single_click():
	InputSettings.log_input_event("Executing single-click action for " + get_character_name() + 
		" in " + ("Selection" if scene_type == SceneType.SELECTION else "Battle") + " scene")
	
	match scene_type:
		SceneType.SELECTION:
			ZoomManager.show_card(character_data)
		SceneType.BATTLE:
			BattleStateManager.show_battle_overlay(self)
			print("SHOE BATTLE OVERLAY")

func _handle_long_press():
	InputSettings.log_input_event("Long press handling initiated for " + get_character_name())
	
	# Cancel any pending click action since we're going to drag instead
	pending_click = false
	pending_click_timer.stop()
	
	set_current_state(CardState.DRAGGING)
	is_dragging = true
	
	match scene_type:
		SceneType.SELECTION:
			if !is_preview:
				_start_drag_operation(self)
			else:
				_start_drag_operation(self)
		SceneType.BATTLE:
			if !BattleStateManager.has_switched_this_turn:
				_start_drag_operation(self)
			else:
				InputSettings.log_input_event("Player has already switched this turn: " + get_character_name())
				return
	
	InputSettings.log_input_event("Started drag operation for " + get_character_name())

func _handle_double_click():
	InputSettings.log_input_event("Executing double-click action for " + get_character_name() +
		" in " + ("Selection" if scene_type == SceneType.SELECTION else "Battle") + " scene")
	
	# Cancel any pending single click action
	pending_click = false
	pending_click_timer.stop()
	
	# Always zoom for double clicks regardless of scene
	ZoomManager.show_card(character_data)

func _handle_mouse_motion(event):
	if current_state == CardState.DRAGGING:
		if !BattleStateManager.has_switched_this_turn:
			_update_drag_position(event.position)

func _start_drag_operation(card: CharacterCard):
	# Switch physics mode to kinematic for smooth dragging
	if card.rigid_body:
		card.rigid_body.freeze = false
		card.rigid_body.linear_velocity = Vector2.ZERO
		card.rigid_body.angular_velocity = 0
		Logger.info("PHYSICS", "Set rigid body freeze=false (dragging) for card: " + card.get_character_name(), Logger.DetailLevel.LOW)
	# Bring dragged card to front layer
	card.z_index = DRAG_Z_INDEX
	
	Logger.info("DRAG", "Starting drag operation | Card: " + card.get_character_name() + 
		  " | Is Preview: " + str(card.is_preview) + 
		  " | Scene: " + ("Selection" if scene_type == SceneType.SELECTION else "Battle"), 
		  Logger.DetailLevel.MEDIUM)
	
	SfxManager.play_sfx("drag")
	if scene_type == SceneType.SELECTION and !card.is_preview:
		# Get position based on scene type first
		var mouse_pos = get_tree().current_scene.get_global_mouse_position()		
		Logger.info("DRAG", "Target position for drag: " + str(mouse_pos), Logger.DetailLevel.LOW)
		
		# Create preview card
		var preview = card.duplicate()
		preview.is_preview = true
		preview.is_duplicate = true
		preview.original_card_reference = card
		# Setup preview card
		_setup_preview_card(preview)
		
		# Add to scene and position at mouse
		get_tree().current_scene.add_child(preview)
		
		# Set position after adding to scene
		if preview.rigid_body:
			preview.rigid_body.global_position = mouse_pos
		else:
			preview.global_position = mouse_pos
		
		Logger.info("DRAG", "Created preview card for " + card.get_character_name() + " | Position: " + str(mouse_pos), Logger.DetailLevel.MEDIUM)
		
		# Disable original card
		card.disable_card()
		Logger.info("CARD_STATE", "Disabled original card: " + card.get_character_name(), Logger.DetailLevel.MEDIUM)
		
		# Start dragging preview
		preview.is_dragging = true
		preview.set_current_state(CardState.DRAGGING)
		emit_signal("drag_started", preview)
		_apply_drag_visual_effects(true, preview)
		# Ensure preview also floats above
		preview.set_current_state(CardState.DRAGGING)
		preview.z_index = DRAG_Z_INDEX
	else:
		# For battle scene or preview cards, always set dragging state
		card.is_dragging = true
		card.set_current_state(CardState.DRAGGING)
		
		# Make sure the emit_signal is called to notify listeners
		emit_signal("drag_started", card)
		
		# Apply visual effects for dragging
		_apply_drag_visual_effects(true, card)
		# Ensure this card floats above
		z_index = DRAG_Z_INDEX
		Logger.info("DRAG", "Started dragging card directly", Logger.DetailLevel.MEDIUM)
		
		# Ensure we're actually dragging the card by updating its position on the next frame
		#call_deferred("_update_drag_position", get_viewport().get_mouse_position())

func _setup_preview_card(preview: CharacterCard):
	Logger.info("DRAG", "Setting up preview card | Original: " + 
		  (original_card_reference.get_character_name() if original_card_reference else "None"), 
		  Logger.DetailLevel.MEDIUM)
	
	# Initialize node references
	preview.portrait = preview.get_node("RigidBody2D/CharacterVisuals/Portrait")
	preview.hp_label = preview.get_node("RigidBody2D/CharacterVisuals/Portrait/HPColor/HPLabel")
	preview.hover_panel = preview.get_node("RigidBody2D/CharacterVisuals/Portrait/BacklightPanel")
	preview.target_panel = preview.get_node("RigidBody2D/CharacterVisuals/Portrait/TargetPanel")
	preview.rigid_body = preview.get_node("RigidBody2D")
	preview.collision_shape = preview.get_node("RigidBody2D/CollisionShape2D")
	
	# Initialize state
	preview.set_current_state(CardState.DRAGGING)
	preview.is_dragging = true
	preview.scene_type = scene_type
	
	# Setup card with original card's data
	if is_preview:
		preview.setup(original_card_reference.character_data)
		Logger.info("DRAG", "Setup preview with original card's data", Logger.DetailLevel.LOW)
	else:
		preview.setup(character_data)
		Logger.info("DRAG", "Setup preview with current card's data", Logger.DetailLevel.LOW)

func _update_drag_position(position):
	if current_state == CardState.DRAGGING:
		# Log the drag operation if debugging is enabled
		if InputSettings.debug_drag:
			Logger.info("DRAG_DEBUG", "Updating drag position: " + str(position) + 
				  " | Card: " + get_character_name() + " Node " +  str(self) +
				  " | State: " + str(current_state) +
				" | Duplicate: " + str(is_duplicate) +
				  " | Is dragging: " + str(is_dragging))
		
		# Get position based on scene type
		var target_pos
		if scene_type == SceneType.SELECTION:
			# In selection scene, use viewport coordinates
			target_pos = get_viewport().get_mouse_position()
			
			# Check for nearby card slots
			var nearest_slot = _find_nearest_card_slot(target_pos)
			if nearest_slot and _is_within_snap_distance(target_pos, nearest_slot):
				Logger.info("SLOT", "Highlighting slot: " + str(nearest_slot), Logger.DetailLevel.LOW)
				# Highlight the slot
				if nearest_slot.has_method("set_highlight"):
					nearest_slot.set_highlight(true)
			else:
				# Remove highlight from all slots
				for slot in get_tree().get_nodes_in_group("card_slots"):
					if slot.has_method("set_highlight"):
						slot.set_highlight(false)
		else:
			# In battle scene, use global coordinates
			target_pos = get_tree().current_scene.get_global_mouse_position()
		
		# Only update the rigid body position if it exists
		if rigid_body:
			rigid_body.global_position = target_pos
			if InputSettings.debug_drag:
				Logger.info("DRAG_DEBUG", "Updated rigid body position to: " + str(target_pos))
		else:
			# If no rigid body, update the card position directly
			global_position = target_pos
			if InputSettings.debug_drag:
				Logger.info("DRAG_DEBUG", "Updated card position to: " + str(target_pos))
	elif InputSettings.debug_drag:
		Logger.info("DRAG_DEBUG", "Not updating position because not in dragging state. Current state: " + str(current_state))

func _apply_drag_visual_effects(is_dragging: bool, card: CharacterCard):
	if is_dragging:
		# Scale the portrait during drag, fallback to card if missing
		if card.portrait:
			card.portrait.scale = drag_scale
		else:
			card.scale = drag_scale
		card.z_index = DRAG_Z_INDEX
		if card.hover_panel:
			card.hover_panel.visible = false
	else:
		# Reset portrait scale after drag, fallback to card
		if card.portrait:
			card.portrait.scale = normal_scale
		else:
			card.scale = normal_scale
		#card.z_index = 0
		if card.hover_panel and card.is_hovered:
			card.hover_panel.visible = true

# Helper functions
func is_in_selection_scene() -> bool:
	return SceneManager.is_in_selection_scene()

func is_in_battle_scene() -> bool:
	return SceneManager.is_in_battle_scene()

func _is_blocked_by_battle_overlay() -> bool:
	if has_meta("is_target"):
		return false
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.is_in_battle_scene():
		var current_scene = get_tree().current_scene
		var battle_overlay = current_scene.get_node_or_null("BattleOverlay")
		if battle_overlay and battle_overlay.visible:
			var parent = get_parent()
			while parent:
				if parent.name == "BattleOverlay":
					return false
				parent = parent.get_parent()
			return true
	return false

# Preserved functions for external compatibility
func setup(data: CharacterData):
	character_data = data
	if hp_label:
		hp_label.text = str(data.current_hp)
	if portrait:
		var texture = load(data.image_path)
		if texture:
			portrait.texture = texture
	set_meta("character_data", data)
	modulate.a = 1.0
	visible = true
	if rigid_body:
		rigid_body.freeze = true
		Logger.info("PHYSICS", "Set rigid body freeze=true (static) for card " + data.name, Logger.DetailLevel.LOW)

func get_character_name() -> String:
	return character_data.name if character_data else "Unknown Character"

func disable_card():
	is_disabled = true
	modulate = Color(0.7, 0.7, 0.7, 0.7)
	if rigid_body:
		rigid_body.input_pickable = false
	if hover_panel:
		hover_panel.visible = false
	is_targetable = false
	if target_panel:
		target_panel.visible = false
	set_process_input(false)
	set_current_state(CardState.IDLE)
	current_input_state = CardInputState.DISABLED
	is_dragging = false
	
	# Stop any active floating animation
	_stop_floating_animation()
	
func disable_input():
	if rigid_body:
		rigid_body.input_pickable = false
	current_input_state = CardInputState.DISABLED
	set_process_input(false)
	
	# Stop any active floating animation if input is disabled
	if is_targetable:
		_stop_floating_animation()
	
func enable_card():
	is_disabled = false
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if rigid_body:
		rigid_body.input_pickable = true
	set_process_input(true)
	set_current_state(CardState.IDLE)
	
	# Only set to SELECTABLE if not currently targetable
	if !is_targetable:
		current_input_state = CardInputState.SELECTABLE
	else:
		current_input_state = CardInputState.TARGETABLE
		# Restart floating animation if card is targetable
		_start_floating_animation()

func _on_mouse_exited() -> void:
	match current_input_state:
		CardInputState.DISABLED:
			return
		CardInputState.TARGETABLE:
			stop_pulsate_glow()
	hover_panel.visible = false
	is_hovered = false
	Logger.info("CARD_STATE", "Hover Exit: " + get_character_name(), Logger.DetailLevel.LOW)


func _on_mouse_entered() -> void:
	match current_input_state:
		CardInputState.DISABLED:
			return
		CardInputState.TARGETABLE:
			set_current_state(CardState.TARGETED)
		CardInputState.SELECTABLE:
			hover_panel.visible = true
	is_hovered = true
	SfxManager.play_sfx("hover")
	Logger.info("CARD_STATE", "Hover Enter: " + get_character_name(), Logger.DetailLevel.LOW)


# Add these new functions after the existing ones
func _find_nearest_card_slot(position):
	var nearest_slot = null
	var min_distance = 100.0  # Snap distance threshold
	
	# Get all card slots in the scene
	var slots = []
	if is_in_selection_scene():
		slots += get_tree().get_nodes_in_group("card_slots")
	elif is_in_battle_scene():
		slots += get_tree().get_nodes_in_group("active_slot")
		slots += get_tree().get_nodes_in_group("support_slot")

	for slot in slots:
		var distance = position.distance_to(slot.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_slot = slot
	
	return nearest_slot

func _is_within_snap_distance(position, slot):
	var snap_distance = 100.0  # Distance threshold for snapping
	return position.distance_to(slot.global_position) < snap_distance

# Modify _end_drag_operation to handle slot snapping
func _end_drag_operation():
	if current_state == CardState.DRAGGING:
		Logger.info("DRAG", "Ending drag operation for card: " + get_character_name(), Logger.DetailLevel.MEDIUM)
		
		# Determine drop location and handle accordingly
		var mouse_pos = get_viewport().get_mouse_position()
		var nearest_slot = _find_nearest_card_slot(mouse_pos)

		if nearest_slot and _is_within_snap_distance(mouse_pos, nearest_slot):
			Logger.info("SLOT", "Card dropped on slot", Logger.DetailLevel.MEDIUM)
			# Reset physics and disable collision so the card stays static in slot
			if rigid_body:
				rigid_body.freeze = true
				rigid_body.linear_velocity = Vector2.ZERO
				rigid_body.angular_velocity = 0
			if collision_shape:
				collision_shape.disabled = true
			Logger.info("PHYSICS", "Card physics reset after drop: " + get_character_name(), Logger.DetailLevel.LOW)
			# Reset z-index after drop
			z_index = DEFAULT_Z_INDEX
			# Handle switching or placement
			if nearest_slot.held_card != null:
				
				if self != nearest_slot.held_card:
					Logger.info("SLOT", "Switch positions requested between cards: " + self.get_character_name() + " and " + nearest_slot.held_card.get_character_name(), Logger.DetailLevel.MEDIUM)
					emit_signal("switch_requested", self, nearest_slot.held_card)
					#BattleStateManager.perform_switch(self, nearest_slot.held_card)
					#Logger.info("SLOT", "Switch positions approved: " + str(), Logger.DetailLevel.MEDIUM)
				else:
					_return_card_to_slot_position()
			else:
				if scene_type == SceneType.SELECTION:
					CharacterSelection.emit_signal("place_character_on_slot", self, nearest_slot)
				else:
					emit_signal("place_character_on_slot", self, nearest_slot)
					#_return_card_to_slot_position()

			# Snap to slot position and play sound
			#if rigid_body:
			#	rigid_body.global_position = nearest_slot.global_position
			#else:
			#	global_position = nearest_slot.global_position
			if scene_type == SceneType.SELECTION:
				SfxManager.play_random_sfx(["yo_1","yo_2"])
			else:
				SfxManager.play_sfx("slide")
		elif is_duplicate:
			# Cleanup preview: re-enable original and free duplicate
			SfxManager.play_sfx("pop")
			if original_card_reference:
				original_card_reference.enable_card()
			queue_free()
			return
		else:
			_return_card_to_slot_position()
		# After snapping or repositioning, reset physics
		if rigid_body:
			rigid_body.freeze = true
			rigid_body.linear_velocity = Vector2.ZERO
			rigid_body.angular_velocity = 0
			Logger.info("PHYSICS", "Returned rigid body freeze=true after drag: " + get_character_name(), Logger.DetailLevel.LOW)

		# Reset z-index and state
		
		z_index = DEFAULT_Z_INDEX
		is_dragging = false
		emit_signal("drag_ended", self, self)
		_apply_drag_visual_effects(false, self)
		print("FINISH DRAG")
		set_current_state(CardState.IDLE)

func is_support_character() -> bool:
	Logger.info("CARD_STATE", "Check if support character: " + get_character_name(), Logger.DetailLevel.LOW)
	if is_in_battle_scene():
		var battle_scene = get_tree().current_scene
		var battle_path = SceneManager.current_scene_path

		Logger.info("CARD_STATE", "Battle scene: " + str(battle_scene), Logger.DetailLevel.LOW)
		Logger.info("CARD_STATE", "Battle path: " + str(battle_path), Logger.DetailLevel.LOW)
		Logger.info("CARD_STATE", "Current Slot Path: " + str(current_slot.get_path()), Logger.DetailLevel.LOW)

		if current_slot in [
			battle_scene.player_slot_active,
			battle_scene.player2_slot_active
			]:
			return false
		elif current_slot in [
			battle_scene.player_slot_support1,
			battle_scene.player_slot_support2,
			battle_scene.player2_slot_support1,
			battle_scene.player2_slot_support2]:
				return true
	return false

func set_hover_detection(enabled: bool):
	# This method exists for compatibility with the existing codebase
	if rigid_body:
		rigid_body.input_pickable = enabled
	
	# If we're targetable, always keep hover detection on
	if is_targetable and current_input_state == CardInputState.TARGETABLE:
		if rigid_body:
			rigid_body.input_pickable = true
			
# Helper function to return a card to its original position
func _return_card_to_slot_position():
	if current_slot != null:
		Logger.info("CARD", "Returning " + character_data.name + " to original position")
		
		# Create tween for smooth movement
		var tween = create_tween()
		tween.tween_property(rigid_body, "global_position", current_slot.global_position, 0.3)
	else:
		Logger.warning("CARD", "Warning: No original slot found for " + character_data.name)
		
func update_hp():
	hp_label.text = str(character_data.current_hp)

# Add tween-based damage feedback functions
func tween_shake_card(duration: float = 0.2, magnitude: float = 10.0) -> void:
	var original_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(magnitude, 0), duration * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", original_pos - Vector2(magnitude, 0), duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", original_pos, duration * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func tween_pop_hp_label(duration: float = 0.2, scale_factor: Vector2 = Vector2(1.2, 1.2)) -> void:
	var original_scale = hp_label.scale
	var tween = create_tween()
	tween.tween_property(hp_label, "scale", scale_factor, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(hp_label, "scale", original_scale, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func tween_damage_popup(damage: int) -> void:
	# Create a floating red damage label above the HP label
	var dmg_label = Label.new()
	dmg_label.text = "-" + str(damage)
	dmg_label.modulate = Color(1, 0, 0, 1)
	dmg_label.scale = Vector2(1.7, 1.7)
	# Position it at the HP label's global position
	add_child(dmg_label)
	dmg_label.global_position = hp_label.global_position
	# Ensure it renders above the card
	dmg_label.z_index = z_index + 1
	# Tween upward and fade out over 1 second
	var tween = create_tween()
	var target_pos = hp_label.global_position + Vector2(0, -40)
	await tween.tween_property(dmg_label, "global_position", target_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.tween_property(dmg_label, "modulate:a", 0.0, 1.0)
	tween.connect("finished", Callable(dmg_label, "queue_free"))

# Helper function to kill all tweens on this card
func kill_all_tweens() -> void:
	get_tree().create_tween().kill()

# Add tween-based glow effect functions
func tween_pulsate_glow() -> void:
	if !target_panel:
		return
		
	# Make sure target panel is visible
	target_hover_panel.visible = true
	
	# Store original position if not already stored
	if original_position == Vector2.ZERO and rigid_body:
		original_position = rigid_body.position
	
	# Create and store the float tween
	float_tween = create_tween()
	float_tween.set_loops()  # Make it loop infinitely
	
	# Create floating motion - chain the tweeners
	float_tween.tween_property(rigid_body, "position:y", 
		original_position.y - float_height, 1.0).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(rigid_body, "position:y", 
		original_position.y, 1.0).set_ease(Tween.EASE_IN_OUT)
	
	# Create and store the glow tween
	glow_tween = create_tween()
	glow_tween.set_loops()  # Make it loop infinitely
	
	# Pulse the target panel's modulate - chain the tweeners
	glow_tween.tween_property(target_panel, "modulate", 
		Color(1.0, 0.7, 0.7, 0.9), 2.0).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_property(target_panel, "modulate", 
		Color(1.0, 0.7, 0.7, 0.7), 2.0).set_ease(Tween.EASE_IN_OUT)
	
	# Ensure input processing is enabled
	set_process_input(true)
	if rigid_body:
		rigid_body.input_pickable = true

func stop_pulsate_glow() -> void:
	# Kill specific tweens
	if float_tween:
		print("FOUDN FLOAT")
		float_tween.kill()
		float_tween = null
	if glow_tween:
		print("FOUDN GLOW")
		glow_tween.kill()
		glow_tween = null
	
	# Reset modulate color immediately
	if portrait:
		portrait.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	target_hover_panel.visible = false
	
	# Reset position if we have a stored original position
	rigid_body.position = original_position
	
	set_targetable(true)
