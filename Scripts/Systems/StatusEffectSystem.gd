extends Node
class_name StatusEffectSystem
## StatusEffectSystem - Centralized management of all status effects
## Handles application, removal, dispel, cleanse, and resistance checks

# ============================================================================
# EFFECT APPLICATION
# ============================================================================

## Apply a status effect to a target
func apply_effect(target: Node, effect: Resource) -> bool:
	if target == null or effect == null:
		push_error("StatusEffectSystem: target or effect is null")
		return false
	
	if not target.is_alive():
		return false
	
	# Check immunity (for debuffs)
	if effect.is_negative() and _check_immunity(target):
		EventBus.log_debug("%s is immune to %s" % [target.name, effect.effect_name], "StatusEffect")
		return false
	
	# Check effect resistance (for debuffs)
	if effect.is_negative() and not _check_effect_lands(effect, target):
		EventBus.log_debug("%s resisted %s" % [target.name, effect.effect_name], "StatusEffect")
		return false
	
	# Check if effect already exists
	var existing_effect = _find_existing_effect(target, effect.effect_name)
	
	if existing_effect != null:
		# Effect already exists - handle stacking/refresh
		_handle_stacking(target, existing_effect, effect)
		return true
	
	# Apply new effect
	target.apply_status_effect(effect)
	
	return true

## Check if effect lands (resistance check)
func _check_effect_lands(effect: Resource, target: Node) -> bool:
	if effect.source_unit == null:
		return true  # No source, auto-land
	
	var source_stats = effect.source_unit.get_stats()
	var target_stats = target.get_stats()
	
	# Base 90% chance + effectiveness - resistance
	var land_chance = 0.90 + source_stats.effectiveness - target_stats.effect_resistance
	land_chance = clampf(land_chance, 0.0, 0.9)  # Min 0%, max 90%
	
	return randf() <= land_chance

## Check if target has immunity
func _check_immunity(target: Node) -> bool:
	if not target.has_method("has_immunity"):
		return false
	
	return target.has_immunity()

## Find existing effect by name
func _find_existing_effect(target: Node, effect_name: String) -> Resource:
	if not target.has_method("get"):
		return null
	
	var status_effects = target.status_effects if target.has_method("get") else []
	
	for effect in status_effects:
		if effect.effect_name == effect_name:
			return effect
	
	return null

## Handle stacking when same effect is reapplied
func _handle_stacking(target: Node, existing: Resource, new_effect: Resource) -> void:
	match existing.stack_type:
		Enums.StackType.NO_STACK:
			# Just refresh duration
			existing.refresh_duration(new_effect.duration)
		
		Enums.StackType.STACK_COUNT:
			# Increase stack count (up to max) and refresh duration
			if existing.max_stacks == 0 or existing.stack_count < existing.max_stacks:
				existing.stack_count += 1
			existing.refresh_duration(new_effect.duration)
		
		Enums.StackType.STACK_DURATION:
			# Add to duration
			existing.duration += new_effect.duration
			existing.on_refresh()
		
		Enums.StackType.INDEPENDENT:
			# Each application is independent - add as new effect
			target.apply_status_effect(new_effect)

# ============================================================================
# EFFECT REMOVAL
# ============================================================================

## Remove a specific effect from target
func remove_effect(target: Node, effect: Resource) -> void:
	if target == null or effect == null:
		return
	
	target.remove_status_effect(effect)

## Remove effect by name
func remove_effect_by_name(target: Node, effect_name: String) -> void:
	var effect = _find_existing_effect(target, effect_name)
	if effect != null:
		remove_effect(target, effect)

# ============================================================================
# DISPEL (Remove Buffs)
# ============================================================================

## Dispel buffs from target
## count: number of buffs to remove (0 = all buffs)
func dispel_buffs(target: Node, count: int = 1) -> int:
	if target == null:
		return 0
	
	var buffs = _get_buffs(target)
	
	# Determine how many to remove
	var remove_count = count if count > 0 else buffs.size()
	remove_count = mini(remove_count, buffs.size())
	
	# Remove buffs (prioritize certain buffs if needed)
	var removed = 0
	for i in remove_count:
		if i >= buffs.size():
			break
		
		var buff = buffs[i]
		if buff.can_be_dispelled:
			target.remove_status_effect(buff)
			removed += 1
	
	if removed > 0:
		EventBus.buffs_dispelled.emit(target, removed)
	
	return removed

## Get all buffs on a target
func _get_buffs(target: Node) -> Array:
	var buffs: Array = []
	
	if not target.has_method("get"):
		return buffs
	
	var status_effects = target.status_effects if target.has_method("get") else []
	
	for effect in status_effects:
		if effect.is_positive() and effect.can_be_dispelled:
			buffs.append(effect)
	
	return buffs

# ============================================================================
# CLEANSE (Remove Debuffs)
# ============================================================================

