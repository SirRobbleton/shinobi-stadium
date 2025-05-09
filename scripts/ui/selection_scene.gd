# selection_scene.gd
extends Control

# Node references for easier access
@onready var zoom_overlay := $ZoomOverlay
@onready var zoom_container := $ZoomOverlay/ZoomCardContainer
@onready var continue_button = $ContinueButton
@onready var support_pos_1 = $VBoxContainer/CardSlotContainer/HBoxContainer/SupportPosition1/CardSlot
@onready var active_pos = $VBoxContainer/CardSlotContainer/HBoxContainer/ActivePosition/CardSlot
@onready var support_pos_2 = $VBoxContainer/CardSlotContainer/HBoxContainer/SupportPosition2/CardSlot
@onready var character_grid = $VBoxContainer/MarginContainer/ScrollContainer/CenterContainer/CharacterGrid

# Scene references
@export var character_card_scene: PackedScene  # Use res://scenes/objects/character_card.tscn here

# Reference to the currently zoomed card
var zoomed_card

# Track selected cards
var selected_characters = []
const MAX_SELECTED_CARDS = 3
var current_character: CharacterCard

# Grid layout properties - simplified with bigger margins for better visibility
var card_width = 170
var card_height = 250
var h_spacing = 20
var v_spacing = 20
var columns = 3  # Using 3 columns for mobile layout

# Track if any card is currently being dragged
var card_being_dragged = null

func _ready():
	# Check if we should skip this scene
	if SceneManager.skip_selection:
		Logger.info("SELECTION", "Skipping selection scene as requested by SceneManager")
		CharacterSelection.generate_random_characters()
		await get_tree().process_frame
		SceneManager.change_scene("res://scenes/battle/battle_scene.tscn")
		return
	
	CharacterSelection.connect("place_character_on_slot", place_character_on_slot)
	
	# Otherwise, proceed with normal setup
	Logger.info("SELECTION", "Scene loading normally")
	
	# Initialize node references
	initialize_nodes()
	
	# Set up character selection grid
	setup_character_selection()
	
	# Hide zoom overlay initially
	zoom_overlay.visible = false
	
	# Disable continue button until all slots filled
	continue_button.disabled = true
	
	# Connect button
	continue_button.connect("pressed", Callable(self, "_on_continue_pressed"))
	
	# Connect zoom overlay signals
	zoom_overlay.connect("gui_input", Callable(self, "_on_zoom_overlay_input"))

# Configure all UI containers for proper layout
func configure_ui_containers():
	# (Viewport-based configuration is no longer needed)
	pass

# Populate the character grid with Node2D cards
func populate_character_grid():
	# Ensure wrapper scene pointer
	if not character_card_scene:
		Logger.error("SELECTION", "CharacterCardCell scene is not assigned!")
		return

	# Get database instance
	var character_db = load("res://scripts/data/character_database.gd").get_instance()
	if not character_db:
		Logger.error("SELECTION", "CharacterDatabase not found!")
		return

	# Clear any existing cells
	for child in character_grid.get_children():
		child.queue_free()

	# Instantiate a cell for each character
	for character_data in character_db.get_all_characters():
		var cell = character_card_scene.instantiate()
		# Add the wrapper to the tree before setup so @onready vars (vp) are valid
		character_grid.add_child(cell)
		if cell.has_method("setup"):
			cell.setup(character_data)
		# Connect wrapper signals to scene handlers
		if cell.has_signal("card_clicked"):
			cell.connect("card_clicked", Callable(self, "_on_card_clicked"))
		if cell.has_signal("zoom_requested"):
			cell.connect("zoom_requested", Callable(self, "_on_card_zoom_requested"))
		if cell.has_signal("drag_started"):
			cell.connect("drag_started", Callable(self, "_on_card_drag_started"))
		if cell.has_signal("drag_ended"):
			cell.connect("drag_ended", Callable(self, "_on_card_drag_ended"))

# Check slot status every frame to update button
func _process(_delta):
	#if CharacterSelection.current_character and !current_character.is_connected("place_character_on_slot", place_character_on_slot):
	#	current_character.connect("place_character_on_slot", place_character_on_slot)
	#	Logger.info("SELECTION", "Card selected: " + current_character.character_data.name)
	#else:
	pass

# Called when a card in the list is clicked for zoom preview
func _on_card_zoom_requested(character_data):
	# Clear existing cards
	for child in zoom_container.get_children():
			child.queue_free()

	# Create zoom card (using the same scene as grid cards)
	zoomed_card = character_card_scene.instantiate()
	zoom_container.add_child(zoomed_card)
	
	# Setup card data if it has the setup method
	if zoomed_card.has_method("setup"):
		zoomed_card.setup(character_data)

	# For Node2D cards, position at center of container
	if zoomed_card is Node2D:
		zoomed_card.position = Vector2.ZERO
		zoomed_card.scale = Vector2(4.0, 4.0)
		
		# If card has RigidBody2D functionality, freeze it
		if zoomed_card.has_method("set_freeze"):
			zoomed_card.set_freeze(true)
		# Check for RigidBody2D child
		elif zoomed_card.has_node("RigidBody2D") and zoomed_card.get_node("RigidBody2D") is RigidBody2D:
			zoomed_card.get_node("RigidBody2D").freeze = true

	zoom_overlay.visible = true

