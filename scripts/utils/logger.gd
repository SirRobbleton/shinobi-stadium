extends Node

# ==============================================
# LOGGER CONFIGURATION - Edit these directly
# ==============================================

# Detail level enum
enum DetailLevel {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2
}

# Master switch - set to false to disable ALL logging
var logging_enabled = true

# Detail level control - logs with level <= current_detail_level will be shown
var current_detail_level = DetailLevel.MEDIUM

# Detail level toggles - individual controls for each level
var detail_level_enabled = {
	DetailLevel.LOW: true,    # Low-detail logs are off by default
	DetailLevel.MEDIUM: true,  # Medium-detail logs are on by default
	DetailLevel.HIGH: false     # High-detail logs are on by default
}

# Category toggles - set to false to disable a specific category
var log_categories = {
	"CARD": true,       # Card-related logs
	"BATTLE": true,     # Battle mechanics logs
	"UI": true,         # UI-related logs
	"GAMESTATE": true,  # Game state logs
	"CHAKRA": true,     # Chakra system logs
	"AUDIO": true,      # Audio/music logs
	"DATABASE": true,   # Data loading logs
	"SELECTION": true,  # Character selection logs
	"NETWORK": true,    # Networking logs (future)
	"DEBUG": false      # Extra debug information
}

# Special category for attack debugging
var log_categories_level2 = {
	"ATTACK": true,     # Attack-specific debugging
	"DRAG": true,       # Drag operation debugging
	"CARD_STATE": true, # Card state transition debugging
	"SLOT": true,       # Card slot interaction debugging
	"OVERLAY": true,    # Overlay UI debugging (battle and zoom)
	"SCENE": true       # Scene management debugging
}

# ==============================================
# Logger Implementation
# ==============================================

# Helper function to get current time as formatted string
func get_timestamp() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%02d:%02d:%02d" % [datetime.hour, datetime.minute, datetime.second]

func _ready():
	print("[" + get_timestamp() + "] Logger initialized - Master switch: " + str(logging_enabled) + 
		  ", Detail level: " + detail_level_to_string(current_detail_level))

# Helper to convert detail level to string
func detail_level_to_string(level: int) -> String:
	match level:
		DetailLevel.LOW: return "LOW"
		DetailLevel.MEDIUM: return "MEDIUM" 
		DetailLevel.HIGH: return "HIGH"
		_: return "UNKNOWN"

# Main logging function with detail level support
func log_message(category: String, message, level: int = DetailLevel.MEDIUM) -> void:
	# Skip if master switch is off
	if !logging_enabled:
		return
		
	# Skip if category is disabled
	if !is_category_enabled(category):
		return
		
	# Skip if detail level for this message is not enabled
	if !is_detail_level_enabled(level):
		return
	
	# Format the message with timestamp and category prefix
	var formatted_message = "[" + get_timestamp() + "] [" + category + "] " + str(message)
	
	# Just use Godot's standard print function
	print(formatted_message)

# Helper method for standard information logs with detail level support
func info(category: String, message, level: int = DetailLevel.MEDIUM) -> void:
	log_message(category, str(message), level)

# Check if a category is enabled
func is_category_enabled(category: String) -> bool:
	# Default to true if category isn't in the list
	if log_categories.has(category):
		return log_categories[category]
	elif log_categories_level2.has(category):
		return log_categories_level2[category]
		
	return true

# Check if a detail level is enabled
func is_detail_level_enabled(level: int) -> bool:
	if detail_level_enabled.has(level):
		return detail_level_enabled[level]
	return false

# Helper method to log with ERROR prefix
func error(category: String, message, level: int = DetailLevel.HIGH) -> void:
	log_message(category, "ERROR: " + str(message), level)

# Helper method to log with WARNING prefix  
func warning(category: String, message, level: int = DetailLevel.MEDIUM) -> void:
	log_message(category, "WARNING: " + str(message), level)

# Utility function to enable/disable a specific detail level
func set_detail_level(level: int, enabled: bool) -> void:
	if detail_level_enabled.has(level):
		detail_level_enabled[level] = enabled
		print("[" + get_timestamp() + "] Detail level " + detail_level_to_string(level) + " set to: " + str(enabled))

# Utility function to enable/disable a specific category
func set_category_enabled(category: String, enabled: bool) -> void:
	if log_categories.has(category):
		log_categories[category] = enabled
		print("[" + get_timestamp() + "] Category " + category + " set to: " + str(enabled))
	elif log_categories_level2.has(category):
		log_categories_level2[category] = enabled
		print("[" + get_timestamp() + "] Category " + category + " set to: " + str(enabled)) 
