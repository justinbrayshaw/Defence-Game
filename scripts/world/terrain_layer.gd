class_name TerrainLayer
extends Node2D

const MASK_W: int = 200
const MASK_H: int = 120

var map_data: Dictionary = {}
var occupied_pads: Dictionary = {} # pad_index -> Turret

# Placement / hover feedback updated by GameController
var placement_active: bool = false
var placement_range: float = 0.0
var placement_affordable: bool = true
var placement_accent: Color = Color(0.25, 0.92, 0.45)
var hovered_pad_index: int = -1

var _time: float = 0.0
var _is_desert: bool = false
var _is_tundra: bool = false
var _is_mountain: bool = false
var _is_christmas: bool = false
var _is_town: bool = false
var _is_countryside: bool = false
var _is_forest: bool = false
var _is_outback: bool = false
var _trees: Array[Dictionary] = []
var _oaks: Array[Dictionary] = []
var _palms: Array[Dictionary] = []
var _shrubs: Array[Dictionary] = []
var _buildings: Array[Dictionary] = []
var _hay_bales: Array[Dictionary] = []
var _logs: Array[Dictionary] = []
var _rocks: Array[Dictionary] = []
var _shore_stones: Array[Dictionary] = []
var _ice_floes: Array[Dictionary] = []
var _snowflakes: Array[Dictionary] = []
var _snowmen: Array[Dictionary] = []
var _candy_canes: Array[Dictionary] = []
var _gift_piles: Array[Dictionary] = []
var _lanterns: Array[Vector2] = []
var _sandbags: Array[Dictionary] = []
var _bunkers: Array[Dictionary] = []
var _bg_rect: ColorRect
var _mask_tex: ImageTexture

func setup(data: Dictionary) -> void:
	map_data = data
	var biome: String = String(data.get("biome", "alpine"))
	_is_desert = (biome == "desert")
	_is_tundra = (biome == "tundra")
	_is_mountain = (biome == "mountain")
	_is_christmas = (biome == "christmas")
	_is_town = (biome == "town")
	_is_countryside = (biome == "countryside")
	_is_forest = (biome == "forest")
	_is_outback = (biome == "outback")
	_bake_map_mask()
	_setup_shader_background()
	_generate_props()
	queue_redraw()

func _get_bridges() -> Array:
	if map_data.has("bridges"):
		return map_data["bridges"]
	return [map_data["bridge_pos"]]

func _bake_map_mask() -> void:
	var img: Image = Image.create_empty(MASK_W, MASK_H, false, Image.FORMAT_RGBA8)
	var mw: float = float(map_data["width"])
	var mh: float = float(map_data["height"])
	var roads: Array = map_data["ground_coarses"]
	var river: PackedVector2Array = map_data["river_points"]
	var pads: Array = map_data["pads"]
	var base_pos: Vector2 = map_data["base_pos"]

	var bytes := PackedByteArray()
	bytes.resize(MASK_W * MASK_H * 4)

	var idx: int = 0
	for y in range(MASK_H):
		var wy: float = (float(y) + 0.5) / float(MASK_H) * mh
		for x in range(MASK_W):
			var wx: float = (float(x) + 0.5) / float(MASK_W) * mw
			var p := Vector2(wx, wy)

			var d_road: float = MapData.distance_to_polylines(p, roads)
			var d_river: float = MapData.distance_to_polyline(p, river)
			var dx_river: float = MapData.signed_x_to_river(p, river)

			var d_pad: float = p.distance_to(base_pos) * 0.55
			for pad_pos in pads:
				var dp: float = p.distance_to(pad_pos)
				if dp < d_pad:
					d_pad = dp

			var r_byte: int = clampi(int(round(clampf(d_road / 128.0, 0.0, 1.0) * 255.0)), 0, 255)
			var g_byte: int = clampi(int(round(clampf(d_river / 140.0, 0.0, 1.0) * 255.0)), 0, 255)
			var b_byte: int = clampi(int(round(clampf(d_pad / 96.0, 0.0, 1.0) * 255.0)), 0, 255)
			var a_norm: float = 0.5 + clampf(dx_river / 120.0, -0.5, 0.5)
			var a_byte: int = clampi(int(round(a_norm * 255.0)), 0, 255)

			bytes[idx] = r_byte
			bytes[idx + 1] = g_byte
			bytes[idx + 2] = b_byte
			bytes[idx + 3] = a_byte
			idx += 4

	img.set_data(MASK_W, MASK_H, false, Image.FORMAT_RGBA8, bytes)
	_mask_tex = ImageTexture.create_from_image(img)

func _setup_shader_background() -> void:
	if _bg_rect != null and is_instance_valid(_bg_rect):
		_bg_rect.queue_free()
	_bg_rect = ColorRect.new()
	_bg_rect.position = Vector2.ZERO
	_bg_rect.size = Vector2(float(map_data["width"]), float(map_data["height"]))
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_rect.z_index = -5
	var shader: Shader = load("res://shaders/terrain.gdshader")
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		var bridges: Array = _get_bridges()
		var b1: Vector2 = bridges[0] if bridges.size() >= 1 else Vector2(-9999.0, -9999.0)
		var b2: Vector2 = bridges[1] if bridges.size() >= 2 else Vector2(-9999.0, -9999.0)
		mat.set_shader_parameter("map_mask", _mask_tex)
		mat.set_shader_parameter("map_size", _bg_rect.size)
		mat.set_shader_parameter("bridge_pos", b1)
		mat.set_shader_parameter("bridge_pos_2", b2)
		mat.set_shader_parameter("biome_type", int(map_data.get("biome_id", 0)))
		_bg_rect.material = mat
	else:
		_bg_rect.color = Color(0.66, 0.72, 0.78) if _is_tundra else (Color(0.45, 0.36, 0.24) if _is_desert else Color(0.22, 0.25, 0.18))
	add_child(_bg_rect)

