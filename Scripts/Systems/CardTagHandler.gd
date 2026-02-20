extends Node
class_name CardTagHandler
## CardTagHandler - Processes card tag effects and behaviors
## Handles Breakout, Lead, Retrieve, Combo, Unusable, etc.

# ============================================================================
# STATE TRACKING
# ============================================================================

## Cards played this turn (for Combo tracking)
var cards_played_this_turn: Array[Node] = []

## Last target of played card (for Clash)
var last_target: Node = null

## Cards that have used Echo this turn
var echo_used_this_turn: Array[int] = []  # Array of card instance_ids

## Cards that have been played (for Spark tracking)
var spark_used: Dictionary = {}  # {card_name: bool}

# ============================================================================
# INITIALIZATION
# ============================================================================

func initialize() -> void:
	# Connect to relevant signals
	EventBus.card_played.connect(_on_card_played)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.turn_ended.connect(_on_turn_ended)
	EventBus.card_discarded.connect(_on_card_discarded)

# ============================================================================
# BREAKOUT TAG
# ============================================================================

## Process Breakout tags during deck initialization
func apply_breakout_tags(deck: Array[Node]) -> Array[Node]:
	var breakout_cards: Array[Node] = []
	var normal_cards: Array[Node] = []
	
	# Separate cards with Breakout tag
	for card in deck:
		if card.card_data != null and card.card_data.has_tag(CardTag.TagType.BREAKOUT):
			breakout_cards.append(card)
		else:
			normal_cards.append(card)
	
	# Breakout cards go on top
	var new_deck: Array[Node] = []
	new_deck.append_array(breakout_cards)
	new_deck.append_array(normal_cards)
	
	EventBus.log_debug("Applied Breakout tags: %d cards moved to top" % breakout_cards.size(), "CardTag")
	
	return new_deck

# ============================================================================
# LEAD TAG
# ============================================================================

## Check if card should refund mana (Lead tag, first card played)
func check_lead_refund(card: Node) -> bool:
	if card == null or card.card_data == null:
		return false
	
	# Check if has Lead tag
	if not card.card_data.has_tag(CardTag.TagType.LEAD):
		return false
	
	# Check if first card this turn
	if cards_played_this_turn.size() == 1:  # Only this card played
		EventBus.log_debug("Lead triggered! Refunding 1 mana" % card.get_display_name(), "CardTag")
		return true
	
	return false

# ============================================================================
# RETRIEVE TAG
# ============================================================================

## Check if card should be retrieved (return to hand when discarded)
func check_retrieve(card: Node, player: Node) -> void:
	if card == null or card.card_data == null:
		return
	
	# Check if has Retrieve tag
	if not card.card_data.has_tag(CardTag.TagType.RETRIEVE):
		return
	
	# Return to hand next turn start
	EventBus.log_debug("%s has Retrieve - will return to hand next turn" % card.get_display_name(), "CardTag")
	
	# Connect to next turn start
	var callable = func(unit: Node):
		if player == null or player.deck_system == null:
			return
		# Move from discard to hand
		if card in player.deck_system.discard_pile:
			player.deck_system.discard_pile.erase(card)
			player.deck_system.add_to_hand(card)
			EventBus.log_debug("%s retrieved to hand!" % card.get_display_name(), "CardTag")
	
	EventBus.turn_started.connect(callable, CONNECT_ONE_SHOT)

# ============================================================================
# COMBO TAG
# ============================================================================

## Check if Combo bonus should activate
func check_combo_active(card: Node) -> bool:
	if card == null or card.card_data == null:
		return false
	
	# Check if has Combo tag
	if not card.card_data.has_tag(CardTag.TagType.COMBO):
		return false
	
	# Check if another card was played this turn (before this one)
	if cards_played_this_turn.size() >= 1:  # At least 1 other card
		EventBus.log_debug("Combo activated for %s!" % card.get_display_name(), "CardTag")
		return true
	
	return false

# ============================================================================
# UNUSABLE TAG
# ============================================================================

## Check if card can be played (Unusable tag)
func check_unusable(card: Node) -> bool:
	if card == null or card.card_data == null:
		return false
	
	return card.card_data.has_tag(CardTag.TagType.UNUSABLE)

# ============================================================================
# SPARK TAG
# ============================================================================

## Check if Spark card can be played (once per battle, 0 cost)
func check_spark_playable(card: Node) -> bool:
	if card == null or card.card_data == null:
		return true
	
	# Check if has Spark tag
	if not card.card_data.has_tag(CardTag.TagType.SPARK):
		return true
	
	# Check if already used
	var card_name = card.get_display_name()
	if spark_used.has(card_name) and spark_used[card_name]:
		EventBus.log_debug("Spark card %s already used this battle" % card_name, "CardTag")
		return false
	
	return true

## Mark Spark card as used
func mark_spark_used(card: Node) -> void:
	if card == null or card.card_data == null:
		return
	
	if card.card_data.has_tag(CardTag.TagType.SPARK):
		var card_name = card.get_display_name()
		spark_used[card_name] = true
		EventBus.log_debug("Spark card %s marked as used" % card_name, "CardTag")

# ============================================================================
# CLASH TAG
# ============================================================================

## Check if Clash bonus activates (same target as previous card)
func check_clash_active(card: Node, target: Node) -> bool:
	if card == null or card.card_data == null:
		return false
	
	# Check if has Clash tag
	if not card.card_data.has_tag(CardTag.TagType.CLASH):
		return false
	
	# Check if same target as last card
	if target == last_target and last_target != null:
		EventBus.log_debug("Clash activated for %s!" % card.get_display_name(), "CardTag")
		return true
	
	return false

# ============================================================================
# FINALE TAG
# ============================================================================

## Check if Finale bonus should activate (last card of turn)
## Note: This needs to be checked at turn end
func check_finale_active(card: Node, is_last_card: bool) -> bool:
	if card == null or card.card_data == null:
		return false
	
	# Check if has Finale tag
	if not card.card_data.has_tag(CardTag.TagType.FINALE):
		return false
	
	if is_last_card:
		EventBus.log_debug("Finale activated for %s!" % card.get_display_name(), "CardTag")
		return true
	
	return false

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_card_played(card: Node, player: Node, target) -> void:
	if card == null:
		return
	
	# Track cards played
	cards_played_this_turn.append(card)
	
	# Track last target for Clash
	if target is Node:
		last_target = target
	
	# Mark Spark as used
	mark_spark_used(card)

func _on_turn_started(unit: Node) -> void:
	# Reset turn tracking
	cards_played_this_turn.clear()
	last_target = null
	echo_used_this_turn.clear()

func _on_turn_ended(unit: Node) -> void:
	# Handle Ethereal cards (disappear at end of turn)
	# Note: This would need access to player's hand
	pass

func _on_card_discarded(card: Node, player: Node) -> void:
	# Check Retrieve tag
	check_retrieve(card, player)

# ============================================================================
# UTILITY
# ============================================================================

## Get Spark cost (0 if has Spark tag)
func get_effective_cost(card: Node) -> int:
	if card == null or card.card_data == null:
		return card.get_mana_cost() if card != null else 0
	
	# Spark cards cost 0
	if card.card_data.has_tag(CardTag.TagType.SPARK):
		return 0
	
	return card.get_mana_cost()
