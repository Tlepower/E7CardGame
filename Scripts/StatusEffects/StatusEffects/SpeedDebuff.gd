extends StatusEffect
class_name SpeedDebuff
## SpeedDebuff - Decreases target's Speed by a percentage

# ============================================================================
# INITIALIZATION
# ============================================================================

## Percentage decrease (e.g., 0.25 = -25% Speed)
var speed_decrease: float = 0.25

func _init(decrease_percent: float = 0.25, turns: int = 2) -> void:
	effect_name = "Speed Down"
	description = "-%.0f%% Speed" % (decrease_percent * 100)
	effect_type = Enums.StatusEffectType.DEBUFF
	base_duration = turns
	speed_decrease = decrease_percent
	
	# Set stat modifiers
	stat_modifiers = {"speed_percent": 1.0 - decrease_percent}
	
	can_be_cleansed = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
