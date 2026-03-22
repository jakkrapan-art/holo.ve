extends Button
class_name TowerSelectButton

var towerNameText: Label;
var evolutionNode: Node;
var evolutionCostText: Label;
var towerPortrait: TextureRect;

func _ready():
	add_to_group("tower_buttons")  # Ensures buttons register correctly

func setup(name: String, sprite, level: int, evolutionCost: int):
	print("name:", name, ", sprite:", sprite, ", level:", level, ", evolutionCost:", evolutionCost);
	if(!towerNameText):
		towerNameText = $TowerName

	if (!evolutionCostText):
		evolutionCostText = $Evolution/EvolutionCost

	if (!evolutionNode):
		evolutionNode = $Evolution

	if (!towerPortrait):
		towerPortrait = $TowerPortrait

	towerNameText.text = name + ("\nLevel " + str(level) if level > 0 else "")
	evolutionNode.visible = evolutionCost > 0
	evolutionCostText.text = " " + str(evolutionCost)
	var portrait = TowerCenter.getTowerPortraitByName(name.to_lower());
	if(portrait):
		towerPortrait.texture = portrait
