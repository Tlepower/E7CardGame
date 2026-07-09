extends Node

signal player_chose(event: InputEvent)

func _ready() -> void:
	# Step 1: do something
	print("A wild choice appears! Press 1 to fight, 2 to flee.")

	# Step 2: wait for input (pauses this function until the signal fires)
	var event: InputEvent = await player_chose

	# Step 3: do something else based on that input
	react_to_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		player_chose.emit(event)


func react_to_input(event: InputEvent) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_1:
				print("You chose to FIGHT!")
			KEY_2:
				print("You chose to FLEE!")
			_:
				print("Unrecognized choice.")
