class_name SeasonalData
extends RefCounted

# Extensible registry of secret seasonal levels.
# Add future seasonal events (Halloween, Easter, Summer, etc.) here!

const RANDOM_INTERCEPT_CHANCE: float = 0.05

static func get_active_seasonal_event() -> Dictionary:
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var month: int = int(dt.get("month", 1))
	var day: int = int(dt.get("day", 1))

	# Christmas Season: November 20 through January 6 (12 days after Christmas!)
	var is_christmas_window: bool = (month == 11 and day >= 20) or (month == 12) or (month == 1 and day <= 6)
	if is_christmas_window:
		return {
			"id": "christmas",
			"map_id": "north_pole",
			"title": "OPERATION TINSEL STORM",
			"banner": "★ NORTH POLE SIGNAL INTERCEPTED — OPERATION TINSEL STORM! ★",
			"hint": "★ SEASONAL INTERCEPT DETECTED ON NORTH POLE FREQUENCIES ★",
			"codes": ["HOHOHO", "XMAS", "SANTA"],
			"accent": Color(0.96, 0.28, 0.26),
		}

	return {}

static func is_any_season_active() -> bool:
	return not get_active_seasonal_event().is_empty()

static func check_secret_code(typed_buffer: String) -> String:
	var upper: String = typed_buffer.to_upper()
	# Always allow checking registered seasonal codes (even outside season for testing if desired,
	# or prioritize the active seasonal event).
	var active := get_active_seasonal_event()
	if not active.is_empty():
		for code in active["codes"]:
			if upper.ends_with(String(code)):
				return String(active["map_id"])
	if upper.ends_with("HOHOHO") or upper.ends_with("XMAS"):
		return "north_pole"
	return ""
