extends StatusEffect
class_name Counter
## Counter - Unit counters attacks with basic attack

# ============================================================================
# INITIALIZATION
# ============================================================================

## Counter chance (e.g., 0.25 = 25% chance to counter)
var counter_chance: float = 0.25

func _init(chance: float = 0.25, turns: int = 2) -> void:
	effect_name = "Counter"
	description = "%.0f%% chance to counter attacks" % (chance * 100)
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns
	counter_chance = chance
	
	stat_modifiers = {"counter_rate": counter_chance * stack_count}
	
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
	
	# Grant counter capability
	target_unit.set_counter_chance(counter_chance * stack_count)
	
	EventBus.log_debug("%s gained Counter (%.0f%%)" % [target_unit.name, counter_chance * stack_count * 100], "StatusEffect")

func on_remove() -> void:
	if target_unit == null:
		return
	
	# Remove counter
	target_unit.set_counter_chance(0.0)
	
	EventBus.log_debug("%s lost Counter" % target_unit.name, "StatusEffect")

# ============================================================================
# STACKING
# ============================================================================

func on_stack_added() -> void:
	# Update counter chance when stacks increase
	if target_unit != null:
		target_unit.set_counter_chance(counter_chance * stack_count)
		# new way to update counter chance when stacks increase
		stat_modifiers = {"counter_rate": counter_chance * stack_count} ## this is for removing later
		if not stat_modifiers.is_empty():
			var stats = target_unit.get_stats()
			stats.add_counter_rate(counter_chance)
			
		EventBus.log_debug("%s Counter stacks: %d (%.0f%% chance)" % [
			target_unit.name, 
			stack_count, 
			counter_chance * stack_count * 100
		], "StatusEffect")
