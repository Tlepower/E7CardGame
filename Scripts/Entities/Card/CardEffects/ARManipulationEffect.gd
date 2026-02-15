extends CardEffect
class_name ARManipulationEffect
## ARManipulationEffect - Pushes or pulls Action Readiness (turn order manipulation)

# ============================================================================
# AR PROPERTIES
# ============================================================================

## Amount of AR to push/pull (percentage, e.g., 20.0 = +20% AR)
@export var ar_amount: float = 20.0

## Is this a push (increase AR) or pull (decrease AR)?
@export var is_push: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "AR Manipulation"
	description = "Modify Action Readiness"
	target_type = Enums.TargetType.SINGLE_ALLY

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Calculate AR change
	var ar_change = ar_amount if is_push else -ar_amount
	
	# Apply AR modification
	target.modify_ar(ar_change)
	
	# Update turn order
	var turn_order_system = game_state.get_node_or_null("TurnOrderSystem")
	if turn_order_system != null:
		turn_order_system.recalculate_queue()
	
	var action_word = "pushed" if is_push else "pulled"
	EventBus.log_debug("%s %s %s's AR by %.1f%%" % [caster.name, action_word, target.name, ar_amount], "ARManipulationEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	var action = "Increase" if is_push else "Decrease"
	var desc = "%s target's Action Readiness by %.0f%%" % [action, ar_amount]
	return desc
