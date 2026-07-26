extends CardEffect
class_name CounterEffect
## CounterEffect - Grants counter buff to target

# ============================================================================
# COUNTER PROPERTIES
# ============================================================================

## Counter chance per stack
@export var counter_chance: float = 0.5

## Duration in turns
@export var duration: int = 2

## Number of stacks to apply
@export var stack_count: int = 1

## Number of turns
@export var turns: int = 1

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(chance: float = 0.5, turns: int = 2, stacks: int = 1) -> void:
	effect_name = "Grant Counter"
	description = "Grant %.0f%% counter chance for %d turns" % [(chance * 100), turns] # and turn
	target_type = Enums.TargetType.SINGLE_ALLY
	counter_chance = chance
	duration = turns
	stack_count = stacks

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Create counter buff
	var counter = Counter.new(counter_chance, duration)
	counter.initialize(caster, target, duration)
	counter.stack_count = stack_count
	
	# Apply through status system
	var status_system = get_status_effect_system(game_state)
	if status_system != null:
		status_system.apply_effect(target, counter)
	else:
		target.apply_status_effect(counter)
	
	EventBus.log_debug("%s granted Counter (%.0f%%) to %s" % [
		caster.name, 
		counter_chance * 100, 
		target.name
	], "CounterEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	return "Grant %.0f%% counter chance for %d turns" % [(counter_chance * 100), turns] # desciption
