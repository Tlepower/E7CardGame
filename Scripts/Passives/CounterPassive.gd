extends Passive
class_name CounterPassive
## CounterPassive - Grants innate counter chance at battle start

# ============================================================================
# PASSIVE PROPERTIES
# ============================================================================

## Base counter chance
const BASE_COUNTER_CHANCE: float = 0.3  # 30% base counter

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	passive_name = "Retaliation"
	description = "30% chance to counter attacks with basic attack. Gains +10% counter per ally under 50% HP."
	passive_type = Enums.PassiveType.TRIGGER
	is_mandatory = false
	can_be_suppressed = false
	
	trigger_conditions = [Enums.TriggerCondition.ON_BATTLE_START]

# ============================================================================
# TRIGGER EXECUTION
# ============================================================================

func execute_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> void:
	if condition == Enums.TriggerCondition.ON_BATTLE_START:
		_on_battle_start()

func _on_battle_start() -> void:
	if owner_unit == null:
		return
	
	# Grant base counter chance
	owner_unit.set_counter_chance(BASE_COUNTER_CHANCE)
	
	EventBus.log_debug("%s gained %.0f%% counter from Retaliation passive" % [
		owner_unit.name, 
		BASE_COUNTER_CHANCE * 100
	], "Passive")
	EventBus.passive_triggered.emit(owner_unit, passive_name, {"counter_chance": BASE_COUNTER_CHANCE})

# ============================================================================
# DYNAMIC COUNTER (future expansion)
# ============================================================================

## Could update counter chance based on conditions
func update_counter_chance() -> void:
	if owner_unit == null:
		return
	
	var bonus_counter = 0.0
	
	# Check wounded allies (for future expansion)
	# For each ally under 50% HP, gain +10% counter
	# This would require battle_manager access
	
	var total_counter = BASE_COUNTER_CHANCE + bonus_counter
	owner_unit.set_counter_chance(total_counter)
