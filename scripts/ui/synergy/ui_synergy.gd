extends Control
class_name UISynergy

@export var contentTemplate: PackedScene;

var contentList: Dictionary = {};   # synergy name -> UISynergyContent
var currentYPos := 0;

# Create or update a synergy row from the single TowerTrait.synergy_updated signal:
# count + tier drive the row (count, proc breakpoints, tier colour); synergy_id
# resolves the SynergyData for the rich hover. Numbers come from SynergyData
# parameters so the hover text cannot drift from the applied effect.
func updateSynergy(synergyName: String, count: int, tier: int, synergy_id: int) -> void:
	var content: UISynergyContent = contentList.get(synergyName, null)
	if content == null:
		content = contentTemplate.instantiate() as UISynergyContent
		contentList[synergyName] = content
		add_child(content)
		content.position.y = currentYPos
		currentYPos += 100
	content.setup(synergyName, count, tier, ResourceManager.getSynergyData(synergy_id))
