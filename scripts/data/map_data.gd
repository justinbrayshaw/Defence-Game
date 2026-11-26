class_name MapData
extends RefCounted

const MAP_WIDTH: int = 1600
const MAP_HEIGHT: int = 960
const ROAD_WIDTH: float = 64.0
const RIVER_WIDTH: float = 78.0

static func get_all_maps() -> Array[Dictionary]:
	return [
		get_iron_valley(),
		get_scorched_wadi(),
		get_frostline_pass(),
		get_granite_gorge(),
		get_ironbourne(),
		get_cotswold_vale(),
		get_whisperwood(),
		get_red_centre(),
		get_coral_atoll(),
		get_obsidian_caldera(),
		get_bayou_delta(),
		get_neon_tokyo(),
		get_tranquility_crater(),
		get_olympus_rift(),
		get_europa_abyss(),
		get_xenon_prime(),
	]

static func get_map_by_id(map_id: String) -> Dictionary:
	if map_id == "north_pole":
		return get_north_pole()
	for m in get_all_maps():
		if String(m["id"]) == map_id:
			return m
	return get_iron_valley()

static func get_iron_valley() -> Dictionary:
	var ground_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 210),
		Vector2(345, 210),
		Vector2(394, 224),
		Vector2(410, 270),
		Vector2(410, 675),
		Vector2(426, 722),
		Vector2(472, 740),
		Vector2(755, 740),
		Vector2(802, 722),
		Vector2(820, 675),
		Vector2(820, 240),
		Vector2(838, 192),
		Vector2(885, 175),
		Vector2(1205, 175),
		Vector2(1252, 192),
		Vector2(1270, 240),
		Vector2(1270, 615),
		Vector2(1288, 662),
		Vector2(1335, 680),
		Vector2(1525, 680),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 105),
		Vector2(480, 285),
		Vector2(980, 455),
		Vector2(1525, 680),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1078, -50),
		Vector2(1056, 75),
		Vector2(1038, 175),
		Vector2(1022, 315),
		Vector2(1038, 495),
		Vector2(1018, 695),
		Vector2(996, 855),
		Vector2(978, 1020),
	])

	var bridge_pos := Vector2(1038, 175)

	var pads: Array[Vector2] = [
		Vector2(155, 118),
		Vector2(290, 118),
		Vector2(180, 305),
		Vector2(310, 305),
		Vector2(310, 465),
		Vector2(310, 625),
		Vector2(520, 260),
		Vector2(708, 260),
		Vector2(515, 415),
		Vector2(715, 415),
		Vector2(615, 515),
		Vector2(520, 630),
		Vector2(708, 630),
		Vector2(535, 838),
		Vector2(705, 838),
		Vector2(918, 82),
		Vector2(1158, 82),
		Vector2(922, 315),
		Vector2(922, 475),
		Vector2(922, 635),
		Vector2(1155, 295),
		Vector2(1155, 465),
		Vector2(1155, 620),
		Vector2(1375, 265),
		Vector2(1375, 435),
		Vector2(1382, 578),
		Vector2(1365, 782),
	]

	var coarse_main := _smooth_chaikin(ground_waypoints, 2)
	var smooth_main := _subdivide_polyline(coarse_main, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "iron_valley",
		"index": 1,
		"short_name": "IRON VALLEY",
		"name": "SECTOR 01 — IRON VALLEY",
		"tag": "ALPINE • 1 LANE • 15 WAVES",
		"biome": "alpine",
		"biome_id": 0,
		"seed": 4091337,
		"hp_scale": 1.0,
		"cash_bonus": 0,
		"briefing": "Enemy mechanized columns and gunships are pushing through the Iron Valley corridor. Hold the river crossing and protect Command HQ.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_main],
		"ground_coarses": [coarse_main],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": bridge_pos,
		"bridges": [bridge_pos],
		"base_pos": Vector2(1525, 680),
		"spawn_positions": [Vector2(18, 210)],
		"air_spawn_pos": Vector2(18, 130),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(458, 160), "angle": 0.25},
			{"pos": Vector2(615, 352), "angle": 0.0},
			{"pos": Vector2(960, 236), "angle": -0.38},
			{"pos": Vector2(1118, 236), "angle": 0.38},
			{"pos": Vector2(1430, 616), "angle": 0.0},
			{"pos": Vector2(1430, 742), "angle": 0.0},
		],
		"bunkers": [
			{"pos": Vector2(615, 168), "angle": PI * 0.5},
			{"pos": Vector2(215, 535), "angle": 0.0},
			{"pos": Vector2(1440, 160), "angle": PI * 0.8},
		],
	}

static func get_scorched_wadi() -> Dictionary:
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 225),
		Vector2(325, 225),
		Vector2(374, 245),
		Vector2(392, 295),
		Vector2(392, 435),
		Vector2(414, 474),
		Vector2(465, 485),
		Vector2(865, 485),
		Vector2(912, 464),
		Vector2(930, 412),
		Vector2(930, 228),
		Vector2(950, 186),
		Vector2(996, 175),
		Vector2(1218, 175),
		Vector2(1265, 196),
		Vector2(1285, 245),
		Vector2(1285, 645),
		Vector2(1304, 692),
		Vector2(1352, 710),
		Vector2(1525, 710),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 765),
		Vector2(375, 765),
		Vector2(432, 742),
		Vector2(455, 686),
		Vector2(455, 545),
		Vector2(476, 502),
		Vector2(525, 485),
		Vector2(865, 485),
		Vector2(912, 464),
		Vector2(930, 412),
		Vector2(930, 228),
		Vector2(950, 186),
		Vector2(996, 175),
		Vector2(1218, 175),
		Vector2(1265, 196),
		Vector2(1285, 245),
		Vector2(1285, 645),
		Vector2(1304, 692),
		Vector2(1352, 710),
		Vector2(1525, 710),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 855),
		Vector2(580, 610),
		Vector2(1080, 415),
		Vector2(1525, 710),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(746, -50),
		Vector2(762, 155),
		Vector2(775, 330),
		Vector2(775, 485),
		Vector2(766, 650),
		Vector2(742, 825),
		Vector2(716, 1020),
	])

	var bridge_pos := Vector2(775, 485)

	var pads: Array[Vector2] = [
		Vector2(155, 125),
		Vector2(295, 125),
		Vector2(180, 330),
		Vector2(295, 330),
		Vector2(175, 655),
		Vector2(325, 655),
		Vector2(235, 860),
		Vector2(415, 860),
		Vector2(510, 265),
		Vector2(645, 265),
		Vector2(645, 125),
		Vector2(565, 385),
		Vector2(565, 595),
		Vector2(645, 725),
		Vector2(855, 120),
		Vector2(862, 615),
		Vector2(862, 775),
		Vector2(1045, 285),
		Vector2(1180, 285),
		Vector2(1045, 435),
		Vector2(1180, 435),
		Vector2(1112, 560),
		Vector2(1045, 685),
		Vector2(1180, 685),
		Vector2(1390, 275),
		Vector2(1390, 440),
		Vector2(1395, 595),
		Vector2(1370, 815),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "scorched_wadi",
		"index": 2,
		"short_name": "SCORCHED WADI",
		"name": "SECTOR 02 — SCORCHED WADI",
		"tag": "DESERT • 2 LANES • 16 WAVES",
		"biome": "desert",
		"biome_id": 1,
		"seed": 8842109,
		"hp_scale": 1.08,
		"cash_bonus": 15,
		"briefing": "Armored divisions are advancing along twin desert highways toward the Oasis Crossing while strike aircraft flank from the south-west. Hold the convergence choke and fortify the sandstone plateau.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_s],
		"ground_coarses": [coarse_n, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": bridge_pos,
		"bridges": [bridge_pos],
		"base_pos": Vector2(1525, 710),
		"spawn_positions": [Vector2(18, 225), Vector2(18, 765)],
		"air_spawn_pos": Vector2(18, 825),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(698, 425), "angle": -0.35},
			{"pos": Vector2(698, 545), "angle": 0.35},
			{"pos": Vector2(852, 425), "angle": 0.35},
			{"pos": Vector2(852, 545), "angle": -0.35},
			{"pos": Vector2(1432, 646), "angle": 0.0},
			{"pos": Vector2(1432, 774), "angle": 0.0},
		],
		"bunkers": [
			{"pos": Vector2(1112, 78), "angle": PI * 0.5},
			{"pos": Vector2(160, 495), "angle": 0.0},
			{"pos": Vector2(1445, 165), "angle": PI * 0.8},
		],
	}

