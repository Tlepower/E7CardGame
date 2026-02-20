# Reaper Vampire Unit Data - Half Grim Reaper, Half Vampire
# Drains life, executes low HP targets, and grows stronger as enemies weaken
# Theme: Death dealer who feeds on the dying

extends Resource
class_name ReaperVampireUnitData

static func create() -> UnitData:
	var reaper = UnitData.new()
	
	# Basic info
	reaper.unit_name = "Reaper Vampire"
	reaper.description = "A harbinger of death who feeds on the dying"
	reaper.rarity = "Legendary"
	
	# Stats
	reaper.base_stats = create_stats()
	
	# Abilities
	reaper.passive_script = load("res://Scripts/Passives/ReaperPassive.gd")
	reaper.skill1_card_data = create_skill1()
	reaper.skill2_card_data = create_skill2()
	reaper.ultimate_data = create_ultimate()
	reaper.basic_attack_data = create_basic_attack()
	
	return reaper

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 1100
	stats.base_atk = 145
	stats.base_def = 65
	stats.speed = 110  # Fast
	stats.crit_rate = 0.25  # 25%
	stats.crit_damage = 1.7  # 170%
	stats.effectiveness = 0.15
	stats.effect_resistance = 0.20
	return stats

static func create_passive() -> Script:
	# Gains lifesteal when enemies are low HP
	return load("res://Scripts/Passives/ReaperPassive.gd")

static func create_basic_attack() -> BasicAttackData:
	var basic = BasicAttackData.new()
	basic.attack_name = "Soul Siphon"
	basic.description = "Drains life from target (30% lifesteal)"
	basic.atk_multiplier = 1.0
	basic.damage_type = Enums.DamageType.MAGICAL
	basic.def_ignore = 0.0
	basic.hit_count = 1
	basic.target_type = Enums.TargetType.SINGLE_ENEMY
	
	# Note: Lifesteal is handled by passive, but thematically this is a drain attack
	
	return basic

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Blood Frenzy"
	skill.description = "Life drain attack that grants lifesteal buff"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Reaper Vampire"
	
	# Life drain damage + healing
	var drain = LifeDrainEffect.new(1.6, 0.6)  # 160% ATK, heal for 60% of damage
	
	# Grant self lifesteal buff
	var lifesteal_buff = Lifesteal.new(0.25, 3)  # 25% lifesteal for 3 turns
	
	var buff = BuffEffect.new()
	buff.status_effect_template = lifesteal_buff
	buff.duration = 3
	
	skill.effects.append(drain)
	skill.effects.append(buff)
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Reaper's Touch"
	skill.description = "Execute low HP enemy and steal their life force"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 3
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Reaper Vampire"
	
	# Execute effect (massive damage to low HP)
	var execute = ExecuteEffect.new(2.0, 3.0, 0.35)  # 200% ATK, +300% if below 35% HP (500% total!)
	
	# Life drain
	var drain = LifeDrainEffect.new(0.5, 1.0)  # Additional 50% ATK that heals 100% of damage
	
	skill.effects.append(execute)
	skill.effects.append(drain)
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Reap What You Sow"
	ult.description = "Massive AOE that executes all low HP enemies and drains life"
	ult.cooldown = 5
	ult.starting_cooldown = 2
	ult.target_type = Enums.TargetType.ALL_ENEMIES
	
	# AOE execute damage
	var execute = ExecuteEffect.new(1.8, 2.5, 0.4)  # 180% ATK, +250% if below 40% HP (430% total!)
	
	# Lifesteal buff after ultimate
	var lifesteal = Lifesteal.new(0.4, 3)  # 40% lifesteal for 3 turns (stacks!)
	
	var buff = BuffEffect.new()
	buff.status_effect_template = lifesteal
	buff.duration = 3
	
	# Grant ATK buff based on kills (flavor)
	var atk_buff = ATKBuff.new(0.3, 3)  # +30% ATK for 3 turns
	
	var atk_buff_effect = BuffEffect.new()
	atk_buff_effect.status_effect_template = atk_buff
	atk_buff_effect.duration = 3
	
	ult.effects.append(execute)
	ult.effects.append(buff)
	ult.effects.append(atk_buff_effect)
	
	return ult
