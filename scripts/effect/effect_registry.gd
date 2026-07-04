class_name EffectRegistry

# Loads and serves EffectDefs from the canonical registry YAML. Lazy-loaded on
# first get_def() so load order never matters; addDeck also calls load_all()
# up-front alongside the other database loads.

const REGISTRY_PATH := "res://resources/database/effect/effects.yaml"
const ICON_GROUP := "effect"

static var _defs: Dictionary = {}
static var _loaded: bool = false

static func load_all() -> void:
	_defs = {}
	_loaded = true
	var raw: Variant = YamlParser.load_data(REGISTRY_PATH)
	if not (raw is Dictionary) or raw.is_empty():
		push_error("EffectRegistry: failed to load or empty registry: " + REGISTRY_PATH)
		return
	for effect_id in raw.keys():
		var entry: Variant = raw[effect_id]
		if not (entry is Dictionary):
			push_error("EffectRegistry: entry '" + str(effect_id) + "' is not a mapping - skipped")
			continue
		var def := _build_def(str(effect_id), entry)
		if def != null:
			_defs[def.id] = def

static func _build_def(effect_id: String, entry: Dictionary) -> EffectDef:
	var kind_str := str(entry.get("kind", ""))
	if not EffectTypes.KIND_FROM_STRING.has(kind_str):
		push_error("EffectRegistry: '" + effect_id + "' has unknown kind '" + kind_str + "' - skipped")
		return null
	var def := EffectDef.new()
	def.id = effect_id
	def.kind = EffectTypes.KIND_FROM_STRING[kind_str]
	def.display_name = str(entry.get("name", effect_id))
	def.desc = str(entry.get("desc", ""))
	def.icon_path = str(entry.get("icon", ""))
	var category_str := str(entry.get("category", "buff"))
	def.category = EffectTypes.CATEGORY_FROM_STRING.get(category_str, EffectTypes.Category.BUFF)
	var stack_str := str(entry.get("stack", "refresh"))
	def.stack_rule = EffectTypes.STACK_FROM_STRING.get(stack_str, EffectTypes.StackRule.REFRESH)
	def.max_stacks = int(entry.get("max_stacks", 0))
	def.default_duration = float(entry.get("duration", 0.0))
	var lifetime_str := str(entry.get("lifetime", "wave"))
	def.lifetime = EffectTypes.LIFETIME_FROM_STRING.get(lifetime_str, EffectTypes.Lifetime.WAVE)
	def.negate_value = effect_id.ends_with("_down")
	var params: Variant = entry.get("params", {})
	def.params = params if params is Dictionary else {}
	return def

static func get_def(effect_id: String) -> EffectDef:
	if not _loaded:
		load_all()
	var def: EffectDef = _defs.get(effect_id, null)
	if def == null:
		push_error("EffectRegistry: unknown effect id '" + effect_id + "'")
	return def

# Cache every registry icon under one sprite group so the icon row can pull
# textures by effect id; artists retarget art by editing the YAML icon path.
static func preload_icons() -> void:
	if not _loaded:
		load_all()
	for def: EffectDef in _defs.values():
		if def.icon_path != "":
			ResourceManager.loadImage(ICON_GROUP, def.id, def.icon_path)
