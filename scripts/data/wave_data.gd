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
	if map_id == "ironbourne":
		return get_ironbourne_waves()
	if map_id == "cotswold_vale":
		return get_cotswold_vale_waves()
	if map_id == "whisperwood":
		return get_whisperwood_waves()
	if map_id == "red_centre":
		return get_red_centre_waves()
	if map_id == "coral_atoll":
		return get_coral_atoll_waves()
	if map_id == "obsidian_caldera":
		return get_obsidian_caldera_waves()
	if map_id == "bayou_delta":
		return get_bayou_delta_waves()
	if map_id == "neon_tokyo":
		return get_neon_tokyo_waves()
	if map_id == "tranquility_crater":
		return get_tranquility_crater_waves()
	if map_id == "olympus_rift":
		return get_olympus_rift_waves()
	if map_id == "europa_abyss":
		return get_europa_abyss_waves()
	if map_id == "xenon_prime":
		return get_xenon_prime_waves()
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
				{"type": E.TANK, "count": 5, "interval": 1.5, "delay": 0.0, "lane": 0},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.4, "delay": 1.4, "lane": 0},
				{"type": E.APC, "count": 6, "interval": 0.9, "delay": 1.0, "lane": 0},
				{"type": E.CHOPPER, "count": 4, "interval": 1.35, "delay": 3.8, "lane": 0},
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
				{"type": E.APS_TANK, "count": 3, "interval": 2.2, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 6, "interval": 1.25, "delay": 1.5, "lane": 0},
				{"type": E.APC, "count": 8, "interval": 0.75, "delay": 2.5, "lane": 0},
			],
		},
		{
			"title": "SIEGE BREAKER",
			"bonus": 110,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 5, "interval": 1.4, "delay": 1.8, "lane": 0},
				{"type": E.CHOPPER, "count": 6, "interval": 1.1, "delay": 4.2, "lane": 0},
			],
		},
		{
			"title": "LIGHTNING RAID",
			"bonus": 100,
			"groups": [
				{"type": E.JEEP, "count": 16, "interval": 0.34, "delay": 0.0, "lane": 0},
				{"type": E.UAV_CARRIER, "count": 3, "interval": 2.8, "delay": 1.2, "lane": 0},
				{"type": E.BOMBER, "count": 4, "interval": 1.7, "delay": 1.5, "lane": 0},
				{"type": E.APC, "count": 8, "interval": 0.65, "delay": 3.5, "lane": 0},
			],
		},
		{
			"title": "ARMOR DIVISION",
			"bonus": 120,
			"groups": [
				{"type": E.APS_TANK, "count": 5, "interval": 1.8, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 8, "interval": 1.05, "delay": 1.2, "lane": 0},
				{"type": E.JUGGERNAUT, "count": 2, "interval": 5.0, "delay": 2.0, "lane": 0},
			],
		},
		{
			"title": "VALKYRIE SORTIE",
			"bonus": 130,
			"groups": [
				{"type": E.SKY_FORTRESS, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.CHOPPER, "count": 9, "interval": 0.8, "delay": 1.0, "lane": 0},
				{"type": E.BOMBER, "count": 6, "interval": 1.45, "delay": 1.6, "lane": 0},
				{"type": E.TANK, "count": 7, "interval": 1.2, "delay": 2.5, "lane": 0},
			],
		},
		{
			"title": "SCORCHED EARTH",
			"bonus": 150,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.8, "delay": 0.0, "lane": 0},
				{"type": E.APS_TANK, "count": 5, "interval": 1.6, "delay": 1.0, "lane": 0},
				{"type": E.TANK, "count": 8, "interval": 0.95, "delay": 1.6, "lane": 0},
				{"type": E.BOMBER, "count": 6, "interval": 1.4, "delay": 3.5, "lane": 0},
			],
		},
		{
			"title": "OPERATION IRON STORM",
			"bonus": 250,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.4, "delay": 0.0, "lane": 0},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 5.2, "delay": 1.8, "lane": 0},
				{"type": E.APS_TANK, "count": 6, "interval": 1.4, "delay": 1.2, "lane": 0},
				{"type": E.UAV_CARRIER, "count": 3, "interval": 2.6, "delay": 2.2, "lane": 0},
				{"type": E.TANK, "count": 10, "interval": 0.85, "delay": 1.4, "lane": 0},
				{"type": E.BOMBER, "count": 6, "interval": 1.25, "delay": 2.5, "lane": 0},
				{"type": E.CHOPPER, "count": 8, "interval": 0.7, "delay": 4.0, "lane": 0},
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
				{"type": E.TANK, "count": 5, "interval": 1.35, "delay": 0.0, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.2, "delay": 1.2, "lane": -1},
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
				{"type": E.APS_TANK, "count": 4, "interval": 2.0, "delay": 0.0, "lane": -1},
				{"type": E.TANK, "count": 8, "interval": 1.10, "delay": 1.2, "lane": -1},
				{"type": E.APC, "count": 10, "interval": 0.65, "delay": 2.2, "lane": -1},
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
				{"type": E.SKY_FORTRESS, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.CHOPPER, "count": 10, "interval": 0.72, "delay": 1.0, "lane": 0},
				{"type": E.BOMBER, "count": 7, "interval": 1.35, "delay": 1.4, "lane": 0},
				{"type": E.APS_TANK, "count": 4, "interval": 1.8, "delay": 2.0, "lane": -1},
				{"type": E.TANK, "count": 6, "interval": 1.10, "delay": 2.6, "lane": -1},
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
				{"type": E.JUGGERNAUT, "count": 4, "interval": 3.0, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 4.8, "delay": 1.6, "lane": 0},
				{"type": E.APS_TANK, "count": 6, "interval": 1.35, "delay": 1.0, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 4, "interval": 2.4, "delay": 2.0, "lane": -1},
				{"type": E.TANK, "count": 12, "interval": 0.78, "delay": 1.2, "lane": -1},
				{"type": E.BOMBER, "count": 8, "interval": 1.15, "delay": 2.2, "lane": 0},
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
				{"type": E.APS_TANK, "count": 4, "interval": 1.9, "delay": 0.0, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.0, "delay": 1.4, "lane": -1},
				{"type": E.TANK, "count": 7, "interval": 1.05, "delay": 1.0, "lane": -1},
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
				{"type": E.JUGGERNAUT, "count": 2, "interval": 3.2, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 4.6, "delay": 1.2, "lane": 0},
				{"type": E.APS_TANK, "count": 5, "interval": 1.5, "delay": 1.6, "lane": -1},
				{"type": E.BOMBER, "count": 7, "interval": 1.18, "delay": 1.8, "lane": 0},
				{"type": E.CHOPPER, "count": 10, "interval": 0.62, "delay": 2.6, "lane": 0},
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
				{"type": E.APS_TANK, "count": 4, "interval": 1.8, "delay": 0.0, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 3, "interval": 2.8, "delay": 1.2, "lane": -1},
				{"type": E.TANK, "count": 8, "interval": 0.98, "delay": 0.8, "lane": -1},
				{"type": E.BOMBER, "count": 4, "interval": 1.75, "delay": 2.0, "lane": 0},
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
				{"type": E.JUGGERNAUT, "count": 2, "interval": 2.9, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 4.4, "delay": 1.0, "lane": 0},
				{"type": E.APS_TANK, "count": 5, "interval": 1.4, "delay": 1.5, "lane": -1},
				{"type": E.BOMBER, "count": 8, "interval": 1.12, "delay": 1.6, "lane": 0},
				{"type": E.CHOPPER, "count": 10, "interval": 0.58, "delay": 2.4, "lane": 0},
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
				{"type": E.TANK, "count": 4, "interval": 1.30, "delay": 0.0, "lane": 0},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.0, "delay": 1.0, "lane": 1},
				{"type": E.TANK, "count": 4, "interval": 1.30, "delay": 0.6, "lane": 1},
				{"type": E.CHOPPER, "count": 5, "interval": 1.0, "delay": 2.8, "lane": 0},
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
				{"type": E.APS_TANK, "count": 3, "interval": 2.0, "delay": 1.0, "lane": -1},
				{"type": E.TANK, "count": 6, "interval": 1.15, "delay": 1.5, "lane": 1},
				{"type": E.JEEP, "count": 12, "interval": 0.36, "delay": 3.2, "lane": -1},
			],
		},
		{
			"title": "DAY 9 — TINSEL SKY CARNIVAL",
			"bonus": 145,
			"groups": [
				{"type": E.SKY_FORTRESS, "count": 1, "interval": 1.0, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 6, "interval": 1.35, "delay": 1.0, "lane": 0},
				{"type": E.UAV_CARRIER, "count": 3, "interval": 2.6, "delay": 1.6, "lane": -1},
				{"type": E.CHOPPER, "count": 10, "interval": 0.65, "delay": 1.2, "lane": 0},
			],
		},
		{
			"title": "DAY 10 — GINGERBREAD BATTALION",
			"bonus": 170,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 2, "interval": 3.4, "delay": 0.0, "lane": -1},
				{"type": E.APS_TANK, "count": 5, "interval": 1.6, "delay": 0.8, "lane": -1},
				{"type": E.TANK, "count": 8, "interval": 0.88, "delay": 1.4, "lane": -1},
				{"type": E.APC, "count": 10, "interval": 0.55, "delay": 2.8, "lane": -1},
			],
		},
		{
			"title": "DAY 11 — OVERWOUND TOYBOX",
			"bonus": 210,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 2, "interval": 3.0, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 4.2, "delay": 1.2, "lane": 0},
				{"type": E.BOMBER, "count": 6, "interval": 1.15, "delay": 1.8, "lane": 0},
				{"type": E.CHOPPER, "count": 10, "interval": 0.60, "delay": 2.4, "lane": 0},
				{"type": E.JEEP, "count": 16, "interval": 0.25, "delay": 3.6, "lane": -1},
			],
		},
		{
			"title": "DAY 12 — OPERATION TINSEL STORM!",
			"bonus": 500,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 4, "interval": 2.6, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 4.0, "delay": 1.4, "lane": 0},
				{"type": E.APS_TANK, "count": 6, "interval": 1.3, "delay": 0.8, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 4, "interval": 2.4, "delay": 1.8, "lane": -1},
				{"type": E.TANK, "count": 12, "interval": 0.72, "delay": 1.2, "lane": -1},
				{"type": E.BOMBER, "count": 8, "interval": 1.08, "delay": 2.0, "lane": 0},
			],
		},
	]

