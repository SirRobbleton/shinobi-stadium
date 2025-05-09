# game_state.gd
extends Node

signal place_character_on_slot(current_character: CharacterCard, slot: CardSlot)

# Player's selected shinobi
var active_shinobi : CharacterData = null
var support_shinobi_1 : CharacterData = null
var support_shinobi_2 : CharacterData = null

var player_shinobi = [await active_shinobi, await support_shinobi_1, await support_shinobi_2]

# Opponent's shinobi
var opponent_shinobi = []

# Card slot positions
var card_slot_positions: Array[Vector2] = []

var CharacterCardScene = load("res://scenes/objects/character_card.tscn")
var current_character: CharacterCard = null

# Generate random characters for both player and opponent
func generate_random_characters():
	Logger.info("SELECTION", "Generating random characters for battle")
	
	# Get character database
	var character_db = load("res://scripts/data/character_database.gd").get_instance()
	if not character_db:
		Logger.error("SELECTION", "CharacterDatabase not found!")
		return false
	
	# Get all available characters
	var all_characters = character_db.get_all_characters()
	if all_characters.size() < 6:
		Logger.error("SELECTION", "Not enough characters in database to generate random teams! Need at least 6.")
		return false
	
	# Shuffle the list for randomness
	all_characters.shuffle()
	
	# Assign first three to player
	active_shinobi = all_characters[0]
	support_shinobi_1 = all_characters[1]
	support_shinobi_2 = all_characters[2]
	
	Logger.info("SELECTION", "Player characters: Active=" + active_shinobi.name + 
		", Support1=" + support_shinobi_1.name + 
		", Support2=" + support_shinobi_2.name)
	
	# Assign next three to opponent
	opponent_shinobi = []
	opponent_shinobi.append(all_characters[3])
	opponent_shinobi.append(all_characters[4])
	opponent_shinobi.append(all_characters[5])
	
	Logger.info("SELECTION", "Opponent characters: " + 
		opponent_shinobi[0].name + ", " + 
		opponent_shinobi[1].name + ", " + 
		opponent_shinobi[2].name)
	
	return true
	
func set_current_character(character: CharacterCard):
	current_character = character
	Logger.info("SELECTION", "Current character: " + str(current_character))
