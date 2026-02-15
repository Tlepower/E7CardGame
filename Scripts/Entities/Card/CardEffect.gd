extends Resource
class_name CardEffect
## CardEffect - Base class for all card effects
## Card effects are executed when cards are played or abilities are used

# ============================================================================
# BASIC PROPERTIES
# ============================================================================

## Name of the effect
@export var effect_name: String = "Effect"

## Description of what this effect does
@export_multiline var description: String = ""

# ============================================================================
# TARGETING
# ============================================================================

## What type of targets this effect needs
@export var target_type: Enums.TargetType = Enums.TargetType.SINGLE_ENEMY

## Can this effect target dead units? (for revive effects, etc.)
@export var can_target_dead: bool = false

# ============================================================================
# EXECUTION PROPERTIES
# ============================================================================

## Can this effect be interrupted by mandatory passives?
@export var can_be_interrupted: bool = true

## Does this effect ignore passives? (skills/ultimates with ignore_passive flag)
@export var ignores_passives: bool = false

## Should this effect be applied to all targets at once or individually?
@export var apply_to_all_at_once: bool = false

# ============================================================================
# EXECUTION
# ============================================================================

## Execute the effect
## caster: Unit using the card/ability
## target: Can be Unit, Array[Unit], or null depending on target_type
## game_state: Reference to BattleManager for accessing systems
func execute(caster: Node, target, game_state: Node) -> void:
	# Validation
	if caster == null:
		push_error("CardEffect '%s': caster is null" % effect_name)
		return
	
	# Handle target conversion
	var targets: Array = []
	if target is Array:
		targets = target
	elif target != null:
		targets = [target]
	elif target_type == Enums.TargetType.SELF:
		targets = [caster]
	else:
		push_error("CardEffect '%s': no valid target" % effect_name)
		return
	
	# Execute effect
	if apply_to_all_at_once:
		# Execute on all targets as a group
		await execute_on_targets(caster, targets, game_state)
	else:
		# Execute on each target individually
		for single_target in targets:
			# Skip null or invalid targets
			if single_target == null:
				continue
			
			# Skip dead targets unless allowed
			if not can_target_dead and not single_target.is_alive():
				continue
			
			# Execute on single target
			await execute_on_single_target(caster, single_target, game_state)
			
			# Check for mandatory passive interruption
			if can_be_interrupted and not ignores_passives:
				var should_interrupt = _check_mandatory_passive_interrupt(single_target)
				if should_interrupt:
					EventBus.log_debug("Effect '%s' interrupted by mandatory passive" % effect_name, "CardEffect")
					break

## Execute effect on a single target (override in subclasses)
func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	push_warning("CardEffect '%s': execute_on_single_target not implemented" % effect_name)

## Execute effect on multiple targets at once (override in subclasses if needed)
func execute_on_targets(caster: Node, targets: Array, game_state: Node) -> void:
	# Default: just call execute_on_single_target for each
	for target in targets:
		if target != null and (can_target_dead or target.is_alive()):
			await execute_on_single_target(caster, target, game_state)

# ============================================================================
# VALIDATION
# ============================================================================

## Validate that this effect can be executed
func can_execute(caster: Node, target, game_state: Node) -> bool:
	if caster == null:
		return false
	
	# Check if caster is alive
	if not caster.is_alive():
		return false
	
	# Validate target
	if not validate_target(target):
		return false
	
	return true

## Validate target (override in subclasses for specific validation)
func validate_target(target) -> bool:
	if target == null:
		return target_type == Enums.TargetType.SELF
	
	if target is Array:
		return not target.is_empty()
	
	if target is Node:
		# Check if target is alive (unless can target dead)
		if not can_target_dead and not target.is_alive():
			return false
		return true
	
	return false

# ============================================================================
# PASSIVE INTERACTION
# ============================================================================

## Check if a mandatory passive should interrupt this effect
func _check_mandatory_passive_interrupt(target: Node) -> bool:
	if target == null or ignores_passives:
		return false
	
	if target.has_method("check_for_mandatory_passive_interrupt"):
		return target.check_for_mandatory_passive_interrupt()
	
	return false

# ============================================================================
# UTILITY
# ============================================================================

## Get description for UI (override for dynamic descriptions)
func get_description() -> String:
	return description

## Is this a multi-target effect?
func is_multi_target() -> bool:
	return Enums.is_multi_target(target_type)

## Get the cost modifier (some effects might modify card cost)
func get_cost_modifier() -> int:
	return 0

## Clone this effect
func duplicate_effect() -> CardEffect:
	return duplicate(true)

# ============================================================================
# HELPER: ACCESS GAME SYSTEMS
# ============================================================================

## Get damage calculator from game state
func get_damage_calculator(game_state: Node) -> Node:
	if game_state == null:
		return null
	
	if game_state.has_method("get_damage_calculator"):
		return game_state.get_damage_calculator()
	
	return game_state.get_node_or_null("DamageCalculator")

## Get status effect system from game state
func get_status_effect_system(game_state: Node) -> Node:
	if game_state == null:
		return null
	
	if game_state.has_method("get_status_effect_system"):
		return game_state.get_status_effect_system()
	
	return game_state.get_node_or_null("StatusEffectSystem")

## Get targeting system from game state
func get_targeting_system(game_state: Node) -> Node:
	if game_state == null:
		return null
	
	if game_state.has_method("get_targeting_system"):
		return game_state.get_targeting_system()
	
	return game_state.get_node_or_null("TargetingSystem")

## Get all units from game state
func get_all_units(game_state: Node) -> Array:
	if game_state == null:
		return []
	
	if game_state.has_method("get_all_units"):
		return game_state.get_all_units()
	
	return []