static func get_ironbourne_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"SUBURBAN RECON", "HIGH STREET PUSH", "RAIL AVENUE CONVOY", "DOWNTOWN ARMOR",
		"ROOFTOP GUNSHIPS", "CANAL CROSSING BLITZ", "CIVIC AIR WING", "BOULEVARD PHALANX",
		"URBAN BREAKER", "STREET SWEEPERS", "TWIN BLOCKADE", "SKYLINE SORTIE",
		"CONCRETE CRUSHER", "MIDTOWN SIEGE", "CANAL HAMMER", "CITY HALL ASSAULT",
		"IRON AVENUE", "METRO OVERRUN", "OPERATION BLACKTOP"
	]
	return _build_campaign_waves(19, 1.08, titles)

static func get_cotswold_vale_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"COUNTRY LANE SCOUTS", "ORCHARD PROBE", "HEDGEROW COLUMN", "MEADOW ARMOR",
		"VALE GUNSHIPS", "STONE BRIDGE PUSH", "PASTURE AIR WING", "WHEATFIELD PHALANX",
		"MANOR BREAKER", "BARNSTORMER RAID", "SPLIT LANE TITANS", "SHIRES SORTIE",
		"DRY-STONE SIEGE", "COUNTRYSIDE STORM", "GREEN BELT HAMMER", "ESTATE ASSAULT",
		"ROLLING THUNDER", "VALLEY OVERRUN", "ROYAL GUARD PUSH", "OPERATION HARVEST"
	]
	return _build_campaign_waves(20, 1.16, titles)

