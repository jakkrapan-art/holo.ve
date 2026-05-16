class_name TowerBuffContainer
extends RefCounted

var _buffs: Dictionary = {}

signal buff_added(buff: BuffInstance)
signal buff_removed(buff: BuffInstance)

func add(buff: BuffInstance) -> bool:
	if buff == null or buff.id == "":
		return false

	if _buffs.has(buff.id):
		match buff.stackPolicy:
			BuffInstance.StackPolicy.IGNORE_IF_PRESENT:
				return false
			BuffInstance.StackPolicy.REFRESH:
				var existing: BuffInstance = _buffs[buff.id]
				existing.appliedAt = Time.get_ticks_msec() / 1000.0
				return true
			BuffInstance.StackPolicy.STACK:
				pass

	buff.appliedAt = Time.get_ticks_msec() / 1000.0
	_buffs[buff.id] = buff
	buff_added.emit(buff)
	return true

func remove(id: String) -> void:
	if not _buffs.has(id):
		return
	var buff: BuffInstance = _buffs[id]
	_buffs.erase(id)
	buff_removed.emit(buff)

func has(id: String) -> bool:
	return _buffs.has(id)

func get_all() -> Array:
	return _buffs.values()

func aggregate(statType: int) -> float:
	var total := 0.0
	for buff: BuffInstance in _buffs.values():
		if buff.statType == statType:
			total += buff.value
	return total

func clear() -> void:
	var buffs := _buffs.values()
	_buffs.clear()
	for buff: BuffInstance in buffs:
		buff_removed.emit(buff)

func clear_skill_buffs() -> void:
	for id in _buffs.keys().duplicate():
		var buff: BuffInstance = _buffs[id]
		if buff.sourceSkill != "":
			_buffs.erase(id)
			buff_removed.emit(buff)
