class_name Staff
extends Node2D

# Runtime entity for the player's Staff avatar.
# Owns: current_hp / max_hp + skill cast lifecycle.
# Does NOT own: visual sprite at the path endpoint (separate scene instanced
# by GameScene from data.end_sprite_scene; reference kept here via `staff_sprite`
# so cast animation can fire on the visible character).

signal hp_changed(current: int, max: int)
signal died
signal skill_cast_requested  # Player pressed the Staff Widget skill button → GameScene enters casting state
signal skill_used            # Skill completed (Phase 2) — StaffWidget greys the button on this

var data: StaffData
var current_hp: int = 0
var max_hp: int = 0

# Skill charge state (MOBA-style).
#   -1 = unlimited (no cap; never decrements)
#    0 = no charges left (button greyed; canCastSkill returns false)
#    N = N remaining charges (positive — capped, decrements per cast)
# Initialized from data.skill_max_charges in setup(). Same field replaces the old
# boolean one_time_use design — supports 1/game, 2/game, ..., unlimited.
var skill_charges_remaining: int = -1

# Reference to the AnimatedSprite2D instance at the path endpoint (set by GameScene
# after instantiating data.end_sprite_scene). Used by executeSkillAtPosition for cast
# animation playback. May be null if the endpoint sprite failed to load.
var staff_sprite: AnimatedSprite2D = null

func setup(staff_data: StaffData) -> void:
	if staff_data == null:
		push_error("Staff.setup: staff_data is null")
		return
	data = staff_data
	max_hp = data.max_hp
	current_hp = data.max_hp

	# Initialize skill charges from data (-1 = unlimited; N = N charges per game).
	skill_charges_remaining = data.skill_max_charges

	hp_changed.emit(current_hp, max_hp)

func takeDamage(amount: int) -> void:
	if amount <= 0 or current_hp <= 0:
		return
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit()

func getCurrentHp() -> int:
	return current_hp

func getMaxHp() -> int:
	return max_hp

func canCastSkill() -> bool:
	# Available when skill defined AND charges remain (or unlimited).
	if data == null or data.skill == null:
		return false
	# -1 = unlimited; > 0 = has charges; 0 = depleted.
	return skill_charges_remaining != 0

# Phase 2 — emit only. GameScene enters "staff_skill_casting" state and shows the
# AOE indicator on receipt. Final execution happens via executeSkillAtPosition()
# once the player confirms the cast position (LeftClick on map).
func requestCastSkill() -> void:
	if not canCastSkill():
		return
	skill_cast_requested.emit()

# Execute the staff skill at the player-aimed world position. Drives the action
# chain manually (no SkillController dependency) since Staff doesn't have the
# Tower-style mana / cooldown model — just one-time / unlimited gating.
func executeSkillAtPosition(world_position: Vector2) -> void:
	if not canCastSkill():
		return

	# Cast animation — fire-and-forget on the endpoint sprite. has_animation() guard
	# means we silently skip when the artist hasn't authored the "skill" animation yet.
	# TODO: replace with the actual SpriteFrames "skill" entry once the artist provides it.
	if staff_sprite != null and data.cast_animation != "":
		var frames: SpriteFrames = staff_sprite.sprite_frames
		if frames != null and frames.has_animation(data.cast_animation):
			staff_sprite.play(data.cast_animation)

	# Cast sound — mirrors Tower attack_sound pattern (attack_controller.gd:37 uses
	# Utility.parse_string_to_enum + AudioManager.playSfx). Empty cast_sound = skip.
	# TODO: Game Director picks the final SFX key from SoundDatabase.SFX_NAME and fills
	# a_chan.yaml cast_sound (e.g., "skill_cast"). Until then, leave "" so we skip silently.
	if data.cast_sound != "":
		var sfx_enum = Utility.parse_string_to_enum(SoundDatabase.SFX_NAME, data.cast_sound)
		AudioManager.playSfx(sfx_enum)

	# Build SkillContext + run actions sequentially via the same pattern as Tower
	# skills (await each action). target_position in extra is the player click world pos.
	var context := SkillContext.new()
	context.skillName = data.skill.name
	context.user = self
	context.target = []
	context.cancel = false
	context.extra = {
		"target_position": world_position,
		"parameter": data.skill.parameters,
	}

	for action in data.skill.actions:
		if action == null:
			continue
		await action.execute(context)
		if context.cancel:
			break

	# Decrement charges only when capped (-1 = unlimited, untouched). On 0, future
	# canCastSkill calls return false → widget shows greyed state on skill_used.
	if skill_charges_remaining > 0:
		skill_charges_remaining -= 1
	skill_used.emit()
