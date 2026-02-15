extends CardEffect
class_name DispelEffect
## DispelEffect - Removes buffs from target(s)

# ============================================================================
# DISPEL PROPERTIES
# ============================================================================

## Number of buffs to dispel (0 = all buffs)
@export_range(0, 10) var buff_count: int = 1

## Should we remove all buffs?
@export var remove_all: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Dispel"
	description = "Remove buffs from target"
	target_type = Enums.TargetType.SINGLE_ENEMY

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Get status effect system
	var status_system = get_status_effect_system(game_state)
	if status_system == null:
		push_error("DispelEffect: StatusEffectSystem not found")
		return
	
	# Determine how many buffs to remove
	var count_to_remove = 0 if remove_all else buff_count
	
	# Dispel buffs
	status_system.dispel_buffs(target, count_to_remove)
	
	var count_text = "all" if remove_all else str(buff_count)
	EventBus.log_debug("%s dispelled %s buff(s) from %s" % [caster.name, count_text, target.name], "DispelEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	if remove_all:
		return "Remove all buffs from target"
	else:
		return "Remove %d buff%s from target" % [buff_count, "s" if buff_count > 1 else ""]
