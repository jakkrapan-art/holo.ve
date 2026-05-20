class_name StaffData
extends Resource

# Static fields loaded from YAML — one StaffData per staff (a_chan, demon, etc.).
# Runtime state (current_hp, skill use count, etc.) lives on the Staff entity,
# NOT here, to avoid the shared-resource gotcha noted for TowerData in AGENTS.md §6.

@export var data_name: String = ""
@export var name: String = ""
@export var max_hp: int = 100

# Path strings (resolved relative to res://resources/ by ResourceManager-style helpers)
@export var hud_portrait: String = ""
@export var hud_skill_icon: String = ""
@export var selection_portrait: String = ""
@export var end_sprite_scene: String = ""

# Skill — reuses the Skill resource class from the Tower pipeline so future staffs
# can author skills via the same SkillAction primitives (find_multi_enemy, attack,
# damage_percent_maxhp, etc.). Player triggers via the HUD widget skill button.
@export var skill: Skill = null

# Charge-based use limit (MOBA-style). Replaces the earlier one_time_use boolean.
#   -1 (or omitted)  → unlimited (no cap; charges never decrement)
#    N (positive)    → N charges per game (1 = once per game, 2 = twice, …)
# YAML field: `use_charges`. UI counter / per-charge cooldown deferred to a future
# extension; Phase 2 only greys the widget at 0 remaining.
@export var skill_max_charges: int = -1

# AOE footprint for the cast-range indicator (cells; rectangle centered on click).
# Independent of any individual SkillAction parameters — the indicator visualizes
# what the skill will affect before commit.
@export var skill_aoe_width: int = 4
@export var skill_aoe_height: int = 4

# Animation + sound hooks — fired once at cast start (BEFORE the action chain).
# Both default empty; framework gracefully skips if asset missing (see Staff.executeSkillAtPosition).
# Asset implementation deferred per Game Director Phase 2 spec: "ทำรองรับรอ implement".
@export var cast_animation: String = ""
@export var cast_sound: String = ""