static func get_whisperwood_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"TRAILHEAD SCOUTS", "LOGGING ROAD PUSH", "DEEP WOODS CONVOY", "TIMBERLINE ARMOR",
		"CANOPY GUNSHIPS", "CREEK BRIDGE PINCER", "TREETOP STRIKE", "MOSSWOOD PHALANX",
		"FOREST BREAKER", "GLADE STAMPEDE", "TWIN TIMBER TITANS", "EMERALD SORTIE",
		"ANCIENT GROVE SIEGE", "WOODLAND THUNDER", "PINE RIDGE HAMMER", "DEEPWOOD ASSAULT",
		"SHADOWED TRAILS", "TIMBER OVERRUN", "WILDWOOD VANGUARD", "IRON CANOPY", "OPERATION FALLEN OAK"
	]
	return _build_campaign_waves(21, 1.24, titles)

static func get_red_centre_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"RED DUST SCOUTS", "STUART TRACK PROBE", "OUTBACK CARAVAN", "IRON-RED ARMOR",
		"HEATWAVE GUNSHIPS", "BILLABONG PINCER", "SCORCHED AIR WING", "MESA PHALANX",
		"ULURU BREAKER", "ROAD TRAIN RAMPAGE", "TWIN RED TITANS", "SOUTHERN CROSS SORTIE",
		"SPINIFEX SIEGE", "OUTBACK THUNDER", "RED ROCK HAMMER", "STATION ASSAULT",
		"DUST DEVIL DIVISION", "BUSHFIRE OVERRUN", "CRIMSON VANGUARD", "SUNSTROKE ARMADA",
		"IRON OUTBACK", "OPERATION RED STORM"
	]
	return _build_campaign_waves(22, 1.34, titles)

