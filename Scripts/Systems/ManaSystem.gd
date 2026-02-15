extends Node
class_name ManaSystem
## ManaSystem - Manages mana for both players
## Mana resets to 3 at the start of each turn (even opponent's turns)

# ============================================================================
# CONSTANTS
# ============================================================================

const DEFAULT_MANA: int = 3
const MAX_MANA: int = 10  # Just in case, prevent overflow

# ============================================================================
# MANA TRACKING
# ============================================================================

## Current mana for player
var player_mana: int = DEFAULT_MANA

## Current mana for enemy
var enemy_mana: int = DEFAULT_MANA

## Mana history (for undo/replay if needed)
var mana_history: Array[Dictionary] = []

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# Connect to turn events
	EventBus.turn_started.connect(_on_turn_started)

## Initialize mana for both players
func initialize() -> void:
	player_mana = DEFAULT_MANA
	enemy_mana = DEFAULT_MANA
	mana_history.clear()
	
	EventBus.log_debug("ManaSystem initialized - both players at %d mana" % DEFAULT_MANA, "Mana")

# ============================================================================
# MANA RESET
# ============================================================================

## Reset mana to default amount (called at turn start)
func reset_mana(player: Node) -> void:
	if player == null:
		push_error("ManaSystem: player is null")
		return
	
	var old_mana = get_current_mana(player)
	
	if _is_player_team(player):
		player_mana = DEFAULT_MANA
	else:
		enemy_mana = DEFAULT_MANA
	
	EventBus.mana_changed.emit(player, DEFAULT_MANA, old_mana)
	EventBus.log_debug("%s mana reset to %d" % [_get_player_name(player), DEFAULT_MANA], "Mana")

## Called when any unit's turn starts (player or enemy)
func _on_turn_started(unit: Node) -> void:
	if unit == null:
		return
	
	# Find which player this unit belongs to
	var player = _find_player_for_unit(unit)
	if player != null:
		reset_mana(player)

# ============================================================================
# SPENDING MANA
# ============================================================================

## Spend mana
## Returns true if successful, false if not enough mana
func spend_mana(player: Node, amount: int) -> bool:
	if player == null:
		push_error("ManaSystem: player is null")
		return false
	
	if amount < 0:
		push_error("ManaSystem: cannot spend negative mana")
		return false
	
	var current = get_current_mana(player)
	
	if current < amount:
		EventBus.log_debug("%s tried to spend %d mana but only has %d" % [_get_player_name(player), amount, current], "Mana")
		return false
	
	# Spend the mana
	if _is_player_team(player):
		player_mana -= amount
	else:
		enemy_mana -= amount
	
	EventBus.mana_spent.emit(player, amount)
	EventBus.mana_changed.emit(player, get_current_mana(player), current)
	
	EventBus.log_debug("%s spent %d mana (%d remaining)" % [_get_player_name(player), amount, get_current_mana(player)], "Mana")
	
	return true

# ============================================================================
# REFUNDING MANA
# ============================================================================

## Refund mana (when card is cancelled, etc.)
func refund_mana(player: Node, amount: int) -> void:
	if player == null or amount <= 0:
		return
	
	var old_mana = get_current_mana(player)
	
	if _is_player_team(player):
		player_mana = mini(player_mana + amount, MAX_MANA)
	else:
		enemy_mana = mini(enemy_mana + amount, MAX_MANA)
	
	EventBus.mana_changed.emit(player, get_current_mana(player), old_mana)
	EventBus.log_debug("%s refunded %d mana (%d total)" % [_get_player_name(player), amount, get_current_mana(player)], "Mana")

# ============================================================================
# QUERIES
# ============================================================================

## Get current mana for a player
func get_current_mana(player: Node) -> int:
	if player == null:
		return 0
	
	if _is_player_team(player):
		return player_mana
	else:
		return enemy_mana

## Check if player can afford a cost
func can_afford(player: Node, cost: int) -> bool:
	return get_current_mana(player) >= cost

## Get mana percentage (for UI bars)
func get_mana_percent(player: Node) -> float:
	var current = get_current_mana(player)
	return float(current) / float(MAX_MANA)

# ============================================================================
# ADVANCED OPERATIONS
# ============================================================================

## Set mana directly (for special effects)
func set_mana(player: Node, amount: int) -> void:
	if player == null:
		return
	
	var old_mana = get_current_mana(player)
	var new_mana = clampi(amount, 0, MAX_MANA)
	
	if _is_player_team(player):
		player_mana = new_mana
	else:
		enemy_mana = new_mana
	
	EventBus.mana_changed.emit(player, new_mana, old_mana)

## Add mana (for ramp effects)
func add_mana(player: Node, amount: int) -> void:
	if player == null or amount <= 0:
		return
	
	var old_mana = get_current_mana(player)
	
	if _is_player_team(player):
		player_mana = mini(player_mana + amount, MAX_MANA)
	else:
		enemy_mana = mini(enemy_mana + amount, MAX_MANA)
	
	EventBus.mana_changed.emit(player, get_current_mana(player), old_mana)

## Reduce mana (for mana drain effects)
func reduce_mana(player: Node, amount: int) -> void:
	if player == null or amount <= 0:
		return
	
	var old_mana = get_current_mana(player)
	
	if _is_player_team(player):
		player_mana = maxi(0, player_mana - amount)
	else:
		enemy_mana = maxi(0, enemy_mana - amount)
	
	EventBus.mana_changed.emit(player, get_current_mana(player), old_mana)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Check if this is the player team
func _is_player_team(player: Node) -> bool:
	if player == null:
		return false
	
	if player.has_method("get"):
		return player.team == Enums.Team.PLAYER
	
	# Fallback: check name
	return player.name == "Player"

## Get player name for logging
func _get_player_name(player: Node) -> String:
	if player == null:
		return "Unknown"
	
	if _is_player_team(player):
		return "Player"
	else:
		return "Enemy"

## Find which player a unit belongs to
func _find_player_for_unit(unit: Node) -> Node:
	if unit == null:
		return null
	
	# Try to get from scene tree
	var tree = get_tree()
	if tree == null:
		return null
	
	var root = tree.root
	if root == null:
		return null
	
	var battle_manager = root.get_node_or_null("BattleManager")
	if battle_manager == null:
		return null
	
	# Check which player owns this unit
	var player = battle_manager.get_node_or_null("Player")
	var enemy = battle_manager.get_node_or_null("Enemy")
	
	if player != null and player.has_method("get_alive_units"):
		var player_units = player.get_alive_units()
		if unit in player_units:
			return player
	
	if enemy != null and enemy.has_method("get_alive_units"):
		var enemy_units = enemy.get_alive_units()
		if unit in enemy_units:
			return enemy
	
	# Fallback: use team
	if unit.has_method("get") and unit.get("team") != null:
		if unit.team == Enums.Team.PLAYER:
			return player
		else:
			return enemy
	
	return null

# ============================================================================
# DEBUG
# ============================================================================

## Get debug info
func get_debug_info() -> String:
	return "Player: %d | Enemy: %d" % [player_mana, enemy_mana]