## Cleanse debuffs from target
## count: number of debuffs to remove (0 = all debuffs)
func cleanse_debuffs(target: Node, count: int = 1) -> int:
	if target == null:
		return 0
	
	var debuffs = _get_debuffs(target)
	
	# Determine how many to remove
	var remove_count = count if count > 0 else debuffs.size()
	remove_count = mini(remove_count, debuffs.size())
	
	# Remove debuffs (prioritize harmful ones)
	var removed = 0
	for i in remove_count:
		if i >= debuffs.size():
			break
		
		var debuff = debuffs[i]
		if debuff.can_be_cleansed:
			target.remove_status_effect(debuff)
			removed += 1
	
	if removed > 0:
		EventBus.debuffs_cleansed.emit(target, removed)
	
	return removed

## Get all debuffs on a target
func _get_debuffs(target: Node) -> Array:
	var debuffs: Array = []
	
	if not target.has_method("get"):
		return debuffs
	
	var status_effects = target.status_effects if target.has_method("get") else []
	
	for effect in status_effects:
		if effect.is_negative() and effect.can_be_cleansed:
			debuffs.append(effect)
	
	return debuffs

# ============================================================================
# TICK MANAGEMENT
# ============================================================================

## Tick all status effects on a unit (called at turn start/end)
func tick_effects(unit: Node, phase: Enums.TurnPhase) -> void:
	if unit == null:
		return
	
	# Let the unit handle its own ticking
	# (Unit.gd already has tick_status_effects method)
	unit.tick_status_effects(phase)

# ============================================================================
# QUERIES
# ============================================================================

## Get all active effects on a unit
func get_all_effects(unit: Node) -> Array:
	if unit == null or not unit.has_method("get"):
		return []
	
	return unit.status_effects.duplicate() if unit.has_method("get") else []

## Get effects by type
func get_effects_by_type(unit: Node, effect_type: Enums.StatusEffectType) -> Array:
	var effects: Array = []
	
	var all_effects = get_all_effects(unit)
	for effect in all_effects:
		if effect.effect_type == effect_type:
			effects.append(effect)
	
	return effects

## Check if unit has a specific effect
func has_effect(unit: Node, effect_name: String) -> bool:
	return _find_existing_effect(unit, effect_name) != null

## Get effect duration remaining
func get_effect_duration(unit: Node, effect_name: String) -> int:
	var effect = _find_existing_effect(unit, effect_name)
	if effect != null:
		return effect.duration
	return 0

## Count total buffs
func count_buffs(unit: Node) -> int:
	return _get_buffs(unit).size()

## Count total debuffs
func count_debuffs(unit: Node) -> int:
	return _get_debuffs(unit).size()

# ============================================================================
# ADVANCED OPERATIONS
# ============================================================================

## Transfer an effect from one unit to another
func transfer_effect(from_unit: Node, to_unit: Node, effect_name: String) -> bool:
	var effect = _find_existing_effect(from_unit, effect_name)
	if effect == null:
		return false
	
	# Remove from source
	from_unit.remove_status_effect(effect)
	
	# Apply to target
	effect.target_unit = to_unit
	to_unit.apply_status_effect(effect)
	
	return true

## Extend effect duration
func extend_effect_duration(unit: Node, effect_name: String, turns: int) -> bool:
	var effect = _find_existing_effect(unit, effect_name)
	if effect == null:
		return false
	
	effect.duration += turns
	return true

## Reduce effect duration
func reduce_effect_duration(unit: Node, effect_name: String, turns: int) -> bool:
	var effect = _find_existing_effect(unit, effect_name)
	if effect == null:
		return false
	
	effect.duration = maxi(0, effect.duration - turns)
	
	# Remove if expired
	if effect.duration <= 0:
		unit.remove_status_effect(effect)
	
	return true

## Remove all effects from a unit
func clear_all_effects(unit: Node) -> void:
	if unit == null:
		return
	
	var effects = get_all_effects(unit)
	for effect in effects:
		unit.remove_status_effect(effect)

## Remove all effects of a specific type
func clear_effects_by_type(unit: Node, effect_type: Enums.StatusEffectType) -> void:
	var effects = get_effects_by_type(unit, effect_type)
	for effect in effects:
		unit.remove_status_effect(effect)

# ============================================================================
# UTILITY
# ============================================================================

## Get effect summary for UI
func get_effect_summary(unit: Node) -> Dictionary:
	return {
		"total_effects": get_all_effects(unit).size(),
		"buffs": count_buffs(unit),
		"debuffs": count_debuffs(unit),
		"control": get_effects_by_type(unit, Enums.StatusEffectType.CONTROL).size(),
		"dot": get_effects_by_type(unit, Enums.StatusEffectType.DOT).size(),
		"shields": get_effects_by_type(unit, Enums.StatusEffectType.SHIELD).size()
	}
