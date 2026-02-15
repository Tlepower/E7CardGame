extends Node
class_name DrawSystem
## DrawSystem - Handles card draw logic for both players
## Wrapper around DeckSystem for centralized draw management

# ============================================================================
# DRAWING CARDS
# ============================================================================

## Draw a card for a player
## If active_unit is provided, uses priority draw
func draw_card_for_player(player: Node, active_unit: Node = null) -> Node:
	if player == null:
		push_error("DrawSystem: player is null")
		return null
	
	if not player.has_method("draw_card"):
		push_error("DrawSystem: player does not have draw_card method")
		return null
	
	# Draw card
	var card = player.draw_card(active_unit)
	
	if card != null:
		EventBus.log_debug("%s drew: %s" % [player.get_display_name(), card.get_display_name()], "Draw")
	else:
		EventBus.log_debug("%s failed to draw card" % player.get_display_name(), "Draw")
	
	return card

## Draw starting hand for a player (5 cards at battle start)
func draw_starting_hand(player: Node) -> void:
	if player == null:
		push_error("DrawSystem: player is null")
		return
	
	if not player.has_method("draw_starting_hand"):
		push_error("DrawSystem: player does not have draw_starting_hand method")
		return
	
	player.draw_starting_hand()
	EventBus.log_debug("%s drew starting hand" % player.get_display_name(), "Draw")

## Draw multiple cards for a player
func draw_multiple_cards(player: Node, count: int, active_unit: Node = null) -> Array[Node]:
	var drawn_cards: Array[Node] = []
	
	for i in count:
		var card = draw_card_for_player(player, active_unit)
		if card != null:
			drawn_cards.append(card)
	
	return drawn_cards

# ============================================================================
# UTILITY
# ============================================================================

## Check if player can draw (deck not empty or can reshuffle)
func can_draw(player: Node) -> bool:
	if player == null or not player.has_method("get_deck_size"):
		return false
	
	# Can draw if deck has cards OR discard has cards to reshuffle
	return player.get_deck_size() > 0 or player.get_discard_size() > 0

## Get total drawable cards (deck + discard)
func get_drawable_count(player: Node) -> int:
	if player == null:
		return 0
	
	return player.get_deck_size() + player.get_discard_size()
