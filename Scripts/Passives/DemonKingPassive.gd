extends Passive
class_name DemonKingPassive
## DemonKingPassive - Grants death prevention every 6 turns
## When death prevention is consumed, push self AR by 100%

# ============================================================================
# PASSIVE PROPERTIES
# ============================================================================

## Turn counter for death prevention
var turn_counter: int = 0

## Turns required for death prevention
const DEATH_PREVENTION_COOLDOWN: int = 6

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	passive_name = "Immortal Sovereign"
	description = "Every 6 turns, gain death prevention. When consumed, gain +100% Action Readiness."
	passive_type = Enums.PassiveType.TRIGGER
	is_mandatory = false
	can_be_suppressed = false
	
	# Trigger on turn start and death prevention
	trigger_conditions = [
		Enums.TriggerCondition.ON_TURN_START
	]

func on_initialize() -> void:
	# Start with counter at 6 (get death prevention immediately on first turn)
	turn_counter = DEATH_PREVENTION_COOLDOWN
	
	# Connect to death prevention signal
	if not EventBus.death_prevented.is_connected(_on_death_prevented):
		EventBus.death_prevented.connect(_on_death_prevented)

# ============================================================================
# TRIGGER EXECUTION
# ============================================================================

func execute_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> void:
	if condition == Enums.TriggerCondition.ON_TURN_START:
		_on_turn_start()

func _on_turn_start() -> void:
	if owner_unit == null or not owner_unit.is_alive():
		return
	
	# Increment counter
	turn_counter += 1
	
	# Check if we should grant death prevention
	if turn_counter >= DEATH_PREVENTION_COOLDOWN:
		# Check if already has death prevention
		if not owner_unit.get_death_prevention():
			owner_unit.grant_death_prevention()
			EventBus.log_debug("%s gained death prevention from Immortal Sovereign" % owner_unit.name, "Passive")
			EventBus.passive_triggered.emit(owner_unit, passive_name, {"action": "grant_death_prevention"})
			
			# Reset counter
			turn_counter = 0

## Called when death prevention is consumed
func _on_death_prevented(unit: Node) -> void:
	if unit != owner_unit:
		return
	
	EventBus.log_debug("%s death prevented! Triggering Immortal Sovereign AR push" % owner_unit.name, "Passive")
	
	# Push AR by 100%
	owner_unit.modify_ar(100.0)
	
	EventBus.passive_triggered.emit(owner_unit, passive_name, {"action": "ar_push_on_survival"})
	EventBus.log_debug("%s gained +100%% AR from surviving death!" % owner_unit.name, "Passive")

# ============================================================================
# DEACTIVATION
# ============================================================================

func on_deactivate() -> void:
	# Disconnect signal
	if EventBus.death_prevented.is_connected(_on_death_prevented):
		EventBus.death_prevented.disconnect(_on_death_prevented)

# ============================================================================
# QUERIES
# ============================================================================

## Get turns until next death prevention
func get_turns_until_death_prevention() -> int:
	return maxi(0, DEATH_PREVENTION_COOLDOWN - turn_counter)
