class_name PassiveSoulHarvest
extends RefCounted

# Soul-harvest passive (Mori Calliope): +soulsPerKill Soul per enemy KILLED BY
# HER SKILLS. Attribution needs BOTH gates: cause.source == tower (this tower
# landed it) AND cause.isSkillDamage (a skill authored it, including the
# aftershock's inner attack). Do not drop the isSkillDamage half - normal attacks
# used to be excluded only because they failed to stamp a source at all, which
# was a bug; once that was fixed they would otherwise start granting Souls.
#
# Souls are run-permanent by design (Director 2026-07-12): board lifetime, no
# cap, kept across wave end AND evolve - reset() is deliberately a no-op (do
# NOT copy PassiveCritPierce.reset(), which drops its stacks).

const SOUL_EFFECT := "soul"
# FIXED source id: identity = source_id + "/" + def.id must stay the same when
# the skill name changes on evolve (Ricky -> RIP), or the stacks would fork.
const SOUL_SOURCE := "calli_souls"

var tower: Tower
var souls_per_kill: int = 1
var _wave_controller: Node = null

func _init(owner: Tower, params: Dictionary) -> void:
	tower = owner
	var parameters: Dictionary = params.get("parameters", {})
	souls_per_kill = int(parameters.get("soulsPerKill", 1))
	_wave_controller = tower.get_tree().get_first_node_in_group("wave_controller")
	if _wave_controller != null:
		Utility.ConnectSignal(_wave_controller, "onEnemyDead", Callable(self, "_on_enemy_dead"))

func _on_enemy_dead(_enemy, cause: Damage, _reward) -> void:
	if cause == null or not is_instance_valid(tower) or cause.source != tower:
		return
	if not cause.isSkillDamage:
		return
	for i in souls_per_kill:
		var inst := EffectUtility.make_instance(SOUL_EFFECT, SOUL_SOURCE, 1.0, 0.0)
		if inst != null:
			tower.data.effects.apply(inst)

# ---- Tower passive contract (tower.gd calls these on any non-null passive) ----

func replaces_attack_on_crit() -> bool:
	return false

func on_normal_attack() -> void:
	pass

func on_crit_attack(_target: Enemy) -> void:
	pass

# Wave reset / passive rebuild hook: Souls persist - no-op by design (header).
func reset() -> void:
	pass

# Detach from the wave controller. The signal connection holds this RefCounted
# alive, so without this the evolve-time _setupPassive rebuild would leave the
# old listener connected = double Souls per kill.
func dispose() -> void:
	if _wave_controller != null and is_instance_valid(_wave_controller):
		var cb := Callable(self, "_on_enemy_dead")
		if _wave_controller.is_connected("onEnemyDead", cb):
			_wave_controller.disconnect("onEnemyDead", cb)
	_wave_controller = null
