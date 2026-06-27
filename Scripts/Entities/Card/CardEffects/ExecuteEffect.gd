extends CardEffect
class_name ExecuteEffect
## ExecuteEffect - Deals massive bonus damage to low HP targets (Reaper execution)

# ============================================================================
# EXECUTE PROPERTIES
# ============================================================================

## Base ATK multiplier
@export var base_atk_multiplier: float = 2.0

## Bonus multiplier against low HP targets
@export var execute_bonus_multiplier: float = 2.0

## HP threshold for execute (e.g., 0.3 = below 30% HP)
@export var hp_threshold: float = 0.3

## Damage type
@export var damage_type: Enums.DamageType = Enums.DamageType.TRUE

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(base_mult: float = 2.0, execute_mult: float = 2.0, threshold: float = 0.3) -> void:
	effect_name = "Execute"
	description = "Massive damage to low HP targets"
	target_type = Enums.TargetType.SINGLE_ENEMY
	base_atk_multiplier = base_mult
	execute_bonus_multiplier = execute_mult
	hp_threshold = threshold

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Get damage calculator
	var damage_calc = get_damage_calculator(game_state)
	if damage_calc == null:
		push_error("ExecuteEffect: DamageCalculator not found")
		return
	
	# Check if target is below HP threshold
	var target_hp_percent = target.get_hp_percent()
	var is_execute = target_hp_percent < hp_threshold
	
	# Calculate multiplier
	var total_multiplier = base_atk_multiplier
	if is_execute:
		total_multiplier += execute_bonus_multiplier
		EventBus.log_debug("EXECUTE! %s HP: %.1f%%" % [target.name, target_hp_percent * 100], "ExecuteEffect")
	
	# Calculate and apply damage (as true damage for reaper theme)
	var caster_stats = caster.get_stats()
	var damage = int(caster_stats.get_effective_atk() * total_multiplier)
	
	damage_calc.apply_damage(caster, target, damage, true)  # True damage
	
	if is_execute:
		EventBus.log_debug("%s executed %s for %d damage!" % [caster.name, target.name, damage], "ExecuteEffect")
	else:
		EventBus.log_debug("%s dealt %d damage to %s" % [caster.name, damage, target.name], "ExecuteEffect")
# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	return "Deal %.0f%% ATK damage (%.0f%% ATK if target below %.0f%% HP)" % [
		base_atk_multiplier * 100,
		(base_atk_multiplier + execute_bonus_multiplier) * 100,
		hp_threshold * 100
	]
