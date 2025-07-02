extends Node

# Nakama Server Configuration (VPS SPECIFIC)
const SERVER_KEY : String = "defaultkey"  
const SCHEME : String = "http"                     # Use "https" if SSL configured
const HOST : String = "englishplatform.duckdns.org" 
const PORT : int = 7350                           # Default Nakama port
const TIMEOUT : int = 3                           # ARM64-optimized timeout
const SESSION_FILE : String = "user://nakama_session.dat"
const SESSION_REFRESH_BUFFER : int = 300  # Refresh tokens 5 mins before expiry
const AUTH_TIMEOUT : int = 5  # ARM64-optimized timeout
const DEFAULT_USERNAME : String = "Player_%s"  # %s will be replaced by email prefix
const SOCKET_TIMEOUT_ARM64: int = 15  # Increased for Ampere CPU
const SOCKET_RETRY_DELAY_MS: int = 3000  # 3-second retry delay

# Debug Settings
const DEBUG_MODE : bool = true  

func _to_string() -> String:
	return "ServerConfig(Host=%s, Port=%d)" % [HOST, PORT]
