extends Control
class_name DamageNumber

var textLabel: Label

var lifetime: float = 1.5
var elapsed_time: float = 0.0
var move_speed: float = 50.0  # Pixels per second upward movement

func _ready():
	# Make sure the control doesn't interfere with input
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta):
	elapsed_time += delta

	# Check if lifetime has expired
	if elapsed_time >= lifetime:
		queue_free()
		return

	# Calculate alpha for fade out effect
	var fade_progress = elapsed_time / lifetime
	var alpha = 1.0 - fade_progress

	if textLabel:
		# Apply fade effect
		textLabel.modulate.a = alpha

		# Move upward
		textLabel.position.y -= move_speed * delta

func setup(damage: int):
	textLabel = $Text as Label
	if textLabel:
		# Format number with commas (000,000,000 format)
		textLabel.text = format_number(damage)
		textLabel.show()

		# Reset properties
		textLabel.modulate.a = 1.0
		textLabel.position = Vector2.ZERO

	# Reset timer
	elapsed_time = 0.0

func format_number(number: int) -> String:
	var str_number = str(abs(number))  # Get absolute value and convert to string
	var formatted = ""
	var length = str_number.length()

	# Add commas every 3 digits from right to left
	for i in range(length):
		if i > 0 and (length - i) % 3 == 0:
			formatted += ","
		formatted += str_number[i]

	# Add negative sign if original number was negative
	if number < 0:
		formatted = "-" + formatted

	return formatted

# Optional: Set custom lifetime
func set_lifetime(new_lifetime: float):
	lifetime = new_lifetime

# Optional: Set custom move speed
func set_move_speed(speed: float):
	move_speed = speed

# Optional: Set custom color
func set_color(color: Color):
	if textLabel:
		textLabel.modulate = color