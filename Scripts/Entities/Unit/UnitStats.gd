extends Resource
class_name UnitStats
## UnitStats - Data container for unit statistics
## This is used both for base stats and runtime modified stats

# ============================================================================
# BASE STATS
# ============================================================================

## Maximum hit points
@export var max_hp: int = 1000

## Base attack power (used in damage calculations)
@export var base_atk: int = 100

## Base defense (used in damage reduction calculations)
@export var base_def: int = 50

## Speed stat - determines turn order (1-200+ range typical)
@export var speed: int = 100

## Counter stat - chances for countering with basic attack (50% to counter = 0.5) 
@export var counter_rate : float = 0.0

## Evasion stat - chance for evade an attack (30% to evade = 0.3)
@export var evasion: float = 0.0

# ============================================================================
# OFFENSIVE STATS
# ============================================================================

## Critical hit chance (0.0 - 1.0, default 0.1 = 10%)
@export_range(0.0, 1.0, 0.01) var crit_rate: float = 0.1

## Critical damage multiplier (default 1.5 = 150% = +50% damage on crit)
@export var crit_damage: float = 1.5

## Effectiveness - increases chance to apply debuffs (0.0 - 2.0+)
@export_range(0.0, 3.0, 0.01) var effectiveness: float = 0.0

# ============================================================================
# DEFENSIVE STATS
# ============================================================================

## Effect resistance - reduces chance of receiving debuffs (0.0 - 1.0)
@export_range(0.0, 1.0, 0.01) var effect_resistance: float = 0.0

# ============================================================================
# PERCENTAGE MODIFIERS (applied by buffs/debuffs)
# ============================================================================

## Multiplicative ATK modifier (1.0 = 100% = no change)
## Example: 1.5 = +50% ATK, 0.7 = -30% ATK
var atk_percent: float = 1.0

## Multiplicative DEF modifier (1.0 = 100% = no change)
var def_percent: float = 1.0

## Multiplicative Speed modifier (1.0 = 100% = no change)
var speed_percent: float = 1.0

## Damage multiplier - final damage output modifier (1.0 = normal)
var damage_multiplier: float = 1.0

## Damage taken multiplier - incoming damage modifier (1.0 = normal)
## Example: 1.3 = take 30% more damage, 0.7 = take 30% less damage
var damage_taken_multiplier: float = 1.0

# ============================================================================
# COMPUTED STATS (read-only, calculated on demand)
# ============================================================================

## Initialize the base stats from gears, weapons, and other stat modifications
func initialize_gear_stats() -> void:
	var c = 5

## Get effective ATK with all modifiers applied
func get_effective_atk() -> int:
	return int(base_atk * atk_percent)

## Get effective DEF with all modifiers applied
func get_effective_def() -> int:
	return int(base_def * def_percent)

## Get effective Speed with all modifiers applied
func get_effective_speed() -> int:
	return int(speed * speed_percent)

## Get a specific stat value by type
func get_stat_value(stat_type: Enums.StatType) -> float:
	match stat_type:
		Enums.StatType.MAX_HP:
			return max_hp
		Enums.StatType.BASE_ATK:
			return base_atk
		Enums.StatType.BASE_DEF:
			return base_def
		Enums.StatType.SPEED:
			return speed
		Enums.StatType.CRIT_RATE:
			return crit_rate
		Enums.StatType.CRIT_DAMAGE:
			return crit_damage
		Enums.StatType.EFFECTIVENESS:
			return effectiveness
		Enums.StatType.EFFECT_RESISTANCE:
			return effect_resistance
		Enums.StatType.ATK_PERCENT:
			return atk_percent
		Enums.StatType.DEF_PERCENT:
			return def_percent
		Enums.StatType.SPEED_PERCENT:
			return speed_percent
		Enums.StatType.COUNTER_RATE:
			return counter_rate
		Enums.StatType.EVASION:
			return evasion
		_:
			push_error("Unknown stat type: %s" % stat_type)
			return 0.0

