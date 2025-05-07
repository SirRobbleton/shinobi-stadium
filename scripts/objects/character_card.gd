extends Node2D
class_name CharacterCard

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
@onready var rigid_body = $RigidBody2D
@onready var collision_shape = $RigidBody2D/CollisionShape2D

# State management
enum CardState { IDLE, CLICKED, DRAGGING }
enum CardInputState { DISABLED, TARGETABLE, SELECTABLE }
enum SceneType { SELECTION, BATTLE }

var current_state: CardState = CardState.IDLE
var current_input_state: CardInputState = CardInputState.SELECTABLE
var scene_type: SceneType
var click_timer: Timer
var last_click_time: float = 0
var double_click_threshold: float = 0.3
var long_press_threshold: float = 0.3

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

func _ready():
	# Initialize scene type
	scene_type = SceneType.SELECTION if is_in_selection_scene() else SceneType.BATTLE

	# Setup click timer
	click_timer = Timer.new()
	click_timer.one_shot = true
	click_timer.timeout.connect(_on_click_timer_timeout)
	add_child(click_timer)
	
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

func _input(event):
	if is_disabled or _is_blocked_by_battle_overlay():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_hovered:
				_handle_mouse_press()
		else:
			_handle_mouse_release()
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_mouse_press():
	#if scene_type == SceneType.SELECTION:
	match current_state:
		CardState.IDLE:
			if Time.get_ticks_msec() - last_click_time < double_click_threshold * 1000:
				_handle_double_click()
			else:
				current_state = CardState.CLICKED
				click_timer.start(long_press_threshold)
				last_click_time = Time.get_ticks_msec()
		CardState.CLICKED:
			_handle_double_click()

func _handle_mouse_release():
	if current_state == CardState.CLICKED and click_timer.time_left > 0:
		_handle_short_click()
	elif current_state == CardState.DRAGGING:
		print("[DRAG DEBUG] Mouse released while dragging | Card: " + get_character_name() + 
			  " | Is Preview: " + str(is_preview))
		
		# Check if we're over a card slot
		var mouse_pos = get_viewport().get_mouse_position()
		var nearest_slot = _find_nearest_card_slot(mouse_pos)
		
		if nearest_slot and _is_within_snap_distance(mouse_pos, nearest_slot):
			print("[DRAG DEBUG] Card dropped on slot")
			if nearest_slot.held_card != null:
				print("SWITCH POSITIONS   !!!!")
				if self != nearest_slot.held_card:
					emit_signal("switch_requested", self, nearest_slot.held_card)
			else:				
				if scene_type == SceneType.SELECTION:
					CharacterSelection.emit_signal("place_character_on_slot", self, nearest_slot)
				else:
					emit_signal("place_character_on_slot", self, nearest_slot)


			# Snap to slot position
			if rigid_body:
				rigid_body.global_position = nearest_slot.global_position
			else:
				global_position = nearest_slot.global_position
			
			# Update current slot reference
			#current_slot = nearest_slot
			if scene_type == SceneType.SELECTION:
				SfxManager.play_random_sfx(["yo_1","yo_2"])
			else:
				SfxManager.play_sfx("slide")
			# Notify slot that card was dropped (pass both slot and card)
			# nearest_slot.emit_signal("card_dropped", nearest_slot, self)
		elif is_duplicate:
			SfxManager.play_sfx("pop")
			original_card_reference.enable_card()
			queue_free()
			return
		else:
			if rigid_body:
				rigid_body.global_position = current_slot.global_position
			else:
				global_position = current_slot.global_position
		
		current_state = CardState.IDLE
		is_dragging = false
		if is_preview:
			print("[DRAG DEBUG] Preview card drag ended")
		else:
			print("[DRAG DEBUG] Original card drag ended")
		
		#emit_signal("drag_ended", self)
		_apply_drag_visual_effects(false, self)
	
	click_timer.stop()
	current_state = CardState.IDLE

func _handle_mouse_motion(event):
	if current_state == CardState.DRAGGING:
		_update_drag_position(event.position)

func _on_click_timer_timeout():
	if current_state == CardState.CLICKED:
		_handle_long_click()

func _handle_short_click():
	match scene_type:
		SceneType.SELECTION:
			ZoomManager.show_card(character_data)
		SceneType.BATTLE:
			GamestateManager.show_battle_overlay(self)

func _handle_long_click():
	current_state = CardState.DRAGGING
	match scene_type:
		SceneType.SELECTION:
			if !is_preview:
				current_state = CardState.IDLE
				_start_drag_operation(self)
			else:
				_start_drag_operation(self)
		SceneType.BATTLE:
			_start_drag_operation(self)

func _handle_double_click():
	if scene_type == SceneType.BATTLE:
		ZoomManager.show_card(character_data)

func _start_drag_operation(card: CharacterCard):
	print("[DRAG DEBUG] Starting drag operation | Card: " + card.get_character_name() + 
		  " | Is Preview: " + str(card.is_preview) + 
		  " | Scene: " + ("Selection" if scene_type == SceneType.SELECTION else "Battle"))
	
	SfxManager.play_sfx("drag")
	if scene_type == SceneType.SELECTION and !card.is_preview:
		# Get position based on scene type first
		var mouse_pos = get_tree().current_scene.get_global_mouse_position()		
		print("[DRAG DEBUG] Target position for drag: " + str(mouse_pos))
		
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
		
		print("[DRAG DEBUG] Created preview card for " + card.get_character_name() + " | Position: " + str(mouse_pos))
		
		# Disable original card
		card.disable_card()
		print("[DRAG DEBUG] Disabled original card: " + card.get_character_name())
		
		# Start dragging preview
		preview.is_dragging = true
		preview.current_state = CardState.DRAGGING
		emit_signal("drag_started", preview)
		_apply_drag_visual_effects(true, preview)
		print("[DRAG DEBUG] Started dragging preview card")
		
	else:
		# For battle scene or preview cards
		card.is_dragging = true
		card.current_state = CardState.DRAGGING
		emit_signal("drag_started", card)
		_apply_drag_visual_effects(true, card)
		print("[DRAG DEBUG] Started dragging card directly")

