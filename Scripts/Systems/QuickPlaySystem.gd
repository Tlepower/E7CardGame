extends Node
class_name QuickPlaySystem
## QuickPlaySystem - Handles Quick Play card chaining (like Yu-Gi-Oh chain system)
## FIFO for priority, LIFO for resolution (stack-based)
## Chain limit: 15 effects maximum

# ============================================================================
# QUICK PLAY STATE
# ============================================================================

## Is the quick play window currently active?
var is_quick_play_window_active: bool = false

## Effect stack (LIFO resolution)
## Each entry: {card: Card, player: Player, target: Variant, caster: Node}
var effect_stack: Array[Dictionary] = []

## Which player currently has priority to respond
var priority_player: Player = null

## Other player (for priority passing)
var other_player: Player = null

## How many times both players have passed in a row
var consecutive_passes: int = 0

## Maximum stack size (15 effects)
const MAX_STACK_SIZE: int = 15

## Last card in the stack 
var last_card = null


# ============================================================================
# REFERENCES
# ============================================================================

## Reference to battle manager
var battle_manager: BattleManager = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func initialize(manager: Node) -> void:
	battle_manager = manager
	EventBus.log_debug("QuickPlaySystem initialized", "QuickPlay")

# ============================================================================
# QUICK PLAY WINDOW
# ============================================================================

## Open quick play window
## triggering_action: description of what triggered this (e.g., "Fireball card played")
func open_window(triggering_action: String, turn_player: Player, opponent: Player) -> void:
	if is_quick_play_window_active:
		push_warning("QuickPlaySystem: window already active")
		return
	
	is_quick_play_window_active = true
	consecutive_passes = 0
	
	# Turn player gets priority first
	priority_player = turn_player
	other_player = opponent
	
	EventBus.quick_play_window_opened.emit(triggering_action)
	EventBus.log_debug("Quick Play window opened: %s" % triggering_action, "QuickPlay")
	
	# Start priority offering
	await _offer_priority()

## Close quick play window and resolve stack
func close_window() -> void:
	if not is_quick_play_window_active:
		return
	
	is_quick_play_window_active = false
	
	EventBus.quick_play_window_closed.emit()
	EventBus.log_debug("Quick Play window closed, resolving stack", "QuickPlay")
	
	# Resolve the stack (LIFO)
	await _resolve_stack()

# ============================================================================
# PRIORITY SYSTEM
# ============================================================================

## Offer priority to a player
func _offer_priority() -> void:
	if not is_quick_play_window_active:
		return
	
	EventBus.quick_play_priority_changed.emit(priority_player)
	EventBus.log_debug("%s has priority" % priority_player.get_display_name(), "QuickPlay")
	
	# Wait for player response (AI or human)
	if priority_player.is_ai:
		await _handle_ai_priority()
	else:
		# player_passes(priority_player)
		# Human player - UI will call player_plays_card or player_passes
		# We wait for those calls
		pass
	
## Handle AI priority (AI decides whether to play quick play card)
func _handle_ai_priority() -> void:
	# TODO: AI decision making for quick play
	# For now, AI always passes
	await get_tree().create_timer(0.5).timeout  # Simulate thinking
	player_passes(priority_player)

## Player plays a quick play card
func player_plays_card(card: Node, player: Node, target, caster: Node) -> void:
	if not is_quick_play_window_active:
		push_error("QuickPlaySystem: window not active")
		return
	
	if player != priority_player:
		push_error("QuickPlaySystem: player does not have priority")
		return
	
	if not card.is_quick_play() and last_card != null:
		push_error("QuickPlaySystem: card is not Quick Play")
		return
	
	# Check stack limit
	if effect_stack.size() >= MAX_STACK_SIZE:
		EventBus.show_error("Chain limit reached (%d)" % MAX_STACK_SIZE)
		return
	
	# Add to stack
	effect_stack.append({
		"card": card,
		"player": player,
		"target": target,
		"caster": caster
	})
	
	EventBus.log_debug("%s played %s (stack: %d)" % [
		player.get_display_name(),
		card.get_display_name(),
		effect_stack.size()
	], "QuickPlay")
	
	# Reset consecutive passes
	consecutive_passes = 0
	
	# update the last card on the stack
	last_card = effect_stack.back().card
	
	# Pass priority to other player
	_switch_priority()
	await _offer_priority()

