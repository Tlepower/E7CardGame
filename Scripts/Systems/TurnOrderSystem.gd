extends Node
class_name TurnOrderSystem
## TurnOrderSystem - Manages turn order based on Action Readiness (AR)
## Simulates AR ticks forward until a unit reaches 100%
## If multiple units at 100%, highest AR goes first

# ============================================================================
# UNITS TRACKING
# ============================================================================

## All units in battle (both teams)
var all_units: Array[Node] = []  # Array[Unit]

## Turn order queue (sorted by AR, updated frequently)
var turn_queue: Array[Node] = []  # Array[Unit]

# ============================================================================
# INITIALIZATION
# ============================================================================

## Initialize turn order system with all units
func initialize(player_units: Array[Node], enemy_units: Array[Node]) -> void:
	all_units.clear()
	turn_queue.clear()
	
	# Combine all units
	for unit in player_units:
		if unit != null:
			all_units.append(unit)
	
	for unit in enemy_units:
		if unit != null:
			all_units.append(unit)
	
	# Set initial AR (randomize or set to 0)
	_initialize_starting_ar()
	
	# Calculate initial turn order
	recalculate_queue()
	
	EventBus.log_debug("TurnOrderSystem initialized with %d units" % all_units.size(), "TurnOrder")

## Set starting AR for all units
func _initialize_starting_ar() -> void:
	# Give units random starting AR (0-5%) for variety
	for unit in all_units:
		var starting_ar = randf_range(0.0, 5.0)
		unit.set_ar(starting_ar)
	
	EventBus.log_debug("Starting AR randomized for all units", "TurnOrder")

# ============================================================================
# TURN CALCULATION
# ============================================================================

## Calculate which unit goes next
## Simulates AR ticks until a unit reaches 100%
## Returns the unit that should take the next turn
func calculate_next_turn() -> Node:
	# Check if any unit already at or above 100%
	var ready_units = _get_ready_units()
	
	if not ready_units.is_empty():
		# Sort by AR (highest first)
		ready_units.sort_custom(func(a, b): return a.action_readiness > b.action_readiness)
		return ready_units[0]
	
	# No unit ready, simulate AR ticks until someone reaches 100%
	var next_unit = _simulate_ar_until_ready()
	
	# Recalculate queue
	recalculate_queue()
	
	return next_unit

## Get all units that are ready (AR >= 100%)
func _get_ready_units() -> Array[Node]:
	var ready: Array[Node] = []
	
	for unit in all_units:
		if unit.is_alive() and unit.is_ready_for_turn():
			ready.append(unit)
	
	return ready

## Simulate AR ticks forward until a unit reaches 100%
func _simulate_ar_until_ready() -> Node:
	var max_iterations = 1000  # Safety limit
	var iterations = 0
	
	while iterations < max_iterations:
		# Calculate AR gain per tick for each unit
		# AR gain = (unit_speed / 0.1) * 100
		# This ensures that AR gained is not effected by who is alive
		
		var tick_size = 0.1
		
		# Tick all units
		for unit in all_units:
			if not unit.is_alive():
				continue
			
			var speed = unit.get_effective_stat(Enums.StatType.SPEED)
			var ar_gain = speed * tick_size
			unit.modify_ar(ar_gain)
		
		# Check if any unit is ready
		var ready_units = _get_ready_units()
		if not ready_units.is_empty():
			# Sort by AR (highest first) in case multiple reached 100%
			ready_units.sort_custom(func(a, b): return a.action_readiness > b.action_readiness)
			return ready_units[0]
		
		iterations += 1
	
	push_error("TurnOrderSystem: max iterations reached in AR simulation")
	return null

## Get highest speed among all alive units
func _get_highest_speed() -> float:
	var max_speed = 0.0
	
	for unit in all_units:
		if not unit.is_alive():
			continue
		
		var speed = unit.get_effective_stat(Enums.StatType.SPEED)
		if speed > max_speed:
			max_speed = speed
	
	return max_speed

# ============================================================================
# TURN QUEUE MANAGEMENT
# ============================================================================

## Recalculate turn order queue
## Shows preview of next N units to take turns
func recalculate_queue(preview_count: int = 10) -> void:
	turn_queue.clear()
	
	# Create a snapshot of current AR state
	var ar_snapshot = _create_ar_snapshot()
	
	# Simulate turns to build queue
	for i in preview_count:
		var next_unit = _simulate_next_turn_in_snapshot(ar_snapshot)
		if next_unit != null:
			turn_queue.append(next_unit)
			# Reset that unit's AR in snapshot
			ar_snapshot[next_unit] = 0.0
		else:
			break
	
	EventBus.turn_order_updated.emit(turn_queue)

## Create snapshot of current AR values
func _create_ar_snapshot() -> Dictionary:
	var snapshot = {}
	
	for unit in all_units:
		if unit.is_alive():
			snapshot[unit] = unit.action_readiness
	
	return snapshot