static func get_coral_atoll_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"BEACHHEAD SCOUTS", "SURF LINE PROBE", "PALM CAUSEWAY PUSH", "CORAL ARMOR",
		"TROPICAL GUNSHIPS", "LAGOON PINCER", "MONSOON AIR WING", "ATOLL PHALANX",
		"REEF BREAKER", "TIDAL STAMPEDE", "TWIN SANDBAR TITANS", "PACIFIC SORTIE",
		"ISLAND SIEGE", "TYPHOON THUNDER", "TURQUOISE HAMMER", "SEAWALL ASSAULT",
		"TROPIC DIVISION", "CYCLONE OVERRUN", "CORAL VANGUARD", "TRADEWIND ARMADA",
		"IRON LAGOON", "PACIFIC TEMPEST", "OPERATION TIDAL WAVE"
	]
	return _build_campaign_waves(23, 1.44, titles)

static func get_obsidian_caldera_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"ASHFALL SCOUTS", "CINDER RIDGE PROBE", "BASALT CONVOY", "MAGMA ARMOR",
		"THERMAL GUNSHIPS", "LAVA BRIDGE PINCER", "SCORCHED AIR WING", "CALDERA PHALANX",
		"OBSIDIAN BREAKER", "PYROCLASTIC RUSH", "TWIN MOLTEN TITANS", "VOLCANO SORTIE",
		"CRATER RIM SIEGE", "BRIMSTONE THUNDER", "SLAG HAMMER", "FORGE ASSAULT",
		"INFERNO DIVISION", "ERUPTION OVERRUN", "MAGMA VANGUARD", "ASHSTORM ARMADA",
		"IRON CALDERA", "MOLTEN FURY", "DOOMSDAY VENT", "OPERATION HELLFIRE"
	]
	return _build_campaign_waves(24, 1.54, titles)

static func get_bayou_delta_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"MARSHLAND SCOUTS", "FOGGY TRAIL PROBE", "CAUSEWAY COLUMN", "PEAT BOG ARMOR",
		"SWAMP GUNSHIPS", "BAYOU BRIDGE PINCER", "NIGHTMIST AIR WING", "CYPRESS PHALANX",
		"DELTA BREAKER", "ALLIGATOR RUSH", "TWIN MIRE TITANS", "TWILIGHT SORTIE",
		"SINKHOLE SIEGE", "BAYOU THUNDER", "QUAGMIRE HAMMER", "BOARDWALK ASSAULT",
		"WETLAND DIVISION", "BLACKWATER OVERRUN", "MARSH VANGUARD", "FIREFLY ARMADA",
		"IRON BAYOU", "MISTY TEMPEST", "DEEP SWAMP FURY", "DELTA STORM", "OPERATION HIGH WATER"
	]
	return _build_campaign_waves(25, 1.64, titles)

