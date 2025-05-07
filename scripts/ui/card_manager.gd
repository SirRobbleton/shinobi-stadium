extends Node2D

# Removed type preloads; use `cards` group and CharacterCard type instead

# Card registry
var active_cards = []

signal card_dragged(card)
signal card_dropped(card)

func _ready():
	print("[CARD_MANAGER] Initialized")

func register_card(card):
	if card.is_in_group("cards"):
		active_cards.append(card)
		
		# Connect common signals
		card.connect("dragged", self, "_on_card_dragged")
		card.connect("dropped", self, "_on_card_dropped")
		
		# Connect character-specific signals
		if card is CharacterCard:
			card.connect("switch_requested", self, "_on_switch_requested")
			
		print("[CARD_MANAGER] Card registered: ", card.name)
	else:
		print("[CARD_MANAGER] Attempted to register non-card object")

func unregister_card(card):
	if card in active_cards:
		active_cards.erase(card)
		
		# Disconnect signals
		if card.is_connected("dragged", self, "_on_card_dragged"):
			card.disconnect("dragged", self, "_on_card_dragged")
		
		if card.is_connected("dropped", self, "_on_card_dropped"):
			card.disconnect("dropped", self, "_on_card_dropped")
			
		if card is CharacterCard and card.is_connected("switch_requested", self, "_on_switch_requested"):
			card.disconnect("switch_requested", self, "_on_switch_requested")
		
		print("[CARD_MANAGER] Card unregistered: ", card.name)

func _on_card_dragged(card):
	emit_signal("card_dragged", card)
	
	# If it's a character card during pre-battle phase, show targetable cards
	if card is CharacterCard and !GamestateManager.has_switched_this_turn and !GamestateManager.in_battle_phase:
		for target_card in active_cards:
			if target_card is CharacterCard and target_card != card and target_card.owner_id == card.owner_id:
				target_card.set_targetable(true)

func _on_card_dropped(card):
	emit_signal("card_dropped", card)
	
	# Hide all target indicators when any card is dropped
	for target_card in active_cards:
		if target_card is CharacterCard:
			target_card.set_targetable(false)

func _on_switch_requested(source_card, target_card):
	print("[CARD_MANAGER] Switch requested from ", source_card.name, " to ", target_card.name)
	
	# Request the switch through the GamestateManager
	if GamestateManager.perform_switch(source_card, target_card):
		_swap_card_positions(source_card, target_card)

func _swap_card_positions(source_card, target_card):
	# Store original positions
	var source_pos = source_card.position
	var source_slot = source_card.current_slot
	var target_pos = target_card.position
	var target_slot = target_card.current_slot
	
	# Update slots
	if source_slot:
		source_slot.card = target_card
	if target_slot:
		target_slot.card = source_card
		
	# Update card references
	source_card.current_slot = target_slot
	target_card.current_slot = source_slot
	
	# Animate the position swap
	source_card.animate_to_position(target_pos)
	target_card.animate_to_position(source_pos)
	
	print("[CARD_MANAGER] Swapped positions of ", source_card.name, " and ", target_card.name)
