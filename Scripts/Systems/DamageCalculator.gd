extends Node
class_name DamageCalculator
## DamageCalculator - Centralized damage calculation and application
## Implements the full E7-style damage formula with shields

# ============================================================================
# DAMAGE FORMULA IMPLEMENTATION
# ============================================================================
# Damage Dealt = Base Atk × Atk% × (1 + Crit Multiplier) × Dmg Multiplier
# Damage Received = True Damage + Damage Dealt + (Damage Dealt / (Damage Dealt + Def Ignore × Base Def × Def% × Def Multiplier))
# ============================================================================

## Calculate damage amount (before applying)
## Returns the final damage number
func calculate_damage(
	attacker: Node,
	defender: Node,
	dmg_multiplier: float = 1.0,
	def_ignore: float = 0.0,
	damage_multiplier: float = 1.0,
	dmg_type: Enums.MultiplierBase = Enums.MultiplierBase.ATK_based,
	can_crit: bool = true,
	force_crit: bool = false
) -> int:
	
	if attacker == null or defender == null:
		push_error("DamageCalculator: attacker or defender is null")
		return 0
	
	var attacker_stats = attacker.get_stats()
	var defender_stats = defender.get_stats()
	
	# Step 1: Calculate base damage dealt
	var base_dmg = attacker_stats.get_effective_atk()
	if dmg_type == Enums.MultiplierBase.DEF_based:
		base_dmg = attacker_stats.get_effective_def()
	
	# Check for crit
	var is_crit = force_crit or roll_crit(attacker_stats.crit_rate) and can_crit
	var crit_multiplier = 1.0
	if is_crit:
		crit_multiplier = attacker_stats.crit_damage
	
	# Apply attacker's damage multiplier stat
	var total_damage_mult = damage_multiplier * attacker_stats.damage_multiplier
	
	# Damage Dealt = Base Atk × Atk% × (1 + Crit Multiplier) × Dmg Multiplier
	var damage_dealt = base_dmg * dmg_multiplier * (crit_multiplier) * total_damage_mult
	
	# Step 2: Calculate damage received (defense formula)
	var base_def = defender_stats.get_effective_def()
	
	# Defense multiplier (could be modified by buffs/debuffs)
	var def_multiplier = 1.0
	
	# Defense value after ignore
	var effective_def = (1.0 - def_ignore) * base_def * def_multiplier
	
	# Damage reduction formula: Damage / (Damage + Effective Defense)
	var damage_after_def = damage_dealt / (1.0 + (effective_def / damage_dealt))
	
	# Apply defender's damage taken multiplier
	var final_damage = damage_after_def * defender_stats.damage_taken_multiplier
	
	# Round to integer
	var damage_int = int(final_damage)
	
	# Emit signal for damage calculation (for UI feedback)
	EventBus.damage_calculated.emit(attacker, defender, damage_int, is_crit)
	
	return damage_int

## Roll for critical hit
func roll_crit(crit_rate: float) -> bool:
	return randf() < crit_rate

# ============================================================================
# DAMAGE APPLICATION
# ============================================================================

## Apply damage to a unit (handles shields and death)
func apply_damage(
	source: Node,
	target: Node,
	amount: int,
	is_damage_shared_ignored: bool = false,
	is_true_damage: bool = false
) -> void:
	
	if target == null or not target.is_alive():
		return
	
	if amount <= 0:
		return
		
	# Check for evasion FIRST (before any damage)
	if target.has_method("should_evade") and target.should_evade():
		EventBus.log_debug("%s EVADED attack! (%.0f%% chance)" % [
			target.name,
			target.current_stats.evasion * 100
			], "Damage")
			# Emit evade event (if signal exists)
		if EventBus.has_signal("unit_evaded"):
			EventBus.unit_evaded.emit(target, source, amount)
		return  # No damage, no counter
	
	var damage_to_apply = amount
	
	# Handle shields (unless true damage)
	if not is_true_damage:
		# Handle damage sharing
		damage_to_apply = target.damaged_shared(damage_to_apply, is_damage_shared_ignored)
		# Handle shields 
		damage_to_apply = _apply_damage_to_shields(target, damage_to_apply)
	
	# Apply remaining damage to HP
	if damage_to_apply > 0:
		target.take_damage(damage_to_apply, is_true_damage)
	
	# Emit signal
	EventBus.damage_dealt.emit(source, target, amount, is_true_damage)
	
	# Trigger passives
	if source != null and source.has_method("_trigger_passive"):
		source._trigger_passive(Enums.TriggerCondition.ON_DAMAGE_DEALT, {
			"target": target,
			"damage": amount,
			"is_crit": false  # Could track this
		})

## Apply damage to shields first, return remaining damage
func _apply_damage_to_shields(target: Node, damage: int) -> int:
	var remaining_damage = damage
	
	# Get all shield effects
	var shield_effects = _get_shield_effects(target)
	
	# Sort shields (could prioritize certain shields)
	# For now, just process in order
	
	for shield in shield_effects:
		if remaining_damage <= 0:
			break
		
		if shield.shield_amount > 0:
			# Apply damage to shield
			var damage_to_shield = mini(remaining_damage, shield.shield_amount)
			shield.shield_amount -= damage_to_shield
			remaining_damage -= damage_to_shield
			
			EventBus.log_debug("Shield absorbed %d damage, %d remaining" % [damage_to_shield, shield.shield_amount], "DamageCalculator")
			
			# Remove shield if depleted
			if shield.shield_amount <= 0:
				target.remove_status_effect(shield)
	
	return remaining_damage

