extends CardEffect
class_name BuffEffect
## BuffEffect - Applies a buff status effect to target(s)

# ============================================================================
# BUFF PROPERTIES
# ============================================================================

## The status effect to apply (should be a StatusEffect resource)
@export var status_effect_template: Resource  # StatusEffect

## Duration in turns (overrides template if > 0)
@export var duration: int = 2

## Number of stacks to apply (for stackable buffs)
@export_range(1, 10) var stack_count: int = 1

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Apply Buff"
	description = "Apply a buff to target"
	target_type = Enums.TargetType.SELF

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	if status_effect_template == null:
		push_error("BuffEffect: status_effect_template is null")
		return
	
	# Get status effect system
	var status_system = get_status_effect_system(game_state)
	if status_system == null:
		push_error("BuffEffect: StatusEffectSystem not found")
		return
	
	# Apply buff(s)
	for i in stack_count:
		# Create instance of the status effect
		var effect_instance = status_effect_template.duplicate_effect()
		
		# Override duration if specified
		if duration > 0:
			effect_instance.base_duration = duration
		
		# Initialize effect
		effect_instance.initialize(caster, target, duration if duration > 0 else -1)
		
		# Apply through system
		status_system.apply_effect(target, effect_instance)
	
	EventBus.log_debug("%s applied %s to %s" % [caster.name, status_effect_template.effect_name, target.name], "BuffEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	if status_effect_template == null:
		return "Apply buff"
	
	var desc = "Apply %s" % status_effect_template.effect_name
	
	if stack_count > 1:
		desc += " x%d" % stack_count
	
	if duration > 0:
		desc += " for %d turn%s" % [duration, "s" if duration > 1 else ""]
	
	return desc
