extends Node
class_name Unit
## Unit - Runtime instance of a unit in battle
## Created from UnitData template, exists for duration of battle

# ============================================================================
# REFERENCES
# ============================================================================

## Original template data
var unit_data: UnitData = null

## Which team this unit belongs to
var team: Enums.Team = Enums.Team.PLAYER

## Reference to the battle manager
var battle_manager: Node = null

# ============================================================================
# STATS
# ============================================================================

## Current hit points
var current_hp: int = 0

## Current maximum hit points
var current_max_hp: int = 0

## Current stats (modified by buffs/debuffs)
var current_stats: UnitStats = null

# ============================================================================
# ACTION READINESS (Turn Order)
# ============================================================================

## Action Readiness (0-100+, unit takes turn at 100)
var action_readiness: float = 0.0

# ============================================================================
# STATUS EFFECTS
# ============================================================================

## Active status effects on this unit
var status_effects: Array[Resource] = []  # Array[StatusEffect]

# ============================================================================
# ABILITIES
# ============================================================================

## Passive ability instance
var passive: Passive = null

## Ultimate ability data (reference from unit_data)
var ultimate_data: UltimateData = null

## Basic attack data (reference from unit_data)
var basic_attack_data: BasicAttackData = null

# ============================================================================
# COOLDOWNS & USAGE TRACKING
# ============================================================================

## Ultimate cooldown remaining (ticks down on this unit's turn start)
var ultimate_cooldown: int = 0

## Has basic attack been used this turn?
var basic_attack_used_this_turn: bool = false

## Has ultimate been used this turn?
var ultimate_used_this_turn: bool = false

# ============================================================================
# CONTROL STATES
# ============================================================================

## Is this unit currently controlled? (stunned, taunted, etc.)
var _is_controlled: bool = false

## Active control effects (for specific control type checking)
var _control_effects: Array[Dictionary] = []  # {control_type: Enums.ControlType, source: Unit}

## Unit that is taunting this unit (if taunted)
var taunt_target: Node = null

# Did you live on 1 hp
var has_death_prevention: bool = false

# chances for countering with basic attack (50% to counter = 0.5) 
var counter_chance: float = 0.0

var has_countered: bool = false

# the percent that healing is less (0.0 - 1.0, 0.5 = 50% healing reduction)
var healing_reduction: float = 0.0

# the percent of damage recieved from other allies
# (0.0 - 0.5, 0.1 = 10% of damage done to other allies goes to this unit)
var damage_share: float = 0.0


# ============================================================================
# INITIALIZATION
# ============================================================================

## Initialize unit from UnitData template
func initialize_from_data(data: UnitData, team_side: Enums.Team) -> void:
	if data == null:
		push_error("Unit: cannot initialize with null UnitData")
		return
	
	# Store references
	unit_data = data
	team = team_side
	name = data.unit_name
	
	# Initialize stats
	if data.base_stats != null:
		data.base_stats.initialize_gear_stats() ##
		current_stats = data.base_stats.duplicate_stats()
		current_hp = current_stats.max_hp
		current_max_hp = current_stats.max_hp
	else:
		push_error("Unit '%s': base_stats is null" % name)
		return
	
	# Initialize abilities
	ultimate_data = data.ultimate_data
	basic_attack_data = data.basic_attack_data
	
	# Set starting ultimate cooldown
	if ultimate_data != null:
		ultimate_cooldown = ultimate_data.starting_cooldown
	
	# Initialize passive
	if data.passive_script != null:
		passive = data.passive_script.new()
		if passive != null:
			passive.initialize(self)
	
	# Initialize AR (starting at 0, will be randomized or set by battle manager)
	action_readiness = 0.0
	
	_trigger_passive(Enums.TriggerCondition.ON_BATTLE_START, {})
	
	EventBus.log_debug("Unit '%s' initialized for team %s" % [name, Enums.team_to_string(team)], "Unit")

# ============================================================================
# HP MANAGEMENT
# ============================================================================

## Take damage
func take_damage(amount: int, is_true_damage: bool = false) -> void:
	if amount <= 0:
		return
	
	# Apply damage
	var damage_taken = amount
	current_hp -= damage_taken
	current_hp = maxi(0, current_hp)
	
	# Emit signal
	EventBus.damage_dealt.emit(null, self, damage_taken, is_true_damage)
	
	# Trigger passives
	_trigger_passive(Enums.TriggerCondition.ON_DAMAGE_TAKEN, {"damage": damage_taken})
	
	# Check for death
	if current_hp <= 0:
		die()

