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

# Progress-normalized per-wave HP multiplier (single source of truth for gameplay + audit).
# Gentle through early waves (p <= 0.25) so Waves 1-6 stay fair, then ramps quadratically
# on mid/late waves (higher on 20-30 wave sectors where player economy reaches Lv3-Lv4).
static func get_wave_hp_scale(wave_index: int, total_waves: int) -> float:
	var denom: float = float(maxi(1, total_waves - 1))
	var p: float = clampf(float(maxi(0, wave_index)) / denom, 0.0, 1.0)
	var len_t: float = clampf(float(total_waves - 15) / 15.0, 0.0, 1.0)
	var lin_term: float = lerpf(0.86, 0.98, len_t)
	var quad_term: float = lerpf(0.34, 1.02, len_t)
	return 1.0 + p * lin_term + p * p * quad_term

# Gentle late-wave kill bounty taper so 19-30 wave sectors stay tense without mid-game cash floods
# while keeping early/mid waves (p <= 0.28) at full 100% reward and preserving end-game surplus $.
static func get_wave_reward_scale(wave_index: int, total_waves: int) -> float:
	if total_waves <= 16:
		return 1.0
	var denom: float = float(maxi(1, total_waves - 1))
	var p: float = clampf(float(maxi(0, wave_index)) / denom, 0.0, 1.0)
	if p <= 0.28:
		return 1.0
	var t: float = (p - 0.28) / 0.72
	var len_factor: float = clampf(float(total_waves - 16) / 14.0, 0.0, 1.0)
	var max_taper: float = lerpf(0.22, 0.72, len_factor)
	return clampf(1.0 - max_taper * pow(t, 0.95), 0.26, 1.0)

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
				{"type": E.JEEP, "count": 6, "interval": 0.85, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 4, "interval": 1.40, "delay": 2.4, "lane": 1},
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
				{"type": E.TANK, "count": 4, "interval": 1.55, "delay": 0.0, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.6, "delay": 1.8, "lane": -1},
				{"type": E.CHOPPER, "count": 5, "interval": 1.30, "delay": 2.6, "lane": 0},
				{"type": E.BOMBER, "count": 1, "interval": 2.40, "delay": 4.8, "lane": 0},
			],
		},
		{
			"title": "SUNSCORCH AIR WING",
			"bonus": 85,
			"groups": [
				{"type": E.CHOPPER, "count": 7, "interval": 1.00, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 3, "interval": 2.05, "delay": 2.2, "lane": 0},
				{"type": E.APC, "count": 8, "interval": 0.80, "delay": 2.8, "lane": -1},
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
				{"type": E.APC, "count": 3, "interval": 1.45, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 7, "interval": 0.80, "delay": 1.8, "lane": 1},
			],
		},
		{
			"title": "GLACIAL CONVOY",
			"bonus": 50,
			"groups": [
				{"type": E.APC, "count": 8, "interval": 1.10, "delay": 0.0, "lane": -1},
				{"type": E.JEEP, "count": 7, "interval": 0.62, "delay": 4.0, "lane": -1},
			],
		},
		{
			"title": "FROSTBITE ARMOR",
			"bonus": 60,
			"groups": [
				{"type": E.TANK, "count": 4, "interval": 1.75, "delay": 0.0, "lane": 0},
				{"type": E.APC, "count": 6, "interval": 1.05, "delay": 1.8, "lane": 1},
			],
		},
		{
			"title": "ARCTIC GUNSHIPS",
			"bonus": 65,
			"groups": [
				{"type": E.CHOPPER, "count": 4, "interval": 1.45, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 2, "interval": 1.90, "delay": 2.4, "lane": 1},
				{"type": E.JEEP, "count": 7, "interval": 0.68, "delay": 3.4, "lane": 0},
			],
		},
		{
			"title": "NORTH-SOUTH PINCER",
			"bonus": 75,
			"groups": [
				{"type": E.TANK, "count": 4, "interval": 1.55, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 4, "interval": 1.55, "delay": 1.2, "lane": 1},
				{"type": E.JEEP, "count": 10, "interval": 0.48, "delay": 4.2, "lane": -1},
			],
		},
		{
			"title": "BLIZZARD SORTIE",
			"bonus": 85,
			"groups": [
				{"type": E.CHOPPER, "count": 5, "interval": 1.25, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 2, "interval": 2.4, "delay": 2.4, "lane": 0},
				{"type": E.APC, "count": 8, "interval": 0.85, "delay": 3.2, "lane": -1},
			],
		},
		{
			"title": "ICEBREAKER COLUMN",
			"bonus": 95,
			"groups": [
				{"type": E.APS_TANK, "count": 3, "interval": 2.25, "delay": 0.0, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.6, "delay": 2.8, "lane": -1},
				{"type": E.TANK, "count": 4, "interval": 1.45, "delay": 2.4, "lane": -1},
				{"type": E.BOMBER, "count": 2, "interval": 2.40, "delay": 4.4, "lane": 0},
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
			"bonus": 140,
			"groups": [
				{"type": E.CHOPPER, "count": 9, "interval": 0.85, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 5, "interval": 1.55, "delay": 1.8, "lane": 0},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.2, "delay": 2.6, "lane": -1},
				{"type": E.TANK, "count": 7, "interval": 1.15, "delay": 3.2, "lane": -1},
			],
		},
		{
			"title": "AVALANCHE DIVISION",
			"bonus": 155,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 2, "interval": 4.2, "delay": 0.0, "lane": -1},
				{"type": E.APS_TANK, "count": 4, "interval": 1.75, "delay": 1.2, "lane": -1},
				{"type": E.TANK, "count": 9, "interval": 1.05, "delay": 2.0, "lane": -1},
				{"type": E.APC, "count": 9, "interval": 0.70, "delay": 4.2, "lane": -1},
			],
		},
		{
			"title": "GLACIER STORM",
			"bonus": 175,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 2, "interval": 4.2, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 1, "interval": 5.0, "delay": 2.2, "lane": 0},
				{"type": E.APS_TANK, "count": 4, "interval": 1.85, "delay": 2.4, "lane": -1},
				{"type": E.BOMBER, "count": 5, "interval": 1.65, "delay": 3.4, "lane": 0},
				{"type": E.CHOPPER, "count": 7, "interval": 0.90, "delay": 4.8, "lane": 0},
			],
		},
		{
			"title": "IRON FROSTLINE",
			"bonus": 195,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.8, "delay": 0.0, "lane": -1},
				{"type": E.APS_TANK, "count": 4, "interval": 1.65, "delay": 1.4, "lane": -1},
				{"type": E.TANK, "count": 10, "interval": 0.95, "delay": 2.0, "lane": -1},
				{"type": E.BOMBER, "count": 6, "interval": 1.45, "delay": 3.8, "lane": 0},
			],
		},
		{
			"title": "NORTHERN OVERRUN",
			"bonus": 220,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.6, "delay": 0.0, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 3, "interval": 3.0, "delay": 1.6, "lane": -1},
				{"type": E.BOMBER, "count": 6, "interval": 1.35, "delay": 2.0, "lane": 0},
				{"type": E.CHOPPER, "count": 9, "interval": 0.72, "delay": 3.6, "lane": 0},
				{"type": E.TANK, "count": 9, "interval": 0.92, "delay": 2.4, "lane": -1},
			],
		},
		{
			"title": "OPERATION PERMAFROST",
			"bonus": 300,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.6, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 5.4, "delay": 2.0, "lane": 0},
				{"type": E.APS_TANK, "count": 5, "interval": 1.55, "delay": 1.4, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 3, "interval": 2.8, "delay": 2.6, "lane": -1},
				{"type": E.TANK, "count": 10, "interval": 0.92, "delay": 2.2, "lane": -1},
				{"type": E.BOMBER, "count": 6, "interval": 1.35, "delay": 3.6, "lane": 0},
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
				{"type": E.CHOPPER, "count": 5, "interval": 1.35, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 3, "interval": 1.70, "delay": 2.0, "lane": 1},
				{"type": E.JEEP, "count": 8, "interval": 0.58, "delay": 3.0, "lane": 0},
			],
		},
		{
			"title": "TWIN CANYON PUSH",
			"bonus": 80,
			"groups": [
				{"type": E.TANK, "count": 5, "interval": 1.40, "delay": 0.0, "lane": 0},
				{"type": E.TANK, "count": 5, "interval": 1.40, "delay": 0.8, "lane": 1},
				{"type": E.JEEP, "count": 12, "interval": 0.42, "delay": 3.4, "lane": -1},
			],
		},
		{
			"title": "HIGH ALTITUDE RAID",
			"bonus": 90,
			"groups": [
				{"type": E.CHOPPER, "count": 6, "interval": 1.10, "delay": 0.0, "lane": 0},
				{"type": E.BOMBER, "count": 2, "interval": 2.25, "delay": 2.0, "lane": 0},
				{"type": E.APC, "count": 9, "interval": 0.78, "delay": 2.8, "lane": -1},
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
			"bonus": 195,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.4, "delay": 0.0, "lane": -1},
				{"type": E.APS_TANK, "count": 4, "interval": 1.65, "delay": 1.2, "lane": -1},
				{"type": E.TANK, "count": 11, "interval": 0.90, "delay": 1.8, "lane": -1},
				{"type": E.BOMBER, "count": 6, "interval": 1.35, "delay": 3.2, "lane": 0},
			],
		},
		{
			"title": "CITADEL ASSAULT",
			"bonus": 220,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.2, "delay": 0.0, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 3, "interval": 2.8, "delay": 1.4, "lane": -1},
				{"type": E.BOMBER, "count": 7, "interval": 1.25, "delay": 1.8, "lane": 0},
				{"type": E.CHOPPER, "count": 10, "interval": 0.68, "delay": 3.2, "lane": 0},
				{"type": E.TANK, "count": 10, "interval": 0.86, "delay": 2.2, "lane": -1},
			],
		},
		{
			"title": "IRON PEAKS",
			"bonus": 250,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 4, "interval": 3.1, "delay": 0.0, "lane": -1},
				{"type": E.APS_TANK, "count": 5, "interval": 1.50, "delay": 1.2, "lane": -1},
				{"type": E.TANK, "count": 11, "interval": 0.85, "delay": 1.8, "lane": -1},
				{"type": E.BOMBER, "count": 7, "interval": 1.25, "delay": 2.6, "lane": 0},
			],
		},
		{
			"title": "OPERATION AVALANCHE",
			"bonus": 320,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 4, "interval": 3.1, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 4.8, "delay": 1.8, "lane": 0},
				{"type": E.APS_TANK, "count": 6, "interval": 1.40, "delay": 1.2, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 4, "interval": 2.6, "delay": 2.4, "lane": -1},
				{"type": E.TANK, "count": 12, "interval": 0.82, "delay": 1.8, "lane": -1},
				{"type": E.BOMBER, "count": 8, "interval": 1.20, "delay": 3.2, "lane": 0},
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
				{"type": E.APC, "count": 5, "interval": 1.25, "delay": 0.0, "lane": 0},
				{"type": E.JEEP, "count": 8, "interval": 0.72, "delay": 1.8, "lane": 1},
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
				{"type": E.TANK, "count": 3, "interval": 1.50, "delay": 0.0, "lane": 0},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.4, "delay": 1.4, "lane": 1},
				{"type": E.TANK, "count": 3, "interval": 1.50, "delay": 1.0, "lane": 1},
				{"type": E.CHOPPER, "count": 4, "interval": 1.20, "delay": 3.2, "lane": 0},
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
				{"type": E.BOMBER, "count": 5, "interval": 1.55, "delay": 1.4, "lane": 0},
				{"type": E.UAV_CARRIER, "count": 2, "interval": 3.0, "delay": 2.2, "lane": -1},
				{"type": E.CHOPPER, "count": 8, "interval": 0.80, "delay": 1.8, "lane": 0},
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
				{"type": E.JUGGERNAUT, "count": 2, "interval": 3.4, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 4.8, "delay": 1.8, "lane": 0},
				{"type": E.BOMBER, "count": 5, "interval": 1.30, "delay": 2.4, "lane": 0},
				{"type": E.CHOPPER, "count": 8, "interval": 0.72, "delay": 3.2, "lane": 0},
				{"type": E.JEEP, "count": 14, "interval": 0.30, "delay": 4.2, "lane": -1},
			],
		},
		{
			"title": "DAY 12 — OPERATION TINSEL STORM!",
			"bonus": 500,
			"groups": [
				{"type": E.JUGGERNAUT, "count": 3, "interval": 3.4, "delay": 0.0, "lane": -1},
				{"type": E.SKY_FORTRESS, "count": 2, "interval": 4.8, "delay": 2.0, "lane": 0},
				{"type": E.APS_TANK, "count": 5, "interval": 1.6, "delay": 1.4, "lane": -1},
				{"type": E.UAV_CARRIER, "count": 3, "interval": 3.0, "delay": 2.6, "lane": -1},
				{"type": E.TANK, "count": 8, "interval": 0.96, "delay": 1.8, "lane": -1},
				{"type": E.BOMBER, "count": 5, "interval": 1.45, "delay": 3.0, "lane": 0},
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
	return _build_campaign_waves(19, 0.00, 2, "balanced", titles)

static func get_cotswold_vale_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"COUNTRY LANE SCOUTS", "ORCHARD PROBE", "HEDGEROW COLUMN", "MEADOW ARMOR",
		"VALE GUNSHIPS", "STONE BRIDGE PUSH", "PASTURE AIR WING", "WHEATFIELD PHALANX",
		"MANOR BREAKER", "BARNSTORMER RAID", "SPLIT LANE TITANS", "SHIRES SORTIE",
		"DRY-STONE SIEGE", "COUNTRYSIDE STORM", "GREEN BELT HAMMER", "ESTATE ASSAULT",
		"ROLLING THUNDER", "VALLEY OVERRUN", "ROYAL GUARD PUSH", "OPERATION HARVEST"
	]
	return _build_campaign_waves(20, 0.09, 2, "armor", titles)

static func get_whisperwood_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"TRAILHEAD SCOUTS", "LOGGING ROAD PUSH", "DEEP WOODS CONVOY", "TIMBERLINE ARMOR",
		"CANOPY GUNSHIPS", "CREEK BRIDGE PINCER", "TREETOP STRIKE", "MOSSWOOD PHALANX",
		"FOREST BREAKER", "GLADE STAMPEDE", "TWIN TIMBER TITANS", "EMERALD SORTIE",
		"ANCIENT GROVE SIEGE", "WOODLAND THUNDER", "PINE RIDGE HAMMER", "DEEPWOOD ASSAULT",
		"SHADOWED TRAILS", "TIMBER OVERRUN", "WILDWOOD VANGUARD", "IRON CANOPY", "OPERATION FALLEN OAK"
	]
	return _build_campaign_waves(21, 0.18, 2, "blitz", titles)

