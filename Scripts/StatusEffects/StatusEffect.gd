extends Resource
class_name StatusEffect
## StatusEffect - Base class for all status effects (buffs, debuffs, control, etc.)
## Status effects have duration, can stack, and tick at turn start or end

# ============================================================================
# BASIC PROPERTIES
# ============================================================================

## Name of the status effect
@export var effect_name: String = "Status Effect"

## Description of what it does
@export_multiline var description: String = ""

## Type of status effect
@export var effect_type: Enums.StatusEffectType = Enums.StatusEffectType.BUFF

## Icon for UI display
@export var icon: Texture2D

# ============================================================================
# DURATION & STACKING
# ============================================================================

## Remaining duration in turns
var duration: int = 1

## Initial duration when applied
@export var base_duration: int = 1

## How this effect stacks with itself
@export var stack_type: Enums.StackType = Enums.StackType.NO_STACK

## Current stack count
var stack_count: int = 1

## Maximum stack count (0 = unlimited)
@export var max_stacks: int = 0

# ============================================================================
# TICK BEHAVIOR
# ============================================================================

## Does this effect tick at turn start?
@export var ticks_on_turn_start: bool = true

## Does this effect tick at turn end?
@export var ticks_on_turn_end: bool = false

## Does duration decrease on turn start?
@export var duration_decreases_on_start: bool = true

## Does duration decrease on turn end?
@export var duration_decreases_on_end: bool = false

# ============================================================================
# SOURCE & TARGET
# ============================================================================

## Unit that applied this effect
var source_unit: Node = null

## Unit this effect is applied to
var target_unit: Node = null

# ============================================================================
# DISPEL/CLEANSE
# ============================================================================

## Can this effect be dispelled (if it's a buff)?
@export var can_be_dispelled: bool = true

## Can this effect be cleansed (if it's a debuff)?
@export var can_be_cleansed: bool = true

## Is this effect permanent (cannot be removed except by death)?
@export var is_permanent: bool = false

# ============================================================================
# STAT MODIFICATIONS (for buff/debuff effects)
# ============================================================================

## Stat modifiers applied by this effect
## Format: {"atk_percent": 1.2, "def_percent": 0.8} = +20% ATK, -20% DEF
@export var stat_modifiers: Dictionary = {}

# ============================================================================
# CONTROL PROPERTIES (for control effects)
# ============================================================================

## Type of control (if this is a control effect)
@export var control_type: Enums.ControlType = Enums.ControlType.STUN

# ============================================================================
# DOT PROPERTIES (for damage over time effects)
# ============================================================================

## Damage dealt per tick
@export var damage_per_tick: int = 0

## Is this DOT based on caster's ATK?
@export var is_atk_based: bool = false

## ATK multiplier if ATK-based (e.g., 0.3 = 30% of caster ATK per tick)
@export var atk_multiplier: float = 0.0

# ============================================================================
# SHIELD PROPERTIES (for shield effects)
# ============================================================================

## Shield strength (damage absorbed)
var shield_amount: int = 0

## Base shield amount
@export var base_shield_amount: int = 0

# ============================================================================
# INITIALIZATION
# ============================================================================

## Initialize the status effect
func initialize(source: Node, target: Node, initial_duration: int = -1) -> void:
	source_unit = source
	target_unit = target
	duration = initial_duration if initial_duration > 0 else base_duration
	stack_count = 1
	
	# Initialize shield amount if this is a shield effect
	if effect_type == Enums.StatusEffectType.SHIELD:
		shield_amount = base_shield_amount

# ============================================================================
# APPLICATION & REMOVAL
# ============================================================================

## Called when effect is first applied to a unit
func apply(target: Node) -> void:
	target_unit = target
	
	# Apply stat modifiers
	if not stat_modifiers.is_empty():
		_apply_stat_modifiers()
	
	# Apply control if this is a control effect
	if effect_type == Enums.StatusEffectType.CONTROL:
		target.set_controlled(true, control_type, source_unit)
	
	# Custom application logic
	on_apply()

## Called when effect is removed from a unit
func remove(target: Node) -> void:
	# Remove stat modifiers
	if not stat_modifiers.is_empty():
		_remove_stat_modifiers()
	
	# Remove control if this is a control effect
	if effect_type == Enums.StatusEffectType.CONTROL:
		target.set_controlled(false, control_type, source_unit)
	
	# Custom removal logic
	on_remove()

## Override in subclasses for custom application logic
func on_apply() -> void:
	pass

