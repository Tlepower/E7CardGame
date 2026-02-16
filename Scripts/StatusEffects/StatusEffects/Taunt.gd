extends StatusEffect
class_name Taunt
## Taunt - Forces enemies to target the taunting unit

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(turns: int = 2) -> void:
	effect_name = "Provoke"
	description = "Forces enemies to attack this unit"
	effect_type = Enums.StatusEffectType.CONTROL
	control_type = Enums.ControlType.TAUNT
	base_duration = turns
	
	can_be_cleansed = true
	ticks_on_turn_end = true  # Control effects tick at END of turn
	duration_decreases_on_end = true
	stack_type = Enums.StackType.NO_STACK

# ============================================================================
# APPLICATION
# ============================================================================

func on_apply() -> void:
	if target_unit == null or source_unit == null:
		return
	
	# Apply taunt - enemies targeting target_unit will be redirected to source_unit
	# Note: This is applied TO the unit being taunted, BY the taunter
	# The taunter is the source_unit
	# We actually need to apply this TO enemy units
	EventBus.log_debug("%s is taunting enemies!" % source_unit.name, "StatusEffect")
	
	# Mark that this unit (source) is taunting
	# This will be checked by TargetingSystem

func on_remove() -> void:
	if target_unit == null:
		return
	
	EventBus.log_debug("%s taunt ended" % source_unit.name, "StatusEffect")
