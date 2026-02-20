extends StatusEffect
class_name Stealth
## Stealth - Unit cannot be targeted (removed when taking damage)

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(turns: int = 99) -> void:
	effect_name = "Stealth"
	description = "Cannot be targeted (removed on damage)"
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns  # Effectively permanent until hit
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = false  # Doesn't decrease by time
	stack_type = Enums.StackType.NO_STACK
	is_permanent = true  # Only removed by damage or dispel

# ============================================================================
# APPLICATION
# ============================================================================

func on_apply() -> void:
	if target_unit == null:
		return
	
	EventBus.log_debug("%s entered stealth!" % target_unit.name, "StatusEffect")
	
	# Connect to damage signal to remove stealth on hit
	if not EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.connect(_on_damage_dealt)

func on_remove() -> void:
	if target_unit == null:
		return
	
	EventBus.log_debug("%s stealth broken!" % target_unit.name, "StatusEffect")
	
	# Disconnect signal
	if EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.disconnect(_on_damage_dealt)

# ============================================================================
# STEALTH BREAKING
# ============================================================================

## Called when any damage is dealt
func _on_damage_dealt(source: Node, target: Node, amount: int, is_true: bool) -> void:
	# Check if our stealthed unit took damage
	if target == target_unit and amount > 0:
		# Break stealth
		EventBus.log_debug("%s took damage, stealth broken!" % target_unit.name, "StatusEffect")
		duration = 0  # Force expiration
