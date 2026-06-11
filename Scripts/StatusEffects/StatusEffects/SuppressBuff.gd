extends StatusEffect
class_name Suppress

func _init(turns: int = 2) -> void:
	effect_name = "Suppress"
	description = "Negate the on_trigger effects of target's passives"
	effect_type = Enums.StatusEffectType.CONTROL
	control_type = Enums.ControlType.SUPPRESS
	base_duration = turns
	
	can_be_cleansed = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
	
func on_apply() -> void:
	if target_unit == null:
		return
	
	# Apply silence control
	target_unit.set_controlled(true, Enums.ControlType.SUPPRESS, source_unit)
	EventBus.log_debug("%s is suppressed!" % target_unit.name, "StatusEffect")

func on_remove() -> void:
	if target_unit == null:
		return
	
	# Remove silence control
	target_unit.set_controlled(false, Enums.ControlType.SUPPRESS, source_unit)
	EventBus.log_debug("%s is no longer suppressed" % target_unit.name, "StatusEffect")
