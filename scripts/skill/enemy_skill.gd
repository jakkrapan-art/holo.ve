class_name EnemySkill
extends Skill

@export var cooldown: float = 3
# Passive: actions apply once at spawn (EnemySkillController.applyPassives);
# never enters the in-combat/random cast pool, cooldown unused.
@export var passive: bool = false
# Triggered: fires itself when its trigger condition is met (first condition:
# hp_below), bypassing the castWait pacing gate - the condition is its own
# telegraph (Director 2026-07-09). Never in the random cast pool.
@export var triggered: bool = false
@export var trigger_hp_below: float = 0.0
# Once the condition fires the skill never re-arms (set at queue time, so a
# heal re-crossing the threshold cannot double-fire while the cast is pending).
var triggerUsed: bool = false
var cooldownRemaining: float = 0.0;

func _init(p_name:String="EnemySkill", p_desc:String="Just an enemy skill", p_actions:Array[SkillAction]=[], p_parameters:Dictionary={}, p_oneTimeUse: bool = false, p_cooldown:float=3.0, p_castTime: float = 0.0):
	super(p_name, p_desc, p_actions, p_parameters, p_oneTimeUse, p_castTime);
	self.cooldown = p_cooldown;

func isReady():
	return super.isReady() and cooldownRemaining <= 0.0

func tick(delta: float):
	cooldownRemaining = maxf(0.0, cooldownRemaining - delta)

func initCooldown():
	# Ready at spawn (Director 2026-07-07; was cooldown/2, which muted King
	# Salam for its first 10s no matter how hard it was hit). First-cast
	# TIMING is owned by Enemy's castWait pacing gate, not by cooldowns;
	# cooldown starts per cast.
	cooldownRemaining = 0.0

func startCooldown():
	cooldownRemaining = cooldown
