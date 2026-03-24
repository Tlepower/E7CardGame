extends Node
class_name TurnManager
## TurnManager - Manages turn phases and unit actions
## Handles: START -> MAIN -> END phase transitions

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when human player explicitly ends their turn
signal player_turn_ended

# ============================================================================
# TURN STATE
# ============================================================================

## Current unit taking turn
var current_unit: Node = null

## Current turn phase
var current_phase: Enums.TurnPhase = Enums.TurnPhase.START

## Has the player taken any action this turn?
var turn_actions_taken: bool = false

## Is currently waiting for human player input?
var waiting_for_player: bool = false

# ============================================================================
# REFERENCES
# ============================================================================

## Reference to battle manager
var battle_manager: Node = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func initialize(manager: Node) -> void:
	battle_manager = manager
	EventBus.log_debug("TurnManager initialized", "Turn")

# ============================================================================
# TURN FLOW
# ============================================================================

## Start a unit's turn
func start_turn(unit: Node) -> void:
	if unit == null:
		push_error("TurnManager: cannot start turn for null unit")
		return
	
	current_unit = unit
	current_phase = Enums.TurnPhase.START
	turn_actions_taken = false
	waiting_for_player = false
	
	EventBus.turn_started.emit(unit)
	EventBus.log_debug("=== %s's turn started ===" % unit.name, "Turn")
	
	# Execute start phase
	await _execute_start_phase()
	
	# Move to main phase
	await advance_to_main_phase()

## Execute START phase
func _execute_start_phase() -> void:
	current_phase = Enums.TurnPhase.START
	EventBus.turn_phase_changed.emit(current_phase, current_unit)
	
	# Call unit's turn start
	current_unit.on_turn_start()
	
	# Get mana system
	var mana_system = battle_manager.get_node_or_null("ManaSystem")
	if mana_system != null:
		var player = _find_player_for_unit(current_unit)
		if player != null:
			mana_system.reset_mana(player)
	
	# Draw a card
	var draw_system = battle_manager.get_node_or_null("DrawSystem")
	if draw_system != null:
		var player = _find_player_for_unit(current_unit)
		if player != null:
			draw_system.draw_card_for_player(player, current_unit)
	
	EventBus.log_debug("Start phase complete", "Turn")

## Advance to MAIN phase
func advance_to_main_phase() -> void:
	current_phase = Enums.TurnPhase.MAIN
	EventBus.turn_phase_changed.emit(current_phase, current_unit)
	
	var owner_player = _find_player_for_unit(current_unit)
	
	if owner_player != null and owner_player.is_ai:
		# AI handles its own turn then ends it
		await _handle_ai_turn()
	else:
		# Human player: suspend here until they call request_end_turn()
		waiting_for_player = true
		EventBus.log_debug("Waiting for player input (press ENTER to end turn)...", "Turn")
		await player_turn_ended
		waiting_for_player = false

## Called by the UI or TestBattle input handler to end the human player's turn
func request_end_turn() -> void:
	if not waiting_for_player:
		EventBus.log_debug("request_end_turn called but not waiting for player", "Turn")
		return
	
	player_turn_ended.emit()
	await end_turn()

## Handle AI taking their turn
func _handle_ai_turn() -> void:
	# Get AI decision maker
	var ai = battle_manager.get_node_or_null("AIDecisionMaker")
	if ai == null:
		EventBus.log_debug("No AI found, defaulting to auto-attack", "Turn")
		await get_tree().create_timer(1.0).timeout
		await end_turn()
		return
	
	# Find AI player
	var ai_player = _find_player_for_unit(current_unit)
	if ai_player == null:
		EventBus.log_debug("Cannot find AI player", "Turn")
		await end_turn()
		return
	
	# Let AI decide and execute action
	await ai.take_turn(ai_player, current_unit)
	##await get_tree().create_timer(1.0).timeout
	await end_turn()

## End the current turn
func end_turn() -> void:
	if current_unit == null:
		return
	
	# Auto-basic attack if no actions taken
	if not turn_actions_taken:
		await _auto_basic_attack()
	
	# Move to END phase
	await _execute_end_phase()
	
	# Signal turn ended
	EventBus.turn_ended.emit(current_unit)
	EventBus.log_debug("=== %s's turn ended ===" % current_unit.name, "Turn")
	
	# Clear current unit
	current_unit = null
	current_phase = Enums.TurnPhase.START

## Execute END phase
func _execute_end_phase() -> void:
	current_phase = Enums.TurnPhase.END
	EventBus.turn_phase_changed.emit(current_phase, current_unit)
	
	# Call unit's turn end
	current_unit.on_turn_end()
	
	EventBus.log_debug("End phase complete", "Turn")

## Auto-basic attack if no action taken
func _auto_basic_attack() -> void:
	if current_unit == null or not current_unit.is_alive():
		return
	
	EventBus.log_debug("No action taken, auto basic attack", "Turn")
	
	var targeting_system = battle_manager.get_node_or_null("TargetingSystem")
	if targeting_system == null:
		push_error("TurnManager: TargetingSystem not found")
		return
	
	var all_units = battle_manager.get_all_units()
	
	var enemy_team = Enums.get_opposite_team(current_unit.team)
	var enemies = []
	for unit in all_units:
		if unit.team == enemy_team and unit.is_alive():
			enemies.append(unit)
	
	if enemies.is_empty():
		EventBus.log_debug("No valid targets for auto basic attack", "Turn")
		return
	
	var target = targeting_system.select_lowest_hp_enemy(enemies)
	if target != null:
		await current_unit.use_basic_attack(target)

# ============================================================================
# ACTION EXECUTION
# ============================================================================

## Mark action as taken
func mark_action_taken() -> void:
	turn_actions_taken = true

## Check if player can take action
func can_take_action() -> bool:
	return current_phase == Enums.TurnPhase.MAIN

## Check if waiting for human player
func is_waiting_for_player() -> bool:
	return waiting_for_player

# ============================================================================
# HELPERS
# ============================================================================

## Find which player owns a unit
func _find_player_for_unit(unit: Node) -> Node:
	if unit == null or battle_manager == null:
		return null
	
	if battle_manager.has_method("get_player_by_team"):
		return battle_manager.get_player_by_team(unit.team)
	
	var player = battle_manager.get_node_or_null("Player")
	var enemy = battle_manager.get_node_or_null("Enemy")
	
	if player != null and player.has_method("get_alive_units"):
		if unit in player.get_alive_units():
			return player
	
	if enemy != null and enemy.has_method("get_alive_units"):
		if unit in enemy.get_alive_units():
			return enemy
	
	return null

# ============================================================================
# QUERIES
# ============================================================================

func get_current_unit() -> Node:
	return current_unit

func get_current_phase() -> Enums.TurnPhase:
	return current_phase

func is_unit_turn(unit: Node) -> bool:
	return current_unit == unit

func has_actions_taken() -> bool:
	return turn_actions_taken

func get_debug_info() -> String:
	return "Unit: %s | Phase: %s | Actions: %s | Waiting: %s" % [
		current_unit.name if current_unit else "None",
		Enums.phase_to_string(current_phase),
		turn_actions_taken,
		waiting_for_player
	]