static func get_frostline_pass() -> Dictionary:
	# SECTOR 03 — TOP-TO-BOTTOM GLACIAL FJORD: Horizontal frozen river across the center,
	# enemies invading from North-West & North-East across twin VERTICAL bridges toward South HQ!
	var lane_west_raw: PackedVector2Array = PackedVector2Array([
		Vector2(260, -60),
		Vector2(260, 225),
		Vector2(290, 272),
		Vector2(355, 290),
		Vector2(415, 290),
		Vector2(448, 325),
		Vector2(455, 390),
		Vector2(455, 625),
		Vector2(422, 668),
		Vector2(355, 682),
		Vector2(280, 682),
		Vector2(248, 725),
		Vector2(248, 805),
		Vector2(292, 855),
		Vector2(375, 868),
		Vector2(800, 868),
	])

	var lane_east_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1340, -60),
		Vector2(1340, 225),
		Vector2(1310, 272),
		Vector2(1245, 290),
		Vector2(1185, 290),
		Vector2(1152, 325),
		Vector2(1145, 390),
		Vector2(1145, 625),
		Vector2(1178, 668),
		Vector2(1245, 682),
		Vector2(1320, 682),
		Vector2(1352, 725),
		Vector2(1352, 805),
		Vector2(1308, 855),
		Vector2(1225, 868),
		Vector2(800, 868),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(800, -60),
		Vector2(800, 340),
		Vector2(800, 620),
		Vector2(800, 868),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 472),
		Vector2(220, 488),
		Vector2(455, 480),
		Vector2(800, 462),
		Vector2(1145, 480),
		Vector2(1380, 488),
		Vector2(1660, 472),
	])

	var bridge_west := {"pos": Vector2(455, 480), "angle": PI * 0.5}
	var bridge_east := {"pos": Vector2(1145, 480), "angle": PI * 0.5}

	var pads: Array[Vector2] = [
		# Northern Arctic Approaches
		Vector2(142, 130),
		Vector2(142, 295),
		Vector2(385, 135),
		Vector2(575, 195),
		Vector2(575, 345),
		Vector2(800, 155),
		Vector2(800, 320),
		Vector2(1025, 195),
		Vector2(1025, 345),
		Vector2(1215, 135),
		Vector2(1458, 130),
		Vector2(1458, 295),
		# Southern Glacial Bank & HQ Fortress Perimeter
		Vector2(135, 620),
		Vector2(135, 795),
		Vector2(325, 588),
		Vector2(575, 615),
		Vector2(575, 760),
		Vector2(685, 685),
		Vector2(800, 615),
		Vector2(800, 735),
		Vector2(915, 685),
		Vector2(1025, 615),
		Vector2(1025, 760),
		Vector2(1275, 588),
		Vector2(1465, 620),
		Vector2(1465, 795),
		Vector2(445, 775),
		Vector2(1155, 775),
	]

	var coarse_w := _smooth_chaikin(lane_west_raw, 2)
	var coarse_e := _smooth_chaikin(lane_east_raw, 2)
	var smooth_w := _subdivide_polyline(coarse_w, 18.0)
	var smooth_e := _subdivide_polyline(coarse_e, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "frostline_pass",
		"index": 3,
		"short_name": "FROSTLINE PASS",
		"name": "SECTOR 03 — FROSTLINE PASS",
		"tag": "TUNDRA • NORTH→SOUTH • 17 WAVES",
		"biome": "tundra",
		"biome_id": 2,
		"seed": 6129443,
		"hp_scale": 1.06,
		"cash_bonus": 35,
		"briefing": "Heavy winter convoys are descending from the northern glacier across two vertical ice bridges spanning the East-West fjord while gunships dive straight south toward Arctic HQ.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_w, smooth_e],
		"ground_coarses": [coarse_w, coarse_e],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(455, 480),
		"bridges": [bridge_west, bridge_east],
		"base_pos": Vector2(800, 868),
		"spawn_positions": [Vector2(260, 18), Vector2(1340, 18)],
		"air_spawn_pos": Vector2(800, 18),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(395, 392), "angle": 0.30},
			{"pos": Vector2(515, 392), "angle": -0.30},
			{"pos": Vector2(1085, 392), "angle": 0.30},
			{"pos": Vector2(1205, 392), "angle": -0.30},
		],
		"bunkers": [
			{"pos": Vector2(685, 240), "angle": 0.0},
			{"pos": Vector2(915, 240), "angle": PI},
		],
	}

static func get_granite_gorge() -> Dictionary:
	# SECTOR 04 — GIANT 3-TIER MOUNTAIN SWITCHBACK + SOUTH CANYON SHORTCUT:
	# Convoys snake across the entire massif (West->East->West->East) over a diagonal mountain gorge!
	var lane_switchback_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 815),
		Vector2(1240, 815),
		Vector2(1310, 792),
		Vector2(1335, 725),
		Vector2(1335, 585),
		Vector2(1308, 520),
		Vector2(1240, 495),
		Vector2(325, 495),
		Vector2(255, 470),
		Vector2(230, 405),
		Vector2(230, 265),
		Vector2(255, 200),
		Vector2(325, 175),
		Vector2(1495, 175),
	])

	var lane_shortcut_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1110, 1020),
		Vector2(1110, 880),
		Vector2(1150, 830),
		Vector2(1240, 815),
		Vector2(1310, 792),
		Vector2(1335, 725),
		Vector2(1335, 585),
		Vector2(1308, 520),
		Vector2(1240, 495),
		Vector2(325, 495),
		Vector2(255, 470),
		Vector2(230, 405),
		Vector2(230, 265),
		Vector2(255, 200),
		Vector2(325, 175),
		Vector2(1495, 175),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 845),
		Vector2(540, 610),
		Vector2(1040, 385),
		Vector2(1495, 175),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(965, -50),
		Vector2(920, 175),
		Vector2(855, 345),
		Vector2(785, 495),
		Vector2(705, 665),
		Vector2(635, 815),
		Vector2(565, 1020),
	])

	var bridge_high := {"pos": Vector2(920, 175), "angle": 0.0}
	var bridge_mid := {"pos": Vector2(785, 495), "angle": 0.0}
	var bridge_low := {"pos": Vector2(635, 815), "angle": 0.0}

	var pads: Array[Vector2] = [
		# High Summit Ridge (North)
		Vector2(135, 115),
		Vector2(365, 82),
		Vector2(565, 82),
		Vector2(765, 82),
		Vector2(1075, 82),
		Vector2(1285, 82),
		# Upper Valley Terrace (Between High & Mid switchbacks)
		Vector2(122, 335),
		Vector2(365, 335),
		Vector2(535, 335),
		Vector2(700, 335),
		Vector2(1015, 335),
		Vector2(1185, 335),
		Vector2(1355, 335),
		Vector2(1485, 335),
		# Lower Valley Terrace (Between Mid & Low switchbacks)
		Vector2(165, 655),
		Vector2(365, 655),
		Vector2(540, 655),
		Vector2(855, 655),
		Vector2(1020, 655),
		Vector2(1185, 655),
		Vector2(1455, 585),
		Vector2(1455, 745),
		# Southern Foothills
		Vector2(215, 902),
		Vector2(435, 902),
		Vector2(835, 902),
		Vector2(975, 902),
		Vector2(1285, 902),
	]

	var coarse_a := _smooth_chaikin(lane_switchback_raw, 2)
	var coarse_b := _smooth_chaikin(lane_shortcut_raw, 2)
	var smooth_a := _subdivide_polyline(coarse_a, 18.0)
	var smooth_b := _subdivide_polyline(coarse_b, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "granite_gorge",
		"index": 4,
		"short_name": "GRANITE GORGE",
		"name": "SECTOR 04 — GRANITE GORGE",
		"tag": "MOUNTAIN • SWITCHBACK • 18 WAVES",
		"biome": "mountain",
		"biome_id": 3,
		"seed": 3187651,
		"hp_scale": 1.20,
		"cash_bonus": 45,
		"briefing": "Enemy armor is climbing the massive 3-tier Granite Gorge switchbacks—crossing the diagonal glacier torrent three times—while raiders flank up the South-East ravine toward Summit Citadel.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_a, smooth_b],
		"ground_coarses": [coarse_a, coarse_b],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(785, 495),
		"bridges": [bridge_high, bridge_mid, bridge_low],
		"base_pos": Vector2(1495, 175),
		"spawn_positions": [Vector2(18, 815), Vector2(1110, 942)],
		"air_spawn_pos": Vector2(18, 815),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(842, 118), "angle": 0.28},
			{"pos": Vector2(998, 118), "angle": -0.28},
			{"pos": Vector2(705, 438), "angle": 0.28},
			{"pos": Vector2(865, 438), "angle": -0.28},
		],
		"bunkers": [
			{"pos": Vector2(1465, 465), "angle": PI},
		],
	}

