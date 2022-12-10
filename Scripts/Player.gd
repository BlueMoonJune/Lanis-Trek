extends KinematicBody2D

const MaxFall = 160
const Gravity = 900
const HalfGravThreshold = 40

const FastMaxFall = 240
const FastMaxAccel = 300

const MaxRun = 90
const RunAccel = 1000
const RunReduce = 400
const AirMult = .65

const HoldingMaxRun = 70
const HoldMinTime = .35

const BounceAutoJumpTime = .1

const DuckFriction = 500
const DuckCorrectCheck = 4
const DuckCorrectSlide = 50

const DodgeSlideSpeedMult = 1.2
const DuckSuperJumpXMult = 1.25
const DuckSuperJumpYMult = .5

const JumpGraceTime = 0.1
const JumpSpeed = -105
const JumpHBoost = 40
const VarJumpTime = .2
const CeilingVarJumpGrace = .05
const UpwardCornerCorrection = 4
const WallSpeedRetentionTime = .06

const StandardHitBox = Rect2(0, -6, 4, 6)
const StandardHurtBox = Rect2(0, -7, 4, 5)
const DuckHitBox = Rect2(0, -3, 4, 3)
const DuckHurtBox = Rect2(0, -4, 4, 2)

var velocity = Vector2.ZERO
var subpixel = Vector2.ZERO

var crouched = false

var jumpNoGrav = 0
var jumpBuffer = 0

var fastJump = false
var cyoteTime = 0

var spawnPos

func set_hitbox(collider : CollisionShape2D, rect : Rect2):
	
	collider.position = rect.position
	if collider.shape is RectangleShape2D:
		collider.shape.extents = rect.size
	else:
		print("CollisionShape does not have a RectangleShape2D!")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	spawnPos = position
	
	$Camera.zoom = Vector2(320, 180) / get_tree().get_root().size

func _physics_process(delta):
	
	var grounded = is_on_floor()
	
	var RunMult
	if grounded:
		RunMult = 1
	else:
		RunMult = AirMult
	
	var move = Vector2(Input.get_axis("move_left","move_right"), Input.get_axis("move_up", "move_down"))
	if !crouched or !grounded:
		if move.x == 0:
			velocity.x = move_toward(velocity.x, 0, delta * RunReduce * RunMult)
		elif velocity.x * move.x < MaxRun:
			velocity.x = move_toward(velocity.x, move.x * MaxRun, delta * RunAccel * RunMult)
		else:
			velocity.x = move_toward(velocity.x, move.x * MaxRun, delta * RunReduce * RunMult)
	
	if Input.is_action_just_pressed("jump"):
		jumpBuffer = 0.1
	if Input.is_action_just_released("jump"):
		jumpBuffer = 0
		
	if Input.is_action_just_pressed("reset"):
		position = spawnPos
	
	if grounded:
		velocity.y = 1
		cyoteTime = JumpGraceTime
		if move.y > 0 and !crouched:
			crouched = true
			$Sprite.animation = "duck"
			set_hitbox($Hitbox, DuckHitBox)
			set_hitbox($Hurtbox/Collider, DuckHurtBox)
		elif move.y <= 0 and crouched:
			crouched = false
			set_hitbox($Hitbox, StandardHitBox)
			set_hitbox($Hurtbox/Collider, StandardHurtBox)
			
	elif jumpNoGrav == 0 or !Input.is_action_pressed("jump"):
		jumpNoGrav = 0
		if move.y > 0 and velocity.y >= 160:
			velocity.y = move_toward(velocity.y, FastMaxFall, FastMaxAccel * delta)
		elif velocity.y >= 160:
			velocity.y = move_toward(velocity.y, MaxFall, FastMaxAccel * delta)
		elif abs(velocity.y) < 40 and Input.is_action_pressed("jump"):
			velocity.y = move_toward(velocity.y, MaxFall, Gravity / 2 * delta)
		else:
			velocity.y = move_toward(velocity.y, MaxFall, Gravity * delta)
	else:
		jumpNoGrav = move_toward(jumpNoGrav, 0, delta)
	
	if cyoteTime > 0 and jumpBuffer > 0:
			jumpBuffer = 0
			velocity.y = JumpSpeed
			velocity.x += JumpHBoost * move.x
			jumpNoGrav = 0.2
	
	jumpBuffer = move_toward(jumpBuffer, 0, delta)
	cyoteTime = move_toward(cyoteTime, 0, delta)
	
	if move.x != 0:
		if move.x < 0:
			$Sprite.flip_h = true
		else:
			$Sprite.flip_h = false
	
	if !crouched:
		if velocity.x != 0 and grounded:
			$Sprite.animation = "walk"
		elif grounded:
			$Sprite.animation = "idle"
		elif fastJump or abs(velocity.x) > MaxRun:
			if $Sprite.animation != "jumpFast":
				$Sprite.animation = "jumpFast"
				$Sprite.frame = 0
		else:
			if $Sprite.animation != "jumpSlow":
				$Sprite.animation = "jumpSlow"
				$Sprite.frame = 0
		
	
	position += subpixel
	velocity = move_and_slide(velocity, Vector2.UP)
	subpixel = position - position.round()
	position = position.round()
