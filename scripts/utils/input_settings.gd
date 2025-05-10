extends Node

# Global input settings that can be tweaked
class_name InputSettings

# Double click timing (in seconds)
static var double_click_threshold: float = 0.3

# Long press threshold (in seconds)
static var long_press_threshold: float = 0.3

# Card drag thresholds
static var drag_distance_threshold: float = 10.0  # Minimum drag distance to initiate a drag operation
static var drag_snap_distance: float = 100.0     # Distance for snapping to slots

# Debug mode for input events
static var debug_input: bool = true  # Enable debugging by default

# Also add drag debugging
static var debug_drag: bool = true

# Logging helpers
static func log_input_event(msg: String, level: int = Logger.DetailLevel.LOW):
	if debug_input:
		Logger.info("INPUT", msg, level) 