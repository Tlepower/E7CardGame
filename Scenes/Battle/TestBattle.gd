extends Node
## TestBattle - Hardcoded test battle for initial testing
## Creates a 3v3 battle with Warrior, Mage, Healer vs same composition

# ============================================================================
# BATTLE MANAGER
# ============================================================================

var battle_manager: BattleManager = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	print("=== INITIALIZING TEST BATTLE ===")
	
	# Create battle manager
	battle_manager = BattleManager.new()
	battle_manager.name = "BattleManager"
	add_child(battle_manager)
	
	# Wait for systems to be ready
	await get_tree().process_frame
	
	# Create test data
	var player_units = create_player_units()
	var enemy_units = create_enemy_units()
	var basic_cards = BasicCards.create_all()
	
	# Initialize battle
	battle_manager.initialize_battle(
		player_units,
		enemy_units,
		basic_cards,
		basic_cards
	)
	
	# Listen for phase changes to show player prompts
	EventBus.turn_phase_changed.connect(_on_phase_changed)
	
	print("Battle initialized!")
	print("Player units: %d" % battle_manager.player.get_units().size())
	print("Enemy units: %d" % battle_manager.enemy.get_units().size())
	
	# Print initial state
	print_battle_info()
	
	# Start battle after a short delay
	await get_tree().create_timer(1.0).timeout
	print("\n=== STARTING BATTLE ===\n")
	await battle_manager.start_battle()
	
	# Battle ended
	print("\n=== BATTLE ENDED ===")
	if battle_manager.winner != null:
		print("Winner: %s" % battle_manager.winner.get_display_name())

## Called whenever the turn phase changes
func _on_phase_changed(phase: Enums.TurnPhase, unit: Node) -> void:
	if phase != Enums.TurnPhase.MAIN:
		return
	
	# Check if this is the human player's unit
	var player = battle_manager.get_node_or_null("Player")
	if player == null:
		return
	
	if unit in player.get_units():
		print("\n╔══════════════════════════════╗")
		print("║     YOUR TURN: %s" % unit.name.rpad(14) + "║")
		print("╠══════════════════════════════╣")
		print("║  ENTER  → End turn           ║")
		print("║  SPACE  → Show battle state  ║")
		print("║  H      → Show hand          ║")
		print("║  T      → Show turn order    ║")
		print("╚══════════════════════════════╝")

# ============================================================================
# UNIT CREATION
# ============================================================================

func create_player_units() -> Array:
	print("Creating player units...")
	return [
		#WarriorUnitData.create(),
		#MageUnitData.create(),
		#DemonKingUnitData.create()
		ReaperVampireUnitData.create(),
		FencerUnitData.create()
	]

func create_enemy_units() -> Array:
	print("Creating enemy units...")
	# Enemy team has same composition
	return [
		WarriorUnitData.create(),
		MageUnitData.create(),
		HealerUnitData.create()
	]

# ============================================================================
# DEBUG OUTPUT
# ============================================================================

func print_battle_info() -> void:
	print("\n=== BATTLE INFO ===")
	
	print("\n--- PLAYER TEAM ---")
	for unit in battle_manager.player.get_units():
		print_unit_info(unit)
	
	print("\n--- ENEMY TEAM ---")
	for unit in battle_manager.enemy.get_units():
		print_unit_info(unit)
	
	print("\n--- PLAYER DECK ---")
	var player_deck = battle_manager.player.deck_system
	if player_deck:
		print("Total cards: %d" % player_deck.get_total_cards())
		print("Hand: %d | Deck: %d | Discard: %d" % [
			player_deck.get_hand_size(),
			player_deck.get_deck_size(),
			player_deck.get_discard_size()
		])
	
	print("\n===================\n")

func print_unit_info(unit: Node) -> void:
	if unit == null:
		return
	
	var stats = unit.get_stats()
	print("  %s:" % unit.name)
	print("    HP: %d/%d" % [unit.current_hp, stats.max_hp])
	print("    ATK: %d | DEF: %d | SPD: %d" % [
		stats.get_effective_atk(),
		stats.get_effective_def(),
		stats.get_effective_speed()
	])
	print("    CR: %.1f%% | CD: %.1f%%" % [
		stats.crit_rate * 100,
		stats.crit_damage * 100
	])

# ============================================================================
# INPUT HANDLING (for manual testing)
# ============================================================================

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	
	match event.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			# End player's turn
			var turn_manager = battle_manager.get_node_or_null("TurnManager")
			if turn_manager != null and turn_manager.is_waiting_for_player():
				print("\n[Player] Turn ended by ENTER key")
				turn_manager.request_end_turn()
			else:
				print("[Player] Not your turn right now")
		
		KEY_SPACE:
			print_current_state()
		
		KEY_T:
			print_turn_order()
		
		KEY_H:
			print_hands()
			
		KEY_P:
			print("\n[Player] will will play a card")
			await play_Card1()
		KEY_Q:
			get_tree().quit()

func print_current_state() -> void:
	print("\n=== CURRENT STATE ===")
	if battle_manager.turn_manager.current_unit:
		print("Current Turn: %s" % battle_manager.turn_manager.current_unit.name)
		print("Phase: %s" % Enums.phase_to_string(battle_manager.turn_manager.current_phase))
	
	print("\nPlayer HP: %.1f%%" % (battle_manager.player.get_hp_percent() * 100))
	print("Enemy HP: %.1f%%" % (battle_manager.enemy.get_hp_percent() * 100))
	
	print("\nPlayer Mana: %d" % battle_manager.mana_system.get_current_mana(battle_manager.player))
	print("Enemy Mana: %d" % battle_manager.mana_system.get_current_mana(battle_manager.enemy))
	print("====================\n")

func print_turn_order() -> void:
	print("\n=== TURN ORDER ===")
	var preview = battle_manager.turn_order_system.get_turn_order_preview(10)
	for i in preview.size():
		var unit = preview[i]
		print("%d. %s (AR: %.1f)" % [i + 1, unit.name, unit.action_readiness])
	print("==================\n")

func print_hands() -> void:
	print("\n=== HANDS ===")
	print("Player Hand:")
	for card in battle_manager.player.get_hand():
		print("  - %s (Cost: %d)" % [card.get_display_name(), card.get_mana_cost()])
	
	print("\nEnemy Hand:")
	for card in battle_manager.enemy.get_hand():
		print("  - %s (Cost: %d)" % [card.get_display_name(), card.get_mana_cost()])
	print("=============\n")

# ============================================================================
# Playing Cards, Cards and Ultmate
# ============================================================================

func play_Card1():
	
	return;

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _on_battle_ended(winner: Node) -> void:
	print("\n!!! BATTLE ENDED !!!")
	print("Winner: %s" % winner.get_display_name())
