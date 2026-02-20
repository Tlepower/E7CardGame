extends CardEffect
class_name DrawSpecificCardEffect
## DrawSpecificCardEffect - Draws a specific card by name (e.g., skill 1)

# ============================================================================
# DRAW PROPERTIES
# ============================================================================

## Name of the card to draw (partial match)
@export var card_name_contains: String = ""

## Fallback: draw any card if specific not found?
@export var fallback_to_any: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(card_name: String = "") -> void:
	effect_name = "Draw Specific Card"
	description = "Draw a specific card from deck"
	target_type = Enums.TargetType.SELF
	card_name_contains = card_name

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	# Get player
	var player = _find_player_for_unit(caster, game_state)
	if player == null:
		push_error("DrawSpecificCardEffect: cannot find player")
		return
	
	# Get deck system
	var deck_system = player.deck_system
	if deck_system == null:
		push_error("DrawSpecificCardEffect: deck system not found")
		return
	
	# Search deck for the card
	var found_card = _find_card_in_deck(deck_system)
	
	if found_card != null:
		# Remove from deck
		deck_system.deck.erase(found_card)
		
		# Add to hand
		deck_system.add_to_hand(found_card)
		
		EventBus.log_debug("%s drew %s" % [player.get_display_name(), found_card.get_display_name()], "DrawSpecificCardEffect")
	elif fallback_to_any:
		# Fallback: draw any card
		var draw_system = game_state.get_node_or_null("DrawSystem")
		if draw_system != null:
			draw_system.draw_card_for_player(player)
			EventBus.log_debug("%s drew a random card (specific card not found)" % player.get_display_name(), "DrawSpecificCardEffect")
	else:
		EventBus.log_debug("Could not find card containing '%s' in deck" % card_name_contains, "DrawSpecificCardEffect")

## Find card in deck
func _find_card_in_deck(deck_system: Node) -> Node:
	if card_name_contains.is_empty():
		return null
	
	for card in deck_system.deck:
		if card.get_display_name().to_lower().contains(card_name_contains.to_lower()):
			return card
	
	return null

## Find player for unit
func _find_player_for_unit(unit: Node, game_state: Node) -> Node:
	if unit == null or game_state == null:
		return null
	
	if game_state.has_method("get_player_by_team"):
		return game_state.get_player_by_team(unit.team)
	
	return null

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	if card_name_contains.is_empty():
		return "Draw a card"
	return "Draw '%s' from deck" % card_name_contains
