extends Node2D

@export var drag_layer: Node

func _ready():
	for card in get_children():
		if card.has_method("set_drag_layer") and drag_layer:
			card.set_drag_layer(drag_layer)
