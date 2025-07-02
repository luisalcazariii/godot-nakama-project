# menu_controller.gd
extends Control
class_name MenuController

@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var logout_button: Button = $VBoxContainer/LogoutButton

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	update_status()

func update_status():
	var session = get_node("/root/ESLNakamaConnection")._current_session
	status_label.text = "Logged in as: %s" % session.username

func _on_play_pressed():
	print("Matchmaking will be implemented in Section 3!")

func _on_logout_pressed():
	logout_button.disabled = true  # Prevent double-click
	await get_node("/root/ESLNakamaConnection").logout()
	get_tree().change_scene_to_file("res://scenes/authentication/auth_screen.tscn")
