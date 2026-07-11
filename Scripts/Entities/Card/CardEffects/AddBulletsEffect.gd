extends CardEffect
class_name AddBullets

const ADDBULLET: int = 1

func _init() -> void:
	effect_name = "Add Bullet"
	description = "Add bullets to the passive setup"
	target_type = Enums.TargetType.SELF
	
func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if target == null or target.passive.passive_name != "Setup":
		return
	
	var setup: SniperPassive = target.passive
	setup.bullet_count += ADDBULLET
	EventBus.log_debug("%s gain %d bullet%s" % [target.name, ADDBULLET, "" if ADDBULLET == 1 else "s"], "AddBullet")
	
# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	return ""
