extends Button
class_name TowerSelectButton

var towerNameText: Label;
var evolutionNode: Node;
var evolutionCostText: Label;

func _ready():
	add_to_group("tower_buttons")  # Ensures buttons register correctly

func setup(name: String, sprite, level: int, evolutionCost: int):
	if(!towerNameText):
		towerNameText = $TowerName

	if (!evolutionCostText):
		evolutionCostText = $Evolution/EvolutionCost

	if (!evolutionNode):
		evolutionNode = $Evolution

	towerNameText.text = name + ("\nLevel " + str(level) if level > 0 else "")
	evolutionNode.visible = evolutionCost > 0
	evolutionCostText.text = " " + str(evolutionCost)
	#sprite should be sprite path
	#self.text = sprite #prototype
#func setup(spritepath: String):
	#var texture = load(spritepath)
	#if texture:
		#self.icon = texture  # Assuming this is a TextureButton
