extends Passive
class_name ReaperPassive
## ReaperPassive - Feeds on the dying
## Gains lifesteal when enemies fall below 50% HP
## All attacks have built-in 30% lifesteal

# ============================================================================
# PASSIVE PROPERTIES
# ============================================================================

## Base lifesteal percentage
const BASE_LIFESTEAL: float = 0.30

## Has lifesteal buff been granted this battle?
var has_granted_buff: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	passive_name = "Feast of the Dying"
	description = "Gain 30% lifesteal on all attacks. When an enemy falls below 50% HP, gain +25% lifesteal for 3 turns."
	passive_type = Enums.PassiveType.TRIGGER
	is_mandatory = false
	can_be_suppressed = false
	
	# Trigger on damage dealt and HP threshold
	trigger_conditions = [
		Enums.TriggerCondition.ON_BATTLE_START
	]

func on_initialize() -> void:
	# Connect to damage dealt signal for lifesteal
	if not EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.connect(_on_damage_dealt)
	
	# Connect to HP threshold for bonus lifesteal
	if not EventBus.damage_dealt.is_connected(_on_any_damage_dealt):
		EventBus.damage_dealt.connect(_on_any_damage_dealt)

# ============================================================================
# TRIGGER EXECUTION
# ============================================================================

func execute_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> void:
	if condition == Enums.TriggerCondition.ON_BATTLE_START:
		_on_battle_start()

func _on_battle_start() -> void:
	if owner_unit == null:
		return
	
	# Grant base lifesteal buff
	var lifesteal = Lifesteal.new(BASE_LIFESTEAL, 99)  # Permanent lifesteal
	lifesteal.is_permanent = true
	lifesteal.initialize(owner_unit, owner_unit)
	owner_unit.apply_status_effect(lifesteal)
	
	EventBus.log_debug("%s gained permanent %.0f%% lifesteal" % [owner_unit.name, BASE_LIFESTEAL * 100], "Passive")

# ============================================================================
# LIFESTEAL APPLICATION
# ============================================================================

## Called when Reaper Vampire deals damage
func _on_damage_dealt(source: Node, target: Node, amount: int, is_true: bool) -> void:
	# Check if our unit dealt damage
	if source != owner_unit:
		return
	
	# Lifesteal is handled by the Lifesteal status effect
	# This is just here for potential future expansion

## Called when any damage is dealt (to check enemy HP)
func _on_any_damage_dealt(source: Node, target: Node, amount: int, is_true: bool) -> void:
	# Only trigger once per battle when an enemy falls below 50%
	if has_granted_buff:
		return
	
	if target == null or not target.is_alive():
		return
	
	# Check if target is an enemy
	if target.team == owner_unit.team:
		return
	
	# Check if target is below 50% HP
	if target.get_hp_percent() < 0.5:
		_grant_bonus_lifesteal()
		has_granted_buff = true

## Grant bonus lifesteal when enemy falls below 50%
func _grant_bonus_lifesteal() -> void:
	if owner_unit == null:
		return
	
	# Grant bonus lifesteal
	var bonus_lifesteal = Lifesteal.new(0.25, 3)  # +25% lifesteal for 3 turns
	bonus_lifesteal.initialize(owner_unit, owner_unit)
	owner_unit.apply_status_effect(bonus_lifesteal)
	
	EventBus.log_debug("%s smells blood! Gained bonus lifesteal" % owner_unit.name, "Passive")
	EventBus.passive_triggered.emit(owner_unit, passive_name, {"bonus_lifesteal": true})

# ============================================================================
# DEACTIVATION
# ============================================================================

func on_deactivate() -> void:
	# Disconnect signals
	if EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.disconnect(_on_damage_dealt)
	
	if EventBus.damage_dealt.is_connected(_on_any_damage_dealt):
		EventBus.damage_dealt.disconnect(_on_any_damage_dealt)