# Handle clicks outside the zoomed card
func _on_zoom_overlay_input(event):
	if event is InputEventMouseButton and event.pressed:
		hide_zoom_overlay()

# Close the zoom overlay
func hide_zoom_overlay():
	zoom_overlay.visible = false
	for child in zoom_overlay.get_node("ZoomCardContainer").get_children():
		child.queue_free()
	zoomed_card = null

# Card selected/deselected events
func _on_card_selected(character_data, _source_card):
	Logger.info("SELECTION", "Card selected: " + character_data.name)
	
func _on_card_deselected(character_data, _source_card):
	Logger.info("SELECTION", "Card deselected: " + character_data.name)

# Start the battle when all slots are filled and button is pressed
func _on_continue_pressed():
	Logger.info("SELECTION", "Continue pressed with selected characters: " + str(selected_characters))
	
	# Get the character database instance
	var character_db = load("res://scripts/data/character_database.gd").get_instance()
	if not character_db:
		Logger.error("SELECTION", "CharacterDatabase not found!")
		return
	
	# Get character data from the selected cards
	var selected_character_data = []
	for card in selected_characters:
		if "character_data" in card and card.character_data:
			selected_character_data.append(card.character_data)
			Logger.info("SELECTION", "Adding character: " + card.character_data.name)
	
	if selected_character_data.size() >= 3:
		# Update global state with player's selected characters
		CharacterSelection.active_shinobi = active_pos.held_card.character_data
		CharacterSelection.support_shinobi_1 = support_pos_1.held_card.character_data
		CharacterSelection.support_shinobi_2 = support_pos_2.held_card.character_data
		Logger.info("SELECTION", "Player characters set: " + str(CharacterSelection.active_shinobi))
		Logger.info("SELECTION", "Player characters set: " + str(CharacterSelection.support_shinobi_1))
		Logger.info("SELECTION", "Player characters set: " + str(CharacterSelection.support_shinobi_2))
		
		# Generate opponent characters (avoid selecting the same as player)
		var all_characters = character_db.get_all_characters()
		var available_characters = all_characters.duplicate()
		
		# Remove player's selected characters from available pool
		for char_data in selected_character_data:
			for i in range(available_characters.size() - 1, -1, -1):
				if available_characters[i].name == char_data.name:
					available_characters.remove_at(i)
					break
		
		CharacterSelection.opponent_shinobi = []
		for i in range(3):
			if available_characters.size() > 0:
				var random_index = randi() % available_characters.size()
				CharacterSelection.opponent_shinobi.append(available_characters[random_index])
				available_characters.remove_at(random_index)
			else:
				# If we run out of unique characters, just pick any
				var random_index = randi() % all_characters.size()
				CharacterSelection.opponent_shinobi.append(all_characters[random_index])
		
		Logger.info("SELECTION", "Battle starting with player characters: " + str([CharacterSelection.active_shinobi,CharacterSelection.support_shinobi_1, CharacterSelection.support_shinobi_2]) + 
			" and opponent characters: " + str(CharacterSelection.opponent_shinobi))
		
		SfxManager.play_sfx("yo")
		
		# Change to battle scene
		SceneManager.change_scene("res://scenes/battle/battle_scene.tscn")
	else:
		Logger.info("SELECTION", "Not enough characters selected: " + str(selected_character_data.size()) + "/" + str(MAX_SELECTED_CARDS))

# Handle card clicked signal
func _on_card_clicked(card):
	Logger.info("SELECTION", "Card clicked: " + card.get_character_name())
	
	# Logic for card selection has been simplified
	# Cards are now selected by dragging to slots instead
	# This function can be used for additional effects on click
	
	# Request zoom when clicked
	if "character_data" in card:
		_on_card_zoom_requested(card.character_data)

# Connect slot signals
func _connect_slot_signals():
	for slot in [active_pos, support_pos_1, support_pos_2]:
		if slot.has_signal("card_dropped"):
			slot.card_dropped.connect(_on_card_dropped_on_slot)
			slot.card_placed.connect(_debug_card_placed)
			slot.card_removed.connect(_debug_card_removed)
		else:
			Logger.error("SELECTION", "Slot does not have card_dropped signal!")
			Logger.error("SELECTION", "Slot missing card_dropped signal: " + slot.name)

# Handle card dropped on a slot
func _on_card_dropped_on_slot(slot, card):
	if card == null or not "character_data" in card:
		return

	# Check for an occupied slot and a previous slot to swap with
	var existing = slot.get_card()
	var old_slot = card.get_meta("current_slot") if card.has_meta("current_slot") else null
	if existing and existing != card and old_slot:
		# Animate the two cards swapping positions
		var tween = create_tween().set_parallel(true)
		tween.tween_property(card,     "global_position", slot.global_position,0.3).set_ease(Tween.EASE_OUT)
		tween.tween_property(existing, "global_position", old_slot.global_position,0.3).set_ease(Tween.EASE_OUT)
		await tween.finished
		# Clear and reassign cards
		slot.clear_card()
		old_slot.clear_card()
		slot.set_card(card)
		old_slot.set_card(existing)
		card.set_meta("current_slot", slot)
		existing.set_meta("current_slot", old_slot)
	elif existing and existing != card:
		# Dragged from list onto occupied slot: remove existing card
		slot.clear_card()
	else:
		# Normal drop into empty slot
	#	slot.set_card(card)
		card.set_meta("current_slot", slot)

	_update_selected_characters()

