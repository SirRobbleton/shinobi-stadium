extends Node

var characters: Array[CharacterData] = []

# Singleton accessor
static func get_instance():
	return Engine.get_main_loop().get_root().get_node("/root/CharacterDatabase")

func _ready():
	# AbilityDatabase is now autoloaded first, so we can load immediately
	load_from_csv("res://data/characters.csv")

func load_from_csv(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Logger.error("DATABASE", "Failed to open CSV at " + path, Logger.DetailLevel.HIGH)
		return

	# Skip header line
	file.get_line()

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "":
			continue

		var fields = line.split(",")
		if fields.size() < 7:  # Now we expect at least 7 fields
			Logger.warning("DATABASE", "Skipping line with insufficient fields: " + line)
			continue

		var character = CharacterData.new()
		character.name = fields[0]
		character.hp = fields[1].to_int()
		character.ability = fields[2]        # Ability is now in column 3
		character.main_jutsu_name = fields[3]  # Attack name is now in column 4
		character.main_jutsu_damage = fields[4].to_int()  # Attack damage in column 5
		character.support_jutsu_damage = fields[5].to_int()  # Support damage in column 6
		character.image_path = fields[6]  # Image path is now in column 7
		
		# Load additional ability data if available
		if fields.size() > 7:
			character.ultimate_name = fields[7] if fields[7] != "" else ""
		if fields.size() > 8:
			character.transformation_name = fields[8] if fields[8] != "" else ""
		if fields.size() > 9:
			character.transformation_jutsu_name = fields[9] if fields[9] != "" else ""
		
		# For backward compatibility
		character.attack = character.main_jutsu_damage
		character.support_attack = character.support_jutsu_damage
		
		# Reset HP to ensure current_hp is properly set after properties are initialized
		character.reset_hp()
		
		# Load ability data from AbilityDatabase
		character.load_ability_data()
		
		# Verify image path exists
		var image_file = FileAccess.file_exists(character.image_path)
		
		if !image_file:
			Logger.info("DATABASE", "Image not found at: " + character.image_path + " for " + character.name, Logger.DetailLevel.LOW)
			
			# Try to find an alternative image based on character name
			var fallback_image = find_fallback_image(character.name)
			if fallback_image != "":
				Logger.info("DATABASE", "Found fallback image: " + fallback_image + " for " + character.name)
				character.image_path = fallback_image
				image_file = true
			else:
				Logger.error("DATABASE", "No suitable image found for: " + character.name, Logger.DetailLevel.HIGH)
		
		# Try loading the texture to verify it works
		var texture = load(character.image_path)
		if texture == null:
			Logger.error("DATABASE", "Failed to load texture for " + character.name + " from " + character.image_path, Logger.DetailLevel.HIGH)
		else:
			Logger.info("DATABASE", "Successfully loaded image for " + character.name + ": " + character.image_path, Logger.DetailLevel.LOW)

		characters.append(character)

	Logger.info("DATABASE", "Loaded " + str(characters.size()) + " characters")

# Find a fallback image for a character based on their name
func find_fallback_image(character_name: String) -> String:
	# Extract the first part of the name (e.g., "naruto" from "naruto_uzumaki")
	var name_parts = character_name.to_lower().split(" ")
	var first_name = name_parts[0]
	
	# Remove any parentheses and content inside them
	if first_name.find("(") != -1:
		first_name = first_name.substr(0, first_name.find("(")).strip_edges()
	
	Logger.info("DATABASE", "Searching for fallback image with name part: " + first_name, Logger.DetailLevel.LOW)
	
	var dir = DirAccess.open("res://assets/characters/")
	if !dir:
		Logger.error("DATABASE", "Could not access assets/characters directory", Logger.DetailLevel.HIGH)
		return ""
		
	# First try: Find a file containing the character's first name
	var image_files = []
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
		
	while file_name != "":
		if !dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".jpg")):
			# Save all image files for potential random selection later
			image_files.append(file_name)
			
			# Check if the filename contains the first part of the character name
			if file_name.to_lower().contains(first_name):
				var fallback_path = "res://assets/characters/" + file_name
				Logger.info("DATABASE", "Found potential match: " + fallback_path, Logger.DetailLevel.LOW)
				dir.list_dir_end()
				return fallback_path
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Second try: Select a random image from the directory
	if image_files.size() > 0:
		# Use a consistent seed based on character name for deterministic results
		var char_seed = 0
		for i in character_name.length():
			char_seed += character_name.unicode_at(i)
		
		# Create a random number generator with the seed
		var rng = RandomNumberGenerator.new()
		rng.seed = char_seed
		
		# Pick a random image
		var random_image = image_files[rng.randi() % image_files.size()]
		var random_path = "res://assets/characters/" + random_image
		Logger.info("DATABASE", "No name match found, using random image: " + random_path, Logger.DetailLevel.LOW)
		return random_path
	
	return ""

# Get the count of characters
func get_character_count() -> int:
	return characters.size()
	
# Get a character by index
func get_character(index: int) -> CharacterData:
	if index >= 0 and index < characters.size():
		return characters[index]
	return null
	
# Get all characters
func get_all_characters() -> Array:
	return characters