static func get_neon_tokyo_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"CYBER RECON", "EXPRESSWAY PROBE", "NEON GRID CONVOY", "CHROME ARMOR",
		"SKYLINE GUNSHIPS", "NEO-CANAL PINCER", "HOLOGRAM AIR WING", "MEGACITY PHALANX",
		"SHIBUYA BREAKER", "OVERDRIVE BLITZ", "TWIN MECHA TITANS", "MIDNIGHT SORTIE",
		"TOWER BLOCK SIEGE", "ACID RAIN THUNDER", "PLASMA HAMMER", "SYNDICATE ASSAULT",
		"CYBER DIVISION", "BLACKOUT OVERRUN", "NEON VANGUARD", "SKYNET ARMADA",
		"IRON METROPOLIS", "VOLTAGE TEMPEST", "CHROME FURY", "GHOST PROTOCOL",
		"HYPERDRIVE PUSH", "OPERATION ZERO HOUR"
	]
	return _build_campaign_waves(26, 1.75, titles)

static func get_tranquility_crater_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"LUNAR ROVERS", "REGOLITH PROBE", "CRATER RIM CONVOY", "LOW-G ARMOR",
		"ORBITAL GUNSHIPS", "RILLE TRUSS PINCER", "VACUUM AIR WING", "TRANQUILITY PHALANX",
		"APOLLO BREAKER", "DUST CLOUD BLITZ", "TWIN CRATER TITANS", "ECLIPSE SORTIE",
		"MARE SIEGE", "SILENT THUNDER", "METEOR HAMMER", "MOONBASE ASSAULT",
		"LUNAR DIVISION", "DARKSIDE OVERRUN", "SELENITE VANGUARD", "STARLIGHT ARMADA",
		"IRON CRATER", "SOLAR FLARE", "ZERO-G FURY", "DEEP RILLE STORM",
		"ORBITAL DROP", "APOGEE PUSH", "OPERATION MOONFALL"
	]
	return _build_campaign_waves(27, 1.86, titles)

static func get_olympus_rift_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"MARTIAN SCOUTS", "RED CANYON PROBE", "FREIGHTWAY CONVOY", "VERMILION ARMOR",
		"DUSTSTORM GUNSHIPS", "VIADUCT PINCER", "ARES AIR WING", "OLYMPUS PHALANX",
		"MARINERIS BREAKER", "RED DUST BLITZ", "TWIN CANYON TITANS", "PHOBOS SORTIE",
		"RIFT VALLEY SIEGE", "MARTIAN THUNDER", "IRON OXIDE HAMMER", "COLONY ASSAULT",
		"RED PLANET DIVISION", "SANDSTORM OVERRUN", "ARES VANGUARD", "ORBITAL ARMADA",
		"IRON RIFT", "SOLAR TEMPEST", "OLYMPUS FURY", "DEIMOS DROP",
		"DRY-ICE STORM", "CRIMSON TIDE", "MARTIAN CRUSADE", "OPERATION RED PLANET"
	]
	return _build_campaign_waves(28, 1.98, titles)

static func get_europa_abyss_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"CRYO SCOUTS", "LINEAE PROBE", "ICE SHELL CONVOY", "SUB-ZERO ARMOR",
		"JOVIAN GUNSHIPS", "FISSURE SPAN PINCER", "ABYSSAL AIR WING", "EUROPA PHALANX",
		"GLACIER BREAKER", "FROSTQUAKE BLITZ", "TWIN CRYO TITANS", "GANYMEDE SORTIE",
		"TECTONIC SIEGE", "JOVIAN THUNDER", "PERMAFROST HAMMER", "OUTPOST ASSAULT",
		"CRYO DIVISION", "WHITEOUT OVERRUN", "EUROPA VANGUARD", "ICE MOON ARMADA",
		"IRON FISSURE", "TIDAL FLEX", "ABSOLUTE ZERO", "DEEP OCEAN STORM",
		"JUPITER ECLIPSE", "CRYO VORTEX", "SUBSURFACE FURY", "JOVIAN CRUSADE", "OPERATION DEEP FREEZE"
	]
	return _build_campaign_waves(29, 2.12, titles)