## Heal HP
func heal(amount: int, source: Node = null) -> void:
	if amount <= 0 or not is_alive():
		return
		
	if has_antiheal():
		return
	
	# Apply healing reduction
	var actual_amount = amount
	if healing_reduction > 0.0:
		actual_amount = int(amount * (1.0 - healing_reduction))
		if actual_amount < amount:
			EventBus.log_debug("%s healing reduced: %d -> %d (%.0f%% reduction)" %[
				name,
				amount,
				actual_amount,
				healing_reduction * 100
			], "Unit")
	
	var old_hp = current_hp
	current_hp = mini(current_hp + actual_amount, current_max_hp)
	var actual_heal = current_hp - old_hp
	
	if actual_heal > 0:
		EventBus.unit_healed.emit(self, actual_heal, source)
		_trigger_passive(Enums.TriggerCondition.ON_HEAL, {"amount": actual_heal, "source": source})

## Check if unit is alive
func is_alive() -> bool:
	return current_hp > 0

## Get HP as percentage (0.0 - 1.0)
func get_hp_percent() -> float:
	if current_stats == null or current_stats.max_hp == 0 or current_max_hp == 0:
		return 0.0
	return float(current_hp) / float(current_max_hp)

## Unit dies
func die() -> void:
	if not is_alive():
		return  # Already dead
	
	# Check death prevention
	if has_death_prevention and current_max_hp != 0:
		EventBus.log_debug("%s death prevented! HP set to 1" % name, "Unit")
		current_hp = 1
		has_death_prevention = false  # Consume death prevention
		
		# Emit signal
		EventBus.death_prevented.emit(self)
		
		# Trigger passive for surviving death
		_trigger_passive(Enums.TriggerCondition.ON_HP_THRESHOLD, {"prevented_death": true})
		return
	
	current_hp = 0
	EventBus.unit_died.emit(self)
	_trigger_passive(Enums.TriggerCondition.ON_ENEMY_DEATH, {"dead_unit": self})
	
	# Notify battle manager
	if battle_manager != null and battle_manager.has_method("handle_unit_death"):
		battle_manager.handle_unit_death(self)

# ============================================================================
# STATUS EFFECT MANAGEMENT
# ============================================================================

## Apply a status effect to this unit
func apply_status_effect(effect: Resource) -> void:
	if effect == null:
		return
	
	# Check immunity
	if has_immunity() and effect.is_negative():
		EventBus.log_debug("Unit '%s' is immune to debuff" % name, "StatusEffect")
		return
	
	# Check block
	if has_block() and effect.is_positive():
		EventBus.log_debug("Unit '%s' is immune to buff" % name, "StatusEffect")
		return
	
	# Check effect resistance for debuffs
	if effect.is_negative() and not _check_effect_lands(effect):
		EventBus.log_debug("Unit '%s' resisted debuff" % name, "StatusEffect")
		return
	
	# Check if effect already exists and handle stacking
	var existing_effect = _find_existing_effect(effect.effect_name)
	if existing_effect != null:
		_handle_effect_stacking(existing_effect, effect)
		return
	
	# Add new effect
	status_effects.append(effect)
	effect.apply(self)
	
	# Update control state
	if effect.effect_type == Enums.StatusEffectType.CONTROL:
		_update_control_state()
	
	EventBus.status_effect_applied.emit(self, effect)
	_trigger_passive(Enums.TriggerCondition.ON_DEBUFF_APPLIED if effect.is_negative() else Enums.TriggerCondition.ON_BUFF_APPLIED, {"effect": effect})

## Remove a status effect
func remove_status_effect(effect: Resource) -> void:
	if effect == null or effect not in status_effects:
		return
	
	status_effects.erase(effect)
	effect.remove(self)
	
	# Update control state
	if effect.effect_type == Enums.StatusEffectType.CONTROL:
		_update_control_state()
	
	EventBus.status_effect_removed.emit(self, effect)

## Tick all status effects (called at turn start or end depending on effect)
func tick_status_effects(phase: Enums.TurnPhase) -> void:
	# Create a copy to iterate (in case effects are removed during tick)
	var effects_copy = status_effects.duplicate()
	
	for effect in effects_copy:
		if effect == null or effect not in status_effects:
			continue
		
		# Check if this effect ticks in this phase
		var should_tick = false
		if phase == Enums.TurnPhase.START and effect.get("ticks_on_turn_start"):
			should_tick = true
		elif phase == Enums.TurnPhase.END and effect.get("ticks_on_turn_end"):
			should_tick = true
		
		if should_tick:
			effect.tick(self)
			EventBus.status_effect_ticked.emit(self, effect)
			
			# Check if effect expired
			if effect.duration <= 0:
				remove_status_effect(effect)

