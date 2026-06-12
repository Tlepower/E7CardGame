extends StatusEffect
class_name Immunity
## Immunity - Prevents all debuffs from being applied, Prevents ar from being reduced, and Prevent CD from being  inceeased

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(turns: int = 2) -> void:
	effect_name = "Immunity"
	description = "Cannot be debuffed, pulled, or CD increased"
	effect_type = Enums.StatusEffectType.IMMUNITY
	base_duration = turns
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
