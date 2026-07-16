extends Button
class_name TowerSelectButton

var towerNameText: Label;
var evolutionNode: Node;
var evolutionCostText: Label;
var towerPortrait: TextureRect;

var towerClassImage: TextureRect;
var towerGenImage: TextureRect;
var synergiesNode: Control;

func _ready():
	add_to_group("tower_buttons")  # Ensures buttons register correctly

func Setup(p_name: String, sprite, towerClass: TowerTrait.TowerClass, towerGen: TowerTrait.TowerGeneration, level: int, evolutionCost: int):
	towerNameText = $TowerName
	evolutionCostText = $Evolution/EvolutionCost
	evolutionNode = $Evolution
	towerPortrait = $TowerPortrait
	towerClassImage = $Synergies/Class
	towerGenImage = $Synergies/Gen
	synergiesNode = $Synergies

	towerNameText.text = p_name + ("\nLevel " + str(level) if level > 0 else "")
	evolutionNode.visible = evolutionCost > 0
	evolutionCostText.text = " " + str(evolutionCost)
	if sprite != null:
		towerPortrait.texture = sprite
	else:
		var portrait = TowerCenter.getTowerPortraitByName(p_name.to_lower());
		if(portrait):
			towerPortrait.texture = portrait
	# No real trait on either slot (deck-add popup cards) -> no synergy chip bar.
	synergiesNode.visible = TowerTrait.TOWER_CLASS_NAMES.has(towerClass) or TowerTrait.TOWER_GENERATION_NAMES.has(towerGen)
	if !synergiesNode.visible:
		return
	var tClassName = TowerTrait.TOWER_CLASS_NAMES.get(towerClass, "default").to_lower();
	var classSprite = ResourceManager.getSprite("synergy", tClassName);
	if(classSprite == null):
		classSprite = ResourceManager.getSprite("synergy", "default");
	var genSprite = ResourceManager.getSprite("synergy", TowerTrait.TOWER_GENERATION_NAMES.get(towerGen, "default").to_lower());
	if(genSprite == null):
		genSprite = ResourceManager.getSprite("synergy", "default");
	if(towerClassImage):
		towerClassImage.texture = classSprite

	if(towerGenImage):
		towerGenImage.texture = genSprite
