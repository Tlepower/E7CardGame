extends StatusEffect
class_name DEFBuff
## DEFBuff - Increases target's DEF by a percentage

# ============================================================================
# INITIALIZATION
# ============================================================================

## Percentage increase (e.g., 0.4 = +40% DEF)
var def_increase: float = 0.4

func _init(increase_percent: float = 0.4, turns: int = 2) -> void:
	effect_name = "DEF Up"
	description = "+%.0f%% DEF" % (increase_percent * 100)
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns
	def_increase = increase_percent
	
	# Set stat modifiers
	stat_modifiers = {"def_percent": 1.0 + increase_percent}
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
