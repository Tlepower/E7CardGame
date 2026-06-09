extends Resource
class_name Passive
## Passive - Base class for unit passive abilities
## Passives can be trigger-based, aura-based, or both

# ============================================================================
# PASSIVE PROPERTIES
# ============================================================================

## Name of the passive ability
@export var passive_name: String = "Unnamed Passive"

## Description of what the passive does
@export_multiline var description: String = ""

## Type of passive (trigger, aura, conditional, mandatory)
@export var passive_type: Enums.PassiveType = Enums.PassiveType.TRIGGER

## Is this a mandatory trigger? (interrupts effect resolution)
@export var is_mandatory: bool = false

## Can this passive be suppressed/ignored?
@export var can_be_suppressed: bool = true

## Icon for UI display
@export var icon: Texture2D

# ============================================================================
# TRIGGER CONDITIONS
# ============================================================================

## What events trigger this passive (if trigger-based)
@export var trigger_conditions: Array[Enums.TriggerCondition] = []

# ============================================================================
# AURA PROPERTIES (for stat modification passives)
# ============================================================================

## If this is an aura passive, what stats does it modify?
## Format: {"atk_percent": 1.2, "speed_percent": 1.1} = +20% ATK, +10% Speed
@export var stat_modifiers: Dictionary = {}

## Does the aura affect allies?
@export var affects_allies: bool = false

## Does the aura affect self?
@export var affects_self: bool = true

# ============================================================================
# CONDITIONAL PROPERTIES
# ============================================================================

## Condition that must be met for passive to be active
## Examples: "hp_below_50", "ally_count_below_3", "enemy_has_buff"
@export var activation_condition: String = ""

# ============================================================================
# REFERENCE TO OWNER
# ============================================================================

## The unit that owns this passive
var owner_unit: Node = null

## Is the passive currently active?
var is_active: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

## Called when passive is attached to a unit
func initialize(unit: Node) -> void:
	owner_unit = unit
	is_active = true
	on_initialize()

## Override in subclasses for custom initialization
func on_initialize() -> void:
	pass

# ============================================================================
# ACTIVATION/DEACTIVATION
# ============================================================================

## Activate the passive (apply aura effects, etc.)
func activate() -> void:
	if is_active:
		return
	
	is_active = true
	on_activate()
	
	# Apply aura stat modifiers if applicable
	if passive_type == Enums.PassiveType.AURA and affects_self:
		apply_aura_to_unit(owner_unit)

## Deactivate the passive (remove aura effects, etc.)
func deactivate() -> void:
	if not is_active:
		return
	
	is_active = false
	on_deactivate()
	
	# Remove aura stat modifiers if applicable
	if passive_type == Enums.PassiveType.AURA and affects_self:
		remove_aura_from_unit(owner_unit)

## Override in subclasses for custom activation
func on_activate() -> void:
	pass

## Override in subclasses for custom deactivation
func on_deactivate() -> void:
	pass

# ============================================================================
# TRIGGER HANDLING
# ============================================================================

## Called when a trigger condition is met
## Returns true if the passive should interrupt current effect resolution
func on_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> bool:
	if not is_active:
		return false
	
	if not can_trigger(condition, data):
		return false
	
	# Check if this trigger condition is valid for this passive
	if trigger_conditions.is_empty() or condition not in trigger_conditions:
		return false
	
	# Execute the trigger effect
	execute_trigger(condition, data)
	
	# Return true if this is a mandatory trigger (interrupts resolution)
	return is_mandatory

## Override in subclasses to implement trigger logic
func execute_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> void:
	pass

## Check if the passive can trigger (for conditional passives)
func can_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> bool:
	# Check activation condition if this is a conditional passive
	if passive_type == Enums.PassiveType.CONDITIONAL:
		return check_activation_condition()
	
	return true

# ============================================================================
# AURA FUNCTIONS
# ============================================================================

## Apply aura stat modifiers to a unit
func apply_aura_to_unit(unit: Node) -> void:
	if unit == null or not unit.has_method("get_stats"):
		return
	
	var stats = unit.get_stats()
	
	for stat_name in stat_modifiers:
		var modifier_value = stat_modifiers[stat_name]
		match stat_name:
			"atk_percent":
				stats.modify_atk_percent(modifier_value)
			"def_percent":
				stats.modify_def_percent(modifier_value)
			"speed_percent":
				stats.modify_speed_percent(modifier_value)
			"crit_rate":
				stats.add_crit_rate(modifier_value)
			"crit_damage":
				stats.add_crit_damage(modifier_value)
			"effectiveness":
				stats.add_effectiveness(modifier_value)
			"effect_resistance":
				stats.add_effect_resistance(modifier_value)
			"counter_rate":
				stats.add_counter_rate(modifier_value)
			"evasion":
				stats.add_evasion(modifier_value)

## Remove aura stat modifiers from a unit
func remove_aura_from_unit(unit: Node) -> void:
	if unit == null or not unit.has_method("get_stats"):
		return
	
	var stats = unit.get_stats()
	
	for stat_name in stat_modifiers:
		var modifier_value = stat_modifiers[stat_name]
		match stat_name:
			"atk_percent":
				stats.modify_atk_percent(1.0 / modifier_value)  # Reverse multiplication
			"def_percent":
				stats.modify_def_percent(1.0 / modifier_value)
			"speed_percent":
				stats.modify_speed_percent(1.0 / modifier_value)
			"crit_rate":
				stats.add_crit_rate(-modifier_value)  # Subtract
			"crit_damage":
				stats.add_crit_damage(-modifier_value)
			"effectiveness":
				stats.add_effectiveness(-modifier_value)
			"effect_resistance":
				stats.add_effect_resistance(-modifier_value)
			"counter_rate":
				stats.add_counter_rate(-modifier_value)
			"evasion":
				stats.add_evasion(-modifier_value)

# ============================================================================
# CONDITIONAL CHECKS
# ============================================================================

## Check if activation condition is met (override in subclasses or use string parsing)
func check_activation_condition() -> bool:
	if activation_condition.is_empty():
		return true
	
	# Basic string parsing for common conditions
	if activation_condition.begins_with("hp_below_"):
		var threshold = float(activation_condition.trim_prefix("hp_below_"))
		return owner_unit.get_hp_percent() < threshold / 100.0
	
	if activation_condition.begins_with("hp_above_"):
		var threshold = float(activation_condition.trim_prefix("hp_above_"))
		return owner_unit.get_hp_percent() > threshold / 100.0
	
	# Override this function for complex conditions
	return true

# ============================================================================
# UTILITY
# ============================================================================

## Check if the owner unit can perform out-of-turn actions
func can_perform_out_of_turn_action() -> bool:
	if owner_unit == null:
		return false
	
	# Cannot perform out-of-turn actions if controlled
	if owner_unit.has_method("is_controlled") and owner_unit.is_controlled():
		return false
	
	return true

## Create a duplicate of this passive
func duplicate_passive() -> Passive:
	return duplicate(true)
