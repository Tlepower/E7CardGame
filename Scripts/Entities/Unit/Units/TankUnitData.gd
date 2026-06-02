# Tank Unit Data - Counter-focused defender
# Built-in counter chance, grants counter to team
# Passively counters when attacked

extends Resource
class_name TankUnitData

static func create() -> UnitData:
	var tank = UnitData.new()
	
	# Basic info
	tank.unit_name = "Tank"
	tank.description = "Defensive unit that counters all attacks"
	tank.rarity = "Epic"
	
	# Stats
	tank.base_stats = create_stats()
	
	# Abilities
	tank.passive_script = load("res://Scripts/Passives/CounterPassive.gd")
	tank.skill1_card_data = create_skill1()
	tank.skill2_card_data = create_skill2()
	tank.ultimate_data = create_ultimate()
	tank.basic_attack_data = create_basic_attack()
	
	return tank

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 1400  # Very tanky
	stats.base_atk = 110  # Lower damage
	stats.base_def = 100  # Highest defense
	stats.speed = 85     # Slow
	stats.crit_rate = 0.05  # Low crit
	stats.crit_damage = 1.5
	stats.effectiveness = 0.10
	stats.effect_resistance = 0.35  # High resistance
	return stats

static func create_passive() -> Script:
	# Counter passive - gains counter at battle start
	return load("res://Scripts/Passives/CounterPassive.gd")

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "Shield Bash"
	basic.description = "Heavy shield strike"
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.PHYSICAL
	basic.def_ignore = 0.0
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Counter Stance"
	skill.description = "Gain 100% counter chance for 2 turns"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = true  # Can respond!
	skill.target_type = Enums.TargetType.SELF
	skill.owner_unit_name = "Tank"
	
	# Grant self massive counter
	var counter = CounterEffect.new(1.0, 2, 1)  # 100% counter for 2 turns
	
	skill.effects = [counter]
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Defensive Formation"
	skill.description = "Grant ally 50% counter and DEF buff"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SINGLE_ALLY
	skill.owner_unit_name = "Tank"
	
	# Grant counter
	var counter = CounterEffect.new(0.5, 3, 1)  # 50% counter for 3 turns
	
	# Grant DEF buff
	var def_buff = DEFBuff.new(0.5, 3)  # +50% DEF for 3 turns
	
	var buff = BuffEffect.new()
	buff.status_effect_template = def_buff
	buff.duration = 3
	
	skill.effects = [counter, buff]
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Fortress Wall"
	ult.description = "Grant ALL allies counter and taunt enemies"
	ult.cooldown = 5
	ult.starting_cooldown = 2
	ult.target_type = Enums.TargetType.ALL_ALLIES
	
	# AOE counter buff
	var counter = CounterEffect.new(0.75, 3, 1)  # 75% counter for all!
	
	# DEF buff
	var def_buff = DEFBuff.new(0.4, 3)  # +40% DEF
	
	var buff = BuffEffect.new()
	buff.status_effect_template = def_buff
	buff.duration = 3
	
	ult.effects = [counter, buff]
	
	return ult
