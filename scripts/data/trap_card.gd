# trap_card.gd
extends BattleCard
class_name TrapCard

# Trap card properties
enum TriggerCondition {ATTACKED, TARGETED, SWITCHED, HEALTH_LOW, TURN_START, TURN_END}
@export var trigger_condition: TriggerCondition = TriggerCondition.ATTACKED
@export var trigger_value: int = 0  # For conditions that need a value (like HEALTH_LOW)
@export var linked_shinobi: String = ""  # ID of shinobi this trap is linked to
@export var is_face_down: bool = true  # Traps start face down

func _init(card_id: String = "", card_name: String = ""):
	super(card_id, card_name)
	card_type = "trap"

func play(game_state, player: String, target = null) -> bool:
	# First check if we can pay the cost
	if not super.play(game_state, player, target):
		return false
	
	print("[TRAP_CARD| Playing trap card: " + name)
	
	# When a trap is played, it is set face down and linked to a shinobi
	is_face_down = true
	if target:
		linked_shinobi = target.id  # Assuming target is a shinobi with an ID
	
	# Register the trap with the game state
	# game_state.register_trap(self, player, linked_shinobi)
	
	return true

func trigger(game_state, player: String, trigger_data = null) -> bool:
	# Check if condition is met for triggering
	if not check_trigger_condition(trigger_data):
		return false
	
	print("[TRAP_CARD| Trap triggered: " + name)
	
	# Reveal the trap
	is_face_down = false
	
	# Apply trap effects
	# This would be similar to support card effects but with specific trap behaviors
	for effect in effects:
		apply_trap_effect(game_state, player, effect)
	
	return true

func apply_trap_effect(game_state, player: String, effect):
	# Apply specific trap effects based on effect type
	# This would be similar to support card effects but could have trap-specific logic
	pass

func check_trigger_condition(trigger_data) -> bool:
	# Check if the trigger condition is met based on the trigger_data
	# trigger_data would contain information about what triggered this check
	match trigger_condition:
		TriggerCondition.ATTACKED:
			# Check if linked shinobi was attacked
			return trigger_data.has("attacked_shinobi") and trigger_data.attacked_shinobi == linked_shinobi
		TriggerCondition.TARGETED:
			# Check if linked shinobi was targeted by an ability
			return trigger_data.has("targeted_shinobi") and trigger_data.targeted_shinobi == linked_shinobi
		TriggerCondition.SWITCHED:
			# Check if player switched active shinobi
			return trigger_data.has("switched") and trigger_data.switched
		TriggerCondition.HEALTH_LOW:
			# Check if linked shinobi's health is below trigger_value
			return trigger_data.has("shinobi_health") and trigger_data.shinobi_id == linked_shinobi and trigger_data.shinobi_health <= trigger_value
		TriggerCondition.TURN_START:
			# Check if it's the start of a turn
			return trigger_data.has("turn_phase") and trigger_data.turn_phase == 0  # 0 = DRAW phase
		TriggerCondition.TURN_END:
			# Check if it's the end of a turn
			return trigger_data.has("turn_phase") and trigger_data.turn_phase == 3  # 3 = END phase
	
	return false

func get_valid_targets(game_state, player: String) -> Array:
	# For traps, valid targets are the player's shinobi
	return get_all_allies(game_state, player)

func get_all_allies(game_state, player: String) -> Array:
	# Return all shinobi belonging to the player
	return []  # Replace with actual shinobi references once implemented 