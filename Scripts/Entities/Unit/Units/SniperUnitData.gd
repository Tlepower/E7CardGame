extends Resource
class_name SniperUnitData

static func create() -> UnitData:
	var unit = UnitData.new()
	
	# Basic info
	unit.unit_name = "Apdonia"
	unit.description = "A Sniper who goes to stealth and loads bullets to fire short cooldown Ultimates"
	unit.rarity = "Rare"
	
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
	stats.max_hp = 860
	stats.base_atk = 106
	stats.base_def = 78   
	stats.speed = 110 # Ok speed    
	stats.crit_rate = 0.3  # 30%  
	stats.crit_damage = 1.9  # 190% crit dmg base
	stats.effectiveness = 0.1
	stats.effect_resistance = 0.05
	return stats

static func create_passive() -> Script:
	# return load("res://Scripts/Passives/FullTestEvasion.gd")
	var passive = Passive.new()
	return null

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "One Shot"
	basic.description = "Quick precise shot"
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.PHYSICAL
	basic.def_ignore = 0.15  # Piercing attacks
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Loading the Bullet"
	skill.description = "Gain one bullet and reduce the CD of Apdonia's ultimate by 1"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 1
	skill.is_quick_play = true  # Quick attack!
	skill.target_type = Enums.TargetType.SELF
	skill.owner_unit_name = "Apdonia"
	
	var cdskill = CDModificationEffect.new()
	cdskill.CD_Amount = 1
	cdskill.is_decrease = true
	cdskill.target_type = Enums.TargetType.SELF
	
	skill.effects.append(cdskill)
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Draw Shot"
	skill.description = "Deal high damage, if crit then gain extra turn"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 1
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Apdonia"
	
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 2.9 # 290% damage
	damage.target_type = Enums.TargetType.SINGLE_ENEMY
	damage.can_crit = true
	
	var extraturn = GainExtraTurn.new()
	extraturn.target_type = Enums.TargetType.SELF
	
	skill.effects.append(extraturn)
	skill.effects.append(damage)
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Take the Shot"
	ult.description = "Deal huge damage that consumes 1 bullet, gains 1 turn stealth, and always crits"
	ult.cooldown = 2
	ult.starting_cooldown = 2
	ult.target_type = Enums.TargetType.SINGLE_ENEMY
	
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 4.5 # 450% base damage
	damage.target_type = Enums.TargetType.SINGLE_ENEMY
	damage.can_crit = true 
	damage.force_crit = true # will guarantee crit attack
	damage.hit_count = 1
	
	var stealth = Stealth.new()
	
	var buff_effect = BuffEffect.new()
	buff_effect.status_effect_template = stealth
	buff_effect.duration = 1 # 1 turn
	buff_effect.target_type = Enums.TargetType.SELF
	
	ult.effects.append(damage)
	ult.effects.append(buff_effect)
	return ult
