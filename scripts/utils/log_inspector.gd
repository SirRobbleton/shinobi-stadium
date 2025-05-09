@tool
extends EditorScript

# This tool script can be used to inspect and control logging settings
# Run it from the Godot editor using the "Run" button in the Script Editor

func _run():
	print("======= LOGGING CONFIGURATION =======")
	
	var logger = Engine.get_singleton("Logger")
	if logger == null:
		var logger_script = load("res://scripts/utils/logger.gd")
		if logger_script:
			logger = logger_script.new()
			print("Logger loaded from script")
		else:
			print("ERROR: Logger script not found!")
			return
	
	# Display current settings
	print("\nMaster logging enabled: " + str(logger.logging_enabled))
	print("Current detail level: " + logger.detail_level_to_string(logger.current_detail_level))
	
	print("\nDetail level enablement:")
	for level in logger.detail_level_enabled:
		print("  - " + logger.detail_level_to_string(level) + ": " + 
			str(logger.detail_level_enabled[level]))
	
	print("\nMain Category enablement:")
	for category in logger.log_categories:
		print("  - " + category + ": " + str(logger.log_categories[category]))
	
	print("\nSpecialized Category enablement:")
	for category in logger.log_categories_level2:
		print("  - " + category + ": " + str(logger.log_categories_level2[category]))
	
	print("\n======= LOGGING COMMANDS =======")
	print("To toggle all logging, run in Console:")
	print("  Logger.logging_enabled = true/false")
	
	print("\nTo enable/disable specific detail level, run:")
	print("  Logger.set_detail_level(Logger.DetailLevel.LOW, true/false)")
	print("  Logger.set_detail_level(Logger.DetailLevel.MEDIUM, true/false)")
	print("  Logger.set_detail_level(Logger.DetailLevel.HIGH, true/false)")
	
	print("\nTo enable/disable specific category, run:")
	print("  Logger.set_category_enabled(\"BATTLE\", true/false)")
	print("  Logger.set_category_enabled(\"UI\", true/false)")
	print("  Logger.set_category_enabled(\"DRAG\", true/false)")
	print("  Logger.set_category_enabled(\"CARD_STATE\", true/false)")
	print("  Logger.set_category_enabled(\"SLOT\", true/false)")
	print("  Logger.set_category_enabled(\"OVERLAY\", true/false)")
	print("  Logger.set_category_enabled(\"SCENE\", true/false)")
	print("  etc.")
	
	print("\n======= EXAMPLE USAGE =======")
	print("# Standard log (MEDIUM level):")
	print("  Logger.info(\"CATEGORY\", \"This is a standard log message\")")
	print("# LOW detail log (verbose debugging):")
	print("  Logger.info(\"CATEGORY\", \"This is a detailed diagnostic message\", Logger.DetailLevel.LOW)")
	print("# HIGH detail log (important/critical):")
	print("  Logger.info(\"CATEGORY\", \"This is an important status update\", Logger.DetailLevel.HIGH)")
	print("# Warning log:")
	print("  Logger.warning(\"CATEGORY\", \"This is a warning message\")")
	print("# Error log:")
	print("  Logger.error(\"CATEGORY\", \"This is an error message\")")
	
	print("\n======= CATEGORY USAGE EXAMPLES =======")
	print("# Battle overlay:")
	print("  Logger.info(\"BATTLE\", \"Attack button pressed\")")
	print("# Scene management:")
	print("  Logger.info(\"SCENE\", \"Changing scene to main.tscn\")")
	print("# Card slot interaction:")
	print("  Logger.info(\"SLOT\", \"Card dropped on slot\")")
	print("# Zoom overlay:")
	print("  Logger.info(\"UI\", \"Showing card for character\")")
	print("  Logger.info(\"OVERLAY\", \"Card positioned at center\", Logger.DetailLevel.LOW)")
	print("# Drag operations:")
	print("  Logger.info(\"DRAG\", \"Started dragging preview card\", Logger.DetailLevel.MEDIUM)")
	
	print("\n=================================") 