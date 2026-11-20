class_name WaveData
extends RefCounted

enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	HELL,
}

static func get_difficulty_config(diff: Difficulty) -> Dictionary:
	match diff:
		Difficulty.EASY:
			return {
				"name": "EASY",
				"hp_mult": 0.80,
				"speed_mult": 0.94,
				"reward_mult": 1.15,
				"start_cash": 340,
				"start_lives": 25,
				"accent": Color(0.38, 0.82, 0.48),
			}
		Difficulty.NORMAL:
			return {
				"name": "NORMAL",
				"hp_mult": 1.0,
				"speed_mult": 1.0,
				"reward_mult": 1.0,
				"start_cash": 280,
				"start_lives": 20,
				"accent": Color(0.92, 0.74, 0.28),
			}
		Difficulty.HARD:
			return {
				"name": "HARD",
				"hp_mult": 1.28,
				"speed_mult": 1.06,
				"reward_mult": 0.95,
				"start_cash": 250,
				"start_lives": 15,
				"accent": Color(0.94, 0.45, 0.24),
			}
		Difficulty.HELL:
			return {
				"name": "HELL",
				"hp_mult": 1.62,
				"speed_mult": 1.12,
				"reward_mult": 0.90,
				"start_cash": 230,
				"start_lives": 10,
				"accent": Color(0.92, 0.20, 0.20),
			}
	return {}

static func get_waves_for_map(map_id: String) -> Array[Dictionary]:
	if map_id == "scorched_wadi":
		return get_scorched_wadi_waves()
	if map_id == "frostline_pass":
		return get_frostline_pass_waves()
	if map_id == "granite_gorge":
		return get_granite_gorge_waves()
	if map_id == "north_pole":
		return get_north_pole_waves()
	return get_waves()

