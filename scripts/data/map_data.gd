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
		"hp_scale": 1.15,
		"cash_bonus": 20,
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
	# Twin-Bridge Glacial Pass: Dual independent arctic highways crossing North & South bridges,
	# squeezing near a high-value central ridge before converging at East HQ.
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 220),
		Vector2(335, 220),
		Vector2(382, 240),
		Vector2(398, 285),
		Vector2(398, 340),
		Vector2(418, 378),
		Vector2(462, 390),
		Vector2(620, 390),
		Vector2(666, 374),
		Vector2(685, 330),
		Vector2(685, 275),
		Vector2(704, 232),
		Vector2(748, 220),
		Vector2(1115, 220),
		Vector2(1160, 240),
		Vector2(1176, 288),
		Vector2(1176, 425),
		Vector2(1196, 466),
		Vector2(1245, 480),
		Vector2(1515, 480),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 735),
		Vector2(335, 735),
		Vector2(382, 715),
		Vector2(398, 670),
		Vector2(398, 625),
		Vector2(418, 588),
		Vector2(462, 575),
		Vector2(620, 575),
		Vector2(666, 592),
		Vector2(685, 635),
		Vector2(685, 682),
		Vector2(704, 722),
		Vector2(748, 735),
		Vector2(1115, 735),
		Vector2(1160, 715),
		Vector2(1176, 668),
		Vector2(1176, 535),
		Vector2(1196, 494),
		Vector2(1245, 480),
		Vector2(1515, 480),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 480),
		Vector2(540, 480),
		Vector2(1015, 480),
		Vector2(1515, 480),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(812, -50),
		Vector2(822, 110),
		Vector2(825, 220),
		Vector2(840, 395),
		Vector2(816, 570),
		Vector2(825, 735),
		Vector2(836, 885),
		Vector2(846, 1020),
	])

	var bridge_north := Vector2(825, 220)
	var bridge_south := Vector2(825, 735)

	var pads: Array[Vector2] = [
		# West entry flanks
		Vector2(155, 118),
		Vector2(290, 118),
		Vector2(165, 325),
		Vector2(285, 325),
		Vector2(225, 482),
		Vector2(165, 630),
		Vector2(285, 630),
		Vector2(155, 842),
		Vector2(290, 842),
		# Central pockets & high-value dual-lane spine
		Vector2(540, 275),
		Vector2(490, 482),
		Vector2(615, 482),
		Vector2(540, 682),
		# North & South bridge overlooks
		Vector2(705, 112),
		Vector2(955, 112),
		Vector2(705, 848),
		Vector2(955, 848),
		# East Glacial Plateau (between river & HQ convergence)
		Vector2(958, 335),
		Vector2(1076, 335),
		Vector2(958, 482),
		Vector2(1076, 482),
		Vector2(958, 625),
		Vector2(1076, 625),
		# East HQ perimeter
		Vector2(1292, 260),
		Vector2(1355, 378),
		Vector2(1355, 582),
		Vector2(1292, 700),
		Vector2(1455, 295),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "frostline_pass",
		"index": 3,
		"short_name": "FROSTLINE PASS",
		"name": "SECTOR 03 — FROSTLINE PASS",
		"tag": "TUNDRA • 2 BRIDGES • 17 WAVES",
		"biome": "tundra",
		"biome_id": 2,
		"seed": 6129443,
		"hp_scale": 1.28,
		"cash_bonus": 40,
		"briefing": "Heavy winter convoys are breaching both the North and South glacial bridges simultaneously while strike wings dive straight down the central blizzard corridor. Hold the central spine and lock down both crossings.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_s],
		"ground_coarses": [coarse_n, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": bridge_north,
		"bridges": [bridge_north, bridge_south],
		"base_pos": Vector2(1515, 480),
		"spawn_positions": [Vector2(18, 220), Vector2(18, 735)],
		"air_spawn_pos": Vector2(18, 480),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(742, 162), "angle": 0.32},
			{"pos": Vector2(910, 162), "angle": -0.32},
			{"pos": Vector2(742, 795), "angle": -0.32},
			{"pos": Vector2(910, 795), "angle": 0.32},
			{"pos": Vector2(1425, 415), "angle": 0.0},
			{"pos": Vector2(1425, 545), "angle": 0.0},
		],
		"bunkers": [
			{"pos": Vector2(540, 145), "angle": PI * 0.5},
			{"pos": Vector2(540, 815), "angle": -PI * 0.5},
			{"pos": Vector2(1445, 680), "angle": -PI * 0.75},
		],
	}

