class_name SynergyDataLoader

# Reads the synergy manifest + per-file YAML into SynergyData objects, keyed by
# the resolved TowerTrait enum id. Manifest-driven (not a folder scan) so it
# works inside an exported PCK, matching the enemy/tower loaders.

const SYNERGY_DIR := "res://resources/database/synergy/"
const MANIFEST := SYNERGY_DIR + "synergy_list.yaml"

static func load_all() -> Dictionary:
	var result: Dictionary = {}   # synergy_id (int) -> SynergyData
	var manifest = YamlParser.load_data(MANIFEST)
	if manifest == null or not manifest.has("synergies"):
		push_error("SynergyDataLoader: missing/empty manifest " + MANIFEST)
		return result

	for entry in manifest.get("synergies", []):
		var id := str(entry).to_lower()
		var path := SYNERGY_DIR + id + ".yaml"
		var raw = YamlParser.load_data(path)
		if raw == null or raw.is_empty():
			push_error("SynergyDataLoader: missing/empty synergy file " + path)
			continue
		var data := _build(raw, path)
		if data != null:
			result[data.synergy_id] = data
	return result

static func _build(raw: Dictionary, path: String) -> SynergyData:
	var d := SynergyData.new()
	d.id = str(raw.get("id", ""))
	d.display_name = str(raw.get("name", d.id))
	d.kind = str(raw.get("kind", ""))
	d.type = str(raw.get("type", "normal"))
	d.effect = str(raw.get("effect", ""))
	# YamlParser does not process escapes; translate \n loader-side, only for the
	# text fields that want it (data_pipeline.md Problem #1).
	# Single tokenized desc key; a stale desc_template key warns and wins.
	d.desc = str(raw.get("desc", "")).replace("\\n", "\n")
	if raw.has("desc_template"):
		push_warning("Synergy '" + d.id + "': 'desc_template' was merged into 'desc' - rename the key (its tokenized text is used).")
		d.desc = str(raw.get("desc_template", "")).replace("\\n", "\n")
	for line in raw.get("tier_effects", []):
		d.tier_effects.append(str(line).replace("\\n", "\n"))

	for t in raw.get("thresholds", []):
		d.thresholds.append(int(t))

	var params = raw.get("parameters", {})
	if params is Dictionary:
		d.parameters = params

	d.synergy_id = _resolve_synergy_id(d.kind, d.id)
	if d.synergy_id == 0:
		push_error("SynergyDataLoader: cannot resolve id for '" + d.id + "' (kind=" + d.kind + ") in " + path)
		return null
	return d

# Maps the YAML id string to the TowerTrait enum int via the display-name tables.
static func _resolve_synergy_id(kind: String, id: String) -> int:
	var table: Dictionary
	match kind:
		"class":
			table = TowerTrait.TOWER_CLASS_NAMES
		"generation":
			table = TowerTrait.TOWER_GENERATION_NAMES
		_:
			push_error("SynergyDataLoader: unknown kind '" + kind + "' for id '" + id + "'")
			return 0

	# Compare through TowerTrait.name_key so a display-name rename ("SpellCaster"
	# -> "Spell Caster") cannot break id resolution.
	var target := TowerTrait.name_key(id)
	for key in table.keys():
		if TowerTrait.name_key(str(table[key])) == target:
			return key
	return 0
