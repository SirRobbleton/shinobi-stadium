# scene_manager.gd
extends Node

signal scene_changing(from_scene, to_scene)
signal scene_changed(current_scene)

# Scene skipping flags
var skip_selection: bool = true  # Set to true to skip selection scene

# Active scene tracking
var current_scene_path: String = ""
var current_scene_node: Node = null
var initialized: bool = false

# Dedicated battle scene reference
var _battle_scene: BattleScene = null

# Scene configuration - easily expandable
var scene_config = {
	"res://scenes/main.tscn": {
		"music": "intro",
		"transition": "fade"
	},
	"res://scenes/selection/selection_scene.tscn": {
		"music": "selection",
		"transition": "fade"
	},
	"res://scenes/battle/battle_scene.tscn": {
		"music": "battle",
		"transition": "fade"
	}
}

func _ready():
	# Wait until the tree is ready
	call_deferred("_initialize")

func _initialize():
	# Prevent double initialization
	if initialized:
		return
		
	# Get the current scene when the game starts
	await get_tree().process_frame
	
	current_scene_node = get_tree().current_scene
	
	Logger.info("SCENE", "CURRENT SCENE NODE 1: " + str(current_scene_node))
	if current_scene_node:
		# Get the scene path, handling both direct path and packed scene
		if current_scene_node.scene_file_path:
			current_scene_path = current_scene_node.scene_file_path
		elif current_scene_node.get_parent() and current_scene_node.get_parent().scene_file_path:
			current_scene_path = current_scene_node.get_parent().scene_file_path
		else:
			# Try to determine scene type from content
			if current_scene_node.has_node("BattleLayout"):
				current_scene_path = "res://scenes/battle/battle_scene.tscn"
			elif current_scene_node.has_node("SelectionLayout"):
				current_scene_path = "res://scenes/selection/selection_scene.tscn"
			else:
				current_scene_path = "res://scenes/main.tscn"
				
		Logger.info("SCENE", "Initial scene is " + current_scene_path)
		
		# Only apply scene config if we haven't changed scenes already
		if not initialized:
			# Play appropriate music for the initial scene
			_apply_scene_config(current_scene_path)
			initialized = true
			
			# Check if we should skip selection in the main scene
			if skip_selection and current_scene_path == "res://scenes/main.tscn":
				# Don't wait for the intro scene to decide to skip to selection
				# Instead go directly to battle scene
				await get_tree().process_frame
				Logger.info("SCENE", "Skipping both intro and selection scenes")
				_skip_to_battle_scene()
			# If we're in the selection scene and should skip it
			elif skip_selection and current_scene_path == "res://scenes/selection/selection_scene.tscn":
				await get_tree().process_frame
				Logger.info("SCENE", "Skipping selection scene")
				_skip_to_battle_scene()
	else:
		# Don't throw an error, just log it
		Logger.warning("SCENE", "Could not get initial scene, will initialize later")
		# Wait for next frame and try again
		await get_tree().process_frame
		_initialize()

# Function to skip straight to battle scene with random characters
func _skip_to_battle_scene():
	# Generate random characters
	CharacterSelection.generate_random_characters()
	
	# Change to battle scene
	change_scene("res://scenes/battle/battle_scene.tscn")
	Logger.info("SCENE", "CURRENT SCENE NODE 2: " + str(current_scene_node))


# Change to a new scene with automatic music handling
func change_scene(new_scene_path: String):
	Logger.info("SCENE", "Changing scene to " + new_scene_path)
	
	# If called before initialization, mark as initialized
	if not initialized:
		initialized = true
	
	# If this is the selection scene and we should skip it
	if new_scene_path == "res://scenes/selection/selection_scene.tscn" and skip_selection:
		Logger.info("SCENE", "Skipping selection scene, going straight to battle")
		new_scene_path = "res://scenes/battle/battle_scene.tscn"

		# Generate random characters
		CharacterSelection.generate_random_characters()
	
	# Signal that we're changing scenes
	emit_signal("scene_changing", current_scene_path, new_scene_path)
	
	# Actually change the scene
	var error = get_tree().change_scene_to_file(new_scene_path)
	if error != OK:
		Logger.error("SCENE", "Failed to change scene: " + str(error))
		return
	
	# Wait for the scene to be ready
	await get_tree().process_frame
	
	# Get the new scene
	var new_scene = get_tree().current_scene
	if new_scene == null:
		Logger.error("SCENE", "Failed to get new scene after change")
		return
	
	# If it's a battle scene, store it separately and wait for full initialization
	if new_scene_path == "res://scenes/battle/battle_scene.tscn":
		if not new_scene is BattleScene:
			Logger.error("SCENE", "Loaded scene is not a BattleScene")
			return
			
		# Wait for the scene to be fully ready
		await new_scene.ready
		
		# Additional wait to ensure all children are ready
		await get_tree().process_frame
		
		# Store the battle scene reference
		_battle_scene = new_scene
		
		# Verify the battle scene is properly initialized
		if _battle_scene == null:
			Logger.error("SCENE", "Failed to store battle scene reference")
			return
			
		Logger.info("SCENE", "Battle scene initialized successfully")
	else:
		_battle_scene = null
	
	# Update current scene tracking
	current_scene_path = new_scene_path
	current_scene_node = new_scene
	
	Logger.info("SCENE", "Scene loaded: " + str(current_scene_node) + " is BattleScene: " + str(is_in_battle_scene()))
	
	# Apply the appropriate music and other scene-specific settings
	_apply_scene_config(new_scene_path)
	
	# Signal that scene has changed
	emit_signal("scene_changed", new_scene_path)

# Apply the configuration for a scene
func _apply_scene_config(scene_path: String):
	if not scene_config.has(scene_path):
		Logger.info("SCENE", "No configuration for scene " + scene_path)
		return
		
	var config = scene_config[scene_path]
	
	# Apply music setting
	if config.has("music"):
		Logger.info("SCENE", "Playing music track: " + config["music"])
		MusicManager.play_track(config["music"])
	else:
		Logger.info("SCENE", "No music specified for scene")

# Add a centralized function to check if current scene is battle scene
func is_in_battle_scene() -> bool:
	Logger.info("SCENE", "Current Scene: " + current_scene_path, Logger.DetailLevel.HIGH)
	return current_scene_path == "res://scenes/battle/battle_scene.tscn"

# Add a centralized function to check if current scene is selection scene
func is_in_selection_scene() -> bool:
	return current_scene_path == "res://scenes/selection/selection_scene.tscn"

# Add a getter for battle scene
func get_battle_scene() -> BattleScene:
	# First check if we have a valid battle scene reference
	if _battle_scene != null and is_instance_valid(_battle_scene):
		Logger.info("SCENE", "Returning cached battle scene reference")
		return _battle_scene
		
	# If no valid reference, try to find the battle scene in the current scene
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_node("BattleLayout"):
		Logger.info("SCENE", "Found battle scene by content")
		_battle_scene = current_scene
		current_scene_path = "res://scenes/battle/battle_scene.tscn"
		return _battle_scene
		
	Logger.info("SCENE", "No valid battle scene found")
	return null
