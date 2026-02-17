# BasicCards - Factory for creating the 8 basic utility cards
# These cards are shared between all players and form the base deck

extends Resource
class_name BasicCards

## Create all 8 basic cards
static func create_all() -> Array[CardData]:
	return [
		create_atk_buff(),
		create_heal(),
		create_damage(),
		create_draw(),
		create_ar_push(),
		create_dispel(),
		create_cleanse(),
		create_shield()
	]

## 1. ATK Buff Card
static func create_atk_buff() -> CardData:
	var card = CardData.new()
	card.card_name = "Battle Hymn"
	card.description = "Grant +40% ATK to an ally for 2 turns"
	card.card_type = Enums.CardType.BASIC
	card.mana_cost = 1
	card.is_quick_play = false
	card.target_type = Enums.TargetType.SINGLE_ALLY
	
	# Create ATK buff
	var atk_buff = StatusEffect.new()
	atk_buff.effect_name = "ATK Up"
	atk_buff.description = "+40% ATK"
	atk_buff.effect_type = Enums.StatusEffectType.BUFF
	atk_buff.base_duration = 2
	atk_buff.stat_modifiers = {"atk_percent": 1.4}
	atk_buff.can_be_dispelled = true
	atk_buff.ticks_on_turn_start = true
	atk_buff.duration_decreases_on_start = true
	
	var buff = BuffEffect.new()
	buff.status_effect_template = atk_buff
	buff.duration = 2
	
	card.effects.append(buff)
	return card

## 2. Heal Card
static func create_heal() -> CardData:
	var card = CardData.new()
	card.card_name = "Minor Heal"
	card.description = "Restore 500 HP to an ally"
	card.card_type = Enums.CardType.BASIC
	card.mana_cost = 1
	card.is_quick_play = false
	card.target_type = Enums.TargetType.SINGLE_ALLY
	
	var heal = HealEffect.new()
	heal.base_heal = 500
	heal.is_atk_based = false
	
	card.effects.append(heal)
	return card

## 3. Damage Card
static func create_damage() -> CardData:
	var card = CardData.new()
	card.card_name = "Strike"
	card.description = "Deal 300 damage to an enemy"
	card.card_type = Enums.CardType.BASIC
	card.mana_cost = 1
	card.is_quick_play = true
	card.target_type = Enums.TargetType.SINGLE_ENEMY
	
	var damage = DamageEffect.new()
	damage.base_damage = 300
	damage.is_atk_based = false
	damage.damage_type = Enums.DamageType.PHYSICAL
	damage.can_crit = false  # Fixed damage, no crit
	
	card.effects.append(damage)
	return card

## 4. Draw Card
static func create_draw() -> CardData:
	var card = CardData.new()
	card.card_name = "Refresh"
	card.description = "Draw 2 cards"
	card.card_type = Enums.CardType.BASIC
	card.mana_cost = 2
	card.is_quick_play = false
	card.target_type = Enums.TargetType.SELF
	
	var draw = DrawCardEffect.new()
	draw.cards_to_draw = 2
	draw.use_priority_draw = false
	
	card.effects.append(draw)
	return card

## 5. AR Push Card
static func create_ar_push() -> CardData:
	var card = CardData.new()
	card.card_name = "Haste"
	card.description = "Increase ally's Action Readiness by 30%"
	card.card_type = Enums.CardType.BASIC
	card.mana_cost = 2
	card.is_quick_play = false
	card.target_type = Enums.TargetType.SINGLE_ALLY
	
	var ar_push = ARManipulationEffect.new()
	ar_push.ar_amount = 30.0
	ar_push.is_push = true
	
	card.effects.append(ar_push)
	return card

## 6. Dispel Card
static func create_dispel() -> CardData:
	var card = CardData.new()
	card.card_name = "Silence"
	card.description = "Remove 2 buffs from an enemy"
	card.card_type = Enums.CardType.BASIC
	card.mana_cost = 2
	card.is_quick_play = false
	card.target_type = Enums.TargetType.SINGLE_ENEMY
	
	var dispel = DispelEffect.new()
	dispel.buff_count = 2
	dispel.remove_all = false
	
	card.effects.append(dispel)
	return card

## 7. Cleanse Card
static func create_cleanse() -> CardData:
	var card = CardData.new()
	card.card_name = "Purge"
	card.description = "Remove 2 debuffs from an ally"
	card.card_type = Enums.CardType.BASIC
	card.mana_cost = 1
	card.is_quick_play = true  # Quick Play!
	card.target_type = Enums.TargetType.SINGLE_ALLY
	
	var cleanse = CleanseEffect.new()
	cleanse.debuff_count = 2
	cleanse.remove_all = false
	
	card.effects.append(cleanse)
	return card

## 8. Shield Card
static func create_shield() -> CardData:
	var card = CardData.new()
	card.card_name = "Barrier"
	card.description = "Grant 400 HP shield to an ally for 2 turns"
	card.card_type = Enums.CardType.BASIC
	card.mana_cost = 2
	card.is_quick_play = true  # Quick Play!
	card.target_type = Enums.TargetType.SINGLE_ALLY
	
	var shield = ShieldEffect.new()
	shield.base_shield = 400
	shield.is_atk_based = false
	shield.duration = 2
	
	card.effects.append(shield)
	return card