func _build_foliage_poly(radius: float, lobes: int, rng: RandomNumberGenerator, jag: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(lobes * 2):
		var a: float = (TAU * float(i) / float(lobes * 2)) + rng.randf_range(-0.08, 0.08)
		var r: float = radius * (rng.randf_range(0.84, 1.14) if (i % 2 == 0) else rng.randf_range(jag - 0.10, jag + 0.08))
		verts.append(Vector2(cos(a) * r, sin(a) * r))
	return verts

func _build_rock_poly(radius: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var verts := PackedVector2Array()
	var sides: int = rng.randi_range(6, 8)
	for s in range(sides):
		var ang: float = (TAU * float(s) / float(sides)) + rng.randf_range(-0.20, 0.20)
		var rad: float = radius * rng.randf_range(0.68, 1.15)
		verts.append(Vector2(cos(ang) * rad, sin(ang) * rad))
	return verts

func _near_any_bridge(pos: Vector2, pad_y: float) -> bool:
	for b in _get_bridges():
		var bp: Vector2 = b
		if absf(pos.y - bp.y) < pad_y and absf(pos.x - bp.x) < 110.0:
			return true
	return false

func _generate_props() -> void:
	_trees.clear()
	_oaks.clear()
	_palms.clear()
	_shrubs.clear()
	_buildings.clear()
	_hay_bales.clear()
	_logs.clear()
	_rocks.clear()
	_shore_stones.clear()
	_ice_floes.clear()
	_snowflakes.clear()
	_snowmen.clear()
	_candy_canes.clear()
	_gift_piles.clear()
	_lanterns.clear()
	_sandbags.clear()
	_bunkers.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = int(map_data.get("seed", 4091337))
	var w: float = float(map_data["width"])
	var h: float = float(map_data["height"])
	var roads: Array = map_data["ground_coarses"]
	var river: PackedVector2Array = map_data["river_points"]
	var pads: Array = map_data["pads"]
	var base_pos: Vector2 = map_data["base_pos"]
	var ref_bridge: Vector2 = map_data["bridge_pos"]

	# Riverbank boulders & half-submerged shoreline stones (skipped for engineered concrete town canal!)
	var shore_attempts: int = 0 if _is_town else 110
	for _i in range(shore_attempts):
		var ry: float = rng.randf_range(16.0, h - 16.0)
		var rx_center: float = ref_bridge.x + rng.randf_range(-42.0, 42.0)
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var probe := Vector2(rx_center + side * rng.randf_range(34.0, 62.0), ry)
		if _near_any_bridge(probe, 58.0):
			continue
		var d_riv: float = MapData.distance_to_polyline(probe, river)
		if d_riv < 32.0 or d_riv > 58.0:
			continue
		if MapData.distance_to_polylines(probe, roads) < MapData.ROAD_WIDTH * 0.78:
			continue
		var r: float = rng.randf_range(4.0, 10.5)
		_shore_stones.append({
			"pos": probe,
			"verts": _build_rock_poly(r, rng),
			"shade": rng.randf_range(0.75, 1.14),
			"wet": d_riv < 44.0,
		})

	if _is_tundra or _is_christmas:
		# Floating glacial / aurora ice floes drifting in the canal
		for _i in range(28):
			var iy: float = rng.randf_range(24.0, h - 24.0)
			var probe := Vector2(ref_bridge.x + rng.randf_range(-34.0, 34.0), iy)
			if _near_any_bridge(probe, 56.0):
				continue
			if MapData.distance_to_polyline(probe, river) > 30.0:
				continue
			_ice_floes.append({
				"pos": probe,
				"verts": _build_rock_poly(rng.randf_range(5.0, 11.5), rng),
				"bob_phase": rng.randf_range(0.0, TAU),
			})

		# Ambient drifting snowflakes (sparklier & denser at the North Pole!)
		var flake_count: int = 125 if _is_christmas else 95
		for _i in range(flake_count):
			_snowflakes.append({
				"x": rng.randf_range(0.0, w),
				"y": rng.randf_range(0.0, h),
				"vx": rng.randf_range(22.0, 48.0),
				"vy": rng.randf_range(38.0, 72.0),
				"r": rng.randf_range(1.1, 2.6),
				"alpha": rng.randf_range(0.28, 0.65),
				"gold": _is_christmas and rng.randf() < 0.14,
			})

	if _is_christmas:
		# Cheerful snowmen, giant candy canes, gift piles & glowing North Pole lanterns!
		var snow_candidates: Array[Vector2] = [
			Vector2(105, 480), Vector2(465, 130), Vector2(465, 830),
			Vector2(635, 145), Vector2(635, 815), Vector2(1065, 760),
			Vector2(1380, 165), Vector2(1380, 795), Vector2(1265, 410),
		]
		for sc in snow_candidates:
			_snowmen.append({"pos": sc, "ang": rng.randf_range(-0.5, 0.5)})

		var cane_candidates: Array[Vector2] = [
			Vector2(345, 140), Vector2(345, 820), Vector2(785, 150), Vector2(985, 150),
			Vector2(785, 810), Vector2(985, 810), Vector2(1425, 415), Vector2(1425, 545),
			Vector2(548, 340), Vector2(548, 620),
		]
		for cc in cane_candidates:
			_candy_canes.append({"pos": cc, "ang": rng.randf_range(-0.4, 0.4)})

		var gift_candidates: Array[Vector2] = [
			Vector2(1445, 440), Vector2(1445, 520), Vector2(1415, 345),
			Vector2(1415, 615), Vector2(552, 435), Vector2(552, 525),
		]
		for gc in gift_candidates:
			_gift_piles.append({"pos": gc, "seed": rng.randi()})

		_lanterns = [
			Vector2(795, 156), Vector2(975, 156), Vector2(795, 804), Vector2(975, 804),
			Vector2(1420, 428), Vector2(1420, 532), Vector2(455, 435), Vector2(455, 525),
		]

	if _is_desert:
		# Oasis Palm Trees clustered near the riverbanks
		for _i in range(120):
			var py: float = rng.randf_range(26.0, h - 26.0)
			var side: float = -1.0 if rng.randf() < 0.5 else 1.0
			var pos := Vector2(ref_bridge.x + side * rng.randf_range(48.0, 128.0) + rng.randf_range(-20.0, 20.0), py)
			if _near_any_bridge(pos, 62.0):
				continue
			var d_riv: float = MapData.distance_to_polyline(pos, river)
			if d_riv < 46.0 or d_riv > 125.0:
				continue
			if MapData.distance_to_polylines(pos, roads) < MapData.ROAD_WIDTH * 0.88:
				continue
			var near_pad := false
			for pad in pads:
				if pos.distance_to(pad) < 48.0:
					near_pad = true
					break
			if near_pad:
				continue
			var fronds: Array[Dictionary] = []
			var count: int = rng.randi_range(7, 9)
			var base_rot: float = rng.randf_range(0.0, TAU)
			var rad: float = rng.randf_range(16.0, 25.0)
			for f in range(count):
				var ang: float = base_rot + float(f) * (TAU / float(count)) + rng.randf_range(-0.16, 0.16)
				fronds.append({
					"ang": ang,
					"len": rad * rng.randf_range(0.80, 1.15),
					"w": rng.randf_range(3.6, 5.2),
				})
			_palms.append({
				"pos": pos,
				"fronds": fronds,
				"shade": rng.randf_range(0.84, 1.16),
			})

		for _i in range(110):
			var pos := Vector2(rng.randf_range(26.0, w - 26.0), rng.randf_range(26.0, h - 26.0))
			if pos.distance_to(base_pos) < 130.0:
				continue
			if MapData.distance_to_polylines(pos, roads) < MapData.ROAD_WIDTH * 0.86:
				continue
			if MapData.distance_to_polyline(pos, river) < MapData.RIVER_WIDTH * 0.80:
				continue
			var near_pad := false
			for pad in pads:
				if pos.distance_to(pad) < 48.0:
					near_pad = true
					break
			if near_pad:
				continue
			var r: float = rng.randf_range(6.0, 12.0)
			_shrubs.append({
				"pos": pos,
				"poly": _build_foliage_poly(r, 7, rng, 0.52),
				"shade": rng.randf_range(0.80, 1.15),
			})
	else:
		# Volumetric multi-cluster 3D conifers (Alpine green, Snow-laden Arctic spruce, or Mountain timberline pines)
		var tree_count: int = 240 if _is_mountain else (195 if _is_tundra else 215)
		for _i in range(tree_count):
			var pos := Vector2(rng.randf_range(24.0, w - 24.0), rng.randf_range(24.0, h - 24.0))
			if pos.distance_to(base_pos) < 130.0:
				continue
			var d_road: float = MapData.distance_to_polylines(pos, roads)
			var d_riv: float = MapData.distance_to_polyline(pos, river)
			if d_road < MapData.ROAD_WIDTH * 0.92:
				continue
			if d_riv < MapData.RIVER_WIDTH * 0.94:
				continue
			# On mountain maps, keep conifers tucked along lower valley slopes so towering snow peaks stay bare & dramatic!
			if _is_mountain and d_road > 125.0 and d_riv > 115.0:
				continue
			var near_pad := false
			for pad in pads:
				if pos.distance_to(pad) < 54.0:
					near_pad = true
					break
			if near_pad:
				continue
			var radius: float = rng.randf_range(11.0, 19.0) if _is_mountain else rng.randf_range(13.0, 23.0)
			var shade: float = rng.randf_range(0.82, 1.16)
			var lobes: int = rng.randi_range(8, 12)
			var sub_boughs: Array[Dictionary] = []
			for _b in range(4):
				var ba: float = rng.randf_range(0.0, TAU)
				var bd: float = radius * rng.randf_range(0.22, 0.42)
				sub_boughs.append({
					"off": Vector2(cos(ba) * bd, sin(ba) * bd),
					"r": radius * rng.randf_range(0.32, 0.48),
				})
			_trees.append({
				"pos": pos,
				"radius": radius,
				"shade": shade,
				"base_poly": _build_foliage_poly(radius, lobes, rng, 0.62),
				"mid_poly": _build_foliage_poly(radius * 0.74, lobes, rng, 0.58),
				"top_poly": _build_foliage_poly(radius * 0.48, maxi(6, lobes - 2), rng, 0.52),
				"boughs": sub_boughs,
			})

	# Clustered 3D boulders
	var rock_attempts: int = 12 if _is_town else (24 if _is_countryside else (108 if (_is_mountain or _is_outback) else (86 if _is_desert else (76 if _is_tundra else 62))))
	for _i in range(rock_attempts):
		var pos := Vector2(rng.randf_range(35.0, w - 35.0), rng.randf_range(35.0, h - 35.0))
		if pos.distance_to(base_pos) < 135.0:
			continue
		if MapData.distance_to_polylines(pos, roads) < MapData.ROAD_WIDTH * 0.88:
			continue
		if MapData.distance_to_polyline(pos, river) < MapData.RIVER_WIDTH * 0.78:
			continue
		var near_pad := false
		for pad in pads:
			if pos.distance_to(pad) < 50.0:
				near_pad = true
				break
		if near_pad:
			continue
		var r: float = rng.randf_range(11.0, 21.0) if _is_desert else rng.randf_range(10.0, 18.0)
		var sats: Array[Dictionary] = []
		for _s in range(rng.randi_range(1, 3)):
			var sa: float = rng.randf_range(0.0, TAU)
			var sd: float = r * rng.randf_range(0.85, 1.35)
			sats.append({
				"off": Vector2(cos(sa) * sd, sin(sa) * sd),
				"verts": _build_rock_poly(r * rng.randf_range(0.30, 0.48), rng),
			})
		_rocks.append({
			"pos": pos,
			"verts": _build_rock_poly(r, rng),
			"shade": rng.randf_range(0.84, 1.15),
			"sats": sats,
		})

	for sb in map_data.get("sandbags", []):
		_sandbags.append(sb)
	for bnk in map_data.get("bunkers", []):
		_bunkers.append(bnk)

	_generate_new_biome_props(rng, w, h, roads, river, pads, base_pos)

func _generate_new_biome_props(rng: RandomNumberGenerator, w: float, h: float, roads: Array, river: PackedVector2Array, pads: Array, base_pos: Vector2) -> void:
	if _is_town:
		# Replace conifers in town with crisp 3D urban buildings & a few manicured park oaks!
		_trees.clear()
		var roof_palette: Array[Color] = [
			Color(0.54, 0.25, 0.20), # Terracotta brick house
			Color(0.30, 0.33, 0.38), # Slate pitched roof
			Color(0.38, 0.39, 0.37), # Concrete flat commercial
			Color(0.46, 0.34, 0.25), # Warm brown town block
			Color(0.28, 0.30, 0.33), # Industrial roof
		]
		for _i in range(145):
			var bw: float = rng.randf_range(34.0, 68.0)
			var bh: float = rng.randf_range(26.0, 52.0)
			var pos := Vector2(rng.randf_range(50.0, w - 50.0), rng.randf_range(45.0, h - 45.0))
			var clearance: float = maxf(bw, bh) * 0.5 + 14.0
			if pos.distance_to(base_pos) < 125.0 + clearance * 0.4:
				continue
			if MapData.distance_to_polylines(pos, roads) < MapData.ROAD_WIDTH * 0.65 + clearance:
				continue
			if MapData.distance_to_polyline(pos, river) < MapData.RIVER_WIDTH * 0.62 + clearance:
				continue
			var blocked := false
			for pad in pads:
				if pos.distance_to(pad) < 34.0 + clearance:
					blocked = true
					break
			if blocked:
				continue
			for existing in _buildings:
				var ep: Vector2 = existing["pos"]
				var er: float = maxf(float(existing["w"]), float(existing["h"])) * 0.55
				if pos.distance_to(ep) < clearance + er - 4.0:
					blocked = true
					break
			if blocked:
				continue
			_buildings.append({
				"pos": pos,
				"w": bw,
				"h": bh,
				"style": rng.randi_range(0, 2), # 0=pitched, 1=flat HVAC, 2=courtyard/skylight
				"color": roof_palette[rng.randi() % roof_palette.size()],
			})
		# Manicured park oak trees in remaining urban clearings
		for _i in range(65):
			var pos := Vector2(rng.randf_range(30.0, w - 30.0), rng.randf_range(30.0, h - 30.0))
			if _prop_blocked(pos, 48.0, roads, river, pads, base_pos):
				continue
			var near_b := false
			for b in _buildings:
				if pos.distance_to(b["pos"]) < maxf(float(b["w"]), float(b["h"])) * 0.6 + 18.0:
					near_b = true
					break
			if near_b:
				continue
			_oaks.append(_make_oak(pos, rng.randf_range(12.0, 18.0), rng, "park"))

	elif _is_countryside:
		# Replace sharp conifers with lush rounded English oaks, charming Cotswold stone cottages & golden hay bales!
		_trees.clear()
		for _i in range(34):
			var bw: float = rng.randf_range(34.0, 50.0)
			var bh: float = rng.randf_range(24.0, 36.0)
			var pos := Vector2(rng.randf_range(55.0, w - 55.0), rng.randf_range(50.0, h - 50.0))
			var cl: float = maxf(bw, bh) * 0.5 + 18.0
			if _prop_blocked(pos, cl + 22.0, roads, river, pads, base_pos):
				continue
			var overlap := false
			for b in _buildings:
				if pos.distance_to(b["pos"]) < 85.0:
					overlap = true
					break
			if overlap:
				continue
			var c_col := Color(0.68, 0.56, 0.34) if rng.randf() < 0.45 else Color(0.58, 0.30, 0.22)
			_buildings.append({"pos": pos, "w": bw, "h": bh, "style": 3, "color": c_col})

		# Golden hay bales in little farm clusters
		for _i in range(52):
			var pos := Vector2(rng.randf_range(40.0, w - 40.0), rng.randf_range(40.0, h - 40.0))
			if _prop_blocked(pos, 52.0, roads, river, pads, base_pos):
				continue
			var near_b := false
			for b in _buildings:
				if pos.distance_to(b["pos"]) < 52.0:
					near_b = true
					break
			if near_b:
				continue
			_hay_bales.append({"pos": pos, "r": rng.randf_range(5.5, 7.5)})

		# Lush broad-leaf English oak & beech trees
		for _i in range(135):
			var pos := Vector2(rng.randf_range(28.0, w - 28.0), rng.randf_range(28.0, h - 28.0))
			if _prop_blocked(pos, 50.0, roads, river, pads, base_pos):
				continue
			var near_b := false
			for b in _buildings:
				if pos.distance_to(b["pos"]) < 46.0:
					near_b = true
					break
			if near_b:
				continue
			_oaks.append(_make_oak(pos, rng.randf_range(14.0, 24.0), rng, "oak"))

	elif _is_forest:
		# Extra lush ancient woodland oaks + mossy fallen timber logs alongside the dense pines!
		for _i in range(155):
			var pos := Vector2(rng.randf_range(24.0, w - 24.0), rng.randf_range(24.0, h - 24.0))
			if _prop_blocked(pos, 50.0, roads, river, pads, base_pos):
				continue
			_oaks.append(_make_oak(pos, rng.randf_range(14.0, 23.0), rng, "woodland"))
		for _i in range(38):
			var pos := Vector2(rng.randf_range(40.0, w - 40.0), rng.randf_range(40.0, h - 40.0))
			if _prop_blocked(pos, 54.0, roads, river, pads, base_pos):
				continue
			_logs.append({"pos": pos, "ang": rng.randf_range(0.0, TAU), "len": rng.randf_range(22.0, 38.0)})

	elif _is_outback:
		# Replace alpine pines with pale-trunked Eucalyptus Ghost Gums, golden Spinifex tufts & Outback tin sheds!
		_trees.clear()
		for _i in range(14):
			var pos := Vector2(rng.randf_range(60.0, w - 60.0), rng.randf_range(60.0, h - 60.0))
			if _prop_blocked(pos, 72.0, roads, river, pads, base_pos):
				continue
			_buildings.append({"pos": pos, "w": rng.randf_range(36.0, 52.0), "h": rng.randf_range(22.0, 32.0), "style": 4, "color": Color(0.56, 0.44, 0.36)})

		# Silvery-sage Eucalyptus Ghost Gum trees (heavier along Billabong creek + scattered across plains)
		for _i in range(115):
			var pos := Vector2(rng.randf_range(28.0, w - 28.0), rng.randf_range(28.0, h - 28.0))
			if _prop_blocked(pos, 52.0, roads, river, pads, base_pos):
				continue
			var d_riv: float = MapData.distance_to_polyline(pos, river)
			if d_riv > 140.0 and rng.randf() < 0.65:
				continue
			_oaks.append(_make_oak(pos, rng.randf_range(13.0, 22.0), rng, "eucalyptus"))

		# Golden spiky Outback Spinifex tussocks scattered across the red dirt!
		for _i in range(160):
			var pos := Vector2(rng.randf_range(24.0, w - 24.0), rng.randf_range(24.0, h - 24.0))
			if _prop_blocked(pos, 48.0, roads, river, pads, base_pos):
				continue
			var r: float = rng.randf_range(5.5, 11.0)
			_shrubs.append({
				"pos": pos,
				"poly": _build_foliage_poly(r, 8, rng, 0.44),
				"shade": rng.randf_range(0.84, 1.16),
			})

func _prop_blocked(pos: Vector2, pad_clear: float, roads: Array, river: PackedVector2Array, pads: Array, base_pos: Vector2) -> bool:
	if pos.distance_to(base_pos) < 128.0:
		return true
	if MapData.distance_to_polylines(pos, roads) < MapData.ROAD_WIDTH * 0.86:
		return true
	if MapData.distance_to_polyline(pos, river) < MapData.RIVER_WIDTH * 0.84:
		return true
	for pad in pads:
		if pos.distance_to(pad) < pad_clear:
			return true
	return false

func _make_oak(pos: Vector2, radius: float, rng: RandomNumberGenerator, kind: String) -> Dictionary:
	var puffs: Array[Dictionary] = []
	for _p in range(5):
		var a: float = rng.randf_range(0.0, TAU)
		var d: float = radius * rng.randf_range(0.24, 0.48)
		puffs.append({
			"off": Vector2(cos(a) * d, sin(a) * d),
			"r": radius * rng.randf_range(0.42, 0.62),
		})
	return {
		"pos": pos,
		"radius": radius,
		"shade": rng.randf_range(0.84, 1.16),
		"kind": kind,
		"puffs": puffs,
	}

func _process(delta: float) -> void:
	_time += delta
	if (_is_tundra or _is_christmas) and not map_data.is_empty():
		var w: float = float(map_data["width"])
		var h: float = float(map_data["height"])
		for sf in _snowflakes:
			sf["x"] = fposmod(float(sf["x"]) + float(sf["vx"]) * delta, w)
			sf["y"] = fposmod(float(sf["y"]) + float(sf["vy"]) * delta, h)
	queue_redraw()

func _draw() -> void:
	if map_data.is_empty():
		return
	_draw_road_markings()
	_draw_shore_stones()
	if _is_tundra or _is_christmas:
		_draw_ice_floes()
	_draw_bridges()
	_draw_air_corridor_hint()
	_draw_bunkers()
	_draw_sandbags()
	_draw_logs()
	_draw_rocks()
	_draw_hay_bales()
	_draw_pads()
	if _is_christmas:
		_draw_santa_workshop()
		_draw_christmas_props()
	else:
		_draw_hq_fortress()
	_draw_spawn_markers()
	_draw_buildings()
	if _is_desert or _is_outback:
		_draw_shrubs()
	if _is_desert:
		_draw_palms()
	if not _trees.is_empty():
		_draw_trees()
	if not _oaks.is_empty():
		_draw_oaks()
	if _is_tundra or _is_christmas:
		_draw_snowfall()

func _point_over_any_bridge(p: Vector2) -> bool:
	for b in _get_bridges():
		var bp: Vector2 = b
		if absf(p.x - bp.x) <= 68.0 and absf(p.y - bp.y) <= 40.0:
			return true
	return false

func _draw_road_markings() -> void:
	var paths: Array = map_data["ground_paths"]
	var line_col := Color(0.86, 0.74, 0.36, 0.46) if _is_desert else (Color(0.82, 0.76, 0.44, 0.40) if _is_tundra else Color(0.78, 0.67, 0.33, 0.44))
	for road in paths:
		var acc: float = 0.0
		for i in range(road.size() - 1):
			var a: Vector2 = road[i]
			var b: Vector2 = road[i + 1]
			var seg: float = a.distance_to(b)
			if not _point_over_any_bridge(a):
				if int(acc / 28.0) % 2 == 0:
					draw_line(a, b, line_col, 2.1, true)
			acc += seg

func _draw_shore_stones() -> void:
	for st in _shore_stones:
		var p: Vector2 = st["pos"]
		var verts: PackedVector2Array = st["verts"]
		var s: float = float(st["shade"])
		var is_wet: bool = bool(st["wet"])
		draw_colored_polygon(_offset_poly(verts, p + Vector2(2.6, 3.0)), Color(0.0, 0.0, 0.0, 0.36))
		var base_c: Color
		var lit_c: Color
		if _is_desert:
			base_c = Color(0.30 * s, 0.20 * s, 0.13 * s) if is_wet else Color(0.46 * s, 0.31 * s, 0.20 * s)
			lit_c = Color(0.45 * s, 0.32 * s, 0.21 * s) if is_wet else Color(0.64 * s, 0.47 * s, 0.31 * s)
		elif _is_tundra:
			base_c = Color(0.16 * s, 0.20 * s, 0.25 * s) if is_wet else Color(0.24 * s, 0.28 * s, 0.33 * s)
			lit_c = Color(0.54 * s, 0.64 * s, 0.72 * s) if is_wet else Color(0.74 * s, 0.80 * s, 0.86 * s)
		else:
			base_c = Color(0.18 * s, 0.19 * s, 0.17 * s) if is_wet else Color(0.28 * s, 0.27 * s, 0.24 * s)
			lit_c = Color(0.32 * s, 0.33 * s, 0.30 * s) if is_wet else Color(0.44 * s, 0.43 * s, 0.39 * s)
		draw_colored_polygon(_offset_poly(verts, p), base_c)
		draw_colored_polygon(_scale_offset_poly(verts, 0.58, p + Vector2(-1.4, -1.4)), lit_c)
		if is_wet:
			draw_circle(p + Vector2(-1.8, -1.8), 1.4, Color(0.88, 0.94, 0.98, 0.38))

func _draw_ice_floes() -> void:
	for floe in _ice_floes:
		var base_p: Vector2 = floe["pos"]
		var bob: float = sin(_time * 1.4 + float(floe["bob_phase"])) * 1.6
		var p: Vector2 = base_p + Vector2(bob * 0.4, bob)
		var verts: PackedVector2Array = floe["verts"]
		draw_colored_polygon(_offset_poly(verts, p + Vector2(2.0, 2.5)), Color(0.02, 0.10, 0.16, 0.42))
		draw_colored_polygon(_offset_poly(verts, p), Color(0.66, 0.82, 0.92, 0.82))
		draw_colored_polygon(_scale_offset_poly(verts, 0.72, p + Vector2(-1.0, -1.0)), Color(0.88, 0.94, 0.98, 0.90))

func _draw_bridges() -> void:
	for b in _get_bridges():
		_draw_single_bridge(Vector2(b))

func _draw_single_bridge(bp: Vector2) -> void:
	var half_w: float = 68.0
	var half_h: float = MapData.ROAD_WIDTH * 0.58

	var conc_dark := Color(0.38, 0.33, 0.26) if _is_desert else (Color(0.32, 0.36, 0.40) if _is_tundra else Color(0.31, 0.32, 0.30))
	var conc_lit := Color(0.54, 0.47, 0.37) if _is_desert else (Color(0.56, 0.62, 0.68) if _is_tundra else Color(0.44, 0.44, 0.41))
	var conc_rim := Color(0.68, 0.60, 0.48) if _is_desert else (Color(0.80, 0.85, 0.90) if _is_tundra else Color(0.58, 0.57, 0.53))

	# Concrete support piers anchored down into the river
	for ox: float in [-20.0, 20.0]:
		draw_rect(Rect2(bp + Vector2(ox - 7.0, -half_h - 14.0), Vector2(14.0, half_h * 2.0 + 28.0)), conc_dark)
		draw_rect(Rect2(bp + Vector2(ox - 5.0, -half_h - 12.0), Vector2(6.0, half_h * 2.0 + 24.0)), conc_lit)

	# Heavy concrete bridge abutments
	for side: float in [-1.0, 1.0]:
		var ax: float = bp.x + side * (half_w + 6.0)
		draw_rect(Rect2(Vector2(ax - 11.0 + 4.0, bp.y - half_h - 10.0 + 5.0), Vector2(22.0, half_h * 2.0 + 20.0)), Color(0.0, 0.0, 0.0, 0.36))
		draw_rect(Rect2(Vector2(ax - 11.0, bp.y - half_h - 10.0), Vector2(22.0, half_h * 2.0 + 20.0)), conc_dark)
		draw_rect(Rect2(Vector2(ax - 9.0, bp.y - half_h - 8.0), Vector2(16.0, half_h * 2.0 + 16.0)), conc_lit)
		draw_line(Vector2(ax - 10.0, bp.y - half_h - 9.0), Vector2(ax - 10.0, bp.y + half_h + 9.0), conc_rim, 2.0)

	# Steel ribbed deck surface with weathered inlay & dark tire ruts
	draw_rect(Rect2(bp + Vector2(-half_w, -half_h), Vector2(half_w * 2.0, half_h * 2.0)), Color(0.24, 0.23, 0.21) if _is_desert else (Color(0.20, 0.23, 0.26) if _is_tundra else Color(0.21, 0.22, 0.22)))
	draw_rect(Rect2(bp + Vector2(-half_w, -half_h + 8.0), Vector2(half_w * 2.0, half_h * 2.0 - 16.0)), Color(0.28, 0.26, 0.23) if _is_desert else (Color(0.25, 0.28, 0.32) if _is_tundra else Color(0.24, 0.24, 0.23)))
	draw_rect(Rect2(bp + Vector2(-half_w, -half_h), Vector2(half_w * 2.0, 8.0)), Color(0.46, 0.52, 0.58) if _is_tundra else Color(0.18, 0.18, 0.17))
	draw_rect(Rect2(bp + Vector2(-half_w, half_h - 8.0), Vector2(half_w * 2.0, 8.0)), Color(0.46, 0.52, 0.58) if _is_tundra else Color(0.18, 0.18, 0.17))

	draw_line(bp + Vector2(-half_w, -13.0), bp + Vector2(half_w, -13.0), Color(0.12, 0.12, 0.13, 0.58), 8.5)
	draw_line(bp + Vector2(-half_w, 13.0), bp + Vector2(half_w, 13.0), Color(0.12, 0.12, 0.13, 0.58), 8.5)
	for dx: float in [-46.0, -14.0, 18.0, 48.0]:
		draw_line(bp + Vector2(dx - 8.0, 0.0), bp + Vector2(dx + 8.0, 0.0), Color(0.82, 0.72, 0.34, 0.48), 2.2)

	for x_off: float in [-54.0, -27.0, 0.0, 27.0, 54.0]:
		draw_line(bp + Vector2(x_off, -half_h + 2.0), bp + Vector2(x_off, half_h - 2.0), Color(0.12, 0.13, 0.14, 0.85), 2.4)
		draw_line(bp + Vector2(x_off + 8.0, -half_h + 6.0), bp + Vector2(x_off + 8.0, half_h - 2.0), Color(0.0, 0.0, 0.0, 0.24), 4.5)

	# Raised 3D steel side truss girders (frosted with snow on tundra!)
	draw_rect(Rect2(bp + Vector2(-half_w - 2.0, -half_h + 2.0), Vector2(half_w * 2.0 + 4.0, 8.0)), Color(0.0, 0.0, 0.0, 0.30))
	draw_rect(Rect2(bp + Vector2(-half_w - 2.0, -half_h - 7.0), Vector2(half_w * 2.0 + 4.0, 10.0)), Color(0.30, 0.28, 0.25) if _is_desert else (Color(0.28, 0.33, 0.38) if _is_tundra else Color(0.24, 0.26, 0.25)))
	draw_rect(Rect2(bp + Vector2(-half_w - 2.0, -half_h - 6.0), Vector2(half_w * 2.0 + 4.0, 3.5)), Color(0.58, 0.54, 0.47) if _is_desert else (Color(0.82, 0.87, 0.92) if _is_tundra else Color(0.52, 0.54, 0.50)))

	draw_rect(Rect2(bp + Vector2(-half_w - 2.0, half_h - 3.0), Vector2(half_w * 2.0 + 4.0, 10.0)), Color(0.27, 0.25, 0.23) if _is_desert else (Color(0.25, 0.30, 0.35) if _is_tundra else Color(0.22, 0.24, 0.23)))
	draw_rect(Rect2(bp + Vector2(-half_w - 2.0, half_h - 2.0), Vector2(half_w * 2.0 + 4.0, 3.5)), Color(0.52, 0.48, 0.42) if _is_desert else (Color(0.76, 0.82, 0.88) if _is_tundra else Color(0.46, 0.48, 0.45)))

	for x_off: float in [-58.0, -35.0, -12.0, 12.0, 35.0, 58.0]:
		draw_rect(Rect2(bp + Vector2(x_off - 4.0, -half_h - 8.0), Vector2(8.0, 12.0)), Color(0.52, 0.58, 0.64) if _is_tundra else Color(0.44, 0.42, 0.38))
		draw_rect(Rect2(bp + Vector2(x_off - 4.0, -half_h - 8.0), Vector2(3.0, 12.0)), Color(0.76, 0.82, 0.88) if _is_tundra else Color(0.58, 0.56, 0.51))
		draw_rect(Rect2(bp + Vector2(x_off - 4.0, half_h - 4.0), Vector2(8.0, 12.0)), Color(0.48, 0.54, 0.60) if _is_tundra else Color(0.40, 0.38, 0.35))
		draw_rect(Rect2(bp + Vector2(x_off - 4.0, half_h - 4.0), Vector2(3.0, 12.0)), Color(0.70, 0.76, 0.82) if _is_tundra else Color(0.52, 0.50, 0.45))
		draw_circle(bp + Vector2(x_off, -half_h - 2.0), 1.4, Color(0.12, 0.13, 0.14))
		draw_circle(bp + Vector2(x_off, half_h + 2.0), 1.4, Color(0.12, 0.13, 0.14))

	for side: float in [-1.0, 1.0]:
		var hx: float = bp.x + side * (half_w + 7.5)
		for y_step in range(-28, 28, 12):
			draw_line(Vector2(hx, bp.y + float(y_step)), Vector2(hx, bp.y + float(y_step) + 6.0), Color(0.92, 0.72, 0.20, 0.88), 3.0)

	# Festive fairy-light garlands & candy-cane side rails on Christmas North Pole bridges!
	if _is_christmas:
		var bulb_cols: Array[Color] = [
			Color(1.0, 0.24, 0.24), Color(1.0, 0.88, 0.26),
			Color(0.24, 0.96, 0.46), Color(0.38, 0.86, 1.0)
		]
		for bx_i in range(9):
			var lx: float = bp.x + lerpf(-half_w + 4.0, half_w - 4.0, float(bx_i) / 8.0)
			var tw: float = 0.55 + 0.45 * sin(_time * 5.2 + float(bx_i) * 1.1)
			var c: Color = bulb_cols[bx_i % bulb_cols.size()]
			for ry: float in [-half_h - 3.0, half_h + 3.0]:
				draw_circle(Vector2(lx, bp.y + ry), 5.2, Color(c.r, c.g, c.b, 0.24 * tw))
				draw_circle(Vector2(lx, bp.y + ry), 2.3, Color(c.r, c.g, c.b, 0.95 * tw))

func _draw_air_corridor_hint() -> void:
	var air: PackedVector2Array = map_data["air_path"]
	var acc: float = 0.0
	var col := Color(0.24, 0.56, 0.76, 0.18) if _is_tundra else Color(0.75, 0.88, 0.96, 0.10)
	for i in range(air.size() - 1):
		var a: Vector2 = air[i]
		var b: Vector2 = air[i + 1]
		var seg: float = a.distance_to(b)
		if int(acc / 38.0) % 2 == 0:
			draw_line(a, b, col, 1.5, true)
		acc += seg

func _draw_bunkers() -> void:
	var b_base := Color(0.40, 0.34, 0.26) if _is_desert else (Color(0.32, 0.36, 0.40) if _is_tundra else Color(0.28, 0.29, 0.26))
	var b_top := Color(0.54, 0.46, 0.35) if _is_desert else (Color(0.76, 0.82, 0.87) if _is_tundra else Color(0.41, 0.42, 0.38))
	for b in _bunkers:
		var p: Vector2 = b["pos"]
		var ang: float = float(b["angle"])
		var d := Vector2.from_angle(ang)
		var perp := Vector2(-d.y, d.x)
		var base := PackedVector2Array([
			p + d * 19.0 + perp * 15.0, p + d * 19.0 - perp * 15.0,
			p - d * 17.0 - perp * 18.0, p - d * 17.0 + perp * 18.0
		])
		draw_colored_polygon(_offset_poly(base, Vector2(6.5, 7.5)), Color(0.05, 0.10, 0.18, 0.42) if _is_tundra else Color(0.0, 0.0, 0.0, 0.42))
		draw_colored_polygon(base, b_base)
		var top := PackedVector2Array([
			p + d * 13.0 + perp * 11.0, p + d * 13.0 - perp * 11.0,
			p - d * 12.0 - perp * 13.0, p - d * 12.0 + perp * 13.0
		])
		draw_colored_polygon(top, b_top)
		draw_line(p + d * 16.0 - perp * 8.0, p + d * 16.0 + perp * 8.0, Color(0.05, 0.05, 0.06), 3.4, true)
		draw_circle(p - d * 2.0, 4.4, Color(0.24, 0.26, 0.28))
		draw_arc(p - d * 2.0, 4.4, 0.0, TAU, 14, Color(0.58, 0.62, 0.66), 1.0, true)

func _draw_sandbags() -> void:
	var bag_dark := Color(0.48, 0.40, 0.27) if _is_desert else (Color(0.44, 0.49, 0.54) if _is_tundra else Color(0.36, 0.33, 0.24))
	var bag_mid := Color(0.66, 0.57, 0.40) if _is_desert else (Color(0.68, 0.74, 0.80) if _is_tundra else Color(0.54, 0.49, 0.36))
	var bag_lit := Color(0.78, 0.69, 0.52, 0.78) if _is_desert else (Color(0.88, 0.93, 0.97, 0.85) if _is_tundra else Color(0.66, 0.61, 0.47, 0.75))
	for sb in _sandbags:
		var p: Vector2 = sb["pos"]
		var ang: float = float(sb["angle"])
		var dir := Vector2.from_angle(ang)
		var perp := Vector2(-dir.y, dir.x)
		for i in range(-2, 3):
			var bp: Vector2 = p + dir * (float(i) * 11.0) + perp * (absf(float(i)) * 1.8)
			draw_circle(bp + Vector2(3.5, 4.0), 6.2, Color(0.06, 0.12, 0.22, 0.34) if _is_tundra else Color(0.0, 0.0, 0.0, 0.36))
		for i in range(-2, 3):
			var bp: Vector2 = p + dir * (float(i) * 11.0) + perp * (absf(float(i)) * 1.8)
			draw_circle(bp, 5.5, bag_dark)
			draw_circle(bp + Vector2(-1.2, -1.2), 3.6, bag_mid)
			draw_circle(bp + Vector2(-2.0, -2.0), 1.5, bag_lit)
			draw_arc(bp, 5.5, 0.0, TAU, 12, Color(0.20, 0.22, 0.24, 0.72), 1.0, true)

func _draw_rocks() -> void:
	for r in _rocks:
		var p: Vector2 = r["pos"]
		var verts: PackedVector2Array = r["verts"]
		var s: float = float(r["shade"])
		var sats: Array = r["sats"]

		var c_dark: Color
		var c_mid: Color
		var c_lit: Color
		if _is_desert:
			c_dark = Color(0.35 * s, 0.22 * s, 0.14 * s)
			c_mid = Color(0.50 * s, 0.33 * s, 0.21 * s)
			c_lit = Color(0.68 * s, 0.49 * s, 0.32 * s)
		elif _is_outback:
			# Deep iron-oxide Uluru crimson sandstone outcrops!
			c_dark = Color(0.36 * s, 0.13 * s, 0.08 * s)
			c_mid = Color(0.56 * s, 0.21 * s, 0.12 * s)
			c_lit = Color(0.74 * s, 0.34 * s, 0.18 * s)
		elif _is_tundra:
			c_dark = Color(0.18 * s, 0.22 * s, 0.27 * s)
			c_mid = Color(0.30 * s, 0.35 * s, 0.41 * s)
			c_lit = Color(0.78 * s, 0.84 * s, 0.90 * s)
		else:
			c_dark = Color(0.22 * s, 0.23 * s, 0.20 * s)
			c_mid = Color(0.35 * s, 0.34 * s, 0.31 * s)
			c_lit = Color(0.50 * s, 0.49 * s, 0.44 * s)

		var sh_col := Color(0.06, 0.12, 0.22, 0.36) if _is_tundra else Color(0.0, 0.0, 0.0, 0.38)
		for sat in sats:
			var sp: Vector2 = p + Vector2(sat["off"])
			var sv: PackedVector2Array = sat["verts"]
			draw_colored_polygon(_offset_poly(sv, sp + Vector2(2.6, 3.0)), sh_col)
			draw_colored_polygon(_offset_poly(sv, sp), c_dark)
			draw_colored_polygon(_scale_offset_poly(sv, 0.62, sp + Vector2(-1.0, -1.0)), c_lit)

		draw_colored_polygon(_offset_poly(verts, p + Vector2(6.0, 7.0)), sh_col)
		draw_colored_polygon(_offset_poly(verts, p + Vector2(1.6, 2.0)), Color(0.0, 0.0, 0.0, 0.42))
		draw_colored_polygon(_offset_poly(verts, p), c_dark)
		draw_colored_polygon(_scale_offset_poly(verts, 0.78, p + Vector2(-1.6, -1.6)), c_mid)
		draw_colored_polygon(_scale_offset_poly(verts, 0.50, p + Vector2(-3.0, -3.0)), c_lit)
		draw_line(p + Vector2(-4.0, 1.0), p + Vector2(3.5, -2.5), Color(0.12, 0.14, 0.17, 0.55), 1.2, true)

func _draw_pads() -> void:
	var pads: Array = map_data["pads"]
	var pulse: float = 0.5 + 0.5 * sin(_time * 4.5)
	var pad_base := Color(0.30, 0.27, 0.22, 0.96) if _is_desert else (Color(0.24, 0.28, 0.33, 0.96) if _is_tundra else Color(0.22, 0.23, 0.20, 0.96))
	var pad_top := Color(0.41, 0.37, 0.30, 0.96) if _is_desert else (Color(0.40, 0.45, 0.50, 0.96) if _is_tundra else Color(0.32, 0.33, 0.29, 0.96))

	for idx in range(pads.size()):
		var pos: Vector2 = pads[idx]
		var occupied: bool = occupied_pads.has(idx)
		var is_hovered: bool = (idx == hovered_pad_index)

		draw_circle(pos + Vector2(3.5, 4.2), 27.0, Color(0.06, 0.12, 0.22, 0.34) if _is_tundra else Color(0.0, 0.0, 0.0, 0.34))
		draw_circle(pos, 26.5, Color(0.11, 0.12, 0.14, 0.40))

		var oct := PackedVector2Array()
		var oct_top := PackedVector2Array()
		for k in range(8):
			var a: float = float(k) * (TAU / 8.0) + PI / 8.0
			oct.append(pos + Vector2.from_angle(a) * 25.0)
			oct_top.append(pos + Vector2(-1.0, -1.0) + Vector2.from_angle(a) * 22.8)
		draw_colored_polygon(oct, pad_base)
		draw_colored_polygon(oct_top, pad_top)
		var oct_closed := PackedVector2Array(oct)
		oct_closed.append(oct[0])
		draw_polyline(oct_closed, Color(0.10, 0.12, 0.14, 0.90), 1.4, true)
		draw_arc(pos, 22.8, PI * 0.85, PI * 1.65, 16, Color(0.76, 0.82, 0.88, 0.62) if _is_tundra else Color(0.64, 0.60, 0.50, 0.55), 1.6, true)

		draw_circle(pos, 18.2, Color(0.10, 0.12, 0.14, 0.96))
		draw_circle(pos + Vector2(1.4, 1.4), 16.2, Color(0.15, 0.17, 0.19, 0.95))
		draw_arc(pos, 18.2, -PI * 0.15, PI * 0.65, 16, Color(0.46, 0.50, 0.54, 0.55), 1.4, true)

		for gy: float in [-8.0, -3.0, 3.0, 8.0]:
			var half_l: float = sqrt(maxf(0.0, 14.5 * 14.5 - gy * gy))
			draw_line(pos + Vector2(-half_l, gy), pos + Vector2(half_l, gy), Color(0.08, 0.09, 0.10, 0.78), 1.3)
		draw_line(pos + Vector2(0, -14.5), pos + Vector2(0, 14.5), Color(0.24, 0.27, 0.30, 0.85), 2.2)

		for b in range(4):
			var ba: float = PI * 0.25 + float(b) * PI * 0.5
			var bp: Vector2 = pos + Vector2.from_angle(ba) * 19.8
			draw_circle(bp, 2.2, Color(0.12, 0.13, 0.14))
			draw_circle(bp + Vector2(-0.5, -0.5), 1.4, Color(0.54, 0.58, 0.62))

		if _is_christmas:
			# Festive evergreen holly wreath with red berries & gold bulbs around turret hardpoint!
			draw_arc(pos, 23.6, 0.0, TAU, 32, Color(0.12, 0.42, 0.18, 0.85), 3.4, true)
			for w_i in range(8):
				var wa: float = float(w_i) * (TAU / 8.0)
				var wp: Vector2 = pos + Vector2.from_angle(wa) * 23.6
				var dot_c := Color(0.96, 0.20, 0.22) if (w_i % 2 == 0) else Color(1.0, 0.86, 0.28)
				draw_circle(wp, 1.9, dot_c)

		if not occupied:
			if placement_active:
				var ring_col := Color(0.24, 0.94, 0.46, 0.62 + pulse * 0.34) if placement_affordable else Color(0.92, 0.28, 0.24, 0.62 + pulse * 0.32)
				if is_hovered:
					var fill_col := Color(placement_accent.r, placement_accent.g, placement_accent.b, 0.13) if placement_affordable else Color(0.95, 0.22, 0.22, 0.13)
					var edge_col := Color(placement_accent.r, placement_accent.g, placement_accent.b, 0.82) if placement_affordable else Color(0.95, 0.28, 0.24, 0.84)
					draw_circle(pos, placement_range, fill_col)
					draw_arc(pos, placement_range, 0.0, TAU, 72, edge_col, 2.2, true)
					draw_circle(pos, 24.0, Color(ring_col.r, ring_col.g, ring_col.b, 0.26))
					draw_arc(pos, 26.2, 0.0, TAU, 36, ring_col, 2.8, true)
				else:
					draw_circle(pos, 17.5, Color(ring_col.r, ring_col.g, ring_col.b, 0.14 + pulse * 0.08))
					draw_arc(pos, 22.5, 0.0, TAU, 32, ring_col, 2.2, true)
				draw_line(pos + Vector2(-7, 0), pos + Vector2(7, 0), ring_col, 1.6)
				draw_line(pos + Vector2(0, -7), pos + Vector2(0, 7), ring_col, 1.6)
			else:
				var idle_alpha: float = 0.68 if is_hovered else 0.38
				var idle_col := Color(0.26, 0.86, 0.46, idle_alpha)
				draw_arc(pos, 21.8, 0.0, TAU, 32, idle_col, 1.8 if not is_hovered else 2.4, true)
				draw_circle(pos, 2.8, Color(0.26, 0.86, 0.46, idle_alpha * 0.9))

func _draw_hq_fortress() -> void:
	var bp: Vector2 = map_data["base_pos"]
	var wall_dark := Color(0.36, 0.31, 0.25) if _is_desert else (Color(0.28, 0.32, 0.37) if _is_tundra else Color(0.26, 0.27, 0.25))
	var wall_lit := Color(0.48, 0.42, 0.34) if _is_desert else (Color(0.56, 0.62, 0.68) if _is_tundra else Color(0.34, 0.35, 0.32))

	draw_rect(Rect2(bp + Vector2(-44, -56), Vector2(108, 132)), Color(0.05, 0.10, 0.18, 0.46) if _is_tundra else Color(0.0, 0.0, 0.0, 0.46))
	draw_rect(Rect2(bp + Vector2(-50, -62), Vector2(100, 124)), wall_dark)
	draw_rect(Rect2(bp + Vector2(-49, -61), Vector2(96, 120)), wall_lit)
	draw_rect(Rect2(bp + Vector2(-44, -56), Vector2(88, 112)), Color(0.20, 0.22, 0.24) if _is_tundra else Color(0.20, 0.19, 0.17))

	for cx: float in [-46.0, 40.0]:
		for cy: float in [-58.0, 52.0]:
			draw_rect(Rect2(bp + Vector2(cx - 2.0, cy - 2.0), Vector2(15.0, 15.0)), Color(0.0, 0.0, 0.0, 0.36))
			draw_rect(Rect2(bp + Vector2(cx - 5.0, cy - 5.0), Vector2(15.0, 15.0)), wall_lit)
			draw_rect(Rect2(bp + Vector2(cx - 4.0, cy - 4.0), Vector2(11.0, 11.0)), wall_lit.lightened(0.14))
			draw_circle(bp + Vector2(cx + 2.0, cy + 2.0), 3.0, Color(0.16, 0.18, 0.20))

	for y in range(-42, 44, 14):
		draw_rect(Rect2(bp + Vector2(-50, float(y)), Vector2(7, 7)), Color(0.86, 0.68, 0.20, 0.88))

	draw_rect(Rect2(bp + Vector2(-19, -37), Vector2(62, 86)), Color(0.0, 0.0, 0.0, 0.40))
	draw_rect(Rect2(bp + Vector2(-24, -42), Vector2(60, 84)), wall_dark.lightened(0.08))
	draw_rect(Rect2(bp + Vector2(-23, -41), Vector2(56, 80)), wall_lit.lightened(0.06))
	draw_rect(Rect2(bp + Vector2(-19, -37), Vector2(50, 74)), Color(0.24, 0.27, 0.30) if _is_tundra else Color(0.26, 0.25, 0.22))

	var pad_c := bp + Vector2(6.0, 18.0)
	draw_circle(pad_c, 14.5, Color(0.16, 0.18, 0.19))
	draw_arc(pad_c, 13.8, 0.0, TAU, 28, Color(0.86, 0.74, 0.28, 0.78), 1.8, true)
	draw_string(ThemeDB.fallback_font, pad_c + Vector2(-5.0, 5.0), "H", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.92, 0.84, 0.36, 0.90))

	var radar_pos := bp + Vector2(6.0, -16.0)
	draw_circle(radar_pos + Vector2(2.0, 2.5), 16.5, Color(0.0, 0.0, 0.0, 0.38))
	draw_circle(radar_pos, 16.5, Color(0.13, 0.17, 0.16))
	draw_arc(radar_pos, 16.5, 0.0, TAU, 32, Color(0.34, 0.88, 0.50, 0.66), 1.6, true)
	var sweep: float = _time * 1.95
	var cone := PackedVector2Array([radar_pos])
	for s in range(7):
		var ca: float = sweep - float(s) * 0.11
		cone.append(radar_pos + Vector2.from_angle(ca) * 15.5)
	draw_colored_polygon(cone, Color(0.32, 0.94, 0.52, 0.26))
	var dish_dir := Vector2.from_angle(sweep)
	var dish_perp := Vector2(-dish_dir.y, dish_dir.x)
	draw_line(radar_pos, radar_pos + dish_dir * 14.0, Color(0.50, 0.98, 0.62, 0.92), 2.0, true)
	draw_line(radar_pos - dish_perp * 10.0, radar_pos + dish_perp * 10.0, Color(0.74, 0.78, 0.78), 3.4, true)

	var blink: float = 0.45 + 0.55 * sin(_time * 5.0)
	draw_circle(bp + Vector2(-15, -32), 3.2, Color(0.25, 0.96, 0.46, blink))
	draw_circle(bp + Vector2(-15, 32), 3.2, Color(0.25, 0.96, 0.46, blink))

func _draw_spawn_markers() -> void:
	var spawns: Array = map_data["spawn_positions"]
	var asp: Vector2 = map_data["air_spawn_pos"]
	var pulse: float = fmod(_time * 1.6, 1.0)

	for sp in spawns:
		for i in range(3):
			var offset: float = float(i) * 14.0 + pulse * 14.0
			var alpha: float = (1.0 - (offset / 56.0)) * 0.86
			var c: Vector2 = Vector2(sp) + Vector2(offset, 0.0)
			var pts := PackedVector2Array([
				c + Vector2(-6, -12),
				c + Vector2(6, 0),
				c + Vector2(-6, 12),
			])
			draw_polyline(pts, Color(0.95, 0.40, 0.20, clampf(alpha, 0.0, 1.0)), 2.8, true)

	var air_dir: Vector2 = (Vector2(map_data["air_path"][1]) - Vector2(map_data["air_path"][0])).normalized()
	var air_perp := Vector2(-air_dir.y, air_dir.x)
	var ap: Vector2 = asp + air_dir * (pulse * 22.0)
	var a_alpha: float = (1.0 - pulse) * 0.82
	var air_pts := PackedVector2Array([
		ap - air_dir * 6.0 - air_perp * 9.0,
		ap + air_dir * 6.0,
		ap - air_dir * 6.0 + air_perp * 9.0,
	])
	var air_col := Color(0.14, 0.54, 0.84, a_alpha) if _is_tundra else Color(0.45, 0.85, 0.98, a_alpha)
	draw_polyline(air_pts, air_col, 2.4, true)

func _offset_poly(poly: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	for i in range(poly.size()):
		out[i] = poly[i] + offset
	return out

func _scale_offset_poly(poly: PackedVector2Array, scale_f: float, offset: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(poly.size())
	for i in range(poly.size()):
		out[i] = poly[i] * scale_f + offset
	return out

func _draw_trees() -> void:
	for t in _trees:
		var pos: Vector2 = t["pos"]
		var s: float = float(t["shade"])
		var base_poly: PackedVector2Array = t["base_poly"]
		var mid_poly: PackedVector2Array = t["mid_poly"]
		var top_poly: PackedVector2Array = t["top_poly"]
		var boughs: Array = t["boughs"]

		if _is_christmas:
			# Decorated North Pole Christmas Trees with twinkling ornaments & golden star toppers!
			draw_colored_polygon(_offset_poly(base_poly, pos + Vector2(9.0, 10.0)), Color(0.06, 0.14, 0.28, 0.26))
			draw_colored_polygon(_offset_poly(base_poly, pos), Color(0.07 * s, 0.22 * s, 0.13 * s))
			for b in boughs:
				var boff: Vector2 = b["off"]
				var br: float = float(b["r"])
				draw_circle(pos + boff, br, Color(0.10 * s, 0.30 * s, 0.16 * s, 0.92))
				draw_circle(pos + boff + Vector2(-1.4, -1.4), br * 0.50, Color(0.84, 0.90, 0.96, 0.72))
			draw_colored_polygon(_offset_poly(mid_poly, pos + Vector2(-1.5, -1.5)), Color(0.13 * s, 0.36 * s, 0.19 * s))
			draw_colored_polygon(_offset_poly(top_poly, pos + Vector2(-2.4, -2.4)), Color(0.82, 0.89, 0.95, 0.78))
			# Twinkling ornaments around the tree
			var r_tree: float = float(t["radius"])
			var orn_cols: Array[Color] = [
				Color(1.0, 0.22, 0.24), Color(1.0, 0.86, 0.26),
				Color(0.30, 0.88, 1.0), Color(0.96, 0.36, 0.82)
			]
			for o_i in range(4):
				var oa: float = float(o_i) * (TAU * 0.25) + pos.x * 0.1
				var op: Vector2 = pos + Vector2.from_angle(oa) * (r_tree * 0.56)
				var oc: Color = orn_cols[o_i]
				var tw: float = 0.62 + 0.38 * sin(_time * 4.5 + pos.y * 0.05 + float(o_i) * 1.4)
				draw_circle(op, 2.2, Color(oc.r, oc.g, oc.b, tw))
			# Glowing golden star topper!
			var sp := pos + Vector2(-2.8, -2.8)
			draw_circle(sp, 5.0, Color(1.0, 0.88, 0.30, 0.26))
			draw_circle(sp, 2.4, Color(1.0, 0.92, 0.42, 0.96))
		elif _is_tundra:
			# Cool ice-blue shadows on snow + dark arctic spruce + heavy white-blue snowcaps!
			draw_colored_polygon(_offset_poly(base_poly, pos + Vector2(9.0, 10.0)), Color(0.08, 0.16, 0.28, 0.24))
			draw_colored_polygon(_offset_poly(base_poly, pos + Vector2(4.5, 5.2)), Color(0.06, 0.12, 0.22, 0.30))
			draw_colored_polygon(_offset_poly(base_poly, pos), Color(0.07 * s, 0.13 * s, 0.12 * s))
			for b in boughs:
				var boff: Vector2 = b["off"]
				var br: float = float(b["r"])
				draw_circle(pos + boff, br, Color(0.10 * s, 0.18 * s, 0.16 * s, 0.92))
				draw_circle(pos + boff + Vector2(-1.6, -1.6), br * 0.62, Color(0.76 * s, 0.83 * s, 0.89 * s, 0.84))
			draw_colored_polygon(_offset_poly(mid_poly, pos + Vector2(-1.6, -1.6)), Color(0.14 * s, 0.22 * s, 0.20 * s))
			# Heavy snow-laden upper spruce boughs & sunlit snow tip
			draw_colored_polygon(_offset_poly(top_poly, pos + Vector2(-2.6, -2.6)), Color(0.78 * s, 0.84 * s, 0.90 * s))
			draw_circle(pos + Vector2(-3.4, -3.4), 3.4, Color(0.92, 0.95, 0.98, 0.92))
		else:
			draw_colored_polygon(_offset_poly(base_poly, pos + Vector2(8.5, 9.5)), Color(0.0, 0.0, 0.0, 0.22))
			draw_colored_polygon(_offset_poly(base_poly, pos + Vector2(4.5, 5.2)), Color(0.0, 0.0, 0.0, 0.28))
			draw_colored_polygon(_offset_poly(base_poly, pos), Color(0.07 * s, 0.13 * s, 0.07 * s))
			for b in boughs:
				var boff: Vector2 = b["off"]
				var br: float = float(b["r"])
				draw_circle(pos + boff, br, Color(0.11 * s, 0.19 * s, 0.10 * s, 0.90))
				draw_circle(pos + boff + Vector2(-1.4, -1.4), br * 0.62, Color(0.17 * s, 0.26 * s, 0.13 * s, 0.80))
			draw_colored_polygon(_offset_poly(mid_poly, pos + Vector2(-1.6, -1.6)), Color(0.13 * s, 0.21 * s, 0.11 * s))
			draw_colored_polygon(_offset_poly(top_poly, pos + Vector2(-3.2, -3.2)), Color(0.22 * s, 0.32 * s, 0.16 * s))
			draw_circle(pos + Vector2(-3.8, -3.8), 2.8, Color(0.34 * s, 0.44 * s, 0.23 * s, 0.78))

func _draw_shrubs() -> void:
	for sh in _shrubs:
		var pos: Vector2 = sh["pos"]
		var poly: PackedVector2Array = sh["poly"]
		var s: float = float(sh["shade"])
		draw_colored_polygon(_offset_poly(poly, pos + Vector2(3.5, 4.0)), Color(0.0, 0.0, 0.0, 0.28))
		if _is_outback:
			# Golden spiky Australian Outback Spinifex tussocks!
			draw_colored_polygon(_offset_poly(poly, pos), Color(0.46 * s, 0.38 * s, 0.15 * s))
			draw_colored_polygon(_scale_offset_poly(poly, 0.65, pos + Vector2(-1.4, -1.4)), Color(0.66 * s, 0.56 * s, 0.22 * s))
		else:
			draw_colored_polygon(_offset_poly(poly, pos), Color(0.26 * s, 0.28 * s, 0.14 * s))
			draw_colored_polygon(_scale_offset_poly(poly, 0.65, pos + Vector2(-1.4, -1.4)), Color(0.36 * s, 0.38 * s, 0.18 * s))

func _draw_palms() -> void:
	for palm in _palms:
		var pos: Vector2 = palm["pos"]
		var s: float = float(palm["shade"])
		var fronds: Array = palm["fronds"]
		var sh_off := Vector2(11.0, 13.0)

		draw_line(pos, pos + sh_off, Color(0.0, 0.0, 0.0, 0.24), 4.0, true)
		for f in fronds:
			var ang: float = float(f["ang"])
			var flen: float = float(f["len"])
			var fw: float = float(f["w"])
			var dir := Vector2.from_angle(ang)
			var perp := Vector2(-dir.y, dir.x)
			var sp := pos + sh_off
			var fpoly := PackedVector2Array([
				sp,
				sp + dir * (flen * 0.42) + perp * (fw * 0.75),
				sp + dir * flen,
				sp + dir * (flen * 0.42) - perp * (fw * 0.75),
			])
			draw_colored_polygon(fpoly, Color(0.0, 0.0, 0.0, 0.22))

		for f in fronds:
			var ang: float = float(f["ang"])
			var flen: float = float(f["len"])
			var fw: float = float(f["w"])
			var dir := Vector2.from_angle(ang)
			var perp := Vector2(-dir.y, dir.x)
			var fpoly := PackedVector2Array([
				pos,
				pos + dir * (flen * 0.38) + perp * fw,
				pos + dir * flen,
				pos + dir * (flen * 0.38) - perp * fw,
			])
			draw_colored_polygon(fpoly, Color(0.14 * s, 0.28 * s, 0.11 * s))
			var lit_poly := PackedVector2Array([
				pos,
				pos + dir * (flen * 0.35) + perp * (fw * 0.55),
				pos + dir * (flen * 0.90),
				pos + dir * (flen * 0.35),
			])
			draw_colored_polygon(lit_poly, Color(0.24 * s, 0.42 * s, 0.16 * s))
			draw_line(pos, pos + dir * (flen * 0.88), Color(0.36 * s, 0.52 * s, 0.22 * s, 0.85), 1.2, true)

		draw_circle(pos, 3.2, Color(0.28, 0.21, 0.13))
		draw_circle(pos + Vector2(-0.8, -0.8), 1.5, Color(0.42, 0.34, 0.20))

func _draw_snowfall() -> void:
	for sf in _snowflakes:
		var p := Vector2(float(sf["x"]), float(sf["y"]))
		var r: float = float(sf["r"])
		var a: float = float(sf["alpha"])
		var is_gold: bool = bool(sf.get("gold", false))
		var col := Color(1.0, 0.90, 0.46, a) if is_gold else Color(0.95, 0.98, 1.0, a)
		draw_circle(p, r, col)

func _draw_santa_workshop() -> void:
	# SANTA'S NORTH POLE WORKSHOP & GIFT VAULT (Cozy festive timber lodge HQ!)
	var bp: Vector2 = map_data["base_pos"]
	var red := Color(0.76, 0.15, 0.18)
	var red_lit := Color(0.90, 0.24, 0.24)
	var wood := Color(0.46, 0.30, 0.18)
	var snow := Color(0.90, 0.94, 0.98)
	var gold := Color(1.0, 0.86, 0.30)

	# Warm golden ambient lantern glow on the courtyard snow
	draw_circle(bp, 82.0, Color(1.0, 0.78, 0.30, 0.14))
	# Deep shadow
	draw_rect(Rect2(bp + Vector2(-46, -58), Vector2(110, 134)), Color(0.05, 0.10, 0.22, 0.42))
	# Snow-rimmed cobblestone courtyard apron
	draw_rect(Rect2(bp + Vector2(-52, -64), Vector2(104, 128)), Color(0.56, 0.44, 0.38))
	draw_rect(Rect2(bp + Vector2(-48, -60), Vector2(96, 120)), Color(0.36, 0.28, 0.24))

	# Candy-cane entrance posts on west courtyard gate
	for gy: float in [-46.0, 46.0]:
		draw_circle(bp + Vector2(-48.0, gy), 6.0, red)
		draw_circle(bp + Vector2(-48.0, gy), 3.4, snow)
		draw_circle(bp + Vector2(-48.0, gy), 1.6, gold)

	# Cozy timber Workshop main lodge & festive pitched crimson roof!
	draw_rect(Rect2(bp + Vector2(-22, -46), Vector2(66, 96)), Color(0.05, 0.08, 0.16, 0.40))
	draw_rect(Rect2(bp + Vector2(-28, -50), Vector2(66, 100)), wood)
	# Pitched red shingle roof (north slope lit, south slope slightly shaded)
	draw_rect(Rect2(bp + Vector2(-25, -47), Vector2(60, 47)), red_lit)
	draw_rect(Rect2(bp + Vector2(-25, 0), Vector2(60, 47)), red)
	# Snowdrifts along roof ridge & eaves
	draw_rect(Rect2(bp + Vector2(-26, -48), Vector2(62, 6)), snow)
	draw_rect(Rect2(bp + Vector2(-26, 42), Vector2(62, 6)), snow)
	draw_line(bp + Vector2(-24, 0), bp + Vector2(34, 0), snow, 4.5, true)

	# Glowing golden frosted Workshop windows along the west wall
	for wy: float in [-30.0, -10.0, 10.0, 30.0]:
		draw_circle(bp + Vector2(-28.0, wy), 8.5, Color(1.0, 0.84, 0.32, 0.28))
		draw_rect(Rect2(bp + Vector2(-29.0, wy - 4.0), Vector2(5.0, 8.0)), Color(1.0, 0.90, 0.48))

	# Brick chimney puffing cozy white animated smoke rings!
	var ch_pos := bp + Vector2(18.0, -28.0)
	draw_rect(Rect2(ch_pos - Vector2(6, 6), Vector2(12, 12)), Color(0.55, 0.22, 0.18))
	draw_rect(Rect2(ch_pos - Vector2(4, 4), Vector2(8, 8)), Color(0.16, 0.14, 0.14))
	for k in range(3):
		var ph: float = fmod(_time * 0.55 + float(k) * 0.33, 1.0)
		var sp := ch_pos + Vector2(ph * 18.0, -ph * 22.0)
		draw_circle(sp, lerpf(3.5, 10.5, ph), Color(0.95, 0.97, 1.0, (1.0 - ph) * 0.48))

	# Giant spinning golden North Star beacon on top of Santa's Workshop!
	var star_c := bp + Vector2(4.0, 16.0)
	draw_circle(star_c, 16.0, Color(1.0, 0.88, 0.32, 0.24))
	var star := PackedVector2Array()
	for s in range(10):
		var sa: float = float(s) * (TAU / 10.0) + _time * 1.1
		var sr: float = 12.5 if (s % 2 == 0) else 5.2
		star.append(star_c + Vector2(cos(sa) * sr, sin(sa) * sr))
	draw_colored_polygon(star, gold)
	draw_circle(star_c, 3.6, Color(1.0, 0.98, 0.86))

	# Twinkling fairy lights outlining the Workshop eaves
	var lights: Array[Color] = [Color(1.0, 0.24, 0.24), Color(0.24, 0.96, 0.46), gold, Color(0.40, 0.88, 1.0)]
	for i in range(6):
		var ly: float = bp.y + lerpf(-44.0, 44.0, float(i) / 5.0)
		var lc: Color = lights[i % lights.size()]
		var tw: float = 0.55 + 0.45 * sin(_time * 6.0 + float(i))
		draw_circle(Vector2(bp.x - 24.0, ly), 2.4, Color(lc.r, lc.g, lc.b, tw))

func _draw_christmas_props() -> void:
	# 1. Warm Glowing North Pole Lantern Posts
	for lp in _lanterns:
		var glow: float = 0.82 + 0.18 * sin(_time * 4.0 + lp.x * 0.05)
		draw_circle(lp, 26.0, Color(1.0, 0.80, 0.30, 0.16 * glow))
		draw_circle(lp, 12.0, Color(1.0, 0.88, 0.42, 0.32 * glow))
		draw_circle(lp, 3.8, Color(0.16, 0.18, 0.20))
		draw_circle(lp, 2.4, Color(1.0, 0.95, 0.65))

	# 2. Giant Peppermint Candy Canes
	for cc in _candy_canes:
		var p: Vector2 = cc["pos"]
		var ang: float = float(cc["ang"])
		var d := Vector2.from_angle(ang)
		var perp := Vector2(-d.y, d.x)
		# Shadow
		draw_line(p + Vector2(3, 4), p + Vector2(3, 4) - perp * 16.0, Color(0.06, 0.12, 0.24, 0.28), 5.2, true)
		# Curved candy cane hook + stem
		var pts := PackedVector2Array([
			p + perp * 6.0, p - perp * 10.0, p - perp * 14.0 + d * 4.0, p - perp * 12.0 + d * 8.0
		])
		draw_polyline(pts, Color(0.98, 0.98, 1.0), 5.2, true)
		draw_line(p + perp * 4.0, p + perp * 0.5, Color(0.90, 0.16, 0.18), 5.0, true)
		draw_line(p - perp * 3.5, p - perp * 7.0, Color(0.90, 0.16, 0.18), 5.0, true)
		draw_line(p - perp * 12.5 + d * 2.0, p - perp * 13.0 + d * 6.0, Color(0.90, 0.16, 0.18), 4.6, true)

	# 3. Wrapped Gift Box Piles
	var gift_cols: Array[Color] = [
		Color(0.88, 0.16, 0.20), Color(0.14, 0.66, 0.30),
		Color(0.20, 0.48, 0.88), Color(0.84, 0.24, 0.74)
	]
	for gp in _gift_piles:
		var center: Vector2 = gp["pos"]
		var sd: int = int(gp["seed"])
		var offsets: Array[Vector2] = [Vector2(-7, -4), Vector2(6, -5), Vector2(0, 6)]
		for i in range(offsets.size()):
			var p: Vector2 = center + offsets[i]
			var sz: float = 11.0 if i == 0 else 9.0
			var c: Color = gift_cols[(sd + i) % gift_cols.size()]
			draw_rect(Rect2(p - Vector2(sz * 0.5, sz * 0.5) + Vector2(2.2, 2.6), Vector2(sz, sz)), Color(0.05, 0.10, 0.20, 0.32))
			draw_rect(Rect2(p - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), c)
			draw_line(p - Vector2(sz * 0.5, 0), p + Vector2(sz * 0.5, 0), Color(1.0, 0.88, 0.30), 2.0)
			draw_line(p - Vector2(0, sz * 0.5), p + Vector2(0, sz * 0.5), Color(1.0, 0.88, 0.30), 2.0)

	# 4. Cheerful Snowmen with Top Hats, Carrot Noses & Red Scarves!
	for sm in _snowmen:
		var p: Vector2 = sm["pos"]
		var ang: float = float(sm["ang"])
		var d := Vector2.from_angle(ang)
		draw_circle(p + Vector2(4.5, 5.5), 11.5, Color(0.06, 0.12, 0.24, 0.28))
		# Snow body + scarf + head
		draw_circle(p, 10.5, Color(0.86, 0.91, 0.96))
		draw_circle(p + Vector2(-1.5, -1.5), 8.2, Color(0.96, 0.98, 1.0))
		# Red scarf tail
		draw_line(p, p + d * 11.0, Color(0.90, 0.18, 0.20), 3.4, true)
		# Bright orange carrot nose peeking out
		draw_line(p, p - d * 9.5, Color(0.98, 0.52, 0.12), 2.8, true)
		# Black top hat with crimson ribbon band
		draw_circle(p + Vector2(-1.2, -1.2), 6.2, Color(0.12, 0.12, 0.15))
		draw_arc(p + Vector2(-1.2, -1.2), 4.4, 0.0, TAU, 16, Color(0.90, 0.18, 0.20), 1.6, true)
		draw_circle(p + Vector2(-1.8, -1.8), 3.4, Color(0.22, 0.22, 0.26))

func _draw_buildings() -> void:
	for b in _buildings:
		var pos: Vector2 = b["pos"]
		var bw: float = float(b["w"])
		var bh: float = float(b["h"])
		var style: int = int(b["style"])
		var col: Color = b["color"]
		var half := Vector2(bw * 0.5, bh * 0.5)
		var rect := Rect2(pos - half, Vector2(bw, bh))

		# Crisp 3D directional building shadow cast SE
		var sh_off := Vector2(8.0, 9.5) if style != 3 else Vector2(6.5, 7.5)
		draw_rect(Rect2(rect.position + sh_off, rect.size), Color(0.0, 0.0, 0.0, 0.42))

		if style == 3:
			# Pleasant English Cotswold Stone Cottage (honey limestone walls + pitched terracotta/thatched roof + chimney!)
			draw_rect(Rect2(rect.position - Vector2(2, 2), rect.size + Vector2(4, 4)), Color(0.68, 0.62, 0.48))
			draw_rect(Rect2(rect.position, Vector2(bw, bh * 0.5)), col.lightened(0.16))
			draw_rect(Rect2(rect.position + Vector2(0, bh * 0.5), Vector2(bw, bh * 0.5)), col.darkened(0.14))
			draw_line(pos + Vector2(-bw * 0.48, 0), pos + Vector2(bw * 0.48, 0), col.lightened(0.32), 2.2)
			# Cozy brick chimney on roof
			draw_rect(Rect2(pos + Vector2(bw * 0.22, -bh * 0.28), Vector2(6, 6)), Color(0.46, 0.22, 0.16))
			draw_rect(Rect2(pos + Vector2(bw * 0.22 + 1.5, -bh * 0.28 + 1.5), Vector2(3, 3)), Color(0.14, 0.12, 0.12))
		elif style == 4:
			# Corrugated-iron Australian Outback Shed + cylindrical water tank!
			draw_rect(rect, col)
			draw_rect(Rect2(rect.position, Vector2(bw, bh * 0.5)), col.lightened(0.16))
			draw_line(pos + Vector2(-bw * 0.5, 0), pos + Vector2(bw * 0.5, 0), Color(0.76, 0.68, 0.58), 1.8)
			for rx in range(int(-bw * 0.4), int(bw * 0.45), 6):
				draw_line(pos + Vector2(float(rx), -bh * 0.48), pos + Vector2(float(rx), bh * 0.48), Color(0.25, 0.18, 0.14, 0.32), 1.0)
			# Corrugated galvanized rainwater tank beside shed
			var tk := pos + Vector2(bw * 0.5 + 8.0, 0.0)
			draw_circle(tk + Vector2(2.5, 3.0), 7.0, Color(0.0, 0.0, 0.0, 0.34))
			draw_circle(tk, 6.8, Color(0.56, 0.58, 0.56))
			draw_circle(tk + Vector2(-1.4, -1.4), 4.6, Color(0.72, 0.74, 0.72))
		elif style == 0:
			# Town pitched-roof terrace / townhouse
			draw_rect(Rect2(rect.position - Vector2(1.5, 1.5), rect.size + Vector2(3, 3)), Color(0.16, 0.17, 0.18))
			draw_rect(Rect2(rect.position, Vector2(bw, bh * 0.5)), col.lightened(0.16))
			draw_rect(Rect2(rect.position + Vector2(0, bh * 0.5), Vector2(bw, bh * 0.5)), col.darkened(0.16))
			draw_line(pos + Vector2(-bw * 0.48, 0), pos + Vector2(bw * 0.48, 0), col.lightened(0.30), 2.0)
			draw_rect(Rect2(pos + Vector2(-bw * 0.25, -bh * 0.24), Vector2(6, 6)), Color(0.32, 0.26, 0.24))
		else:
			# Town flat concrete roof commercial/industrial building with parapet & HVAC units!
			draw_rect(rect, col.darkened(0.18))
			draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6)), col)
			draw_line(rect.position, rect.position + Vector2(bw, 0), col.lightened(0.26), 1.6)
			draw_line(rect.position, rect.position + Vector2(0, bh), col.lightened(0.22), 1.6)
			# Rooftop HVAC box + skylight
			var hvac := Rect2(pos + Vector2(-bw * 0.24, -bh * 0.22), Vector2(10, 9))
			draw_rect(Rect2(hvac.position + Vector2(2, 2.5), hvac.size), Color(0.0, 0.0, 0.0, 0.34))
			draw_rect(hvac, Color(0.54, 0.56, 0.55))
			draw_circle(hvac.position + Vector2(5, 4.5), 3.0, Color(0.24, 0.26, 0.26))
			if style == 2:
				draw_rect(Rect2(pos + Vector2(4, -bh * 0.18), Vector2(bw * 0.26, bh * 0.36)), Color(0.28, 0.42, 0.50, 0.85))

