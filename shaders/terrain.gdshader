shader_type canvas_item;

uniform sampler2D map_mask : filter_linear, repeat_disable;
uniform vec2 map_size = vec2(1600.0, 960.0);
uniform vec2 bridge_pos = vec2(1038.0, 175.0);
uniform vec2 bridge_pos_2 = vec2(-9999.0, -9999.0);
uniform int biome_type = 0; // 0 = Alpine, 1 = Desert, 2 = Tundra, 3 = Mountain, 4 = Christmas North Pole

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(37.2, 17.9)));
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	for (int i = 0; i < 5; i++) {
		v += amp * noise(p);
		p = rot * p * 2.03 + vec2(19.3, 37.1);
		amp *= 0.5;
	}
	return v;
}

float ridged(vec2 p) {
	float v = 0.0;
	float amp = 0.55;
	mat2 rot = mat2(vec2(0.80, -0.60), vec2(0.60, 0.80));
	for (int i = 0; i < 4; i++) {
		float n = 1.0 - abs(noise(p) * 2.0 - 1.0);
		v += n * n * amp;
		p = rot * p * 2.12 + vec2(7.4, 13.9);
		amp *= 0.48;
	}
	return v;
}

float cobble_cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float min_d = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash2(i + g);
			vec2 r = g + o - f;
			float d = dot(r, r);
			min_d = min(min_d, d);
		}
	}
	return sqrt(min_d);
}

float caustics(vec2 p, float t) {
	vec2 p1 = p + vec2(sin(p.y * 1.4 + t * 1.3) * 0.35, -t * 0.75);
	vec2 p2 = p * 1.35 + vec2(cos(p.x * 1.2 - t * 1.1) * 0.3, -t * 1.05);
	float c1 = 1.0 - abs(noise(p1) * 2.0 - 1.0);
	float c2 = 1.0 - abs(noise(p2) * 2.0 - 1.0);
	return pow(clamp(c1 * c2 * 1.55, 0.0, 1.0), 2.4);
}

float water_wave_height(vec2 wp, float t) {
	vec2 flow1 = vec2(wp.x * 0.055, wp.y * 0.032 - t * 1.15);
	vec2 flow2 = vec2(wp.x * 0.11 + sin(wp.y * 0.035 - t) * 0.55, wp.y * 0.075 - t * 1.85);
	vec2 flow3 = vec2(wp.x * 0.24 - t * 0.35, wp.y * 0.19 - t * 2.6);
	float w1 = fbm(flow1) * 0.55;
	float w2 = noise(flow2) * 0.30;
	float w3 = noise(flow3) * 0.15;
	return w1 + w2 + w3;
}

float dune_ripples(vec2 wp) {
	float warp = fbm(wp * 0.012) * 4.5;
	float r1 = sin(wp.x * 0.17 + wp.y * 0.095 + warp);
	float r2 = sin(wp.x * 0.31 + wp.y * 0.16 - warp * 0.6) * 0.4;
	return (r1 + r2) * 0.018;
}

float snow_drifts(vec2 wp) {
	float warp = fbm(wp * 0.009) * 5.2;
	float s1 = sin(wp.x * 0.08 + wp.y * 0.13 + warp);
	float s2 = sin(wp.x * 0.19 + wp.y * 0.24 - warp * 0.5) * 0.35;
	return (s1 + s2) * 0.022;
}

float bridge_abutment_mask(vec2 wp, vec2 bpos) {
	return exp(-pow((wp.y - bpos.y) / 40.0, 2.0)) * smoothstep(52.0, 74.0, abs(wp.x - bpos.x));
}

bool is_over_bridge(vec2 wp, vec2 bpos) {
	return abs(wp.x - bpos.x) < 66.0 && abs(wp.y - bpos.y) < 38.0;
}

float bridge_shadow_mask(vec2 wp, vec2 bpos) {
	vec2 b_rel = wp - (bpos + vec2(12.0, 16.0));
	float bx = 1.0 - smoothstep(56.0, 74.0, abs(b_rel.x));
	float by = 1.0 - smoothstep(30.0, 48.0, abs(b_rel.y));
	return bx * by;
}

float bridge_pier_wake(vec2 wp, vec2 bpos, float t) {
	float dy_pier = wp.y - (bpos.y + 30.0);
	if (dy_pier <= 0.0 || dy_pier >= 95.0) {
		return 0.0;
	}
	float wake_fade = smoothstep(0.0, 12.0, dy_pier) * (1.0 - smoothstep(25.0, 95.0, dy_pier));
	float spread = 5.0 + dy_pier * 0.18;
	float p1 = exp(-pow((wp.x - (bpos.x - 19.0)) / spread, 2.0));
	float p2 = exp(-pow((wp.x - (bpos.x + 19.0)) / spread, 2.0));
	float turb = smoothstep(0.36, 0.72, fbm(vec2(wp.x * 0.16, wp.y * 0.12 - t * 3.4)));
	return clamp(p1 + p2, 0.0, 1.0) * wake_fade * turb;
}

