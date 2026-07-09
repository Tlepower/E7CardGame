extends Node
class_name AIDecisionMaker
## AIDecisionMaker - Core AI brain for strategic decision making
## Evaluates threats, priorities, and chooses optimal actions

# ============================================================================
# AI DIFFICULTY
# ============================================================================

enum Difficulty {
	EASY,      # Random actions, sometimes suboptimal
	MEDIUM,    # Basic threat assessment
	HARD       # Full strategic evaluation
}

var difficulty: Difficulty = Difficulty.MEDIUM

# ============================================================================
# REFERENCES
# ============================================================================

var battle_manager: BattleManager = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func initialize(manager: Node, ai_difficulty: Difficulty = Difficulty.MEDIUM) -> void:
	battle_manager = manager
	difficulty = ai_difficulty
	EventBus.log_debug("AIDecisionMaker initialized (Difficulty: %s)" % Difficulty.keys()[difficulty], "AI")

# ============================================================================
# MAIN DECISION MAKING
# ============================================================================

## Main AI turn - decide what action to take
func take_turn(ai_player: Node, current_unit: Node) -> void:
	EventBus.log_debug("AI (%s) is thinking..." % current_unit.name, "AI")
	
	# Small thinking delay for realism
	await get_tree().create_timer(0.3).timeout
	
	# Get available actions
	var hand = ai_player.get_hand()
	var mana_system = battle_manager.get_mana_system()
	var available_mana = mana_system.get_current_mana(ai_player)
	
	# Evaluate options
	var best_action = _evaluate_best_action(current_unit, hand, available_mana, ai_player)
	
	if best_action != null:
		await _execute_action(best_action, ai_player, current_unit)
	else:
		# No good actions, will auto basic attack
		EventBus.log_debug("AI has no playable cards, will auto-attack", "AI")

# ============================================================================
# ACTION EVALUATION
# ============================================================================

## Evaluate and choose best action
func _evaluate_best_action(unit: Unit, hand: Array, mana: int, player: Node) -> Dictionary:
	var playable_actions: Array[Dictionary] = []
	
	# Evaluate each card in hand
	for card in hand:
		if not _can_play_card(card, mana):
			continue
		
		var targets = _get_valid_targets_for_card(card, unit)
		if targets.is_empty():
			continue
		
		# Score each possible target
		for target in targets:
			var score = _score_card_play(card, unit, target)
			playable_actions.append({
				"type": "card",
				"card": card,
				"target": target,
				"score": score
			})
	
	# Evaluate ultimate if available
	if unit.can_use_ultimate():
		var ult_targets = _get_valid_targets_for_ultimate(unit)
		# checks if the ult is an AOE ult so all target are added to playable_action
		if unit.ultimate_data.target_type in [Enums.TargetType.ALL_ALLIES, Enums.TargetType.ALL_ENEMIES]:
			var score = _score_ultimate_use(unit, ult_targets)
			playable_actions.append({
				"type": "ultimate",
				"target": ult_targets,
				"score": score
			})
		else:
			for target in ult_targets:
				var score = _score_ultimate_use(unit, target)
				playable_actions.append({
					"type": "ultimate",
					"target": target,
					"score": score
				})
	
	# Choose best action based on difficulty
	if playable_actions.is_empty():
		return {}
	
	match difficulty:
		Difficulty.EASY:
			# Random choice
			return playable_actions[randi() % playable_actions.size()]
		Difficulty.MEDIUM, Difficulty.HARD:
			# Choose highest scored action
			playable_actions.sort_custom(func(a, b): return a.score > b.score)
			return playable_actions[0]
	
	return {}

## Can this card be played?
func _can_play_card(card: Node, mana: int) -> bool:
	if card == null:
		return false
		
	var turn_manager = battle_manager.get_node_or_null("TurnManager")
	if turn_manager == null:
		return true
	var current_unit = turn_manager.current_unit
	if card.card_data.is_skill_card():
		if current_unit.unit_data.unit_name != card.card_data.owner_unit_name:
			return false
	
	var cost = card.get_mana_cost()
	return cost <= mana

## Get valid targets for card
func _get_valid_targets_for_card(card: Node, caster: Node) -> Array:
	var targeting = battle_manager.get_targeting_system()
	var all_units = battle_manager.get_all_units()
	
	return targeting.get_valid_targets_for_ability(
		card.card_data.target_type,
		caster.team,
		all_units
	)

## Get valid targets for ultimate
func _get_valid_targets_for_ultimate(unit: Node) -> Array:
	if unit.ultimate_data == null:
		return []
	
	var targeting = battle_manager.get_targeting_system()
	var all_units = battle_manager.get_all_units()
	
	return targeting.get_valid_targets_for_ability(
		unit.ultimate_data.target_type,
		unit.team,
		all_units
	)

