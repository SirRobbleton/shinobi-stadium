extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var is_selected: bool = false
var is_dragging: bool = false
var drag_offset: Vector2

var original_position: Vector2
var original_parent: Node = null
var valid_drop_zone: Node2D = null
var previous_drop_zone: Node2D = null

var drag_layer: Node = null

func _ready():
	set_highlight(false)
	original_position = global_position
	add_to_group("cards")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func set_drag_layer(layer: Node):
	drag_layer = layer

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true

			if drag_layer:
				original_parent = get_parent()
				get_parent().remove_child(self)
				drag_layer.add_child(self)
				z_index = 100
				z_as_relative = false
			else:
				push_error("DragLayer not assigned to card!")

			is_selected = !is_selected
			set_highlight(is_selected)
			print("[CARD| " + (name if is_selected else "Card deselected: " + name))

			drag_offset = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled()
		else:
			is_dragging = false
			snap_to_slot_or_reset()

func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func set_highlight(enabled: bool):
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 0.5) if enabled else Color(1, 1, 1)

func snap_to_slot_or_reset():
	if original_parent:
		get_parent().remove_child(self)
		original_parent.add_child(self)
		original_parent = null

	var slot_to_restore := previous_drop_zone
	if slot_to_restore:
		print("[CARD| Deferring re-enable of previous slot: " + slot_to_restore.name)
		slot_to_restore.held_card = null
		previous_drop_zone = null

	# Try to find a new valid slot (excluding the one we just left)
	if not valid_drop_zone:
		for slot in get_tree().get_nodes_in_group("slots"):
			if slot != slot_to_restore and overlaps_area(slot) and slot.held_card == null:
				valid_drop_zone = slot
				break

	if valid_drop_zone:
		print("[CARD| Hiding new slot: " + valid_drop_zone.name)
		global_position = valid_drop_zone.global_position
		original_position = global_position

		valid_drop_zone.held_card = self
		valid_drop_zone.disable_collision()

		previous_drop_zone = valid_drop_zone

		print("[CARD| " + name + " dropped into slot: " + valid_drop_zone.name)
	else:
		global_position = original_position
		print("[CARD| " + name + " returned to hand.")

	# Defer enabling of old slot (after overlap checks are complete)
	if slot_to_restore:
		slot_to_restore.call_deferred("enable_collision")

	valid_drop_zone = null
