extends Area2D


const HitEffect = preload("res://Effects/HitEffect.tscn")

onready var timer = $Timer
onready var collision_shape_2d = $CollisionShape2D

var invincible = false setget set_invincible
var player_rolling = false
signal invicibility_started
signal invicibility_ended

func set_invincible(value):
	invincible = value
	if invincible:
		emit_signal("invicibility_started",player_rolling)
	else:
		emit_signal("invicibility_ended")

func start_invicibility(duration,roll := false):
	timer.start(duration)
	player_rolling = roll
	self.invincible = true

func create_hit_effect():
	var effect = HitEffect.instance()
	var main = get_tree().current_scene
	main.add_child(effect)
	effect.global_position = global_position

func _on_Timer_timeout():
	player_rolling = false
	self.invincible = false

func _on_Hurtbox_invicibility_started():
	collision_shape_2d.set_deferred("disabled",true)

func _on_Hurtbox_invicibility_ended():
	collision_shape_2d.disabled =false
