extends StatusEffect
class_name Poison
## Poison - Deals poison damage over time based on caster's ATK

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(hp_mult: float = 0.2, turns: int = 4) -> void:
	effect_name = "Poison"
	description = "Takes poison damage each turn, based off target's max hp"
	effect_type = Enums.StatusEffectType.DOT
	base_duration = turns
	
	# DOT properties
	is_hp_based = true
	hp_multiplier = hp_mult
	damage_per_tick = 0  # Will be calculated from target's max hp
	
	can_be_cleansed = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.STACK_COUNT  # Poison can stack
	max_stacks = 5

# ============================================================================
# TICK BEHAVIOR
# ============================================================================

func on_tick() -> void:
	EventBus.log_debug("%s takes Poison damage (x%d)" % [target_unit.name, stack_count], "StatusEffect")
