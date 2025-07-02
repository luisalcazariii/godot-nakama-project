extends Node
class_name NakamaConnection

var _client : NakamaClient  
var _socket : NakamaSocket  
var _current_session: NakamaSession  # Add this with other variable declarations
var _is_connected : bool = false
var _reconnect_attempts : int = 0
const MAX_RECONNECT_ATTEMPTS : int = 3

@onready var _server_config = preload("res://scripts/network/network_constants.gd").new()
@onready var _session_manager = preload("res://scripts/network/session_manager.gd").new()
@onready var _auth_handler = preload("res://scripts/network/authentication_handler.gd").new()

func _ready() -> void:
	# Initialize dependencies in correct order
	_initialize_client()
	add_child(_session_manager)
	add_child(_auth_handler)

	# Proper dependency injection
	_auth_handler.initialize(_client, _session_manager)
	_auth_handler.login_success.connect(_on_login_success)

	_try_restore_session()

func _initialize_client() -> void:
	# Create client (ARM64-compatible)
	_client = Nakama.create_client(
		_server_config.SERVER_KEY,
		_server_config.HOST,
		_server_config.PORT,
		_server_config.SCHEME,
		_server_config.TIMEOUT
	)
	
	if _server_config.DEBUG_MODE:
		print("=== NAKAMA CLIENT INITIALIZED ===")
		print("Scheme: ", _server_config.SCHEME)
		print("Host: ", _server_config.HOST)
		print("Port: ", _server_config.PORT)

func _initialize_socket() -> void:
	if _socket:  # Skip if socket exists
		return

	_socket = Nakama.create_socket_from(_client)
	if _server_config.DEBUG_MODE:
		_socket.logger._level = NakamaLogger.LOG_LEVEL.DEBUG
	_setup_socket_signals()
	print("=== NAKAMA SOCKET INITIALIZED ===")  # Single print

func _setup_socket_signals() -> void:
	_socket.closed.connect(_on_socket_closed)
	_socket.connected.connect(_on_socket_connected)
	_socket.received_error.connect(_on_socket_error)

func _on_socket_connected() -> void:
	_is_connected = true
	_reconnect_attempts = 0
	print("Socket connected! Ready for multiplayer.")

func _on_socket_closed() -> void:
	_is_connected = false
	print("Socket closed. Attempting reconnect..." if _reconnect_attempts < MAX_RECONNECT_ATTEMPTS else "Permanent disconnect")

func _on_socket_error(error: NakamaException) -> void:
	push_error("Socket error (Code %d): %s" % [error.status_code, error.message])
	if _reconnect_attempts < MAX_RECONNECT_ATTEMPTS:
		await get_tree().create_timer(_server_config.SOCKET_RETRY_DELAY_MS / 1000.0).timeout
		_reconnect_attempts += 1
		await _socket.connect_async(_current_session)

func _try_restore_session() -> void:
	_current_session = _session_manager.load_session()
	if _current_session:
		print("Restored session for: ", _current_session.username)
		_initialize_socket()
		var result = await _socket.connect_async(_current_session)
		if result.is_exception():
			push_error("Failed to restore socket: ", result.get_exception().message)
	else:
		print("No saved session found")

func _on_login_success(session : NakamaSession) -> void:
	_current_session = session  # Store the active session
	print("=== AUTHENTICATION SUCCESS ===")
	print("User: ", session.username)
	print("Session expires: ", Time.get_datetime_string_from_unix_time(session.expire_time))

	if _socket:
		if _socket.is_connecting_to_host():  # Wait if connecting
			await _socket.connected
		elif _socket.is_connected_to_host():  # Close if connected
			_socket.close()
			await _socket.closed

	_initialize_socket()
	await _socket.connect_async(session)
	_print_connection_status()  # Will now show "Connected"

func logout() -> void:
	if _socket:
		_socket.close()
		await _socket.closed  # Wait for socket to close

	if _current_session:
		await _client.session_logout_async(_current_session)
		_session_manager.clear_session()
		_current_session = null

	# Delay to ensure clean transition
	await get_tree().create_timer(0.5).timeout

func _print_connection_status() -> void:
	if _client == null:
		push_error("Client not initialized!")
		return

	print("\n" + "=".repeat(20))
	print("CONNECTION STATUS")
	print("-".repeat(20))
	print("Client: ", _client)
	print("Socket: ", "Connected" if _is_connected else "Disconnected")
	print("=".repeat(20) + "\n")
