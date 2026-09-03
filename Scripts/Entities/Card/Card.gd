extends Node
class_name Card
## Card - Runtime instance of a card in a player's deck/hand
## Created from CardData template

# ============================================================================
# REFERENCES
# ============================================================================

## Original card data template
var card_data: CardData = null

## Player who owns this card
var owner_player: Node = null

## Unique instance ID for this specific card
var instance_id: int = 0

## Is this card currently in hand?
var in_hand: bool = false

## Is this card currently being dragged?
var is_being_dragged: bool = false

# ============================================================================
# PLAYABLE
# ============================================================================

## Can this card be countered
var can_be_negated: bool = false

## Is this card negated?
var is_negated: bool = false

# ============================================================================
# STATIC COUNTER FOR INSTANCE IDs
# ============================================================================

static var _next_instance_id: int = 1

# ============================================================================
# INITIALIZATION
# ============================================================================

## Initialize card from CardData template
func initialize_from_data(data: CardData, player: Node) -> void:
	if data == null:
		push_error("Card: cannot initialize with null CardData")
		return
	
	card_data = data
	owner_player = player
	name = data.card_name
	
	# Assign unique instance ID
	instance_id = _next_instance_id
	_next_instance_id += 1
	
	EventBus.log_debug("Card '%s' [ID:%d] created for player" % [name, instance_id], "Card")

# ============================================================================
# PLAYABILITY
# ============================================================================

## Check if this card can be played
func can_play(game_state: Node) -> bool:
	if card_data == null or owner_player == null:
		return false
	
	# Must be in hand
	if not in_hand:
		return false
	
	# Check mana cost
	#if not can_afford_mana(game_state):
		#return false
	
	# Check if we have valid targets
	if not _has_valid_targets(game_state) and card_data.target_type != Enums.TargetType.SELF:
		return false
		
	var turn_manager = game_state.get_node_or_null("TurnManager")
	if turn_manager == null:
		return true
	var current_unit = turn_manager.current_unit
	
	# Check if the current unit is using other's cards
	if card_data.is_skill_card():
		if current_unit.unit_data.unit_name != card_data.owner_unit_name:
			return false
	
	# Check if it's the right time to play (quick play vs main phase)
	if not _can_play_now(game_state):
		return false
	
	return true

## Check if player can afford this card
func can_afford_mana(game_state: Node) -> bool:
	var mana_system = game_state.get_node_or_null("ManaSystem")
	if mana_system == null:
		push_warning("Card: ManaSystem not found")
		return true  # Assume can afford if system not found
	
	var current_mana = mana_system.get_current_mana(owner_player)
	return current_mana >= get_mana_cost()

## Check if there are valid targets for this card
func _has_valid_targets(game_state: Node) -> bool:
	var valid_targets = get_valid_targets(game_state)
	return not valid_targets.is_empty()

## Check if this card can be played now (timing check)
func _can_play_now(game_state: Node) -> bool:
	# Quick play cards can be played during quick play window
	if is_quick_play():
		# Can be played during quick play window or main phase
		return true
	
	# Non-quick play cards can only be played during your main phase
	var turn_manager = game_state.get_node_or_null("TurnManager")
	if turn_manager == null:
		return true
	
	# Check if it's the owner's turn and main phase
	var current_phase = turn_manager.current_phase
	var current_unit = turn_manager.current_unit
	
	if current_phase != Enums.TurnPhase.MAIN:
		return false
	
	# Check if current unit belongs to this card's owner
	if current_unit == null:
		return false
		
	
	return current_unit.team == _get_owner_team()

## Get owner's team
func _get_owner_team() -> Enums.Team:
	if owner_player != null and owner_player.has_method("get"):
		return owner_player.team
	return Enums.Team.PLAYER

# ============================================================================
# CARD PLAYING
# ============================================================================

## Play this card
func play(target, game_state: Node) -> void:
	if not can_play(game_state):
		EventBus.show_error("Cannot play card: %s" % get_display_name())
		return
	
	EventBus.log_debug("Playing card '%s' [ID:%d]" % [name, instance_id], "Card")
	
	# Pay mana cost
	#if not pay_mana_cost(game_state):
		#EventBus.show_error("Cannot pay mana cost")
		#return
	
	# Emit signal
	EventBus.card_played.emit(self, owner_player, target)
	
	# Move card to discard pile
	_move_to_discard(game_state)
	
	# Execute all effects
	await _execute_effects(target, game_state)
	

## Pay the mana cost
func pay_mana_cost(game_state: Node) -> bool:
	var mana_system = game_state.get_node_or_null("ManaSystem")
	if mana_system == null:
		push_error("Card: ManaSystem not found")
		return false
	
	return mana_system.spend_mana(owner_player, get_mana_cost())

