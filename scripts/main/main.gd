extends Node2D

@onready var title_label: Label = $UI/Title


func _ready() -> void:
	title_label.text = "Bound Souls"