static func get_waves() -> Array[Dictionary]:
	var E := EnemyData.EnemyType
	return [
		{
			"title": "RECON PATROL",
			"bonus": 30,
			"groups": [
				{"type": E.JEEP, "count": 7, "interval": 1.05, "delay": 0.0, "lane": 0},
			],
		},
		{
			"title": "FORWARD COLUMN",
			"bonus": 35,
			"groups": [
				{"type": E.JEEP, "count": 6, "interval": 0.85, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 4, "interval": 1.4, "delay": 3.5, "lane": 0},
			],
		},
		{
			"title": "MECHANIZED PUSH",
			"bonus": 40,
			"groups": [
				{"type": E.APC, "count": 8, "interval": 1.15, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 6, "interval": 0.65, "delay": 5.0, "lane": 0},
			],
		},
		{
			"title": "ARMORED SPEARHEAD",
			"bonus": 45,
			"groups": [
				{"type": E.TANK, "count": 4, "interval": 1.9, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 5, "interval": 1.1, "delay": 2.4, "lane": 0},
			],
		},
		{
			"title": "GUNSHIP INCURSION",
			"bonus": 55,
			"groups": [
				{"type": E.CHOPPER, "count": 5, "interval": 1.5, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 8, "interval": 0.7, "delay": 1.5, "lane": 0},
			],
		},
		{
			"title": "CONVOY BLITZ",
			"bonus": 60,
			"groups": [
				{"type": E.JEEP, "count": 12, "interval": 0.48, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 5, "interval": 1.6, "delay": 3.0, "lane": 0},
			],
		},
		{
			"title": "COMBINED ARMS",
			"bonus": 65,
			"groups": [
				{"type": E.TANK, "count": 6, "interval": 1.5, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 8, "interval": 0.9, "delay": 1.0, "lane": 0},
				{"type": E.CHOPPER, "count": 5, "interval": 1.35, "delay": 3.8, "lane": 0},
			],
		},
		{
			"title": "HEAVY AIR WING",
			"bonus": 75,
			"groups": [
				{"type": E.CHOPPER, "count": 6, "interval": 1.1, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 3, "interval": 2.2, "delay": 2.5, "lane": 0},
			],
		},
		{
			"title": "IRON PHALANX",
			"bonus": 85,
			"groups": [
				{"type": E.TANK, "count": 9, "interval": 1.25, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 10, "interval": 0.75, "delay": 2.5, "lane": 0},
			],
		},
		{
			"title": "SIEGE BREAKER",
			"bonus": 110,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 6, "interval": 1.4, "delay": 1.8, "lane": 0},
				{"type": E.CHOPPER, "count": 6, "interval": 1.1, "delay": 4.2, "lane": 0},
			],
		},
		{
			"title": "LIGHTNING RAID",
			"bonus": 100,
			"groups": [
				{"type": E.JEEP, "count": 18, "interval": 0.34, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 5, "interval": 1.7, "delay": 1.5, "lane": 0},
				{"type": E.APC, "count": 10, "interval": 0.65, "delay": 3.5, "lane": 0},
			],
		},
		{
			"title": "ARMOR DIVISION",
			"bonus": 120,
			"groups": [
				{"type": E.TANK, "count": 12, "interval": 1.05, "delay": 0.0, "lane": 0},
				{"type": E.JUGGERNAUT, "count": 2, "interval": 5.0, "delay": 2.0, "lane": 0},
			],
		},
		{
			"title": "VALKYRIE SORTIE",
			"bonus": 130,
			"groups": [
				{"type": E.CHOPPER, "count": 10, "interval": 0.8, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 7, "interval": 1.45, "delay": 1.2, "lane": 0},
				{"type": E.TANK, "count": 8, "interval": 1.2, "delay": 2.5, "lane": 0},
			],
		},
		{
			"title": "SCORCHED EARTH",
			"bonus": 150,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.8, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 12, "interval": 0.95, "delay": 1.0, "lane": 0},
				{"type": E.BOMBER, "count": 6, "interval": 1.4, "delay": 3.5, "lane": 0},
			],
		},
		{
			"title": "OPERATION IRON STORM",
			"bonus": 250,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 4, "interval": 3.4, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 14, "interval": 0.85, "delay": 1.2, "lane": 0},
				{"type": E.BOMBER, "count": 8, "interval": 1.25, "delay": 2.5, "lane": 0},
				{"type": E.CHOPPER, "count": 10, "interval": 0.7, "delay": 4.0, "lane": 0},
				{"type": E.JEEP, "count": 16, "interval": 0.3, "delay": 5.5, "lane": 0},
			],
		},
	]

