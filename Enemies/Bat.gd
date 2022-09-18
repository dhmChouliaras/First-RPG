extends KinematicBody2D

onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var animated_sprite = $AnimatedSprite
onready var hurtbox = $Hurtbox
onready var soft_collision = $SoftCollision
onready var wander_controller = $WanderController
onready var animation_player = $AnimationPlayer

signal give_exp(value)

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO
const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var WANDER_TARGET_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE
}

var state = IDLE

func _ready():
	animated_sprite.frame = rand_range(0, 4)
	state = pick_random_state([IDLE,WANDER])

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO,FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO,FRICTION * delta)
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander_timer()
		
		WANDER:
			seek_player()
			if wander_controller.get_time_left() == 0:
				update_wander_timer()
			accelerate_towards_point(wander_controller.target_position,delta)
			
			if global_position.distance_to(wander_controller.target_position) <= WANDER_TARGET_RANGE:
				update_wander_timer()
		
		CHASE: 
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(player.global_position,delta)
			else:
				state = IDLE
			animated_sprite.flip_h = velocity.x < 0 
	
	if soft_collision.is_colliding():
		velocity += soft_collision.get_push_vector() * delta * 1000
	velocity = move_and_slide(velocity)

func update_wander_timer():
	state = pick_random_state([IDLE,WANDER])
	wander_controller.start_wander_timer(rand_range(1,3))

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	animated_sprite.flip_h = velocity.x < 0 

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func _on_Hurtbox_area_entered(area):
	stats.health -=area.damage
	knockback = area.knockback_vector * 120
	hurtbox.create_hit_effect()
	hurtbox.start_invicibility(0.4)

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
	Events.emit_signal("give_exp", 10);

func _on_Hurtbox_invicibility_started():
	animation_player.play("Start")

func _on_Hurtbox_invicibility_ended():
	animation_player.play("Stop")