func _setup_preview_card(preview: CharacterCard):
	print("[DRAG DEBUG] Setting up preview card | Original: " + 
		  (original_card_reference.get_character_name() if original_card_reference else "None"))
	
	# Initialize node references
	preview.portrait = preview.get_node("RigidBody2D/CharacterVisuals/Portrait")
	preview.hp_label = preview.get_node("RigidBody2D/CharacterVisuals/Portrait/HPColor/HPLabel")
	preview.hover_panel = preview.get_node("RigidBody2D/CharacterVisuals/Portrait/BacklightPanel")
	preview.target_panel = preview.get_node("RigidBody2D/CharacterVisuals/Portrait/TargetPanel")
	preview.rigid_body = preview.get_node("RigidBody2D")
	preview.collision_shape = preview.get_node("RigidBody2D/CollisionShape2D")
	
	# Initialize state
	preview.current_state = CardState.DRAGGING
	preview.is_dragging = true
	preview.scene_type = scene_type
	
	# Setup card with original card's data
	if is_preview:
		preview.setup(original_card_reference.character_data)
		print("[DRAG DEBUG] Setup preview with original card's data")
	else:
		preview.setup(character_data)
		print("[DRAG DEBUG] Setup preview with current card's data")

func _update_drag_position(position):
	if current_state == CardState.DRAGGING:
		# Get position based on scene type
		var target_pos
		if scene_type == SceneType.SELECTION:
			# In selection scene, use viewport coordinates
			target_pos = get_viewport().get_mouse_position()
			
			# Check for nearby card slots
			var nearest_slot = _find_nearest_card_slot(target_pos)
			if nearest_slot and _is_within_snap_distance(target_pos, nearest_slot):
				#target_pos = nearest_slot.global_position
				print("[DRAG DEBUG] Highlighting slot : " + str(nearest_slot))
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
			print("[DRAG DEBUG] Updated rigid body position: " + str(target_pos) + 
				  " | Card: " + get_character_name() + 
				  " | Is Preview: " + str(is_preview) +
				  " | Is Duplicate: " + str(is_duplicate) +
				  " | Scene: " + ("Selection" if scene_type == SceneType.SELECTION else "Battle"))
		else:
			# If no rigid body, update the card position directly
			global_position = target_pos
			print("[DRAG DEBUG] Updated card position: " + str(target_pos) + 
				  " | Card: " + get_character_name() + 
				  " | Is Preview: " + str(is_preview) +
				  " | Is Duplicate: " + str(is_duplicate) +
				  " | Scene: " + ("Selection" if scene_type == SceneType.SELECTION else "Battle"))

func _apply_drag_visual_effects(is_dragging: bool, card: CharacterCard):
	if is_dragging:
		if card.rigid_body:
			card.rigid_body.scale = Vector2(1.1, 1.1)
		else:
			card.scale = Vector2(1.1, 1.1)
		card.z_index = 1
		if card.hover_panel:
			card.hover_panel.visible = false
	else:
		if card.rigid_body:
			card.rigid_body.scale = Vector2(1.0, 1.0)
		else:
			card.scale = Vector2(1.0, 1.0)
		card.z_index = 0
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
	current_state = CardState.IDLE
	current_input_state = CardInputState.DISABLED
	is_dragging = false
	

func enable_card():
	is_disabled = false
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if rigid_body:
		rigid_body.input_pickable = true
	set_process_input(true)
	current_state = CardState.IDLE
	current_input_state = CardInputState.SELECTABLE


func _on_mouse_exited() -> void:
	if current_input_state == CardInputState.DISABLED:
		return
	hover_panel.visible = false
	is_hovered = false	

func _on_mouse_entered() -> void:
	if current_input_state == CardInputState.DISABLED:
		return
	hover_panel.visible = true
	is_hovered = true
	SfxManager.play_sfx("hover")


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
		print("[DRAG DEBUG] Ending drag operation for card: " + get_character_name())
		
		# Check if we're over a card slot
		var mouse_pos = get_viewport().get_mouse_position()
		var nearest_slot = _find_nearest_card_slot(mouse_pos)
		
		if nearest_slot and _is_within_snap_distance(mouse_pos, nearest_slot):
			print("[DRAG DEBUG] Card dropped on slot")
			# Snap to slot position
			if rigid_body:
				rigid_body.global_position = nearest_slot.global_position
			else:
				global_position = nearest_slot.global_position
			
			# Notify slot that card was dropped
			nearest_slot.emit_signal("card_dropped", nearest_slot, self)
		elif is_duplicate:
			queue_free()
			return
		else:
			print("REPOSITIONING")
			if rigid_body:
				rigid_body.global_position = current_slot.global_position
			else:
				global_position = current_slot.global_position
			return
		
	# Reset drag state
	is_dragging = false
	current_state = CardState.IDLE
	emit_signal("drag_ended", self)
	_apply_drag_visual_effects(false, self)

func is_support_character() -> bool:
	if is_in_battle_scene():
		var battle_scene = get_tree().current_scene
		var battle_path = SceneManager.current_scene_path

		print(str(battle_scene))
		print(str(battle_path))

		if current_slot == battle_scene.player_slot_active:
			return false
		elif current_slot == battle_scene.player_slot_support1 or current_slot == battle_scene.player_slot_support2:
				return true
	return false