# Update the selected characters array based on slots
func _update_selected_characters():
	selected_characters.clear()
	
	Logger.info("SELECTION", "Updating selected characters")
	
	for slot in [active_pos, support_pos_1, support_pos_2]:
		var card = slot.get_card()
		if card != null:
			if card.is_in_group("cards") and "character_data" in card:
				Logger.info("SELECTION", "Adding to selection: " + card.get_character_name())
				selected_characters.append(card)
			else:
				if "character_data" not in card:
					Logger.info("SELECTION", "Card missing character_data: " + str(card))
				else:
					Logger.info("SELECTION", "Card not in 'cards' group: " + str(card))
		else:
			Logger.info("SELECTION", "Slot has no card")
	
	# Log the selection status
	Logger.info("SELECTION", "Current selection: " + str(selected_characters.size()) + "/" + str(MAX_SELECTED_CARDS))
	
	# Update the continue button
	continue_button.disabled = selected_characters.size() < MAX_SELECTED_CARDS

# Initialize all node references
func initialize_nodes():
	Logger.info("SELECTION", "Initializing nodes")
	
	# Verify expected nodes
	var nodes_to_check = [
		["zoom_overlay", zoom_overlay],
		["zoom_container", zoom_container],
		["continue_button", continue_button],
		["character_grid", character_grid]
	]
	
	for node_check in nodes_to_check:
		var node_name = node_check[0]
		var node = node_check[1]
		if node == null:
			Logger.error("SELECTION", "MISSING NODE: " + node_name + " is null!")
			Logger.error("SELECTION", node_name + " is null!")
		else:
			Logger.info("SELECTION", "Found " + node_name + ": " + str(node.get_class()))
	
	# Check scene assignment
	if character_card_scene == null:
		Logger.error("SELECTION", "ERROR: character_card_scene is not assigned in the inspector!")
		Logger.error("SELECTION", "character_card_scene is not assigned!")
	else:
		Logger.info("SELECTION", "character_card_scene assigned: " + str(character_card_scene.resource_path))

# Called when a card starts being dragged
func _on_card_drag_started(card):
	#Logger.info("SELECTION", "Drag started for card: " + card.get_character_name() + "]")
	card_being_dragged = card
	
	# Get all cards in the grid
	var all_cards = get_tree().get_nodes_in_group("character")

	#var all_cards = character_grid.get_children()
	#Logger.info("SELECTION", "Found " + str(all_cards.size()) + " cards in grid]")
	
	# Disable all cards except the one being dragged
	if !card.is_preview:
		for other_card in all_cards:
			if card != other_card:
				other_card.disable_card()
				#other_card.set_hover_detection(false)

	Logger.info("SELECTION", "Card drag started, disabled input and hover on other cards")

# Called when a card stops being dragged
func _on_card_drag_ended(card):
	Logger.info("SELECTION", "Drag ended for card: " + card.get_character_name())
	# Only proceed if this is the card we're tracking
	if card_being_dragged != card:
		Logger.info("SELECTION", "Ignoring drag end for non-tracked card")
		return
		
	card_being_dragged = null
	
	# Get all cards in the grid
	var all_cards = character_grid.get_children()
	Logger.info("SELECTION", "Found " + str(all_cards.size()) + " cards in grid")
	
	# Re-enable all cards
	for other_card in all_cards:
		if other_card.has_method("enable_input"):
			other_card.enable_input()
		if other_card.has_method("set_hover_detection"):
			other_card.set_hover_detection(true)
		
		other_card.enable_card()
		
	Logger.info("SELECTION", "Card drag ended, re-enabled input and hover on all cards")
	
func place_character_on_slot(card: CharacterCard, slot: CardSlot):
	Logger.info("SELECTION", "Placing " + card.character_data.name + " on slot " + str(slot))

	# Create a new card instance
	
	# Add to the Control parent of the slot for proper positioning
	#card.get_parent().remove_child(card)
	#slot.get_parent().add_child(card)
	#slot.add_child(card)

	await get_tree().process_frame

	# Set up the card data
	#card.setup(card.character_data)
	card.current_slot = slot
	slot.set_card(card)

# Add this function to set up the character selection grid
func setup_character_selection():
	_connect_slot_signals()
	populate_character_grid()

func _debug_card_placed(slot, card):
	Logger.info("SELECTION", "[DEBUG][SLOT] card_placed on slot '%s' with card '%s'" % [slot.name, card.name])

func _debug_card_removed(slot):
	Logger.info("SELECTION", "[DEBUG][SLOT] card_removed on slot '%s'" % slot.name)