# ============================================================================
# ACTION SCORING
# ============================================================================

## Score playing a card on a target
func _score_card_play(card: Node, caster: Node, target) -> float:
	var score: float = 0.0
	
	# Base score from card type
	if "damage" in card.get_display_name().to_lower():
		score += 5.0
	if "heal" in card.get_display_name().to_lower():
		score += 3.0
	if "buff" in card.get_display_name().to_lower():
		score += 2.0
	
	# Target priority
	if target is Node:
		# Prefer low HP enemies (execute them)
		if target.team != caster.team:
			var hp_percent = target.get_hp_percent()
			score += (1.0 - hp_percent) * 10.0  # More points for lower HP
		
		# Prefer healing low HP allies
		if target.team == caster.team:
			var hp_percent = target.get_hp_percent()
			if hp_percent < 0.5:
				score += (1.0 - hp_percent) * 8.0
	
	# Mana efficiency
	var cost = card.get_mana_cost()
	if cost <= 1:
		score += 1.0  # Cheap cards are good
	
	return score

## Score using ultimate
func _score_ultimate_use(unit: Node, target) -> float:
	var score: float = 15.0  # Ultimates are powerful, high base score
	
	# AOE ultimates are great if multiple enemies alive
	if unit.ultimate_data.target_type == Enums.TargetType.ALL_ENEMIES:
		var enemy_count = _count_alive_enemies()
		score += enemy_count * 3.0
	
	if unit.ultimate_data.target_type == Enums.TargetType.ALL_ALLIES:
		var enemy_count = _count_alive_allies()
		score += enemy_count * 3.0
	
	# Single target ultimates prefer low HP targets
	if target is Node and target.team != unit.team:
		var hp_percent = target.get_hp_percent()
		score += (1.0 - hp_percent) * 5.0
	
	return score

# ============================================================================
# ACTION EXECUTION
# ============================================================================

## Execute the chosen action
func _execute_action(action: Dictionary, player: Node, unit: Node) -> void:
	match action.type:
		"card":
			await _play_card(action.card, player, unit, action.target)
		"ultimate":
			await _use_ultimate(unit, action.target)

## Play a card
func _play_card(card: Node, player: Node, unit: Node, target) -> void:
	EventBus.log_debug("AI plays: %s on %s" % [card.get_display_name(), target.name if target is Node else "targets"], "AI")
	
	# Check mana
	var mana_system = battle_manager.get_mana_system()
	var cost = card.get_mana_cost()
	
	if not mana_system.can_afford(player, cost):
		EventBus.log_debug("AI cannot afford card (this shouldn't happen)", "AI")
		return
	
	# Spend mana
	# mana_system.spend_mana(player, cost)
	
	# Play card
	# await card.play(target, battle_manager)
	await battle_manager.play_card(card,player,target)
	
	# Discard
	# player.discard_card(card)
	
	# Mark action taken
	var turn_manager = battle_manager.get_turn_manager()
	turn_manager.mark_action_taken()

## Use ultimate
func _use_ultimate(unit: Node, target) -> void:
	EventBus.log_debug("AI uses ultimate: %s" % unit.ultimate_data.ultimate_name, "AI")
	
	await unit.use_ultimate(target)
	
	# Mark action taken
	var turn_manager = battle_manager.get_turn_manager()
	turn_manager.mark_action_taken()

# ============================================================================
# UTILITY
# ============================================================================

## Count alive enemies
func _count_alive_enemies() -> int:
	var count = 0
	for unit in battle_manager.get_all_units():
		if unit.team == Enums.Team.ENEMY and unit.is_alive():
			count += 1
	return count

## Count alive allies
func _count_alive_allies() -> int:
	var count = 0
	for unit in battle_manager.get_all_units():
		if unit.team == Enums.Team.PLAYER and unit.is_alive():
			count += 1
	return count

## Get weakest enemy (lowest HP)
func _get_weakest_enemy() -> Node:
	var targeting = battle_manager.get_targeting_system()
	var enemies = []
	for unit in battle_manager.get_all_units():
		if unit.team == Enums.Team.ENEMY and unit.is_alive():
			enemies.append(unit)
	
	if enemies.is_empty():
		return null
	
	return targeting.select_lowest_hp_enemy(enemies)

## Get most wounded ally (lowest HP%)
func _get_most_wounded_ally() -> Node:
	var targeting = battle_manager.get_targeting_system()
	var allies = []
	for unit in battle_manager.get_all_units():
		if unit.team == Enums.Team.PLAYER and unit.is_alive():
			allies.append(unit)
	
	if allies.is_empty():
		return null
	
	return targeting.select_lowest_hp_percent_ally(allies)
