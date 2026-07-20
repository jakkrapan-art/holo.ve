class_name EffectContainer
extends RefCounted

# Per-host store for EffectInstances (towers: on TowerData; enemies: on Enemy).
# Owns the expiry clock: the host's _process calls tick(delta) - there are NO
# scene-tree timers in this system (root fix for review R2/R3), so nothing can
# outlive a wave reset or remove another host's effect.

signal effect_added(inst: EffectInstance)
signal effect_removed(inst: EffectInstance)
signal effect_updated(inst: EffectInstance)

var _effects: Dictionary = {}          # key() -> EffectInstance
var _host: Node = null
var _agg_cache: Dictionary = {}        # Kind -> float, invalidated on mutation
# Mark thresholds: def.id -> { "count": int, "callback": Callable }.
# Cleared on clear_all/clear_wave_scoped so stale Callables never fire.
var _mark_thresholds: Dictionary = {}

func set_host(host: Node) -> void:
	_host = host

func get_host() -> Node:
	return _host

# Apply one instance following its def's stack rule. Returns the stored
# instance (the existing record on refresh/stack, the new one on first apply).
func apply(inst: EffectInstance) -> EffectInstance:
	if inst == null or inst.def == null:
		return null
	var k := inst.key()
	if _effects.has(k):
		var existing: EffectInstance = _effects[k]
		match inst.def.stack_rule:
			EffectTypes.StackRule.STACK:
				if inst.def.max_stacks <= 0 or existing.stacks < inst.def.max_stacks:
					existing.stacks += 1
			_:
				existing.value = inst.value
		# Both rules refresh the (shared) timer - player-favorable.
		existing.duration = inst.duration
		existing.remaining = inst.duration
		# Re-adopt caster data captured at this application (e.g. the DOT
		# attack snapshot - Liquid Fire: snapshot at EVERY apply). A fresh
		# instance's snapshot holds only capture()-written keys, so runtime
		# keys (tick clock, prev_modulate) are never clobbered.
		existing.snapshot.merge(inst.snapshot, true)
		_agg_cache.clear()
		effect_updated.emit(existing)
		_check_mark_threshold(existing)
		return existing

	inst.remaining = inst.duration
	_effects[k] = inst
	_agg_cache.clear()
	if inst.behavior != null:
		inst.behavior.on_apply(_host, inst)
	effect_added.emit(inst)
	_check_mark_threshold(inst)
	return inst

func tick(delta: float) -> void:
	var expired: Array = []
	for inst: EffectInstance in _effects.values():
		if inst.behavior != null:
			inst.behavior.process(delta, _host, inst)
		if inst.duration > 0.0:
			inst.remaining -= delta
			if inst.remaining <= 0.0:
				expired.append(inst)
	for inst: EffectInstance in expired:
		_remove_instance(inst)

func remove_key(k: String) -> void:
	var inst: EffectInstance = _effects.get(k, null)
	if inst != null:
		_remove_instance(inst)

func remove_source(source_id: String) -> void:
	for inst: EffectInstance in _effects.values().duplicate():
		if inst.source_id == source_id:
			_remove_instance(inst)

func has_key(k: String) -> bool:
	return _effects.has(k)

func get_all() -> Array:
	return _effects.values()

# Sum of effective values for one stat kind. Debuffs are negative values in
# the same bucket (one stat path - no separate debuff fields).
func aggregate(kind: int) -> float:
	if _agg_cache.has(kind):
		return _agg_cache[kind]
	var total := 0.0
	for inst: EffectInstance in _effects.values():
		if inst.def.kind == kind:
			total += inst.effective_value()
	_agg_cache[kind] = total
	return total

func has_kind(kind: int) -> bool:
	for inst: EffectInstance in _effects.values():
		if inst.def.kind == kind:
			return true
	return false

# Wave-end / host-left-board cleanup: WAVE-lifetime effects go, BOARD
# (synergy) effects stay. Behaviors get on_expire so side effects undo.
func clear_wave_scoped() -> void:
	for inst: EffectInstance in _effects.values().duplicate():
		if inst.lifetime == EffectTypes.Lifetime.WAVE:
			_remove_instance(inst)
	_mark_thresholds.clear()

func clear_all() -> void:
	for inst: EffectInstance in _effects.values().duplicate():
		_remove_instance(inst)
	_mark_thresholds.clear()

# Total stacks of one effect id across all sources, any category - generic
# stack-counter reader (e.g. the Calliope soul buff; mark_stacks below is
# MARK-category only).
func stacks_of(effect_id: String) -> int:
	var total := 0
	for inst: EffectInstance in _effects.values():
		if inst.def.id == effect_id:
			total += inst.stacks
	return total

# ---- Mark API (framework; no consumer tower yet) ----

func has_mark(effect_id: String) -> bool:
	return mark_stacks(effect_id) > 0

# Total stacks of one mark def across all sources.
func mark_stacks(effect_id: String) -> int:
	var total := 0
	for inst: EffectInstance in _effects.values():
		if inst.def.id == effect_id and inst.def.category == EffectTypes.Category.MARK:
			total += inst.stacks
	return total

# Consume up to `count` stacks (-1 = all). Returns the number consumed.
func consume_mark(effect_id: String, count: int = -1) -> int:
	var consumed := 0
	for inst: EffectInstance in _effects.values().duplicate():
		if inst.def.id != effect_id or inst.def.category != EffectTypes.Category.MARK:
			continue
		if count < 0 or count - consumed >= inst.stacks:
			consumed += inst.stacks
			_remove_instance(inst)
		else:
			var take := count - consumed
			if take <= 0:
				break
			inst.stacks -= take
			consumed += take
			_agg_cache.clear()
			effect_updated.emit(inst)
		if count >= 0 and consumed >= count:
			break
	return consumed

# Fire `callback` once when the mark's total stacks reach `count`.
func set_mark_threshold(effect_id: String, count: int, callback: Callable) -> void:
	_mark_thresholds[effect_id] = { "count": count, "callback": callback }

func _check_mark_threshold(inst: EffectInstance) -> void:
	if inst.def.category != EffectTypes.Category.MARK:
		return
	var entry: Variant = _mark_thresholds.get(inst.def.id, null)
	if entry == null:
		return
	if mark_stacks(inst.def.id) >= int(entry["count"]):
		_mark_thresholds.erase(inst.def.id)
		var cb: Callable = entry["callback"]
		if cb.is_valid():
			cb.call(inst)

# ---- internal ----

func _remove_instance(inst: EffectInstance) -> void:
	_effects.erase(inst.key())
	_agg_cache.clear()
	if inst.behavior != null:
		inst.behavior.on_expire(_host, inst)
	effect_removed.emit(inst)
