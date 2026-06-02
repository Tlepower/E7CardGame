extends StatusEffect
class_name Evasion
## Evasion - Chance to dodge incoming attacks

# ============================================================================
# INITIALIZATION
# ============================================================================

## Evasion chance (e.g., 0.3 = 30% chance to evade)
var evasion_chance: float = 0.3

func _init(chance: float = 0.3, turns: int = 3) -> void:
	effect_name = "Evasion"
	description = "%.0f%% chance to evade attacks" % (chance * 100)
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns
	evasion_chance = chance
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.STACK_COUNT
	max_stacks = 3

# ============================================================================
# APPLICATION
# ============================================================================

func on_apply() -> void:
	if target_unit == null:
		return
	
	# Grant evasion capability
	target_unit.set_evasion_chance(evasion_chance * stack_count)
	
	EventBus.log_debug("%s gained Evasion (%.0f%%)" % [target_unit.name, evasion_chance * stack_count * 100], "StatusEffect")

func on_remove() -> void:
	if target_unit == null:
		return
	
	# Remove evasion
	target_unit.set_evasion_chance(0.0)
	
	EventBus.log_debug("%s lost Evasion" % target_unit.name, "StatusEffect")

# ============================================================================
# STACKING
# ============================================================================

func on_stack_added() -> void:
	# Update evasion chance when stacks increase
	if target_unit != null:
		target_unit.set_evasion_chance(evasion_chance * stack_count)
		EventBus.log_debug("%s Evasion stacks: %d (%.0f%% chance)" % [
			target_unit.name, 
			stack_count, 
			evasion_chance * stack_count * 100
		], "StatusEffect")
