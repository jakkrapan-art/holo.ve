class_name Inventory
extends RefCounted

var items: Array[InventoryItem] = []

func addItem(item: InventoryItem) -> void:
	for existing in items:
		if existing.id == item.id:
			var space_left = existing.maxStack - existing.stack
			if space_left > 0:
				var to_add = min(space_left, item.stack)
				existing.stack += to_add
				item.stack -= to_add
				if item.stack <= 0:
					return
	# If there's still leftover stack, add as new slot
	if item.stack > 0:
		items.append(item)


func removeItem(item: InventoryItem) -> void:
	for existing in items:
		if existing.id == item.id:
			if existing.stack > item.stack:
				existing.stack -= item.stack
				return
			elif existing.stack == item.stack:
				items.erase(existing)
				return
			else:
				# If removing more than available, remove it entirely
				item.stack -= existing.stack
				items.erase(existing)
				# Continue removing from other stacks if multiple
				if item.stack > 0:
					removeItem(item)
				return


func getItem(id: int) -> InventoryItem:
	for item in items:
		if item.id == id:
			return item
	return null


func getItemAmount(id: int) -> int:
	var total := 0
	for item in items:
		if item.id == id:
			total += item.stack
	return total