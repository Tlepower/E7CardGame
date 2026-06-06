extends Node
class_name TargetingSystemOld
## TargetingSystem - Handles target selection, validation, and auto-targeting
## Used by cards, abilities, and effects to find valid targets

# ============================================================================
# TARGET VALIDATION
# ============================================================================

## Get valid targets for a card/ability
func get_valid_targets_for_ability(
	target_type: Enums.TargetType,
	caster_team: Enums.Team,
	all_units: Array
) -> Array:
	
	var valid_targets: Array = []
	
	match target_type:
		Enums.TargetType.SINGLE_ENEMY:
			valid_targets = _get_alive_enemies(caster_team, all_units)
		
		Enums.TargetType.SINGLE_ALLY:
			valid_targets = _get_alive_allies(caster_team, all_units)
		
		Enums.TargetType.ALL_ENEMIES:
			valid_targets = _get_alive_enemies(caster_team, all_units)
		
		Enums.TargetType.ALL_ALLIES:
			valid_targets = _get_alive_allies(caster_team, all_units)
		
		Enums.TargetType.ALL_UNITS:
			valid_targets = _get_all_alive_units(all_units)
		
		Enums.TargetType.SELF:
			# Self is handled specially, but we return empty for now
			valid_targets = []
		
		Enums.TargetType.OTHER_ALLIES:
			valid_targets = _get_alive_allies(caster_team, all_units)
			# Filter out self (caller must remove caster from list)
		
		Enums.TargetType.RANDOM_ENEMY:
			valid_targets = _get_alive_enemies(caster_team, all_units)
		
		Enums.TargetType.RANDOM_ALLY:
			valid_targets = _get_alive_allies(caster_team, all_units)
		
		Enums.TargetType.LOWEST_HP_ENEMY:
			valid_targets = _get_alive_enemies(caster_team, all_units)
		
		Enums.TargetType.HIGHEST_HP_ENEMY:
			valid_targets = _get_alive_enemies(caster_team, all_units)
		
		Enums.TargetType.LOWEST_HP_ALLY:
			valid_targets = _get_alive_allies(caster_team, all_units)
		
		Enums.TargetType.HIGHEST_HP_ALLY:
			valid_targets = _get_alive_allies(caster_team, all_units)
	
	return valid_targets

## Validate that a specific target is valid for an ability
func validate_target(
	target,
	target_type: Enums.TargetType,
	caster_team: Enums.Team,
	all_units: Array
) -> bool:
	
	if target == null:
		return false
	
	var valid_targets = get_valid_targets_for_ability(target_type, caster_team, all_units)
	
	# For multi-target
	if target is Array:
		for t in target:
			if t not in valid_targets:
				return false
		return true
	
	# For single target
	return target in valid_targets

# ============================================================================
# AUTO-TARGET SELECTION
# ============================================================================

## Automatically select target(s) based on target type
## Returns: Unit, Array[Unit], or null
func auto_select_target(
	target_type: Enums.TargetType,
	caster_team: Enums.Team,
	all_units: Array
) -> Variant:
	
	match target_type:
		Enums.TargetType.SELF:
			# Self targeting is handled by caller
			return null
		
		Enums.TargetType.ALL_ENEMIES:
			return _get_alive_enemies(caster_team, all_units)
		
		Enums.TargetType.ALL_ALLIES:
			return _get_alive_allies(caster_team, all_units)
		
		Enums.TargetType.ALL_UNITS:
			return _get_all_alive_units(all_units)
		
		Enums.TargetType.OTHER_ALLIES:
			return _get_alive_allies(caster_team, all_units)
			# Caller must filter out self
		
		Enums.TargetType.RANDOM_ENEMY:
			return select_random_target(_get_alive_enemies(caster_team, all_units))
		
		Enums.TargetType.RANDOM_ALLY:
			return select_random_target(_get_alive_allies(caster_team, all_units))
		
		Enums.TargetType.LOWEST_HP_ENEMY:
			return select_lowest_hp_enemy(_get_alive_enemies(caster_team, all_units))
		
		Enums.TargetType.HIGHEST_HP_ENEMY:
			return select_highest_hp_enemy(_get_alive_enemies(caster_team, all_units))
		
		Enums.TargetType.LOWEST_HP_ALLY:
			return select_lowest_hp_ally(_get_alive_allies(caster_team, all_units))
		
		Enums.TargetType.HIGHEST_HP_ALLY:
			return select_highest_hp_ally(_get_alive_allies(caster_team, all_units))
	
	# Default: return null (requires manual targeting)
	return null

# ============================================================================
# TARGET SELECTION STRATEGIES
# ============================================================================

## Select random target from array
func select_random_target(targets: Array) -> Node:
	if targets.is_empty():
		return null
	
	return targets[randi() % targets.size()]

## Select enemy with lowest HP
func select_lowest_hp_enemy(enemies: Array) -> Node:
	if enemies.is_empty():
		return null
	
	var lowest_hp_unit = enemies[0]
	var lowest_hp = lowest_hp_unit.current_hp
	
	for enemy in enemies:
		if enemy.current_hp < lowest_hp:
			lowest_hp = enemy.current_hp
			lowest_hp_unit = enemy
	
	return lowest_hp_unit

