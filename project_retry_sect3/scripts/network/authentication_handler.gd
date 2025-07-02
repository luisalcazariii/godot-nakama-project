extends Node
class_name AuthenticationHandler

signal login_success(session : NakamaSession)
signal login_failed(error : String)

var _client: NakamaClient
var _session_manager: SessionManager
var _server_config = preload("res://scripts/network/network_constants.gd").new()  # Added this line

func initialize(client: NakamaClient, session_manager: SessionManager) -> void:
	_client = client
	_session_manager = session_manager

func login_email(email: String, password: String) -> void:
	var username = _server_config.DEFAULT_USERNAME % email.split("@")[0]

	var session: NakamaSession = await _client.authenticate_email_async(
		email, password, username, true
	)

	if session.is_exception():
		var error_msg = "Login failed"
		match session.get_exception().grpc_status_code:
			-1: error_msg = "Network error - check connection"
			5:  error_msg = "Account not found"  # GRPC NotFound
			16: error_msg = "Invalid credentials"  # GRPC Unauthenticated
		login_failed.emit(error_msg)
	else:
		_session_manager.save_session(session)
		login_success.emit(session)
