# scripts/ui/character_card_cell.gd
extends Control
class_name CharacterCardCell

@export var card_scene: PackedScene # assign res://scenes/objects/character_card.tscn in inspector
@onready var vp = $SubViewportContainer/SubViewport

var script_name: String = "[" + get_script().resource_path.get_file().get_basename().to_upper() + "] "

# Forwarded signals
signal card_clicked(card)
signal zoom_requested(character_data)
signal drag_started(card)
signal drag_ended(card)

func setup(character_data):
	print(script_name + "Setting up character: " + character_data.name)
	# clear old children
	for child in vp.get_children():
		child.queue_free()

	# instance the real card
	var card = card_scene.instantiate()
	vp.add_child(card)
	if card.has_method("setup"):
		card.setup(character_data)

	# center the card's origin so it's fully inside the SubViewport
	card.position = vp.size / 2

	# hook signals to re-emit
	#if card.has_signal("card_clicked"):
	#	card.card_clicked.connect(self.card_clicked)
	#if card.has_signal("zoom_requested"):
		#card.zoom_requested.connect(self.zoom_requested)
	#if card.has_signal("drag_started"):
		#card.drag_started.connect(self.drag_started)
	#if card.has_signal("drag_ended"):
		#card.drag_ended.connect(self.drag_ended)

	# adjust SubViewport to card size if needed
	#if card.has_meta("original_position") == false:
		# assume exported defaults
		#pass 