func detonate_status_effects(effect: Resource) -> void:
	if effect == null or effect not in status_effects:
		return
	
	# find the effect
	var existing_effect = _find_existing_effect(effect.effect_name) 
	if existing_effect == null:
		return
	
	# check if it has a detonate effect and detonate the dot
	if existing_effect.has_method("detonate"):
		existing_effect.detonate(self)
	
	EventBus.status_effect_detonated.emit(self, effect)
	
	remove_status_effect(effect)
	 

## Find existing effect by name
func _find_existing_effect(effect_name: String) -> Resource:
	for effect in status_effects:
		if effect.effect_name == effect_name:
			return effect
	return null

## Handle stacking when same effect is applied
func _handle_effect_stacking(existing: Resource, new_effect: Resource) -> void:
	if new_effect.get("can_stack"):
		# Stack count increases
		existing.stack_count += 1
	
	# Always refresh duration
	existing.refresh_duration(new_effect.duration)
	
	EventBus.log_debug("Effect '%s' refreshed/stacked on '%s'" % [existing.effect_name, name], "StatusEffect")

## Check if effect lands (resistance check)
func _check_effect_lands(effect: Resource) -> bool:
	if effect.source_unit == null:
		return true  # No source unit, auto-land
	
	var source_unit = effect.source_unit
	if source_unit == null:
		return true
	
	# Calculate land chance
	var effectiveness = source_unit.current_stats.effectiveness if source_unit.current_stats else 0.0
	var resistance = current_stats.effect_resistance
	
	var land_chance = 0.90 + effectiveness - resistance  # 90% base + eff - res
	land_chance = clampf(land_chance, 0.0, 0.9)  # Min 0%, max 90%
	
	return randf() <= land_chance

# ============================================================================
# BUFF/DEBUFF QUERIES
# ============================================================================

## Get all buffs
func get_buffs() -> Array[Resource]:
	var buffs: Array[Resource] = []
	for effect in status_effects:
		if effect.effect_type == Enums.StatusEffectType.BUFF:
			buffs.append(effect)
	return buffs

## Get all debuffs
func get_debuffs() -> Array[Resource]:
	var debuffs: Array[Resource] = []
	for effect in status_effects:
		if effect.effect_type == Enums.StatusEffectType.DEBUFF or effect.effect_type == Enums.StatusEffectType.DOT:
			debuffs.append(effect)
	return debuffs

## Get all control effects
func get_control_effects() -> Array[Dictionary]:
	return _control_effects.duplicate()

## Check if unit has immunity
func has_immunity() -> bool:
	for effect in status_effects:
		if effect.effect_type == Enums.StatusEffectType.IMMUNITY:
			return true
	return false

func has_block() -> bool:
	for effect in status_effects:
		if effect.effect_type == Enums.StatusEffectType.BLOCK:
			return true
	return false

func has_antiheal() -> bool:
	for effect in status_effects:
		if effect.effect_type == Enums.StatusEffectType.ANTIHEAL:
			return true
	return false

## Check if unit has a specific status effect
func has_status_effect(effect_name: String) -> bool:
	return _find_existing_effect(effect_name) != null

# ============================================================================
# CONTROL STATE MANAGEMENT
# ============================================================================

## Check if unit is controlled
func is_controlled() -> bool:
	return _is_controlled

## Set controlled state (called by control effects)
func set_controlled(value: bool, control_type: Enums.ControlType = Enums.ControlType.STUN, source: Node = null) -> void:
	var was_controlled = _is_controlled
	
	if value:
		# Add control effect
		_control_effects.append({"control_type": control_type, "source": source})
		_is_controlled = true
		
		# Special handling for taunt
		if control_type == Enums.ControlType.TAUNT or control_type == Enums.ControlType.PROVOKE:
			taunt_target = source
			EventBus.unit_taunted.emit(self, source)
	else:
		# Remove control effect
		_control_effects = _control_effects.filter(func(c): return c.control_type != control_type or c.source != source)
		_is_controlled = not _control_effects.is_empty()
		
		if control_type == Enums.ControlType.TAUNT or control_type == Enums.ControlType.PROVOKE:
			taunt_target = null
	
	# If control state changed, emit signal
	if was_controlled != _is_controlled:
		if _is_controlled:
			EventBus.unit_controlled.emit(self, Enums.ControlType.keys()[control_type])
		else:
			EventBus.unit_uncontrolled.emit(self)

