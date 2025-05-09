extends Node

var abilities: Dictionary = {}  # name -> AbilityData

func _ready():
	load_from_csv("res://data/abilities.csv")

# Helper function to parse a value that might be a list
func parse_value(value: String) -> Variant:
	value = value.strip_edges()
	
	# Debug the incoming value - set to LOW detail level
	Logger.info("DATABASE", "Parsing value: '" + str(value) + "'", Logger.DetailLevel.LOW)
	
	# Empty values become null
	if value == "":
		Logger.info("DATABASE", "Empty value, returning null", Logger.DetailLevel.LOW)
		return null
	
	# Check if it's a list (starts with [ and ends with ])
	if value.begins_with("[") and value.ends_with("]"):
		Logger.info("DATABASE", "Detected as list: " + str(value), Logger.DetailLevel.LOW)
		# Remove the brackets and split by comma
		var list_str = value.substr(1, value.length() - 2)
		var items = list_str.split(",")
		
		# Try to convert each item to int, if possible
		var result = []
		for item in items:
			item = item.strip_edges()
			if item.is_valid_int():
				result.append(item.to_int())
				Logger.info("DATABASE", "Added int: " + str(item.to_int()), Logger.DetailLevel.LOW)
			else:
				result.append(item)
				Logger.info("DATABASE", "Added string: " + str(item), Logger.DetailLevel.LOW)
		Logger.info("DATABASE", "Final list result: " + str(result), Logger.DetailLevel.LOW)
		return result
	
	# If it's a single value, try to convert to int
	if value.is_valid_int():
		Logger.info("DATABASE", "Parsed as integer: " + str(value.to_int()), Logger.DetailLevel.LOW)
		return value.to_int()
	
	# If it's not a number, return as string
	Logger.info("DATABASE", "Parsed as string: " + str(value), Logger.DetailLevel.LOW)
	return value

# Clean up field values - handles problematic triple quotes 
func clean_field(field: String) -> String:
	var cleaned = field.strip_edges()
	
	# Fix triple-quoted strings (""") by replacing with single quotes
	if cleaned.begins_with('"""') and cleaned.ends_with('"""'):
		cleaned = cleaned.substr(3, cleaned.length() - 6)
	
	# Remove any remaining quotes
	cleaned = cleaned.replace('"', '')
	
	return cleaned

func load_from_csv(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Logger.error("DATABASE", "Failed to open abilities CSV at " + path)
		return

	# Skip header
	file.get_line()
	var line_count = 0

	while not file.eof_reached():
		line_count += 1
		var line = file.get_line().strip_edges()
		if line == "":
			continue
			
		# We need a more robust CSV parser for lines with commas in quoted strings
		var fields = parse_csv_line(line)
		if fields.size() < 12:
			Logger.warning("DATABASE", "Skipping line with insufficient fields: " + line)
			continue

		# Create AbilityData resource
		var ability_res = AbilityData.new()
		ability_res.name = clean_field(fields[0])
		ability_res.ability_class = clean_field(fields[1])
		ability_res.ability_type = clean_field(fields[2])
		ability_res.random = parse_value(clean_field(fields[3]))
		ability_res.ninjutsu = parse_value(clean_field(fields[4]))
		ability_res.taijutsu = parse_value(clean_field(fields[5]))
		ability_res.genjutsu = parse_value(clean_field(fields[6]))
		ability_res.bloodline = parse_value(clean_field(fields[7]))
		ability_res.damage = parse_value(clean_field(fields[8]))
		ability_res.support_damage = parse_value(clean_field(fields[9]))
		ability_res.target = parse_value(clean_field(fields[10]))
		ability_res.duration = parse_value(clean_field(fields[11]))

		# Print extra debug info for problem fields - keep at MEDIUM level for important entries
		if ability_res.name.contains("Karasu") or ability_res.name.contains("Summoning"):
			Logger.info("DATABASE", "Special entry: " + ability_res.name)
			Logger.info("DATABASE", "  - damage: " + str(ability_res.damage))
			Logger.info("DATABASE", "  - support_damage: " + str(ability_res.support_damage))
			Logger.info("DATABASE", "  - target: " + str(ability_res.target))
		
		abilities[ability_res.name] = ability_res

	# Keep summary logs at medium detail level
	Logger.info("DATABASE", "Loaded " + str(abilities.size()) + " abilities")

# Custom CSV line parser that properly handles quoted strings
func parse_csv_line(line: String) -> Array:
	var result = []
	var current_field = ""
	var inside_quotes = false
	var i = 0
	
	while i < line.length():
		var char = line[i]
		
		# Handle quotes
		if char == '"':
			if i + 1 < line.length() and line[i + 1] == '"':
				# Double quotes inside quoted string = escaped quote
				current_field += '"'
				i += 2
				continue
			else:
				# Single quote = toggle quote mode
				inside_quotes = !inside_quotes
				i += 1
				continue
		
		# Handle commas
		if char == ',' and !inside_quotes:
			# End of field
			result.append(current_field)
			current_field = ""
			i += 1
			continue
		
		# Add character to current field
		current_field += char
		i += 1
	
	# Add the last field
	result.append(current_field)
	
	return result

func get_ability(ability_name: String) -> AbilityData:
	return abilities.get(ability_name, null)

func get_all_abilities() -> Dictionary:
	return abilities 
