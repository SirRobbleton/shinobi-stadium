# support_card.gd
extends BattleCard
class_name SupportCard

# Support card properties
enum TargetType {SELF, ALLY, ENEMY, ALL_ALLIES, ALL_ENEMIES, ALL}
@export var target_type: TargetType = TargetType.SELF
@export var effect_type: String  # "buff", "debuff", "heal", "damage"
@export var effect_value: int = 0
@export var effect_duration: int = 1  # 0 means one-time effect, >0 means lasting effect

func _init(card_id: String = "", card_name: String = ""):
	super(card_id, card_name)
	card_type = "support"

func play(game_state, player: String, target = null) -> bool:
	# First check if we can pay the cost
	if not super.play(game_state, player, target):
		return false
	
	print("[SUPPORT_CARD| Playing support card: " + name)
	
	# Apply the effect based on targeting type
	match target_type:
		TargetType.SELF:
			apply_effect_to_target(game_state, player, target if target else get_default_target(game_state, player))
		TargetType.ALLY:
			if target:
				apply_effect_to_target(game_state, player, target)
		TargetType.ENEMY:
			var enemy_player = "opponent" if player == "player" else "player"
			if target:
				apply_effect_to_target(game_state, enemy_player, target)
		TargetType.ALL_ALLIES:
			for ally in get_all_allies(game_state, player):
				apply_effect_to_target(game_state, player, ally)
		TargetType.ALL_ENEMIES:
			var enemy_player = "opponent" if player == "player" else "player"
			for enemy in get_all_enemies(game_state, player):
				apply_effect_to_target(game_state, enemy_player, enemy)
		TargetType.ALL:
			# Apply to all characters
			for ally in get_all_allies(game_state, player):
				apply_effect_to_target(game_state, player, ally)
			
			var enemy_player = "opponent" if player == "player" else "player"
			for enemy in get_all_enemies(game_state, player):
				apply_effect_to_target(game_state, enemy_player, enemy)
	
	return true

func apply_effect_to_target(game_state, player: String, target):
	# Create and apply effect based on effect type
	if effect_duration <= 0:
		# One-time effect
		match effect_type:
			"heal":
				# Heal target
				if target.has_method("heal"):
					target.heal(effect_value)
			"damage":
				# Damage target
				if target.has_method("take_damage"):
					target.take_damage(effect_value)
			"buff":
				# Apply a buff (one-time attribute increase)
				pass
			"debuff":
				# Apply a debuff (one-time attribute decrease)
				pass
	else:
		# Duration-based effect (will be processed each turn)
		game_state.apply_effect(target, effect_type, effect_duration, effect_value, self)

func get_valid_targets(game_state, player: String) -> Array:
	var valid_targets = []
	
	match target_type:
		TargetType.SELF:
			valid_targets.append(get_default_target(game_state, player))
		TargetType.ALLY:
			valid_targets = get_all_allies(game_state, player)
		TargetType.ENEMY:
			valid_targets = get_all_enemies(game_state, player)
		TargetType.ALL_ALLIES, TargetType.ALL_ENEMIES, TargetType.ALL:
			# No target needed as all valid targets will be affected
			valid_targets = []
	
	return valid_targets

func get_default_target(game_state, player: String):
	# Get the active shinobi for a player
	var active_index = game_state.get_active_shinobi(player)
	
	if player == "player":
		# Return player's active shinobi
		return null  # Replace with actual reference once character battle instances are implemented
	else:
		# Return opponent's active shinobi
		return null  # Replace with actual reference once character battle instances are implemented

func get_all_allies(game_state, player: String) -> Array:
	# Return all shinobi belonging to the player
	return []  # Replace with actual shinobi references once implemented

func get_all_enemies(game_state, player: String) -> Array:
	# Return all shinobi belonging to the opponent
	return []  # Replace with actual shinobi references once implemented 