float scene_height(vec2 wp, vec4 m) {
	float d_road = m.r * 128.0;
	float d_river = m.g * 140.0;
	float d_pad = m.b * 96.0;

	vec2 uv_n = wp * 0.0036;
	float macro = fbm(uv_n) * 0.62 + ridged(uv_n * 2.05 + vec2(4.1, 2.7)) * 0.38;
	float micro_bump = (fbm(wp * 0.048) - 0.5) * 0.11;
	float h = 0.42 + macro * 0.55 + micro_bump;

	if (biome_type == 1) {
		float mesa = floor(h * 6.5) / 6.5;
		h = mix(h, mesa, 0.22) + dune_ripples(wp);
	} else if (biome_type == 2 || biome_type == 4) {
		h += snow_drifts(wp);
	} else if (biome_type == 3) {
		// Towering jagged mountain peaks rising steeply out of deep carved convoy valleys!
		float peaks = ridged(wp * 0.0052 + vec2(3.2, 6.8)) * 0.72 + ridged(wp * 0.0115 + vec2(-2.1, 4.4)) * 0.28;
		float valley_rise = smoothstep(38.0, 118.0, d_road) * smoothstep(46.0, 104.0, d_river);
		float pad_clear = smoothstep(26.0, 56.0, d_pad);
		float massif = valley_rise * mix(0.28, 1.0, pad_clear);
		h = 0.34 + macro * 0.24 + micro_bump * 1.15 + massif * (0.38 + peaks * 0.98);
	}

	float pad_flat = 1.0 - smoothstep(22.0, 52.0, d_pad);
	float pad_mound = 1.0 - smoothstep(26.0, 44.0, d_pad);
	float pad_elev = (biome_type == 3) ? 0.76 : 0.72;
	h = mix(h, pad_elev + pad_mound * 0.10, pad_flat * 0.78);

	float road_zone = 1.0 - smoothstep(32.0, 56.0, d_road);
	float ditch = exp(-pow((d_road - 43.0) / 7.5, 2.0)) * 0.12;
	float road_crown = (1.0 - smoothstep(0.0, 34.0, d_road)) * 0.08;
	float road_elev = (biome_type == 3) ? 0.42 : 0.64;
	h = mix(h, road_elev + road_crown, road_zone * 0.88) - ditch;

	float bank_warp = (fbm(wp * 0.026) - 0.5) * 18.0;
	float r_eff = d_river + bank_warp;
	float gorge = 1.0 - smoothstep(34.0, 102.0, r_eff);
	float cliff_step = (1.0 - smoothstep(42.0, 62.0, r_eff)) * 0.24;
	float abut = max(bridge_abutment_mask(wp, bridge_pos), bridge_abutment_mask(wp, bridge_pos_2));
	h -= (gorge * 0.74 + cliff_step) * (1.0 - abut * 0.85);

	return h;
}

