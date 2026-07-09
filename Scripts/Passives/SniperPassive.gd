extends Passive
class_name SniperPassive
## Gain bullets to fire at foes

var bullet_count = 0

## number of bullets you start with
const BASE_STARTING_BULLETS = 2

func _init() -> void:
	passive_name = "Setup"
	description = "Start the game with 2 Bullets"
	passive_type = Enums.PassiveType.TRIGGER
	is_mandatory = false
	
	trigger_conditions = [Enums.TriggerCondition.ON_BATTLE_START]
	
func execute_trigger(condition: Enums.TriggerCondition, data: Dictionary) -> void:
	if condition in trigger_conditions:
		_on_battle_start()
	
func _on_battle_start():
	bullet_count = BASE_STARTING_BULLETS
	
	EventBus.log_debug("%s gained %d bullets" % [owner_unit.name,BASE_STARTING_BULLETS], "Passive")
	
## call when removing bullets is necessary
func removing_bullets(b: int) -> bool:
	if (bullet_count - b) < 0:
		return false
	bullet_count = bullet_count - b 
	return true
	
	