static func get_scorched_wadi_waves() -> Array[Dictionary]:
	# lane: 0 = North Desert Highway, 1 = South Dune Track, -1 = Alternate both lanes
	var E := EnemyData.EnemyType
	return [
		{
			"title": "DUNE SCOUTS",
			"bonus": 35,
			"groups": [
				{"type": E.JEEP, "count": 8, "interval": 0.95, "delay": 0.0, "lane": -1},
			],
		},
		{
			"title": "PINCER PROBE",
			"bonus": 40,
			"groups": [
				{"type": E.JEEP, "count": 6, "interval": 0.80, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 5, "interval": 1.25, "delay": 2.2, "lane": 1},
			],
		},
		{
			"title": "DESERT MECHANIZED",
			"bonus": 45,
			"groups": [
				{"type": E.APC, "count": 9, "interval": 1.05, "delay": 0.0, "lane": -1},
				{"type": E.JEEP, "count": 8, "interval": 0.55, "delay": 3.8, "lane": 0},
			],
		},
		{
			"title": "SANDSTONE ARMOR",
			"bonus": 55,
			"groups": [
				{"type": E.TANK, "count": 5, "interval": 1.65, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 6, "interval": 0.95, "delay": 1.5, "lane": 1},
			],
		},
		{
			"title": "DUST DEVIL GUNSHIPS",
			"bonus": 60,
			"groups": [
				{"type": E.CHOPPER, "count": 6, "interval": 1.35, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 10, "interval": 0.58, "delay": 1.2, "lane": -1},
			],
		},
		{
			"title": "TWIN FLANK BLITZ",
			"bonus": 65,
			"groups": [
				{"type": E.TANK, "count": 4, "interval": 1.50, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 4, "interval": 1.50, "delay": 0.8, "lane": 1},
				{"type": E.JEEP, "count": 12, "interval": 0.42, "delay": 3.5, "lane": -1},
			],
		},
		{
			"title": "OASIS ASSAULT",
			"bonus": 75,
			"groups": [
				{"type": E.TANK, "count": 7, "interval": 1.35, "delay": 0.0, "lane": -1},
				{"type": E.CHOPPER, "count": 6, "interval": 1.15, "delay": 2.0, "lane": 0},
				{"type": E.BOMBER, "count": 2, "interval": 2.40, "delay": 4.0, "lane": 0},
			],
		},
		{
			"title": "SUNSCORCH AIR WING",
			"bonus": 85,
			"groups": [
				{"type": E.CHOPPER, "count": 7, "interval": 0.95, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 4, "interval": 1.95, "delay": 2.0, "lane": 0},
				{"type": E.APC, "count": 8, "interval": 0.75, "delay": 3.0, "lane": 1},
			],
		},
		{
			"title": "IRON CARAVAN",
			"bonus": 95,
			"groups": [
				{"type": E.TANK, "count": 11, "interval": 1.10, "delay": 0.0, "lane": -1},
				{"type": E.APC, "count": 12, "interval": 0.65, "delay": 2.2, "lane": -1},
			],
		},
		{
			"title": "DUNE BREAKER",
			"bonus": 120,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 8, "interval": 1.25, "delay": 1.4, "lane": 1},
				{"type": E.CHOPPER, "count": 7, "interval": 1.0, "delay": 3.6, "lane": 0},
			],
		},
		{
			"title": "SIROCCO RAID",
			"bonus": 115,
			"groups": [
				{"type": E.JEEP, "count": 20, "interval": 0.30, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 6, "interval": 1.55, "delay": 1.4, "lane": 0},
				{"type": E.APC, "count": 12, "interval": 0.58, "delay": 3.0, "lane": -1},
			],
		},
		{
			"title": "HEAVY CONVERGENCE",
			"bonus": 135,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 3.6, "lane": 1},
				{"type": E.TANK, "count": 12, "interval": 0.95, "delay": 1.0, "lane": -1},
			],
		},
		{
			"title": "MIRAGE SORTIE",
			"bonus": 145,
			"groups": [
				{"type": E.CHOPPER, "count": 12, "interval": 0.72, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 8, "interval": 1.35, "delay": 1.2, "lane": 0},
				{"type": E.TANK, "count": 9, "interval": 1.10, "delay": 2.4, "lane": -1},
			],
		},
		{
			"title": "DESERT HAMMER",
			"bonus": 165,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.5, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 14, "interval": 0.88, "delay": 1.0, "lane": -1},
				{"type": E.BOMBER, "count": 7, "interval": 1.30, "delay": 3.2, "lane": 0},
			],
		},
		{
			"title": "CRIMSON HORIZON",
			"bonus": 190,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 4, "interval": 3.2, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 9, "interval": 1.20, "delay": 1.5, "lane": 0},
				{"type": E.CHOPPER, "count": 12, "interval": 0.65, "delay": 3.0, "lane": 0},
				{"type": E.TANK, "count": 12, "interval": 0.82, "delay": 2.0, "lane": -1},
			],
		},
		{
			"title": "OPERATION RED SAND",
			"bonus": 300,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 5, "interval": 3.0, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 16, "interval": 0.78, "delay": 1.0, "lane": -1},
				{"type": E.BOMBER, "count": 10, "interval": 1.15, "delay": 2.2, "lane": 0},
				{"type": E.CHOPPER, "count": 12, "interval": 0.62, "delay": 3.8, "lane": 0},
				{"type": E.JEEP, "count": 18, "interval": 0.28, "delay": 5.0, "lane": -1},
			],
		},
	]

