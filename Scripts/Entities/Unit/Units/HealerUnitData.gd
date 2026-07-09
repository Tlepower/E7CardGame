# Healer Unit Data - Example Test Unit
# This script creates a UnitData resource for a Healer character

extends Resource
class_name HealerUnitData

static func create() -> UnitData:
	var healer = UnitData.new()
	
	# Basic info
	healer.unit_name = "Healer"
	healer.description = "A supportive healer who keeps the team alive"
	healer.rarity = "Epic"
	
	# Stats
	healer.base_stats = create_stats()
	
	# Abilities
	healer.passive_script = null  # No passive for now
	healer.skill1_card_data = create_skill1()
	healer.skill2_card_data = create_skill2()
	healer.ultimate_data = create_ultimate()
	healer.basic_attack_data = create_basic_attack()
	
	return healer

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 1000
	stats.base_atk = 100
	stats.base_def = 70
	stats.speed = 110  # Faster than average
	stats.crit_rate = 0.10  # 10%
	stats.crit_damage = 1.5  # 150%
	stats.effectiveness = 0.05
	stats.effect_resistance = 0.25  # High resistance
	return stats

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Healing Light"
	skill.description = "Heal an ally for 50% of their max HP"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SINGLE_ALLY
	skill.owner_unit_name = "Healer"
	
	# Add heal effect
	var heal = HealEffect.new()
	heal.is_max_hp_based = true
	heal.max_hp_percent = 0.5  # 50% of target's max HP
	
	skill.effects.append(heal)
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Purify"
	skill.description = "Cleanse all debuffs from an ally"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 1
	skill.is_quick_play = true  # Can respond to debuffs!
	skill.target_type = Enums.TargetType.SINGLE_ALLY
	skill.owner_unit_name = "Healer"
	
	# Add cleanse effect
	var cleanse = CleanseEffect.new()
	cleanse.remove_all = true  # Remove all debuffs
	
	skill.effects.append(cleanse)
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Divine Blessing"
	ult.description = "Heal all allies and grant immunity"
	ult.cooldown = 4
	ult.starting_cooldown = 0  # Available at start
	ult.target_type = Enums.TargetType.ALL_ALLIES
	
	# AOE heal effect
	var heal = HealEffect.new()
	heal.is_max_hp_based = true
	heal.max_hp_percent = 0.3  # 30% of each target's max HP
	
	# Immunity buff
	var immunity = StatusEffect.new()
	immunity.effect_name = "Immunity"
	immunity.description = "Cannot be debuffed"
	immunity.effect_type = Enums.StatusEffectType.IMMUNITY
	immunity.base_duration = 2
	immunity.can_be_dispelled = true
	immunity.ticks_on_turn_start = true
	immunity.duration_decreases_on_start = true
	
	var buff = BuffEffect.new()
	buff.status_effect_template = immunity
	buff.duration = 2
	buff.target_type = Enums.TargetType.ALL_ALLIES
	
	ult.effects.append(buff)
	ult.effects.append(heal)
	
	return ult

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "Staff Strike"
	basic.description = "A weak staff attack"
	basic.atk_multiplier = 0.8  # Weaker than normal
	basic.damage_type = Enums.DamageType.PHYSICAL
	basic.def_ignore = 0.0
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic
