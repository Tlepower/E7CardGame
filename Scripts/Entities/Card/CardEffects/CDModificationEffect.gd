extends CardEffect
class_name CDModificationEffect
# Increase or Decrease the cd of the target 

## Amount of CD that is incease or decrease
var CD_Amount: int = 1

## Is it an Increase or Decrease
var is_decrease: bool = true

func _init() -> void:
	effect_name = "Fast Forward"
	description = "Increase or Decrease the CD of a Unit's UItimate"
	target_type = Enums.TargetType.SELF

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Calculate AR change
	var cd_changed = CD_Amount if is_decrease else -CD_Amount
	
	# Apply AR modification
	target.modify_CD(cd_changed)
	
	var action_word = "decreased" if is_decrease else "increased"
	EventBus.log_debug("%s %s %s's CD by %d" % [caster.name, action_word, target.name, cd_changed], "CDModificationEffect")

func get_description() -> String:
	var action = "Decreased" if is_decrease else "Increased"
	var desc = "%s target's Cooldown by %.0f%%" % [action, is_decrease]
	return desc
