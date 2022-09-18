extends Control

onready var heart_ui_empty = $HeartUIEmpty
onready var heart_ui_full = $HeartUIFull

var hearts = 4 setget set_hearts
var max_hearts = 4 setget set_max_hearts



func set_hearts(value):
	hearts = clamp(value, 0 , max_hearts)
	if heart_ui_full != null:
		heart_ui_full.rect_size.x = hearts * 15

func set_max_hearts(value):
	max_hearts = max(value, 1)
	self.hearts = min(hearts, max_hearts)
	if heart_ui_empty != null:
		heart_ui_empty.rect_size.x = max_hearts * 15

func _ready():
	self.max_hearts = GlobalPlayerStats.max_health
	self.hearts = GlobalPlayerStats.health
	GlobalPlayerStats.connect("health_changed", self, "set_hearts")
	GlobalPlayerStats.connect("max_health_changed", self, "set_max_hearts")
