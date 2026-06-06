extends StatusEffect
class_name Burn
## Burn - Deals fire damage over time based on caster's ATK

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(dmg: int = 300, turns: int = 3) -> void:
	effect_name = "Burn"
	description = "Takes fire damage each turn, can be detonated for more damage"
	effect_type = Enums.StatusEffectType.DOT
	base_duration = turns
	
	# DOT properties
	damage_per_tick = dmg  # Will be calculated from ATK
	
	can_be_cleansed = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.STACK_COUNT  # Burn can stack
	max_stacks = 10

# ============================================================================
# TICK BEHAVIOR
# ============================================================================

func on_tick() -> void:
	EventBus.log_debug("%s takes Burn damage (x%d)" % [target_unit.name, stack_count], "StatusEffect")
	
	# Damage is applied by base StatusEffect._apply_dot_damage()
	# which is called automatically during tick

func detonate(target: Node) -> void:
	target_unit = target
	
	if target_unit == null or not target_unit.is_alive():
		return
	
	var damage = damage_per_tick * stack_count
	
	if damage > 0:
		target_unit.take_damage(damage, true)  # DOT is usually true damage
		EventBus.log_debug("%s takes %d detonation Burn damage" % [target_unit.name, damage], "StatusEffect")
