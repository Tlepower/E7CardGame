extends StatusEffect
class_name DEFDebuff
## DEFDebuff - Decreases target's DEF by a percentage

# ============================================================================
# INITIALIZATION
# ============================================================================

## Percentage decrease (e.g., 0.4 = -40% DEF)
var def_decrease: float = 0.4

func _init(decrease_percent: float = 0.4, turns: int = 2) -> void:
	effect_name = "DEF Down"
	description = "-%.0f%% DEF" % (decrease_percent * 100)
	effect_type = Enums.StatusEffectType.DEBUFF
	base_duration = turns
	def_decrease = decrease_percent
	
	# Set stat modifiers
	stat_modifiers = {"def_percent": 1.0 - decrease_percent}
	
	can_be_cleansed = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
