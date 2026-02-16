extends StatusEffect
class_name ATKBuff
## ATKBuff - Increases target's ATK by a percentage

# ============================================================================
# INITIALIZATION
# ============================================================================

## Percentage increase (e.g., 0.3 = +30% ATK)
var atk_increase: float = 0.3

func _init(increase_percent: float = 0.3, turns: int = 2) -> void:
	effect_name = "ATK Up"
	description = "+%.0f%% ATK" % (increase_percent * 100)
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns
	atk_increase = increase_percent
	
	# Set stat modifiers
	stat_modifiers = {"atk_percent": 1.0 + increase_percent}
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK  # Refresh duration instead

# ============================================================================
# REFRESH BEHAVIOR
# ============================================================================

func on_refresh() -> void:
	EventBus.log_debug("ATK Up refreshed on %s" % target_unit.name, "StatusEffect")