static func get_granite_gorge() -> Dictionary:
	# High-Altitude Mountain Valleys: Two deep winding canyon roads carving around towering
	# snow-capped granite massifs, crossing twin mountain gorge bridges to the East Citadel.
	var lane_north_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 175),
		Vector2(320, 175),
		Vector2(368, 198),
		Vector2(388, 250),
		Vector2(388, 415),
		Vector2(412, 462),
		Vector2(465, 480),
		Vector2(650, 480),
		Vector2(698, 458),
		Vector2(720, 405),
		Vector2(720, 245),
		Vector2(742, 198),
		Vector2(792, 185),
		Vector2(1128, 185),
		Vector2(1174, 208),
		Vector2(1194, 260),
		Vector2(1194, 438),
		Vector2(1218, 482),
		Vector2(1268, 500),
		Vector2(1515, 500),
	])

	var lane_south_raw: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 795),
		Vector2(465, 795),
		Vector2(515, 775),
		Vector2(540, 725),
		Vector2(540, 695),
		Vector2(564, 658),
		Vector2(615, 648),
		Vector2(755, 648),
		Vector2(802, 668),
		Vector2(826, 720),
		Vector2(842, 772),
		Vector2(890, 795),
		Vector2(1148, 795),
		Vector2(1192, 772),
		Vector2(1212, 720),
		Vector2(1212, 562),
		Vector2(1234, 518),
		Vector2(1280, 500),
		Vector2(1515, 500),
	])

	var air_waypoints: PackedVector2Array = PackedVector2Array([
		Vector2(-60, 115),
		Vector2(540, 320),
		Vector2(1040, 485),
		Vector2(1515, 500),
	])

	var river_raw: PackedVector2Array = PackedVector2Array([
		Vector2(930, -50),
		Vector2(945, 92),
		Vector2(956, 185),
		Vector2(972, 370),
		Vector2(986, 580),
		Vector2(996, 795),
		Vector2(1012, 912),
		Vector2(1025, 1020),
	])

	var bridge_north := Vector2(956, 185)
	var bridge_south := Vector2(996, 795)

	var pads: Array[Vector2] = [
		# Northwest pass ledges
		Vector2(155, 86),
		Vector2(295, 86),
		Vector2(282, 285),
		Vector2(282, 445),
		# Southwest ravine ledges
		Vector2(175, 690),
		Vector2(360, 690),
		Vector2(240, 886),
		Vector2(440, 886),
		# Central valley hairpin & ridge overlooks
		Vector2(555, 188),
		Vector2(555, 365),
		Vector2(455, 580),
		Vector2(665, 565),
		Vector2(688, 752),
		# North & South mountain gorge bridge overlooks
		Vector2(835, 92),
		Vector2(1082, 92),
		Vector2(865, 888),
		Vector2(1130, 888),
		# West gorge cliff ledges
		Vector2(842, 325),
		Vector2(855, 495),
		# East gorge ridge (between roaring river & east climb)
		Vector2(1088, 315),
		Vector2(1095, 470),
		Vector2(1102, 625),
		# East Mountain Citadel perimeter
		Vector2(1308, 245),
		Vector2(1355, 385),
		Vector2(1355, 615),
		Vector2(1308, 755),
		Vector2(1455, 315),
		Vector2(1455, 685),
	]

	var coarse_n := _smooth_chaikin(lane_north_raw, 2)
	var coarse_s := _smooth_chaikin(lane_south_raw, 2)
	var smooth_n := _subdivide_polyline(coarse_n, 18.0)
	var smooth_s := _subdivide_polyline(coarse_s, 18.0)
	var smooth_river := _smooth_chaikin(river_raw, 3)
	var smooth_air := _subdivide_polyline(air_waypoints, 24.0)

	return {
		"id": "granite_gorge",
		"index": 4,
		"short_name": "GRANITE GORGE",
		"name": "SECTOR 04 — GRANITE GORGE",
		"tag": "MOUNTAIN • 2 VALLEYS • 18 WAVES",
		"biome": "mountain",
		"biome_id": 3,
		"seed": 3187651,
		"hp_scale": 1.40,
		"cash_bonus": 60,
		"briefing": "Enemy armor divisions are snaking through deep granite mountain valleys and switchbacks beneath snow-capped peaks while bombers sweep over the high ridge. Fortify the cliffside overlooks and hold the gorge bridges.",
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
		"ground_paths": [smooth_n, smooth_s],
		"ground_coarses": [coarse_n, coarse_s],
		"air_path": smooth_air,
		"river_points": smooth_river,
		"bridge_pos": bridge_north,
		"bridges": [bridge_north, bridge_south],
		"base_pos": Vector2(1515, 500),
		"spawn_positions": [Vector2(18, 175), Vector2(18, 795)],
		"air_spawn_pos": Vector2(18, 145),
		"pads": pads,
		"sandbags": [
			{"pos": Vector2(872, 130), "angle": 0.30},
			{"pos": Vector2(1042, 130), "angle": -0.30},
			{"pos": Vector2(912, 852), "angle": -0.30},
			{"pos": Vector2(1082, 852), "angle": 0.30},
			{"pos": Vector2(1425, 435), "angle": 0.0},
			{"pos": Vector2(1425, 565), "angle": 0.0},
		],
		"bunkers": [
			{"pos": Vector2(160, 480), "angle": 0.12},
			{"pos": Vector2(555, 868), "angle": -PI * 0.5},
			{"pos": Vector2(1435, 165), "angle": PI * 0.78},
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
		"hp_scale": 1.18,
		"cash_bonus": 75,
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
