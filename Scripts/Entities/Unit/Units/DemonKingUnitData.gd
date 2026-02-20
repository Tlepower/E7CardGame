# Demon King Unit Data - Immortal Sovereign
# Gains death prevention every 6 turns, gains +100% AR when it's consumed
# Basic attack cuts DEF, skills manipulate turn order and draw cards
# Ultimate hits all enemies and resets passive cooldown

extends Resource
class_name DemonKingUnitData

static func create() -> UnitData:
	var demon_king = UnitData.new()
	
	# Basic info
	demon_king.unit_name = "Demon King"
	demon_king.description = "The immortal ruler of demons, impossible to truly kill"
	demon_king.rarity = "Legendary"
	
	# Stats
	demon_king.base_stats = create_stats()
	
	# Abilities
	demon_king.passive_script = load("res://Scripts/Passives/DemonKingPassive.gd")
	demon_king.skill1_card_data = create_skill1()
	demon_king.skill2_card_data = create_skill2()
	demon_king.ultimate_data = create_ultimate()
	demon_king.basic_attack_data = create_basic_attack()
	
	return demon_king

static func create_stats() -> UnitStats:
	var stats = UnitStats.new()
	stats.max_hp = 1500  # Very tanky
	stats.base_atk = 140
	stats.base_def = 90   # High defense
	stats.speed = 90      # Slower
	stats.crit_rate = 0.10  # 10%
	stats.crit_damage = 1.5  # 150%
	stats.effectiveness = 0.25
	stats.effect_resistance = 0.30  # High resistance
	return stats

static func create_basic_attack() -> BasicAttackData:
	return DemonKingBasicAttack.new()

static func create_skill1() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Dominating Presence"
	skill.description = "Push back an enemy's turn order"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 2
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SINGLE_ENEMY
	skill.owner_unit_name = "Demon King"
	
	# Light damage
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 1.2  # 120% ATK
	damage.damage_type = Enums.DamageType.MAGICAL
	damage.can_crit = true
	
	# AR pull (push back enemy)
	var ar_pull = ARManipulationEffect.new()
	ar_pull.ar_amount = 20.0
	ar_pull.is_push = false  # Pull = decrease AR
	
	skill.effects.append(damage)
	skill.effects.append(ar_pull)
	
	return skill

static func create_skill2() -> CardData:
	var skill = CardData.new()
	skill.card_name = "Dark Insight"
	skill.description = "Draw Dominating Presence and gain 1 mana"
	skill.card_type = Enums.CardType.SKILL
	skill.mana_cost = 1
	skill.is_quick_play = false
	skill.target_type = Enums.TargetType.SELF
	skill.owner_unit_name = "Demon King"
	
	# Draw skill 1
	var draw_skill = DrawSpecificCardEffect.new("Dominating Presence")
	draw_skill.fallback_to_any = true
	
	# Add mana
	var add_mana = AddManaEffect.new(1)
	
	skill.effects.append(draw_skill)
	skill.effects.append(add_mana)
	
	return skill

static func create_ultimate() -> UltimateData:
	var ult = UltimateData.new()
	ult.ultimate_name = "Demon Lord's Wrath"
	ult.description = "Devastate all enemies and reset Immortal Sovereign"
	ult.cooldown = 5
	ult.starting_cooldown = 3
	ult.target_type = Enums.TargetType.ALL_ENEMIES
	
	# AOE damage
	var damage = DamageEffect.new()
	damage.is_atk_based = true
	damage.atk_multiplier = 2.2  # 220% ATK to all
	damage.damage_type = Enums.DamageType.MAGICAL
	damage.can_crit = true
	damage.apply_to_all_at_once = false
	
	# Reset passive cooldown and grant immediate death prevention
	var reset_passive = ResetPassiveCooldownEffect.new()
	
	ult.effects.append(damage)
	ult.effects.append(reset_passive)
	
	return ult
