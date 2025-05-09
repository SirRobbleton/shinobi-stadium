extends Resource
class_name AbilityData

# Core identifying info
@export var name: String = ""
@export var ability_class: String = ""   # Special, Attack, Ultimate Attack, etc.
@export var ability_type: String = ""    # Ninjutsu, Taijutsu, Genjutsu, Bloodline

# Chakra / randomness requirements (ints OR arrays of ints)
@export var random: Variant = null
@export var ninjutsu: Variant = null
@export var taijutsu: Variant = null
@export var genjutsu: Variant = null
@export var bloodline: Variant = null

# Power / support fields (ints OR arrays)
@export var damage: Variant = null
@export var support_damage: Variant = null

# Target and duration (strings or arrays)
@export var target: Variant = null
@export var duration: Variant = null

# Helper function to get the first value from an array field, or the value itself if not an array
func get_value(field_name: String, default_value = 0):
	var value = get(field_name)
	
	if value == null:
		return default_value
		
	if typeof(value) == TYPE_ARRAY and value.size() > 0:
		return int(value[0])
	
	return value

func get_damage_value(is_support: bool = false) -> int:
	if is_support and support_damage != null:
		return get_value("support_damage", 0)
	return get_value("damage", 0)

func get_summary() -> String:
	var dmg = get_damage_value()
	return "%s (%s) dmg:%s" % [name, ability_class, str(dmg)] 
