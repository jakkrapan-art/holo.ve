extends Button
class_name TowerSelectButton

var towerNameText: Label;
var evolutionNode: Node;
var evolutionCostText: Label;
var towerPortrait: TextureRect;

var towerClassImage: SynergyChipIcon;
var towerGenImage: SynergyChipIcon;
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
	# Display names stay player-facing and may contain spaces ("Spell Caster");
	# the sprite key is normalised by ResourceManager, never by the caller.
	var classDisplayName = TowerTrait.TOWER_CLASS_NAMES.get(towerClass, "default");
	var genDisplayName = TowerTrait.TOWER_GENERATION_NAMES.get(towerGen, "default");
	var classSprite = ResourceManager.getSynergySprite(classDisplayName);
	var genSprite = ResourceManager.getSynergySprite(genDisplayName);
	if(towerClassImage):
		towerClassImage.texture = classSprite
		towerClassImage.set_synergy(towerClass, classDisplayName)

	if(towerGenImage):
		towerGenImage.texture = genSprite
		towerGenImage.set_synergy(towerGen, genDisplayName)
