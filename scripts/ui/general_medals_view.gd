class_name GeneralMedalsView
extends Control

# Procedural portrait of the Sovereign General whose dress uniform starts completely bare
# and becomes farcically overburdened with gleaming ribbons & medals — spilling from his
# left chest across his right chest, down his ceremonial sash, onto his sleeves, down onto
# his trousers below his belt, and finally right onto the front of his peaked cap!

signal medal_selected(medal_id: String)

var unlocked_ids: Array[String] = []
var selected_medal_id: String = ""
var hovered_medal_id: String = ""
var avatar_style: String = "male" # "male" or "female" (both proudly keep the exact same magnificent moustache!)
var _time: float = 0.0
var _redraw_accum: float = 0.0
var _placed_medals: Array[Dictionary] = [] # { "id": String, "pos": Vector2, "scale": float, "rot": float, "def": Dictionary }

# 36 escalating placement slots in normalized coordinates relative to the General's torso center (cx, cy)
# and unit scale `s`. Order of slots = comedic escalation as more medals are unlocked!
#   Slots 00..07: Left chest (respectable 2x4 rows)
#   Slots 08..15: Right chest (heavy 2x4 rows)
#   Slots 16..21: Lower torso creeping down to the leather belt
#   Slots 22..25: Directly across the diagonal crimson sash & lapels
#   Slots 26..29: Pinned onto left & right sleeves / shoulders
#   Slots 30..33: Pinned onto his TROUSERS below the belt!
#   Slots 34..35: Pinned directly onto the front of his PEAKED CAP!
const MEDAL_SLOTS: Array[Array] = [
	# 0-3: Left chest row 1 (viewer's right side of coat = General's left chest)
	[0.14, -0.14, 0.96, 0.0],
	[0.24, -0.14, 0.96, 0.0],
	[0.34, -0.14, 0.96, 0.0],
	[0.44, -0.13, 0.94, 0.03],
	# 4-7: Left chest row 2
	[0.14, -0.02, 0.96, 0.0],
	[0.24, -0.02, 0.96, 0.0],
	[0.34, -0.02, 0.96, 0.0],
	[0.44, -0.01, 0.94, 0.04],
	# 8-11: Right chest row 1 (viewer's left side of coat)
	[-0.14, -0.14, 0.96, 0.0],
	[-0.24, -0.14, 0.96, 0.0],
	[-0.34, -0.14, 0.96, 0.0],
	[-0.44, -0.13, 0.94, -0.03],
	# 12-15: Right chest row 2
	[-0.14, -0.02, 0.96, 0.0],
	[-0.24, -0.02, 0.96, 0.0],
	[-0.34, -0.02, 0.96, 0.0],
	[-0.44, -0.01, 0.94, -0.04],
	# 16-21: Lower torso rows above belt (overcrowding!)
	[0.16, 0.11, 0.94, 0.02],
	[0.27, 0.11, 0.94, -0.02],
	[0.38, 0.11, 0.92, 0.04],
	[-0.16, 0.11, 0.94, -0.02],
	[-0.27, 0.11, 0.94, 0.02],
	[-0.38, 0.11, 0.92, -0.04],
	# 22-25: Lapels & center sash overflow
	[0.04, -0.16, 0.92, 0.06],
	[-0.04, -0.05, 0.92, -0.05],
	[0.05, 0.07, 0.92, 0.05],
	[-0.05, 0.18, 0.90, -0.06],
	# 26-29: Left & right sleeves / shoulders!
	[0.57, -0.08, 0.88, 0.14],
	[-0.57, -0.08, 0.88, -0.14],
	[0.61, 0.06, 0.88, 0.16],
	[-0.61, 0.06, 0.88, -0.16],
	# 30-33: TROUSERS below the belt (full North Korean general satire!)
	[0.15, 0.36, 0.94, 0.03],
	[0.29, 0.36, 0.94, -0.03],
	[-0.15, 0.36, 0.94, -0.03],
	[-0.29, 0.36, 0.94, 0.03],
	# 34-35: Directly pinned onto the PEAKED CAP!
	[-0.15, -0.68, 0.80, -0.10],
	[0.15, -0.68, 0.80, 0.10],
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_medals(ids: Array[String], selected_id: String = "") -> void:
	unlocked_ids = ids.duplicate()
	selected_medal_id = selected_id
	_rebuild_layout()
	queue_redraw()

func set_selected_medal(medal_id: String) -> void:
	selected_medal_id = medal_id
	queue_redraw()

func set_avatar_style(style: String) -> void:
	avatar_style = "female" if style == "female" else "male"
	queue_redraw()

func _process(delta: float) -> void:
	if not visible or unlocked_ids.is_empty():
		return
	var real_delta: float = delta / maxf(0.01, Engine.time_scale)
	_time += real_delta
	if unlocked_ids.size() >= 12:
		_redraw_accum += real_delta
		if _redraw_accum >= 0.066:
			_redraw_accum = 0.0
			queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild_layout()
		queue_redraw()

func _get_anchor_and_scale() -> Dictionary:
	var w := size.x
	var h := size.y
	var s := minf(w * 0.56, h * 0.58)
	var cx := w * 0.5
	var cy := h * 0.56
	return {"cx": cx, "cy": cy, "s": s}

func _rebuild_layout() -> void:
	_placed_medals.clear()
	var g := _get_anchor_and_scale()
	var cx: float = g["cx"]
	var cy: float = g["cy"]
	var s: float = g["s"]

	for i in range(mini(unlocked_ids.size(), MEDAL_SLOTS.size())):
		var mid: String = unlocked_ids[i]
		var def := MedalData.get_medal_by_id(mid)
		if def.is_empty():
			continue
		var slot: Array = MEDAL_SLOTS[i]
		var pos := Vector2(cx + float(slot[0]) * s, cy + float(slot[1]) * s)
		_placed_medals.append({
			"id": mid,
			"pos": pos,
			"scale": float(slot[2]) * (s / 245.0),
			"rot": float(slot[3]),
			"def": def,
			"index": i,
		})

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		var hit := _hit_test(event.position)
		if hit != hovered_medal_id:
			hovered_medal_id = hit
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hit != "" else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var is_touch_tap: bool = (event.device == InputEvent.DEVICE_ID_EMULATION) or DisplayServer.is_touchscreen_available()
		var hit := _hit_test(event.position, 1.45 if is_touch_tap else 1.0)
		if is_touch_tap:
			hovered_medal_id = ""
		if hit != "":
			selected_medal_id = hit
			medal_selected.emit(hit)
			queue_redraw()

func _hit_test(p: Vector2, radius_mult: float = 1.0) -> String:
	# Search in reverse so frontmost medals take priority
	for i in range(_placed_medals.size() - 1, -1, -1):
		var m: Dictionary = _placed_medals[i]
		var pos: Vector2 = m["pos"]
		var r: float = 18.0 * float(m["scale"]) * radius_mult
		if p.distance_to(pos) <= r:
			return String(m["id"])
	return ""

func _draw() -> void:
	if _placed_medals.size() != mini(unlocked_ids.size(), MEDAL_SLOTS.size()):
		_rebuild_layout()
	var g := _get_anchor_and_scale()
	var cx: float = g["cx"]
	var cy: float = g["cy"]
	var s: float = g["s"]

	# Background portrait frame (warm dark military command backdrop with subtle radial spotlight)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.08, 0.07, 1.0))
	for k in range(5, 0, -1):
		var rad := s * (0.35 + float(k) * 0.22)
		draw_circle(Vector2(cx, cy - s * 0.14), rad, Color(0.14, 0.18, 0.14, 0.08))

	# Subtle sunburst rays behind the General when heavily decorated (12+ medals!)
	if unlocked_ids.size() >= 12:
		var ray_alpha: float = clampf(float(unlocked_ids.size() - 10) / 26.0, 0.05, 0.24)
		var ray_center := Vector2(cx, cy - s * 0.20)
		for i in range(16):
			var ang := float(i) * (TAU / 16.0) + _time * 0.06
			var a1 := ang - 0.065
			var a2 := ang + 0.065
			var ray_r := s * 1.15
			var pts := PackedVector2Array([
				ray_center,
				ray_center + Vector2(cos(a1), sin(a1)) * ray_r,
				ray_center + Vector2(cos(a2), sin(a2)) * ray_r,
			])
			draw_colored_polygon(pts, Color(0.98, 0.82, 0.28, ray_alpha))

	# Comedic subtle posture sag when overburdened with 15+ kg of hardware!
	var droop: float = clampf(float(unlocked_ids.size() - 12) * 0.45, 0.0, 10.0)
	_draw_general_uniform(cx, cy + droop * 0.35, s)

	# Draw all pinned medals on top of the General!
	for i in range(_placed_medals.size()):
		var m: Dictionary = _placed_medals[i]
		var mid: String = String(m["id"])
		var is_sel: bool = (mid == selected_medal_id)
		var is_hov: bool = (mid == hovered_medal_id)
		var pos: Vector2 = m["pos"]
		pos.y += droop * 0.35
		_draw_single_medal(pos, float(m["scale"]), float(m["rot"]), m["def"], is_sel, is_hov, i)

	# Empty chest joke plaque when 0 medals earned
	if unlocked_ids.is_empty():
		var msg := "CHEST TRAGICALLY UNDECORATED"
		var font := ThemeDB.fallback_font
		var tw := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_CENTER, -1, 13).x
		var pill_rect := Rect2(cx - tw * 0.5 - 12, cy - 12, tw + 24, 24)
		draw_rect(pill_rect, Color(0.06, 0.07, 0.06, 0.82))
		draw_rect(pill_rect, Color(0.70, 0.58, 0.28, 0.7), false, 1.0)
		draw_string(font, Vector2(cx - tw * 0.5, cy + 5), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.78, 0.52))

	# Outer portrait gold trim
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.75, 0.62, 0.28, 0.55), false, 2.0)