void fragment() {
	vec2 wp = UV * map_size;
	vec2 texel = vec2(2.6) / map_size;

	vec4 m = texture(map_mask, UV);
	vec4 mx = texture(map_mask, UV + vec2(texel.x, 0.0));
	vec4 my = texture(map_mask, UV + vec2(0.0, texel.y));

	float d_road = m.r * 128.0;
	float d_river = m.g * 140.0;
	float d_pad = m.b * 96.0;
	float river_side = (m.a - 0.5) * 2.0;

	float h = scene_height(wp, m);
	float hx = scene_height(wp + vec2(2.6, 0.0), mx);
	float hy = scene_height(wp + vec2(0.0, 2.6), my);

	float micro_h = fbm(wp * 0.14);
	float micro_hx = fbm((wp + vec2(1.4, 0.0)) * 0.14);
	float micro_hy = fbm((wp + vec2(0.0, 1.4)) * 0.14);

	vec3 normal = normalize(vec3(
		(h - hx) * 10.5 + (micro_h - micro_hx) * 1.8,
		(h - hy) * 10.5 + (micro_h - micro_hy) * 1.8,
		1.0
	));
	float slope = clamp(1.0 - normal.z, 0.0, 1.0);

	vec3 sun_dir = normalize(vec3(-0.68, -0.58, 0.66));
	vec3 view_dir = vec3(0.0, 0.0, 1.0);
	float ndotl = clamp(dot(normal, sun_dir), 0.0, 1.0);

	vec3 shadow_tint = vec3(0.46, 0.52, 0.58);
	vec3 sun_tint = vec3(1.24, 1.18, 1.04);
	if (biome_type == 1) {
		shadow_tint = vec3(0.50, 0.44, 0.48);
		sun_tint = vec3(1.26, 1.15, 0.94);
	} else if (biome_type == 2) {
		shadow_tint = vec3(0.45, 0.56, 0.72);
		sun_tint = vec3(1.10, 1.14, 1.18);
	} else if (biome_type == 3) {
		shadow_tint = vec3(0.36, 0.42, 0.52);
		sun_tint = vec3(1.26, 1.22, 1.14);
	} else if (biome_type == 4) {
		// Cozy starlit North Pole twilight with warm golden workshop bounce
		shadow_tint = vec3(0.34, 0.46, 0.66);
		sun_tint = vec3(1.08, 1.12, 1.20);
	}
	vec3 sun_lit = mix(shadow_tint, sun_tint, smoothstep(0.12, 0.92, ndotl));

	float moisture = fbm(wp * 0.0052 + vec2(14.2, -9.8));
	float turf_var = fbm(wp * 0.022);
	float grain = noise(wp * 0.38) * 0.65 + noise(wp * 0.92) * 0.35;
	float cobbles = cobble_cells(wp * 0.16);
	float strata = fbm(wp * 0.065 + vec2(h * 3.5, 0.0));

	vec3 ground = vec3(0.0);
	if (biome_type == 1) {
		// DESERT SCORCHED WADI
		vec3 warm_sand = vec3(0.56, 0.44, 0.27);
		vec3 golden_dune = vec3(0.66, 0.53, 0.33);
		vec3 ochre_dust = vec3(0.47, 0.34, 0.21);
		vec3 red_sandstone = vec3(0.46, 0.26, 0.17);
		vec3 dark_mesa = vec3(0.32, 0.20, 0.14);
		vec3 oasis_grass = vec3(0.24, 0.31, 0.15);

		ground = mix(ochre_dust, warm_sand, smoothstep(0.24, 0.60, turf_var));
		ground = mix(ground, golden_dune, smoothstep(0.50, 0.84, h));
		ground *= mix(0.88, 1.12, grain);

		float rock_mask = smoothstep(0.13, 0.40, slope) + smoothstep(0.82, 0.96, h) * 0.62;
		float band = 0.5 + 0.5 * sin(h * 34.0 + strata * 3.0);
		vec3 cliff_col = mix(dark_mesa, red_sandstone, band);
		cliff_col *= mix(0.78, 1.16, smoothstep(0.18, 0.62, cobbles));
		ground = mix(ground, cliff_col, clamp(rock_mask, 0.0, 1.0));

		float oasis_belt = (1.0 - smoothstep(42.0, 92.0, d_river + (turf_var - 0.5) * 24.0)) * smoothstep(38.0, 50.0, d_river);
		ground = mix(ground, oasis_grass * mix(0.82, 1.16, grain), oasis_belt * 0.72 * (1.0 - rock_mask * 0.6));

		float pad_dirt = 1.0 - smoothstep(24.0, 42.0, d_pad + (turf_var - 0.5) * 9.0);
		ground = mix(ground, vec3(0.40, 0.32, 0.22) * mix(0.85, 1.12, cobbles), pad_dirt * 0.65);
	} else if (biome_type == 2) {
		// ARCTIC TUNDRA: Wind-sculpted snowdrifts, glacial ice-blue recesses, wind-scoured slate rock & permafrost
		vec3 packed_snow = vec3(0.68, 0.74, 0.80);
		vec3 fresh_snow = vec3(0.82, 0.86, 0.90);
		vec3 ice_crust = vec3(0.54, 0.65, 0.74);
		vec3 frozen_moss = vec3(0.26, 0.29, 0.24);
		vec3 dark_slate = vec3(0.22, 0.25, 0.29);
		vec3 frosty_granite = vec3(0.38, 0.42, 0.46);

		ground = mix(ice_crust, packed_snow, smoothstep(0.22, 0.58, turf_var));
		ground = mix(ground, fresh_snow, smoothstep(0.46, 0.82, h));

		// Wind-scoured patches of frozen dark tundra lichen/permafrost
		float scoured = smoothstep(0.64, 0.84, moisture) * (1.0 - smoothstep(0.55, 0.80, h));
		ground = mix(ground, frozen_moss * mix(0.84, 1.14, grain), scoured * 0.68);

		// Steep canyon walls & rocky outcrops expose craggy dark slate & frost-crusted granite
		float rock_mask = smoothstep(0.14, 0.40, slope) + smoothstep(0.85, 0.98, h) * 0.50;
		vec3 rock_col = mix(dark_slate, frosty_granite, smoothstep(0.28, 0.76, strata));
		rock_col *= mix(0.76, 1.18, smoothstep(0.18, 0.62, cobbles));
		ground = mix(ground, rock_col, clamp(rock_mask, 0.0, 1.0));

		// Fine snow powder micro-grain & subtle frost sparkle on sunlit snow
		ground *= mix(0.92, 1.08, grain);
		float sparkle = smoothstep(0.92, 0.99, noise(wp * 0.95)) * ndotl * (1.0 - rock_mask);
		ground += vec3(0.24, 0.28, 0.32) * sparkle;

		// Cleared frozen gravel/slush ring around turret hardpoints
		float pad_dirt = 1.0 - smoothstep(24.0, 40.0, d_pad + (turf_var - 0.5) * 9.0);
		ground = mix(ground, vec3(0.34, 0.37, 0.40) * mix(0.85, 1.12, cobbles), pad_dirt * 0.62);
	} else if (biome_type == 3) {
		// HIGH-ALTITUDE MOUNTAIN VALLEYS: Deep pine valley floors -> craggy granite cliffs -> snow-capped peaks!
		vec3 valley_moss = vec3(0.14, 0.20, 0.12);
		vec3 scree_earth = vec3(0.27, 0.25, 0.21);
		vec3 dark_granite = vec3(0.24, 0.25, 0.26);
		vec3 pale_granite = vec3(0.45, 0.44, 0.42);
		vec3 warm_quartz = vec3(0.42, 0.37, 0.31);
		vec3 peak_snow = vec3(0.86, 0.90, 0.94);

		// Deep valley floor greenery & talus scree
		ground = mix(valley_moss, scree_earth, smoothstep(0.36, 0.68, turf_var));
		ground *= mix(0.84, 1.14, grain);

		// Craggy alpine granite cliffs rising out of the valleys
		float cliff_band = 0.5 + 0.5 * sin(h * 28.0 + strata * 3.4);
		vec3 granite = mix(dark_granite, mix(pale_granite, warm_quartz, 0.32), cliff_band);
		granite *= mix(0.74, 1.20, smoothstep(0.16, 0.64, cobbles));

		float rock_mask = smoothstep(0.11, 0.36, slope) + smoothstep(0.56, 0.84, h);
		ground = mix(ground, granite, clamp(rock_mask, 0.0, 1.0));

		// High-altitude snowcaps clinging to mountain summits & ledges (shedding off ultra-sheer rock faces)
		float snow_line = smoothstep(0.94, 1.22, h + (turf_var - 0.5) * 0.14);
		float sheer_shed = 1.0 - smoothstep(0.48, 0.74, slope);
		float summit_snow = clamp(snow_line * sheer_shed, 0.0, 1.0);
		ground = mix(ground, peak_snow * mix(0.92, 1.08, grain), summit_snow);

		// Subtle deep-valley atmospheric depth & cliff-base ambient occlusion
		float valley_depth_ao = smoothstep(0.32, 0.62, h);
		ground *= mix(0.80, 1.0, valley_depth_ao);

		// Compacted rocky gravel shelf on mountain turret ledges
		float pad_dirt = 1.0 - smoothstep(24.0, 42.0, d_pad + (turf_var - 0.5) * 8.0);
		ground = mix(ground, vec3(0.33, 0.33, 0.31) * mix(0.84, 1.14, cobbles), pad_dirt * 0.72);
	} else if (biome_type == 4) {
		// SANTA'S NORTH POLE: Plush sparkling snow + shimmering Northern Lights (Aurora Borealis!)
		vec3 snow_shadow = vec3(0.56, 0.68, 0.82);
		vec3 snow_plush = vec3(0.82, 0.88, 0.94);
		vec3 snow_bright = vec3(0.92, 0.96, 1.00);
		vec3 frost_slate = vec3(0.30, 0.38, 0.48);

		ground = mix(snow_shadow, snow_plush, smoothstep(0.22, 0.60, turf_var));
		ground = mix(ground, snow_bright, smoothstep(0.50, 0.85, h));

		float rock_mask = smoothstep(0.18, 0.46, slope);
		ground = mix(ground, frost_slate * mix(0.82, 1.16, cobbles), rock_mask * 0.75);
		ground *= mix(0.94, 1.06, grain);

		// Magical Northern Lights aurora waves drifting softly across the snow
		float a_wave1 = sin(wp.x * 0.0045 + wp.y * 0.0025 + TIME * 0.45 + fbm(wp * 0.003) * 3.5);
		float a_wave2 = sin(wp.x * 0.0032 - wp.y * 0.0042 - TIME * 0.32 + fbm(wp * 0.004) * 3.0);
		float aurora_green = smoothstep(0.35, 0.95, a_wave1) * 0.14;
		float aurora_violet = smoothstep(0.45, 0.98, a_wave2) * 0.10;
		ground += vec3(0.08, 0.55, 0.42) * aurora_green + vec3(0.46, 0.16, 0.62) * aurora_violet;

		// Glistening diamond snow sparkles
		float sparkle = smoothstep(0.91, 0.99, noise(wp * 0.88 + vec2(sin(TIME * 0.6) * 0.05, 0.0)));
		ground += vec3(0.45, 0.52, 0.60) * sparkle;

		// Warm golden glow radiating around Santa's Workshop on the eastern courtyard
		float workshop_dist = length(wp - vec2(1515.0, 480.0));
		float warm_glow = exp(-workshop_dist * 0.0055);
		ground += vec3(0.42, 0.28, 0.08) * warm_glow * 0.55;

		// Festive cobblestone clearing under wreath turret pads
		float pad_clear = 1.0 - smoothstep(23.0, 38.0, d_pad + (turf_var - 0.5) * 6.0);
		ground = mix(ground, vec3(0.44, 0.34, 0.30) * mix(0.84, 1.14, cobbles), pad_clear * 0.58);
	} else {
		// ALPINE IRON VALLEY
		vec3 rich_moss = vec3(0.15, 0.21, 0.12);
		vec3 olive_grass = vec3(0.22, 0.28, 0.16);
		vec3 dry_meadow = vec3(0.32, 0.30, 0.19);
		vec3 packed_earth = vec3(0.28, 0.23, 0.17);
		vec3 cliff_rock = vec3(0.35, 0.34, 0.30);
		vec3 wet_shale = vec3(0.21, 0.20, 0.17);

		ground = mix(rich_moss, olive_grass, smoothstep(0.28, 0.62, turf_var));
		ground = mix(ground, dry_meadow, smoothstep(0.50, 0.80, turf_var) * (1.0 - moisture * 0.55));
		ground *= mix(0.84, 1.15, grain);

		float rock_mask = smoothstep(0.14, 0.42, slope) + smoothstep(0.84, 0.98, h) * 0.55;
		vec3 rock_col = mix(wet_shale, cliff_rock, smoothstep(0.25, 0.78, strata));
		rock_col *= mix(0.76, 1.16, smoothstep(0.18, 0.62, cobbles));
		ground = mix(ground, rock_col, clamp(rock_mask, 0.0, 1.0));

		float pad_dirt = 1.0 - smoothstep(24.0, 40.0, d_pad + (turf_var - 0.5) * 9.0);
		ground = mix(ground, packed_earth * mix(0.85, 1.12, cobbles), pad_dirt * 0.68);
	}

	vec3 col = ground * sun_lit;

	// === TEXTURED 3D MILITARY ROAD ===
	float road_edge_noise = (fbm(wp * 0.08) - 0.5) * 4.5;
	float r_dist = d_road + road_edge_noise;
	float in_shoulder = 1.0 - smoothstep(32.0, 45.0, r_dist);
	float in_asphalt = 1.0 - smoothstep(28.5, 32.5, r_dist);

	bool over_bridge_span = is_over_bridge(wp, bridge_pos) || is_over_bridge(wp, bridge_pos_2);

	if (in_shoulder > 0.001 && !over_bridge_span) {
		float gravel_grain = noise(wp * 0.45) * 0.5 + cobbles * 0.5;
		vec3 sh_dark = vec3(0.24, 0.22, 0.18);
		vec3 sh_light = vec3(0.38, 0.35, 0.29);
		if (biome_type == 1) {
			sh_dark = vec3(0.42, 0.32, 0.20);
			sh_light = vec3(0.60, 0.48, 0.31);
		} else if (biome_type == 2) {
			sh_dark = vec3(0.38, 0.43, 0.48);
			sh_light = vec3(0.76, 0.81, 0.86);
		} else if (biome_type == 4) {
			// Candy-cane striped snowy cobblestone curb!
			float stripe = step(0.5, fract((wp.x + wp.y) * 0.032));
			sh_dark = mix(vec3(0.78, 0.14, 0.16), vec3(0.92, 0.94, 0.96), stripe);
			sh_light = mix(vec3(0.92, 0.24, 0.24), vec3(0.98, 0.98, 1.00), stripe);
		}
		vec3 shoulder_col = mix(sh_dark, sh_light, gravel_grain) * sun_lit;
		col = mix(col, shoulder_col, in_shoulder * 0.94);

		if (in_asphalt > 0.001) {
			float agg = noise(wp * 0.72) * 0.55 + noise(wp * 1.55) * 0.45;
			float wear = fbm(wp * 0.042);
			float crack_n = abs(noise(wp * 0.075 + vec2(wear * 2.0, 0.0)) * 2.0 - 1.0);
			float crack = 1.0 - smoothstep(0.0, 0.045, crack_n);

			vec3 asp_a = vec3(0.17, 0.175, 0.17);
			vec3 asp_b = vec3(0.26, 0.26, 0.25);
			if (biome_type == 1) {
				asp_a = vec3(0.23, 0.21, 0.19);
				asp_b = vec3(0.34, 0.30, 0.25);
			} else if (biome_type == 2) {
				asp_a = vec3(0.16, 0.18, 0.21);
				asp_b = vec3(0.27, 0.30, 0.34);
			} else if (biome_type == 4) {
				// Cozy frosted red-brown Workshop cobblestone highway
				asp_a = vec3(0.30, 0.22, 0.20);
				asp_b = vec3(0.46, 0.34, 0.30);
			}
			vec3 asphalt = mix(asp_a, asp_b, wear);
			if (biome_type == 4) {
				asphalt *= mix(0.76, 1.18, smoothstep(0.16, 0.65, cobbles));
				float snow_dust = smoothstep(16.0, 30.0, d_road) * smoothstep(0.34, 0.72, fbm(wp * 0.055));
				asphalt = mix(asphalt, vec3(0.86, 0.91, 0.96), snow_dust * 0.74);
			} else {
				asphalt *= mix(0.84, 1.14, agg);
				asphalt = mix(asphalt, vec3(0.09, 0.10, 0.11), crack * 0.55);
			}

			if (biome_type == 1) {
				float sand_drift = smoothstep(16.0, 31.0, d_road) * smoothstep(0.36, 0.72, fbm(wp * 0.055));
				asphalt = mix(asphalt, vec3(0.56, 0.44, 0.28), sand_drift * 0.62);
			} else if (biome_type == 2) {
				// Wind-blown snowdrifts & frosty rime creeping over the edges of the winter highway
				float snow_drift = smoothstep(15.0, 30.5, d_road) * smoothstep(0.32, 0.70, fbm(wp * 0.052));
				asphalt = mix(asphalt, vec3(0.74, 0.80, 0.86), snow_drift * 0.72);
			}

			// Dual darkened tank/convoy tire ruts (extra wet-slush dark on tundra!)
			float rut = exp(-pow((abs(d_road - 13.5)) / 4.2, 2.0));
			asphalt *= mix(1.0, (biome_type == 2) ? 0.62 : 0.72, rut * 0.82);

			float white_edge = exp(-pow((d_road - 25.5) / 1.15, 2.0));
			float paint_chip = smoothstep(0.28, 0.70, noise(wp * 0.25));
			asphalt = mix(asphalt, vec3(0.74, 0.74, 0.70), white_edge * paint_chip * 0.32);

			float curb_ao = smoothstep(26.0, 31.0, r_dist) * 0.24;
			asphalt *= (1.0 - curb_ao);

			vec3 road_n = normalize(vec3((agg - 0.5) * 0.35, (agg - 0.5) * 0.35, 1.0));
			vec3 half_v = normalize(sun_dir + view_dir);
			float spec_gain = (biome_type == 2) ? (0.06 + rut * 0.14) : (0.04 + rut * 0.07);
			float road_spec = pow(max(dot(road_n, half_v), 0.0), 24.0) * spec_gain;
			vec3 road_lit = asphalt * mix(vec3(0.80, 0.84, 0.88), sun_tint * 0.94, ndotl) + vec3(road_spec);

			col = mix(col, road_lit, in_asphalt);
		}
	}

	// === PHOTOREALISTIC 3D RIVER / GLACIAL STREAM WATER ===
	float shore_warp = (fbm(wp * 0.032) - 0.5) * 16.0 + (noise(wp * 0.12) - 0.5) * 4.5;
	float river_r = d_river + shore_warp;
	float water_edge = 41.0;

	float wet_rim = (1.0 - smoothstep(water_edge - 1.0, water_edge + 14.0, river_r)) * smoothstep(water_edge - 3.0, water_edge + 2.0, river_r);
	if (wet_rim > 0.001 && !over_bridge_span) {
		float wet_cob = smoothstep(0.15, 0.65, cobbles);
		vec3 wet_a = vec3(0.10, 0.10, 0.08);
		vec3 wet_b = vec3(0.22, 0.21, 0.18);
		if (biome_type == 1) {
			wet_a = vec3(0.22, 0.15, 0.10);
			wet_b = vec3(0.36, 0.26, 0.17);
		} else if (biome_type == 2) {
			wet_a = vec3(0.18, 0.23, 0.28);
			wet_b = vec3(0.58, 0.68, 0.76);
		}
		vec3 wet_bank = mix(wet_a, wet_b, wet_cob) * sun_lit;
		vec3 half_w = normalize(sun_dir + view_dir);
		float damp_spec = pow(max(dot(normal, half_w), 0.0), 28.0) * 0.26 * wet_rim;
		col = mix(col, wet_bank + vec3(damp_spec), wet_rim * 0.85);
	}

	float in_water = 1.0 - smoothstep(water_edge - 2.4, water_edge + 1.2, river_r);
	if (in_water > 0.001) {
		float depth = clamp((water_edge - river_r) / 34.0, 0.0, 1.0);
		float depth_smooth = smoothstep(0.0, 1.0, depth);

		float wh = water_wave_height(wp, TIME);
		float whx = water_wave_height(wp + vec2(1.8, 0.0), TIME);
		float why = water_wave_height(wp + vec2(0.0, 1.8), TIME);
		vec3 water_n = normalize(vec3((wh - whx) * 4.6, (wh - why) * 4.6, 1.0));

		vec2 refracted_wp = wp + water_n.xy * (8.0 + depth_smooth * 14.0);
		float bed_stones = cobble_cells(refracted_wp * 0.15);
		float bed_grit = fbm(refracted_wp * 0.06);

		vec3 bed_a = vec3(0.16, 0.15, 0.11);
		vec3 bed_b = vec3(0.32, 0.29, 0.22);
		vec3 caust_col = vec3(0.42, 0.56, 0.48);
		vec3 abs_coeff = vec3(3.1, 1.55, 1.15);
		vec3 deep_water = vec3(0.035, 0.105, 0.145);
		vec3 mid_col = vec3(0.07, 0.21, 0.23);
		vec3 sky_a = vec3(0.24, 0.36, 0.44);
		vec3 sky_b = vec3(0.58, 0.64, 0.66);

		if (biome_type == 1) {
			bed_a = vec3(0.32, 0.24, 0.14);
			bed_b = vec3(0.52, 0.40, 0.24);
			caust_col = vec3(0.62, 0.72, 0.56);
			abs_coeff = vec3(2.8, 1.15, 0.95);
			deep_water = vec3(0.03, 0.16, 0.20);
			mid_col = vec3(0.06, 0.30, 0.30);
			sky_a = vec3(0.32, 0.48, 0.54);
			sky_b = vec3(0.72, 0.70, 0.62);
		} else if (biome_type == 2) {
			bed_a = vec3(0.10, 0.15, 0.20);
			bed_b = vec3(0.28, 0.36, 0.44);
			caust_col = vec3(0.52, 0.78, 0.92);
			abs_coeff = vec3(3.4, 1.50, 0.92);
			deep_water = vec3(0.02, 0.075, 0.145);
			mid_col = vec3(0.07, 0.24, 0.34);
			sky_a = vec3(0.36, 0.50, 0.64);
			sky_b = vec3(0.76, 0.84, 0.90);
		} else if (biome_type == 3) {
			// Crisp glacial-snowmelt alpine rapids cutting through the granite gorge
			bed_a = vec3(0.14, 0.16, 0.18);
			bed_b = vec3(0.34, 0.36, 0.38);
			caust_col = vec3(0.50, 0.76, 0.78);
			abs_coeff = vec3(3.0, 1.35, 1.02);
			deep_water = vec3(0.025, 0.115, 0.165);
			mid_col = vec3(0.07, 0.28, 0.32);
			sky_a = vec3(0.30, 0.44, 0.56);
			sky_b = vec3(0.74, 0.78, 0.82);
		} else if (biome_type == 4) {
			// Enchanted Aurora Borealis Ice Canal!
			bed_a = vec3(0.10, 0.18, 0.30);
			bed_b = vec3(0.30, 0.52, 0.64);
			caust_col = vec3(0.38, 0.92, 0.76);
			abs_coeff = vec3(3.2, 1.35, 0.85);
			deep_water = vec3(0.03, 0.08, 0.22);
			mid_col = vec3(0.10, 0.44, 0.48);
			sky_a = vec3(0.18, 0.56, 0.54);
			sky_b = vec3(0.68, 0.44, 0.86);
		}

		vec3 riverbed = mix(bed_a, bed_b, smoothstep(0.18, 0.68, bed_stones)) * mix(0.75, 1.15, bed_grit);
		float caust = caustics(refracted_wp * 0.055, TIME);
		riverbed += caust_col * caust * (1.0 - depth_smooth * 0.60) * 0.72;

		vec3 absorption = exp(-depth_smooth * abs_coeff);
		vec3 mid_scatter = mid_col * (0.55 + 0.45 * wh);
		vec3 water_body = mix(deep_water, riverbed * absorption + mid_scatter * 0.38, clamp(absorption.b * 0.92, 0.18, 1.0));

		float fresnel = 0.06 + 0.58 * pow(1.0 - clamp(water_n.z, 0.0, 1.0), 2.4);
		float sky_cloud = fbm(wp * 0.004 + water_n.xy * 0.45 + vec2(TIME * 0.015, TIME * 0.008));
		vec3 sky_refl = mix(sky_a, sky_b, smoothstep(0.42, 0.78, sky_cloud));
		vec3 water_col = mix(water_body, sky_refl, fresnel * (0.45 + depth_smooth * 0.55));

		vec3 half_vec = normalize(sun_dir + view_dir);
		float spec_sharp = pow(max(dot(water_n, half_vec), 0.0), 96.0);
		float spec_broad = pow(max(dot(water_n, half_vec), 0.0), 18.0);
		water_col += vec3(1.0, 0.97, 0.90) * spec_sharp * ((biome_type == 1) ? 1.10 : 0.98);
		water_col += vec3(0.55, 0.76, 0.84) * spec_broad * 0.22;

		// Steep western canyon wall casts shadow onto western river edge
		float west_shadow = smoothstep(0.08, -0.55, river_side) * smoothstep(10.0, 40.0, river_r);
		float bank_ao = 1.0 - smoothstep(water_edge - 9.0, water_edge + 1.0, river_r) * 0.30;
		water_col *= (1.0 - west_shadow * 0.52) * bank_ao;

		// Dual-bridge cast shadows onto the flowing water
		float bridge_shadow = max(bridge_shadow_mask(wp, bridge_pos), bridge_shadow_mask(wp, bridge_pos_2));
		water_col *= (1.0 - bridge_shadow * 0.62);

		// Organic shoreline foam (plus jagged glacial shelf-ice on tundra & extra mountain rapids!)
		float foam_wave = fbm(vec2(wp.x * 0.14, wp.y * 0.11 - TIME * 1.45));
		float shore_foam = smoothstep(water_edge - 9.5, water_edge - 1.0, river_r) * smoothstep(0.44, 0.74, foam_wave);
		water_col = mix(water_col, vec3(0.84, 0.90, 0.94), shore_foam * ((biome_type == 3) ? 0.68 : 0.54));

		if (biome_type == 3) {
			float rapids = smoothstep(0.58, 0.84, fbm(vec2(wp.x * 0.16, wp.y * 0.08 - TIME * 2.5)));
			water_col = mix(water_col, vec3(0.86, 0.92, 0.94), rapids * 0.34 * (1.0 - bridge_shadow * 0.75));
		}

		if (biome_type == 2 || biome_type == 4) {
			float ice_n = fbm(wp * 0.075);
			float shelf_ice = smoothstep(water_edge - 13.0 + ice_n * 8.0, water_edge - 2.5, river_r) * (1.0 - bridge_shadow * 0.7);
			vec3 ice_col = mix(vec3(0.62, 0.78, 0.88), vec3(0.88, 0.94, 0.98), cobbles) * sun_lit;
			water_col = mix(water_col, ice_col, shelf_ice * 0.82);
		}

		// Turbulent whitewater wakes behind BOTH bridges' piers
		float wake_foam = max(bridge_pier_wake(wp, bridge_pos, TIME), bridge_pier_wake(wp, bridge_pos_2, TIME));
		water_col = mix(water_col, vec3(0.88, 0.94, 0.96), wake_foam * 0.72);

		float flow_streak = smoothstep(0.68, 0.88, fbm(vec2(wp.x * 0.18, wp.y * 0.035 - TIME * 1.65)));
		water_col += vec3(0.36, 0.54, 0.62) * flow_streak * depth_smooth * 0.20 * (1.0 - bridge_shadow * 0.8);

		col = mix(col, water_col, in_water);
	}

	// Drifting soft cloud shadows
	vec2 cloud_uv = wp * 0.0013 + vec2(TIME * 0.014, TIME * 0.007);
	float cloud = smoothstep(0.50, 0.80, fbm(cloud_uv));
	float cloud_str = (biome_type == 1) ? 0.36 : ((biome_type == 2) ? 0.45 : 0.62);
	col *= mix(1.0, 0.80, cloud * cloud_str);

	// Soft battlefield edge vignette
	vec2 edge = min(UV, 1.0 - UV);
	float vig = smoothstep(0.0, 0.08, min(edge.x, edge.y));
	col *= mix(0.72, 1.0, vig);

	COLOR = vec4(col, 1.0);
}