static func get_north_pole() -> Dictionary:
	# SECRET CHRISTMAS LEVEL: Santa's North Pole Workshop!
	# Runaway clockwork toys march down Peppermint Lane & Gingerbread Lane across twin
	# fairy-lit Candy Bridges over the Aurora Ice Canal toward Santa's Workshop.
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 205),
		Vector2(330, 205),
		Vector2(376, 226),
		Vector2(394, 275),
		Vector2(394, 338),
		Vector2(416, 376),
		Vector2(462, 388),
		Vector2(632, 388),
		Vector2(678, 372),
		Vector2(696, 326),
		Vector2(696, 260),
		Vector2(716, 218),
		Vector2(762, 205),
		Vector2(1122, 205),
		Vector2(1168, 226),
		Vector2(1188, 278),
		Vector2(1188, 428),
		Vector2(1210, 468),
		Vector2(1260, 480),
		Vector2(1515, 480),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 755),
		Vector2(330, 755),
		Vector2(376, 734),
		Vector2(394, 685),
		Vector2(394, 622),
		Vector2(416, 584),
		Vector2(462, 572),
		Vector2(632, 572),
		Vector2(678, 588),
		Vector2(696, 634),
		Vector2(696, 700),
		Vector2(716, 742),
		Vector2(762, 755),
		Vector2(1122, 755),
		Vector2(1168, 734),
		Vector2(1188, 682),
		Vector2(1188, 532),
		Vector2(1210, 492),
		Vector2(1260, 480),
		Vector2(1515, 480),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 480),
		Vector2(540, 320),
		Vector2(1035, 640),
		Vector2(1515, 480),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(870, -50),
		Vector2(880, 100),
		Vector2(885, 205),
		Vector2(902, 390),
		Vector2(874, 575),
		Vector2(885, 755),
		Vector2(895, 900),
		Vector2(905, 1020),
	])

	var bridge_north := Vector2(885, 205)
	var bridge_south := Vector2(885, 755)

	var pads: Array[Vector2] = [
		# West Peppermint & Gingerbread approaches
		Vector2(155, 105),
		Vector2(290, 105),
		Vector2(165, 315),
		Vector2(288, 315),
		Vector2(225, 480),
		Vector2(165, 645),
		Vector2(288, 645),
		Vector2(155, 855),
		Vector2(290, 855),
		# Central Toybox Courtyard & Spine
		Vector2(548, 265),
		Vector2(490, 480),
		Vector2(618, 480),
		Vector2(548, 695),
		# Candy Bridge overlooks
		Vector2(765, 102),
		Vector2(1012, 102),
		Vector2(765, 858),
		Vector2(1012, 858),
		# East Aurora Courtyard (between Aurora Canal & Workshop Lane)
		Vector2(1015, 328),
		Vector2(1095, 418),
		Vector2(1005, 480),
		Vector2(1095, 542),
		Vector2(1015, 632),
		# Santa's Workshop Courtyard Perimeter
		Vector2(1302, 260),
		Vector2(1358, 378),
		Vector2(1358, 582),
		Vector2(1302, 700),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "north_pole",
		"index": 99,
		"is_secret": true,
		"festive_mode": true,
		"short_name": "NORTH POLE",
		"name": "★ SECRET SECTOR — SANTA'S NORTH POLE ★",
		"tag": "CHRISTMAS SPECIAL • 12 WAVES",
		"biome": "christmas",
		"biome_id": 4,
		"seed": 12252026,
		"hp_scale": 1.10,
		"cash_bonus": 60,
		"briefing": "A mischievous clockwork glitch in Santa's Toy Factory has set hundreds of wind-up racers, choo-choo trains, nutcrackers, and whirlybirds loose! Pop and re-wrap the runaway toys before they crash the Gift Vault!",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_s],
		"ground_coarses": [coarse_n, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": bridge_north,
		"bridges": [bridge_north, bridge_south],
		"base_pos": Vector2(1515, 480),
		"spawn_positions": [Vector2(18, 205), Vector2(18, 755)],
		"air_spawn_pos": Vector2(18, 480),
		"pads": pads,
		"sandbags": [],
		"bunkers": [],
	}

static func get_ironbourne() -> Dictionary:
	# SECTOR 05 — TOWN / URBAN WARFRONT: Grid-like downtown avenues, central canal with two
	# urban bridges, brick rooftops, city parks, and an eastern civic loop to Town Hall HQ.
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 175),
		Vector2(500, 175),
		Vector2(548, 196),
		Vector2(565, 245),
		Vector2(565, 425),
		Vector2(586, 468),
		Vector2(635, 480),
		Vector2(1065, 480),
		Vector2(1112, 458),
		Vector2(1130, 408),
		Vector2(1130, 232),
		Vector2(1152, 188),
		Vector2(1202, 175),
		Vector2(1325, 175),
		Vector2(1372, 198),
		Vector2(1390, 250),
		Vector2(1390, 622),
		Vector2(1412, 665),
		Vector2(1455, 678),
		Vector2(1525, 678),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 785),
		Vector2(1125, 785),
		Vector2(1174, 764),
		Vector2(1195, 718),
		Vector2(1218, 686),
		Vector2(1265, 678),
		Vector2(1525, 678),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 480),
		Vector2(520, 480),
		Vector2(1020, 560),
		Vector2(1525, 678),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(815, -50),
		Vector2(815, 240),
		Vector2(815, 480),
		Vector2(815, 785),
		Vector2(815, 1020),
	])

	var bridge_mid := Vector2(815, 480)
	var bridge_south := Vector2(815, 785)

	var pads: Array[Vector2] = [
		# West High Street & Downtown blocks
		Vector2(155, 86),
		Vector2(340, 86),
		Vector2(155, 285),
		Vector2(345, 285),
		Vector2(460, 290),
		Vector2(460, 445),
		# West South Avenue & Central Park
		Vector2(175, 675),
		Vector2(355, 675),
		Vector2(555, 675),
		Vector2(255, 878),
		Vector2(475, 878),
		Vector2(660, 878),
		# West Canal Embankment
		Vector2(692, 195),
		Vector2(692, 355),
		Vector2(692, 625),
		# East Canal Embankment
		Vector2(945, 195),
		Vector2(945, 355),
		Vector2(945, 625),
		Vector2(975, 878),
		# East Civic Plaza & Town Hall perimeter
		Vector2(1258, 290),
		Vector2(1258, 435),
		Vector2(1258, 565),
		Vector2(1065, 625),
		Vector2(1320, 785),
		Vector2(1485, 260),
		Vector2(1485, 430),
		Vector2(1485, 550),
		Vector2(1145, 86),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 2)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "ironbourne",
		"index": 5,
		"short_name": "IRONBOURNE",
		"name": "SECTOR 05 — TOWN OF IRONBOURNE",
		"tag": "TOWN • URBAN GRID • 19 WAVES",
		"biome": "town",
		"biome_id": 5,
		"seed": 5019283,
		"hp_scale": 1.14,
		"cash_bonus": 55,
		"briefing": "Hostile columns have pushed into Ironbourne's street grid. One spearhead snakes through Downtown and the Central Canal while a fast southern force races down Rail Avenue toward Town Hall HQ.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_s],
		"ground_coarses": [coarse_n, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": bridge_mid,
		"bridges": [bridge_mid, bridge_south],
		"base_pos": Vector2(1525, 678),
		"spawn_positions": [Vector2(18, 175), Vector2(18, 785)],
		"air_spawn_pos": Vector2(18, 480),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(738, 422), "angle": -0.30},
			{"pos": Vector2(892, 422), "angle": 0.30},
			{"pos": Vector2(738, 728), "angle": -0.30},
			{"pos": Vector2(892, 728), "angle": 0.30},
			{"pos": Vector2(1430, 616), "angle": 0.0},
			{"pos": Vector2(1430, 742), "angle": 0.0},
		],
		"bunkers": [],
	}

static func get_cotswold_vale() -> Dictionary:
	# SECTOR 06 — PLEASANT ENGLISH COUNTRYSIDE: Patchwork emerald pastures & golden wheat fields,
	# butterfly split-merge-split lanes converging across an old stone bridge before splitting
	# around rolling farmland toward Manor Estate HQ.
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 205),
		Vector2(405, 205),
		Vector2(455, 228),
		Vector2(478, 285),
		Vector2(478, 415),
		Vector2(504, 462),
		Vector2(558, 480),
		Vector2(1112, 480),
		Vector2(1164, 456),
		Vector2(1188, 402),
		Vector2(1188, 248),
		Vector2(1214, 198),
		Vector2(1268, 182),
		Vector2(1425, 182),
		Vector2(1476, 208),
		Vector2(1515, 265),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 765),
		Vector2(405, 765),
		Vector2(455, 742),
		Vector2(478, 685),
		Vector2(478, 545),
		Vector2(504, 498),
		Vector2(558, 480),
		Vector2(1112, 480),
		Vector2(1164, 504),
		Vector2(1188, 558),
		Vector2(1188, 712),
		Vector2(1214, 762),
		Vector2(1268, 778),
		Vector2(1395, 778),
		Vector2(1445, 752),
		Vector2(1468, 695),
		Vector2(1468, 365),
		Vector2(1485, 305),
		Vector2(1515, 265),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 740),
		Vector2(560, 565),
		Vector2(1060, 390),
		Vector2(1515, 265),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(952, -50),
		Vector2(936, 180),
		Vector2(915, 480),
		Vector2(894, 740),
		Vector2(870, 1020),
	])

	var bridge_center := Vector2(915, 480)

	var pads: Array[Vector2] = [
		# West Meadow & Orchard Lanes
		Vector2(160, 106),
		Vector2(335, 106),
		Vector2(165, 315),
		Vector2(365, 315),
		Vector2(245, 480),
		Vector2(165, 655),
		Vector2(365, 655),
		Vector2(175, 862),
		Vector2(365, 862),
		# Central Stone Bridge Approaches (West of stream)
		Vector2(598, 245),
		Vector2(598, 375),
		Vector2(768, 375),
		Vector2(598, 588),
		Vector2(768, 588),
		Vector2(598, 725),
		Vector2(765, 215),
		Vector2(748, 765),
		# East Pastures (East of stream, between split lanes!)
		Vector2(1055, 215),
		Vector2(1055, 368),
		Vector2(1055, 592),
		Vector2(1055, 758),
		# Far East Manor Meadows
		Vector2(1328, 305),
		Vector2(1328, 480),
		Vector2(1328, 652),
		Vector2(1315, 88),
		Vector2(1315, 875),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "cotswold_vale",
		"index": 6,
		"short_name": "COTSWOLD VALE",
		"name": "SECTOR 06 — COTSWOLD VALE",
		"tag": "COUNTRYSIDE • SPLIT • 20 WAVES",
		"biome": "countryside",
		"biome_id": 6,
		"seed": 6044812,
		"hp_scale": 1.20,
		"cash_bonus": 65,
		"briefing": "Enemy armor is rolling through peaceful English country lanes, converging over the old Stone Bridge before splitting around the golden wheat fields toward Manor HQ. Hold the bridge choke and guard both eastern meadows.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_s],
		"ground_coarses": [coarse_n, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": bridge_center,
		"bridges": [bridge_center],
		"base_pos": Vector2(1515, 265),
		"spawn_positions": [Vector2(18, 205), Vector2(18, 765)],
		"air_spawn_pos": Vector2(18, 720),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(835, 420), "angle": -0.32},
			{"pos": Vector2(835, 540), "angle": 0.32},
			{"pos": Vector2(995, 420), "angle": 0.32},
			{"pos": Vector2(995, 540), "angle": -0.32},
		],
		"bunkers": [],
	}

