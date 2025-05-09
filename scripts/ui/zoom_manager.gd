# zoom_manager.gd
extends Node

# Scene reference
var zoom_overlay_scene = preload("res://scenes/ui/zoom_overlay.tscn")
var zoom_overlay_instance = null

# Show a card in the zoom overlay
func show_card(character_data):
	print("[ZOOM_MANAGER] Attempting to show card: " + str(character_data))
		
	# Create or get the zoom overlay instance
	if zoom_overlay_instance == null:
		print("[ZOOM_MANAGER] Creating new zoom overlay instance")
		zoom_overlay_instance = zoom_overlay_scene.instantiate()
		# Add to the current scene
		var current_scene = get_tree().current_scene
		print("[ZOOM_MANAGER] Current scene: " + str(current_scene))
		current_scene.add_child(zoom_overlay_instance)
		# Wait for the next frame to ensure the instance is ready
		await get_tree().process_frame
		
		# Ensure the instance is valid before proceeding
		if zoom_overlay_instance == null:
			push_error("[ZOOM_MANAGER] Failed to create zoom overlay instance")
			return
		print("[ZOOM_MANAGER] Successfully created zoom overlay instance")
	
	# Show the card in the overlay
	if zoom_overlay_instance.has_method("show_card"):
		print("[ZOOM_MANAGER] Calling show_card on overlay instance")
		zoom_overlay_instance.show_card(character_data)
		zoom_overlay_instance.z_index = 100

	else:
		push_error("[ZOOM_MANAGER] Zoom overlay instance does not have show_card method")

# Hide the zoom overlay
func hide_overlay():
	print("[ZOOM_MANAGER] Attempting to hide overlay")
	if zoom_overlay_instance != null:
		if zoom_overlay_instance.has_method("hide_overlay"):
			print("[ZOOM_MANAGER] Calling hide_overlay on instance")
			zoom_overlay_instance.hide_overlay()
		else:
			print("[ZOOM_MANAGER] Instance does not have hide_overlay method")
		# Remove from scene
		print("[ZOOM_MANAGER] Queueing instance for removal")
		zoom_overlay_instance.queue_free()
		zoom_overlay_instance = null
	else:
		print("[ZOOM_MANAGER] No overlay instance to hide") 
