extends Node
## EventBus - Global event system for decoupled communication
## This is an autoload singleton that all game systems use to communicate

# ============================================================================
# TURN SYSTEM SIGNALS
# ============================================================================

## Emitted when a unit's turn begins (before START phase)
signal turn_started(unit: Node)

## Emitted when turn phase changes (START -> MAIN -> END)
signal turn_phase_changed(phase: int, unit: Node)

## Emitted when a unit's turn completely ends
signal turn_ended(unit: Node)

## Emitted when turn order queue is recalculated
signal turn_order_updated(turn_queue: Array)

# ============================================================================
# CARD & ACTION SIGNALS
# ============================================================================

## Emitted when a card is successfully played
## target can be Unit, Array[Unit], or null depending on card
signal card_played(card: Node, player: Node, target)

## Emitted when a card is drawn from deck to hand
signal card_drawn(card: Node, player: Node)

## Emitted when a card is discarded from hand
signal card_discarded(card: Node, player: Node)

## Emitted when basic attack is used
signal basic_attack_used(attacker: Node, target: Node)

## Emitted when ultimate is used
signal ultimate_used(caster: Node, target)

# ============================================================================
# RESOURCE SIGNALS
# ============================================================================

## Emitted when player's mana changes
signal mana_changed(player: Node, new_amount: int, old_amount: int)

## Emitted when mana is spent
signal mana_spent(player: Node, amount: int)

## Emitted when mana is gained
signal mana_added(player: Node, anount: int)

# ============================================================================
# COMBAT SIGNALS
# ============================================================================

## Emitted when damage is calculated (before applying)
signal damage_calculated(source: Node, target: Node, amount: int, is_crit: bool)

## Emitted when damage is actually dealt (after applying)
signal damage_dealt(source: Node, target: Node, final_amount: int, is_true_damage: bool)

## Emitted when a unit is healed
signal unit_healed(target: Node, amount: int, source: Node)

## Emitted when a unit dies
signal unit_died(unit: Node)

## Emitted when a unit is revived (for future expansion)
signal unit_revived(unit: Node)

# ============================================================================
# STATUS EFFECT SIGNALS
# ============================================================================

## Emitted when a status effect is applied to a unit
signal status_effect_applied(target: Node, effect: Resource)

## Emitted when a status effect is removed from a unit
signal status_effect_removed(target: Node, effect: Resource)

## Emitted when a status effect ticks (at turn start/end)
signal status_effect_ticked(target: Node, effect: Resource)

## Emitted when status effects are cleansed (debuffs removed)
signal debuffs_cleansed(target: Node, count: int)

## Emitted when buffs are dispelled
signal buffs_dispelled(target: Node, count: int)

# ============================================================================
# ACTION READINESS (AR) SIGNALS
# ============================================================================

## Emitted when a unit's AR changes
signal ar_changed(unit: Node, new_value: float, old_value: float)

## Emitted when AR is pushed (increased)
signal ar_pushed(unit: Node, amount: float)

## Emitted when AR is pulled (decreased)
signal ar_pulled(unit: Node, amount: float)

# ============================================================================
# QUICK PLAY SIGNALS
# ============================================================================

## Emitted when quick play window opens (waiting for responses)
signal quick_play_window_opened(triggering_action: String)

## Emitted when quick play window closes (chain resolving)
signal quick_play_window_closed()

## Emitted when a player gains priority in quick play window
signal quick_play_priority_changed(player: Node)

## Emitted when a player passes priority
signal player_passed_priority(player: Node)

## Emitted when the effect stack starts resolving
signal effect_stack_resolving()

## Emitted when each effect in stack resolves
signal effect_resolved(effect_data: Dictionary)

# ============================================================================
# BATTLE FLOW SIGNALS
# ============================================================================

## Emitted when battle initialization completes
signal battle_initialized()

## Emitted when battle actually starts (after init)
signal battle_started()

## Emitted when battle ends
signal battle_ended(winner: Node)

## Emitted when a phase transition occurs (not turn-specific)
signal game_phase_changed(new_phase: String)

# ============================================================================
# TARGETING SIGNALS
# ============================================================================

## Emitted when targeting mode is activated
signal targeting_started(card: Node, valid_targets: Array)

## Emitted when a target is selected
signal target_selected(target: Node)

## Emitted when targeting is cancelled
signal targeting_cancelled()

# ============================================================================
# PASSIVE TRIGGER SIGNALS
# ============================================================================

## Emitted when a passive ability triggers
signal passive_triggered(unit: Node, passive_name: String, data: Dictionary)

## Emitted when a passive is suppressed/ignored
signal passive_suppressed(unit: Node, passive_name: String)

# ============================================================================
# CONTROL EFFECT SIGNALS
# ============================================================================

## Emitted when a unit becomes controlled
signal unit_controlled(unit: Node, control_type: String)

## Emitted when a unit is freed from control
signal unit_uncontrolled(unit: Node)

## Emitted when a taunt is applied
signal unit_taunted(taunted_unit: Node, taunter: Node)

# ============================================================================
# UI SIGNALS
# ============================================================================

## Emitted when UI needs to update displays
signal ui_refresh_requested()

## Emitted when an error message should be shown
signal show_error_message(message: String)

## Emitted when a notification should be shown
signal show_notification(message: String, type: String)

# ============================================================================
# DEBUG SIGNALS
# ============================================================================

## Emitted for debug logging
signal debug_log(message: String, category: String)


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Convenience function to emit debug logs
func log_debug(message: String, category: String = "General") -> void:
	debug_log.emit(message, category)
	print("[%s] %s" % [category, message])

## Convenience function to show error to player
func show_error(message: String) -> void:
	show_error_message.emit(message)
	push_error(message)

## Convenience function to show notification to player
func notify(message: String, type: String = "info") -> void:
	show_notification.emit(message, type)
