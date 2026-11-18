class_name PlayerMessages
extends RefCounted
## Maps internal reason codes (StringName) to translation keys. The only place a failure code
## becomes player text. Unknown codes fall back to a safe generic message, never the code itself.

const SAVE_REASON_KEYS := {
	&"write_failed": "MSG_SAVE_FAILED",
	&"not_allowed_now": "MSG_SAVE_FAILED",
	&"unknown_slot": "MSG_SAVE_FAILED",
	&"newer_version": "MSG_SAVE_NEWER_VERSION",
	&"corrupt": "MSG_SAVE_CORRUPT",
	&"recovered": "MSG_SAVE_RECOVERED",
}

const ROUTE_REASON_KEYS := {
	&"unknown_route": "MSG_SCREEN_FAILED",
	&"load_failed": "MSG_SCREEN_FAILED",
}


static func save_message(reason: StringName) -> String:
	return TranslationServer.translate(SAVE_REASON_KEYS.get(reason, "MSG_SAVE_FAILED"))


static func route_message(reason: StringName) -> String:
	return TranslationServer.translate(ROUTE_REASON_KEYS.get(reason, "MSG_SCREEN_FAILED"))
