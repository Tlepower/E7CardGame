extends CardEffect
class_name DamageEffect
## DamageEffect - Deals damage to target(s)

# ============================================================================
# DAMAGE PROPERTIES
# ============================================================================

## Base damage amount (if not ATK-based)
@export var base_damage: int = 100

## Is this damage based on caster's ATK?
@export var is_atk_based: bool = true

## ATK multiplier if ATK-based (e.g., 1.5 = 150% of ATK)
@export var atk_multiplier: float = 1.0

## Damage type (physical, magical, true)
@export var damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL

## Defense ignore percentage (0.0 - 1.0)
@export_range(0.0, 1.0, 0.01) var def_ignore: float = 0.0

## Additional damage multiplier
@export var damage_multiplier: float = 1.0

## Number of hits (for multi-hit attacks)
@export_range(1, 10) var hit_count: int = 1

## Can this damage crit?
@export var can_crit: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Damage"
	description = "Deal damage to target"
	target_type = Enums.TargetType.SINGLE_ENEMY

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Get damage calculator
	var damage_calc = get_damage_calculator(game_state)
	if damage_calc == null:
		push_error("DamageEffect: DamageCalculator not found")
		return
	
	# Calculate damage amount
	var total_damage = 0
	
	# Execute each hit
	for hit_index in hit_count:
		if not target.is_alive():
			break
		
		var damage_amount = 0
		
		if is_atk_based:
			# ATK-based damage calculation
			damage_amount = damage_calc.calculate_damage(
				caster,
				target,
				atk_multiplier,
				def_ignore,
				damage_multiplier,
				can_crit
			)
		else:
			# Fixed damage
			damage_amount = int(base_damage * damage_multiplier)
		
		# Apply damage
		var is_true = (damage_type == Enums.DamageType.TRUE)
		damage_calc.apply_damage(caster, target, damage_amount, is_true)
		
		total_damage += damage_amount
		
		# Small delay between hits for visual feedback
		if hit_count > 1 and hit_index < hit_count - 1:
			await caster.get_tree().create_timer(0.05).timeout
	
	EventBus.log_debug("%s dealt %d damage to %s" % [caster.name, total_damage, target.name], "DamageEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	var desc = "Deal "
	
	if is_atk_based:
		desc += "%.0f%% ATK" % (atk_multiplier * 100)
	else:
		desc += "%d" % base_damage
	
	if hit_count > 1:
		desc += " damage %dx" % hit_count
	else:
		desc += " damage"
	
	if def_ignore > 0:
		desc += " (ignoring %.0f%% DEF)" % (def_ignore * 100)
	
	return desc
