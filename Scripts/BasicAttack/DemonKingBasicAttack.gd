extends BasicAttackData
class_name DemonKingBasicAttack
## DemonKingBasicAttack - Basic attack that applies DEF debuff

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	attack_name = "Demon's Grasp"
	description = "Dark energy attack that weakens defenses (75% chance -25% DEF for 2 turns)"
	atk_multiplier = 1.0
	damage_type = Enums.DamageType.MAGICAL
	def_ignore = 0.0
	hit_count = 1
	target_type = Enums.TargetType.SINGLE_ENEMY
	effect_chance = 0.75

# ============================================================================
# EXECUTION OVERRIDE
# ============================================================================

func execute(caster: Node, target: Node, game_state: Node) -> void:
	if not can_use(caster):
		return
	
	if target == null or not target.is_alive():
		return
	
	# Get damage calculator
	var damage_calc = game_state.get_node_or_null("DamageCalculator")
	if damage_calc == null:
		push_error("DemonKingBasicAttack: DamageCalculator not found")
		return
	
	# Calculate and apply damage
	var damage = damage_calc.calculate_damage(
		caster,
		target,
		atk_multiplier,
		def_ignore,
		damage_multiplier,
		Enums.MultiplierBase.ATK_based
	)
	
	damage_calc.apply_damage(caster, target, damage, false, false)
	
	EventBus.log_debug("%s dealt %d damage to %s" % [caster.name, damage, target.name], "BasicAttack")
	
	# Apply DEF debuff with chance
	if randf() <= effect_chance:
		_apply_def_debuff(caster, target, game_state)

## Apply DEF debuff to target
func _apply_def_debuff(caster: Node, target: Node, game_state: Node) -> void:
	# Create DEF debuff
	var def_debuff = DEFDebuff.new(0.25, 2)  # -25% DEF for 2 turns
	def_debuff.initialize(caster, target, 2)
	
	# Get status effect system
	var status_system = game_state.get_node_or_null("StatusEffectSystem")
	if status_system != null:
		status_system.apply_effect(target, def_debuff)
	else:
		# Fallback: apply directly
		target.apply_status_effect(def_debuff)
	
	EventBus.log_debug("%s applied DEF debuff to %s with basic attack" % [caster.name, target.name], "BasicAttack")