func _draw_general_uniform(cx: float, cy: float, s: float) -> void:
	var coat_main := Color(0.24, 0.29, 0.20)
	var coat_dark := Color(0.16, 0.20, 0.14)
	var coat_light := Color(0.30, 0.36, 0.25)
	var pants_col := Color(0.18, 0.22, 0.16)
	var gold := Color(0.95, 0.78, 0.26)
	var crimson := Color(0.72, 0.16, 0.16)
	var skin := Color(0.86, 0.70, 0.56)
	var skin_shade := Color(0.74, 0.56, 0.44)
	var is_female := (avatar_style == "female")

	# 1. Trousers (male) OR Regulation Dress Skirt (female) — where medals 31-34 overflow!
	if is_female:
		var skirt := PackedVector2Array([
			Vector2(cx - 0.44 * s, cy + 0.24 * s),
			Vector2(cx + 0.44 * s, cy + 0.24 * s),
			Vector2(cx + 0.54 * s, cy + 0.75 * s),
			Vector2(cx - 0.54 * s, cy + 0.75 * s),
		])
		draw_colored_polygon(skirt, pants_col)
		# Crisp center box-pleat shading
		var pleat := PackedVector2Array([
			Vector2(cx - 0.06 * s, cy + 0.26 * s),
			Vector2(cx + 0.06 * s, cy + 0.26 * s),
			Vector2(cx + 0.09 * s, cy + 0.75 * s),
			Vector2(cx - 0.09 * s, cy + 0.75 * s),
		])
		draw_colored_polygon(pleat, pants_col.darkened(0.16))
		draw_line(Vector2(cx, cy + 0.26 * s), Vector2(cx, cy + 0.75 * s), Color(0.10, 0.12, 0.09), 1.4)
		# Ceremonial crimson dress piping along the skirt sides
		draw_line(Vector2(cx - 0.43 * s, cy + 0.25 * s), Vector2(cx - 0.52 * s, cy + 0.75 * s), crimson, maxf(2.0, s * 0.018))
		draw_line(Vector2(cx + 0.43 * s, cy + 0.25 * s), Vector2(cx + 0.52 * s, cy + 0.75 * s), crimson, maxf(2.0, s * 0.018))
	else:
		var leg_l := PackedVector2Array([
			Vector2(cx - 0.44 * s, cy + 0.24 * s),
			Vector2(cx - 0.02 * s, cy + 0.24 * s),
			Vector2(cx - 0.04 * s, cy + 0.75 * s),
			Vector2(cx - 0.48 * s, cy + 0.75 * s),
		])
		var leg_r := PackedVector2Array([
			Vector2(cx + 0.02 * s, cy + 0.24 * s),
			Vector2(cx + 0.44 * s, cy + 0.24 * s),
			Vector2(cx + 0.48 * s, cy + 0.75 * s),
			Vector2(cx + 0.04 * s, cy + 0.75 * s),
		])
		draw_colored_polygon(leg_l, pants_col)
		draw_colored_polygon(leg_r, pants_col)
		# Red dress trouser stripes
		draw_line(Vector2(cx - 0.43 * s, cy + 0.25 * s), Vector2(cx - 0.46 * s, cy + 0.75 * s), crimson, maxf(2.0, s * 0.018))
		draw_line(Vector2(cx + 0.43 * s, cy + 0.25 * s), Vector2(cx + 0.46 * s, cy + 0.75 * s), crimson, maxf(2.0, s * 0.018))

	# 1.5. Regulation Ponytail peeking out behind the head/ear (female avatar — drawn behind head)
	if is_female:
		var hair_col := Color(0.26, 0.24, 0.23)
		var hair_dark := Color(0.18, 0.16, 0.16)
		var hair_hi := Color(0.38, 0.34, 0.32)
		# Gathered hair peeking subtly behind both temples under the cap
		draw_circle(Vector2(cx - 0.155 * s, cy - 0.52 * s), 0.042 * s, hair_col)
		draw_circle(Vector2(cx + 0.155 * s, cy - 0.52 * s), 0.042 * s, hair_col)
		# Compact S-curved ponytail tucked close to the neck with a tapered curl at the bottom
		var pony := PackedVector2Array([
			Vector2(cx + 0.14 * s, cy - 0.48 * s),
			Vector2(cx + 0.20 * s, cy - 0.49 * s),
			Vector2(cx + 0.245 * s, cy - 0.44 * s),
			Vector2(cx + 0.245 * s, cy - 0.37 * s),
			Vector2(cx + 0.28 * s, cy - 0.325 * s), # outward curl at tip
			Vector2(cx + 0.24 * s, cy - 0.305 * s),
			Vector2(cx + 0.195 * s, cy - 0.33 * s),
			Vector2(cx + 0.175 * s, cy - 0.39 * s),
			Vector2(cx + 0.155 * s, cy - 0.44 * s),
		])
		draw_colored_polygon(pony, hair_col)
		draw_polyline(pony, hair_dark, 1.2, true)
		# Subtle curved hair strand highlight following the flick
		var strand := PackedVector2Array([
			Vector2(cx + 0.195 * s, cy - 0.455 * s),
			Vector2(cx + 0.22 * s, cy - 0.40 * s),
			Vector2(cx + 0.225 * s, cy - 0.355 * s),
			Vector2(cx + 0.258 * s, cy - 0.322 * s),
		])
		draw_polyline(strand, hair_hi, maxf(1.4, s * 0.011))
		# Small neat crimson & gold hair tie right behind the ear
		draw_circle(Vector2(cx + 0.175 * s, cy - 0.468 * s), maxf(2.6, s * 0.019), crimson)
		draw_arc(Vector2(cx + 0.175 * s, cy - 0.468 * s), maxf(2.6, s * 0.019), 0.0, TAU, 12, gold, 1.2)

	# 2. Sleeves / Arms (where medals 27-30 overflow!)
	var sleeve_l := PackedVector2Array([
		Vector2(cx - 0.50 * s, cy - 0.26 * s),
		Vector2(cx - 0.68 * s, cy - 0.16 * s),
		Vector2(cx - 0.74 * s, cy + 0.34 * s),
		Vector2(cx - 0.50 * s, cy + 0.34 * s),
	])
	var sleeve_r := PackedVector2Array([
		Vector2(cx + 0.50 * s, cy - 0.26 * s),
		Vector2(cx + 0.68 * s, cy - 0.16 * s),
		Vector2(cx + 0.74 * s, cy + 0.34 * s),
		Vector2(cx + 0.50 * s, cy + 0.34 * s),
	])
	draw_colored_polygon(sleeve_l, coat_dark)
	draw_colored_polygon(sleeve_r, coat_dark)
	draw_polyline(sleeve_l, Color(0.10, 0.12, 0.09), 1.5, true)
	draw_polyline(sleeve_r, Color(0.10, 0.12, 0.09), 1.5, true)

	# 3. Broad Dress Coat Torso
	var torso := PackedVector2Array([
		Vector2(cx - 0.54 * s, cy - 0.28 * s),
		Vector2(cx + 0.54 * s, cy - 0.28 * s),
		Vector2(cx + 0.48 * s, cy + 0.27 * s),
		Vector2(cx - 0.48 * s, cy + 0.27 * s),
	])
	draw_colored_polygon(torso, coat_main)
	# Subtle chest highlight panels
	draw_rect(Rect2(cx - 0.47 * s, cy - 0.24 * s, 0.41 * s, 0.45 * s), coat_light.darkened(0.08))
	draw_rect(Rect2(cx + 0.06 * s, cy - 0.24 * s, 0.41 * s, 0.45 * s), coat_light.darkened(0.08))

	# 4. Ceremonial Diagonal Crimson & Gold Sash
	var sash := PackedVector2Array([
		Vector2(cx + 0.34 * s, cy - 0.28 * s),
		Vector2(cx + 0.45 * s, cy - 0.28 * s),
		Vector2(cx - 0.34 * s, cy + 0.25 * s),
		Vector2(cx - 0.46 * s, cy + 0.25 * s),
	])
	draw_colored_polygon(sash, crimson)
	draw_line(Vector2(cx + 0.34 * s, cy - 0.28 * s), Vector2(cx - 0.46 * s, cy + 0.25 * s), gold, maxf(1.5, s * 0.012))
	draw_line(Vector2(cx + 0.45 * s, cy - 0.28 * s), Vector2(cx - 0.34 * s, cy + 0.25 * s), gold, maxf(1.5, s * 0.012))

	# 5. Shirt V-Neck, Tie & Lapels
	var vneck := PackedVector2Array([
		Vector2(cx - 0.14 * s, cy - 0.30 * s),
		Vector2(cx + 0.14 * s, cy - 0.30 * s),
		Vector2(cx, cy - 0.08 * s),
	])
	draw_colored_polygon(vneck, Color(0.88, 0.88, 0.82))
	var tie := PackedVector2Array([
		Vector2(cx - 0.03 * s, cy - 0.27 * s),
		Vector2(cx + 0.03 * s, cy - 0.27 * s),
		Vector2(cx + 0.04 * s, cy - 0.14 * s),
		Vector2(cx, cy - 0.09 * s),
		Vector2(cx - 0.04 * s, cy - 0.14 * s),
	])
	draw_colored_polygon(tie, Color(0.16, 0.18, 0.15))

	# Coat lapels
	var lapel_l := PackedVector2Array([
		Vector2(cx - 0.14 * s, cy - 0.30 * s),
		Vector2(cx - 0.25 * s, cy - 0.24 * s),
		Vector2(cx - 0.17 * s, cy - 0.16 * s),
		Vector2(cx, cy - 0.08 * s),
	])
	var lapel_r := PackedVector2Array([
		Vector2(cx + 0.14 * s, cy - 0.30 * s),
		Vector2(cx + 0.25 * s, cy - 0.24 * s),
		Vector2(cx + 0.17 * s, cy - 0.16 * s),
		Vector2(cx, cy - 0.08 * s),
	])
	draw_colored_polygon(lapel_l, coat_light)
	draw_colored_polygon(lapel_r, coat_light)
	draw_line(Vector2(cx, cy - 0.08 * s), Vector2(cx, cy + 0.26 * s), coat_dark, 2.0)

	# Brass coat buttons
	for by in [-0.03, 0.06, 0.15]:
		draw_circle(Vector2(cx, cy + by * s), maxf(2.5, s * 0.018), gold)

	# 6. Gilded Shoulder Epaulets
	var ep_l := PackedVector2Array([
		Vector2(cx - 0.55 * s, cy - 0.29 * s),
		Vector2(cx - 0.24 * s, cy - 0.31 * s),
		Vector2(cx - 0.26 * s, cy - 0.23 * s),
		Vector2(cx - 0.56 * s, cy - 0.21 * s),
	])
	var ep_r := PackedVector2Array([
		Vector2(cx + 0.55 * s, cy - 0.29 * s),
		Vector2(cx + 0.24 * s, cy - 0.31 * s),
		Vector2(cx + 0.26 * s, cy - 0.23 * s),
		Vector2(cx + 0.56 * s, cy - 0.21 * s),
	])
	draw_colored_polygon(ep_l, gold.darkened(0.12))
	draw_colored_polygon(ep_r, gold.darkened(0.12))
	draw_polyline(ep_l, gold.lightened(0.2), 1.6, true)
	draw_polyline(ep_r, gold.lightened(0.2), 1.6, true)
	# Epaulet stars
	for sx in [-0.46, -0.37, 0.37, 0.46]:
		draw_circle(Vector2(cx + sx * s, cy - 0.26 * s), maxf(2.0, s * 0.014), crimson)

	# 7. Leather Officer Belt & Brass Buckle
	draw_rect(Rect2(cx - 0.48 * s, cy + 0.21 * s, 0.96 * s, 0.068 * s), Color(0.16, 0.11, 0.08))
	draw_rect(Rect2(cx - 0.48 * s, cy + 0.21 * s, 0.96 * s, 0.068 * s), Color(0.08, 0.05, 0.04), false, 1.2)
	draw_rect(Rect2(cx - 0.065 * s, cy + 0.20 * s, 0.13 * s, 0.088 * s), gold)
	draw_rect(Rect2(cx - 0.04 * s, cy + 0.22 * s, 0.08 * s, 0.048 * s), Color(0.18, 0.12, 0.08))

	# 8. Neck & Stern Square-Jawed Head
	draw_rect(Rect2(cx - 0.095 * s, cy - 0.39 * s, 0.19 * s, 0.13 * s), skin_shade)
	var head := PackedVector2Array([
		Vector2(cx - 0.16 * s, cy - 0.58 * s),
		Vector2(cx + 0.16 * s, cy - 0.58 * s),
		Vector2(cx + 0.15 * s, cy - 0.41 * s),
		Vector2(cx + 0.08 * s, cy - 0.34 * s),
		Vector2(cx - 0.08 * s, cy - 0.34 * s),
		Vector2(cx - 0.15 * s, cy - 0.41 * s),
	])
	draw_colored_polygon(head, skin)
	# Ears
	draw_circle(Vector2(cx - 0.165 * s, cy - 0.49 * s), 0.032 * s, skin_shade)
	draw_circle(Vector2(cx + 0.165 * s, cy - 0.49 * s), 0.032 * s, skin_shade)

	# Stern eyebrows & eyes
	var hair := Color(0.22, 0.21, 0.20)
	draw_line(Vector2(cx - 0.11 * s, cy - 0.53 * s), Vector2(cx - 0.025 * s, cy - 0.515 * s), hair, maxf(2.4, s * 0.018))
	draw_line(Vector2(cx + 0.11 * s, cy - 0.53 * s), Vector2(cx + 0.025 * s, cy - 0.515 * s), hair, maxf(2.4, s * 0.018))
	draw_circle(Vector2(cx - 0.068 * s, cy - 0.495 * s), maxf(2.0, s * 0.013), Color(0.12, 0.13, 0.14))
	draw_circle(Vector2(cx + 0.068 * s, cy - 0.495 * s), maxf(2.0, s * 0.013), Color(0.12, 0.13, 0.14))
	# Nose
	draw_line(Vector2(cx, cy - 0.50 * s), Vector2(cx, cy - 0.44 * s), skin_shade, maxf(1.5, s * 0.012))
	# Magnificent pompous mustache
	var stache := PackedVector2Array([
		Vector2(cx - 0.11 * s, cy - 0.405 * s),
		Vector2(cx - 0.04 * s, cy - 0.432 * s),
		Vector2(cx, cy - 0.422 * s),
		Vector2(cx + 0.04 * s, cy - 0.432 * s),
		Vector2(cx + 0.11 * s, cy - 0.405 * s),
		Vector2(cx + 0.07 * s, cy - 0.395 * s),
		Vector2(cx, cy - 0.404 * s),
		Vector2(cx - 0.07 * s, cy - 0.395 * s),
	])
	draw_colored_polygon(stache, Color(0.28, 0.27, 0.26))
	# Resolute frown
	draw_line(Vector2(cx - 0.045 * s, cy - 0.382 * s), Vector2(cx + 0.045 * s, cy - 0.382 * s), skin_shade.darkened(0.25), maxf(1.4, s * 0.010))

	# 9. Absurdly Tall Sovereign Peaked Officer Cap (where medals 35-36 overflow!)
	var cap_crown := PackedVector2Array([
		Vector2(cx - 0.28 * s, cy - 0.72 * s),
		Vector2(cx, cy - 0.78 * s),
		Vector2(cx + 0.28 * s, cy - 0.72 * s),
		Vector2(cx + 0.20 * s, cy - 0.59 * s),
		Vector2(cx - 0.20 * s, cy - 0.59 * s),
	])
	draw_colored_polygon(cap_crown, coat_main.lightened(0.05))
	draw_polyline(cap_crown, gold, maxf(1.5, s * 0.010), true)
	# Red cap band + gold chinstrap
	draw_rect(Rect2(cx - 0.195 * s, cy - 0.635 * s, 0.39 * s, 0.045 * s), crimson)
	draw_line(Vector2(cx - 0.19 * s, cy - 0.595 * s), Vector2(cx + 0.19 * s, cy - 0.595 * s), gold, maxf(2.0, s * 0.014))
	# Shiny black visor
	var visor := PackedVector2Array([
		Vector2(cx - 0.20 * s, cy - 0.59 * s),
		Vector2(cx + 0.20 * s, cy - 0.59 * s),
		Vector2(cx + 0.16 * s, cy - 0.545 * s),
		Vector2(cx - 0.16 * s, cy - 0.545 * s),
	])
	draw_colored_polygon(visor, Color(0.08, 0.09, 0.09))
	draw_line(Vector2(cx - 0.12 * s, cy - 0.568 * s), Vector2(cx + 0.06 * s, cy - 0.568 * s), Color(0.45, 0.48, 0.52, 0.55), 1.5)
	# Center golden cap cockade star
	_draw_star(Vector2(cx, cy - 0.685 * s), 0.045 * s, 0.020 * s, 5, gold)

