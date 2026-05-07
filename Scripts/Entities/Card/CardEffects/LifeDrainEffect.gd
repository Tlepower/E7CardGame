extends CardEffect
class_name LifeDrainEffect
## LifeDrainEffect - Deal damage and heal caster for a percentage of damage dealt

# ============================================================================
# DAMAGE PROPERTIES
# ============================================================================

## ATK multiplier for damage
@export var atk_multiplier: float = 1.5

## Percentage of damage converted to healing (e.g., 0.5 = 50%)
@export var drain_percent: float = 0.5

## Damage type
@export var damage_type: Enums.DamageType = Enums.DamageType.MAGICAL

## Can crit?
@export var can_crit: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(atk_mult: float = 1.5, drain_pct: float = 0.5) -> void:
	effect_name = "Life Drain"
	description = "Deal damage and heal for %.0f%% of damage dealt" % (drain_pct * 100)
	target_type = Enums.TargetType.SINGLE_ENEMY
	atk_multiplier = atk_mult
	drain_percent = drain_pct

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Get damage calculator
	var damage_calc = get_damage_calculator(game_state)
	if damage_calc == null:
		push_error("LifeDrainEffect: DamageCalculator not found")
		return
	
	# Calculate damage
	var damage = damage_calc.calculate_damage(
		caster,
		target,
		atk_multiplier,
		0.0,  # No def ignore
		1.0,  # No damage multiplier
		can_crit
	)
	
	# Apply damage
	damage_calc.apply_damage(caster, target, damage, false)
	
	# Heal caster based on damage dealt
	var heal_amount = int(damage * drain_percent)
	if heal_amount > 0:
		caster.heal(heal_amount, caster)
		EventBus.log_debug("%s drained %d HP from %s" % [caster.name, heal_amount, target.name], "LifeDrainEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	return "Deal %.0f%% ATK damage and heal for %.0f%% of damage dealt" % [atk_multiplier * 100, drain_percent * 100]