func _draw_oaks() -> void:
	for o in _oaks:
		var pos: Vector2 = o["pos"]
		var r: float = float(o["radius"])
		var s: float = float(o["shade"])
		var kind: String = String(o["kind"])
		var puffs: Array = o["puffs"]

		var c_dark: Color
		var c_mid: Color
		var c_lit: Color
		if kind == "eucalyptus":
			# Silvery-sage Australian Eucalyptus Ghost Gum foliage!
			c_dark = Color(0.18 * s, 0.27 * s, 0.20 * s)
			c_mid = Color(0.28 * s, 0.39 * s, 0.29 * s)
			c_lit = Color(0.42 * s, 0.53 * s, 0.41 * s)
		elif kind == "oak":
			# Vibrant sunlit English countryside oak & beech
			c_dark = Color(0.11 * s, 0.24 * s, 0.09 * s)
			c_mid = Color(0.18 * s, 0.36 * s, 0.13 * s)
			c_lit = Color(0.30 * s, 0.48 * s, 0.18 * s)
		elif kind == "woodland":
			# Deep ancient Whisperwood forest oak (rich emerald + hints of autumn bronze!)
			c_dark = Color(0.08 * s, 0.19 * s, 0.08 * s)
			c_mid = Color(0.14 * s, 0.29 * s, 0.11 * s)
			c_lit = Color(0.26 * s, 0.38 * s, 0.14 * s)
		else:
			# Urban park broad-leaf tree
			c_dark = Color(0.12 * s, 0.24 * s, 0.11 * s)
			c_mid = Color(0.19 * s, 0.34 * s, 0.15 * s)
			c_lit = Color(0.28 * s, 0.44 * s, 0.20 * s)

		# Soft multi-layer broad-leaf shadow
		draw_circle(pos + Vector2(8.0, 9.0), r * 0.96, Color(0.0, 0.0, 0.0, 0.24))
		draw_circle(pos + Vector2(4.5, 5.0), r * 0.88, Color(0.0, 0.0, 0.0, 0.22))
		# Pale ghost-gum trunk peeking out on Eucalyptus trees!
		if kind == "eucalyptus":
			draw_line(pos, pos + Vector2(6.0, 7.0), Color(0.82, 0.80, 0.74, 0.85), 3.0, true)

		# Fluffy layered broad-leaf canopy puffs
		draw_circle(pos, r * 0.86, c_dark)
		for pf in puffs:
			var off: Vector2 = pf["off"]
			var pr: float = float(pf["r"])
			draw_circle(pos + off, pr, c_mid)
			draw_circle(pos + off + Vector2(-1.8, -1.8), pr * 0.64, c_lit)
		draw_circle(pos + Vector2(-3.0, -3.0), r * 0.44, c_lit.lightened(0.08))

