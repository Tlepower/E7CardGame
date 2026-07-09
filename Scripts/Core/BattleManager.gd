extends Node
class_name BattleManager
## BattleManager - Main battle coordinator
## Orchestrates all battle systems and manages game flow

# ============================================================================
# BATTLE STATE
# ============================================================================

## Current battle state
enum BattleState {
	SETUP,          ## Initializing battle
	STARTING_HAND,  ## Drawing starting hands
	ONGOING,        ## Battle in progress
	ENDED           ## Battle complete
}

var battle_state: BattleState = BattleState.SETUP

# ============================================================================
# PLAYERS
# ============================================================================

## Player 1 (human player)
var player: Player = null

## Player 2 (enemy/AI)
var enemy: Player = null

## Winner of the battle
var winner: Player = null

# ============================================================================
# GAME SYSTEMS
# ============================================================================

## Turn order system
var turn_order_system: TurnOrderSystem = null

## Turn manager
var turn_manager: TurnManager = null

## Mana system
var mana_system: ManaSystem = null

## Status effect system
var status_effect_system: StatusEffectSystem = null

## Damage calculator
var damage_calculator: DamageCalculator = null

## Targeting system
var targeting_system: TargetingSystem = null

## Draw system
var draw_system: DrawSystem = null

## Quick play system
var quick_play_system: QuickPlaySystem = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# Create all game systems as children
	_create_game_systems()

## Create all game systems
func _create_game_systems() -> void:
	# Turn order
	turn_order_system = TurnOrderSystem.new()
	turn_order_system.name = "TurnOrderSystem"
	add_child(turn_order_system)
	
	# Turn manager
	turn_manager = TurnManager.new()
	turn_manager.name = "TurnManager"
	add_child(turn_manager)
	turn_manager.initialize(self)
	
	# Mana
	mana_system = ManaSystem.new()
	mana_system.name = "ManaSystem"
	add_child(mana_system)
	mana_system.initialize()
	
	# Status effects
	status_effect_system = StatusEffectSystem.new()
	status_effect_system.name = "StatusEffectSystem"
	add_child(status_effect_system)
	
	# Damage calculator
	damage_calculator = DamageCalculator.new()
	damage_calculator.name = "DamageCalculator"
	add_child(damage_calculator)
	
	# Targeting
	targeting_system = TargetingSystem.new()
	targeting_system.name = "TargetingSystem"
	add_child(targeting_system)
	
	# Draw system
	draw_system = DrawSystem.new()
	draw_system.name = "DrawSystem"
	add_child(draw_system)
	
	# Quick play
	quick_play_system = QuickPlaySystem.new()
	quick_play_system.name = "QuickPlaySystem"
	add_child(quick_play_system)
	quick_play_system.initialize(self)
	
	# AI Decision Maker
	var ai = AIDecisionMaker.new()
	ai.name = "AIDecisionMaker"
	add_child(ai)
	ai.initialize(self, AIDecisionMaker.Difficulty.MEDIUM)
	
	EventBus.log_debug("All game systems created", "Battle")

## Initialize battle with player configurations
func initialize_battle(
	player_unit_datas: Array,
	enemy_unit_datas: Array,
	player_basic_cards: Array,
	enemy_basic_cards: Array
) -> void:
	
	EventBus.log_debug("=== INITIALIZING BATTLE ===", "Battle")
	battle_state = BattleState.SETUP
	
	# Create players
	player = Player.new()
	player.name = "Player"
	player.player_name = "Player"
	player.team = Enums.Team.PLAYER
	player.is_ai = false
	add_child(player)
	
	enemy = Player.new()
	enemy.name = "Enemy"
	enemy.player_name = "Enemy"
	enemy.team = Enums.Team.ENEMY
	enemy.is_ai = true
	add_child(enemy)
	
	# Initialize players with units and decks
	player.initialize(player_unit_datas, player_basic_cards)
	enemy.initialize(enemy_unit_datas, enemy_basic_cards)
	
	# Set battle manager reference on all units
	for unit in get_all_units():
		unit.set_battle_manager(self)
	
	# Initialize turn order system
	turn_order_system.initialize(player.get_units(), enemy.get_units())
	
	# Connect signals
	_connect_signals()
	
	EventBus.battle_initialized.emit()
	EventBus.log_debug("Battle initialized", "Battle")

## Connect to important signals
func _connect_signals() -> void:
	EventBus.unit_died.connect(_on_unit_died)

# ============================================================================
# BATTLE FLOW
# ============================================================================

## Start the battle
func start_battle() -> void:
	EventBus.log_debug("=== BATTLE START ===", "Battle")
	battle_state = BattleState.STARTING_HAND
	
	# Draw starting hands
	draw_system.draw_starting_hand(player)
	draw_system.draw_starting_hand(enemy)
	
	battle_state = BattleState.ONGOING
	EventBus.battle_started.emit()
	
	# Start main battle loop
	await _battle_loop()

## Main battle loop
func _battle_loop() -> void:
	while battle_state == BattleState.ONGOING:
		# Get next unit to act
		var next_unit = turn_order_system.calculate_next_turn()
		
		if next_unit == null:
			push_error("BattleManager: no unit could take turn")
			break
		
		# Execute turn
		await turn_manager.start_turn(next_unit)
		
		# Check win condition
		if check_win_condition():
			break
		
		# Small delay between turns
		await get_tree().create_timer(0.5).timeout

## Check win condition
func check_win_condition() -> bool:
	if player.has_lost():
		end_battle(enemy)
		return true
	
	if enemy.has_lost():
		end_battle(player)
		return true
	
	return false

