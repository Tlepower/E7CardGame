extends StatusEffect
class_name SpeedBuff
## SpeedBuff - Increases target's Speed by a percentage

# ============================================================================
# INITIALIZATION
# ============================================================================

## Percentage increase (e.g., 0.25 = +25% Speed)
var speed_increase: float = 0.25

func _init(increase_percent: float = 0.25, turns: int = 2) -> void:
	effect_name = "Speed Up"
	description = "+%.0f%% Speed" % (increase_percent * 100)
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns
	speed_increase = increase_percent
	
	# Set stat modifiers
	stat_modifiers = {"speed_percent": 1.0 + increase_percent}
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