## Get all active shield effects on a unit
func _get_shield_effects(target: Node) -> Array:
	var shields: Array = []
	
	if not target.has_method("get"):
		return shields
	
	var status_effects = target.status_effects if target.has_method("get") else []
	
	for effect in status_effects:
		if effect.effect_type == Enums.StatusEffectType.SHIELD:
			shields.append(effect)
	
	return shields

# apply the damage to all the units with damage share and returns the remaining damage
func _apply_damage_share(target: Node, damage: int, game_state: Node) -> int:
	var remaining_damage = damage

	var all_units = game_state.get_all_units()
	
	for unit in all_units:
		if unit != null and unit.team == target.team and unit.name != target.name:
			var damage_share_dmg = remaining_damage * unit.damage_share
			remaining_damage = remaining_damage - damage_share_dmg
			unit.take_damage(damage_share_dmg, false)
			
			if damage_share_dmg != 0:
				EventBus.log_debug("%s takes %d shared damage from %s" % [ 
					unit.name,
					damage_share_dmg,
					target.name
				], "Damage")
			
	return remaining_damage
# ============================================================================
# MASS DAMAGE (for AOE attacks)
# ============================================================================

## Calculate and apply damage to multiple targets
func calculate_and_apply_damage_to_multiple(
	attacker: Node,
	targets: Array,
	atk_multiplier: float = 1.0,
	def_ignore: float = 0.0,
	damage_multiplier: float = 1.0,
	is_damage_shared_ignored: bool = false,
	is_true_damage: bool = false
) -> Dictionary:
	
	var results = {}
	
	for target in targets:
		if target == null or not target.is_alive():
			continue
		
		var damage = 0
		if is_true_damage:
			# True damage ignores defense
			var attacker_stats = attacker.get_stats()
			damage = int(attacker_stats.get_effective_atk() * atk_multiplier * damage_multiplier)
		else:
			damage = calculate_damage(attacker, target, atk_multiplier, def_ignore, damage_multiplier)
		
		apply_damage(attacker, target, damage, is_damage_shared_ignored, is_true_damage)
		results[target] = damage
	
	return results

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

## Calculate damage preview (for AI or UI)
func preview_damage(
	attacker: Node,
	defender: Node,
	atk_multiplier: float = 1.0,
	def_ignore: float = 0.0,
	damage_multiplier: float = 1.0
) -> Dictionary:
	
	var damage_no_crit = calculate_damage(attacker, defender, atk_multiplier, def_ignore, damage_multiplier, Enums.DMG_MULTIPLIER.ATK_based,false)
	var damage_with_crit = calculate_damage(attacker, defender, atk_multiplier, def_ignore, damage_multiplier, Enums.DMG_MULTIPLIER.ATK_based, true)
	
	var attacker_stats = attacker.get_stats()
	var crit_rate = attacker_stats.crit_rate
	
	return {
		"min_damage": damage_no_crit,
		"max_damage": damage_with_crit,
		"average_damage": int(damage_no_crit * (1.0 - crit_rate) + damage_with_crit * crit_rate),
		"crit_rate": crit_rate
	}

## Check if an attack would kill the target
func would_kill(
	attacker: Node,
	defender: Node,
	atk_multiplier: float = 1.0,
	def_ignore: float = 0.0,
	damage_multiplier: float = 1.0
) -> bool:
	
	var damage = calculate_damage(attacker, defender, atk_multiplier, def_ignore, damage_multiplier)
	
	# Account for shields
	var shield_total = 0
	var shields = _get_shield_effects(defender)
	for shield in shields:
		shield_total += shield.shield_amount
	
	var effective_hp = defender.current_hp + shield_total
	
	return damage >= effective_hp

## Get total effective HP (HP + shields)
func get_effective_hp(unit: Node) -> int:
	var total_hp = unit.current_hp
	
	var shields = _get_shield_effects(unit)
	for shield in shields:
		total_hp += shield.shield_amount
	
	return total_hp

# ============================================================================
# DAMAGE BREAKDOWNS (for debugging/UI)
# ============================================================================

## Get detailed damage breakdown for debugging
func get_damage_breakdown(
	attacker: Node,
	defender: Node,
	atk_multiplier: float = 1.0,
	def_ignore: float = 0.0,
	damage_multiplier: float = 1.0
) -> Dictionary:
	
	var attacker_stats = attacker.get_stats()
	var defender_stats = defender.get_stats()
	
	var base_atk = attacker_stats.get_effective_atk()
	var is_crit = roll_crit(attacker_stats.crit_rate)
	var crit_mult = attacker_stats.crit_damage - 1.0 if is_crit else 0.0
	
	var damage_dealt = base_atk * atk_multiplier * (1.0 + crit_mult) * damage_multiplier * attacker_stats.damage_multiplier
	
	var base_def = defender_stats.get_effective_def()
	var effective_def = (1.0 - def_ignore) * base_def
	
	var damage_after_def = damage_dealt / (1.0 + (effective_def / damage_dealt))
	var final_damage = damage_after_def * defender_stats.damage_taken_multiplier
	
	return {
		"base_atk": base_atk,
		"atk_percent": attacker_stats.atk_percent,
		"atk_multiplier": atk_multiplier,
		"is_crit": is_crit,
		"crit_multiplier": crit_mult,
		"damage_multiplier": damage_multiplier,
		"damage_dealt": damage_dealt,
		"defender_def": base_def,
		"effective_def": effective_def,
		"def_ignore": def_ignore,
		"damage_after_def": damage_after_def,
		"damage_taken_mult": defender_stats.damage_taken_multiplier,
		"final_damage": int(final_damage)
	}
