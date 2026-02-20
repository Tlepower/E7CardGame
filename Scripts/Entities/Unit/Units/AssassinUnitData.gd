# Assassin Unit Data - Stealth-based Quick Play Specialist
# Gains stealth on turn start, loses it when hit
# All skills are Quick Play cards

extends Resource
class_name AssassinUnitData

static func create() -> UnitData:
	var assassin = UnitData.new()
	
	# Basic info
	assassin.unit_name = "Assassin"
	assassin.description = "A stealthy assassin who strikes from the shadows with quick reflexes"
	assassin.rarity = "Epic"
	
	# Stats
	assassin.base_stats = create_stats()
	
	# Abilities
	assassin.passive_script = create_passive()
	assassin.skill1_card_data = create_skill1()
	assassin.skill2_card_data = create_skill2()
	assassin.ultimate_data = create_ultimate()
	assassin.basic_attack_data = create_basic_attack()
	
	return assassin

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 850  # Fragile
	stats.base_atk = 160  # High damage
	stats.base_def = 40   # Low defense
	stats.speed = 125     # Very fast!
	stats.crit_rate = 0.30  # 30% - High crit
	stats.crit_damage = 2.0  # 200% - High crit damage
	stats.effectiveness = 0.20
	stats.effect_resistance = 0.15
	return stats

static func create_passive() -> Script:
	# Stealth passive - gains stealth at turn start
	return load("res://Scripts/Passives/StealthPassive.gd")

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Shadow Strike"
	skill.description = "Quick strike that cuts enemy DEF"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = true  # Quick Play!
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Assassin"
	
	# Damage effect
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 1.4  # 140% ATK
	damage.damage_type = Enums.DamageType.PHYSICAL
	damage.def_ignore = 0.15  # Ignore 15% DEF
	damage.can_crit = true
	
	# DEF debuff
	var def_debuff = DEFDebuff.new(0.4, 2)  # -40% DEF for 2 turns
	
	var debuff = DebuffEffect.new()
	debuff.status_effect_template = def_debuff
	debuff.duration = 2
	debuff.application_chance = 0.85  # 85% chance
	
	skill.effects.append(damage)
	skill.effects.append(debuff)
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Poison Blade"
	skill.description = "Apply multiple poison stacks"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = true  # Quick Play!
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Assassin"
	
	# Light damage
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 1.0  # 100% ATK
	damage.damage_type = Enums.DamageType.PHYSICAL
	damage.can_crit = true
	
	# Apply 2 stacks of poison
	var poison = Poison.new(0.25, 4)  # 25% ATK per turn for 4 turns
	
	var debuff1 = DebuffEffect.new()
	debuff1.status_effect_template = poison
	debuff1.duration = 4
	debuff1.stack_count = 2  # Apply 2 stacks at once!
	
	skill.effects.append(damage)
	skill.effects.append(debuff1)
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Assassinate"
	ult.description = "Devastating strike that stuns and weakens"
	ult.cooldown = 4
	ult.starting_cooldown = 2
	ult.target_type = Enums.TargetType.SINGLE_ENEMY
	
	# Massive damage
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 3.0  # 300% ATK!
	damage.damage_type = Enums.DamageType.PHYSICAL
	damage.def_ignore = 0.3  # Ignore 30% DEF
	damage.can_crit = true
	
	# Stun
	var stun = Stun.new(1)  # 1 turn stun
	
	var stun_debuff = DebuffEffect.new()
	stun_debuff.status_effect_template = stun
	stun_debuff.duration = 1
	stun_debuff.application_chance = 0.9  # 90% chance
	
	# ATK debuff
	var atk_debuff = ATKDebuff.new(0.5, 2)  # -50% ATK for 2 turns
	
	var atk_debuff_effect = DebuffEffect.new()
	atk_debuff_effect.status_effect_template = atk_debuff
	atk_debuff_effect.duration = 2
	atk_debuff_effect.application_chance = 1.0  # 100% chance
	
	ult.effects.append(damage)
	ult.effects.append(stun_debuff)
	ult.effects.append(atk_debuff_effect)
	
	return ult

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "Dagger Strike"
	basic.description = "Swift dagger attack"
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.PHYSICAL
	basic.def_ignore = 0.1  # Always ignore 10% DEF
	basic.hit_count = 2  # Dual wield - hits twice!
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	return basic
