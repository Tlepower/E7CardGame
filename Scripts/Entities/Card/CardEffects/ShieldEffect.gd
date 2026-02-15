extends CardEffect
class_name ShieldEffect
## ShieldEffect - Applies a shield/barrier to target(s)

# ============================================================================
# SHIELD PROPERTIES
# ============================================================================

## Base shield amount
@export var base_shield: int = 200

## Is shield based on caster's ATK?
@export var is_atk_based: bool = false

## ATK multiplier if ATK-based (e.g., 1.0 = 100% of ATK)
@export var atk_multiplier: float = 1.0

## Is shield based on target's max HP?
@export var is_max_hp_based: bool = false

## Max HP percentage if max HP-based (e.g., 0.15 = 15% of max HP)
@export_range(0.0, 1.0, 0.01) var max_hp_percent: float = 0.15

## Duration in turns
@export_range(1, 10) var duration: int = 2

## Shield multiplier
@export var shield_multiplier: float = 1.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Shield"
	description = "Apply a shield to target"
	target_type = Enums.TargetType.SINGLE_ALLY

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Calculate shield amount
	var shield_amount = 0
	
	if is_max_hp_based:
		# Based on target's max HP
		var target_stats = target.get_stats()
		shield_amount = int(target_stats.max_hp * max_hp_percent * shield_multiplier)
	elif is_atk_based:
		# Based on caster's ATK
		var caster_stats = caster.get_stats()
		shield_amount = int(caster_stats.get_effective_atk() * atk_multiplier * shield_multiplier)
	else:
		# Fixed shield amount
		shield_amount = int(base_shield * shield_multiplier)
	
	# Create shield status effect
	var shield_effect = StatusEffect.new()
	shield_effect.effect_name = "Shield"
	shield_effect.description = "Absorbs damage"
	shield_effect.effect_type = Enums.StatusEffectType.SHIELD
	shield_effect.base_duration = duration
	shield_effect.base_shield_amount = shield_amount
	shield_effect.can_be_dispelled = true
	shield_effect.ticks_on_turn_start = true
	shield_effect.duration_decreases_on_start = true
	
	# Initialize and apply
	shield_effect.initialize(caster, target, duration)
	
	# Get status effect system
	var status_system = get_status_effect_system(game_state)
	if status_system != null:
		status_system.apply_effect(target, shield_effect)
	else:
		# Fallback: apply directly
		target.apply_status_effect(shield_effect)
	
	EventBus.log_debug("%s applied %d shield to %s" % [caster.name, shield_amount, target.name], "ShieldEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	var desc = "Apply shield for "
	
	if is_max_hp_based:
		desc += "%.0f%% of target's max HP" % (max_hp_percent * 100)
	elif is_atk_based:
		desc += "%.0f%% ATK" % (atk_multiplier * 100)
	else:
		desc += "%d" % base_shield
	
	desc += " for %d turn%s" % [duration, "s" if duration > 1 else ""]
	
	return desc
