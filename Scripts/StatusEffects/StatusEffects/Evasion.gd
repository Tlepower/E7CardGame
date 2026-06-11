extends StatusEffect
class_name Evasion
## Evasion - Chance to dodge incoming attacks

# ============================================================================
# INITIALIZATION
# ============================================================================

## Evasion chance (e.g., 0.25 = 25% chance to evade)
var evasion_chance: float = 0.25

func _init(chance: float = 0.25, turns: int = 2) -> void:
	effect_name = "Evasion"
	description = "%.0f%% chance to evade attacks" % (chance * 100)
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns
	evasion_chance = chance
	
	stat_modifiers = {"evasion": evasion_chance * stack_count}
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.STACK_COUNT
	max_stacks = 4

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
		## new way to update evasion chance when stacks increase
		stat_modifiers = {"evasion" : evasion_chance * stack_count}
		if not stat_modifiers.is_empty():
			var stats = target_unit.get_stats()
			stats.add_evasion(evasion_chance)
		
		EventBus.log_debug("%s Evasion stacks: %d (%.0f%% chance)" % [
			target_unit.name, 
			stack_count, 
			evasion_chance * stack_count * 100
		], "StatusEffect")
