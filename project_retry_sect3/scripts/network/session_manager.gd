extends Node
class_name SessionManager

@onready var _server_config = preload("res://scripts/network/network_constants.gd").new()

signal session_restored
signal session_refreshed
signal session_failed

var _current_session : NakamaSession

func _ready():
	# Verify config loaded
	if not _server_config:
		push_error("Failed to load network constants!")
		return

# Load saved session from disk
func load_session() -> NakamaSession:
	if not FileAccess.file_exists(_server_config.SESSION_FILE):
		return null
	
	var file = FileAccess.open(_server_config.SESSION_FILE, FileAccess.READ)
	var token = file.get_as_text()
	file.close()
	
	var session = NakamaClient.restore_session(token)
	if session and not session.expired:
		_current_session = session
		session_restored.emit()
		return session
	return null

# Save session to disk
func save_session(session : NakamaSession) -> void:
	var file = FileAccess.open(_server_config.SESSION_FILE, FileAccess.WRITE)
	file.store_string(session.token)
	file.close()
	_current_session = session

func clear_session() -> void:
	if FileAccess.file_exists(_server_config.SESSION_FILE):
		DirAccess.remove_absolute(_server_config.SESSION_FILE)
	_current_session = null

# Refresh before expiry
func try_refresh_session(client: NakamaClient) -> bool:
	if not _current_session or _current_session.expired:
		return false

	if _current_session.would_expire_in(_server_config.SESSION_REFRESH_BUFFER):
		var new_session = await client.session_refresh_async(_current_session)
		if not new_session.is_exception():
			save_session(new_session)
			return true
	return false
