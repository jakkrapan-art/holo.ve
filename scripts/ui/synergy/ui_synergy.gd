extends Control
class_name UISynergy

const ROW_HEIGHT := 100

@export var contentTemplate: PackedScene;

var contentList: Dictionary = {};   # synergy name -> UISynergyContent
var _nextOrder := 0;                 # creation order, frozen per row (stable-sort tie-break)

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
		content.setOrder(_nextOrder)   # frozen once at creation; never rewritten
		_nextOrder += 1
	content.setup(synergyName, count, tier, ResourceManager.getSynergyData(synergy_id))
	_reflow()

# Re-order rows on every update: tier desc, then count desc, then creation order.
# Active rows (tier >= 0) float above inactive (tier -1) because -1 sorts lowest.
# sort_custom is NOT stable, so creation order is the final key to keep rows with
# equal tier+count from swapping (and flickering) each reflow.
func _reflow() -> void:
	var rows: Array = contentList.values()
	rows.sort_custom(_compare_rows)
	for i in rows.size():
		rows[i].position.y = i * ROW_HEIGHT

func _compare_rows(a: UISynergyContent, b: UISynergyContent) -> bool:
	if a.getTier() != b.getTier():
		return a.getTier() > b.getTier()
	if a.getCount() != b.getCount():
		return a.getCount() > b.getCount()
	return a.getOrder() < b.getOrder()