static func get_whisperwood() -> Dictionary:
	# SECTOR 07 — WHISPERWOOD FIGURE-8 CROSSROADS: Two forest logging trails physically CROSS
	# in a central sunlit X-clearing before splitting to twin eastern woodland creek bridges!
	var lane_a_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 175),
		Vector2(305, 175),
		Vector2(380, 200),
		Vector2(505, 345),
		Vector2(630, 480),
		Vector2(760, 620),
		Vector2(860, 745),
		Vector2(945, 775),
		Vector2(1245, 775),
		Vector2(1310, 748),
		Vector2(1345, 680),
		Vector2(1375, 560),
		Vector2(1420, 495),
		Vector2(1515, 480),
	])

	var lane_b_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 785),
		Vector2(305, 785),
		Vector2(380, 760),
		Vector2(505, 615),
		Vector2(630, 480),
		Vector2(760, 340),
		Vector2(860, 215),
		Vector2(945, 185),
		Vector2(1245, 185),
		Vector2(1310, 212),
		Vector2(1345, 280),
		Vector2(1375, 400),
		Vector2(1420, 465),
		Vector2(1515, 480),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 480),
		Vector2(630, 480),
		Vector2(1100, 480),
		Vector2(1515, 480),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1078, -50),
		Vector2(1082, 95),
		Vector2(1085, 185),
		Vector2(1105, 385),
		Vector2(1065, 585),
		Vector2(1085, 775),
		Vector2(1098, 900),
		Vector2(1110, 1020),
	])

	var bridge_north := {"pos": Vector2(1085, 185), "angle": 0.0}
	var bridge_south := {"pos": Vector2(1085, 775), "angle": 0.0}

	var pads: Array[Vector2] = [
		# West Timber Approaches
		Vector2(145, 82),
		Vector2(290, 82),
		Vector2(148, 305),
		Vector2(285, 340),
		Vector2(175, 480),
		Vector2(345, 480),
		Vector2(148, 655),
		Vector2(285, 620),
		Vector2(145, 878),
		Vector2(290, 878),
		# Central X-Crossroads Killzone!
		Vector2(630, 185),
		Vector2(630, 320),
		Vector2(495, 480),
		Vector2(775, 480),
		Vector2(630, 640),
		Vector2(630, 775),
		Vector2(465, 878),
		Vector2(465, 82),
		# West Creek Bank
		Vector2(955, 84),
		Vector2(950, 355),
		Vector2(950, 605),
		Vector2(955, 876),
		# East Creek Bank & Forest HQ Perimeter
		Vector2(1215, 84),
		Vector2(1218, 335),
		Vector2(1218, 480),
		Vector2(1218, 625),
		Vector2(1215, 876),
		Vector2(1445, 295),
	]

	var coarse_a := _smooth_chaikin(lane_a_raw, 2)
	var coarse_b := _smooth_chaikin(lane_b_raw, 2)
	var smooth_a := _subdivide_polyline(coarse_a, 18.0)
	var smooth_b := _subdivide_polyline(coarse_b, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "whisperwood",
		"index": 7,
		"short_name": "WHISPERWOOD",
		"name": "SECTOR 07 — WHISPERWOOD FOREST",
		"tag": "FOREST • X-CROSSING • 21 WAVES",
		"biome": "forest",
		"biome_id": 7,
		"seed": 7712904,
		"hp_scale": 1.24,
		"cash_bonus": 75,
		"briefing": "Two forest logging convoys cross directly through Whisperwood's central sunlit X-clearing before splitting toward twin eastern creek bridges. Dominate the central crossroads!",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_a, smooth_b],
		"ground_coarses": [coarse_a, coarse_b],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(1085, 185),
		"bridges": [bridge_north, bridge_south],
		"base_pos": Vector2(1515, 480),
		"spawn_positions": [Vector2(18, 175), Vector2(18, 785)],
		"air_spawn_pos": Vector2(18, 480),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(1005, 130), "angle": 0.25},
			{"pos": Vector2(1165, 130), "angle": -0.25},
			{"pos": Vector2(1005, 830), "angle": -0.25},
			{"pos": Vector2(1165, 830), "angle": 0.25},
		],
		"bunkers": [
			{"pos": Vector2(1455, 685), "angle": -PI * 0.78},
		],
	}

