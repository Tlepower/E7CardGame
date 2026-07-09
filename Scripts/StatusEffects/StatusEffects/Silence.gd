extends StatusEffect
class_name Silence
## Silence - Cannot use skill cards (basic attack and passives still work)

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(turns: int = 2) -> void:
	effect_name = "Silence"
	description = "Cannot use skills"
	effect_type = Enums.StatusEffectType.CONTROL
	control_type = Enums.ControlType.SILENCE
	base_duration = turns
	
	can_be_cleansed = true
	ticks_on_turn_start = false
	ticks_on_turn_end = true  # Control effects tick at END of turn
	duration_decreases_on_start = false
	duration_decreases_on_end = true
	stack_type = Enums.StackType.NO_STACK

# ============================================================================
# APPLICATION
# ============================================================================

func on_apply() -> void:
	if target_unit == null:
		return
	
	# Apply silence control
	target_unit.set_controlled(true, Enums.ControlType.SILENCE, source_unit)
	EventBus.log_debug("%s is silenced!" % target_unit.name, "StatusEffect")

func on_remove() -> void:
	if target_unit == null:
		return
	
	# Remove silence control
	target_unit.set_controlled(false, Enums.ControlType.SILENCE, source_unit)
	EventBus.log_debug("%s is no longer silenced" % target_unit.name, "StatusEffect")
