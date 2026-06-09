extends Resource
class_name BasicAttackData
## BasicAttackData - Defines a unit's basic attack ability
## Basic attacks are free, once per turn, and executed via a button (not a card)

# ============================================================================
# BASIC PROPERTIES
# ============================================================================

## Name of the basic attack
@export var attack_name: String = "Basic Attack"

## Description of what it does
@export_multiline var description: String = "A basic attack."

## Icon for UI button
@export var icon: Texture2D

# ============================================================================
# DAMAGE PROPERTIES
# ============================================================================

## ATK multiplier (1.0 = 100% of caster's ATK)
@export var atk_multiplier: float = 1.0

## Type of damage dealt
@export var damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL

## Defense ignore percentage (0.0 - 1.0, 0% - 100%)
@export_range(0.0, 1.0, 0.01) var def_ignore: float = 0.0

## Number of hits (for multi-hit attacks)
@export_range(1, 10) var hit_count: int = 1

## Damage multiplier per hit (affects final damage calculation)
@export var damage_multiplier: float = 1.0

# ============================================================================
# TARGETING
# ============================================================================

## Who can be targeted (basic attacks typically target SINGLE_ENEMY or LOWEST_HP_ENEMY)
@export var target_type: Enums.TargetType = Enums.TargetType.SINGLE_ENEMY

# ============================================================================
# ADDITIONAL EFFECTS
# ============================================================================

## Additional effects applied on hit (e.g., apply debuff, push AR, etc.)
## These are CardEffect resources that get executed after damage
@export var additional_effects: Array[Resource] = []  # Array[CardEffect]

## Chance for additional effects to apply (0.0 - 1.0, 100% if 1.0)
@export_range(0.0, 1.0, 0.01) var effect_chance: float = 1.0

# ============================================================================
# EXECUTION
# ============================================================================

## Execute the basic attack
## caster: Unit performing the attack
## target: Unit or Array[Unit] being attacked
## game_state: Reference to BattleManager for accessing systems
func execute(caster: Node, target, game_state: Node) -> void:
	if caster == null:
		push_error("BasicAttack: caster is null")
		return
	
	# Emit signal
	EventBus.basic_attack_used.emit(caster, target)
	
	# Handle single or multi-target
	var targets: Array = []
	if target is Array:
		targets = target
	elif target != null:
		targets = [target]
	else:
		push_error("BasicAttack: no valid target")
		return
	
	# Execute attack on each target
	for single_target in targets:
		if single_target == null or not single_target.is_alive():
			continue
		
		_attack_single_target(caster, single_target, game_state)

## Attack a single target with all hits
func _attack_single_target(caster: Node, target: Node, game_state: Node) -> void:
	# Get damage calculator
	var damage_calc = game_state.get_damage_calculator()
	if damage_calc == null:
		push_error("BasicAttack: damage calculator not found")
		return
	
	# Execute each hit
	for hit_index in hit_count:
		# Check if target is still alive
		if not target.is_alive():
			break
		
		# Calculate and apply damage
		var damage_amount = damage_calc.calculate_damage(
			caster,
			target,
			atk_multiplier,
			def_ignore,
			damage_multiplier,
			false  # Crit check will be done inside calculate_damage
		)
		
		# Apply the damage
		var is_true = (damage_type == Enums.DamageType.TRUE)
		damage_calc.apply_damage(caster, target, damage_amount, game_state, is_true)
		
		# Apply additional effects (if chance succeeds)
		if not additional_effects.is_empty() and randf() <= effect_chance:
			_apply_additional_effects(caster, target, game_state)
		
		# Small delay between hits for multi-hit attacks
		if hit_count > 1 and hit_index < hit_count - 1:
			await caster.get_tree().create_timer(0.1).timeout

## Apply additional effects after attack
func _apply_additional_effects(caster: Node, target: Node, game_state: Node) -> void:
	for effect_resource in additional_effects:
		if effect_resource == null or not effect_resource.has_method("execute"):
			continue
		
		# Execute the effect
		effect_resource.execute(caster, target, game_state)

# ============================================================================
# VALIDATION
# ============================================================================

## Check if the basic attack can be used
func can_use(caster: Node) -> bool:
	if caster == null:
		return false
	
	# Check if unit is alive
	if not caster.is_alive():
		return false
	
	# Check if basic attack was already used this turn
	if caster.basic_attack_used_this_turn:
		return false
	
	# Check if unit is controlled in a way that prevents basic attacks
	if caster.is_controlled() and not can_use_while_controlled():
		return false
	
	return true

## Can this basic attack be used while controlled?
## Most control effects allow basic attacks, but some (silence, stun) prevent them
func can_use_while_controlled() -> bool:
	# This can be overridden, but by default basic attacks can't be used while controlled
	# The Unit class will handle specific control types
	return false

# ============================================================================
# UTILITY
# ============================================================================

## Get valid targets for this basic attack
func get_valid_targets(caster: Node, all_units: Array) -> Array:
	if caster == null:
		return []
	
	var targeting_system = get_targeting_system()
	if targeting_system == null:
		# Fallback: filter manually
		return _filter_targets_manually(caster, all_units)
	
	return targeting_system.get_valid_targets_for_ability(
		target_type,
		caster.team,
		all_units
	)

## Manual target filtering (fallback)
func _filter_targets_manually(caster: Node, all_units: Array) -> Array:
	var valid_targets: Array = []
	var enemy_team = Enums.get_opposite_team(caster.team)
	
	for unit in all_units:
		if unit.team == enemy_team and unit.is_alive():
			valid_targets.append(unit)
	
	return valid_targets

## Get reference to targeting system (helper)
func get_targeting_system() -> Node:
	# Try to get from scene tree
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	
	var root = tree.root
	if root == null:
		return null
	
	return root.get_node_or_null("BattleManager/TargetingSystem")

## Create a duplicate
func duplicate_data() -> BasicAttackData:
	return duplicate(true)
