extends Entity

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var dashTimer: Timer = $DashTimer
@onready var skill: SkillController = $SkillController
@export var moveSpeed: float = 100
@export var runSpeedMultiplier: float = 1.2

@export var dashSpeedMultiplier: float = 3
@export var dashDuration: float = 0.2

@onready var attackController: AttackController = $AttackController
@onready var enemyDetector: EnemyDetector = $EnemyDetector

@onready var weapon = $Gun

var moveInput: Vector2 = Vector2.ZERO
var isFacingRight: bool = true

var isDashing: bool = false
var dashDirection: Vector2 = Vector2.ZERO

var bulletModifier: Array[AttackModifier] = []

func _ready():
	attackController.setDelayTime(stats.attackSpeed)
	dashTimer.wait_time = dashDuration
	attackController.setup(weapon)
	
	addBulletModifier(AttackModifier.new(15))
	addBulletModifier(AttackModifier.new(20))
	super()

func _process(delta):
	checkMoveInput()
	checkDashInput()
	if Input.is_action_just_pressed("dash"):
		skill.useSkill(0, self, self)
	attack()
		
func _physics_process(delta):
	if(isDashing):
		dash(delta, dashDirection);
		return

	moveCharacter(delta)

func checkDashInput():
	if Input.is_action_just_pressed("dash"):
		isDashing = true
		dashDirection = moveInput
		dashTimer.start()
	
func checkMoveInput():
	if Input.is_action_pressed("move_down"):
		moveInput.y = 1
	elif Input.is_action_pressed("move_up"):
		moveInput.y = -1
	else: 
		moveInput.y = 0
		
	if Input.is_action_pressed("move_left"):
		moveInput.x = -1
	elif  Input.is_action_pressed("move_right"):
		moveInput.x = 1
	else:
		moveInput.x = 0

func moveCharacter(delta):
	var velocity = moveInput * moveSpeed
	var isRunning = Input.is_action_pressed("run")
	
	if isRunning:
		velocity *= runSpeedMultiplier
		
	if(velocity.length() > 0):
		anim.play("walk")
	else:
		anim.play("idle")
		
	flip()
	position += velocity * delta
	
func flip():
	if (isFacingRight && moveInput.x < 0) || (!isFacingRight && moveInput.x > 0):
		anim.flip_h = !anim.flip_h
		isFacingRight = !anim.flip_h

func dash(delta, dir):
	if(dashTimer.time_left <= 0):
		isDashing = false
		dashTimer.stop()
		return

	position += dir * moveSpeed * dashSpeedMultiplier * delta

func attack():
	if attackController == null || !attackController.isReady() || enemyDetector == null || !enemyDetector.isHasEnemy():
		return
	attackController.attack(enemyDetector.target, stats.attack)

func addBulletModifier(modifier):
	if (weapon != null && weapon.has_signal("onTargetHit")):
		bulletModifier += [modifier]		
		weapon.connect("onTargetHit", Callable(modifier, "active"))

func test(target):
	print("test func with target: ", target);

func _onDashTimerTimeout():
	pass # Replace with function body.