static func get_xenon_prime_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"EXOPLANET SCOUTS", "CRYSTAL TRAIL PROBE", "NEBULA CONVOY", "XENO-ALLOY ARMOR",
		"STARFIRE GUNSHIPS", "PLASMA SPAN PINCER", "VOID AIR WING", "XENON PHALANX",
		"SPIRE BREAKER", "WARP SPEED BLITZ", "TWIN PLASMA TITANS", "SUPERNOVA SORTIE",
		"LEY-LINE SIEGE", "COSMIC THUNDER", "QUASAR HAMMER", "STARPORT ASSAULT",
		"GALACTIC DIVISION", "ECLIPSE OVERRUN", "XENON VANGUARD", "DEEP SPACE ARMADA",
		"IRON EXOPLANET", "ION TEMPEST", "CRYSTAL FURY", "SINGULARITY WAVE",
		"NEBULA STORM", "HYPERNOVA PUSH", "STARFORGE TITAN", "VOID CONVERGENCE",
		"FINAL FRONTIER", "OPERATION XENON OMEGA"
	]
	return _build_campaign_waves(30, 2.28, titles)

static func _build_campaign_waves(count: int, intensity: float, titles: Array[String]) -> Array[Dictionary]:
	var E := EnemyData.EnemyType
	var out: Array[Dictionary] = []
	for i in range(count):
		var w_num: int = i + 1
		var title: String = titles[i] if i < titles.size() else ("HOSTILE WAVE %d" % w_num)
		var groups: Array[Dictionary] = []
		var bonus: int = int(round((42.0 + float(i) * 14.0) * intensity))
		var pace: float = clampf(1.0 / pow(intensity, 0.45), 0.72, 1.0)

		if w_num == 1:
			groups.append({"type": E.JEEP, "count": int(round(10 * intensity)), "interval": 0.78 * pace, "delay": 0.0, "lane": -1})
		elif w_num == 2:
			groups.append({"type": E.APC, "count": int(round(5 * intensity)), "interval": 1.10 * pace, "delay": 0.0, "lane": 0})
			groups.append({"type": E.JEEP, "count": int(round(9 * intensity)), "interval": 0.60 * pace, "delay": 1.2, "lane": 1})
		elif w_num == 3:
			groups.append({"type": E.APC, "count": int(round(11 * intensity)), "interval": 0.85 * pace, "delay": 0.0, "lane": -1})
			groups.append({"type": E.JEEP, "count": int(round(10 * intensity)), "interval": 0.44 * pace, "delay": 2.8, "lane": -1})
		elif w_num == 4:
			groups.append({"type": E.TANK, "count": int(round(6 * intensity)), "interval": 1.38 * pace, "delay": 0.0, "lane": 0})
			groups.append({"type": E.APC, "count": int(round(8 * intensity)), "interval": 0.78 * pace, "delay": 1.0, "lane": 1})
		elif w_num == 5:
			groups.append({"type": E.CHOPPER, "count": int(round(7 * intensity)), "interval": 1.08 * pace, "delay": 0.0, "lane": 0})
			groups.append({"type": E.TANK, "count": int(round(5 * intensity)), "interval": 1.35 * pace, "delay": 1.4, "lane": 1})
			groups.append({"type": E.JEEP, "count": int(round(10 * intensity)), "interval": 0.45 * pace, "delay": 2.0, "lane": 0})
		elif w_num == count:
			# Epic multi-domain final wave!
			bonus = int(round(420.0 * intensity))
			groups.append({"type": E.JUGGERNAUT, "count": int(round(4 * intensity)), "interval": 2.4 * pace, "delay": 0.0, "lane": -1})
			groups.append({"type": E.SKY_FORTRESS, "count": maxi(2, int(round(2.0 * intensity))), "interval": 3.8 * pace, "delay": 1.4, "lane": 0})
			groups.append({"type": E.APS_TANK, "count": maxi(4, int(round(6.0 * intensity))), "interval": 1.25 * pace, "delay": 0.6, "lane": -1})
			groups.append({"type": E.UAV_CARRIER, "count": maxi(3, int(round(3.5 * intensity))), "interval": 2.2 * pace, "delay": 1.8, "lane": -1})
			groups.append({"type": E.TANK, "count": int(round(12 * intensity)), "interval": 0.65 * pace, "delay": 0.8, "lane": -1})
			groups.append({"type": E.BOMBER, "count": int(round(8 * intensity)), "interval": 0.98 * pace, "delay": 1.6, "lane": 0})
		else:
			var pattern: int = w_num % 5
			var scale: float = intensity * (1.0 + float(w_num - 5) * 0.075)
			if pattern == 1:
				# Dual-lane armor pincer + fast jeeps
				groups.append({"type": E.TANK, "count": maxi(5, int(round(6.0 * scale))), "interval": 1.10 * pace, "delay": 0.0, "lane": 0})
				groups.append({"type": E.TANK, "count": maxi(5, int(round(6.0 * scale))), "interval": 1.10 * pace, "delay": 0.5, "lane": 1})
				groups.append({"type": E.JEEP, "count": int(round(14.0 * scale)), "interval": 0.34 * pace, "delay": 2.5, "lane": -1})
			elif pattern == 2:
				# Heavy air wing + UAV carriers
				groups.append({"type": E.CHOPPER, "count": int(round(8.0 * scale)), "interval": 0.80 * pace, "delay": 0.0, "lane": 0})
				groups.append({"type": E.BOMBER, "count": maxi(3, int(round(4.5 * scale))), "interval": 1.55 * pace, "delay": 1.2, "lane": 0})
				groups.append({"type": E.UAV_CARRIER, "count": maxi(2, int(round(2.2 * scale))), "interval": 2.8 * pace, "delay": 1.4, "lane": -1})
				if w_num >= 12:
					groups.append({"type": E.SKY_FORTRESS, "count": maxi(1, int(round(1.0 * intensity))), "interval": 4.2 * pace, "delay": 2.0, "lane": 0})
			elif pattern == 3:
				# APS Armor + Bomber division
				groups.append({"type": E.APS_TANK, "count": maxi(3, int(round(4.0 * scale))), "interval": 1.65 * pace, "delay": 0.0, "lane": -1})
				groups.append({"type": E.TANK, "count": int(round(8.0 * scale)), "interval": 0.90 * pace, "delay": 0.8, "lane": -1})
				groups.append({"type": E.BOMBER, "count": maxi(4, int(round(5.0 * scale))), "interval": 1.40 * pace, "delay": 1.6, "lane": 0})
				if w_num >= 12:
					groups.append({"type": E.JUGGERNAUT, "count": maxi(2, int(round(1.8 * scale))), "interval": 3.0 * pace, "delay": 0.6, "lane": -1})
			elif pattern == 4:
				# Juggernaut siege wave!
				var jugs: int = 1 if w_num < 11 else (2 if w_num < 15 else int(round(3.0 * intensity + float(w_num - 15) * 0.45)))
				groups.append({"type": E.JUGGERNAUT, "count": jugs, "interval": 2.8 * pace, "delay": 0.0, "lane": -1})
				groups.append({"type": E.APS_TANK, "count": maxi(2, int(round(3.0 * scale))), "interval": 1.6 * pace, "delay": 0.8, "lane": -1})
				groups.append({"type": E.TANK, "count": int(round(7.0 * scale)), "interval": 0.95 * pace, "delay": 1.2, "lane": -1})
				groups.append({"type": E.CHOPPER, "count": int(round(8.0 * scale)), "interval": 0.72 * pace, "delay": 2.4, "lane": 0})
			else:
				# High-speed blitz + heavy bombers + air boss
				groups.append({"type": E.JEEP, "count": int(round(18.0 * scale)), "interval": 0.25 * pace, "delay": 0.0, "lane": -1})
				groups.append({"type": E.BOMBER, "count": maxi(5, int(round(6.0 * scale))), "interval": 1.25 * pace, "delay": 1.0, "lane": 0})
				groups.append({"type": E.UAV_CARRIER, "count": maxi(2, int(round(2.5 * scale))), "interval": 2.5 * pace, "delay": 1.8, "lane": -1})
				if w_num >= 14:
					groups.append({"type": E.SKY_FORTRESS, "count": maxi(1, int(round(1.5 * intensity))), "interval": 4.0 * pace, "delay": 0.8, "lane": 0})

		out.append({
			"title": title,
			"bonus": bonus,
			"groups": groups,
		})
	return out
