class_name TurretData
extends RefCounted

enum TurretType {
	VULCAN,
	CANNON,
	MISSILE,
	CRYO,
	LASER,
	MLRS,
	DRONE,
}

enum TargetMode {
	FIRST,
	STRONGEST,
	WEAKEST,
	NEAREST,
}

const TARGET_MODE_NAMES: Dictionary = {
	TargetMode.FIRST: "FIRST",
	TargetMode.STRONGEST: "STRONG",
	TargetMode.WEAKEST: "WEAK",
	TargetMode.NEAREST: "NEAR",
}

const SELL_REFUND_RATIO: float = 0.72

static func get_config(type: TurretType) -> Dictionary:
	match type:
		TurretType.VULCAN:
			return {
				"id": "vulcan",
				"name": "VULCAN MG",
				"short": "VULCAN",
				"hotkey": "1",
				"role": "GND + AIR",
				"desc": "High-ROF rotary cannon. Shreds light vehicles and low-flying choppers.",
				"can_hit_ground": true,
				"can_hit_air": true,
				"accent": Color(0.95, 0.72, 0.25),
				"base_cost": 70,
				"levels": [
					{"cost": 70, "damage": 11.0, "range": 175.0, "fire_rate": 6.2, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 900.0, "armor_pierce": 0.15},
					{"cost": 95, "damage": 17.0, "range": 195.0, "fire_rate": 7.6, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 960.0, "armor_pierce": 0.25},
					{"cost": 150, "damage": 26.0, "range": 215.0, "fire_rate": 9.2, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 1020.0, "armor_pierce": 0.35},
					{"cost": 230, "damage": 40.0, "range": 240.0, "fire_rate": 11.5, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 1100.0, "armor_pierce": 0.5},
				],
			}
		TurretType.CANNON:
			return {
				"id": "cannon",
				"name": "HOWITZER",
				"short": "CANNON",
				"hotkey": "3",
				"role": "GND • AOE",
				"desc": "Heavy armor-piercing artillery shells with explosive blast radius.",
				"can_hit_ground": true,
				"can_hit_air": false,
				"accent": Color(0.92, 0.42, 0.22),
				"base_cost": 120,
				"levels": [
					{"cost": 120, "damage": 58.0, "range": 215.0, "fire_rate": 0.68, "splash": 62.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 560.0, "armor_pierce": 0.65},
					{"cost": 145, "damage": 94.0, "range": 235.0, "fire_rate": 0.78, "splash": 74.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 600.0, "armor_pierce": 0.75},
					{"cost": 215, "damage": 150.0, "range": 260.0, "fire_rate": 0.90, "splash": 88.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 650.0, "armor_pierce": 0.85},
					{"cost": 310, "damage": 235.0, "range": 290.0, "fire_rate": 1.05, "splash": 104.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 700.0, "armor_pierce": 1.0},
				],
			}
		TurretType.MISSILE:
			return {
				"id": "missile",
				"name": "SAM BATTERY",
				"short": "MISSILE",
				"hotkey": "4",
				"role": "AA + HEAVY",
				"desc": "Long-range homing rockets. Massive bonus vs. aircraft & heavy tanks.",
				"can_hit_ground": true,
				"can_hit_air": true,
				"air_bonus": 1.65,
				"accent": Color(0.36, 0.84, 0.56),
				"base_cost": 140,
				"levels": [
					{"cost": 140, "damage": 64.0, "range": 285.0, "fire_rate": 0.62, "splash": 38.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 420.0, "armor_pierce": 0.85},
					{"cost": 165, "damage": 104.0, "range": 315.0, "fire_rate": 0.74, "splash": 46.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 460.0, "armor_pierce": 0.9},
					{"cost": 235, "damage": 165.0, "range": 350.0, "fire_rate": 0.90, "splash": 56.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 510.0, "armor_pierce": 0.95},
					{"cost": 330, "damage": 255.0, "range": 390.0, "fire_rate": 1.08, "splash": 68.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 560.0, "armor_pierce": 1.0},
				],
			}
		TurretType.CRYO:
			return {
				"id": "cryo",
				"name": "CRYO EMITTER",
				"short": "CRYO",
				"hotkey": "2",
				"role": "SLOW • AOE",
				"desc": "Liquid-nitrogen projector. Chills enemy columns to multiply kill-zone time.",
				"can_hit_ground": true,
				"can_hit_air": true,
				"accent": Color(0.34, 0.78, 0.96),
				"base_cost": 100,
				"levels": [
					{"cost": 100, "damage": 9.0, "range": 160.0, "fire_rate": 1.35, "splash": 68.0, "slow": 0.34, "slow_dur": 2.4, "proj_speed": 440.0, "armor_pierce": 1.0},
					{"cost": 125, "damage": 15.0, "range": 180.0, "fire_rate": 1.55, "splash": 78.0, "slow": 0.44, "slow_dur": 2.8, "proj_speed": 470.0, "armor_pierce": 1.0},
					{"cost": 180, "damage": 24.0, "range": 200.0, "fire_rate": 1.75, "splash": 90.0, "slow": 0.54, "slow_dur": 3.2, "proj_speed": 500.0, "armor_pierce": 1.0},
					{"cost": 260, "damage": 38.0, "range": 225.0, "fire_rate": 2.0, "splash": 105.0, "slow": 0.64, "slow_dur": 3.8, "proj_speed": 540.0, "armor_pierce": 1.0},
				],
			}
		TurretType.LASER:
			return {
				"id": "laser",
				"name": "DRAGONFIRE HEL",
				"short": "LASER",
				"hotkey": "6",
				"role": "BEAM • APS",
				"desc": "Directed-energy laser. Continuous beam ramps up damage over time, ignores armor, and deals 2x vs APS shields.",
				"can_hit_ground": true,
				"can_hit_air": true,
				"shield_bonus": 2.0,
				"accent": Color(0.98, 0.28, 0.58),
				"base_cost": 160,
				"levels": [
					{"cost": 160, "damage": 50.0, "range": 235.0, "fire_rate": 1.0, "max_ramp": 2.2, "ramp_time": 3.0, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 0.0, "armor_pierce": 1.0},
					{"cost": 195, "damage": 82.0, "range": 260.0, "fire_rate": 1.0, "max_ramp": 2.35, "ramp_time": 2.8, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 0.0, "armor_pierce": 1.0},
					{"cost": 270, "damage": 132.0, "range": 285.0, "fire_rate": 1.0, "max_ramp": 2.5, "ramp_time": 2.6, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 0.0, "armor_pierce": 1.0},
					{"cost": 375, "damage": 210.0, "range": 315.0, "fire_rate": 1.0, "max_ramp": 2.75, "ramp_time": 2.4, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 0.0, "armor_pierce": 1.0},
				],
			}
		TurretType.MLRS:
			return {
				"id": "mlrs",
				"name": "HIMARS MLRS",
				"short": "MLRS",
				"hotkey": "7",
				"role": "SALVO • FIRE",
				"desc": "Long-range precision rocket salvo. Saturates ground convoys and leaves burning thermobaric pools on the road.",
				"can_hit_ground": true,
				"can_hit_air": false,
				"accent": Color(0.98, 0.56, 0.16),
				"base_cost": 185,
				"levels": [
					{"cost": 185, "damage": 34.0, "range": 345.0, "fire_rate": 0.22, "salvo_count": 3, "splash": 54.0, "burn_dps": 14.0, "burn_dur": 3.4, "burn_radius": 44.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 520.0, "armor_pierce": 0.55},
					{"cost": 225, "damage": 52.0, "range": 375.0, "fire_rate": 0.24, "salvo_count": 4, "splash": 60.0, "burn_dps": 22.0, "burn_dur": 3.8, "burn_radius": 50.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 550.0, "armor_pierce": 0.65},
					{"cost": 300, "damage": 78.0, "range": 410.0, "fire_rate": 0.26, "salvo_count": 5, "splash": 66.0, "burn_dps": 34.0, "burn_dur": 4.2, "burn_radius": 56.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 580.0, "armor_pierce": 0.75},
					{"cost": 410, "damage": 112.0, "range": 445.0, "fire_rate": 0.28, "salvo_count": 6, "splash": 74.0, "burn_dps": 50.0, "burn_dur": 4.6, "burn_radius": 62.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 620.0, "armor_pierce": 0.85},
				],
			}
		TurretType.DRONE:
			return {
				"id": "drone",
				"name": "HUNTER DRONE PAD",
				"short": "DRONE",
				"hotkey": "5",
				"role": "MAP HUNT",
				"desc": "Launches 1 orbiting hunter-killer UAV at a time. Pursues its locked target map-wide until destroyed, then rearms.",
				"can_hit_ground": true,
				"can_hit_air": true,
				"accent": Color(0.56, 0.90, 0.30),
				"base_cost": 150,
				"levels": [
					{"cost": 150, "damage": 16.0, "range": 240.0, "fire_rate": 4.2, "drone_speed": 235.0, "rearm_time": 4.2, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 0.0, "armor_pierce": 0.65},
					{"cost": 185, "damage": 25.0, "range": 275.0, "fire_rate": 4.8, "drone_speed": 265.0, "rearm_time": 3.6, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 0.0, "armor_pierce": 0.75},
					{"cost": 255, "damage": 38.0, "range": 310.0, "fire_rate": 5.5, "drone_speed": 300.0, "rearm_time": 3.0, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 0.0, "armor_pierce": 0.85},
					{"cost": 350, "damage": 58.0, "range": 350.0, "fire_rate": 6.4, "drone_speed": 340.0, "rearm_time": 2.4, "splash": 0.0, "slow": 0.0, "slow_dur": 0.0, "proj_speed": 0.0, "armor_pierce": 0.95},
				],
			}
	return {}

static func get_all_types() -> Array[TurretType]:
	return [
		TurretType.VULCAN,
		TurretType.CRYO,
		TurretType.CANNON,
		TurretType.MISSILE,
		TurretType.DRONE,
		TurretType.LASER,
		TurretType.MLRS,
	]
