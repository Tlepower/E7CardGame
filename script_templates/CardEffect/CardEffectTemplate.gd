extends CardEffect

func _init() -> void:
	effect_name = "Effect"
	description = "Simple Template for Card Effect"
	target_type = Enums.TargetType.SINGLE_ENEMY
	
func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	pass
	
# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	return ""
