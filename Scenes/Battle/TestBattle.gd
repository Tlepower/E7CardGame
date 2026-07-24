extends Node
## TestBattle - Hardcoded test battle for initial testing
## Creates a 3v3 battle with Warrior, Mage, Healer vs same composition

# ============================================================================
# BATTLE MANAGER
# ============================================================================

var battle_manager: BattleManager = null

var targeting: bool = false
var targetunits: Array
var abilily

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
	targeting = false
	abilily = null
	targetunits = []
	
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
		print("║  #      → Play a card        ║")
		print("║  L      → Show Unit stats    ║")
		print("║  U      → Show Unit Ult      ║")
		print("║  B      → Show Unit basic    ║")
		print("╚══════════════════════════════╝")

# ============================================================================
# UNIT CREATION
# ============================================================================

func create_player_units() -> Array:
	print("Creating player units...")
	return [
		#WarriorUnitData.create(),
		#MageUnitData.create(),
		#DemonKingUnitData.create(),
		#AssassinUnitData.create(),
		ReaperVampireUnitData.create(),
		#FencerUnitData.create()
		SniperUnitData.create()
	]

func create_enemy_units() -> Array:
	print("Creating enemy units...")
	# Enemy team has same composition
	return [
		#ReaperVampireUnitData.create(),
		WarriorUnitData.create(),
		#AssassinUnitData.create()
		#MageUnitData.create(),
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

func print_unit_info(unit: Unit) -> void:
	if unit == null:
		return
	
	var stats = unit.get_stats()
	var status_effects = unit.status_effects
	print("  %s:" % unit.name)
	print("    HP: %d/%d" % [unit.current_hp, stats.max_hp,])
	print("    ATK: %d | DEF: %d | SPD: %d" % [
		stats.get_effective_atk(),
		stats.get_effective_def(),
		stats.get_effective_speed()
	])
	print("    CR: %.1f%% | CD: %.1f%%" % [
		stats.crit_rate * 100,
		stats.crit_damage * 100
	])
	var effect_names: Array = []
	for status_effect in status_effects:
		effect_names.append(status_effect.effect_name)
	print("    StatusEffect: %s" % [", ".join(effect_names) if not effect_names.is_empty() else "no buffs or debuffs"])
	print("    Ultimate CD: %d" % unit.ultimate_cooldown)

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
				await turn_manager.request_end_turn()
			else:
				print("[Player] Not your turn right now")
		
		KEY_SPACE:
			print_current_state()
			print("\n--- PLAYER TEAM ---")
			for unit in battle_manager.player.get_units():
				print_unit_info(unit)
	
			print("\n--- ENEMY TEAM ---")
			for unit in battle_manager.enemy.get_units():
				print_unit_info(unit)
		
		KEY_T:
			print_turn_order()
		
		KEY_H:
			print_hands()
			
		KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
			print("\n[Player] will play a card")
			await get_target(event)
		
		KEY_W, KEY_E, KEY_R:
			if targeting:
				if abilily is Card and abilily in battle_manager.player.get_hand(): 
					var targets = event_to_int(event)
					await play_Card(targets)
				elif abilily == "Ultimate":
					var targets = event_to_int(event)
					await play_Ultimate(targets)
				elif abilily == "BasicAttack":
					var targets = event_to_int(event)
					await play_BasicAttack(targets)
				else:
					pass
		
		KEY_U:
			print("Player is using Unit's Ultimate")
			await get_target(event)
		
		KEY_B:
			print("Player is using Unit's Basic Attack")
			await get_target(event)
		
		KEY_L:
			_get_current_unit_info()
			
		KEY_P:
			pass_priority()
		
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
	var hand = battle_manager.player.get_hand()
	for x in range(hand.size()):
		var card = hand[x]
		print(" %d - %s (Cost: %d%s) %s" % [x,card.get_display_name(), card.get_mana_cost(), ", Quick Play" if card.is_quick_play() else "", card.get_owner_unit_name() if card.is_skill_card() else ""])
		print(" Card Effect: %s \n" % [card.card_data.description])
	
	print("\nEnemy Hand:")
	for card in battle_manager.enemy.get_hand():
		print("  - %s (Cost: %d)" % [card.get_display_name(), card.get_mana_cost()])
		
	print("=============\n")

# ============================================================================
# Playing Cards, Cards and Ultmate
# ============================================================================

func play_Card(targets) -> void:
	if targets == null:
		return
	await battle_manager.play_card(abilily,battle_manager.player,targets)
	print("Finshed playing %s " % [abilily.get_display_name()])
	targeting = false
	targetunits = []
	abilily = null

func play_Ultimate(targets) -> void:
	if targets == null:
		return
	if battle_manager.quick_play_system.is_window_active():
		return
	await battle_manager.use_ultimate(_get_current_unit(),targets)
	print("Finshed playing %s " % [_get_current_unit().ultimate_data.ultimate_name])
	targeting = false
	targetunits = []
	abilily = null

func play_BasicAttack(targets) -> void:
	if targets == null:
		return
	await battle_manager.use_basic_attack(_get_current_unit(),targets)
	print("Finshed playing %s " % [_get_current_unit().basic_attack_data.attack_name])
	targeting = false
	targetunits = []
	abilily = null
	

func get_target(event: InputEvent) -> void:
	var key = event_to_int(event)
	
	## get the targetingSystem
	var targetingSystem = battle_manager.get_targeting_system()
	if targetingSystem == null:
		print("TargetingSystem doesn't exist")
		return
	
	var TargetType: Enums.TargetType
	
	if typeof(key) == TYPE_STRING and key == "Ultimate":
		var current_unit = _get_current_unit()
		TargetType = current_unit.ultimate_data.target_type
		abilily = key
	elif typeof(key) == TYPE_STRING and key == "BasicAttack":
		var current_unit = _get_current_unit()
		TargetType = current_unit.basic_attack_data.target_type
		abilily = key
	elif  typeof(key) == TYPE_INT and key in [0,1,2,3,4,5,6,7,8,9]:
		var cards = battle_manager.player.get_hand()
		if cards == null:
			return
		if key > cards.size() + 1:
			return 
		var card = cards[key]
		TargetType = card.card_data.target_type
		abilily = card
	else:
		return
	
	# get card from the key
	
	var TargetUnits: Array = targetingSystem.get_valid_targets_for_ability(TargetType,Enums.Team.PLAYER,battle_manager.get_all_units())
	
	if TargetType in [Enums.TargetType.SINGLE_ENEMY, Enums.TargetType.SINGLE_ALLY]:
		print("\nWho do you want to target")
		for target in TargetUnits:
			print("%s " % [target.name])
		targeting = true
		targetunits = TargetUnits
	elif TargetType in [Enums.TargetType.ALL_ENEMIES, Enums.TargetType.ALL_ALLIES, Enums.TargetType.SELF, Enums.TargetType.OTHER_ALLIES]:
		if abilily is Card and abilily in battle_manager.player.get_hand(): 
			await play_Card(TargetUnits)
		elif abilily == "Ultimate":
			await play_Ultimate(TargetUnits)
		elif abilily == "BasicAttack":
			await play_BasicAttack(TargetUnits)
		
# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
func pass_priority():
	var quick_play_system = battle_manager.quick_play_system
	var player = battle_manager.player
	if quick_play_system.is_window_active():
		quick_play_system.player_passes(player)

func event_to_int(event: InputEvent):
	if event is InputEventKey:
		match event.keycode:
			KEY_0: return 0
			KEY_1: return 1
			KEY_2: return 2
			KEY_3: return 3
			KEY_4: return 4
			KEY_5: return 5
			KEY_6: return 6
			KEY_7: return 7
			KEY_8: return 8
			KEY_9: return 9
			KEY_W: return targetunits[0]
			KEY_E: return targetunits[1]
			KEY_R: return targetunits[2]
			KEY_U: return "Ultimate"
			KEY_B: return "BasicAttack"
			
	return -1  # unrecognized
	
func _get_current_unit() -> Unit:
	var turnmanager = battle_manager.get_turn_manager()
	return turnmanager.current_unit

func _get_current_unit_info() -> void:
	var current_unit = _get_current_unit()
	print_unit_info(current_unit)

func _on_battle_ended(winner: Node) -> void:
	print("\n!!! BATTLE ENDED !!!")
	print("Winner: %s" % winner.get_display_name())
