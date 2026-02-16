extends StatusEffect
class_name Stun
## Stun - Unit cannot act and turn ends immediately if controlled mid-turn

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(turns: int = 1) -> void:
	effect_name = "Stun"
	description = "Cannot act"
	effect_type = Enums.StatusEffectType.CONTROL
	control_type = Enums.ControlType.STUN
	base_duration = turns
	
	can_be_cleansed = true
	ticks_on_turn_end = true  # Control effects tick at END of turn
	duration_decreases_on_end = true
	stack_type = Enums.StackType.NO_STACK

# ============================================================================
# APPLICATION
# ============================================================================

func on_apply() -> void:
	if target_unit == null:
		return
	
	# Apply stun control
	target_unit.set_controlled(true, Enums.ControlType.STUN, source_unit)
	EventBus.log_debug("%s is stunned!" % target_unit.name, "StatusEffect")

func on_remove() -> void:
	if target_unit == null:
		return
	
	# Remove stun control
	target_unit.set_controlled(false, Enums.ControlType.STUN, source_unit)
	EventBus.log_debug("%s is no longer stunned" % target_unit.name, "StatusEffect")
