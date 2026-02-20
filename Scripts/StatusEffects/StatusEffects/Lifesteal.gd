extends StatusEffect
class_name Lifesteal
## Lifesteal - Heal for a percentage of damage dealt

# ============================================================================
# INITIALIZATION
# ============================================================================

## Percentage of damage healed (e.g., 0.3 = 30% lifesteal)
var lifesteal_percent: float = 0.3

func _init(percent: float = 0.3, turns: int = 3) -> void:
	effect_name = "Lifesteal"
	description = "Heal for %.0f%% of damage dealt" % (percent * 100)
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns
	lifesteal_percent = percent
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true
	stack_type = Enums.StackType.STACK_COUNT
	max_stacks = 3  # Can stack for more lifesteal

# ============================================================================
# APPLICATION
# ============================================================================

func on_apply() -> void:
	if target_unit == null:
		return
	
	# Connect to damage dealt signal
	if not EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.connect(_on_damage_dealt)
	
	EventBus.log_debug("%s gained Lifesteal (%.0f%%)" % [target_unit.name, lifesteal_percent * 100 * stack_count], "StatusEffect")

func on_remove() -> void:
	# Disconnect signal
	if EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.disconnect(_on_damage_dealt)

# ============================================================================
# LIFESTEAL TRIGGER
# ============================================================================

## Called when any damage is dealt
func _on_damage_dealt(source: Node, target: Node, amount: int, is_true: bool) -> void:
	# Check if our unit dealt the damage
	if source != target_unit:
		return
	
	if amount <= 0:
		return
	
	# Calculate lifesteal healing
	var total_lifesteal = lifesteal_percent * stack_count
	var heal_amount = int(amount * total_lifesteal)
	
	if heal_amount > 0:
		source.heal(heal_amount, source)
		EventBus.log_debug("%s lifestealed %d HP" % [source.name, heal_amount], "StatusEffect")
