extends CardEffect
class_name DebuffEffect
## DebuffEffect - Applies a debuff status effect to target(s)

# ============================================================================
# DEBUFF PROPERTIES
# ============================================================================

## The status effect to apply (should be a StatusEffect resource)
@export var status_effect_template: Resource  # StatusEffect

## Duration in turns (overrides template if > 0)
@export var duration: int = 2

## Number of stacks to apply (for stackable debuffs)
@export_range(1, 10) var stack_count: int = 1

## Chance to apply (0.0 - 1.0, affected by effectiveness/resistance)
@export_range(0.0, 1.0, 0.01) var application_chance: float = 1.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Apply Debuff"
	description = "Apply a debuff to target"
	target_type = Enums.TargetType.SINGLE_ENEMY

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	if status_effect_template == null:
		push_error("DebuffEffect: status_effect_template is null")
		return
	
	# Check application chance (before effectiveness/resistance check)
	if randf() > application_chance:
		EventBus.log_debug("Debuff application failed (chance roll)", "DebuffEffect")
		return
	
	# Get status effect system
	var status_system = get_status_effect_system(game_state)
	if status_system == null:
		push_error("DebuffEffect: StatusEffectSystem not found")
		return
	
	# Apply debuff(s)
	for i in stack_count:
		# Create instance of the status effect
		var effect_instance = status_effect_template.duplicate_effect()
		
		# Override duration if specified
		if duration > 0:
			effect_instance.base_duration = duration
		
		# Initialize effect
		effect_instance.initialize(caster, target, duration if duration > 0 else -1)
		
		# Apply through system (system will handle resistance check)
		status_system.apply_effect(target, effect_instance)
	
	EventBus.log_debug("%s applied %s to %s" % [caster.name, status_effect_template.effect_name, target.name], "DebuffEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	if status_effect_template == null:
		return "Apply debuff"
	
	var desc = "Apply %s" % status_effect_template.effect_name
	
	if stack_count > 1:
		desc += " x%d" % stack_count
	
	if duration > 0:
		desc += " for %d turn%s" % [duration, "s" if duration > 1 else ""]
	
	if application_chance < 1.0:
		desc += " (%.0f%% chance)" % (application_chance * 100)
	
	return desc
