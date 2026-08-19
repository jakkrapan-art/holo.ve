class_name EnemyRosterValidator

const ENEMY_DATABASE_ROOT := "res://resources/database/enemy/"
const TIERS := ["normal", "elite", "boss"]

static var _has_run: bool = false


static func warn_duplicate_ids_once() -> void:
	if _has_run:
		return
	_has_run = true

	var owners_by_id: Dictionary = {}
	var map_names := DirAccess.get_directories_at(ENEMY_DATABASE_ROOT)
	map_names.sort()

	for map_name in map_names:
		for tier in TIERS:
			var tier_path: String = "%s%s/%s" % [ENEMY_DATABASE_ROOT, map_name, tier]
			if not DirAccess.dir_exists_absolute(tier_path):
				continue

			var file_names := DirAccess.get_files_at(tier_path)
			file_names.sort()
			for file_name in file_names:
				if file_name.get_extension().to_lower() != "yaml":
					continue
				var enemy_id := file_name.get_basename()
				var owners: PackedStringArray = owners_by_id.get(enemy_id, PackedStringArray())
				owners.append("%s/%s" % [map_name, tier])
				owners_by_id[enemy_id] = owners

	var enemy_ids := owners_by_id.keys()
	enemy_ids.sort()
	for enemy_id in enemy_ids:
		var owners: PackedStringArray = owners_by_id[enemy_id]
		if owners.size() <= 1:
			continue
		owners.sort()
		push_warning(
			"EnemyRosterValidator: enemy id '%s' is defined by %s. Enemy ids must be globally unique."
			% [enemy_id, ", ".join(owners)]
		)