static func get_red_centre() -> Dictionary:
	# SECTOR 08 — THE AUSTRALIAN OUTBACK: 3-FRONT CONVERGENCE!
	# Three separate red-dirt tracks pour in from NORTH, WEST, and SOUTH-WEST across a diagonal
	# Billabong creek spanned by THREE bridges converging on East-South Outback Station!
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(360, -60),
		Vector2(360, 155),
		Vector2(405, 200),
		Vector2(1265, 200),
		Vector2(1340, 232),
		Vector2(1370, 305),
		Vector2(1370, 520),
		Vector2(1405, 588),
		Vector2(1495, 610),
	])

	var lane_mid_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 485),
		Vector2(540, 485),
		Vector2(635, 445),
		Vector2(760, 445),
		Vector2(845, 485),
		Vector2(1245, 485),
		Vector2(1335, 530),
		Vector2(1395, 595),
		Vector2(1495, 610),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 810),
		Vector2(1185, 810),
		Vector2(1265, 780),
		Vector2(1330, 710),
		Vector2(1395, 635),
		Vector2(1495, 610),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(120, -60),
		Vector2(620, 260),
		Vector2(1080, 440),
		Vector2(1495, 610),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1195, -50),
		Vector2(1115, 200),
		Vector2(1025, 485),
		Vector2(925, 810),
		Vector2(860, 1020),
	])

	var bridge_n := {"pos": Vector2(1115, 200), "angle": 0.0}
	var bridge_m := {"pos": Vector2(1025, 485), "angle": 0.0}
	var bridge_s := {"pos": Vector2(925, 810), "angle": 0.0}

	var pads: Array[Vector2] = [
		# Northwest Outback Flats
		Vector2(155, 130),
		Vector2(235, 285),
		Vector2(155, 365),
		Vector2(490, 92),
		Vector2(685, 92),
		Vector2(885, 92),
		# Between North & Mid Tracks
		Vector2(465, 335),
		Vector2(645, 325),
		Vector2(825, 325),
		Vector2(965, 335),
		# Between Mid & South Tracks
		Vector2(155, 645),
		Vector2(345, 645),
		Vector2(535, 645),
		Vector2(725, 645),
		Vector2(865, 645),
		# Southern Spinifex Verge
		Vector2(225, 902),
		Vector2(465, 902),
		Vector2(725, 902),
		# East of Billabong Creek
		Vector2(1245, 92),
		Vector2(1225, 338),
		Vector2(1165, 645),
		Vector2(1065, 902),
		Vector2(1275, 895),
		# Station HQ Perimeter
		Vector2(1475, 275),
		Vector2(1475, 445),
		Vector2(1465, 765),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_m := _smooth_chaikin(lane_mid_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_m := _subdivide_polyline(coarse_m, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "red_centre",
		"index": 8,
		"short_name": "RED CENTRE",
		"name": "SECTOR 08 — THE AUSTRALIAN OUTBACK",
		"tag": "OUTBACK • 3 LANES • 22 WAVES",
		"biome": "outback",
		"biome_id": 8,
		"seed": 8806142,
		"hp_scale": 1.22,
		"cash_bonus": 90,
		"briefing": "Three mechanized divisions are converging from the North, West, and South-West across the blistering iron-red tracks of the Outback! Guard all three Billabong crossings before they overwhelm Station HQ.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_m, smooth_s],
		"ground_coarses": [coarse_n, coarse_m, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(1025, 485),
		"bridges": [bridge_n, bridge_m, bridge_s],
		"base_pos": Vector2(1495, 610),
		"spawn_positions": [Vector2(360, 18), Vector2(18, 485), Vector2(18, 810)],
		"air_spawn_pos": Vector2(150, 18),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(1035, 145), "angle": 0.28},
			{"pos": Vector2(1195, 145), "angle": -0.28},
			{"pos": Vector2(945, 430), "angle": 0.28},
			{"pos": Vector2(1105, 430), "angle": -0.28},
		],
		"bunkers": [],
	}

static func get_coral_atoll() -> Dictionary:
	# SECTOR 09 — PACIFIC CORAL ATOLL: True aerial coral atoll ring surrounded by deep Pacific Ocean,
	# a wide glowing turquoise coral lagoon, and a Central Palm Island HQ!
	# Two long ~2,200px opposing ring routes sweep around the outer sandy islets before crossing
	# North & South vertical lagoon bridges and spiraling into the Central Island Citadel!
	var lane_west_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 775),
		Vector2(130, 775),
		Vector2(168, 742),
		Vector2(175, 685),
		Vector2(175, 225),
		Vector2(198, 168),
		Vector2(265, 148),
		Vector2(745, 148),
		Vector2(792, 178),
		Vector2(800, 232),
		Vector2(800, 345),
		Vector2(768, 378),
		Vector2(620, 378),
		Vector2(575, 412),
		Vector2(575, 452),
		Vector2(615, 480),
		Vector2(800, 480),
	])

	var lane_east_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1660, 185),
		Vector2(1470, 185),
		Vector2(1432, 218),
		Vector2(1425, 275),
		Vector2(1425, 735),
		Vector2(1402, 792),
		Vector2(1335, 812),
		Vector2(855, 812),
		Vector2(808, 782),
		Vector2(800, 728),
		Vector2(800, 615),
		Vector2(832, 582),
		Vector2(980, 582),
		Vector2(1025, 548),
		Vector2(1025, 508),
		Vector2(985, 480),
		Vector2(800, 480),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 140),
		Vector2(380, 305),
		Vector2(800, 480),
	])

	# Closed oval turquoise coral lagoon encircling the Central Palm Island (rx=505, ry=210)!
	var river_raw := PackedVector2Array()
	var segs: int = 36
	for i in range(segs + 1):
		var a: float = float(i) / float(segs) * TAU
		river_raw.append(Vector2(800.0 + cos(a) * 505.0, 480.0 + sin(a) * 210.0))

	var bridge_north := {"pos": Vector2(800, 270), "angle": PI * 0.5}
	var bridge_south := {"pos": Vector2(800, 690), "angle": PI * 0.5}

	var pads: Array[Vector2] = [
		# Outer West Coral Sandbar
		Vector2(82, 345),
		Vector2(82, 545),
		Vector2(268, 255),
		Vector2(248, 685),
		# Outer North Coral Islet
		Vector2(385, 74),
		Vector2(565, 74),
		Vector2(725, 74),
		Vector2(455, 245),
		Vector2(965, 155),
		Vector2(1155, 165),
		Vector2(1315, 225),
		# Outer East Coral Sandbar
		Vector2(1518, 415),
		Vector2(1518, 615),
		Vector2(1352, 295),
		Vector2(1332, 705),
		# Outer South Coral Islet
		Vector2(1215, 886),
		Vector2(1035, 886),
		Vector2(875, 886),
		Vector2(1145, 715),
		Vector2(635, 805),
		Vector2(445, 795),
		Vector2(285, 745),
		# Central Palm Island Fortress (inside the turquoise lagoon!)
		Vector2(435, 480),
		Vector2(495, 572),
		Vector2(675, 578),
		Vector2(925, 382),
		Vector2(1105, 388),
		Vector2(1165, 480),
	]

	var coarse_wn := _smooth_chaikin(lane_west_north_raw, 2)
	var coarse_es := _smooth_chaikin(lane_east_south_raw, 2)
	var smooth_wn := _subdivide_polyline(coarse_wn, 18.0)
	var smooth_es := _subdivide_polyline(coarse_es, 18.0)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "coral_atoll",
		"index": 9,
		"short_name": "CORAL ATOLL",
		"name": "SECTOR 09 — PACIFIC CORAL ATOLL",
		"tag": "TROPICAL • ATOLL RING • 23 WAVES",
		"biome": "tropical",
		"biome_id": 9,
		"seed": 9012471,
		"hp_scale": 1.12,
		"cash_bonus": 95,
		"briefing": "Amphibious divisions have landed on the outer sandy ring of our Pacific Coral Atoll! Convoys sweep all the way around the palm-fringed atoll islets before crossing the North and South lagoon bridges onto Central Island HQ.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_wn, smooth_es],
		"ground_coarses": [coarse_wn, coarse_es],
		"air_path": smooth_air,
		"river_points": river_raw,
		"bridge_pos": Vector2(800, 270),
		"bridges": [bridge_north, bridge_south],
		"base_pos": Vector2(800, 480),
		"spawn_positions": [Vector2(18, 775), Vector2(1582, 185)],
		"air_spawn_pos": Vector2(18, 175),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(738, 336), "angle": 0.25},
			{"pos": Vector2(862, 336), "angle": -0.25},
			{"pos": Vector2(738, 624), "angle": -0.25},
			{"pos": Vector2(862, 624), "angle": 0.25},
		],
		"bunkers": [],
	}

