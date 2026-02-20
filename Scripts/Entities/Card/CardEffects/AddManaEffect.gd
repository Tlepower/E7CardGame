extends CardEffect
class_name AddManaEffect
## AddManaEffect - Grants mana to the player

# ============================================================================
# MANA PROPERTIES
# ============================================================================

## Amount of mana to add
@export var mana_amount: int = 1

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(amount: int = 1) -> void:
	effect_name = "Add Mana"
	description = "Gain %d mana" % amount
	target_type = Enums.TargetType.SELF
	mana_amount = amount

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	# Get mana system
	var mana_system = game_state.get_node_or_null("ManaSystem")
	if mana_system == null:
		push_error("AddManaEffect: ManaSystem not found")
		return
	
	# Find player
	var player = _find_player_for_unit(caster, game_state)
	if player == null:
		push_error("AddManaEffect: cannot find player")
		return
	
	# Add mana
	mana_system.add_mana(player, mana_amount)
	
	EventBus.log_debug("%s gained %d mana" % [player.get_display_name(), mana_amount], "AddManaEffect")

# ============================================================================
# HELPERS
# ============================================================================

func _find_player_for_unit(unit: Node, game_state: Node) -> Node:
	if unit == null or game_state == null:
		return null
	
	# Try to get from battle manager
	if game_state.has_method("get_player_by_team"):
		return game_state.get_player_by_team(unit.team)
	
	return null

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	return "Gain %d mana" % mana_amount
