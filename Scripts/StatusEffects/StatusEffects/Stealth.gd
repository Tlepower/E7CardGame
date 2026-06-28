extends StatusEffect
class_name Stealth
## Stealth - Unit cannot be targeted (removed when taking damage)

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(turns: int = 2) -> void:
	effect_name = "Stealth"
	description = "Cannot be targeted (removed on damage)"
	effect_type = Enums.StatusEffectType.BUFF
	base_duration = turns 
	
	can_be_dispelled = true
	ticks_on_turn_start = true
	duration_decreases_on_start = true 
	stack_type = Enums.StackType.NO_STACK  

# ============================================================================
# APPLICATION
# ============================================================================

func on_apply() -> void:
	if target_unit == null:
		return
		
	if _is_last_one_standing():
		target_unit.remove_status_effect(self)
		return
	
	EventBus.log_debug("%s entered stealth!" % target_unit.name, "StatusEffect")
	
	# Connect to damage signal to remove stealth on hit
	if not EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.connect(_on_damage_dealt)
	if not EventBus.unit_died.is_connected(_on_unit_died):
		EventBus.unit_died.connect(_on_unit_died)

func on_remove() -> void:
	if target_unit == null:
		return
	
	EventBus.log_debug("%s stealth broken!" % target_unit.name, "StatusEffect")
	
	# Disconnect signal
	if EventBus.damage_dealt.is_connected(_on_damage_dealt):
		EventBus.damage_dealt.disconnect(_on_damage_dealt)
	if not EventBus.unit_died.is_connected(_on_unit_died):
		EventBus.unit_died.disconnect(_on_unit_died)

# ============================================================================
# STEALTH BREAKING
# ============================================================================

## Called when any damage is dealt
func _on_damage_dealt(source: Node, target: Node, amount: int, is_true: bool) -> void:
	# Check if our stealthed unit took damage
	if target == target_unit and amount > 0:
		# Break stealth
		EventBus.log_debug("%s took damage, stealth broken!" % target_unit.name, "StatusEffect")
		target.remove_status_effect(self)
		
## Called when a unit dieds
func _on_unit_died(target: Node) -> void:
	if _is_last_one_standing() and target != target_unit:
		EventBus.log_debug("%s losses stealth because %s is the last unit alive", "Stealth")
		target_unit.remove_status_effect(self)

## Helper function that asks if the target is the last unit alive on the team
func _is_last_one_standing() -> bool:
	if not target_unit.is_alive() or target_unit == null:
		return false
	
	var player = target_unit.battle_manager.get_player_by_team(target_unit.team)
	var alive_units = player.get_alive_units()
	if alive_units.size() == 1:
		return true
	
	return false
