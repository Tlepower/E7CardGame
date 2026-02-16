extends CardEffect
class_name DeathPreventionEffect
## DeathPreventionEffect - Grants death prevention to target
## When target would die, they survive with 1 HP and lose death prevention

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init() -> void:
	effect_name = "Death Prevention"
	description = "Grant death prevention - survive fatal damage once at 1 HP"
	target_type = Enums.TargetType.SINGLE_ALLY

# ============================================================================
# EXECUTION
# ============================================================================

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if not target.is_alive():
		return
	
	# Grant death prevention
	target.grant_death_prevention()
	
	EventBus.log_debug("%s granted death prevention to %s" % [caster.name, target.name], "DeathPreventionEffect")

# ============================================================================
# DESCRIPTION
# ============================================================================

func get_description() -> String:
	return "Grant death prevention - survive one fatal hit with 1 HP"