## Update control state based on current status effects
func _update_control_state() -> void:
	var has_control = false
	_control_effects.clear()
	taunt_target = null
	
	for effect in status_effects:
		if effect.effect_type == Enums.StatusEffectType.CONTROL:
			has_control = true
			var control_type = effect.get("control_type")
			_control_effects.append({"control_type": control_type, "source": effect.source_unit})
			
			if control_type == Enums.ControlType.TAUNT or control_type == Enums.ControlType.PROVOKE:
				taunt_target = effect.source_unit
	
	_is_controlled = has_control

## Check if unit can perform out-of-turn actions
func can_perform_out_of_turn_action() -> bool:
	if not _is_controlled:
		return true
	
	# Check specific control types
	for control in _control_effects:
		match control.control_type:
			Enums.ControlType.STUN, Enums.ControlType.FREEZE, Enums.ControlType.SLEEP:
				return false  # Cannot perform any out-of-turn actions
	
	return true

# ============================================================================
# ACTION READINESS (AR) MANAGEMENT
# ============================================================================

## Modify Action Readiness (push/pull)
func modify_ar(amount: float) -> void:
	var old_ar = action_readiness
	action_readiness += amount
	action_readiness = maxf(0.0, action_readiness)  # Can't go below 0
	
	if action_readiness != old_ar:
		EventBus.ar_changed.emit(self, action_readiness, old_ar)
		
		if amount > 0:
			EventBus.ar_pushed.emit(self, amount)
		elif amount < 0:
			EventBus.ar_pulled.emit(self, abs(amount))

## Set AR directly
func set_ar(value: float) -> void:
	var old_ar = action_readiness
	action_readiness = maxf(0.0, value)
	
	if action_readiness != old_ar:
		EventBus.ar_changed.emit(self, action_readiness, old_ar)

## Check if ready for turn (AR >= 100)
func is_ready_for_turn() -> bool:
	return action_readiness >= 100.0

# ============================================================================
# STAT QUERIES
# ============================================================================

## Get current stats (with all modifiers)
func get_stats() -> UnitStats:
	return current_stats

## Get effective value of a specific stat
func get_effective_stat(stat_type: Enums.StatType) -> float:
	if current_stats == null:
		return 0.0
	
	match stat_type:
		Enums.StatType.BASE_ATK:
			return current_stats.get_effective_atk()
		Enums.StatType.BASE_DEF:
			return current_stats.get_effective_def()
		Enums.StatType.SPEED:
			return current_stats.get_effective_speed()
		_:
			return current_stats.get_stat_value(stat_type)

# ============================================================================
# ABILITY USAGE
# ============================================================================

## Can this unit use its basic attack?
func can_use_basic_attack() -> bool:
	if basic_attack_data == null:
		return false
	
	return basic_attack_data.can_use(self)

## Can this unit use its ultimate?
func can_use_ultimate() -> bool:
	if ultimate_data == null:
		return false
	
	return ultimate_data.can_use(self)

## Use basic attack
func use_basic_attack(target) -> void:
	if not can_use_basic_attack():
		EventBus.show_error("Cannot use basic attack")
		return
	
	# Mark as used
	basic_attack_used_this_turn = true
	
	# Execute attack
	if battle_manager != null:
		await basic_attack_data.execute(self, target, battle_manager)
	else:
		push_error("Unit: battle_manager not set, cannot execute basic attack")
	
	# Trigger passives
	_trigger_passive(Enums.TriggerCondition.ON_ATTACK, {"target": target})

## Use ultimate
func use_ultimate(target) -> void:
	if not can_use_ultimate():
		EventBus.show_error("Cannot use ultimate")
		return
	
	# Mark as used
	ultimate_used_this_turn = true
	
	# Execute ultimate
	if battle_manager != null:
		await ultimate_data.execute(self, target, battle_manager)
	else:
		push_error("Unit: battle_manager not set, cannot execute ultimate")
	
	# Trigger passives
	_trigger_passive(Enums.TriggerCondition.ON_ULTIMATE_USE, {"target": target})

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

## Called at the start of this unit's turn
func on_turn_start() -> void:
	EventBus.log_debug("Unit '%s' turn started" % name, "Turn")
	
	# Reset turn-specific flags
	basic_attack_used_this_turn = false
	ultimate_used_this_turn = false
	
	# Tick status effects that trigger at turn start
	tick_status_effects(Enums.TurnPhase.START)
	
	# Decrement ultimate cooldown
	if ultimate_cooldown > 0:
		ultimate_cooldown -= 1
		EventBus.log_debug("Unit '%s' ultimate cooldown: %d" % [name, ultimate_cooldown], "Turn")
	
	# Reset AR to 0 (unit used up their turn)
	set_ar(0.0)
	
	# Trigger turn start passives
	_trigger_passive(Enums.TriggerCondition.ON_TURN_START, {})

