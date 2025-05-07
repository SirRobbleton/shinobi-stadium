extends Control

# Set this to true to skip directly to selection scene
var skip_intro = true

@onready var intro_logo = $IntroLogo
@onready var fade_overlay = $FadeOverlay

func _ready():
	if skip_intro:
		# Skip directly to selection scene - using call_deferred to avoid timing issues
		call_deferred("_change_scene")
		return
		
	# Start with black screen
	fade_overlay.color = Color(0, 0, 0, 1)
	
	# Play intro music
	#MusicManager.play_track_instant("intro")
	
	# Fade in logo
	var fade_in = create_tween()
	fade_in.tween_property(fade_overlay, "color:a", 0.0, 1.0)
	await fade_in.finished
	
	# Display for a few seconds
	await get_tree().create_timer(5.0).timeout
	
	# Fade out
	var fade_out = create_tween()
	fade_out.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	await fade_out.finished
	
	# Transition to selection scene
	SceneManager.change_scene("res://scenes/selection/selection_scene.tscn")

# Deferred scene change to avoid timing issues
func _change_scene():
	SceneManager.change_scene("res://scenes/selection/selection_scene.tscn")
