extends CardEffect
class_name GainExtraTurn
## Gain the target the next turn by giving 100% ar or more ar than the unit with the highest ar

func _init() -> void:
	effect_name = "Gain_Turn"
	description = "Gain the turn the next turn"
	target_type = Enums.TargetType.SINGLE_ALLY
	
func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# get turn_order_system
	var turn_order_system = game_state.get_turn_order_system()
	if turn_order_system == null:
		return
		
	# gain the ar that will be set 
	turn_order_system.gain_turn(target) # get 100% or highest ar + 1
	
	EventBus.log_debug("%s gain a turn from %s" % [target.name, caster.name,], "GainExtraTurnEffect")
	
func get_description() -> String:
	return ""
	
