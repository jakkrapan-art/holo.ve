extends Button

func _ready():
	# IMPORTANT: Allow this button to work while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect the button's pressed signal to our function
	pressed.connect(_on_pressed)

func _on_pressed():
	# Toggle pause state
	get_tree().paused = !get_tree().paused

	# Optional: Update button text to show current state
	if get_tree().paused:
		text = "Resume"
	else:
		text = "Pause"
