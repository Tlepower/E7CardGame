extends CardEffect
class_name ResetPassiveCooldownEffect
## ResetPassiveCooldownEffect - Resets the Demon King's passive cooldown

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Reset Passive"
	description = "Reset Immortal Sovereign cooldown"
	target_type = Enums.TargetType.SELF

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if caster == null or caster.passive == null:
		return
	
	# Check if this is the Demon King passive
	if caster.passive.passive_name == "Immortal Sovereign":
		# Reset the turn counter to cooldown (grants death prevention immediately next turn)
		if caster.passive.has_method("set"):
			caster.passive.turn_counter = caster.passive.DEATH_PREVENTION_COOLDOWN
			
			EventBus.log_debug("%s reset Immortal Sovereign cooldown!" % caster.name, "ResetPassiveCooldownEffect")
			
			# Grant death prevention immediately if they don't have it
			if not caster.get_death_prevention():
				caster.grant_death_prevention()
				EventBus.log_debug("%s gained immediate death prevention from reset!" % caster.name, "ResetPassiveCooldownEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	return "Reset Immortal Sovereign - gain death prevention immediately"
