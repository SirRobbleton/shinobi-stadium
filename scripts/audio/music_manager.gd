# music_manager.gd
extends Node

# Two audio players for crossfading
var primary_player: AudioStreamPlayer
var secondary_player: AudioStreamPlayer
var current_player: AudioStreamPlayer

# Track dictionary
var tracks = {
	"intro": "res://assets/audio/storm_theme.mp3",
	"selection":
		["res://assets/audio/peace_theme.mp3",
		"res://assets/audio/konoha_theme.mp3",
		"res://assets/audio/hidan_theme.mp3",
		"res://assets/audio/pain_theme.mp3"],
	"battle":
		[#"res://assets/audio/battle_theme.mp3",
		"res://assets/audio/akatsuki_theme.mp3",
		"res://assets/audio/orochimaru_theme.mp3",
		"res://assets/audio/yogensha_theme.mp3",
		"res://assets/audio/hidan_theme.mp3",
		"res://assets/audio/pain_theme.mp3"]
}

# Current state
var current_track: String = ""
var fade_duration: float = 2.0  # Fade duration in seconds

# Add these variables at the top with other declarations
var current_track_index: int = 0
var track_sequence: Array = []
var is_sequence_playing: bool = false

func _ready():
	Logger.info("AUDIO", "MusicManager initializing...")
	
	# Create audio players
	primary_player = AudioStreamPlayer.new()
	secondary_player = AudioStreamPlayer.new()
	
	# Configure players
	primary_player.bus = "Music"
	secondary_player.bus = "Music"
	
	# Set initial volumes
	primary_player.volume_db = 0  # Normal volume
	secondary_player.volume_db = -80  # Silent
	
	# Add to scene tree
	add_child(primary_player)
	add_child(secondary_player)
	
	# Set initial player
	current_player = primary_player
	
	# Verify track existence
	for track_name in tracks:
		var path = tracks[track_name]
		if path is Array:
			# Handle track sequences
			for track_path in path:
				if !FileAccess.file_exists(track_path):
					Logger.warning("AUDIO", "Music file not found: " + track_path)
		else:
			# Handle single tracks
			if !FileAccess.file_exists(path):
				Logger.warning("AUDIO", "Music file not found: " + path)
	
	Logger.info("AUDIO", "MusicManager ready")

# Play a track with crossfading
func play_track(track_name: String):
	# If this is a sequence, use the sequence player
	if tracks.has(track_name) and tracks[track_name] is Array:
		play_track_sequence(track_name)
		return
	
	# Otherwise use the original single-track logic
	# Skip if already playing this track
	if is_track_playing(track_name):
		return
	
	# Check if we have this track
	if not tracks.has(track_name):
		Logger.error("AUDIO", "Track not found - " + track_name)
		return
	
	var path = tracks[track_name]
	if !FileAccess.file_exists(path):
		Logger.error("AUDIO", "Music file doesn't exist - " + path)
		return
	
	Logger.info("AUDIO", "Playing track - " + track_name)
	
	# Get the track to play
	var stream = load(path)
	if not stream:
		Logger.error("AUDIO", "Failed to load stream - " + path)
		return
	
	# Determine which player to use next
	var next_player = secondary_player if current_player == primary_player else primary_player
	
	# Load stream into next player and start playing
	next_player.stream = stream
	next_player.volume_db = -80  # Start silent
	next_player.play()
	
	# Create crossfade
	var tween = create_tween()
	
	# If something is already playing, fade it out
	if current_player.playing:
		tween.parallel().tween_property(current_player, "volume_db", -80, fade_duration)
	
	# Fade in the new track
	tween.parallel().tween_property(next_player, "volume_db", 0, fade_duration)
	
	# Update tracking
	current_track = track_name
	current_player = next_player
	
	Logger.info("AUDIO", "Music crossfading to: " + track_name)

# Check if a specific track is currently playing
func is_track_playing(track_name: String) -> bool:
	return current_track == track_name && current_player.playing

# Stop all music with fade
func stop_all():
	var tween = create_tween()
	tween.tween_property(primary_player, "volume_db", -80, fade_duration)
	tween.parallel().tween_property(secondary_player, "volume_db", -80, fade_duration)
	tween.tween_callback(Callable(self, "_stop_players"))
	
	current_track = ""

# Helper to stop both players after fade out
func _stop_players():
	primary_player.stop()
	secondary_player.stop()

# Set global music volume (0.0 to 1.0)
func set_volume(vol: float):
	# Convert linear volume to dB
	var db = linear_to_db(clamp(vol, 0.0, 1.0))
	
	# Apply only to the active player
	if current_player.playing:
		current_player.volume_db = db
		
# Play a track instantly without fading
func play_track_instant(track_name: String):
	# Check if we have this track
	if not tracks.has(track_name):
		Logger.error("AUDIO", "Track not found - " + track_name)
		return
		
	var path = tracks[track_name]
	
	if !FileAccess.file_exists(path):
		Logger.error("AUDIO", "Music file doesn't exist - " + path)
		return
	
	Logger.info("AUDIO", "Playing track instantly - " + track_name)
	
	# Stop both players immediately
	primary_player.stop()
	secondary_player.stop()
		
	# Load and play on primary player at full volume
	var stream = load(path)
	if stream:
		primary_player.stream = stream
		primary_player.volume_db = 0  # Full volume
		primary_player.play()

		# Update tracking
		current_track = track_name
		current_player = primary_player

		Logger.info("AUDIO", "Music started: " + track_name)
	else:
		Logger.error("AUDIO", "Failed to load stream - " + path)

# Add this new function to handle sequential playback
func play_track_sequence(track_name: String):
	# Check if we have this track sequence
	if not tracks.has(track_name):
		Logger.error("AUDIO", "Track sequence not found - " + track_name)
		return
	
	var sequence = tracks[track_name]
	if not sequence is Array:
		Logger.error("AUDIO", "Track is not a sequence - " + track_name)
		return
	
	# Set up sequence
	track_sequence = sequence
	current_track_index = 0
	is_sequence_playing = true
	
	# Start playing the first track
	_play_next_track_in_sequence()

# Add this helper function for sequence playback
func _play_next_track_in_sequence():
	if not is_sequence_playing or current_track_index >= track_sequence.size():
		is_sequence_playing = false
		return
	
	var path = track_sequence[current_track_index]
	if !FileAccess.file_exists(path):
		Logger.error("AUDIO", "Music file doesn't exist - " + path)
		return
	
	Logger.info("AUDIO", "Playing track " + str(current_track_index + 1) + " of " + str(track_sequence.size()))
	
	# Get the track to play
	var stream = load(path)
	if not stream:
		Logger.error("AUDIO", "Failed to load stream - " + path)
		return
	
	# Determine which player to use next
	var next_player = secondary_player if current_player == primary_player else primary_player
	
	# Load stream into next player and start playing
	next_player.stream = stream
	next_player.volume_db = -80  # Start silent
	next_player.play()
	
	# Create crossfade
	var tween = create_tween()
	
	# If something is already playing, fade it out
	if current_player.playing:
		tween.parallel().tween_property(current_player, "volume_db", -80, fade_duration)
	
	# Fade in the new track
	tween.parallel().tween_property(next_player, "volume_db", 0, fade_duration)
	
	# Update tracking
	current_track = "sequence_" + str(current_track_index)
	current_player = next_player
	
	# Connect to the finished signal to play next track
	#next_player.finished.connect(_on_track_finished, CONNECT_ONE_SHOT)

# Add this signal handler
func _on_track_finished():
	if is_sequence_playing:
		current_track_index += 1
		_play_next_track_in_sequence()