## Execute all card effects
func _execute_effects(target, game_state: Node) -> void:
	if card_data == null or card_data.effects.is_empty():
		return
	
	# Get the caster (the unit currently taking the turn)
	var caster = _get_caster(game_state)
	if caster == null:
		push_error("Card: cannot find caster")
		return
	
	# Execute each effect
	for effect in card_data.effects:
		if effect == null:
			continue
		
		# Apply ignore_passives flag from card
		if card_data.ignore_passives and effect.has_method("set"):
			effect.ignores_passives = true
		
		# Execute effect
		await effect.execute(caster, target, game_state)

## Get the caster (current unit taking turn)
func _get_caster(game_state: Node) -> Node:
	var turn_manager = game_state.get_node_or_null("TurnManager")
	if turn_manager == null:
		push_error("Card: TurnManager not found")
		return null
	
	return turn_manager.current_unit

## Move card to discard pile
func _move_to_discard(game_state: Node) -> void:
	if owner_player == null:
		return
	
	# Get deck system
	var deck_system = owner_player.get_node_or_null("DeckSystem")
	if deck_system == null:
		push_error("Card: DeckSystem not found")
		return
	
	# Remove from hand and add to discard
	deck_system.discard_card(self)
	in_hand = false
	
	EventBus.card_discarded.emit(self, owner_player)

# ============================================================================
# TARGETING
# ============================================================================

## Get valid targets for this card
func get_valid_targets(game_state: Node) -> Array:
	if card_data == null:
		return []
	
	var targeting_system = game_state.get_node_or_null("TargetingSystem")
	if targeting_system == null:
		push_warning("Card: TargetingSystem not found")
		return []
	
	var caster = _get_caster(game_state)
	if caster == null:
		return []
	
	return targeting_system.get_valid_targets_for_ability(
		card_data.target_type,
		caster.team,
		game_state.get_all_units()
	)

## Validate that a target is valid for this card
func validate_target(target, game_state: Node) -> bool:
	if card_data == null:
		return false
	
	var valid_targets = get_valid_targets(game_state)
	
	# For multi-target cards
	if target is Array:
		for t in target:
			if t not in valid_targets:
				return false
		return true
	
	# For single-target cards
	return target in valid_targets

## Auto-select target if possible (for auto-target cards)
func auto_select_target(game_state: Node) -> Variant:
	if card_data == null or not card_data.is_auto_target():
		return null
	
	var targeting_system = game_state.get_node_or_null("TargetingSystem")
	if targeting_system == null:
		return null
	
	var caster = _get_caster(game_state)
	if caster == null:
		return null
	
	return targeting_system.auto_select_target(
		card_data.target_type,
		caster.team,
		game_state.get_all_units()
	)

# ============================================================================
# QUERIES
# ============================================================================

## Get card name for display
func get_display_name() -> String:
	return card_data.card_name if card_data else "Unknown Card"

## Get mana cost
func get_mana_cost() -> int:
	return card_data.get_display_cost() if card_data else 0

## Get description
func get_description() -> String:
	return card_data.get_full_description() if card_data else ""

## Is this a quick play card?
func is_quick_play() -> bool:
	return card_data.is_quick_play if card_data else false

## Is this a skill card?
func is_skill_card() -> bool:
	return card_data.is_skill_card() if card_data else false

## Is this a basic card?
func is_basic_card() -> bool:
	return card_data.is_basic_card() if card_data else false

## Get owner unit name (for skill cards)
func get_owner_unit_name() -> String:
	return card_data.owner_unit_name if card_data else ""

## Get card type
func get_card_type() -> Enums.CardType:
	return card_data.card_type if card_data else Enums.CardType.BASIC

## Get card color (for UI)
func get_card_color() -> Color:
	return card_data.get_card_color() if card_data else Color.WHITE

## Get icon
func get_icon() -> Texture2D:
	return card_data.icon if card_data else null
	
func get_negated() -> bool:
	return is_negated

func get_can_be_negated() -> bool:
	return can_be_negated

func set_negated_status(status) -> void:
	is_negated = status

# ============================================================================
# UTILITY
# ============================================================================

## String representation
func _to_string() -> String: # changing to_string to _to_string
	return "%s [ID:%d] (Cost:%d)" % [get_display_name(), instance_id, get_mana_cost()]

## Compare cards (for sorting)
func compare_by_cost(other: Card) -> bool:
	return get_mana_cost() < other.get_mana_cost()

## Compare cards by name
func compare_by_name(other: Card) -> bool:
	return get_display_name() < other.get_display_name()
