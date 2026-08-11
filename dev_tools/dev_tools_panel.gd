extends CanvasLayer

const SKILL_AREAS_META: StringName = &"_dev_show_skill_areas"
const UNLIMITED_REROLLS_META: StringName = &"_dev_unlimited_card_rerolls"

var _wave_controller: Node = null
var _add_evo_token: Callable = Callable()

@onready var dev_tab: Button = $DevTab
@onready var panel: PanelContainer = $Panel
@onready var skill_areas: CheckButton = $Panel/Margin/VBox/SkillAreas
@onready var unlimited_rerolls: CheckButton = $Panel/Margin/VBox/UnlimitedRerolls
@onready var add_evo_token: Button = $Panel/Margin/VBox/AddEvoToken
@onready var boss_select: OptionButton = $Panel/Margin/VBox/BossSelect
@onready var spawn_boss: Button = $Panel/Margin/VBox/SpawnBoss
@onready var status: Label = $Panel/Margin/VBox/Status

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	dev_tab.pressed.connect(_toggle_panel)
	skill_areas.toggled.connect(_on_skill_areas_toggled)
	unlimited_rerolls.toggled.connect(_on_unlimited_rerolls_toggled)
	add_evo_token.pressed.connect(_on_add_evo_token_pressed)
	spawn_boss.pressed.connect(_on_spawn_boss_pressed)

func setup(wave_controller: Node, add_evo_token_callback: Callable = Callable()) -> void:
	_wave_controller = wave_controller
	_add_evo_token = add_evo_token_callback
	get_tree().set_meta(SKILL_AREAS_META, false)
	get_tree().set_meta(UNLIMITED_REROLLS_META, false)
	skill_areas.set_pressed_no_signal(false)
	unlimited_rerolls.set_pressed_no_signal(false)
	get_tree().call_group("dev_reroll_surface", "sync_dev_reroll_state")
	boss_select.clear()
	if _wave_controller != null and _wave_controller.has_method("get_dev_boss_options"):
		for boss_name in _wave_controller.call("get_dev_boss_options"):
			boss_select.add_item(str(boss_name))
	status.text = "Select a boss during an active wave."
	_sync_boss_state()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_toggle_panel()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	_sync_boss_state()

func _toggle_panel() -> void:
	panel.visible = not panel.visible

func _on_skill_areas_toggled(enabled: bool) -> void:
	get_tree().set_meta(SKILL_AREAS_META, enabled)

func _on_unlimited_rerolls_toggled(enabled: bool) -> void:
	get_tree().set_meta(UNLIMITED_REROLLS_META, enabled)
	get_tree().call_group("dev_reroll_surface", "sync_dev_reroll_state")

func _on_add_evo_token_pressed() -> void:
	if not _add_evo_token.is_valid() or not bool(_add_evo_token.call(1)):
		status.text = "Evolve Token request was rejected."
		return
	status.text = "Added 1 Evolve Token."

func _on_spawn_boss_pressed() -> void:
	if _wave_controller == null or not _wave_controller.has_method("request_dev_spawn_boss"):
		status.text = "Boss spawning is unavailable."
		return
	spawn_boss.disabled = true
	var boss_name := boss_select.get_item_text(boss_select.selected)
	var spawned: bool = await _wave_controller.call("request_dev_spawn_boss", boss_select.selected)
	status.text = "Spawned " + boss_name + "." if spawned else "Boss spawn request was rejected."
	_sync_boss_state()

func _sync_boss_state() -> void:
	var allowed := false
	if _wave_controller != null and _wave_controller.has_method("can_dev_spawn_boss"):
		allowed = bool(_wave_controller.call("can_dev_spawn_boss"))
	spawn_boss.disabled = not allowed or boss_select.item_count == 0
	boss_select.disabled = boss_select.item_count == 0

func _exit_tree() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.remove_meta(SKILL_AREAS_META)
	tree.remove_meta(UNLIMITED_REROLLS_META)
