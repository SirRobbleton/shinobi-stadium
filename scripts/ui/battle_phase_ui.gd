extends Node

# Reference to phase label
@onready var phase_label = null
@onready var turn_label = null
@onready var phase_container = null

# Flag to track if we're in the battle scene
var in_battle_scene = false

# Colors for different phases
const phase_colors = {
	"DRAW": Color(0.2, 0.6, 1.0),   # Blue
	"CHAKRA": Color(0.1, 0.8, 0.1), # Green
	"MAIN": Color(1.0, 0.5, 0.0),   # Orange
	"END": Color(0.7, 0.0, 0.0)     # Red
}

func _ready():
	# Connect to scene change signals
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.connect("scene_changed", _on_scene_changed)
		
		# Check if we're already in battle scene
		in_battle_scene = scene_manager.is_in_battle_scene()
		if in_battle_scene:
			_find_ui_elements()
	
	# Connect to the BattleStateManager signals
	var battle_state = get_node_or_null("/root/BattleStateManager")
	if battle_state:
		battle_state.connect("phase_changed", _on_phase_changed)
		battle_state.connect("turn_changed", _on_turn_changed)
		
		# Set initial labels if we're already in battle scene
		if in_battle_scene:
			_update_phase_display(battle_state.current_player, 
							 battle_state.current_phase)
			_update_turn_display(battle_state.current_player)
	else:
		push_error("BattleStateManager not found!")

# Handle scene changes
func _on_scene_changed(scene_path):
	if scene_path == "res://scenes/battle/battle_scene.tscn":
		in_battle_scene = true
		# Short delay to ensure scene is loaded
		get_tree().create_timer(0.2).timeout.connect(_find_ui_elements)
	else:
		in_battle_scene = false

func _find_ui_elements():
	# Only try to find elements if we're in battle scene
	if !in_battle_scene:
		return
		
	# Get the current scene (which should be the battle scene)
	var battle_scene = get_tree().current_scene
	if battle_scene:
		# Adjust these paths to match your actual UI structure
		phase_container = battle_scene.get_node_or_null("UI/PhaseContainer")
		if phase_container:
			phase_label = phase_container.get_node_or_null("PhaseLabel")
			turn_label = phase_container.get_node_or_null("TurnLabel")
			
			print("[BATTLE_PHASE_UI] Found UI elements")
		else:
			print("[BATTLE_PHASE_UI] Phase container not found, creating one")
			_create_phase_ui(battle_scene)
	else:
		# Schedule retry after a delay
		print("[BATTLE_PHASE_UI] Battle scene not found, will try again later")
		get_tree().create_timer(0.5).timeout.connect(_find_ui_elements)

func _create_phase_ui(parent):
	# Create the phase UI if it doesn't exist
	phase_container = Control.new()
	phase_container.name = "PhaseContainer"
	parent.add_child(phase_container)
	
	# Position at top center
	phase_container.anchor_top = 0
	phase_container.anchor_left = 0.5
	phase_container.anchor_right = 0.5
	phase_container.anchor_bottom = 0
	phase_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	phase_container.grow_vertical = Control.GROW_DIRECTION_END
	phase_container.size = Vector2(300, 80)
	phase_container.position = Vector2(0, 10)
	
	# Create phase background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.1, 0.1, 0.1, 0.7)
	bg.size = phase_container.size
	phase_container.add_child(bg)
	
	# Create labels
	phase_label = Label.new()
	phase_label.name = "PhaseLabel"
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phase_label.size = Vector2(300, 40)
	phase_label.position = Vector2(0, 0)
	phase_label.add_theme_font_size_override("font_size", 24)
	phase_container.add_child(phase_label)
	
	turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.size = Vector2(300, 40)
	turn_label.position = Vector2(0, 40)
	turn_label.add_theme_font_size_override("font_size", 18)
	phase_container.add_child(turn_label)
	
	print("[BATTLE_PHASE_UI] Created phase UI elements")

func _on_phase_changed(player_id, old_phase, new_phase):
	# Only update if we're in battle scene
	if !in_battle_scene:
		return
		
	_update_phase_display(player_id, new_phase)

func _on_turn_changed(player_id):
	# Only update if we're in battle scene
	if !in_battle_scene:
		return
		
	_update_turn_display(player_id)

func _update_phase_display(player_id, phase_id):
	# Only update if we're in battle scene
	if !in_battle_scene:
		return
		
	if phase_label:
		var battle_state = get_node("/root/BattleStateManager")
		var phase_name = battle_state.get_current_phase_name()
		
		# Set text
		phase_label.text = phase_name + " PHASE"
		
		# Set color based on phase
		if phase_colors.has(phase_name):
			phase_label.add_theme_color_override("font_color", phase_colors[phase_name])
		
		# Animate phase change
		_animate_phase_change()
		
		print("[BATTLE_PHASE_UI] Updated phase display to: " + phase_name)

func _update_turn_display(player_id):
	# Only update if we're in battle scene
	if !in_battle_scene:
		return
		
	if turn_label:
		turn_label.text = player_id.capitalize() + "'s Turn"
		
		# Set color based on player
		var player_color = Color(0.2, 0.6, 1.0) if player_id == "player" else Color(1.0, 0.2, 0.2)
		turn_label.add_theme_color_override("font_color", player_color)
		
		print("[BATTLE_PHASE_UI] Updated turn display to: " + player_id)

func _animate_phase_change():
	# Only animate if we're in battle scene
	if !in_battle_scene:
		return
		
	# Create a flashy animation for phase change
	if phase_label:
		var original_scale = phase_label.scale
		
		var tween = create_tween()
		tween.tween_property(phase_label, "scale", original_scale * 1.2, 0.2)
		tween.tween_property(phase_label, "scale", original_scale, 0.2)
		
		# Also flash the background
		if phase_container and phase_container.has_node("Background"):
			var bg = phase_container.get_node("Background")
			var original_color = bg.color
			var flash_color = Color(1, 1, 1, 0.9)
			
			tween.parallel().tween_property(bg, "color", flash_color, 0.1)
			tween.tween_property(bg, "color", original_color, 0.3) 
