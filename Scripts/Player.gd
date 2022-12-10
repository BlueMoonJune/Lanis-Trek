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

var velocity = Vector2.ZERO
var subpixel = Vector2.ZERO

var jump_no_grav = 0
var jump_buffer = 0

var fastJump = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#get_tree().get_root().size = Vector2(320, 180)


func _physics_process(delta):
	
	var grounded = is_on_floor()
	
	var RunMult
	if grounded:
		RunMult = 1
	else:
		RunMult = AirMult
	
	var move = Vector2(Input.get_axis("move_left","move_right"), Input.get_axis("move_up", "move_down"))
	if move.x == 0:
		velocity.x = move_toward(velocity.x, 0, delta * RunReduce * RunMult)
	elif velocity.x * move.x < MaxRun:
		velocity.x = move_toward(velocity.x, move.x * MaxRun, delta * RunAccel * RunMult)
	else:
		velocity.x = move_toward(velocity.x, move.x * MaxRun, delta * RunReduce * RunMult)
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.1
	if Input.is_action_just_released("jump"):
		jump_buffer = 0
	
	
	if grounded:
		velocity.y = 1
		if jump_buffer > 0:
			jump_buffer = 0
			velocity.y = JumpSpeed
			velocity.x += JumpHBoost * move.x
			jump_no_grav = 0.2
		else:
			jump_buffer = move_toward(jump_buffer, 0, delta)
	elif jump_no_grav == 0 or !Input.is_action_pressed("jump"):
		jump_no_grav = 0
		if move.y > 0 and velocity.y >= 160:
			velocity.y = move_toward(velocity.y, FastMaxFall, FastMaxAccel * delta)
		elif velocity.y >= 160:
			velocity.y = move_toward(velocity.y, MaxFall, FastMaxAccel * delta)
		elif abs(velocity.y) < 40 and Input.is_action_pressed("jump"):
			velocity.y = move_toward(velocity.y, MaxFall, Gravity / 2 * delta)
		else:
			velocity.y = move_toward(velocity.y, MaxFall, Gravity * delta)
	else:
		jump_no_grav = move_toward(jump_no_grav, 0, delta)
	
	if move.x != 0:
		if move.x < 0:
			$Sprite.flip_h = true
		else:
			$Sprite.flip_h = false
		
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