static func get_red_centre_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"RED DUST SCOUTS", "STUART TRACK PROBE", "OUTBACK CARAVAN", "IRON-RED ARMOR",
		"HEATWAVE GUNSHIPS", "BILLABONG PINCER", "SCORCHED AIR WING", "MESA PHALANX",
		"ULURU BREAKER", "ROAD TRAIN RAMPAGE", "TWIN RED TITANS", "SOUTHERN CROSS SORTIE",
		"SPINIFEX SIEGE", "OUTBACK THUNDER", "RED ROCK HAMMER", "STATION ASSAULT",
		"DUST DEVIL DIVISION", "BUSHFIRE OVERRUN", "CRIMSON VANGUARD", "SUNSTROKE ARMADA",
		"IRON OUTBACK", "OPERATION RED STORM"
	]
	return _build_campaign_waves(22, 0.27, 3, "swarm", titles)

static func get_coral_atoll_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"BEACHHEAD SCOUTS", "SURF LINE PROBE", "PALM CAUSEWAY PUSH", "CORAL ARMOR",
		"TROPICAL GUNSHIPS", "LAGOON PINCER", "MONSOON AIR WING", "ATOLL PHALANX",
		"REEF BREAKER", "TIDAL STAMPEDE", "TWIN SANDBAR TITANS", "PACIFIC SORTIE",
		"ISLAND SIEGE", "TYPHOON THUNDER", "TURQUOISE HAMMER", "SEAWALL ASSAULT",
		"TROPIC DIVISION", "CYCLONE OVERRUN", "CORAL VANGUARD", "TRADEWIND ARMADA",
		"IRON LAGOON", "PACIFIC TEMPEST", "OPERATION TIDAL WAVE"
	]
	return _build_campaign_waves(23, 0.36, 2, "air", titles)

