extends Node

var sfx_library := {
	"hover": "res://assets/audio/hover_sfx.mp3",
	"select": "res://assets/audio/select_sfx.mp3",
	"pop": "res://assets/audio/pop_sfx.mp3",
	"yo": "res://assets/audio/yo_sfx.mp3",
	"yo_1": "res://assets/audio/yo_1_sfx.mp3",
	"yo_2": "res://assets/audio/yo_2_sfx.mp3",
	"drag": "res://assets/audio/drag_sfx.mp3",
	"slide": "res://assets/audio/card_slide_sfx.mp3"
}

var sfx_player: AudioStreamPlayer

func _ready():
	print("SFXManager initializing...")
	
	# Create an AudioStreamPlayer for short SFX
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

	# (Optional) Verify files exist
	for sfx_name in sfx_library:
		var path = sfx_library[sfx_name]
		if not FileAccess.file_exists(path):
			push_warning("SFX file not found: " + path)
	
	print("SFXManager ready!")

func play_sfx(sfx_name: String):
	# Check if we have this sfx
	if not sfx_library.has(sfx_name):
		push_error("SFXManager: Sound not found - " + sfx_name)
		return

	var path = sfx_library[sfx_name]
	if not FileAccess.file_exists(path):
		push_error("SFXManager: File doesn't exist - " + path)
		return

	var stream = load(path)
	if stream:
		sfx_player.stream = stream
		sfx_player.play()
	else:
		push_error("SFXManager: Failed to load stream - " + path)

func play_random_sfx(sfx_list: Array):
	if !sfx_list:
		push_error("SFXManager: No SFX names provided to play_random_sfx.")
		return

	# Filter only valid entries from the input
	var valid_sfx = []
	for name in sfx_list:
		if sfx_library.has(name) and FileAccess.file_exists(sfx_library[name]):
			valid_sfx.append(name)
		else:
			push_warning("SFXManager: Skipping invalid or missing SFX - " + str(name))

	# If no valid tracks, abort
	if !valid_sfx:
		push_error("SFXManager: No valid SFX tracks found in list.")
		return

	# Pick one at random
	var random_name = valid_sfx[randi() % valid_sfx.size()]
	play_sfx(random_name)
