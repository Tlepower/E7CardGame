extends StatusEffect
class_name Invincibility
## Invincibility - Prevents all damage (sets damage taken multiplier to 0)

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(turns: int = 1) -> void:
	effect_name = "Invincibility"
	description = "Cannot take damage"
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns
	
	# Set damage taken to 0
	stat_modifiers = {"damage_taken_multiplier": 0.0}
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
