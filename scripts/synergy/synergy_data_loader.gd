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
	d.type = str(raw.get("type", SynergyData.TYPE_STANDARD))
	d.rarity = str(raw.get("rarity", SynergyData.RARITY_COMMON))
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

	# Fail loud on category authoring. `type` is doubly load-bearing: a typo would
	# both drop the mission hover behaviour and print the typo into the player's
	# tooltip, since the key is the copy.
	if not SynergyData.TYPES.has(d.type):
		push_warning("Synergy '" + d.id + "': unknown type '" + d.type + "' - expected one of " + str(SynergyData.TYPES) + ".")
	# A rarity typo would otherwise read as common and the synergy would silently
	# lose its colour and its top slot in the panel.
	if not SynergyData.RARITIES.has(d.rarity):
		push_warning("Synergy '" + d.id + "': unknown rarity '" + d.rarity + "' - expected one of " + str(SynergyData.RARITIES) + "; treated as common.")
	# A unique trait is carried by exactly one tower in the game, so no unit gate
	# can ever exceed 1. Several tiers stay legal ([1, 1, 1]) for a unique mission
	# synergy whose tiers gate on the kill goal instead of the count.
	if d.is_unique():
		for t in d.thresholds:
			if int(t) != 1:
				push_warning("Synergy '" + d.id + "': rarity is unique but a threshold is " + str(t) + " - a unique trait has at most one holder, so every threshold must be 1.")
				break

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
