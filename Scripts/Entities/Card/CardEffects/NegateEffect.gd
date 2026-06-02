extends CardEffect
class_name NegateEffect

enum CounterType {
	ANY,
	SKILL_ONLY,
	BASIC_ONLY,
	ULTMATE_ONLY,
}

var counter_type: CounterType = CounterType.ANY
var target_card =  null

func _init(card : Node) -> void:
	effect_name = "Negate"
	description = "Negates a card"
	target_type = Enums.TargetType.SINGLE_ENEMY
	target_card = card
	
func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	var quickplay = get_quickplay_system(game_state)
	var last_card = quickplay.get_last_card()
	
	if not can_counter(last_card.card):
		return 
	
	if not last_card.card.get_can_be_negated():
		return
	
	# change card's is_countered to turn
	last_card.card.set_negated_status(true) 
	
func can_counter(target_card: Card) -> bool:
	match counter_type:
		CounterType.BASIC_ONLY:
			if target_card.card_data.card_type != Enums.CardType.BASIC:
				return false
		CounterType.SKILL_ONLY:
			if target_card.card_data.card_type != Enums.CardType.SKILL:
				return false
	return true

func get_description() -> String:
	return "Pass"
	
