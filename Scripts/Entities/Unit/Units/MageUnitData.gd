# Mage Unit Data - Example Test Unit
# This script creates a UnitData resource for a Mage character

extends Resource
class_name MageUnitData

static func create() -> UnitData:
	var mage = UnitData.new()
	
	# Basic info
	mage.unit_name = "Mage"
	mage.description = "A powerful mage with high ATK and AOE damage"
	mage.rarity = "Rare"
	
	# Stats
	mage.base_stats = create_stats()
	
	# Abilities
	mage.passive_script = null  # No passive for now
	mage.skill1_card_data = create_skill1()
	mage.skill2_card_data = create_skill2()
	mage.ultimate_data = create_ultimate()
	mage.basic_attack_data = create_basic_attack()
	
	return mage

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 900
	stats.base_atk = 150
	stats.base_def = 50
	stats.speed = 105
	stats.crit_rate = 0.20  # 20%
	stats.crit_damage = 1.8  # 180%
	stats.effectiveness = 0.15
	stats.effect_resistance = 0.1
	return stats

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Fireball"
	skill.description = "Deal fire damage to an enemy"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Mage"
	
	# Add damage effect
	var damage = DamageEffect.new()
	damage.dmg_type = Enums.MultiplierBase.ATK_based
	damage.atk_multiplier = 1.6  # 160% ATK
	damage.damage_type = Enums.DamageType.MAGICAL
	damage.def_ignore = 0.0
	damage.can_crit = true
	
	# Add burn DOT
	var burn = StatusEffect.new()
	burn.effect_name = "Burn"
	burn.description = "Take fire damage each turn"
	burn.effect_type = Enums.StatusEffectType.DOT
	burn.base_duration = 2
	burn.is_atk_based = true
	burn.atk_multiplier = 0.3  # 30% ATK per turn
	burn.can_be_cleansed = true
	burn.ticks_on_turn_start = true
	burn.duration_decreases_on_start = true
	
	var debuff = DebuffEffect.new()
	debuff.status_effect_template = burn
	debuff.duration = 2
	debuff.application_chance = 0.75  # 75% chance
	
	skill.effects.append(damage)
	skill.effects.append(debuff)
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Arcane Shield"
	skill.description = "Grant shield to an ally"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = true  # Can be used as response!
	skill.target_type = Enums.TargetType.SINGLE_ALLY
	skill.owner_unit_name = "Mage"
	
	# Add shield effect
	var shield = ShieldEffect.new()
	shield.is_atk_based = true
	shield.atk_multiplier = 1.0  # 100% ATK shield
	shield.duration = 2
	
	skill.effects.append(shield)
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Meteor Storm"
	ult.description = "Deal massive AOE damage to all enemies"
	ult.cooldown = 5
	ult.starting_cooldown = 3
	ult.target_type = Enums.TargetType.ALL_ENEMIES
	
	# AOE damage effect
	var damage = DamageEffect.new()
	damage.dmg_type = Enums.MultiplierBase.ATK_based
	damage.atk_multiplier = 2.0  # 200% ATK
	damage.damage_type = Enums.DamageType.MAGICAL
	damage.def_ignore = 0.1  # Ignore 10% DEF
	damage.can_crit = true
	damage.apply_to_all_at_once = false  # Apply individually for passive triggers
	
	ult.effects.append(damage)
	
	return ult

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "Magic Bolt"
	basic.description = "Fire a bolt of magic energy"
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.MAGICAL
	basic.def_ignore = 0.0
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic
