extends Resource
class_name UltimateData
## UltimateData - Defines a unit's ultimate ability
## Ultimates have cooldowns, are once per turn, and do NOT cost mana
## Ultimates are NO LONGER Quick Play (as per updated specs)

# ============================================================================
# BASIC PROPERTIES
# ============================================================================

## Name of the ultimate
@export var ultimate_name: String = "Ultimate"

## Description of what it does
@export_multiline var description: String = "A powerful ultimate ability."

## Icon for UI button
@export var icon: Texture2D

# ============================================================================
# COOLDOWN
# ============================================================================

## Number of turns this ultimate must cool down before it can be used again
## This is unit-specific and ticks only on that unit's turn
@export_range(0, 20) var cooldown: int = 5

## Starting cooldown (if ultimate starts on cooldown at battle start)
@export_range(0, 20) var starting_cooldown: int = 0

# ============================================================================
# TARGETING
# ============================================================================

## Who can be targeted by this ultimate
@export var target_type: Enums.TargetType = Enums.TargetType.SINGLE_ENEMY

# ============================================================================
# EFFECTS
# ============================================================================

## Effects that this ultimate executes
## Array of CardEffect resources (damage, healing, buffs, etc.)
@export var effects: Array[Resource] = []  # Array[CardEffect]

## Can this ultimate ignore passives?
@export var ignore_passives: bool = false

# ============================================================================
# EXECUTION
# ============================================================================

## Execute the ultimate ability
## caster: Unit using the ultimate
## target: Unit, Array[Unit], or null depending on target_type
## game_state: Reference to BattleManager
func execute(caster: Node, target, game_state: Node) -> void:
	if caster == null:
		push_error("Ultimate: caster is null")
		return
	
	# Emit signal
	EventBus.ultimate_used.emit(caster, target)
	
	# Handle targeting
	var targets: Array = []
	if target is Array:
		targets = target
	elif target != null:
		targets = [target]
	elif target_type == Enums.TargetType.SELF:
		targets = [caster]
	elif Enums.is_multi_target(target_type):
		# Auto-select all targets
		targets = _get_auto_targets(caster, game_state)
	else:
		push_error("Ultimate: no valid target provided")
		return
	
	# Execute all effects
	await _execute_effects(caster, targets, game_state)
	
	# Set ultimate on cooldown
	caster.ultimate_cooldown = cooldown
	caster.ultimate_used_this_turn = true

## Execute all effects on targets
func _execute_effects(caster: Node, targets: Array, game_state: Node) -> void:
	for effect_resource in effects:
		if effect_resource == null or not effect_resource.has_method("execute"):
			continue
		
		# Check if this is a multi-target effect
		if effect_resource.has_method("is_multi_target") and effect_resource.is_multi_target():
			# Execute on all targets at once
			await effect_resource.execute(caster, targets, game_state)
		else:
			# Execute on each target individually
			for single_target in targets:
				if single_target == null:
					continue
				
				# Skip dead targets unless effect can target dead units
				if not single_target.is_alive() and not effect_resource.get("can_target_dead"):
					continue
				
				# Execute effect
				await effect_resource.execute(caster, single_target, game_state)
				
				# Check for mandatory passive interruption
				var should_interrupt = _check_mandatory_passives(single_target, game_state)
				if should_interrupt:
					EventBus.log_debug("Ultimate effect interrupted by mandatory passive", "Ultimate")
					break

## Check if any mandatory passives should interrupt
func _check_mandatory_passives(target: Node, game_state: Node) -> bool:
	if target == null or not target.has_method("check_passive_triggers"):
		return false
	
	# If this ultimate ignores passives, skip check
	if ignore_passives:
		return false
	
	# Check target's mandatory passives
	return target.check_for_mandatory_passive_interrupt()

## Get auto-selected targets for multi-target abilities
func _get_auto_targets(caster: Node, game_state: Node) -> Array:
	var targeting_system = game_state.get_node_or_null("TargetingSystem")
	if targeting_system == null:
		push_error("Ultimate: TargetingSystem not found")
		return []
	
	return targeting_system.auto_select_targets(target_type, caster.team, game_state.get_all_units())

# ============================================================================
# VALIDATION
# ============================================================================

## Check if this ultimate can be used
func can_use(caster: Node) -> bool:
	if caster == null:
		return false
	
	# Must be alive
	if not caster.is_alive():
		return false
	
	# Must not be on cooldown
	if caster.ultimate_cooldown > 0:
		return false
	
	# Must not have been used this turn already
	if caster.ultimate_used_this_turn:
		return false
	
	# Cannot use while controlled (most control effects prevent ultimates)
	if caster.is_controlled():
		# Check specific control types
		var can_use_controlled = _can_use_while_controlled(caster)
		if not can_use_controlled:
			return false
	
	return true

## Check if ultimate can be used while under specific control effects
func _can_use_while_controlled(caster: Node) -> bool:
	# Get active control effects
	var control_effects = caster.get_control_effects()
	
	for control in control_effects:
		var control_type = control.get("control_type")
		
		match control_type:
			Enums.ControlType.STUN, Enums.ControlType.FREEZE, Enums.ControlType.SLEEP:
				return false  # Cannot use ultimate while stunned/frozen/asleep
			Enums.ControlType.SILENCE, Enums.ControlType.RESTRICT:
				return false  # Cannot use skills/ultimate while silenced
			Enums.ControlType.TAUNT, Enums.ControlType.PROVOKE:
				return true  # Can use ultimate, but targeting might be forced
	
	return false

# ============================================================================
# UTILITY
# ============================================================================

## Get valid targets for this ultimate
func get_valid_targets(caster: Node, all_units: Array) -> Array:
	if caster == null:
		return []
	
	# Try to get targeting system
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return _filter_targets_manually(caster, all_units)
	
	var battle_manager = tree.root.get_node_or_null("BattleManager")
	if battle_manager == null:
		return _filter_targets_manually(caster, all_units)
	
	var targeting_system = battle_manager.get_node_or_null("TargetingSystem")
	if targeting_system == null:
		return _filter_targets_manually(caster, all_units)
	
	return targeting_system.get_valid_targets_for_ability(
		target_type,
		caster.team,
		all_units
	)

## Manual target filtering (fallback)
func _filter_targets_manually(caster: Node, all_units: Array) -> Array:
	var valid_targets: Array = []
	
	match target_type:
		Enums.TargetType.SINGLE_ENEMY, Enums.TargetType.ALL_ENEMIES:
			var enemy_team = Enums.get_opposite_team(caster.team)
			for unit in all_units:
				if unit.team == enemy_team and unit.is_alive():
					valid_targets.append(unit)
		
		Enums.TargetType.SINGLE_ALLY, Enums.TargetType.ALL_ALLIES:
			for unit in all_units:
				if unit.team == caster.team and unit.is_alive():
					valid_targets.append(unit)
		
		Enums.TargetType.SELF:
			valid_targets = [caster]
		
		Enums.TargetType.OTHER_ALLIES:
			for unit in all_units:
				if unit.team == caster.team and unit != caster and unit.is_alive():
					valid_targets.append(unit)
	
	return valid_targets

## Check if this ultimate is ready (off cooldown)
func is_ready(caster: Node) -> bool:
	return caster != null and caster.ultimate_cooldown == 0

## Get cooldown remaining
func get_cooldown_remaining(caster: Node) -> int:
	if caster == null:
		return 0
	return caster.ultimate_cooldown

## Create a duplicate
func duplicate_data() -> UltimateData:
	return duplicate(true)
