extends Node
class_name DeckSystem
## DeckSystem - Manages a player's deck, hand, and discard pile
## Handles drawing cards with priority for active unit's skills

# ============================================================================
# CARD PILES
# ============================================================================

## Cards currently in deck (draw pile)
var deck: Array[Node] = []  # Array[Card]

## Cards currently in hand
var hand: Array[Node] = []  # Array[Card]

## Cards in discard pile
var discard_pile: Array[Node] = []  # Array[Card]

# ============================================================================
# CONFIGURATION
# ============================================================================

## Owner of this deck
var Owner: Node = null # changed from owner to Owner because "Member "Owner" redefined"

## Maximum hand size (0 = unlimited)
@export var max_hand_size: int = 10

## Starting hand size (drawn at battle start)
@export var starting_hand_size: int = 6

# ============================================================================
# INITIALIZATION
# ============================================================================

## Initialize the deck system
func initialize(player: Node, unit_datas: Array, basic_card_datas: Array) -> void:
	Owner = player
	
	# Clear all piles
	deck.clear()
	hand.clear()
	discard_pile.clear()
	
	# Build the deck: 6 skill cards (2 per unit) + 8 basic cards
	_build_deck(unit_datas, basic_card_datas)
	
	# Shuffle deck
	shuffle_deck()
	
	EventBus.log_debug("DeckSystem initialized with %d cards" % deck.size(), "Deck")

## Build the deck from unit data and basic cards
func _build_deck(unit_datas: Array, basic_card_datas: Array) -> void:
	# Add skill cards (2 per unit, 3 units = 6 cards)
	for unit_data in unit_datas:
		if unit_data == null:
			continue
		
		# Add skill 1
		if unit_data.skill1_card_data != null:
			var card = unit_data.skill1_card_data.create_instance(Owner)
			if card != null:
				deck.append(card)
		
		# Add skill 2
		if unit_data.skill2_card_data != null:
			var card = unit_data.skill2_card_data.create_instance(Owner)
			if card != null:
				deck.append(card)
	
	# Add basic cards (8 cards)
	for card_data in basic_card_datas:
		if card_data == null:
			continue
		
		var card = card_data.create_instance(Owner)
		if card != null:
			deck.append(card)
	
	EventBus.log_debug("Built deck: %d skill cards + %d basic cards" % [unit_datas.size() * 2, basic_card_datas.size()], "Deck")

# ============================================================================
# SHUFFLING
# ============================================================================

## Shuffle the deck
func shuffle_deck() -> void:
	deck.shuffle()
	EventBus.log_debug("Deck shuffled (%d cards)" % deck.size(), "Deck")

## Reshuffle discard pile into deck
func reshuffle_discard_into_deck() -> void:
	# Move all cards from discard to deck
	for card in discard_pile:
		deck.append(card)
	
	discard_pile.clear()
	
	# Shuffle
	shuffle_deck()
	
	EventBus.log_debug("Discard pile reshuffled into deck", "Deck")

# ============================================================================
# DRAWING CARDS
# ============================================================================

## Draw a card from deck to hand
## Returns the drawn card, or null if deck is empty
func draw_card() -> Node:
	# If deck is empty, reshuffle discard
	if deck.is_empty():
		if discard_pile.is_empty():
			EventBus.log_debug("Cannot draw: deck and discard are both empty", "Deck")
			return null
		
		reshuffle_discard_into_deck()
	
	# Check hand size limit
	if max_hand_size > 0 and hand.size() >= max_hand_size:
		EventBus.log_debug("Cannot draw: hand is full (%d/%d)" % [hand.size(), max_hand_size], "Deck")
		# Card is burned (goes to discard without being drawn)
		var burned_card = deck.pop_front()
		discard_pile.append(burned_card)
		return null
	
	# Draw top card
	var card = deck.pop_front()
	
	# Add to hand
	add_to_hand(card)
	
	return card

## Draw card with priority for active unit's skills
## If active_unit's skill cards are not in hand, prioritize drawing them
func draw_with_priority(active_unit: Node = null) -> Node:
	# If no active unit specified, normal draw
	if active_unit == null:
		return draw_card()
	
	# Check if unit's skill cards are in hand
	if has_unit_skill_in_hand(active_unit):
		# Already has skills in hand, normal draw
		return draw_card()
	
	# Try to find unit's skill card in deck
	var unit_skill_card = _find_unit_skill_in_deck(active_unit)
	
	if unit_skill_card != null:
		# Found a skill card, draw it specifically
		deck.erase(unit_skill_card)
		add_to_hand(unit_skill_card)
		EventBus.log_debug("Drew %s's skill card with priority" % active_unit.name, "Deck")
		return unit_skill_card
	
	# No skill card found in deck, normal draw
	return draw_card()

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

