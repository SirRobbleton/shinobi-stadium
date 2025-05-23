# zoom_overlay.gd
extends Control

# Node references
@onready var zoom_container := $ZoomCardContainer

# Reference to the currently zoomed card
var zoomed_card

func _ready():
	# Wait for the next frame to ensure the node is fully initialized
	await get_tree().process_frame
	
	# Now it's safe to set properties
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	
	# Connect input handler
	connect("gui_input", Callable(self, "_on_zoom_overlay_input"))

# Handle clicks outside the zoomed card
func _on_zoom_overlay_input(event):
	if event is InputEventMouseButton and event.pressed:
		# Get the mouse position in screen coordinates
		var mouse_pos = get_viewport().get_mouse_position()
		Logger.info("UI", "Mouse position: " + str(mouse_pos))
		
		# Check if the click is outside the zoomed card
		if zoomed_card and zoomed_card is Node2D:
			# Get the card's position in screen coordinates
			var card_screen_pos = zoomed_card.get_viewport_transform() * zoomed_card.global_position
			Logger.info("OVERLAY", "Card screen position: " + str(card_screen_pos), Logger.DetailLevel.LOW)
			
			# Create a rectangle around the card (accounting for scale)
			var card_rect = Rect2(
				card_screen_pos - Vector2(85, 125) * zoomed_card.scale,
				Vector2(170, 250) * zoomed_card.scale
			)
			Logger.info("OVERLAY", "Card rect: " + str(card_rect), Logger.DetailLevel.LOW)
			
			if !card_rect.has_point(mouse_pos):
				Logger.info("OVERLAY", "Click outside card detected, hiding overlay")
				hide_overlay()

# Show a card in the zoom overlay
func show_card(character_data):
	Logger.info("UI", "Showing card for character: " + str(character_data.name))
	
	# Clear existing cards
	for child in zoom_container.get_children():
		child.queue_free()

	# Create zoom card (using the same scene as grid cards)
	zoomed_card = load("res://scenes/objects/character_card.tscn").instantiate()
	zoom_container.add_child(zoomed_card)
	Logger.info("OVERLAY", "Created and added zoom card instance")
	
	# Setup card data if it has the setup method
	if zoomed_card.has_method("setup"):
		Logger.info("OVERLAY", "Setting up card with character data")
		zoomed_card.setup(character_data)
	else:
		Logger.warning("OVERLAY", "Zoom card does not have setup method")

	# For Node2D cards, position at center of container
	if zoomed_card is Node2D:
		# Get the viewport size
		var viewport_size = get_viewport_rect().size
		
		# Calculate center position in world coordinates
		var center_pos = Vector2(viewport_size.x / 2, viewport_size.y / 2)
		
		# Set the card's global position to the center of the screen
		zoomed_card.global_position = center_pos
		Logger.info("OVERLAY", "Positioned card at center: " + str(center_pos), Logger.DetailLevel.LOW)
		
		# Scale to a larger size (3.5x)
		zoomed_card.scale = Vector2(3.5, 3.5)
		zoomed_card.z_index = 100
		zoomed_card.disable_input()
		# If card has RigidBody2D functionality, freeze it
		if zoomed_card.has_method("set_freeze"):
			zoomed_card.set_freeze(true)
		# Check for RigidBody2D child
		elif zoomed_card.has_node("RigidBody2D") and zoomed_card.get_node("RigidBody2D") is RigidBody2D:
			zoomed_card.get_node("RigidBody2D").freeze = true

	# Make the overlay visible
	visible = true
	Logger.info("UI", "Zoom overlay now visible")

# Close the zoom overlay
func hide_overlay():
	Logger.info("UI", "Hiding zoom overlay")
	visible = false
	for child in zoom_container.get_children():
		child.queue_free()
	zoomed_card = null
	accept_event()
