# meta-name: Unit Maker
# meta-description: Basic Model for every unit data
extends Resource

static func create() -> UnitData:
	var unit = UnitData.new()
	
	# Basic info
	unit.unit_name = ""
	unit.description = ""
	unit.rarity = "Common"
	
	# Stats
	unit.base_stats = create_stats()
	
	# Abilities
	unit.passive_script = create_passive()
	unit.skill1_card_data = create_skill1()
	unit.skill2_card_data = create_skill2()
	unit.ultimate_data = create_ultimate()
	unit.basic_attack_data = create_basic_attack()
	
	return unit

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 1000
	stats.base_atk = 100 
	stats.base_def = 70   
	stats.speed = 100    
	stats.crit_rate = 0.1  
	stats.crit_damage = 1.5
	stats.effectiveness = 0.25
	stats.effect_resistance = 0.25
	return stats

static func create_passive() -> Script:
	# return load("res://Scripts/Passives/FullTestEvasion.gd")
	var passive = Passive.new()
	return passive

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = ""
	basic.description = ""
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.PHYSICAL
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = ""
	skill.description = ""
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 1
	skill.is_quick_play = false 
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "" # Name of the character
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = ""
	skill.description = ""
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 1
	skill.is_quick_play = false 
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "" # Name of the character
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = ""
	ult.description = ""
	ult.cooldown = 3
	ult.starting_cooldown = 1
	ult.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return ult