func _draw_hay_bales() -> void:
	for hb in _hay_bales:
		var p: Vector2 = hb["pos"]
		var r: float = float(hb["r"])
		draw_circle(p + Vector2(2.6, 3.0), r, Color(0.0, 0.0, 0.0, 0.32))
		draw_circle(p, r, Color(0.72, 0.58, 0.22))
		draw_circle(p + Vector2(-1.2, -1.2), r * 0.68, Color(0.86, 0.72, 0.30))
		draw_arc(p, r * 0.55, 0.0, TAU, 14, Color(0.56, 0.42, 0.14, 0.65), 1.1, true)

func _draw_logs() -> void:
	for lg in _logs:
		var p: Vector2 = lg["pos"]
		var d := Vector2.from_angle(float(lg["ang"])) * (float(lg["len"]) * 0.5)
		draw_line(p - d + Vector2(2.5, 3.0), p + d + Vector2(2.5, 3.0), Color(0.0, 0.0, 0.0, 0.36), 6.2, true)
		draw_line(p - d, p + d, Color(0.24, 0.16, 0.10), 6.0, true)
		draw_line(p - d + Vector2(-0.8, -0.8), p + d + Vector2(-0.8, -0.8), Color(0.36, 0.26, 0.16), 2.4, true)
		# Green woodland moss clinging to fallen timber log
		draw_circle(p + d * 0.2, 3.2, Color(0.18, 0.34, 0.14, 0.85))