static func get_obsidian_caldera() -> Dictionary:
	# SECTOR 10 — OBSIDIAN CALDERA: REVERSE EAST→WEST ASSAULT ACROSS DIAGONAL LAVA RIFT!
	# Molten magma river slices NW→SE while enemies storm from the EAST toward South-West Forge HQ!
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1660, 180),
		Vector2(290, 180),
		Vector2(220, 210),
		Vector2(195, 285),
		Vector2(195, 435),
		Vector2(235, 485),
		Vector2(490, 485),
		Vector2(540, 530),
		Vector2(540, 745),
		Vector2(495, 800),
		Vector2(150, 800),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1660, 680),
		Vector2(1245, 680),
		Vector2(1185, 725),
		Vector2(1145, 785),
		Vector2(1080, 800),
		Vector2(150, 800),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(1660, 125),
		Vector2(1120, 360),
		Vector2(620, 590),
		Vector2(150, 800),
	])

	# Diagonal molten lava river slicing Top-Left -> Bottom-Right!
	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(480, -60),
		Vector2(620, 180),
		Vector2(765, 445),
		Vector2(905, 680),
		Vector2(970, 800),
		Vector2(1100, 1020),
	])

	var bridge_north := {"pos": Vector2(620, 180), "angle": 0.0}
	var bridge_south := {"pos": Vector2(970, 800), "angle": 0.0}

	var pads: Array[Vector2] = [
		# Northern Volcanic Rim (West & East of Lava Rift)
		Vector2(165, 86),
		Vector2(365, 86),
		Vector2(775, 86),
		Vector2(995, 86),
		Vector2(1215, 86),
		Vector2(1435, 86),
		# West Caldera Shelf (Switchback killzone!)
		Vector2(95, 345),
		Vector2(345, 340),
		Vector2(515, 340),
		Vector2(355, 635),
		Vector2(135, 635),
		# Central Magma Ridge
		Vector2(685, 625),
		Vector2(800, 900),
		Vector2(655, 900),
		Vector2(385, 900),
		# Eastern Obsidian Plateau (East of Lava Rift)
		Vector2(855, 315),
		Vector2(1045, 315),
		Vector2(1245, 315),
		Vector2(1445, 315),
		Vector2(995, 485),
		Vector2(1185, 485),
		Vector2(1385, 485),
		Vector2(1505, 485),
		Vector2(1145, 600),
		Vector2(1345, 825),
		Vector2(1495, 825),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "obsidian_caldera",
		"index": 10,
		"short_name": "OBSIDIAN CALDERA",
		"name": "SECTOR 10 — OBSIDIAN CALDERA",
		"tag": "VOLCANIC • EAST→WEST • 24 WAVES",
		"biome": "volcanic",
		"biome_id": 10,
		"seed": 1066642,
		"hp_scale": 1.28,
		"cash_bonus": 100,
		"briefing": "Hostile columns are charging WESTWARD across the diagonal molten lava rift toward our South-West Forge! Hold the twin magma bridges and trap the northern column in the caldera hairpin.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_s],
		"ground_coarses": [coarse_n, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(620, 180),
		"bridges": [bridge_north, bridge_south],
		"base_pos": Vector2(150, 800),
		"spawn_positions": [Vector2(1582, 180), Vector2(1582, 680)],
		"air_spawn_pos": Vector2(1582, 155),
		"pads": pads,
		"sandbags": [],
		"bunkers": [
			{"pos": Vector2(360, 725), "angle": 0.0},
		],
	}

static func get_bayou_delta() -> Dictionary:
	# SECTOR 11 — CYPRESS BAYOU: WINDING HORIZONTAL BAYOU WITH 3 VERTICAL TIMBER BRIDGES!
	# Convoys weave South -> North -> South back and forth across the foggy marsh river!
	var lane_main_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 185),
		Vector2(300, 185),
		Vector2(355, 220),
		Vector2(365, 290),
		Vector2(365, 725),
		Vector2(405, 775),
		Vector2(475, 785),
		Vector2(735, 785),
		Vector2(785, 745),
		Vector2(800, 680),
		Vector2(800, 265),
		Vector2(835, 200),
		Vector2(905, 185),
		Vector2(1175, 185),
		Vector2(1225, 220),
		Vector2(1240, 290),
		Vector2(1240, 755),
		Vector2(1285, 805),
		Vector2(1355, 815),
		Vector2(1495, 815),
	])

	var lane_flank_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 785),
		Vector2(735, 785),
		Vector2(785, 745),
		Vector2(800, 680),
		Vector2(800, 265),
		Vector2(835, 200),
		Vector2(905, 185),
		Vector2(1175, 185),
		Vector2(1225, 220),
		Vector2(1240, 290),
		Vector2(1240, 755),
		Vector2(1285, 805),
		Vector2(1355, 815),
		Vector2(1495, 815),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 480),
		Vector2(560, 560),
		Vector2(1080, 685),
		Vector2(1495, 815),
	])

	# Winding horizontal bayou river West -> East across the map!
	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 465),
		Vector2(180, 445),
		Vector2(365, 450),
		Vector2(580, 495),
		Vector2(800, 515),
		Vector2(1020, 475),
		Vector2(1240, 450),
		Vector2(1440, 470),
		Vector2(1660, 465),
	])

	var bridge_w := {"pos": Vector2(365, 450), "angle": PI * 0.5}
	var bridge_c := {"pos": Vector2(800, 515), "angle": PI * 0.5}
	var bridge_e := {"pos": Vector2(1240, 450), "angle": PI * 0.5}

	var pads: Array[Vector2] = [
		# Northern Marsh Islands
		Vector2(145, 84),
		Vector2(315, 84),
		Vector2(145, 310),
		Vector2(245, 310),
		Vector2(515, 145),
		Vector2(665, 145),
		Vector2(515, 315),
		Vector2(665, 315),
		Vector2(945, 84),
		Vector2(1135, 84),
		Vector2(945, 325),
		Vector2(1105, 325),
		Vector2(1385, 145),
		Vector2(1385, 315),
		Vector2(1505, 235),
		# Southern Marsh Islands
		Vector2(145, 625),
		Vector2(245, 650),
		Vector2(165, 892),
		Vector2(365, 892),
		Vector2(515, 645),
		Vector2(665, 645),
		Vector2(585, 892),
		Vector2(800, 892),
		Vector2(955, 645),
		Vector2(1105, 645),
		Vector2(1025, 845),
		Vector2(1385, 645),
		Vector2(1495, 645),
	]

	var coarse_m := _smooth_chaikin(lane_main_raw, 2)
	var coarse_f := _smooth_chaikin(lane_flank_raw, 2)
	var smooth_m := _subdivide_polyline(coarse_m, 18.0)
	var smooth_f := _subdivide_polyline(coarse_f, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "bayou_delta",
		"index": 11,
		"short_name": "CYPRESS BAYOU",
		"name": "SECTOR 11 — CYPRESS BAYOU DELTA",
		"tag": "SWAMP • 3 CROSSINGS • 25 WAVES",
		"biome": "swamp",
		"biome_id": 11,
		"seed": 1184209,
		"hp_scale": 1.36,
		"cash_bonus": 105,
		"briefing": "Convoys are weaving back and forth across three vertical timber bridges over the foggy Cypress Bayou! Turn the central marsh islands into crossfire killzones.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_m, smooth_f],
		"ground_coarses": [coarse_m, coarse_f],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(800, 515),
		"bridges": [bridge_w, bridge_c, bridge_e],
		"base_pos": Vector2(1495, 815),
		"spawn_positions": [Vector2(18, 185), Vector2(18, 785)],
		"air_spawn_pos": Vector2(18, 480),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(305, 365), "angle": 0.25},
			{"pos": Vector2(860, 602), "angle": -0.25},
		],
		"bunkers": [],
	}

static func get_neon_tokyo() -> Dictionary:
	# SECTOR 12 — NEO-TOKYO 2099: RIVERLESS MEGACITY GRID — 3-CORNER SIEGE ON CENTRAL NEO-TOWER!
	# Pure rain-slicked neon skyscraper blocks with crisp 90-degree expressways spiraling into HQ!
	var lane_nw_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 145),
		Vector2(560, 145),
		Vector2(588, 175),
		Vector2(588, 320),
		Vector2(560, 345),
		Vector2(280, 345),
		Vector2(252, 375),
		Vector2(252, 455),
		Vector2(282, 480),
		Vector2(800, 480),
	])

	var lane_ne_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1660, 145),
		Vector2(1040, 145),
		Vector2(1012, 175),
		Vector2(1012, 320),
		Vector2(1040, 345),
		Vector2(1320, 345),
		Vector2(1348, 375),
		Vector2(1348, 455),
		Vector2(1318, 480),
		Vector2(800, 480),
	])

	var lane_s_raw: PackedVector2Array = PackedVector2Array([
		Vector2(800, 1020),
		Vector2(800, 860),
		Vector2(768, 835),
		Vector2(495, 835),
		Vector2(465, 805),
		Vector2(465, 695),
		Vector2(495, 665),
		Vector2(770, 665),
		Vector2(800, 635),
		Vector2(800, 480),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(800, -60),
		Vector2(800, 220),
		Vector2(800, 480),
	])

	# Riverless cyberpunk downtown grid!
	var river_raw := PackedVector2Array()

	var pads: Array[Vector2] = [
		# North-West Downtown Blocks
		Vector2(145, 245),
		Vector2(340, 245),
		Vector2(475, 245),
		Vector2(710, 145),
		Vector2(710, 295),
		Vector2(140, 455),
		Vector2(385, 585),
		Vector2(575, 575),
		# North-East Downtown Blocks
		Vector2(890, 145),
		Vector2(890, 295),
		Vector2(1125, 245),
		Vector2(1260, 245),
		Vector2(1455, 245),
		Vector2(1460, 455),
		Vector2(1215, 585),
		Vector2(1025, 575),
		# Central Neo-Tower Plaza Ring
		Vector2(445, 412),
		Vector2(665, 395),
		Vector2(935, 395),
		Vector2(1155, 412),
		# South Expressway Blocks
		Vector2(215, 675),
		Vector2(355, 765),
		Vector2(635, 750),
		Vector2(935, 725),
		Vector2(1115, 725),
		Vector2(1345, 725),
		Vector2(955, 875),
		Vector2(635, 910),
	]

	var coarse_nw := _smooth_chaikin(lane_nw_raw, 1)
	var coarse_ne := _smooth_chaikin(lane_ne_raw, 1)
	var coarse_s := _smooth_chaikin(lane_s_raw, 1)
	var smooth_nw := _subdivide_polyline(coarse_nw, 18.0)
	var smooth_ne := _subdivide_polyline(coarse_ne, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "neon_tokyo",
		"index": 12,
		"short_name": "NEO-TOKYO 2099",
		"name": "SECTOR 12 — NEO-TOKYO 2099",
		"tag": "CYBERPUNK • 3-CORNER • 26 WAVES",
		"biome": "cyberpunk",
		"biome_id": 12,
		"seed": 20991204,
		"hp_scale": 1.03,
		"cash_bonus": 120,
		"briefing": "Rogue corporate divisions are closing in on Central Neo-Tower from North-West, North-East, and South through Neo-Tokyo's rain-slicked neon street grid! Defend the central core.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_nw, smooth_ne, smooth_s],
		"ground_coarses": [coarse_nw, coarse_ne, coarse_s],
		"air_path": smooth_air,
		"river_points": river_raw,
		"bridge_pos": Vector2(-9999, -9999),
		"bridges": [],
		"base_pos": Vector2(800, 480),
		"spawn_positions": [Vector2(18, 145), Vector2(1582, 145), Vector2(800, 942)],
		"air_spawn_pos": Vector2(800, 18),
		"pads": pads,
		"sandbags": [],
		"bunkers": [],
	}

