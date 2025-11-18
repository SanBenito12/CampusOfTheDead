extends Control

const ARENA_SCENE := preload("res://scenes/arena/arena.tscn")

@onready var play_button: Button = $VBoxContainer/PlayButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(ARENA_SCENE)
