extends KinematicBody2D

# movement
const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")


var character_stats = CharacterStats setget set_stats

enum {
	MOVE,
	ROLL,
	ATTACK
}

var velocity = Vector2.ZERO
var state = MOVE
var roll_vector = Vector2.DOWN
var stats = GlobalPlayerStats

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blink_animation_player = $BlinkAnimationPlayer

signal save_requested

func _ready() -> void:
	set_physics_process(false)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -30)
	randomize()
	stats.connect("no_health",self, "queue_free")
	Events.connect("give_exp", self,"_on_give_exp");
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector

func set_stats(new_stats: CharacterStats) -> void:
	character_stats = new_stats
	set_physics_process(character_stats != null)

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_home"):
		emit_signal("save_requested")
	match state:
		MOVE:
			move_state(delta)
		
		ROLL:
			roll_state(delta)
		
		ATTACK:
			attack_state(delta)

func move_state(delta):
#	set player level
	GlobalPlayerStats.level = character_stats.LEVEL
	
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position" , input_vector)
		animationTree.set("parameters/Run/blend_position" , input_vector)
		animationTree.set("parameters/Attack/blend_position" , input_vector)
		animationTree.set("parameters/Roll/blend_position" , input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * character_stats.MAX_SPEED, character_stats.ACCELERATION * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, character_stats.FRICTION * delta)
	move()
	
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK

func roll_state(delta):
	velocity = roll_vector * character_stats.ROLL_SPEED
	animationState.travel("Roll")
	hurtbox.start_invicibility(0.6,true)
	move()

func attack_state(delta):
	velocity = velocity*.8
	animationState.travel("Attack")

func move():
	velocity = move_and_slide(velocity)

func attack_animation_finished():
	velocity = Vector2.ZERO
	state = MOVE

func roll_animation_finished():
	state = MOVE

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	hurtbox.start_invicibility(0.6)
	hurtbox.create_hit_effect()
	var player_hurt_sound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(player_hurt_sound)

func _on_Hurtbox_invicibility_started(player_rolling):
	if(!player_rolling):
		blink_animation_player.play("Start")

func _on_Hurtbox_invicibility_ended():
	blink_animation_player.play("Stop")

func _on_give_exp(value):
	character_stats.EXP += value
	if character_stats.EXP > 10:
		character_stats.LEVEL += 1
		Events.emit_signal("lvl_changed", true);
	print(character_stats.EXP)
