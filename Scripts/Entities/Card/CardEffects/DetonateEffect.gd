extends CardEffect
class_name DetonateEffect
## Detonate Dots that have detonation effect

var burn = Burn.new()
var DetonateDot = burn

func _init() -> void:
	effect_name = "Detonate"
	description = "Detonate Dots that have detonation effects"
	target_type = Enums.TargetType.SINGLE_ENEMY

# Execute effect

func execute_on_single_target(caster: Node, target: Node, game_state: Node) -> void:
	if target == null or not target.is_alive():
		return
	
	# Get the effect
	if not target.has_status_effect(DetonateDot):
		return
	
	# Just changing name
	var effect = DetonateDot
	
	# detonate the effect
	target.detonate_status_effects(effect)
	
	EventBus.emit.status_effect_detonated(target,effect)
	EventBus.log_debug("%s detonated %s on %s" % [caster,effect.effect_name,target], "DetonateEffect")

func get_description() -> String:
	var effect = DetonateDot
	return "Detonate the %s effect" % [effect.effect_nam]
