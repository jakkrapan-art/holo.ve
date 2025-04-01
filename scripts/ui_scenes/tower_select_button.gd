extends Button
class_name TowerSelectButton

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("tower_buttons")  # Ensures buttons register correctly

func setup(sprite):
	#sprite should be sprite path
	self.text = sprite #prototype
#func setup(spritepath: String):
	#var texture = load(spritepath)
	#if texture:
		#self.icon = texture  # Assuming this is a TextureButton
