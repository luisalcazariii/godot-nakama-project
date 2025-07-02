extends Control
class_name AuthController

var _auth_handler: AuthenticationHandler

@onready var email_input: LineEdit = $VBoxContainer/EmailInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var login_button: Button = $VBoxContainer/LoginButton
@onready var error_panel: ColorRect = $ErrorPanel
@onready var error_label: Label = $ErrorPanel/Label

func _ready():
	# Use the autoload name directly (no "/root/" needed if it's an autoload)
	_auth_handler = get_node("/root/ESLNakamaConnection")._auth_handler
	if _auth_handler == null:
		push_error("AuthenticationHandler not found! Check NakamaConnection initialization.")
		return
	_auth_handler.login_success.connect(_on_login_success)
	_auth_handler.login_failed.connect(_on_login_failed)
	login_button.pressed.connect(_on_login_pressed)

func _on_login_pressed():
	var email = email_input.text.strip_edges()
	var password = password_input.text
	if email.is_empty() or password.is_empty():
		status_label.text = "Please fill all fields!"
		return
	
	status_label.text = "Logging in..."
	login_button.disabled = true
	
	# Replace the TODO with this:
	await _auth_handler.login_email(email, password)  # This triggers the signals

func _on_login_success(_session: NakamaSession):
	status_label.text = "Success! Loading..."
	# Wait 1 second to simulate loading (optional)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu/menu_screen.tscn")

func _on_login_failed(error: String):
	status_label.text = ""
	error_label.text = error
	error_panel.visible = true
	login_button.disabled = false

	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	error_panel.visible = false