## Called at the end of this unit's turn
func on_turn_end() -> void:
	EventBus.log_debug("Unit '%s' turn ended" % name, "Turn")
	
	# Tick status effects that trigger at turn end (INCLUDING CONTROL EFFECTS)
	tick_status_effects(Enums.TurnPhase.END)
	
	# Trigger turn end passives
	_trigger_passive(Enums.TriggerCondition.ON_TURN_END, {})

# ============================================================================
# PASSIVE TRIGGERS
# ============================================================================

## Trigger passive with specific condition
func _trigger_passive(condition: Enums.TriggerCondition, data: Dictionary) -> void:
	if passive == null or not passive.is_active:
		return
	
	# Check if unit has suppress status
	for control in _control_effects:
		if control.control_type == Enums.ControlType.SUPPRESS:
			return
	
	# Check if unit can perform out-of-turn actions (if this is not their turn)
	if condition != Enums.TriggerCondition.ON_TURN_START and condition != Enums.TriggerCondition.ON_TURN_END:
		if not can_perform_out_of_turn_action():
			return
	
	# Trigger the passive
	var did_interrupt = passive.on_trigger(condition, data)
	
	if did_interrupt:
		EventBus.passive_triggered.emit(self, passive.passive_name, data)

## Check if any mandatory passive should interrupt current effect
func check_for_mandatory_passive_interrupt() -> bool:
	if passive == null or not passive.is_active:
		return false
	
	return passive.is_mandatory

# ============================================================================
# UTILITY
# ============================================================================

## Get display name
func get_display_name() -> String:
	return name if name != "" else "Unknown Unit"

## Get team color (for UI)
func get_team_color() -> Color:
	return Color.BLUE if team == Enums.Team.PLAYER else Color.RED

## Debug string
func _to_string() -> String: # changed from to_string to _to_string
	return "%s [%s] HP:%d/%d AR:%.1f" % [
		name,
		Enums.team_to_string(team),
		current_hp,
		current_stats.max_hp if current_stats else 0,
		action_readiness
	]

## Set battle manager reference
func set_battle_manager(manager: Node) -> void:
	battle_manager = manager

# Counter

# Set counter chance
func set_counter_chance(chance: float) -> void:
	counter_chance = clampf(chance,0.0,1.0)

# Get counter chance
func get_counter_chance() -> float:
	return counter_chance

# add counter chance
func add_counter_chance(chance: float) -> void:
	counter_chance = clampf(counter_chance + chance,0.0,1.0)

# subtract counter chance
func subtract_counter_chance(chance: float) -> void:
	counter_chance = clampf(counter_chance - chance,0.0,1.0)
	
# check if you get to counter
func should_counter() -> bool:
	if counter_chance <= 0:
		return false
	return randf() <= current_stats.counter_rate
	# return randf() <= counter_chance

## Perform counter attack
func counter_attack(attacker: Node) -> void:
	if not is_alive() or not attacker.is_alive():
		return
	
	if is_controlled():
		EventBus.log_debug("%s is controlled, cannot counter" % name, "Unit")
		return
	
	EventBus.log_debug("%s counters %s!" % [name, attacker.name], "Unit")
	
	# Counter with basic attack
	if !has_countered:
		await use_basic_attack(attacker)
		has_countered = false
	has_countered = true

# ============================================================================
# EVASION SYSTEM
# ============================================================================

	
## Check if should evade (random roll)
func should_evade() -> bool:
	if current_stats.evasion <= 0.0:
		return false
	return randf() <= current_stats.evasion
	# return randf() <= evasion_chance

# ==============================================================================
# Death Prevention
# ==============================================================================

func set_death_prevention(value: bool) -> void:
	has_death_prevention = value
	if value:
		EventBus.log_debug("%s gained death prevention" % name, "Unit")
	else:
		EventBus.log_debug("%s lost death prevention" % name, "Unit")

func get_death_prevention():
	return has_death_prevention
	
func grant_death_prevention():
	set_death_prevention(true)

func remove_death_prevention():
	set_death_prevention(false)

## Clean up when unit is removed
func cleanup() -> void:
	# Remove all status effects
	for effect in status_effects.duplicate():
		remove_status_effect(effect)
	
	# Deactivate passive
	if passive != null:
		passive.deactivate()
		
	if has_death_prevention != null:
		has_death_prevention = false
	
	status_effects.clear()
	_control_effects.clear()