static func get_frostline_pass_waves() -> Array[Dictionary]:
	# lane: 0 = North Bridge Highway, 1 = South Bridge Highway, -1 = Alternate both bridges
	var E := EnemyData.EnemyType
	return [
		{
			"title": "WHITE-OUT SCOUTS",
			"bonus": 40,
			"groups": [
				{"type": E.JEEP, "count": 9, "interval": 0.88, "delay": 0.0, "lane": -1},
			],
		},
		{
			"title": "TWIN BRIDGE PROBE",
			"bonus": 45,
			"groups": [
				{"type": E.APC, "count": 4, "interval": 1.25, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 8, "interval": 0.70, "delay": 1.4, "lane": 1},
			],
		},
		{
			"title": "GLACIAL CONVOY",
			"bonus": 50,
			"groups": [
				{"type": E.APC, "count": 10, "interval": 0.95, "delay": 0.0, "lane": -1},
				{"type": E.JEEP, "count": 8, "interval": 0.50, "delay": 3.5, "lane": -1},
			],
		},
		{
			"title": "FROSTBITE ARMOR",
			"bonus": 60,
			"groups": [
				{"type": E.TANK, "count": 5, "interval": 1.55, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 7, "interval": 0.90, "delay": 1.2, "lane": 1},
			],
		},
		{
			"title": "ARCTIC GUNSHIPS",
			"bonus": 65,
			"groups": [
				{"type": E.CHOPPER, "count": 6, "interval": 1.25, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 4, "interval": 1.50, "delay": 1.8, "lane": 1},
				{"type": E.JEEP, "count": 8, "interval": 0.55, "delay": 2.4, "lane": 0},
			],
		},
		{
			"title": "NORTH-SOUTH PINCER",
			"bonus": 75,
			"groups": [
				{"type": E.TANK, "count": 5, "interval": 1.35, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 5, "interval": 1.35, "delay": 0.6, "lane": 1},
				{"type": E.JEEP, "count": 14, "interval": 0.40, "delay": 3.0, "lane": -1},
			],
		},
		{
			"title": "BLIZZARD SORTIE",
			"bonus": 85,
			"groups": [
				{"type": E.CHOPPER, "count": 7, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 3, "interval": 2.1, "delay": 1.8, "lane": 0},
				{"type": E.APC, "count": 10, "interval": 0.72, "delay": 2.4, "lane": -1},
			],
		},
		{
			"title": "ICEBREAKER COLUMN",
			"bonus": 95,
			"groups": [
				{"type": E.TANK, "count": 10, "interval": 1.05, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 4, "interval": 1.85, "delay": 2.2, "lane": 0},
			],
		},
		{
			"title": "WINTER VANGUARD",
			"bonus": 110,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 8, "interval": 1.15, "delay": 1.2, "lane": 1},
				{"type": E.CHOPPER, "count": 8, "interval": 0.90, "delay": 3.0, "lane": 0},
			],
		},
		{
			"title": "SUBZERO BLITZ",
			"bonus": 120,
			"groups": [
				{"type": E.JEEP, "count": 22, "interval": 0.28, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 6, "interval": 1.45, "delay": 1.2, "lane": 0},
				{"type": E.APC, "count": 12, "interval": 0.55, "delay": 2.8, "lane": -1},
			],
		},
		{
			"title": "TWIN JUGGERNAUTS",
			"bonus": 140,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 2.4, "lane": 1},
				{"type": E.TANK, "count": 12, "interval": 0.92, "delay": 1.0, "lane": -1},
			],
		},
		{
			"title": "POLAR AIR STRIKE",
			"bonus": 150,
			"groups": [
				{"type": E.CHOPPER, "count": 12, "interval": 0.68, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 8, "interval": 1.30, "delay": 1.0, "lane": 0},
				{"type": E.TANK, "count": 10, "interval": 1.0, "delay": 2.4, "lane": -1},
			],
		},
		{
			"title": "AVALANCHE DIVISION",
			"bonus": 170,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.4, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 14, "interval": 0.85, "delay": 1.0, "lane": -1},
				{"type": E.APC, "count": 12, "interval": 0.58, "delay": 3.0, "lane": -1},
			],
		},
		{
			"title": "GLACIER STORM",
			"bonus": 190,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.2, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 9, "interval": 1.18, "delay": 1.2, "lane": 0},
				{"type": E.CHOPPER, "count": 12, "interval": 0.62, "delay": 2.6, "lane": 0},
			],
		},
		{
			"title": "IRON FROSTLINE",
			"bonus": 215,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 4, "interval": 3.0, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 16, "interval": 0.78, "delay": 1.0, "lane": -1},
				{"type": E.BOMBER, "count": 8, "interval": 1.20, "delay": 2.8, "lane": 0},
			],
		},
		{
			"title": "NORTHERN OVERRUN",
			"bonus": 250,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 4, "interval": 2.8, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 10, "interval": 1.10, "delay": 1.2, "lane": 0},
				{"type": E.CHOPPER, "count": 14, "interval": 0.56, "delay": 2.4, "lane": 0},
				{"type": E.TANK, "count": 14, "interval": 0.74, "delay": 1.6, "lane": -1},
			],
		},
		{
			"title": "OPERATION PERMAFROST",
			"bonus": 350,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 6, "interval": 2.8, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 18, "interval": 0.72, "delay": 1.0, "lane": -1},
				{"type": E.BOMBER, "count": 11, "interval": 1.08, "delay": 2.0, "lane": 0},
				{"type": E.CHOPPER, "count": 14, "interval": 0.56, "delay": 3.4, "lane": 0},
				{"type": E.JEEP, "count": 20, "interval": 0.25, "delay": 4.8, "lane": -1},
			],
		},
	]