static func get_tranquility_crater() -> Dictionary:
	# SECTOR 13 — THE MOON: RIVERLESS GIANT CRATER SPIRAL!
	# Dual lunar drop corridors spiral inward around concentric impact terraces to Central Moonbase Alpha!
	var lane_outer_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 140),
		Vector2(1345, 140),
		Vector2(1415, 175),
		Vector2(1435, 245),
		Vector2(1435, 745),
		Vector2(1405, 815),
		Vector2(1335, 835),
		Vector2(275, 835),
		Vector2(205, 805),
		Vector2(185, 735),
		Vector2(185, 415),
		Vector2(215, 345),
		Vector2(285, 325),
		Vector2(1115, 325),
		Vector2(1185, 355),
		Vector2(1205, 425),
		Vector2(1205, 575),
		Vector2(1175, 640),
		Vector2(1105, 658),
		Vector2(860, 658),
		Vector2(815, 620),
		Vector2(800, 480),
	])

	var lane_inner_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1660, 835),
		Vector2(275, 835),
		Vector2(205, 805),
		Vector2(185, 735),
		Vector2(185, 415),
		Vector2(215, 345),
		Vector2(285, 325),
		Vector2(1115, 325),
		Vector2(1185, 355),
		Vector2(1205, 425),
		Vector2(1205, 575),
		Vector2(1175, 640),
		Vector2(1105, 658),
		Vector2(860, 658),
		Vector2(815, 620),
		Vector2(800, 480),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 880),
		Vector2(420, 680),
		Vector2(800, 480),
	])

	# Pure airless cratered regolith — no river!
	var river_raw := PackedVector2Array()

	var pads: Array[Vector2] = [
		# Outer Crater Rim Terrace (Between Outer & Middle rings!)
		Vector2(160, 232),
		Vector2(345, 232),
		Vector2(545, 232),
		Vector2(745, 232),
		Vector2(945, 232),
		Vector2(1145, 232),
		Vector2(1320, 238),
		Vector2(1320, 415),
		Vector2(1320, 585),
		Vector2(1315, 742),
		Vector2(1145, 748),
		Vector2(955, 748),
		Vector2(755, 748),
		Vector2(555, 748),
		Vector2(355, 748),
		Vector2(92, 465),
		Vector2(92, 665),
		# Inner Crater Core Ring (High-value dual-coverage pads around Moonbase Alpha!)
		Vector2(325, 445),
		Vector2(485, 445),
		Vector2(635, 445),
		Vector2(965, 445),
		Vector2(1095, 485),
		Vector2(325, 625),
		Vector2(485, 625),
		Vector2(645, 625),
		Vector2(975, 565),
		Vector2(1520, 465),
	]

	var coarse_o := _smooth_chaikin(lane_outer_raw, 2)
	var coarse_i := _smooth_chaikin(lane_inner_raw, 2)
	var smooth_o := _subdivide_polyline(coarse_o, 18.0)
	var smooth_i := _subdivide_polyline(coarse_i, 18.0)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "tranquility_crater",
		"index": 13,
		"short_name": "LUNAR CRATER",
		"name": "SECTOR 13 — SEA OF TRANQUILITY (MOON)",
		"tag": "THE MOON • SPIRAL • 27 WAVES",
		"biome": "moon",
		"biome_id": 13,
		"seed": 19690720,
		"hp_scale": 1.19,
		"cash_bonus": 120,
		"briefing": "Orbital drop-pods have deployed hostile rover columns onto the outer rim of Tranquility Crater! They are spiraling inward around the concentric lunar terraces toward Central Moonbase Alpha.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_o, smooth_i],
		"ground_coarses": [coarse_o, coarse_i],
		"air_path": smooth_air,
		"river_points": river_raw,
		"bridge_pos": Vector2(-9999, -9999),
		"bridges": [],
		"base_pos": Vector2(800, 480),
		"spawn_positions": [Vector2(18, 140), Vector2(1582, 835)],
		"air_spawn_pos": Vector2(18, 860),
		"pads": pads,
		"sandbags": [],
		"bunkers": [],
	}

static func get_olympus_rift() -> Dictionary:
	# SECTOR 14 — MARS: OLYMPUS RIFT: REVERSE-SPLIT CANYON FORK!
	# Columns enter a single western canyon mouth and SPLIT into High Rim vs Deep Chasm routes
	# crossing a horizontal Martian dry-ice rift via twin VERTICAL viaducts toward SE Ares HQ!
	var lane_high_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 265),
		Vector2(315, 265),
		Vector2(365, 232),
		Vector2(395, 175),
		Vector2(455, 155),
		Vector2(1195, 155),
		Vector2(1250, 185),
		Vector2(1270, 250),
		Vector2(1270, 745),
		Vector2(1308, 795),
		Vector2(1375, 810),
		Vector2(1495, 810),
	])

	var lane_low_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 265),
		Vector2(315, 265),
		Vector2(368, 298),
		Vector2(385, 365),
		Vector2(385, 745),
		Vector2(422, 798),
		Vector2(490, 810),
		Vector2(735, 810),
		Vector2(785, 775),
		Vector2(805, 705),
		Vector2(845, 675),
		Vector2(1015, 675),
		Vector2(1062, 712),
		Vector2(1082, 780),
		Vector2(1145, 810),
		Vector2(1495, 810),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 120),
		Vector2(560, 355),
		Vector2(1080, 585),
		Vector2(1495, 810),
	])

	# Horizontal Martian dry-ice canyon chasm West -> East!
	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 495),
		Vector2(180, 512),
		Vector2(385, 505),
		Vector2(660, 480),
		Vector2(960, 520),
		Vector2(1270, 508),
		Vector2(1480, 490),
		Vector2(1660, 500),
	])

	var bridge_west := {"pos": Vector2(385, 505), "angle": PI * 0.5}
	var bridge_east := {"pos": Vector2(1270, 508), "angle": PI * 0.5}

	var pads: Array[Vector2] = [
		# Western Canyon Mouth (Single-Choke Power Zone!)
		Vector2(135, 155),
		Vector2(265, 155),
		Vector2(145, 368),
		Vector2(265, 368),
		# Northern Martian Rim
		Vector2(565, 74),
		Vector2(805, 74),
		Vector2(1045, 74),
		Vector2(545, 285),
		Vector2(735, 285),
		Vector2(925, 285),
		Vector2(1115, 285),
		Vector2(1405, 165),
		Vector2(1425, 325),
		# Southern Martian Basin
		Vector2(145, 665),
		Vector2(265, 665),
		Vector2(245, 845),
		Vector2(525, 675),
		Vector2(665, 675),
		Vector2(565, 900),
		Vector2(805, 895),
		Vector2(930, 815),
		Vector2(1145, 665),
		Vector2(1185, 900),
		Vector2(1405, 665),
		Vector2(1505, 665),
		Vector2(1375, 900),
	]

	var coarse_h := _smooth_chaikin(lane_high_raw, 2)
	var coarse_l := _smooth_chaikin(lane_low_raw, 2)
	var smooth_h := _subdivide_polyline(coarse_h, 18.0)
	var smooth_l := _subdivide_polyline(coarse_l, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "olympus_rift",
		"index": 14,
		"short_name": "OLYMPUS RIFT",
		"name": "SECTOR 14 — MARS: OLYMPUS RIFT",
		"tag": "MARS • CANYON FORK • 28 WAVES",
		"biome": "mars",
		"biome_id": 14,
		"seed": 20420314,
		"hp_scale": 1.48,
		"cash_bonus": 130,
		"briefing": "Martian siege divisions are pouring through the West Canyon Mouth before splitting along the High Rim and Southern Basin across two vertical dry-ice viaducts toward South-East Ares Command.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_h, smooth_l],
		"ground_coarses": [coarse_h, coarse_l],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(385, 505),
		"bridges": [bridge_west, bridge_east],
		"base_pos": Vector2(1495, 810),
		"spawn_positions": [Vector2(18, 265)],
		"air_spawn_pos": Vector2(18, 150),
		"pads": pads,
		"sandbags": [],
		"bunkers": [],
	}