# ============================================================================
# MODIFIER FUNCTIONS
# ============================================================================

## Apply a percentage modifier to ATK
func modify_atk_percent(modifier: float) -> void:
	atk_percent *= modifier
	atk_percent = maxf(0.0, atk_percent)  # Can't go below 0

## Apply a percentage modifier to DEF
func modify_def_percent(modifier: float) -> void:
	def_percent *= modifier
	def_percent = maxf(0.0, def_percent)

## Apply a percentage modifier to Speed
func modify_speed_percent(modifier: float) -> void:
	speed_percent *= modifier
	speed_percent = maxf(0.0, speed_percent)

## Add flat crit rate (clamped to 0-1)
func add_crit_rate(amount: float) -> void:
	crit_rate = clampf(crit_rate + amount, 0.0, 1.0)

## Add flat crit damage
func add_crit_damage(amount: float) -> void:
	crit_damage = maxf(1.0, crit_damage + amount)

## Add flat effectiveness
func add_effectiveness(amount: float) -> void:
	effectiveness = maxf(0.0, effectiveness + amount)

## Add flat effect resistance (clamped to 0-1)
func add_effect_resistance(amount: float) -> void:
	effect_resistance = clampf(effect_resistance + amount, 0.0, 1.0)
	
func add_counter_rate(amount: float) -> void:
	counter_rate = clampf(counter_rate + amount, 0.0, 1.0)

func add_evasion(amount: float) -> void:
	evasion = clampf(evasion + amount, 0.0, 1.0)

# ============================================================================
# RESET FUNCTIONS
# ============================================================================

## Reset all percentage modifiers to baseline (1.0)
func reset_modifiers() -> void:
	atk_percent = 1.0
	def_percent = 1.0
	speed_percent = 1.0
	damage_multiplier = 1.0
	damage_taken_multiplier = 1.0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

## Create a deep copy of this UnitStats
func duplicate_stats() -> UnitStats:
	var new_stats := UnitStats.new()
	
	# Copy base stats
	new_stats.max_hp = max_hp
	new_stats.base_atk = base_atk
	new_stats.base_def = base_def
	new_stats.speed = speed
	new_stats.crit_rate = crit_rate
	new_stats.crit_damage = crit_damage
	new_stats.effectiveness = effectiveness
	new_stats.effect_resistance = effect_resistance
	new_stats.counter_rate = counter_rate
	new_stats.evasion = evasion
	
	# Copy modifiers
	new_stats.atk_percent = atk_percent
	new_stats.def_percent = def_percent
	new_stats.speed_percent = speed_percent
	new_stats.damage_multiplier = damage_multiplier
	new_stats.damage_taken_multiplier = damage_taken_multiplier
	
	return new_stats

## Copy stats from another UnitStats instance
func copy_from(other: UnitStats) -> void:
	max_hp = other.max_hp
	base_atk = other.base_atk
	base_def = other.base_def
	speed = other.speed
	crit_rate = other.crit_rate
	crit_damage = other.crit_damage
	effectiveness = other.effectiveness
	effect_resistance = other.effect_resistance
	atk_percent = other.atk_percent
	def_percent = other.def_percent
	speed_percent = other.speed_percent
	damage_multiplier = other.damage_multiplier
	damage_taken_multiplier = other.damage_taken_multiplier
	counter_rate = other.counter_rate
	evasion = other.evasion

## Get a debug string representation
func _to_string() -> String: # Changed to_string to _to_string
	return "HP:%d ATK:%d(%d) DEF:%d(%d) SPD:%d(%d) CR:%.1f%% CD:%.1f%%" % [
		max_hp,
		base_atk, get_effective_atk(),
		base_def, get_effective_def(),
		speed, get_effective_speed(),
		crit_rate * 100,
		crit_damage * 100
	]