static func get_granite_gorge_waves() -> Array[Dictionary]:
	# lane: 0 = Highland Switchback Valley (North), 1 = Deep Ravine Valley (South), -1 = Alternate both valleys
	var E := EnemyData.EnemyType
	return [
		{
			"title": "VALLEY OUTRIDERS",
			"bonus": 45,
			"groups": [
				{"type": E.JEEP, "count": 10, "interval": 0.82, "delay": 0.0, "lane": -1},
			],
		},
		{
			"title": "RAVINE INFILTRATION",
			"bonus": 50,
			"groups": [
				{"type": E.APC, "count": 5, "interval": 1.15, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 9, "interval": 0.65, "delay": 1.2, "lane": 1},
			],
		},
		{
			"title": "SWITCHBACK CONVOY",
			"bonus": 55,
			"groups": [
				{"type": E.APC, "count": 11, "interval": 0.90, "delay": 0.0, "lane": -1},
				{"type": E.JEEP, "count": 10, "interval": 0.45, "delay": 3.0, "lane": -1},
			],
		},
		{
			"title": "GRANITE SPEARHEAD",
			"bonus": 65,
			"groups": [
				{"type": E.TANK, "count": 6, "interval": 1.45, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 8, "interval": 0.82, "delay": 1.0, "lane": 1},
			],
		},
		{
			"title": "RIDGE RUNNERS",
			"bonus": 70,
			"groups": [
				{"type": E.CHOPPER, "count": 7, "interval": 1.15, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 5, "interval": 1.40, "delay": 1.5, "lane": 1},
				{"type": E.JEEP, "count": 10, "interval": 0.48, "delay": 2.2, "lane": 0},
			],
		},
		{
			"title": "TWIN CANYON PUSH",
			"bonus": 80,
			"groups": [
				{"type": E.TANK, "count": 6, "interval": 1.25, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 6, "interval": 1.25, "delay": 0.5, "lane": 1},
				{"type": E.JEEP, "count": 14, "interval": 0.36, "delay": 2.8, "lane": -1},
			],
		},
		{
			"title": "HIGH ALTITUDE RAID",
			"bonus": 90,
			"groups": [
				{"type": E.CHOPPER, "count": 8, "interval": 0.92, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 4, "interval": 1.95, "delay": 1.6, "lane": 0},
				{"type": E.APC, "count": 11, "interval": 0.68, "delay": 2.2, "lane": -1},
			],
		},
		{
			"title": "BOULDER BREAKER",
			"bonus": 105,
			"groups": [
				{"type": E.TANK, "count": 12, "interval": 0.98, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 5, "interval": 1.75, "delay": 2.0, "lane": 0},
			],
		},
		{
			"title": "SUMMIT SIEGE",
			"bonus": 120,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 9, "interval": 1.08, "delay": 1.0, "lane": 1},
				{"type": E.CHOPPER, "count": 9, "interval": 0.82, "delay": 2.8, "lane": 0},
			],
		},
		{
			"title": "GORGE STAMPEDE",
			"bonus": 130,
			"groups": [
				{"type": E.JEEP, "count": 24, "interval": 0.25, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 7, "interval": 1.38, "delay": 1.0, "lane": 0},
				{"type": E.APC, "count": 14, "interval": 0.50, "delay": 2.6, "lane": -1},
			],
		},
		{
			"title": "DOUBLE TITAN",
			"bonus": 150,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 2.0, "lane": 1},
				{"type": E.TANK, "count": 13, "interval": 0.88, "delay": 0.8, "lane": -1},
			],
		},
		{
			"title": "CONDOR WING",
			"bonus": 165,
			"groups": [
				{"type": E.CHOPPER, "count": 13, "interval": 0.62, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 9, "interval": 1.22, "delay": 1.0, "lane": 0},
				{"type": E.TANK, "count": 11, "interval": 0.94, "delay": 2.2, "lane": -1},
			],
		},
		{
			"title": "LANDSLIDE ARMOR",
			"bonus": 185,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.1, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 15, "interval": 0.80, "delay": 0.9, "lane": -1},
				{"type": E.APC, "count": 14, "interval": 0.52, "delay": 2.8, "lane": -1},
			],
		},
		{
			"title": "ALPINE THUNDER",
			"bonus": 205,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 2.9, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 10, "interval": 1.12, "delay": 1.1, "lane": 0},
				{"type": E.CHOPPER, "count": 13, "interval": 0.58, "delay": 2.4, "lane": 0},
			],
		},
		{
			"title": "CRAG HAMMER",
			"bonus": 230,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 4, "interval": 2.7, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 17, "interval": 0.74, "delay": 0.8, "lane": -1},
				{"type": E.BOMBER, "count": 9, "interval": 1.14, "delay": 2.5, "lane": 0},
			],
		},
		{
			"title": "CITADEL ASSAULT",
			"bonus": 265,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 5, "interval": 2.6, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 11, "interval": 1.05, "delay": 1.0, "lane": 0},
				{"type": E.CHOPPER, "count": 15, "interval": 0.52, "delay": 2.2, "lane": 0},
				{"type": E.TANK, "count": 15, "interval": 0.70, "delay": 1.5, "lane": -1},
			],
		},
		{
			"title": "IRON PEAKS",
			"bonus": 310,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 5, "interval": 2.5, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 18, "interval": 0.68, "delay": 0.8, "lane": -1},
				{"type": E.BOMBER, "count": 12, "interval": 1.02, "delay": 1.8, "lane": 0},
				{"type": E.JEEP, "count": 24, "interval": 0.24, "delay": 3.5, "lane": -1},
			],
		},
		{
			"title": "OPERATION AVALANCHE",
			"bonus": 400,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 7, "interval": 2.5, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 20, "interval": 0.66, "delay": 0.9, "lane": -1},
				{"type": E.BOMBER, "count": 12, "interval": 1.0, "delay": 1.8, "lane": 0},
				{"type": E.CHOPPER, "count": 16, "interval": 0.50, "delay": 3.2, "lane": 0},
				{"type": E.JEEP, "count": 24, "interval": 0.22, "delay": 4.4, "lane": -1},
			],
		},
	]

