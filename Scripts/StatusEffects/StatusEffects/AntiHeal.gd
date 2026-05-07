extends StatusEffect
class_name AntiHead

# Called when the node enters the scene tree for the first time.
func _init(turns: int = 2) -> void:
	effect_name = "AntiHeal"
	description = "Cannot be healed"
	effect_type = Enums.StatusEffectType.AntiHeal
	base_duration = turns
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.NO_STACK
