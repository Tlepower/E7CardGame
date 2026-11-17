extends Passive
class_name EvasionPassive
## EvasionPassive - Grants innate evasion chance at battle start

# ============================================================================
# PASSIVE PROPERTIES
# ============================================================================

## Base evasion chance
const BASE_EVASION_CHANCE: float = 0.25  # 25% base evasion
const BOUNS_EVASION_CHANCE: float = 0.10 # 10% bouns evasion, 35 total evasion

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	passive_name = "Graceful Footwork"
	description = "25% chance to evade attacks. Gain +10% evasion when below 50% HP."
	passive_type = Enums.PassiveType.TRIGGER
	is_mandatory = false
	can_be_suppressed = false
	
	trigger_conditions = [
		Enums.TriggerCondition.ON_BATTLE_START,
		Enums.TriggerCondition.ON_TURN_START
	]

# ============================================================================
# TRIGGER EXECUTION
# ============================================================================

func execute_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> void:
	if condition == Enums.TriggerCondition.ON_BATTLE_START:
		_on_battle_start()
	elif condition == Enums.TriggerCondition.ON_TURN_START:
		_update_evasion()

func _on_battle_start() -> void:
	if owner_unit == null:
		return
	
	# Grant base evasion chance
	stat_modifiers = {"Evasion" : BASE_EVASION_CHANCE}
	
	EventBus.log_debug("%s gained %.0f%% evasion from Graceful Footwork" % [
		owner_unit.name, 
		BASE_EVASION_CHANCE * 100
	], "Passive")
	EventBus.passive_triggered.emit(owner_unit, passive_name, {"evasion_chance": BASE_EVASION_CHANCE})

func _update_evasion() -> void:
	if owner_unit == null:
		return
	
	var bonus_evasion = 0.0
	# Bonus evasion when wounded
	if owner_unit.get_hp_percent() < 0.5:
		bonus_evasion = BOUNS_EVASION_CHANCE 
	
	var total_evasion = BASE_EVASION_CHANCE + bonus_evasion
	var BaseEvasion = stat_modifiers["Evasion"] 
	stat_modifiers = {"Evasion" : BaseEvasion + bonus_evasion}
	apply_aura_to_unit(owner_unit)
	
	if bonus_evasion > 0:
		EventBus.log_debug("%s evasion increased to %.0f%% (wounded)" % [
			owner_unit.name,
			total_evasion * 100
		], "Passive")
