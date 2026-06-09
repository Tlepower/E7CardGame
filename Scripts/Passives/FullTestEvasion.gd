extends Passive
class_name FullTestEvasion

const BASE_EVASION_CHANCE: float = 1.0

func _init() -> void:
	passive_name = "Full Evasion"
	description = "To test evasion fully. set evasion to 100%"
	passive_type = Enums.PassiveType.AURA
	is_mandatory = false
	can_be_suppressed = false
	
	trigger_conditions = [Enums.TriggerCondition.ON_TURN_START]
	

func on_initialize() -> void:
	is_active = false
	activate()
	
func on_activate() -> void:
	# if condition == Enums.TriggerCondition.ON_TURN_START:
	if owner_unit == null:
		return 
		
	# grant 100% evasion
	stat_modifiers = {"evasion" : BASE_EVASION_CHANCE}
		
	EventBus.log_debug("%s gained %.0f%% evasion from Graceful Footwork" % [
		owner_unit.name, 
		BASE_EVASION_CHANCE * 100
	], "Passive")
	EventBus.passive_triggered.emit(owner_unit, passive_name, {"evasion_chance": BASE_EVASION_CHANCE})
