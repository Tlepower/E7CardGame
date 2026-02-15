extends CardEffect
class_name CleanseEffect
## CleanseEffect - Removes debuffs from target(s)

# ============================================================================
# CLEANSE PROPERTIES
# ============================================================================

## Number of debuffs to cleanse (0 = all debuffs)
@export_range(0, 10) var debuff_count: int = 1

## Should we remove all debuffs?
@export var remove_all: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Cleanse"
	description = "Remove debuffs from target"
	target_type = Enums.TargetType.SINGLE_ALLY

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Get status effect system
	var status_system = get_status_effect_system(game_state)
	if status_system == null:
		push_error("CleanseEffect: StatusEffectSystem not found")
		return
	
	# Determine how many debuffs to remove
	var count_to_remove = 0 if remove_all else debuff_count
	
	# Cleanse debuffs
	status_system.cleanse_debuffs(target, count_to_remove)
	
	var count_text = "all" if remove_all else str(debuff_count)
	EventBus.log_debug("%s cleansed %s debuff(s) from %s" % [caster.name, count_text, target.name], "CleanseEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	if remove_all:
		return "Remove all debuffs from target"
	else:
		return "Remove %d debuff%s from target" % [debuff_count, "s" if debuff_count > 1 else ""]
