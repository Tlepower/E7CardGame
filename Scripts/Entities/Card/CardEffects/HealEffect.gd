extends CardEffect
class_name HealEffect
## HealEffect - Heals target(s)

# ============================================================================
# HEAL PROPERTIES
# ============================================================================

## Base heal amount (if not ATK-based)
@export var base_heal: int = 100

## Is this heal based on caster's ATK?
@export var is_atk_based: bool = false

## ATK multiplier if ATK-based (e.g., 0.5 = 50% of ATK)
@export var atk_multiplier: float = 0.5

## Is this heal based on target's max HP?
@export var is_max_hp_based: bool = false

## Max HP percentage if max HP-based (e.g., 0.2 = 20% of max HP)
@export_range(0.0, 1.0, 0.01) var max_hp_percent: float = 0.2

## Additional heal multiplier
@export var heal_multiplier: float = 1.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Heal"
	description = "Heal target"
	target_type = Enums.TargetType.SINGLE_ALLY

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	var heal_amount = 0
	
	# Calculate heal amount
	if is_max_hp_based:
		# Based on target's max HP
		var target_stats = target.get_stats()
		heal_amount = int(target_stats.max_hp * max_hp_percent * heal_multiplier)
	elif is_atk_based:
		# Based on caster's ATK
		var caster_stats = caster.get_stats()
		heal_amount = int(caster_stats.get_effective_atk() * atk_multiplier * heal_multiplier)
	else:
		# Fixed heal amount
		heal_amount = int(base_heal * heal_multiplier)
	
	# Apply heal
	target.heal(heal_amount, caster)
	
	EventBus.log_debug("%s healed %s for %d HP" % [caster.name, target.name, heal_amount], "HealEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	var desc = "Heal "
	
	if is_max_hp_based:
		desc += "%.0f%% of target's max HP" % (max_hp_percent * 100)
	elif is_atk_based:
		desc += "%.0f%% ATK" % (atk_multiplier * 100)
	else:
		desc += "%d HP" % base_heal
	
	return desc
