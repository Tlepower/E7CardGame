extends Resource
class_name ElfQueenUnitData

static func create() -> UnitData:
	var unit = UnitData.new()
	
	# Basic info
	unit.unit_name = "ElfQueen"
	unit.description = "ElfQueen is a support that buffs all allies with atk buffs and shields.
	 she even have global AR avance, with more for jade units"
	unit.rarity = "Epic"
	unit.Type = Enums.ElementType.JADE
	
	# Stats
	unit.base_stats = create_stats()
	
	# Abilities
	unit.passive_script = create_passive()
	unit.skill1_card_data = create_skill1(unit.unit_name)
	unit.skill2_card_data = create_skill2(unit.unit_name)
	unit.ultimate_data = create_ultimate()
	unit.basic_attack_data = create_basic_attack()
	
	return unit

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 1400
	stats.base_atk = 85 # weak attackr
	stats.base_def = 65   
	stats.speed = 112 # above average speed
	stats.crit_rate = 0.1  
	stats.crit_damage = 1.5
	stats.effectiveness = 0.25
	stats.effect_resistance = 0.25
	return stats

static func create_passive() -> Script:
	# return load("res://Scripts/Passives/FullTestEvasion.gd")
	return null # for now

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "Light geus"
	basic.description = "Average basis attack"
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.PHYSICAL
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic

static func create_skill1(name: String) -> CardData:
	var skill = CardData.new()
	skill.card_name = "Queen's commands"
	skill.description = "Give a single ally a 1 turn 30% atk buff and advance them by 15%"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 0
	skill.is_quick_play = true 
	skill.target_type = Enums.TargetType.SINGLE_ALLY
	skill.owner_unit_name = name
	
	var atk_buff = StatusEffect.new()
	atk_buff.effect_name = "ATK Up"
	atk_buff.description = "+30% ATK"
	atk_buff.effect_type = Enums.StatusEffectType.BUFF
	atk_buff.base_duration = 1
	atk_buff.stat_modifiers = {"atk_percent": 1.3}
	atk_buff.can_be_dispelled = true
	atk_buff.ticks_on_turn_start = true
	atk_buff.duration_decreases_on_start = true
	
	var ar_advance = ARManipulationEffect.new()
	ar_advance.is_push = true
	ar_advance.ar_amount = 15.0
	
	var buff = BuffEffect.new()
	buff.status_effect_template = atk_buff
	buff.duration = atk_buff.base_duration
	
	skill.effects.append(buff)
	skill.effects.append(ar_advance)
	
	return skill

static func create_skill2(name: String) -> CardData:
	var skill = CardData.new()
	skill.card_name = "Heartwood blessing"
	skill.description = ""
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 1
	skill.is_quick_play = true 
	skill.target_type = Enums.TargetType.SINGLE_ALLY
	skill.owner_unit_name = name
	
	var shieldbuff = ShieldEffect.new()
	shieldbuff.shield_multiplier = 20.0
	shieldbuff.is_max_hp_based = true
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Aegis of the fist star"
	ult.description = "Advance all allies by 25%"
	ult.cooldown = 3
	ult.starting_cooldown = 0
	ult.target_type = Enums.TargetType.ALL_ALLIES
	
	var ar_advance = ARManipulationEffect.new()
	ar_advance.ar_amount = 25.0
	ar_advance.is_push = true
	
	ult.effects.append(ar_advance)
	
	return ult
