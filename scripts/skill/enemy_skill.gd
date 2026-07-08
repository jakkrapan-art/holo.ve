class_name EnemySkill
extends Skill

@export var cooldown: float = 3
# Passive: actions apply once at spawn (EnemySkillController.applyPassives);
# never enters the in-combat/random cast pool, cooldown unused.
@export var passive: bool = false
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
