# Warrior Unit Data - Example Test Unit
# This script creates a UnitData resource for a Warrior character
# To use: Create a .tres file and attach this script, or create in code

extends Resource
class_name WarriorUnitData

static func create() -> UnitData:
	var warrior = UnitData.new()
	
	# Basic info
	warrior.unit_name = "Warrior"
	warrior.description = "A brave warrior with high HP and defense"
	warrior.rarity = "Common"
	
	# Stats
	warrior.base_stats = create_stats()
	
	# Abilities
	warrior.passive_script = create_passive()
	warrior.skill1_card_data = create_skill1()
	warrior.skill2_card_data = create_skill2()
	warrior.ultimate_data = create_ultimate()
	warrior.basic_attack_data = create_basic_attack()
	
	return warrior

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 1200
	stats.base_atk = 120
	stats.base_def = 80
	stats.speed = 95
	stats.crit_rate = 0.15  # 15%
	stats.crit_damage = 1.5  # 150%
	stats.effectiveness = 0.1
	stats.effect_resistance = 0.2
	return stats

static func create_passive() -> Script:
	# TODO: Create actual passive script
	# For now, return null (no passive)
	return null

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Power Strike"
	skill.description = "Deal heavy damage to an enemy"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Warrior"
	
	# Add damage effect
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 1.5  # 150% ATK
	damage.damage_type = Enums.DamageType.PHYSICAL
	damage.def_ignore = 0.0
	damage.can_crit = true
	
	skill.effects.append(damage)
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Battle Cry"
	skill.description = "Increase own ATK for 2 turns"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 1
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SELF
	skill.owner_unit_name = "Warrior"
	
	# Create ATK buff status effect
	var atk_buff = StatusEffect.new()
	atk_buff.effect_name = "ATK Up"
	atk_buff.description = "+30% ATK"
	atk_buff.effect_type = Enums.StatusEffectType.BUFF
	atk_buff.base_duration = 2
	atk_buff.stat_modifiers = {"atk_percent": 1.3}  # +30% ATK
	atk_buff.can_be_dispelled = true
	atk_buff.ticks_on_turn_start = true
	atk_buff.duration_decreases_on_start = true
	
	# Add buff effect
	var buff = BuffEffect.new()
	buff.status_effect_template = atk_buff
	buff.duration = 2
	
	skill.effects.append(buff)	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Devastating Slash"
	ult.description = "Deal massive damage and reduce enemy DEF"
	ult.cooldown = 4
	ult.starting_cooldown = 2
	ult.target_type = Enums.TargetType.SINGLE_ENEMY
	
	# Damage effect
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 2.5  # 250% ATK
	damage.damage_type = Enums.DamageType.PHYSICAL
	damage.def_ignore = 0.2  # Ignore 20% DEF
	damage.can_crit = true
	
	# DEF debuff
	var def_debuff = StatusEffect.new()
	def_debuff.effect_name = "DEF Down"
	def_debuff.description = "-30% DEF"
	def_debuff.effect_type = Enums.StatusEffectType.DEBUFF
	def_debuff.base_duration = 2
	def_debuff.stat_modifiers = {"def_percent": 0.7}  # -30% DEF
	def_debuff.can_be_cleansed = true
	def_debuff.ticks_on_turn_start = true
	def_debuff.duration_decreases_on_start = true
	
	var debuff = DebuffEffect.new()
	debuff.status_effect_template = def_debuff
	debuff.duration = 2
	debuff.application_chance = 0.85  # 85% chance
	
	ult.effects.append(damage)
	ult.effects.append(def_debuff)
	
	return ult

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "Slash"
	basic.description = "A basic sword slash"
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.PHYSICAL
	basic.def_ignore = 0.0
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic
