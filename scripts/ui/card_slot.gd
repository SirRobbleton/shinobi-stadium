extends Area2D
class_name CardSlot

var held_card: Node = null
signal card_placed(slot, card)
signal card_removed(slot)
signal card_dropped(slot, card)

func _ready():
	add_to_group("slots")
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.is_in_group("cards") and held_card == null:
		body.valid_drop_zone = self

func _on_body_exited(body):
	if body.is_in_group("cards") and held_card != body:
		if body.valid_drop_zone == self:
			body.valid_drop_zone = null

func disable_collision():
	print("[CARD_SLOT| Disabling collision for slot: " + name)
	$CollisionShape2D.disabled = true
	input_pickable = false
	# Keep slot visible
	emit_signal("card_placed", self, held_card)
	print("[CARD_SLOT| Collision disabled")

func enable_collision():
	if held_card == null:
		print("[CARD_SLOT| Enabling collision for slot: " + name)
		$CollisionShape2D.disabled = false
		input_pickable = true
		# Keep slot visible
		emit_signal("card_removed", self)
		print("[CARD_SLOT| Collision enabled")

# Set a card in this slot
func set_card(card):
	print("[CARD_SLOT| Setting card in slot: " + name)
	held_card = card
	disable_collision()  # Disable collision when a card is set
	emit_signal("card_dropped", self, card)  # Emit dropped signal
	return true

# Get the card in this slot
func get_card():
	return held_card

# Clear the card from this slot
func clear_card():
	print("[CARD_SLOT| Clearing card from slot: " + name)
	held_card = null
	enable_collision()  # Re-enable collision when cleared
	return true

# Set slot highlighting (called during card drag operations)
func set_highlight(is_highlighted: bool):
	# Get the TextureRect (visual representation of the slot)
	var texture_rect = $TextureRect
	if texture_rect:
		if is_highlighted:
			# Highlight with a more visible color
			texture_rect.color = Color(0.5, 0.8, 1.0, 0.4)
		else:
			# Reset to default color
			texture_rect.color = Color(1, 1, 1, 0.196078)
	
	# Print debug information
	if is_highlighted:
		print("[CARD_SLOT| Highlighting slot: " + name)