static func get_europa_abyss() -> Dictionary:
	# SECTOR 15 — EUROPA ICE SHELL: BOTTOM-TO-TOP ASSAULT!
	# Invaders advance UPWARD from South-West & South-East across a horizontal glowing cyan
	# abyssal ocean fissure toward our Northern Ice Outpost HQ at top-center!
	var lane_west_raw: PackedVector2Array = PackedVector2Array([
		Vector2(215, 1020),
		Vector2(215, 795),
		Vector2(252, 745),
		Vector2(320, 730),
		Vector2(415, 730),
		Vector2(455, 695),
		Vector2(465, 630),
		Vector2(465, 355),
		Vector2(428, 305),
		Vector2(355, 290),
		Vector2(285, 290),
		Vector2(248, 245),
		Vector2(248, 175),
		Vector2(292, 128),
		Vector2(375, 115),
		Vector2(800, 115),
	])

	var lane_east_raw: PackedVector2Array = PackedVector2Array([
		Vector2(1385, 1020),
		Vector2(1385, 795),
		Vector2(1348, 745),
		Vector2(1280, 730),
		Vector2(1185, 730),
		Vector2(1145, 695),
		Vector2(1135, 630),
		Vector2(1135, 355),
		Vector2(1172, 305),
		Vector2(1245, 290),
		Vector2(1315, 290),
		Vector2(1352, 245),
		Vector2(1352, 175),
		Vector2(1308, 128),
		Vector2(1225, 115),
		Vector2(800, 115),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(800, 1020),
		Vector2(800, 620),
		Vector2(800, 340),
		Vector2(800, 115),
	])

	# Horizontal glowing bioluminescent Europan abyssal ocean fissure!
	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 492),
		Vector2(220, 472),
		Vector2(465, 480),
		Vector2(800, 505),
		Vector2(1135, 480),
		Vector2(1380, 472),
		Vector2(1660, 492),
	])

	var bridge_w := {"pos": Vector2(465, 480), "angle": PI * 0.5}
	var bridge_e := {"pos": Vector2(1135, 480), "angle": PI * 0.5}

	var pads: Array[Vector2] = [
		# Southern Cryo Approaches
		Vector2(105, 835),
		Vector2(105, 655),
		Vector2(345, 855),
		Vector2(585, 795),
		Vector2(585, 645),
		Vector2(800, 825),
		Vector2(800, 665),
		Vector2(1015, 795),
		Vector2(1015, 645),
		Vector2(1255, 855),
		Vector2(1495, 835),
		Vector2(1495, 655),
		# Northern Tectonic Shelf & Outpost HQ Perimeter
		Vector2(132, 345),
		Vector2(132, 175),
		Vector2(335, 385),
		Vector2(455, 205),
		Vector2(585, 345),
		Vector2(585, 215),
		Vector2(695, 285),
		Vector2(800, 355),
		Vector2(800, 245),
		Vector2(905, 285),
		Vector2(1015, 345),
		Vector2(1015, 215),
		Vector2(1145, 205),
		Vector2(1265, 385),
		Vector2(1468, 345),
		Vector2(1468, 175),
	]

	var coarse_w := _smooth_chaikin(lane_west_raw, 2)
	var coarse_e := _smooth_chaikin(lane_east_raw, 2)
	var smooth_w := _subdivide_polyline(coarse_w, 18.0)
	var smooth_e := _subdivide_polyline(coarse_e, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "europa_abyss",
		"index": 15,
		"short_name": "EUROPA ICE SHELL",
		"name": "SECTOR 15 — EUROPA ICE SHELL (JUPITER)",
		"tag": "EUROPA • SOUTH→NORTH • 29 WAVES",
		"biome": "europa",
		"biome_id": 15,
		"seed": 15799012,
		"hp_scale": 1.22,
		"cash_bonus": 135,
		"briefing": "Deep-space raiders are advancing NORTHWARD from the southern ice plains across twin vertical cryo-bridges spanning the glowing Europan ocean fissure! Hold the Northern Research Outpost.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_w, smooth_e],
		"ground_coarses": [coarse_w, coarse_e],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(465, 480),
		"bridges": [bridge_w, bridge_e],
		"base_pos": Vector2(800, 115),
		"spawn_positions": [Vector2(215, 942), Vector2(1385, 942)],
		"air_spawn_pos": Vector2(800, 942),
		"pads": pads,
		"sandbags": [],
		"bunkers": [],
	}

static func get_xenon_prime() -> Dictionary:
	# SECTOR 16 — XENON PRIME (GRAND FINALE): 3-FRONT ALIEN PLASMA GAUNTLET!
	# Simultaneous invasions from NORTH, WEST, and SOUTH surge across a crescent plasma river
	# spanned by THREE glowing plasma bridges converging on the Starport Citadel!
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(345, -60),
		Vector2(345, 145),
		Vector2(395, 190),
		Vector2(1145, 190),
		Vector2(1215, 222),
		Vector2(1242, 290),
		Vector2(1242, 415),
		Vector2(1285, 468),
		Vector2(1355, 480),
		Vector2(1505, 480),
	])

	var lane_mid_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 480),
		Vector2(280, 480),
		Vector2(345, 445),
		Vector2(395, 385),
		Vector2(545, 385),
		Vector2(600, 435),
		Vector2(655, 480),
		Vector2(1505, 480),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(345, 1020),
		Vector2(345, 815),
		Vector2(395, 770),
		Vector2(1145, 770),
		Vector2(1215, 738),
		Vector2(1242, 670),
		Vector2(1242, 545),
		Vector2(1285, 492),
		Vector2(1355, 480),
		Vector2(1505, 480),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 125),
		Vector2(560, 315),
		Vector2(1060, 465),
		Vector2(1505, 480),
	])

	# Dramatic curving crescent alien plasma river!
	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(955, -50),
		Vector2(885, 190),
		Vector2(815, 335),
		Vector2(785, 480),
		Vector2(815, 625),
		Vector2(885, 770),
		Vector2(955, 1020),
	])

	var bridge_n := {"pos": Vector2(885, 190), "angle": 0.0}
	var bridge_m := {"pos": Vector2(785, 480), "angle": 0.0}
	var bridge_s := {"pos": Vector2(885, 770), "angle": 0.0}

	var pads: Array[Vector2] = [
		# West Crystal Approaches
		Vector2(145, 145),
		Vector2(145, 335),
		Vector2(145, 625),
		Vector2(145, 815),
		Vector2(255, 295),
		Vector2(255, 665),
		# Northern & Southern Ridge Overlooks
		Vector2(525, 86),
		Vector2(735, 86),
		Vector2(1035, 86),
		Vector2(525, 874),
		Vector2(735, 874),
		Vector2(1035, 874),
		# Central Crystal Valley (West of Plasma River)
		Vector2(485, 288),
		Vector2(665, 315),
		Vector2(485, 535),
		Vector2(485, 665),
		Vector2(665, 645),
		# East Plasma Basin (Between Plasma River & Starport Convergence!)
		Vector2(995, 335),
		Vector2(1125, 335),
		Vector2(995, 625),
		Vector2(1125, 625),
		# Starport Citadel Final Perimeter
		Vector2(1355, 225),
		Vector2(1375, 368),
		Vector2(1375, 592),
		Vector2(1355, 735),
		Vector2(1475, 315),
		Vector2(1475, 645),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_m := _smooth_chaikin(lane_mid_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_m := _subdivide_polyline(coarse_m, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "xenon_prime",
		"index": 16,
		"short_name": "XENON PRIME",
		"name": "SECTOR 16 — XENON PRIME (EXOPLANET)",
		"tag": "ALIEN • 3-FRONT FINAL • 30 WAVES",
		"biome": "alien",
		"biome_id": 16,
		"seed": 16999001,
		"hp_scale": 1.44,
		"cash_bonus": 150,
		"briefing": "Three full invasion fronts—North, West, and South—are surging across the crescent plasma river toward Starport Citadel! Defend all three plasma bridges and survive the 30-wave finale.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_m, smooth_s],
		"ground_coarses": [coarse_n, coarse_m, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": Vector2(785, 480),
		"bridges": [bridge_n, bridge_m, bridge_s],
		"base_pos": Vector2(1505, 480),
		"spawn_positions": [Vector2(345, 18), Vector2(18, 480), Vector2(345, 942)],
		"air_spawn_pos": Vector2(18, 155),
		"pads": pads,
		"sandbags": [],
		"bunkers": [],
	}

static func _smooth_chaikin(pts: PackedVector2Array, iterations: int) -> PackedVector2Array:
	var cur := pts
	for _it in range(iterations):
		if cur.size() < 3:
			return cur
		var next := PackedVector2Array()
		next.append(cur[0])
		for i in range(cur.size() - 1):
			var a: Vector2 = cur[i]
			var b: Vector2 = cur[i + 1]
			if i > 0:
				next.append(a.lerp(b, 0.25))
			if i < cur.size() - 2:
				next.append(a.lerp(b, 0.75))
		next.append(cur[cur.size() - 1])
		cur = next
	return cur

static func _subdivide_polyline(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.size() < 2:
		return points
	result.append(points[0])
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var dist: float = a.distance_to(b)
		var segs: int = maxi(1, int(ceil(dist / step)))
		for s in range(1, segs + 1):
			result.append(a.lerp(b, float(s) / float(segs)))
	return result

static func distance_to_polyline(p: Vector2, poly: PackedVector2Array) -> float:
	var best: float = INF
	for i in range(poly.size() - 1):
		var d: float = _dist_to_segment(p, poly[i], poly[i + 1])
		if d < best:
			best = d
	return best

static func distance_to_polylines(p: Vector2, polys: Array) -> float:
	var best: float = INF
	for poly in polys:
		var d: float = distance_to_polyline(p, poly)
		if d < best:
			best = d
	return best

static func signed_sun_to_river(p: Vector2, river: PackedVector2Array) -> float:
	if river.size() < 2:
		return 0.0
	var best_d: float = INF
	var best_proj: float = 0.0
	var sun_2d := Vector2(0.76, 0.65)
	for i in range(river.size() - 1):
		var a: Vector2 = river[i]
		var b: Vector2 = river[i + 1]
		var ab: Vector2 = b - a
		var len_sq: float = ab.length_squared()
		var t: float = clampf((p - a).dot(ab) / maxf(0.0001, len_sq), 0.0, 1.0)
		var closest: Vector2 = a + ab * t
		var d: float = p.distance_to(closest)
		if d < best_d:
			best_d = d
			best_proj = (p - closest).dot(sun_2d)
	return best_proj

static func signed_x_to_river(p: Vector2, river: PackedVector2Array) -> float:
	var best_d: float = INF
	var best_dx: float = 0.0
	for i in range(river.size() - 1):
		var a: Vector2 = river[i]
		var b: Vector2 = river[i + 1]
		var ab: Vector2 = b - a
		var len_sq: float = ab.length_squared()
		var t: float = clampf((p - a).dot(ab) / maxf(0.0001, len_sq), 0.0, 1.0)
		var closest: Vector2 = a + ab * t
		var d: float = p.distance_to(closest)
		if d < best_d:
			best_d = d
			best_dx = p.x - closest.x
	return best_dx

static func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)
