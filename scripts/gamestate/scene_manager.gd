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
	print("CURRENT SCENE NODE 1: " + str(current_scene_node))
	if current_scene_node:
		current_scene_path = current_scene_node.scene_file_path
		print("[SCENE_MANAGER| Initial scene is " + current_scene_path)
		
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
				print("[SCENE_MANAGER| Skipping both intro and selection scenes")
				_skip_to_battle_scene()
			# If we're in the selection scene and should skip it
			elif skip_selection and current_scene_path == "res://scenes/selection/selection_scene.tscn":
				await get_tree().process_frame
				print("[SCENE_MANAGER| Skipping selection scene")
				_skip_to_battle_scene()
	else:
		# Don't throw an error, just log it
		print("[SCENE_MANAGER| WARNING: Could not get initial scene, will initialize later")
		# Wait for next frame and try again
		await get_tree().process_frame
		_initialize()

# Function to skip straight to battle scene with random characters
func _skip_to_battle_scene():
	# Generate random characters
	CharacterSelection.generate_random_characters()
	
	# Change to battle scene
	change_scene("res://scenes/battle/battle_scene.tscn")
	print("CURRENT SCENE NODE 2: " + str(current_scene_node))


# Change to a new scene with automatic music handling
func change_scene(new_scene_path: String):
	print("[SCENE_MANAGER| Changing scene to " + new_scene_path)
	
	# If called before initialization, mark as initialized
	if not initialized:
		initialized = true
	
	# If this is the selection scene and we should skip it
	if new_scene_path == "res://scenes/selection/selection_scene.tscn" and skip_selection:
		print("[SCENE_MANAGER| Skipping selection scene, going straight to battle")
		new_scene_path = "res://scenes/battle/battle_scene.tscn"
		
		# Generate random characters
		CharacterSelection.generate_random_characters()
	
	# Signal that we're changing scenes
	emit_signal("scene_changing", current_scene_path, new_scene_path)
	
	# Actually change the scene
	var error = get_tree().change_scene_to_file(new_scene_path)
	if error != OK:
		push_error("SceneManager: Failed to change scene: " + str(error))
		return
	
	# Wait for the scene to be ready
	await get_tree().process_frame
	
	# Update current scene tracking
	current_scene_path = new_scene_path
	current_scene_node = get_tree().current_scene
	print("CURRENT SCENE NODE 3: " + str(current_scene_node))

	# Apply the appropriate music and other scene-specific settings
	_apply_scene_config(new_scene_path)
	
	# Signal that scene has changed
	emit_signal("scene_changed", new_scene_path)

# Apply the configuration for a scene
func _apply_scene_config(scene_path: String):
	if not scene_config.has(scene_path):
		print("[SCENE_MANAGER| No configuration for scene " + scene_path)
		return
		
	var config = scene_config[scene_path]
	
	# Apply music setting
	if config.has("music"):
		print("[SCENE_MANAGER| Playing music track: " + config["music"])
		MusicManager.play_track(config["music"])
	else:
		print("[SCENE_MANAGER| No music specified for scene")

# Add a centralized function to check if current scene is battle scene
func is_in_battle_scene() -> bool:
	return current_scene_path == "res://scenes/battle/battle_scene.tscn"

# Add a centralized function to check if current scene is battle scene
func is_in_selection_scene() -> bool:
	return current_scene_path == "res://scenes/selection/selection_scene.tscn"
