extends Node
class_name Player
## Player - Represents a player (human or AI) in battle
## Owns units, deck system, and tracks battle state

# ============================================================================
# PLAYER PROPERTIES
# ============================================================================

## Which team this player is on
@export var team: Enums.Team = Enums.Team.PLAYER

## Is this player controlled by AI?
@export var is_ai: bool = false

## Player name
@export var player_name: String = "Player"

# ============================================================================
# UNITS
# ============================================================================

## Units owned by this player (max 3)
var units: Array[Node] = []  # Array[Unit]

# ============================================================================
# DECK SYSTEM
# ============================================================================

## Deck system for this player
var deck_system: DeckSystem = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# Create deck system
	deck_system = DeckSystem.new()
	deck_system.name = "DeckSystem"
	add_child(deck_system)

## Initialize player with units and cards
func initialize(unit_datas: Array, basic_card_datas: Array) -> void:
	# Validate inputs
	if unit_datas.size() != 3:
		push_error("Player: must have exactly 3 units, got %d" % unit_datas.size())
		return
	
	if basic_card_datas.size() != 8:
		push_error("Player: must have exactly 8 basic cards, got %d" % basic_card_datas.size())
		return
	
	# Create units
	_create_units(unit_datas)
	
	# Initialize deck system
	if deck_system == null:
		_ready()  # Create deck system if not ready yet
	
	deck_system.initialize(self, unit_datas, basic_card_datas)
	
	EventBus.log_debug("Player '%s' initialized with %d units and %d deck cards" % [
		player_name,
		units.size(),
		deck_system.get_total_cards()
	], "Player")

## Create unit instances from unit data
func _create_units(unit_datas: Array) -> void:
	units.clear()
	
	for unit_data in unit_datas:
		if unit_data == null:
			push_error("Player: null unit data")
			continue
		
		# Create unit instance
		var unit = unit_data.create_instance(team)
		if unit == null:
			push_error("Player: failed to create unit from data")
			continue
		
		# Add to player
		units.append(unit)
		add_child(unit)
		
		EventBus.log_debug("Created unit: %s" % unit.name, "Player")

# ============================================================================
# UNIT QUERIES
# ============================================================================

## Get all units (alive and dead)
func get_units() -> Array[Node]:
	return units.duplicate()

## Get only alive units
func get_alive_units() -> Array[Node]:
	var alive: Array[Node] = []
	
	for unit in units:
		if unit.is_alive():
			alive.append(unit)
	
	return alive

## Get only dead units
func get_dead_units() -> Array[Node]:
	var dead: Array[Node] = []
	
	for unit in units:
		if not unit.is_alive():
			dead.append(unit)
	
	return dead

## Get unit by index (0-2)
func get_unit(index: int) -> Node:
	if index < 0 or index >= units.size():
		return null
	
	return units[index]

## Find unit by name
func find_unit_by_name(unit_name: String) -> Node:
	for unit in units:
		if unit.name == unit_name:
			return unit
	
	return null

# ============================================================================
# BATTLE STATE QUERIES
# ============================================================================

## Check if this player has lost (all units dead)
func has_lost() -> bool:
	return get_alive_units().is_empty()

## Check if this player has won (opponent has lost)
func has_won(opponent: Player) -> bool:
	return opponent != null and opponent.has_lost()

## Get total HP remaining
func get_total_hp() -> int:
	var total = 0
	
	for unit in units:
		total += unit.current_hp
	
	return total

## Get total max HP
func get_total_max_hp() -> int:
	var total = 0
	
	for unit in units:
		if unit.current_stats != null:
			total += unit.current_stats.max_hp
	
	return total

## Get HP percentage (0.0 - 1.0)
func get_hp_percent() -> float:
	var max_hp = get_total_max_hp()
	if max_hp == 0:
		return 0.0
	
	return float(get_total_hp()) / float(max_hp)

# ============================================================================
# DECK QUERIES
# ============================================================================

## Get hand
func get_hand() -> Array[Node]:
	if deck_system == null:
		return []
	
	return deck_system.get_hand()

## Get hand size
func get_hand_size() -> int:
	if deck_system == null:
		return 0
	
	return deck_system.get_hand_size()

## Get deck size
func get_deck_size() -> int:
	if deck_system == null:
		return 0
	
	return deck_system.get_deck_size()

## Get discard size
func get_discard_size() -> int:
	if deck_system == null:
		return 0
	
	return deck_system.get_discard_size()

# ============================================================================
# ACTIONS
# ============================================================================

## Draw starting hand
func draw_starting_hand() -> void:
	if deck_system == null:
		push_error("Player: deck system not initialized")
		return
	
	deck_system.draw_starting_hand()

## Draw a card
func draw_card(active_unit: Node = null) -> Node:
	if deck_system == null:
		push_error("Player: deck system not initialized")
		return null
	
	if active_unit != null:
		return deck_system.draw_with_priority(active_unit)
	else:
		return deck_system.draw_card()

## Discard a card
func discard_card(card: Node) -> void:
	if deck_system == null:
		return
	
	deck_system.discard_card(card)

# ============================================================================
# UNIT MANAGEMENT
# ============================================================================

## Handle unit death
func on_unit_died(unit: Node) -> void:
	EventBus.log_debug("Player '%s' lost unit: %s" % [player_name, unit.name], "Player")
	
	# Check if player lost
	if has_lost():
		EventBus.log_debug("Player '%s' has been defeated!" % player_name, "Player")

## Add a unit (for summon effects)
func add_unit(unit: Node) -> void:
	if units.size() >= 3:
		push_warning("Player: cannot add unit, already at max (3)")
		return
	
	units.append(unit)
	add_child(unit)
	
	EventBus.log_debug("Player '%s' summoned: %s" % [player_name, unit.name], "Player")

## Remove a unit
func remove_unit(unit: Node) -> void:
	if unit not in units:
		return
	
	units.erase(unit)
	unit.queue_free()
	
	EventBus.log_debug("Player '%s' removed unit: %s" % [player_name, unit.name], "Player")

# ============================================================================
# TURN START/END CALLBACKS
# ============================================================================

## Called when any of this player's units starts their turn
func on_unit_turn_start(unit: Node) -> void:
	# Player-level logic can go here
	# For now, mostly handled by unit itself
	pass

## Called when any of this player's units ends their turn
func on_unit_turn_end(unit: Node) -> void:
	# Player-level logic can go here
	pass

# ============================================================================
# UTILITY
# ============================================================================

## Get display name
func get_display_name() -> String:
	return player_name

## Get team name
func get_team_name() -> String:
	return Enums.team_to_string(team)

## Get player color (for UI)
func get_player_color() -> Color:
	return Color.BLUE if team == Enums.Team.PLAYER else Color.RED

## String representation
func _to_string() -> String: # changed to_string to _to_string
	return "%s [%s] - %d units alive, %d cards in hand" % [
		player_name,
		get_team_name(),
		get_alive_units().size(),
		get_hand_size()
	]

## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"name": player_name,
		"team": get_team_name(),
		"is_ai": is_ai,
		"units": units.size(),
		"alive_units": get_alive_units().size(),
		"hp_percent": get_hp_percent(),
		"hand_size": get_hand_size(),
		"deck_size": get_deck_size(),
		"discard_size": get_discard_size()
	}

# ============================================================================
# CLEANUP
# ============================================================================

## Clean up when battle ends
func cleanup() -> void:
	# Clean up units
	for unit in units:
		if unit != null:
			unit.cleanup()
	
	# Clean up deck system
	if deck_system != null:
		deck_system.queue_free()