static func get_obsidian_caldera_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"ASHFALL SCOUTS", "CINDER RIDGE PROBE", "BASALT CONVOY", "MAGMA ARMOR",
		"THERMAL GUNSHIPS", "LAVA BRIDGE PINCER", "SCORCHED AIR WING", "CALDERA PHALANX",
		"OBSIDIAN BREAKER", "PYROCLASTIC RUSH", "TWIN MOLTEN TITANS", "VOLCANO SORTIE",
		"CRATER RIM SIEGE", "BRIMSTONE THUNDER", "SLAG HAMMER", "FORGE ASSAULT",
		"INFERNO DIVISION", "ERUPTION OVERRUN", "MAGMA VANGUARD", "ASHSTORM ARMADA",
		"IRON CALDERA", "MOLTEN FURY", "DOOMSDAY VENT", "OPERATION HELLFIRE"
	]
	return _build_campaign_waves(24, 0.45, 2, "armor", titles)

static func get_bayou_delta_waves() -> Array[Dictionary]:
	var titles: Array[String] = [
		"MARSHLAND SCOUTS", "FOGGY TRAIL PROBE", "CAUSEWAY COLUMN", "PEAT BOG ARMOR",
		"SWAMP GUNSHIPS", "BAYOU BRIDGE PINCER", "NIGHTMIST AIR WING", "CYPRESS PHALANX",
		"DELTA BREAKER", "ALLIGATOR RUSH", "TWIN MIRE TITANS", "TWILIGHT SORTIE",
		"SINKHOLE SIEGE", "BAYOU THUNDER", "QUAGMIRE HAMMER", "BOARDWALK ASSAULT",
		"WETLAND DIVISION", "BLACKWATER OVERRUN", "MARSH VANGUARD", "FIREFLY ARMADA",
		"IRON BAYOU", "MISTY TEMPEST", "DEEP SWAMP FURY", "DELTA STORM", "OPERATION HIGH WATER"
	]
	return _build_campaign_waves(25, 0.54, 2, "drone", titles)

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
	return _build_campaign_waves(26, 0.63, 3, "drone", titles)

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
	return _build_campaign_waves(27, 0.72, 2, "armor", titles)

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
	return _build_campaign_waves(28, 0.81, 2, "blitz", titles)

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
	return _build_campaign_waves(29, 0.90, 2, "air", titles)

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
	return _build_campaign_waves(30, 1.00, 3, "omega", titles)

