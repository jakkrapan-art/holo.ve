class_name EffectIconRow
extends HBoxContainer

# Buff/debuff status-icon row, two surfaces (Director 2026-07-17):
# - Overhead (towers: above the Energy bar; enemies: above the HP bar):
#   display-only, hover disabled - the desc surface moved to the stats panels.
# - Stats-panel strip (rich_hover = true): floats above the panel, icons open
#   the shared opaque tooltip card on hover.
# Purely signal-driven off one EffectContainer - no per-frame work.
# Icons are built in code from the registry texture (green/red/purple
# placeholders today; artists swap art via the icon path in effects.yaml).
# Stack count shows bottom-right when stacks > 1. Left-aligned, oldest first;
# only the first max_visible show - when one expires, the next hidden icon
# shifts in (Director 2026-07-03).

const FALLBACK_COLORS := {
	EffectTypes.Category.BUFF: Color(0.27, 0.78, 0.35),
	EffectTypes.Category.DEBUFF: Color(0.86, 0.27, 0.27),
	EffectTypes.Category.MARK: Color(0.67, 0.35, 0.86),
}

@export var icon_size: int = 44
@export var max_visible: int = 5
# Stats-panel strips set true: icons STOP the mouse and open the rich tooltip
# card. Default false = overhead row, display-only (icons IGNORE the mouse).
@export var rich_hover: bool = false

var _container: EffectContainer = null
var _icons: Dictionary = {}    # EffectInstance.key() -> TextureRect
var _order: Array = []         # keys in apply order (drives overflow)

# Bind (or rebind) to a container. Existing effects are drawn immediately so
# a row bound after effects were applied never shows stale-empty (plan F3).
func setup(container: EffectContainer) -> void:
	if _container == container:
		return
	if _container != null:
		_container.effect_added.disconnect(_on_effect_added)
		_container.effect_removed.disconnect(_on_effect_removed)
		_container.effect_updated.disconnect(_on_effect_updated)
	_clear_icons()
	_container = container
	if container == null:
		return
	Utility.ConnectSignal(container, "effect_added", Callable(self, "_on_effect_added"))
	Utility.ConnectSignal(container, "effect_removed", Callable(self, "_on_effect_removed"))
	Utility.ConnectSignal(container, "effect_updated", Callable(self, "_on_effect_updated"))
	for inst: EffectInstance in container.get_all():
		_on_effect_added(inst)

func _on_effect_added(inst: EffectInstance) -> void:
	if inst == null or not inst.show_icon:
		return   # e.g. synergy board buffs: aggregated but shown in the synergy panel
	var k := inst.key()
	if _icons.has(k):
		_on_effect_updated(inst)
		return
	var icon := _make_icon(inst)
	_icons[k] = icon
	_order.append(k)
	add_child(icon)
	_update_stack_label(icon, inst)
	_refresh_overflow()

func _on_effect_removed(inst: EffectInstance) -> void:
	var icon: TextureRect = _icons.get(inst.key(), null)
	if icon != null:
		_icons.erase(inst.key())
		_order.erase(inst.key())
		icon.queue_free()
		_refresh_overflow()

# First max_visible icons (apply order) show; the rest wait hidden and shift
# in as earlier effects expire.
func _refresh_overflow() -> void:
	for i in range(_order.size()):
		var icon: TextureRect = _icons.get(_order[i], null)
		if icon != null:
			icon.visible = i < max_visible

func _on_effect_updated(inst: EffectInstance) -> void:
	var icon: TextureRect = _icons.get(inst.key(), null)
	if icon != null:
		_update_stack_label(icon, inst)

func _make_icon(inst: EffectInstance) -> EffectHoverIcon:
	var icon := EffectHoverIcon.new()
	icon.inst = inst
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Panel strip: STOP so the icon is a hover source for the tooltip card.
	# Overhead: IGNORE - display-only, transparent to world clicks and hover.
	icon.mouse_filter = Control.MOUSE_FILTER_STOP if rich_hover else Control.MOUSE_FILTER_IGNORE
	icon.texture = ResourceManager.getSprite(EffectRegistry.ICON_GROUP, inst.def.id)
	if icon.texture == null:
		# Registry icon missing/unloaded: flat category-colored square so the
		# effect is still visible in-game.
		var fill := ColorRect.new()
		fill.color = FALLBACK_COLORS.get(inst.def.category, Color.WHITE)
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(fill)
	var label := Label.new()
	label.name = "StackLabel"
	label.visible = false
	label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(label)
	return icon

func _update_stack_label(icon: TextureRect, inst: EffectInstance) -> void:
	if rich_hover:
		# tooltip_text must carry REAL text or the viewport strips it and never
		# calls _make_custom_tooltip (same trap as TowerSkillIcon).
		var title := inst.display_title()
		icon.tooltip_text = title if title != "" else inst.def.id
	var label: Label = icon.get_node_or_null("StackLabel")
	if label == null:
		return
	label.visible = inst.stacks > 1
	label.text = str(inst.stacks)

func _clear_icons() -> void:
	for icon in _icons.values():
		if is_instance_valid(icon):
			icon.queue_free()
	_icons.clear()
	_order.clear()
