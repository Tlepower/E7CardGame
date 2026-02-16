extends StatusEffect
class_name ATKDebuff
## ATKDebuff - Decreases target's ATK by a percentage

# ============================================================================
# INITIALIZATION
# ============================================================================

## Percentage decrease (e.g., 0.3 = -30% ATK)
var atk_decrease: float = 0.3

func _init(decrease_percent: float = 0.3, turns: int = 2) -> void:
	effect_name = "ATK Down"
	description = "-%.0f%% ATK" % (decrease_percent * 100)
	effect_type = Enums.StatusEffectType.DEBUFF
	base_duration = turns
	atk_decrease = decrease_percent
	
	# Set stat modifiers
	stat_modifiers = {"atk_percent": 1.0 - decrease_percent}
	
	can_be_cleansed = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
