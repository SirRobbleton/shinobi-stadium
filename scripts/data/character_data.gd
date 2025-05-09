extends Resource
class_name CharacterData

# Basic character info
@export var name: String
@export var hp: int
@export var ability: String
@export var attack: int
@export var support_attack: int
@export var image_path: String
@export var village: String
@export var affiliation: String

# Enhanced ability information
@export var ability_data: AbilityData
@export var attack_data: AbilityData
@export var ultimate_data: AbilityData
@export var transformation_effect_data: AbilityData
@export var transformation_attack_data: AbilityData

# Battle attributes
@export var chakra_type: int = -1  # Main chakra type, aligned with GameStateManager.ChakraType
@export var main_jutsu_name: String = ""
@export var main_jutsu_cost: Dictionary = {}  # {chakra_type: amount}
@export var main_jutsu_damage: int = 0
@export var main_jutsu_effect: Dictionary = {}  # {type, value, duration}

@export var support_jutsu_name: String = ""
@export var support_jutsu_cost: Dictionary = {}
@export var support_jutsu_damage: int = 0
@export var support_jutsu_effect: Dictionary = {}

# Transformation (Flick Mode) properties
@export var has_transformation: bool = false
@export var transformation_name: String = ""
@export var transformation_chakra_cost: Dictionary = {}
@export var transformation_effect: Dictionary = {}  # {type, value, duration}
@export var transformation_jutsu_name: String = ""
@export var transformation_jutsu_damage: int = 0

# Alternative to transformation: Ultimate jutsu
@export var has_ultimate: bool = false
@export var ultimate_name: String = ""
@export var ultimate_chakra_cost: Dictionary = {}
@export var ultimate_damage: int = 0
@export var ultimate_effect: Dictionary = {}

# Flags for tracking battle state
var current_hp: int = 0
var is_transformed: bool = false
var is_active: bool = false  # Is this the active shinobi
var active_effects: Array = []

func _init():
	# Don't initialize health here, as hp property isn't set yet
	# We'll do this in reset_hp() which will be called after properties are set
	Logger.info("DATA", "New character data created, will initialize HP later")

# Call this after the properties are set to ensure current_hp is correct
func reset_hp():
	current_hp = hp
	Logger.info("DATA", name + " HP reset to: " + str(current_hp) + "/" + str(hp))

# Load ability data from AbilityDatabase
func load_ability_data():
	var ability_db = Engine.get_main_loop().get_root().get_node("/root/AbilityDatabase")
	if not ability_db:
		Logger.error("DATA", "AbilityDatabase not found! Make sure it's loaded before CharacterDatabase.")
		return

	# Load ability data
	if ability != "":
		ability_data = ability_db.get_ability(ability)
		if ability_data == null:
			Logger.warning("DATA", "No data found for ability: " + ability)

	# Load attack data
	if main_jutsu_name != "":
		attack_data = ability_db.get_ability(main_jutsu_name)
		if attack_data == null:
			Logger.warning("DATA", "No data found for attack: " + main_jutsu_name)

	# Load ultimate data
	if ultimate_name != "":
		ultimate_data = ability_db.get_ability(ultimate_name)
		if ultimate_data == null:
			Logger.warning("DATA", "No data found for ultimate: " + ultimate_name)

	# Load transformation effect data
	if transformation_name != "":
		transformation_effect_data = ability_db.get_ability(transformation_name)
		if transformation_effect_data == null:
			Logger.warning("DATA", "No data found for transformation effect: " + transformation_name)

	# Load transformation attack data
	if transformation_jutsu_name != "":
		transformation_attack_data = ability_db.get_ability(transformation_jutsu_name)
		if transformation_attack_data == null:
			Logger.warning("DATA", "No data found for transformation attack: " + transformation_jutsu_name)

func take_damage(amount: int):
	current_hp = max(0, current_hp - amount)
	Logger.info("DATA", name + " took " + str(amount) + " damage. HP: " + str(current_hp) + "/" + str(hp))
	return current_hp <= 0  # Return true if character is defeated

func heal(amount: int):
	current_hp = min(hp, current_hp + amount)
	Logger.info("DATA", name + " healed " + str(amount) + " HP. HP: " + str(current_hp) + "/" + str(hp))

func transform():
	if has_transformation and not is_transformed:
		is_transformed = true
		Logger.info("DATA", name + " transformed into " + transformation_name)
		return true
	return false

func revert_transformation():
	if is_transformed:
		is_transformed = false
		Logger.info("DATA", name + " reverted from transformation")
		return true
	return false

func use_main_jutsu(target):
	# This would need to interact with the game state for chakra costs and effects
	var damage = main_jutsu_damage
	if is_transformed:
		damage = transformation_jutsu_damage
		Logger.info("DATA", name + " used " + transformation_jutsu_name + " for " + str(damage) + " damage")
	else:
		Logger.info("DATA", name + " used " + main_jutsu_name + " for " + str(damage) + " damage")
	
	# Apply damage to target
	if target and target.has_method("take_damage"):
		return target.take_damage(damage)
	return false

func use_support_jutsu(target):
	# If support_jutsu_name is empty, default to "Support Attack"
	var jutsu_name = support_jutsu_name if support_jutsu_name != "" else "Support Attack"
	Logger.info("DATA", name + " used support jutsu " + jutsu_name + " for " + str(support_jutsu_damage) + " damage")
	
	# Apply damage to target
	if target and target.has_method("take_damage"):
		return target.take_damage(support_jutsu_damage)
	return false

func use_ultimate(target):
	if has_ultimate:
		Logger.info("DATA", name + " used ultimate jutsu " + ultimate_name + " for " + str(ultimate_damage) + " damage")
		
		# Apply damage to target
		if target and target.has_method("take_damage"):
			return target.take_damage(ultimate_damage)
	return false