## Select enemy with highest HP
func select_highest_hp_enemy(enemies: Array) -> Node:
	if enemies.is_empty():
		return null
	
	var highest_hp_unit = enemies[0]
	var highest_hp = highest_hp_unit.current_hp
	
	for enemy in enemies:
		if enemy.current_hp > highest_hp:
			highest_hp = enemy.current_hp
			highest_hp_unit = enemy
	
	return highest_hp_unit

## Select ally with lowest HP
func select_lowest_hp_ally(allies: Array) -> Node:
	if allies.is_empty():
		return null
	
	var lowest_hp_unit = allies[0]
	var lowest_hp = lowest_hp_unit.current_hp
	
	for ally in allies:
		if ally.current_hp < lowest_hp:
			lowest_hp = ally.current_hp
			lowest_hp_unit = ally
	
	return lowest_hp_unit

## Select ally with highest HP
func select_highest_hp_ally(allies: Array) -> Node:
	if allies.is_empty():
		return null
	
	var highest_hp_unit = allies[0]
	var highest_hp = highest_hp_unit.current_hp
	
	for ally in allies:
		if ally.current_hp > highest_hp:
			highest_hp = ally.current_hp
			highest_hp_unit = ally
	
	return highest_hp_unit

## Select enemy with lowest HP% (percentage)
func select_lowest_hp_percent_enemy(enemies: Array) -> Node:
	if enemies.is_empty():
		return null
	
	var lowest_hp_unit = enemies[0]
	var lowest_hp_percent = lowest_hp_unit.get_hp_percent()
	
	for enemy in enemies:
		var hp_percent = enemy.get_hp_percent()
		if hp_percent < lowest_hp_percent:
			lowest_hp_percent = hp_percent
			lowest_hp_unit = enemy
	
	return lowest_hp_unit

## Select ally with lowest HP% (percentage)
func select_lowest_hp_percent_ally(allies: Array) -> Node:
	if allies.is_empty():
		return null
	
	var lowest_hp_unit = allies[0]
	var lowest_hp_percent = lowest_hp_unit.get_hp_percent()
	
	for ally in allies:
		var hp_percent = ally.get_hp_percent()
		if hp_percent < lowest_hp_percent:
			lowest_hp_percent = hp_percent
			lowest_hp_unit = ally
	
	return lowest_hp_unit

# ============================================================================
# FILTERING HELPERS
# ============================================================================

## Get all alive enemies
func _get_alive_enemies(caster_team: Enums.Team, all_units: Array) -> Array:
	var enemies: Array = []
	var enemy_team = Enums.get_opposite_team(caster_team)
	
	for unit in all_units:
		if unit.team == enemy_team and unit.is_alive():
			enemies.append(unit)
	
	return enemies

## Get all alive allies
func _get_alive_allies(caster_team: Enums.Team, all_units: Array) -> Array:
	var allies: Array = []
	
	for unit in all_units:
		if unit.team == caster_team and unit.is_alive():
			allies.append(unit)
	
	return allies

## Get all alive units
func _get_all_alive_units(all_units: Array) -> Array:
	var alive: Array = []
	
	for unit in all_units:
		if unit.is_alive():
			alive.append(unit)
	
	return alive

# ============================================================================
# TAUNT HANDLING
# ============================================================================

## Check if targeting should be forced due to taunt
## Returns taunter if caster is taunted, otherwise null
func check_for_taunt_redirect(caster: Node) -> Node:
	if caster == null:
		return null
	
	if not caster.is_controlled():
		return null
	
	# Check if caster has a taunt target
	if caster.has_method("get") and caster.get("taunt_target") != null:
		var taunter = caster.taunt_target
		if taunter != null and taunter.is_alive():
			return taunter
	
	return null

## Apply taunt redirect to target selection
func apply_taunt_redirect(caster: Node, intended_target, target_type: Enums.TargetType):
	var taunter = check_for_taunt_redirect(caster)
	
	if taunter == null:
		return intended_target
	
	# Only redirect single-target enemy abilities
	if target_type == Enums.TargetType.SINGLE_ENEMY:
		EventBus.log_debug("%s is taunted by %s, redirecting target" % [caster.name, taunter.name], "Targeting")
		return taunter
	
	# Multi-target and ally-targeting abilities are not affected by taunt
	return intended_target

# ============================================================================
# UTILITY
# ============================================================================

## Count valid targets
func count_valid_targets(
	target_type: Enums.TargetType,
	caster_team: Enums.Team,
	all_units: Array
) -> int:
	
	return get_valid_targets_for_ability(target_type, caster_team, all_units).size()

## Check if there are any valid targets
func has_valid_targets(
	target_type: Enums.TargetType,
	caster_team: Enums.Team,
	all_units: Array
) -> bool:
	
	return count_valid_targets(target_type, caster_team, all_units) > 0
