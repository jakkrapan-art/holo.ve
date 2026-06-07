class_name PassiveCritPierce
extends RefCounted

# Crit-pierce passive (Josuiji Shinri "Bull Eyes" / "Heartpierce Shot").
#
# Loop:
#   - Each NON-crit auto-attack -> +1 Bull Eyes stack. Stacks are kept as a single
#     counter and pushed as ONE CRIT_CHANCE buff = crit_chance_per_stack * stacks
#     (state stays O(1); no per-stack BuffInstance churn). No cap -- overcap is a
#     deliberate buffer against enemy crit-chance debuffs.
#   - The auto-attack that CRITS fires a guaranteed-crit pierce arrow (w1xhN line)
#     toward the crit target instead of the normal single hit (tower replaces the
#     instant hit with this). The crit shot does not grant a stack.
#   - After the crit: reset_on_crit true  -> clear stacks (Bull Eyes normal form)
#                     reset_on_crit false -> keep stacks (Heartpierce Shot / evolve)
#
# Crit roll itself stays in TowerData.calculateFinalDamage (uses getCritChance,
# which already includes the Bull Eyes CRIT_CHANCE buff), so the ramp is automatic.

const BULL_EYES_KEY := "bull_eyes"

var tower: Tower
var crit_chance_per_stack: float
var reset_on_crit: bool
var bonus_crit_damage: Array          # per-level additive crit damage (x); index by level-1
var projectile_scene: PackedScene
var arrow_speed: float                # tiles/sec
var arrow_range: float                # tiles
var stacks: int = 0

func _init(owner: Tower, params: Dictionary) -> void:
	tower = owner
	# Designer-tunable numbers live under `parameters` (matches active-skill YAML).
	var parameters: Dictionary = params.get("parameters", {})
	crit_chance_per_stack = float(parameters.get("critChancePerStack", 5))
	bonus_crit_damage = parameters.get("bonusCritDamage", [0.0])
	# Structural/runtime params stay top-level.
	reset_on_crit = bool(params.get("reset_on_crit", true))
	arrow_speed = float(params.get("arrow_speed", 12.0))
	arrow_range = float(params.get("arrow_range", 4.0))
	var path: String = str(params.get("projectile", ""))
	if path != "" and ResourceLoader.exists(path):
		projectile_scene = load(path)

# Does a crit replace the normal instant hit with the arrow? (Tower asks before attacking.)
func replaces_attack_on_crit() -> bool:
	return projectile_scene != null

# Called after a NON-crit auto-attack landed.
func on_normal_attack() -> void:
	stacks += 1
	tower.data.addCritChanceBuff(crit_chance_per_stack * stacks, BULL_EYES_KEY)

# Called when the auto-attack rolled a crit; fires the arrow and updates stacks.
func on_crit_attack(target: Enemy) -> void:
	_fire_arrow(target)
	if reset_on_crit:
		reset()

# Wave reset / re-setup: drop all stacks and the Bull Eyes buff.
func reset() -> void:
	stacks = 0
	tower.data.removeCritChanceBuff(BULL_EYES_KEY)

func _bonus_for_level() -> float:
	if not (bonus_crit_damage is Array) or bonus_crit_damage.is_empty():
		return 0.0
	var idx: int = clampi(tower.data.level - 1, 0, bonus_crit_damage.size() - 1)
	return float(bonus_crit_damage[idx])

func _fire_arrow(target: Enemy) -> void:
	if projectile_scene == null or not is_instance_valid(target) or not is_instance_valid(tower):
		return

	# Guaranteed-crit arrow damage = TotalAttack * (crit damage + x), additive x.
	var crit_damage: float = tower.data.getCritDamage() + _bonus_for_level()
	var value: int = int(tower.data.getTotalAttack() * crit_damage)
	var dmg := Damage.new(tower, value, tower.data.attackType, true)

	var direction: Vector2 = (target.global_position - tower.global_position).normalized()
	var lifetime: float = arrow_range / arrow_speed if arrow_speed > 0.0 else 1.0

	var p: Projectile = projectile_scene.instantiate() as Projectile
	p.global_position = tower.global_position
	tower.get_tree().root.add_child(p)
	p.speed = arrow_speed * GridHelper.CELL_SIZE
	p.prevent_rehit = true
	p.setup_direction(tower, direction, dmg, lifetime,
			ProjectileCallback.new(Callable(self, "_on_arrow_hit"), Callable(), Callable()))

func _on_arrow_hit(_projectile: Projectile, hit) -> void:
	if hit is Enemy and is_instance_valid(hit):
		(hit as Enemy).recvDamage(_projectile.damage)