static func _build_campaign_waves(
	count: int,
	tier: float,
	num_lanes: int,
	flavor: String,
	titles: Array[String]
) -> Array[Dictionary]:
	var E := EnemyData.EnemyType
	var out: Array[Dictionary] = []

	# Subtle per-sector flavor modifiers (keep bounded so every sector stays balanced)
	var air_bias: float = 1.12 if flavor == "air" else (1.06 if flavor == "omega" else 1.0)
	var armor_bias: float = 1.14 if flavor == "armor" else (1.08 if flavor == "omega" else 1.0)
	var drone_bias: float = 1.18 if (flavor == "drone" or flavor == "swarm") else 1.0
	var blitz_bias: float = 1.15 if (flavor == "blitz" or flavor == "swarm") else 1.0

	# Mild pacing tighten across campaign without crushing early-game reaction time
	var pace: float = lerpf(0.98, 0.84, tier)

	for i in range(count):
		var w_num: int = i + 1
		var p: float = float(i) / float(maxi(1, count - 1))
		var title: String = titles[i] if i < titles.size() else ("HOSTILE WAVE %d" % w_num)
		var groups: Array[Dictionary] = []

		# Economy-aligned wave clear bonus (no compounding intensity blowup)
		var bonus: int = int(round(lerpf(36.0, 145.0, p) * lerpf(0.95, 1.05, tier)))

		# Smooth progression multiplier: stays modest on W1-W8, then ramps cleanly with player Lv3-Lv4 economy
		var mid_ramp: float = pow(clampf((p - 0.22) / 0.78, 0.0, 1.0), 1.25)
		var prog: float = (0.76 + 0.22 * minf(1.0, p / 0.25) + mid_ramp * lerpf(0.95, 1.48, tier)) * lerpf(0.92, 1.12, tier)

		if w_num == 1:
			# Opening scouts across all lanes
			var jeeps: int = int(round(lerpf(10.0, 14.0, tier) * blitz_bias))
			groups.append({"type": E.JEEP, "count": maxi(num_lanes * 3, jeeps), "interval": 0.84 * pace, "delay": 0.0, "lane": -1})
		elif w_num == 2:
			# Smooth multi-lane probe (all lanes active, fair on 3-lane maps)
			var apcs: int = maxi(num_lanes, int(round(lerpf(3.0, 3.8, tier))))
			var jeeps: int = maxi(num_lanes * 2, int(round(lerpf(6.5, 8.0, tier))))
			if num_lanes >= 3:
				groups.append({"type": E.APC, "count": apcs, "interval": 1.50 * pace, "delay": 0.0, "lane": -1})
				groups.append({"type": E.JEEP, "count": jeeps, "interval": 0.82 * pace, "delay": 2.4, "lane": -1})
			else:
				groups.append({"type": E.APC, "count": apcs, "interval": 1.35 * pace, "delay": 0.0, "lane": 0})
				groups.append({"type": E.JEEP, "count": jeeps, "interval": 0.74 * pace, "delay": 1.9, "lane": 1})
		elif w_num == 3:
			# Mechanized convoy across all lanes
			var apcs: int = int(round(lerpf(6.5, 7.8, tier)))
			var jeeps: int = int(round(lerpf(6.5, 8.5, tier) * blitz_bias))
			var w3_space: float = 1.18 if num_lanes >= 3 else 1.05
			groups.append({"type": E.APC, "count": apcs, "interval": w3_space * pace, "delay": 0.0, "lane": -1})
			groups.append({"type": E.JEEP, "count": jeeps, "interval": 0.62 * pace, "delay": 3.8, "lane": -1})
		elif w_num == 4:
			# First heavy armor test across all lanes
			var tanks: int = maxi(num_lanes, int(round(lerpf(3.0, 3.8, tier) * armor_bias)))
			var apcs: int = maxi(num_lanes * 2, int(round(lerpf(4.8, 6.0, tier))))
			if num_lanes >= 3:
				groups.append({"type": E.TANK, "count": tanks, "interval": 2.00 * pace, "delay": 0.0, "lane": -1})
				groups.append({"type": E.APC, "count": apcs, "interval": 1.18 * pace, "delay": 2.8, "lane": -1})
			else:
				groups.append({"type": E.TANK, "count": tanks, "interval": 1.70 * pace, "delay": 0.0, "lane": 0})
				groups.append({"type": E.APC, "count": apcs, "interval": 1.02 * pace, "delay": 2.0, "lane": 1})
		elif w_num == 5:
			# First gunship air incursion — staggered from ground push so short-air-path maps stay fair!
			var choppers: int = 3
			var tanks: int = 3 if num_lanes >= 3 else 2
			var jeeps: int = maxi(num_lanes * 2, int(round(lerpf(5.8, 7.2, tier))))
			groups.append({"type": E.CHOPPER, "count": choppers, "interval": 2.15 * pace, "delay": 0.0, "lane": 0})
			if num_lanes >= 3:
				groups.append({"type": E.TANK, "count": tanks, "interval": 2.20 * pace, "delay": 4.8, "lane": -1})
				groups.append({"type": E.JEEP, "count": jeeps, "interval": 0.78 * pace, "delay": 6.2, "lane": -1})
			else:
				groups.append({"type": E.TANK, "count": tanks, "interval": 2.10 * pace, "delay": 4.8, "lane": 1})
				groups.append({"type": E.JEEP, "count": jeeps, "interval": 0.74 * pace, "delay": 6.0, "lane": 0})
		elif w_num == count:
			# Epic multi-domain boss finale (crisp ~38-52 elite units, multi-stage staggered assault)
			bonus = int(round(lerpf(280.0, 380.0, tier)))
			var jugs: int = clampi(int(round(lerpf(3.0, 5.0, tier) * armor_bias)), 3, 5)
			var skies: int = clampi(int(round(lerpf(2.0, 3.2, tier) * air_bias)), 2, 3)
			var aps: int = clampi(int(round(lerpf(5.0, 8.5, tier) * armor_bias)), 5, 9)
			var carriers: int = clampi(int(round(lerpf(3.0, 5.0, tier) * drone_bias)), 3, 5)
			var tanks: int = clampi(int(round(lerpf(9.0, 12.5, tier))), 9, 13)
			var bombers: int = clampi(int(round(lerpf(6.0, 8.0, tier) * air_bias)), 6, 8)
			groups.append({"type": E.JUGGERNAUT, "count": jugs, "interval": 3.4 * pace, "delay": 0.0, "lane": -1})
			groups.append({"type": E.APS_TANK, "count": aps, "interval": 1.60 * pace, "delay": 2.0, "lane": -1})
			groups.append({"type": E.TANK, "count": tanks, "interval": 1.00 * pace, "delay": 3.4, "lane": -1})
			groups.append({"type": E.SKY_FORTRESS, "count": skies, "interval": 5.2 * pace, "delay": 4.5, "lane": 0})
			groups.append({"type": E.UAV_CARRIER, "count": carriers, "interval": 3.0 * pace, "delay": 5.4, "lane": -1})
			groups.append({"type": E.BOMBER, "count": bombers, "interval": 1.55 * pace, "delay": 6.4, "lane": 0})
		else:
			# 9 distinct rotating tactical archetypes with phase-gated boss escalation
			var arch: int = (w_num - 6) % 9
			match arch:
				0:
					# Multi-lane Armor Pincer + heavy late-game spearhead
					var total_tanks: int = clampi(int(round(7.2 * prog * armor_bias)), num_lanes * 2, 18)
					var jeeps: int = clampi(int(round(11.0 * prog * blitz_bias)), 8, 20)
					var t_int_mul: float = 1.38 if p < 0.30 else 1.12
					if num_lanes >= 3:
						groups.append({"type": E.TANK, "count": total_tanks, "interval": (t_int_mul - 0.16) * pace, "delay": 0.0, "lane": -1})
					else:
						var half_t: int = maxi(3, int(ceil(float(total_tanks) * 0.5)))
						groups.append({"type": E.TANK, "count": half_t, "interval": t_int_mul * pace, "delay": 0.0, "lane": 0})
						groups.append({"type": E.TANK, "count": half_t, "interval": t_int_mul * pace, "delay": 1.1, "lane": 1})
					groups.append({"type": E.JEEP, "count": jeeps, "interval": 0.44 * pace, "delay": 3.4, "lane": -1})
					if p >= 0.42:
						groups.append({"type": E.APS_TANK, "count": clampi(int(round(3.8 * prog * armor_bias)), 3, 9), "interval": 1.45 * pace, "delay": 1.4, "lane": -1})
					if p >= 0.55:
						var jugs0: int = 1 if p < 0.72 else (2 if p < 0.88 else 3)
						groups.append({"type": E.JUGGERNAUT, "count": jugs0, "interval": 3.4 * pace, "delay": 0.6, "lane": -1})
						groups.append({"type": E.BOMBER, "count": clampi(int(round(3.2 * prog * air_bias)), 3, 7), "interval": 1.50 * pace, "delay": 3.6, "lane": 0})
				1:
					# UAV Carrier Drone Warfare + Air Screen
					var choppers: int = clampi(int(round(4.4 * prog * air_bias)), 4, 12)
					var carriers: int = clampi(int(round(2.2 * prog * drone_bias)), 2, 6)
					var apcs: int = clampi(int(round(6.2 * prog)), 5, 14)
					var c_int: float = 1.52 if p < 0.32 else 1.15
					groups.append({"type": E.CHOPPER, "count": choppers, "interval": c_int * pace, "delay": 0.0, "lane": 0})
					groups.append({"type": E.UAV_CARRIER, "count": carriers, "interval": 3.4 * pace, "delay": 3.4 if p < 0.32 else 2.4, "lane": -1})
					groups.append({"type": E.APC, "count": apcs, "interval": 0.90 * pace, "delay": 4.0 if p < 0.32 else 3.2, "lane": -1})
					if p >= 0.36:
						groups.append({"type": E.BOMBER, "count": clampi(int(round(3.2 * prog * air_bias)), 3, 7), "interval": 1.55 * pace, "delay": 3.6, "lane": 0})
					if p >= 0.58:
						groups.append({"type": E.APS_TANK, "count": clampi(int(round(3.5 * prog)), 3, 8), "interval": 1.50 * pace, "delay": 1.8, "lane": -1})
					if p >= 0.74:
						groups.append({"type": E.SKY_FORTRESS, "count": 2 if p >= 0.88 else 1, "interval": 4.8 * pace, "delay": 3.2, "lane": 0})
				2:
					# APS Trophy Phalanx (rewards Dragonfire Laser & AP counter-play)
					var aps: int = clampi(int(round(3.8 * prog * armor_bias)), 3, 9)
					var tanks: int = clampi(int(round(6.5 * prog)), 5, 14)
					var apcs: int = clampi(int(round(7.0 * prog)), 5, 13)
					var aps_int: float = 1.80 if p < 0.35 else 1.58
					groups.append({"type": E.APS_TANK, "count": aps, "interval": aps_int * pace, "delay": 0.0, "lane": -1})
					groups.append({"type": E.TANK, "count": tanks, "interval": 1.12 * pace, "delay": 2.0 if p < 0.35 else 1.5, "lane": -1})
					groups.append({"type": E.APC, "count": apcs, "interval": 0.78 * pace, "delay": 3.4 if p < 0.35 else 2.8, "lane": -1})
					if p >= 0.48:
						groups.append({"type": E.BOMBER, "count": clampi(int(round(3.4 * prog * air_bias)), 3, 7), "interval": 1.55 * pace, "delay": 3.8, "lane": 0})
					if p >= 0.62:
						groups.append({"type": E.JUGGERNAUT, "count": 2 if p >= 0.80 else 1, "interval": 3.6 * pace, "delay": 1.0, "lane": -1})
				3:
					# High-Speed Blitz + Tactical Air Support (staggered air for short-air maps!)
					var jeeps: int = clampi(int(round(13.0 * prog * blitz_bias)), 10, 24)
					var apcs: int = clampi(int(round(7.0 * prog)), 5, 14)
					var choppers: int = clampi(int(round(4.6 * prog * air_bias)), 4, 11)
					var bombers: int = clampi(int(round(2.4 * prog * air_bias)), 2, 6)
					groups.append({"type": E.JEEP, "count": jeeps, "interval": 0.38 * pace, "delay": 0.0, "lane": -1})
					groups.append({"type": E.APC, "count": apcs, "interval": 0.78 * pace, "delay": 2.6, "lane": -1})
					groups.append({"type": E.CHOPPER, "count": choppers, "interval": 1.32 * pace, "delay": 4.8, "lane": 0})
					groups.append({"type": E.BOMBER, "count": bombers, "interval": 1.95 * pace, "delay": 6.8, "lane": 0})
					if p >= 0.56:
						groups.append({"type": E.TANK, "count": clampi(int(round(5.5 * prog)), 5, 11), "interval": 1.05 * pace, "delay": 3.8, "lane": -1})
				4:
					# Siege Breaker (Juggernaut flagship + Armored Escort)
					var jugs: int = 1 if p < 0.42 else (2 if p < 0.68 else (3 if p < 0.86 else 4))
					var tanks: int = clampi(int(round(6.5 * prog * armor_bias)), 5, 13)
					var choppers: int = clampi(int(round(5.5 * prog * air_bias)), 4, 11)
					groups.append({"type": E.JUGGERNAUT, "count": jugs, "interval": 3.4 * pace, "delay": 0.0, "lane": -1})
					groups.append({"type": E.TANK, "count": tanks, "interval": 1.05 * pace, "delay": 1.5, "lane": -1})
					groups.append({"type": E.CHOPPER, "count": choppers, "interval": 0.98 * pace, "delay": 3.6, "lane": 0})
					if p >= 0.44:
						groups.append({"type": E.APS_TANK, "count": clampi(int(round(3.6 * prog)), 3, 8), "interval": 1.55 * pace, "delay": 2.2, "lane": -1})
					if p >= 0.65:
						groups.append({"type": E.BOMBER, "count": clampi(int(round(3.2 * prog * air_bias)), 3, 7), "interval": 1.55 * pace, "delay": 4.4, "lane": 0})
				5:
					# Heavy Air Wing + Ground Pin (staggered bomber/tank arrival for short-air maps)
					var choppers: int = clampi(int(round(5.2 * prog * air_bias)), 4, 12)
					var bombers: int = clampi(int(round(3.2 * prog * air_bias)), 2, 8)
					var tanks: int = clampi(int(round(5.5 * prog)), 4, 12)
					groups.append({"type": E.CHOPPER, "count": choppers, "interval": 1.12 * pace, "delay": 0.0, "lane": 0})
					groups.append({"type": E.BOMBER, "count": bombers, "interval": 1.70 * pace, "delay": 2.8, "lane": 0})
					groups.append({"type": E.TANK, "count": tanks, "interval": 1.10 * pace, "delay": 3.4, "lane": -1})
					if p >= 0.50:
						var skies: int = 1 if p < 0.78 else 2
						groups.append({"type": E.SKY_FORTRESS, "count": skies, "interval": 4.8 * pace, "delay": 3.8, "lane": 0})
					if p >= 0.66:
						groups.append({"type": E.APS_TANK, "count": clampi(int(round(3.5 * prog)), 3, 7), "interval": 1.55 * pace, "delay": 2.0, "lane": -1})
				6:
					# Combined-Arms Drone & APS Push
					var carriers: int = clampi(int(round(3.0 * prog * drone_bias)), 2, 6)
					var aps: int = clampi(int(round(4.2 * prog * armor_bias)), 3, 9)
					var apcs: int = clampi(int(round(7.5 * prog)), 5, 13)
					var choppers: int = clampi(int(round(5.5 * prog * air_bias)), 4, 11)
					groups.append({"type": E.APS_TANK, "count": aps, "interval": 1.55 * pace, "delay": 0.0, "lane": -1})
					groups.append({"type": E.UAV_CARRIER, "count": carriers, "interval": 2.7 * pace, "delay": 1.6, "lane": -1})
					groups.append({"type": E.APC, "count": apcs, "interval": 0.74 * pace, "delay": 2.4, "lane": -1})
					groups.append({"type": E.CHOPPER, "count": choppers, "interval": 0.98 * pace, "delay": 3.6, "lane": 0})
					if p >= 0.64:
						groups.append({"type": E.JUGGERNAUT, "count": 2 if p >= 0.82 else 1, "interval": 3.5 * pace, "delay": 0.8, "lane": -1})
				7:
					# Armored Juggernaut Division
					var jugs: int = 1 if p < 0.45 else (2 if p < 0.68 else (3 if p < 0.86 else 4))
					var aps: int = clampi(int(round(4.2 * prog * armor_bias)), 3, 9)
					var tanks: int = clampi(int(round(7.2 * prog)), 5, 14)
					var bombers: int = clampi(int(round(3.5 * prog * air_bias)), 3, 8)
					groups.append({"type": E.JUGGERNAUT, "count": jugs, "interval": 3.6 * pace, "delay": 0.0, "lane": -1})
					groups.append({"type": E.APS_TANK, "count": aps, "interval": 1.65 * pace, "delay": 2.2, "lane": -1})
					groups.append({"type": E.TANK, "count": tanks, "interval": 1.06 * pace, "delay": 3.2, "lane": -1})
					groups.append({"type": E.BOMBER, "count": bombers, "interval": 1.62 * pace, "delay": 4.8, "lane": 0})
				_:
					# Sky Fortress Sortie (high-altitude air boss + drone/armor support)
					var skies: int = 1 if p < 0.70 else 2
					var bombers: int = clampi(int(round(4.4 * prog * air_bias)), 3, 8)
					var carriers: int = clampi(int(round(2.8 * prog * drone_bias)), 2, 5)
					var tanks: int = clampi(int(round(6.8 * prog)), 5, 13)
					groups.append({"type": E.SKY_FORTRESS, "count": skies, "interval": 4.6 * pace, "delay": 0.0, "lane": 0})
					groups.append({"type": E.BOMBER, "count": bombers, "interval": 1.45 * pace, "delay": 2.0, "lane": 0})
					groups.append({"type": E.UAV_CARRIER, "count": carriers, "interval": 2.8 * pace, "delay": 2.6, "lane": -1})
					groups.append({"type": E.TANK, "count": tanks, "interval": 1.00 * pace, "delay": 2.8, "lane": -1})
					if p >= 0.70:
						groups.append({"type": E.APS_TANK, "count": clampi(int(round(3.5 * prog)), 3, 7), "interval": 1.50 * pace, "delay": 1.8, "lane": -1})

		out.append({
			"title": title,
			"bonus": bonus,
			"groups": groups,
		})
	return out
