extends StatusEffect
class_name Burn
## Burn - Deals fire damage over time based on caster's ATK

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(atk_mult: float = 0.3, turns: int = 3) -> void:
	effect_name = "Burn"
	description = "Takes fire damage each turn"
	effect_type = Enums.StatusEffectType.DOT
	base_duration = turns
	
	# DOT properties
	is_atk_based = true
	atk_multiplier = atk_mult
	damage_per_tick = 0  # Will be calculated from ATK
	
	can_be_cleansed = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.STACK_COUNT  # Burn can stack
	max_stacks = 5

# ============================================================================
# TICK BEHAVIOR
# ============================================================================

func on_tick() -> void:
	EventBus.log_debug("%s takes Burn damage (x%d)" % [target_unit.name, stack_count], "StatusEffect")
	
	# Damage is applied by base StatusEffect._apply_dot_damage()
	# which is called automatically during tick