## Simulate next turn using AR snapshot (doesn't modify actual units)
func _simulate_next_turn_in_snapshot(ar_snapshot: Dictionary) -> Node:
	# Check if any unit already at 100%
	var ready_units: Array[Node] = []
	
	for unit in ar_snapshot.keys():
		if ar_snapshot[unit] >= 100.0:
			ready_units.append(unit)
	
	if not ready_units.is_empty():
		ready_units.sort_custom(func(a, b): return ar_snapshot[a] > ar_snapshot[b])
		return ready_units[0]
	
	# Simulate AR ticks
	var max_iterations = 1000
	var iterations = 0
	
	while iterations < max_iterations:
		# var fastest_speed = _get_highest_speed_from_snapshot(ar_snapshot)
		# if fastest_speed <= 0:
			# return null
		
		var tick_size = 0.1
		
		# Tick all units in snapshot
		for unit in ar_snapshot.keys():
			var speed = unit.get_effective_stat(Enums.StatType.SPEED)
			var ar_gain = speed * tick_size
			ar_snapshot[unit] += ar_gain
		
		# Check for ready units
		ready_units.clear()
		for unit in ar_snapshot.keys():
			if ar_snapshot[unit] >= 100.0:
				ready_units.append(unit)
		
		if not ready_units.is_empty():
			ready_units.sort_custom(func(a, b): return ar_snapshot[a] > ar_snapshot[b])
			return ready_units[0]
		
		iterations += 1
	
	return null

## Get highest speed from snapshot units
func _get_highest_speed_from_snapshot(ar_snapshot: Dictionary) -> float:
	var max_speed = 0.0
	
	for unit in ar_snapshot.keys():
		var speed = unit.get_effective_stat(Enums.StatType.SPEED)
		if speed > max_speed:
			max_speed = speed
	
	return max_speed

# ============================================================================
# AR MANIPULATION
# ============================================================================

## Push unit's AR (increase)
func push_ar(unit: Node, amount: float) -> void:
	if unit == null or not unit.is_alive():
		return
	
	unit.modify_ar(amount)
	recalculate_queue()

## Pull unit's AR (decrease)
func pull_ar(unit: Node, amount: float) -> void:
	if unit == null or not unit.is_alive():
		return
	
	unit.modify_ar(-amount)
	recalculate_queue()

## Set unit's AR directly
func set_ar(unit: Node, value: float) -> void:
	if unit == null or not unit.is_alive():
		return
	
	unit.set_ar(value)
	recalculate_queue()

func gain_turn(unit: Node) -> void:
	var snapshot = _create_ar_snapshot()
	var highest_ar = 0.0
	for uni in snapshot:
		if highest_ar <= snapshot[uni]:
			highest_ar = snapshot[uni]
	
	set_ar(unit,max(100.0, highest_ar + 1))

# ============================================================================
# UNIT MANAGEMENT
# ============================================================================

## Remove a unit from turn order (when it dies)
func remove_unit(unit: Node) -> void:
	if unit == null:
		return
	
	all_units.erase(unit)
	turn_queue.erase(unit)
	
	recalculate_queue()
	
	EventBus.log_debug("Unit '%s' removed from turn order" % unit.name, "TurnOrder")

## Add a unit to turn order (for summons, etc.)
func add_unit(unit: Node, starting_ar: float = 0.0) -> void:
	if unit == null or unit in all_units:
		return
	
	all_units.append(unit)
	unit.set_ar(starting_ar)
	
	recalculate_queue()
	
	EventBus.log_debug("Unit '%s' added to turn order" % unit.name, "TurnOrder")

# ============================================================================
# QUERIES
# ============================================================================

## Get turn order preview (next N units)
func get_turn_order_preview(count: int = 10) -> Array[Node]:
	if turn_queue.size() < count:
		recalculate_queue(count)
	
	return turn_queue.slice(0, mini(count, turn_queue.size()))

## Get position of a unit in turn queue
func get_unit_turn_position(unit: Node) -> int:
	if turn_queue.is_empty():
		recalculate_queue()
	
	return turn_queue.find(unit)

## Get all units sorted by AR (highest first)
func get_units_by_ar() -> Array[Node]:
	var sorted_units = all_units.duplicate()
	sorted_units.sort_custom(func(a, b): return a.action_readiness > b.action_readiness)
	return sorted_units

# ============================================================================
# DEBUG
# ============================================================================

## Print turn order for debugging
func print_turn_order() -> void:
	print("=== Turn Order ===")
	var preview = get_turn_order_preview(10)
	for i in preview.size():
		var unit = preview[i]
		print("%d. %s (AR: %.1f, Speed: %d)" % [
			i + 1,
			unit.name,
			unit.action_readiness,
			unit.get_effective_stat(Enums.StatType.SPEED)
		])
	print("==================")

## Get debug info
func get_debug_info() -> String:
	return "Units: %d | Queue: %d" % [all_units.size(), turn_queue.size()]