## Override in subclasses for custom removal logic
func on_remove() -> void:
	pass

# ============================================================================
# TICK BEHAVIOR
# ============================================================================

## Called each turn (start or end depending on settings)
func tick(target: Node) -> void:
	target_unit = target
	
	# Execute tick effect
	on_tick()
	
	# Handle DOT damage
	if effect_type == Enums.StatusEffectType.DOT:
		_apply_dot_damage()
	
	# Decrease duration if configured
	var should_decrease_duration = false
	if ticks_on_turn_start and duration_decreases_on_start:
		should_decrease_duration = true
	elif ticks_on_turn_end and duration_decreases_on_end:
		should_decrease_duration = true
	
	if should_decrease_duration and not is_permanent:
		duration -= 1

## Override in subclasses for custom tick behavior
func on_tick() -> void:
	pass

# ============================================================================
# STACKING & REFRESH
# ============================================================================

## Refresh duration when same effect is reapplied
func refresh_duration(new_duration: int) -> void:
	match stack_type:
		Enums.StackType.NO_STACK:
			# Just refresh duration
			duration = new_duration
		
		Enums.StackType.STACK_COUNT:
			# Increase stack count and refresh duration
			if max_stacks == 0 or stack_count < max_stacks:
				stack_count += 1
			duration = new_duration
		
		Enums.StackType.STACK_DURATION:
			# Add to duration
			duration += new_duration
		
		Enums.StackType.INDEPENDENT:
			# This shouldn't happen - independent effects don't refresh
			pass
	
	on_refresh()

## Override in subclasses for custom refresh behavior
func on_refresh() -> void:
	pass

# ============================================================================
# STAT MODIFIER HELPERS
# ============================================================================

## Apply stat modifiers to target
func _apply_stat_modifiers() -> void:
	if target_unit == null or not target_unit.has_method("get_stats"):
		return
	
	var stats = target_unit.get_stats()
	
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
			"damage_multiplier":
				stats.damage_multiplier *= modifier_value
			"damage_taken_multiplier":
				stats.damage_taken_multiplier *= modifier_value

## Remove stat modifiers from target
func _remove_stat_modifiers() -> void:
	if target_unit == null or not target_unit.has_method("get_stats"):
		return
	
	var stats = target_unit.get_stats()
	
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
			"damage_multiplier":
				stats.damage_multiplier /= modifier_value
			"damage_taken_multiplier":
				stats.damage_taken_multiplier /= modifier_value

# ============================================================================
# DOT DAMAGE
# ============================================================================

## Apply damage over time
func _apply_dot_damage() -> void:
	if target_unit == null or not target_unit.is_alive():
		return
	
	var damage = damage_per_tick
	
	# Calculate ATK-based damage
	if is_atk_based and source_unit != null:
		var source_stats = source_unit.get_stats()
		damage = int(source_stats.get_effective_atk() * atk_multiplier)
	
	if damage > 0:
		target_unit.take_damage(damage, true)  # DOT is usually true damage
		EventBus.log_debug("%s takes %d DOT damage from %s" % [target_unit.name, damage, effect_name], "StatusEffect")

# ============================================================================
# QUERIES
# ============================================================================

## Check if this is a positive effect (buff/shield/immunity)
func is_positive() -> bool:
	return Enums.is_positive_effect(effect_type)

## Check if this is a negative effect (debuff/control/DOT)
func is_negative() -> bool:
	return Enums.is_negative_effect(effect_type)

## Check if effect has expired
func has_expired() -> bool:
	return duration <= 0 and not is_permanent

## Get display text for UI
func get_display_text() -> String:
	var text = effect_name
	
	if stack_count > 1:
		text += " x%d" % stack_count
	
	if not is_permanent:
		text += " (%d)" % duration
	
	return text

## Get tooltip description
func get_tooltip() -> String:
	var tooltip = description
	
	if not stat_modifiers.is_empty():
		tooltip += "\n\nModifiers:"
		for stat_name in stat_modifiers:
			var value = stat_modifiers[stat_name]
			tooltip += "\n• %s: %+.0f%%" % [stat_name, (value - 1.0) * 100]
	
	if damage_per_tick > 0:
		tooltip += "\n• Deals %d damage per turn" % damage_per_tick
	
	return tooltip

## Create a duplicate of this effect
func duplicate_effect() -> StatusEffect:
	var new_effect = duplicate(true)
	new_effect.duration = base_duration
	new_effect.stack_count = 1
	new_effect.source_unit = source_unit
	new_effect.target_unit = null
	return new_effect
