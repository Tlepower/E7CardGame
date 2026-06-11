extends CardEffect
class_name GainTurn
# Gain the target the next turn by giving 100% ar or more ar than the unit with the highest ar

func _init() -> void:
	effect_name = "Gain_Turn"
	description = "Gain the turn the next turn"
	target_type = Enums.TargetType.SINGLE_ALLY
	
func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# get turn_order_system
	var turn_order_system = game_state.get_node_or_null("turn_order_system")
	if turn_order_system == null:
		return
		
	# gain the ar that will be set 
	var ar_gain = turn_order_system.gain_turn() # get 100% or highest ar + 1
	target.set_ar(ar_gain)
	
	EventBus.log_debug("%s gain a turn from %s" % [target.name, caster.name,], "GainTurnEffect")
	
func get_description() -> String:
	return ""
	