## Player passes priority
func player_passes(player: Node) -> void:
	if not is_quick_play_window_active:
		return
	
	if player != priority_player:
		push_error("QuickPlaySystem: player does not have priority")
		return
	
	EventBus.player_passed_priority.emit(player)
	EventBus.log_debug("%s passed priority" % player.get_display_name(), "QuickPlay")
	
	consecutive_passes += 1
	
	# If both players passed, close window
	if consecutive_passes >= 2:
		await close_window()
		return
	
	# Pass priority to other player
	_switch_priority()
	await _offer_priority()

## Switch priority to other player
func _switch_priority() -> void:
	var temp = priority_player
	priority_player = other_player
	other_player = temp

# ============================================================================
# STACK RESOLUTION
# ============================================================================

## Resolve the effect stack (LIFO - last in, first out)
func _resolve_stack() -> void:
	if effect_stack.is_empty():
		EventBus.log_debug("Stack is empty, nothing to resolve", "QuickPlay")
		return
	
	EventBus.effect_stack_resolving.emit()
	EventBus.log_debug("Resolving stack (%d effects)" % effect_stack.size(), "QuickPlay")
	
	# Resolve in reverse order (LIFO)
	while not effect_stack.is_empty():
		var effect_data = effect_stack.pop_back()
		
		await _resolve_single_effect(effect_data)
		
		# Small delay between resolutions for visual clarity
		await get_tree().create_timer(0.3).timeout
	
	# reset variables 
	last_card = null
	consecutive_passes = 0
	priority_player = null
	other_player = null
	
	EventBus.log_debug("Stack resolution complete", "QuickPlay")

## Resolve a single effect from the stack
func _resolve_single_effect(effect_data: Dictionary) -> void:
	var card = effect_data.card
	var player = effect_data.player
	var target = effect_data.target
	var caster = effect_data.caster
	
	EventBus.log_debug("Resolving: %s" % card.get_display_name(), "QuickPlay")
	
	# Check if caster is still alive and not controlled
	if caster == null or not caster.is_alive():
		EventBus.log_debug("Caster is dead, effect negated", "QuickPlay")
		EventBus.effect_resolved.emit(effect_data)
		return
	
	if caster.is_controlled():
		EventBus.log_debug("Caster is controlled, effect negated", "QuickPlay")
		EventBus.effect_resolved.emit(effect_data)
		return
	
	# Execute card effects
	await card.play(target, battle_manager)
	
	EventBus.effect_resolved.emit(effect_data)

# ============================================================================
# QUERIES
# ============================================================================

## Check if a player can play a quick play card right now
func can_play_quick_card(player: Node, card: Node) -> bool:
	if not is_quick_play_window_active:
		return false
	
	if player != priority_player:
		return false
	
	if not card.is_quick_play():
		return false
	
	if effect_stack.size() >= MAX_STACK_SIZE:
		return false
	
	# Check if card can be played (mana, targets, etc.)
	if not card.can_play(battle_manager):
		return false
	
	return true

## Get current stack size
func get_stack_size() -> int:
	return effect_stack.size()

## Check if window is active
func is_window_active() -> bool:
	return is_quick_play_window_active

## Get player with current priority
func get_priority_player() -> Node:
	return priority_player
	
func get_last_card() -> Node:
	return last_card

# ============================================================================
# FORCED CLOSURE
# ============================================================================

## Force close window (for emergency situations)
func force_close() -> void:
	if not is_quick_play_window_active:
		return
	
	EventBus.log_debug("Force closing Quick Play window", "QuickPlay")
	
	is_quick_play_window_active = false
	effect_stack.clear()
	consecutive_passes = 0
	priority_player = null
	other_player = null
	
	EventBus.quick_play_window_closed.emit()

# ============================================================================
# DEBUG
# ============================================================================

## Get debug info
func get_debug_info() -> String:
	return "Active: %s | Stack: %d | Priority: %s" % [
		is_quick_play_window_active,
		effect_stack.size(),
		priority_player.get_display_name() if priority_player else "None"
	]

## Print stack contents
func print_stack() -> void:
	print("=== Quick Play Stack ===")
	for i in range(effect_stack.size() - 1, -1, -1):  # Print in resolution order
		var effect = effect_stack[i]
		var card = effect.card
		print("%d. %s" % [effect_stack.size() - i, card.get_display_name()])
	print("========================")