## End the battle
func end_battle(winning_player: Player) -> void:
	battle_state = BattleState.ENDED
	winner = winning_player
	
	EventBus.log_debug("=== BATTLE END ===", "Battle")
	EventBus.log_debug("Winner: %s" % winning_player.get_display_name(), "Battle")
	
	EventBus.battle_ended.emit(winning_player)

# ============================================================================
# CARD PLAYING
# ============================================================================

## Play a card
func play_card(card: Node, player_node: Player, target) -> void:
	if card == null or player_node == null:
		push_error("BattleManager: cannot play card - null card or player")
		return
	
	# Validate it's the player's turn
	var current_unit = turn_manager.get_current_unit()
	if current_unit == null:
		push_error("BattleManager: no current unit")
		return
	
	# Check if unit belongs to player
	if current_unit not in player_node.get_alive_units():
		push_error("BattleManager: not this player's turn")
		return
	
	# Check if in main phase
	if not turn_manager.can_take_action():
		push_error("BattleManager: cannot play cards outside main phase")
		return
	
	if card.can_afford_mana(self):
		card.pay_mana_cost(self)
	# Play the card
	# await card.play(target, self)
	if not quick_play_system.is_window_active():
		quick_play_system.open_window("%s just played a card" % [player_node.get_display_name()],player_node,get_opponent(player_node))
		
	await quick_play_system.player_plays_card(card,player_node,target,current_unit)
	
	# Mark action taken
	turn_manager.mark_action_taken()
	
	# Open quick play window for Quick Play cards
	# Note: Per updated specs, ultimates are NOT quick play
	# Only certain cards marked as quick_play
	# Since we just played a card, we don't open window for our own card
	# Quick play window would be for responding to opponent's cards
	# This may need adjustment based on exact game rules

## Use basic attack
func use_basic_attack(unit: Node, target: Node) -> void:
	if unit == null or target == null:
		return
	
	# Validate it's this unit's turn
	if turn_manager.get_current_unit() != unit:
		push_error("BattleManager: not this unit's turn")
		return
	
	# Use basic attack
	await unit.use_basic_attack(target)
	
	# Mark action taken
	turn_manager.mark_action_taken()

## Use ultimate
func use_ultimate(unit: Node, target) -> void:
	if unit == null:
		return
	
	# Validate it's this unit's turn
	if turn_manager.get_current_unit() != unit:
		push_error("BattleManager: not this unit's turn")
		return
	
	# Use ultimate
	await unit.use_ultimate(target)
	
	# Mark action taken
	turn_manager.mark_action_taken()

# ============================================================================
# EVENT HANDLERS
# ============================================================================

## Handle unit death
func _on_unit_died(unit: Node) -> void:
	EventBus.log_debug("Unit died: %s" % unit.name, "Battle")
	
	# Remove from turn order
	turn_order_system.remove_unit(unit)
	
	# Check win condition
	check_win_condition()

## Handle unit death (called by unit or player)
func handle_unit_death(unit: Node) -> void:
	_on_unit_died(unit)

# ============================================================================
# QUERIES
# ============================================================================

## Get all units in battle
func get_all_units() -> Array:
	var units: Array = []
	
	if player != null:
		units.append_array(player.get_units())
	
	if enemy != null:
		units.append_array(enemy.get_units())
	
	return units

## Get player by team
func get_player_by_team(team: Enums.Team) -> Player:
	if team == Enums.Team.PLAYER:
		return player
	else:
		return enemy

## Get opponent of a player
func get_opponent(player_node: Player) -> Player:
	if player_node == player:
		return enemy
	else:
		return player

# ============================================================================
# SYSTEM GETTERS
# ============================================================================

## Get damage calculator
func get_damage_calculator() -> DamageCalculator:
	return damage_calculator

## Get status effect system
func get_status_effect_system() -> StatusEffectSystem:
	return status_effect_system

## Get targeting system
func get_targeting_system() -> TargetingSystem:
	return targeting_system

## Get turn order system
func get_turn_order_system() -> TurnOrderSystem:
	return turn_order_system

## Get mana system
func get_mana_system() -> ManaSystem:
	return mana_system

## Get draw system
func get_draw_system() -> DrawSystem:
	return draw_system

## Get quick play system
func get_quick_play_system() -> QuickPlaySystem:
	return quick_play_system

## Get turn manager
func get_turn_manager() -> TurnManager:
	return turn_manager

# ============================================================================
# CLEANUP
# ============================================================================

## Clean up when battle ends
func cleanup() -> void:
	# Clean up players
	if player != null:
		player.cleanup()
		player.queue_free()
	
	if enemy != null:
		enemy.cleanup()
		enemy.queue_free()
	
	# Systems will be freed automatically as children

# ============================================================================
# DEBUG
# ============================================================================

## Get battle state string
func get_battle_state_string() -> String:
	match battle_state:
		BattleState.SETUP:
			return "Setup"
		BattleState.STARTING_HAND:
			return "Drawing Starting Hands"
		BattleState.ONGOING:
			return "Ongoing"
		BattleState.ENDED:
			return "Ended"
		_:
			return "Unknown"

## Print battle state
func print_battle_state() -> void:
	print("=== BATTLE STATE ===")
	print("State: %s" % get_battle_state_string())
	print("Turn: %s" % (turn_manager.get_current_unit().name if turn_manager.get_current_unit() else "None"))
	print("Phase: %s" % Enums.phase_to_string(turn_manager.get_current_phase()))
	print("\nPlayer: %s" % player.to_string())
	print("Enemy: %s" % enemy.to_string())
	print("\nTurn Order:")
	turn_order_system.print_turn_order()
	print("===================")