static func get_north_pole_waves() -> Array[Dictionary]:
	# THE 12 WAVES OF CHRISTMAS — Runaway Clockwork Toys!
	var E := EnemyData.EnemyType
	return [
		{
			"title": "DAY 1 — WIND-UP TIN RACERS",
			"bonus": 45,
			"groups": [
				{"type": E.JEEP, "count": 10, "interval": 0.85, "delay": 0.0, "lane": -1},
			],
		},
		{
			"title": "DAY 2 — CHOO-CHOO EXPRESS",
			"bonus": 50,
			"groups": [
				{"type": E.APC, "count": 6, "interval": 1.15, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 8, "interval": 0.65, "delay": 1.6, "lane": 1},
			],
		},
		{
			"title": "DAY 3 — CLOCKWORK PARADE",
			"bonus": 55,
			"groups": [
				{"type": E.APC, "count": 10, "interval": 0.90, "delay": 0.0, "lane": -1},
				{"type": E.JEEP, "count": 10, "interval": 0.45, "delay": 3.0, "lane": -1},
			],
		},
		{
			"title": "DAY 4 — NUTCRACKER GUARD",
			"bonus": 65,
			"groups": [
				{"type": E.TANK, "count": 5, "interval": 1.50, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 8, "interval": 0.85, "delay": 1.2, "lane": 1},
			],
		},
		{
			"title": "DAY 5 — WHIRLYBIRD SWARM",
			"bonus": 75,
			"groups": [
				{"type": E.CHOPPER, "count": 7, "interval": 1.10, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 12, "interval": 0.48, "delay": 1.4, "lane": -1},
			],
		},
		{
			"title": "DAY 6 — PEPPERMINT PINCER",
			"bonus": 85,
			"groups": [
				{"type": E.TANK, "count": 5, "interval": 1.30, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 5, "interval": 1.30, "delay": 0.6, "lane": 1},
				{"type": E.CHOPPER, "count": 6, "interval": 1.0, "delay": 2.8, "lane": 0},
			],
		},
		{
			"title": "DAY 7 — TIN ZEPPELIN FLEET",
			"bonus": 95,
			"groups": [
				{"type": E.BOMBER, "count": 4, "interval": 1.90, "delay": 0.0, "lane": 0},
				{"type": E.CHOPPER, "count": 8, "interval": 0.85, "delay": 1.4, "lane": 0},
				{"type": E.APC, "count": 10, "interval": 0.70, "delay": 2.0, "lane": -1},
			],
		},
		{
			"title": "DAY 8 — KING CRACKER AWAKENS",
			"bonus": 130,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 8, "interval": 1.15, "delay": 1.5, "lane": 1},
				{"type": E.JEEP, "count": 14, "interval": 0.36, "delay": 3.2, "lane": -1},
			],
		},
		{
			"title": "DAY 9 — TINSEL SKY CARNIVAL",
			"bonus": 145,
			"groups": [
				{"type": E.BOMBER, "count": 7, "interval": 1.35, "delay": 0.0, "lane": 0},
				{"type": E.CHOPPER, "count": 12, "interval": 0.65, "delay": 1.0, "lane": 0},
				{"type": E.TANK, "count": 9, "interval": 1.0, "delay": 2.4, "lane": -1},
			],
		},
		{
			"title": "DAY 10 — GINGERBREAD BATTALION",
			"bonus": 170,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 2, "interval": 3.4, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 12, "interval": 0.88, "delay": 1.0, "lane": -1},
				{"type": E.APC, "count": 12, "interval": 0.55, "delay": 2.8, "lane": -1},
			],
		},
		{
			"title": "DAY 11 — OVERWOUND TOYBOX",
			"bonus": 210,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.0, "delay": 0.0, "lane": -1},
				{"type": E.BOMBER, "count": 8, "interval": 1.15, "delay": 1.2, "lane": 0},
				{"type": E.CHOPPER, "count": 12, "interval": 0.60, "delay": 2.4, "lane": 0},
				{"type": E.JEEP, "count": 20, "interval": 0.25, "delay": 3.6, "lane": -1},
			],
		},
		{
			"title": "DAY 12 — OPERATION TINSEL STORM!",
			"bonus": 500,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 5, "interval": 2.6, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 16, "interval": 0.72, "delay": 1.0, "lane": -1},
				{"type": E.BOMBER, "count": 10, "interval": 1.08, "delay": 1.8, "lane": 0},
				{"type": E.CHOPPER, "count": 14, "interval": 0.52, "delay": 3.0, "lane": 0},
				{"type": E.APC, "count": 14, "interval": 0.48, "delay": 4.2, "lane": -1},
			],
		},
	]