## Find a skill card belonging to a specific unit in the deck
func _find_unit_skill_in_deck(unit: Node) -> Node:
	var unit_name = unit.unit_data.unit_name if unit.has_method("get") else unit.name
	
	for card in deck:
		if card.is_skill_card() and card.get_owner_unit_name() == unit_name:
			return card
	
	return null

## Check if hand contains any of this unit's skill cards
func has_unit_skill_in_hand(unit: Node) -> bool:
	var unit_name = unit.unit_data.unit_name if unit.has_method("get") else unit.name
	
	for card in hand:
		if card.is_skill_card() and card.get_owner_unit_name() == unit_name:
			return true
	
	return false

## draw a selected card from the deck in put it in the hand
func draw_selected_card(card: Card) -> Node:
	# check if the card is in the deck
	if !(card in deck):
		return null
		
	# check if hand if full
	if max_hand_size > 0 and hand.size() >= max_hand_size:
		EventBus.log_debug("Cannot draw: hand is full (%d/%d)" % [hand.size(), max_hand_size], "Deck")
		return null
		
	# draw the card
	if card != null:
		return null
		
	deck.erase(card)
	add_to_hand(card)
	
	return card

# ============================================================================
# HAND MANAGEMENT
# ============================================================================

## Add card to hand
func add_to_hand(card: Node) -> void:
	if card == null:
		return
	
	hand.append(card)
	card.in_hand = true
	
	EventBus.card_drawn.emit(card, Owner)
	EventBus.log_debug("Drew: %s (%d cards in hand)" % [card.get_display_name(), hand.size()], "Deck")

## Remove card from hand
func remove_from_hand(card: Node) -> void:
	if card == null or card not in hand:
		return
	
	hand.erase(card)
	card.in_hand = false

## Discard a card from hand
func discard_card(card: Node) -> void:
	if card == null:
		return
	
	# Remove from hand
	remove_from_hand(card)
	
	# Add to discard pile
	discard_pile.append(card)
	
	EventBus.card_discarded.emit(card, Owner
)
	EventBus.log_debug("Discarded: %s" % card.get_display_name(), "Deck")

## Discard entire hand
func discard_hand() -> void:
	var cards_to_discard = hand.duplicate()
	
	for card in cards_to_discard:
		discard_card(card)

# ============================================================================
# STARTING HAND
# ============================================================================

## Draw starting hand
func draw_starting_hand() -> void:
	for i in starting_hand_size:
		draw_card()
	
	EventBus.log_debug("Drew starting hand (%d cards)" % hand.size(), "Deck")

# ============================================================================
# QUERIES
# ============================================================================

## Get hand size
func get_hand_size() -> int:
	return hand.size()

## Get deck size
func get_deck_size() -> int:
	return deck.size()

## Get discard size
func get_discard_size() -> int:
	return discard_pile.size()

## Get total cards (deck + hand + discard)
func get_total_cards() -> int:
	return deck.size() + hand.size() + discard_pile.size()

## Get hand as array
func get_hand() -> Array[Node]:
	return hand.duplicate()

## Check if hand is full
func is_hand_full() -> bool:
	if max_hand_size <= 0:
		return false
	return hand.size() >= max_hand_size

## Check if deck is empty
func is_deck_empty() -> bool:
	return deck.is_empty()

## Find card in hand by instance ID
func find_card_by_id(instance_id: int) -> Node:
	for card in hand:
		if card.instance_id == instance_id:
			return card
	return null

# ============================================================================
# ADVANCED OPERATIONS
# ============================================================================

## Add a card to deck (for effects that create cards)
func add_card_to_deck(card: Node, shuffle: bool = true) -> void:
	if card == null:
		return
	
	deck.append(card)
	
	if shuffle:
		shuffle_deck()

## Add a card directly to hand (skip draw)
func add_card_to_hand(card: Node) -> void:
	if card == null:
		return
	
	if is_hand_full():
		# Discard immediately if hand is full
		discard_pile.append(card)
		return
	
	add_to_hand(card)

## Move card from discard back to deck
func return_card_to_deck(card: Node) -> void:
	if card == null or card not in discard_pile:
		return
	
	discard_pile.erase(card)
	deck.append(card)

## Mulligan (redraw hand)
func mulligan(cards_to_replace: Array[Node]) -> void:
	# Put selected cards back in deck
	for card in cards_to_replace:
		if card in hand:
			remove_from_hand(card)
			deck.append(card)
	
	# Shuffle deck
	shuffle_deck()
	
	# Draw replacement cards
	for i in cards_to_replace.size():
		draw_card()

# ============================================================================
# DEBUG
# ============================================================================

## Get debug info
func get_debug_info() -> String:
	return "Deck: %d | Hand: %d | Discard: %d" % [deck.size(), hand.size(), discard_pile.size()]

## Print hand contents
func print_hand() -> void:
	print("=== Hand Contents ===")
	for card in hand:
		print("  - %s (Cost: %d)" % [card.get_display_name(), card.get_mana_cost()])
	print("===================")
