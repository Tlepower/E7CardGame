extends Passive
class_name StealthPassive
## StealthPassive - Automatically grants stealth at the start of each turn

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	passive_name = "Shadow Veil"
	description = "Enter stealth at the start of your turn. Stealth breaks when taking damage."
	passive_type = Enums.PassiveType.TRIGGER
	is_mandatory = false
	can_be_suppressed = false
	
	# Trigger on turn start
	trigger_conditions = [Enums.TriggerCondition.ON_TURN_START]

# ============================================================================
# TRIGGER EXECUTION
# ============================================================================

func execute_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> void:
	if condition != Enums.TriggerCondition.ON_TURN_START:
		return
	
	if owner_unit == null or not owner_unit.is_alive():
		return
	
	# Check if already has stealth
	if owner_unit.has_status_effect("Stealth"):
		EventBus.log_debug("%s already in stealth" % owner_unit.name, "Passive")
		return
	
	# Grant stealth
	var stealth = Stealth.new()
	stealth.is_permanent = true
	stealth.duration_decreases_on_start = false # Doesn't decrease turn 
	stealth.initialize(owner_unit, owner_unit)
	owner_unit.apply_status_effect(stealth)
	
	EventBus.log_debug("%s activated Shadow Veil - entered stealth" % owner_unit.name, "Passive")
	EventBus.passive_triggered.emit(owner_unit, passive_name, data)
