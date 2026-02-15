extends CardEffect
class_name DrawCardEffect
## DrawCardEffect - Draws cards from deck to hand

# ============================================================================
# DRAW PROPERTIES
# ============================================================================

## Number of cards to draw
@export_range(1, 5) var cards_to_draw: int = 1

## Should drawing prioritize the active unit's skills?
@export var use_priority_draw: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Draw Cards"
	description = "Draw cards from deck"
	target_type = Enums.TargetType.SELF

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	# Drawing is done by the card owner's player, not the unit
	var player = null
	
	# Get the player who owns this card
	if caster.has_method("get") and caster.get("team") != null:
		# Find player by team
		player = _find_player_by_team(caster.team, game_state)
	
	if player == null:
		push_error("DrawCardEffect: cannot find player")
		return
	
	# Get draw system
	var draw_system = game_state.get_node_or_null("DrawSystem")
	if draw_system == null:
		push_error("DrawCardEffect: DrawSystem not found")
		return
	
	# Draw cards
	for i in cards_to_draw:
		if use_priority_draw:
			draw_system.draw_card_for_player(player, caster)
		else:
			draw_system.draw_card_for_player(player, null)
	
	EventBus.log_debug("%s drew %d card(s)" % [player.name if player.has_method("get") else "Player", cards_to_draw], "DrawCardEffect")

## Find player by team
func _find_player_by_team(team: Enums.Team, game_state: Node) -> Node:
	if game_state.has_method("get_player_by_team"):
		return game_state.get_player_by_team(team)
	
	# Fallback: try to get from battle manager
	var battle_manager = game_state
	if battle_manager.has_node("Player") and battle_manager.get_node("Player").team == team:
		return battle_manager.get_node("Player")
	if battle_manager.has_node("Enemy") and battle_manager.get_node("Enemy").team == team:
		return battle_manager.get_node("Enemy")
	
	return null

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	var desc = "Draw %d card%s" % [cards_to_draw, "s" if cards_to_draw > 1 else ""]
	return desc