func _draw_single_medal(pos: Vector2, sc: float, rot: float, def: Dictionary, is_sel: bool, is_hov: bool, idx: int) -> void:
	draw_set_transform(pos, rot, Vector2(sc, sc))

	var ribbon_cols: Array = def.get("ribbon", [Color.RED, Color.GOLD, Color.RED])
	var metal: Color = def.get("metal", MedalData.GOLD)
	var shape: String = String(def.get("shape", "circle"))

	# Selection / Hover glow halo
	if is_sel or is_hov:
		var pulse := 1.0 + 0.08 * sin(_time * 6.0)
		var hcol := Color(1.0, 0.94, 0.45, 0.85) if is_sel else Color(1.0, 1.0, 1.0, 0.45)
		draw_arc(Vector2(0, 4), 17.5 * pulse, 0.0, TAU, 24, hcol, 2.2)

	# Drop shadow under medal
	draw_circle(Vector2(1.5, 9.5), 10.0, Color(0, 0, 0, 0.38))

	# Striped Military Ribbon (top)
	var rw := 16.0
	var rh := 11.0
	var r_top := -11.0
	var stripe_w := rw / float(maxi(1, ribbon_cols.size()))
	for i in range(ribbon_cols.size()):
		var rcol: Color = ribbon_cols[i]
		draw_rect(Rect2(-rw * 0.5 + float(i) * stripe_w, r_top, stripe_w + 0.4, rh), rcol)
	draw_rect(Rect2(-rw * 0.5, r_top, rw, rh), Color(0.08, 0.08, 0.08, 0.75), false, 1.0)
	# Top gold pin bar
	draw_rect(Rect2(-rw * 0.5 - 1.5, r_top - 2.0, rw + 3.0, 2.6), metal.lightened(0.15))

	# Metal Pendant / Badge below ribbon
	var pc := Vector2(0, 8.5)
	if shape == "bar":
		# Extra ornate enameled ribbon clasp bar
		draw_rect(Rect2(-11.0, 2.0, 22.0, 8.5), metal)
		draw_rect(Rect2(-8.5, 4.0, 17.0, 4.5), ribbon_cols[0])
		draw_circle(Vector2(0, 6.2), 2.6, metal.lightened(0.25))
	elif shape == "star":
		_draw_star(pc, 11.5, 5.2, 5, metal)
		_draw_star(pc, 5.5, 2.6, 5, metal.lightened(0.32))
	elif shape == "sunburst":
		_draw_star(pc, 12.2, 7.2, 10, metal)
		draw_circle(pc, 5.5, ribbon_cols[0])
		draw_circle(pc, 2.8, metal.lightened(0.35))
	elif shape == "cross":
		var arm := 4.4
		var len_c := 10.5
		draw_rect(Rect2(pc.x - arm * 0.5, pc.y - len_c, arm, len_c * 2.0), metal)
		draw_rect(Rect2(pc.x - len_c, pc.y - arm * 0.5, len_c * 2.0, arm), metal)
		draw_circle(pc, 3.8, ribbon_cols[0])
		draw_circle(pc, 1.8, metal.lightened(0.3))
	elif shape == "shield":
		var sh := PackedVector2Array([
			pc + Vector2(-8.5, -8.5),
			pc + Vector2(8.5, -8.5),
			pc + Vector2(7.5, 2.0),
			pc + Vector2(0.0, 10.5),
			pc + Vector2(-7.5, 2.0),
		])
		draw_colored_polygon(sh, metal)
		draw_polyline(sh, metal.darkened(0.35), 1.2, true)
		draw_circle(pc + Vector2(0, -1.0), 3.6, ribbon_cols[0])
	elif shape == "diamond":
		var dm := PackedVector2Array([
			pc + Vector2(0, -10.8),
			pc + Vector2(9.2, 0),
			pc + Vector2(0, 10.8),
			pc + Vector2(-9.2, 0),
		])
		draw_colored_polygon(dm, metal)
		draw_polyline(dm, metal.lightened(0.3), 1.2, true)
		draw_circle(pc, 3.6, ribbon_cols[0])
	elif shape == "wings":
		var wl := PackedVector2Array([
			pc + Vector2(-2, 0),
			pc + Vector2(-13, -5),
			pc + Vector2(-11, 2),
			pc + Vector2(-2, 4),
		])
		var wr := PackedVector2Array([
			pc + Vector2(2, 0),
			pc + Vector2(13, -5),
			pc + Vector2(11, 2),
			pc + Vector2(2, 4),
		])
		draw_colored_polygon(wl, metal)
		draw_colored_polygon(wr, metal)
		draw_circle(pc, 5.2, metal.lightened(0.18))
		draw_circle(pc, 2.8, ribbon_cols[0])
	else:
		# Classic circular medallion
		draw_circle(pc, 9.6, metal)
		draw_arc(pc, 9.6, 0.0, TAU, 18, metal.darkened(0.3), 1.2)
		draw_circle(pc, 6.2, metal.lightened(0.22))
		_draw_star(pc, 4.4, 2.0, 5, ribbon_cols[0])

	# Periodic gleaming sparkle glint across medals
	var phase := fmod(_time * 1.4 + float(idx) * 0.73, 4.2)
	if phase < 0.35:
		var a := sin((phase / 0.35) * PI)
		var sp := pc + Vector2(-3.5, -3.5)
		var glen := 5.5 * a
		draw_line(sp - Vector2(glen, 0), sp + Vector2(glen, 0), Color(1, 1, 1, a * 0.9), 1.4)
		draw_line(sp - Vector2(0, glen), sp + Vector2(0, glen), Color(1, 1, 1, a * 0.9), 1.4)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_star(center: Vector2, outer_r: float, inner_r: float, points: int, col: Color) -> void:
	var pts := PackedVector2Array()
	var total := points * 2
	for i in range(total):
		var r := outer_r if (i % 2 == 0) else inner_r
		var a := -PI * 0.5 + float(i) * (TAU / float(total))
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)
