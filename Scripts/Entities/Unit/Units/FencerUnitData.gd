# Fencer Unit Data - Evasive Duelist
# Quick attacks, evasion chance, taunt ultimate
# Fast, agile, defensive specialist

extends Resource
class_name FencerUnitData

static func create() -> UnitData:
	var fencer = UnitData.new()
	
	# Basic info
	fencer.unit_name = "Fencer"
	fencer.description = "An agile duelist who evades attacks and provokes enemies"
	fencer.rarity = "Epic"
	
	# Stats
	fencer.base_stats = create_stats()
	
	# Abilities
	fencer.passive_script = load("res://Scripts/Passives/EvasionPassive.gd")
	fencer.skill1_card_data = create_skill1()
	fencer.skill2_card_data = create_skill2()
	fencer.ultimate_data = create_ultimate()
	fencer.basic_attack_data = create_basic_attack()
	
	return fencer

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 1000  # Moderate HP
	stats.base_atk = 135  # High damage
	stats.base_def = 60   # Low defense (relies on evasion)
	stats.speed = 120     # Very fast!
	stats.crit_rate = 0.35  # 35% - High crit
	stats.crit_damage = 1.8  # 180%
	stats.effectiveness = 0.25
	stats.effect_resistance = 0.20
	return stats

static func create_passive() -> Script:
	# Evasion passive - gains evasion at battle start
	return load("res://Scripts/Passives/EvasionPassive.gd")

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "Rapier Thrust"
	basic.description = "Quick precise strike"
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.PHYSICAL
	basic.def_ignore = 0.15  # Piercing attacks
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Flurry"
	skill.description = "Rapid multi-hit attack"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = true  # Quick attack!
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Fencer"
	
	# Fast multi-hit damage
	var damage1 = DamageEffect.new()
	damage1.is_atk_based = true
	damage1.atk_multiplier = 0.7  # 70% ATK
	damage1.damage_type = Enums.DamageType.PHYSICAL
	damage1.def_ignore = 0.2  # 20% DEF ignore
	damage1.can_crit = true
	
	var damage2 = DamageEffect.new()
	damage2.is_atk_based = true
	damage2.atk_multiplier = 0.7  # 70% ATK
	damage2.damage_type = Enums.DamageType.PHYSICAL
	damage2.def_ignore = 0.2
	damage2.can_crit = true
	
	var damage3 = DamageEffect.new()
	damage3.is_atk_based = true
	damage3.atk_multiplier = 0.7  # 70% ATK
	damage3.damage_type = Enums.DamageType.PHYSICAL
	damage3.def_ignore = 0.2
	damage3.can_crit = true
	
	# Total: 3 hits × 70% = 210% ATK damage!
	
	skill.effects = [damage1, damage2, damage3]
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Parry"
	skill.description = "Gain massive evasion and counter buff"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = true  # Quick defense!
	skill.target_type = Enums.TargetType.SELF
	skill.owner_unit_name = "Fencer"
	
	# Grant high evasion
	var evasion = Evasion.new(0.6, 2)  # 60% evasion for 2 turns
	
	var evasion_effect = BuffEffect.new()
	evasion_effect.status_effect_template = evasion
	evasion_effect.duration = 2
	
	# Grant counter
	var counter = Counter.new(0.5, 2)  # 50% counter for 2 turns
	
	var counter_effect = BuffEffect.new()
	counter_effect.status_effect_template = counter
	counter_effect.duration = 2
	
	skill.effects = [evasion_effect, counter_effect]
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "En Garde!"
	ult.description = "Force enemy to duel you with undispellable taunt"
	ult.cooldown = 4
	ult.starting_cooldown = 2
	ult.target_type = Enums.TargetType.SINGLE_ENEMY
	
	# Damage
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 2.0  # 200% ATK
	damage.damage_type = Enums.DamageType.PHYSICAL
	damage.def_ignore = 0.25
	damage.can_crit = true
	
	#Taunt for 2 turns!
	var taunt = Taunt.new(2)  # 2 turns, undispellable = true
	
	var taunt_effect = DebuffEffect.new()
	taunt_effect.status_effect_template = taunt
	taunt_effect.duration = 2
	taunt_effect.application_chance = 1.0  # 100% chance
	
	# Self evasion buff (survive the duel!)
	var evasion = Evasion.new(0.4, 2)  # 40% evasion for 2 turns
	
	var evasion_buff = BuffEffect.new()
	evasion_buff.status_effect_template = evasion
	evasion_buff.duration = 2
	
	ult.effects = [damage, taunt_effect, evasion_buff]
	
	return ult
