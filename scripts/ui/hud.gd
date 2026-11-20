class_name GameHud
extends CanvasLayer

signal start_game_requested(map_id: String, difficulty: WaveData.Difficulty)
signal sector_selected(map_id: String)
signal next_sector_requested()
signal secret_sector_requested(map_id: String)
signal turret_card_selected(turret_type: TurretData.TurretType)
signal airstrike_requested()
signal next_wave_requested()
signal speed_changed(speed_mult: float)
signal pause_toggled()
signal mute_toggled()
signal restart_requested()
signal upgrade_requested()
signal target_mode_requested()
signal sell_requested()

const COL_BG := Color(0.08, 0.10, 0.09, 0.90)
const COL_BG_DARK := Color(0.05, 0.06, 0.06, 0.94)
const COL_BORDER := Color(0.28, 0.35, 0.28, 0.95)
const COL_TEXT := Color(0.88, 0.92, 0.86)
const COL_MUTED := Color(0.60, 0.66, 0.58)
const COL_AMBER := Color(0.96, 0.76, 0.28)
const COL_GREEN := Color(0.34, 0.88, 0.48)
const COL_RED := Color(0.94, 0.30, 0.24)

var _root: Control
var _sector_label: Label
var _cash_label: Label
var _lives_label: Label
var _wave_label: Label
var _diff_label: Label
var _pause_btn: Button
var _speed_btns: Dictionary = {}
var _mute_btn: Button

var _turret_btns: Dictionary = {}
var _airstrike_btn: Button
var _airstrike_bar: ProgressBar
var _next_wave_btn: Button

var _inspector_panel: PanelContainer
var _insp_title: Label
var _insp_stats: Label
var _insp_upgrade_btn: Button
var _insp_target_btn: Button
var _insp_sell_btn: Button

var _banner_panel: PanelContainer
var _banner_label: Label
var _banner_timer: float = 0.0

var _menu_overlay: ColorRect
var _menu_title: Label
var _menu_sub: Label
var _menu_brief: Label
var _selected_map_id: String = "iron_valley"
var _sector_btns: Dictionary = {}
var _selected_diff: WaveData.Difficulty = WaveData.Difficulty.NORMAL
var _diff_btns: Dictionary = {}

var _end_overlay: ColorRect
var _end_title: Label
var _end_summary: Label
var _end_next_btn: Button
var _end_secret_btn: Button
var _secret_map_id: String = ""
var _btn_style_cache: Dictionary = {}

func _ready() -> void:
	layer = 10
	_build_ui()

func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.6:
			_banner_panel.modulate.a = clampf(_banner_timer / 0.6, 0.0, 1.0)
		if _banner_timer <= 0.0:
			_banner_panel.visible = false

func _make_box(bg: Color, border: Color, radius: int = 4, border_w: int = 1, pad_x: int = 10, pad_y: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb

func _style_button(btn: Button, accent: Color = COL_BORDER, bg: Color = Color(0.12, 0.15, 0.13, 0.95), pad_x: int = 10, pad_y: int = 6) -> void:
	btn.add_theme_stylebox_override("normal", _make_box(bg, accent, 4, 1, pad_x, pad_y))
	btn.add_theme_stylebox_override("hover", _make_box(bg.lightened(0.08), accent.lightened(0.22), 4, 1, pad_x, pad_y))
	btn.add_theme_stylebox_override("pressed", _make_box(bg.darkened(0.12), accent.lightened(0.35), 4, 2, pad_x, pad_y))
	btn.add_theme_stylebox_override("disabled", _make_box(Color(0.08, 0.09, 0.08, 0.72), Color(0.20, 0.22, 0.20, 0.6), 4, 1, pad_x, pad_y))
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.48, 0.45))
	btn.focus_mode = Control.FOCUS_NONE

func _style_button_cached(btn: Button, state_key: String, accent: Color = COL_BORDER, bg: Color = Color(0.12, 0.15, 0.13, 0.95), font_col: Color = COL_TEXT) -> void:
	if _btn_style_cache.get(btn, "") == state_key:
		return
	_btn_style_cache[btn] = state_key
	_style_button(btn, accent, bg)
	btn.add_theme_color_override("font_color", font_col)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_top_bar()
	_build_wave_banner()
	_build_bottom_dock()
	_build_inspector()
	_build_menu_overlay()
	_build_end_overlay()

func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 10
	bar.offset_right = -10
	bar.offset_top = 8
	bar.offset_bottom = 52
	bar.add_theme_stylebox_override("panel", _make_box(COL_BG, COL_BORDER, 4, 1, 14, 6))
	_root.add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	bar.add_child(hbox)

	_sector_label = Label.new()
	_sector_label.text = "IRON VALLEY"
	_sector_label.add_theme_font_size_override("font_size", 15)
	_sector_label.add_theme_color_override("font_color", COL_TEXT)
	hbox.add_child(_sector_label)

	_diff_label = Label.new()
	_diff_label.text = "[NORMAL]"
	_diff_label.add_theme_font_size_override("font_size", 13)
	_diff_label.add_theme_color_override("font_color", COL_AMBER)
	hbox.add_child(_diff_label)

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer1)

	_cash_label = Label.new()
	_cash_label.text = "$ 280"
	_cash_label.add_theme_font_size_override("font_size", 17)
	_cash_label.add_theme_color_override("font_color", COL_AMBER)
	hbox.add_child(_cash_label)

	_lives_label = Label.new()
	_lives_label.text = "HQ 20/20"
	_lives_label.add_theme_font_size_override("font_size", 16)
	_lives_label.add_theme_color_override("font_color", COL_GREEN)
	hbox.add_child(_lives_label)

	_wave_label = Label.new()
	_wave_label.text = "WAVE 0 / 15"
	_wave_label.add_theme_font_size_override("font_size", 15)
	_wave_label.add_theme_color_override("font_color", COL_TEXT)
	hbox.add_child(_wave_label)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer2)

	_pause_btn = Button.new()
	_pause_btn.text = "||"
	_pause_btn.custom_minimum_size = Vector2(36, 28)
	_style_button(_pause_btn)
	_pause_btn.pressed.connect(func(): pause_toggled.emit())
	hbox.add_child(_pause_btn)

	for spd in [1.0, 2.0, 3.0]:
		var sb := Button.new()
		sb.text = "%dx" % int(spd)
		sb.custom_minimum_size = Vector2(38, 28)
		_style_button(sb)
		sb.pressed.connect(func(): speed_changed.emit(spd))
		hbox.add_child(sb)
		_speed_btns[spd] = sb

	_mute_btn = Button.new()
	_mute_btn.text = "SFX"
	_mute_btn.custom_minimum_size = Vector2(52, 28)
	_style_button(_mute_btn)
	_mute_btn.pressed.connect(func(): mute_toggled.emit())
	hbox.add_child(_mute_btn)

	var reset_btn := Button.new()
	reset_btn.text = "MENU"
	reset_btn.custom_minimum_size = Vector2(58, 28)
	_style_button(reset_btn, Color(0.55, 0.32, 0.28))
	reset_btn.pressed.connect(func(): restart_requested.emit())
	hbox.add_child(reset_btn)

func _build_wave_banner() -> void:
	_banner_panel = PanelContainer.new()
	_banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner_panel.offset_left = -210
	_banner_panel.offset_right = 210
	_banner_panel.offset_top = 62
	_banner_panel.offset_bottom = 98
	_banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_panel.add_theme_stylebox_override("panel", _make_box(Color(0.09, 0.11, 0.09, 0.88), COL_AMBER, 4, 1, 16, 6))
	_banner_panel.visible = false
	_root.add_child(_banner_panel)

	_banner_label = Label.new()
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 15)
	_banner_label.add_theme_color_override("font_color", COL_AMBER)
	_banner_panel.add_child(_banner_label)

func _build_bottom_dock() -> void:
	var dock := PanelContainer.new()
	dock.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dock.grow_horizontal = Control.GROW_DIRECTION_END
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.offset_left = 10
	dock.offset_right = 10
	dock.offset_top = -92
	dock.offset_bottom = -10
	dock.add_theme_stylebox_override("panel", _make_box(COL_BG, COL_BORDER, 5, 1, 10, 8))
	_root.add_child(dock)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	dock.add_child(hbox)

	for t_type in TurretData.get_all_types():
		var cfg := TurretData.get_config(t_type)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(118, 66)
		btn.text = "[%s] %s\n$%d  •  %s" % [cfg["hotkey"], cfg["short"], int(cfg["base_cost"]), cfg["role"]]
		btn.add_theme_font_size_override("font_size", 12)
		_style_button(btn, cfg["accent"])
		btn.pressed.connect(func(): turret_card_selected.emit(t_type))
		hbox.add_child(btn)
		_turret_btns[t_type] = btn

	var sep := VSeparator.new()
	hbox.add_child(sep)

	# Hellfire Air Strike slot — matches adjacent card height flush, with integrated cooldown strip
	_airstrike_btn = Button.new()
	_airstrike_btn.custom_minimum_size = Vector2(124, 66)
	_airstrike_btn.text = "[Q] AIR STRIKE\nREADY"
	_airstrike_btn.add_theme_font_size_override("font_size", 12)
	_style_button(_airstrike_btn, COL_RED, Color(0.22, 0.10, 0.08, 0.95))
	_airstrike_btn.pressed.connect(func(): airstrike_requested.emit())
	hbox.add_child(_airstrike_btn)

	_airstrike_bar = ProgressBar.new()
	_airstrike_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_airstrike_bar.offset_left = 5
	_airstrike_bar.offset_right = -5
	_airstrike_bar.offset_top = -6
	_airstrike_bar.offset_bottom = -3
	_airstrike_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_airstrike_bar.show_percentage = false
	_airstrike_bar.max_value = 100.0
	_airstrike_bar.value = 100.0
	_airstrike_bar.visible = false
	_airstrike_bar.add_theme_stylebox_override("background", _make_box(Color(0.08, 0.05, 0.05, 0.85), Color(0, 0, 0, 0), 2, 0, 0, 0))
	_airstrike_bar.add_theme_stylebox_override("fill", _make_box(COL_AMBER, Color(0, 0, 0, 0), 2, 0, 0, 0))
	_airstrike_btn.add_child(_airstrike_bar)

	# Next Wave button
	_next_wave_btn = Button.new()
	_next_wave_btn.custom_minimum_size = Vector2(118, 66)
	_next_wave_btn.text = "[N] START\nWAVE 1"
	_next_wave_btn.add_theme_font_size_override("font_size", 12)
	_style_button(_next_wave_btn, COL_GREEN, Color(0.10, 0.20, 0.12, 0.95))
	_next_wave_btn.pressed.connect(func(): next_wave_requested.emit())
	hbox.add_child(_next_wave_btn)

func _build_inspector() -> void:
	_inspector_panel = PanelContainer.new()
	_inspector_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_inspector_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_inspector_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_inspector_panel.offset_left = -336
	_inspector_panel.offset_right = -10
	_inspector_panel.offset_top = -92
	_inspector_panel.offset_bottom = -10
	_inspector_panel.add_theme_stylebox_override("panel", _make_box(COL_BG, COL_AMBER, 5, 1, 10, 6))
	_inspector_panel.visible = false
	_root.add_child(_inspector_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_inspector_panel.add_child(vbox)

	_insp_title = Label.new()
	_insp_title.add_theme_font_size_override("font_size", 13)
	_insp_title.add_theme_color_override("font_color", COL_AMBER)
	vbox.add_child(_insp_title)

	_insp_stats = Label.new()
	_insp_stats.add_theme_font_size_override("font_size", 11)
	_insp_stats.add_theme_color_override("font_color", COL_TEXT)
	vbox.add_child(_insp_stats)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	_insp_upgrade_btn = Button.new()
	_insp_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_insp_upgrade_btn.custom_minimum_size = Vector2(0, 24)
	_insp_upgrade_btn.add_theme_font_size_override("font_size", 11)
	_style_button(_insp_upgrade_btn, COL_GREEN, Color(0.10, 0.20, 0.12, 0.95), 8, 3)
	_insp_upgrade_btn.pressed.connect(func(): upgrade_requested.emit())
	btn_row.add_child(_insp_upgrade_btn)

	_insp_target_btn = Button.new()
	_insp_target_btn.custom_minimum_size = Vector2(90, 24)
	_insp_target_btn.add_theme_font_size_override("font_size", 11)
	_style_button(_insp_target_btn, COL_AMBER, Color(0.12, 0.15, 0.13, 0.95), 8, 3)
	_insp_target_btn.pressed.connect(func(): target_mode_requested.emit())
	btn_row.add_child(_insp_target_btn)

	_insp_sell_btn = Button.new()
	_insp_sell_btn.custom_minimum_size = Vector2(82, 24)
	_insp_sell_btn.add_theme_font_size_override("font_size", 11)
	_style_button(_insp_sell_btn, COL_RED, Color(0.22, 0.10, 0.09, 0.95), 8, 3)
	_insp_sell_btn.pressed.connect(func(): sell_requested.emit())
	btn_row.add_child(_insp_sell_btn)

func _build_menu_overlay() -> void:
	_menu_overlay = ColorRect.new()
	_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.color = Color(0.03, 0.04, 0.03, 0.76)
	_root.add_child(_menu_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(820, 445)
	card.add_theme_stylebox_override("panel", _make_box(COL_BG_DARK, COL_AMBER, 6, 2, 24, 18))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	_menu_title = Label.new()
	_menu_title.text = "DEFENCE ZONE"
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.add_theme_font_size_override("font_size", 24)
	_menu_title.add_theme_color_override("font_color", COL_AMBER)
	vbox.add_child(_menu_title)

	_menu_sub = Label.new()
	_menu_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_sub.add_theme_font_size_override("font_size", 12)
	_menu_sub.add_theme_color_override("font_color", COL_MUTED)
	vbox.add_child(_menu_sub)

	var sector_title := Label.new()
	sector_title.text = "SELECT SECTOR:"
	sector_title.add_theme_font_size_override("font_size", 12)
	sector_title.add_theme_color_override("font_color", COL_AMBER)
	vbox.add_child(sector_title)

	var sector_grid := GridContainer.new()
	sector_grid.columns = 4
	sector_grid.add_theme_constant_override("h_separation", 8)
	sector_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(sector_grid)

	for m in MapData.get_all_maps():
		var mid: String = String(m["id"])
		var b := Button.new()
		b.text = "0%d %s\n%s" % [int(m["index"]), String(m["short_name"]), String(m["tag"])]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 46)
		b.add_theme_font_size_override("font_size", 11)
		_style_button(b, COL_AMBER)
		b.pressed.connect(func(): _select_sector(mid, true))
		sector_grid.add_child(b)
		_sector_btns[mid] = b

	_menu_brief = Label.new()
	_menu_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_brief.add_theme_font_size_override("font_size", 13)
	_menu_brief.add_theme_color_override("font_color", COL_TEXT)
	vbox.add_child(_menu_brief)

	var diff_title := Label.new()
	diff_title.text = "SELECT DIFFICULTY:"
	diff_title.add_theme_font_size_override("font_size", 12)
	diff_title.add_theme_color_override("font_color", COL_AMBER)
	vbox.add_child(diff_title)

	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 8)
	vbox.add_child(diff_row)

	for d in [WaveData.Difficulty.EASY, WaveData.Difficulty.NORMAL, WaveData.Difficulty.HARD, WaveData.Difficulty.HELL]:
		var cfg := WaveData.get_difficulty_config(d)
		var b := Button.new()
		b.text = "%s\n$%d • %d HP" % [cfg["name"], int(cfg["start_cash"]), int(cfg["start_lives"])]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 48)
		b.add_theme_font_size_override("font_size", 12)
		_style_button(b, cfg["accent"])
		b.pressed.connect(func(): _select_difficulty(d))
		diff_row.add_child(b)
		_diff_btns[d] = b

	var controls := Label.new()
	controls.text = "CONTROLS:  [1-4] Select Turret  •  [LMB] Build / Inspect  •  [RMB/ESC] Cancel\n[Q] Hellfire Air Strike  •  [N] Next Wave  •  [WASD / RMB Drag / Wheel] Pan & Zoom  •  [SPACE] Pause"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 11)
	controls.add_theme_color_override("font_color", COL_MUTED)
	vbox.add_child(controls)

	var deploy_btn := Button.new()
	deploy_btn.text = "DEPLOY DEFENSES"
	deploy_btn.custom_minimum_size = Vector2(0, 44)
	deploy_btn.add_theme_font_size_override("font_size", 16)
	_style_button(deploy_btn, COL_GREEN, Color(0.11, 0.24, 0.13, 0.98))
	deploy_btn.pressed.connect(func():
		_menu_overlay.visible = false
		start_game_requested.emit(_selected_map_id, _selected_diff)
	)
	vbox.add_child(deploy_btn)

	var active_season := SeasonalData.get_active_seasonal_event()
	if not active_season.is_empty():
		var hint_lbl := Label.new()
		hint_lbl.text = String(active_season["hint"])
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.add_theme_font_size_override("font_size", 11)
		hint_lbl.add_theme_color_override("font_color", Color(0.98, 0.44, 0.38, 0.92))
		vbox.add_child(hint_lbl)

	_select_sector("iron_valley", false)
	_select_difficulty(WaveData.Difficulty.NORMAL)

func _select_sector(map_id: String, emit_signal: bool) -> void:
	_selected_map_id = map_id
	var m := MapData.get_map_by_id(map_id)
	_menu_title.text = "DEFENCE ZONE: %s" % String(m["short_name"])
	_menu_sub.text = "SECTOR 0%d  •  %s" % [int(m["index"]), String(m["tag"])]
	_menu_brief.text = String(m["briefing"])

	for key in _sector_btns.keys():
		var btn: Button = _sector_btns[key]
		if String(key) == map_id:
			var bname: String = String(m["biome"])
			var accent := COL_GREEN
			if bname == "desert":
				accent = Color(0.95, 0.68, 0.28)
			elif bname == "tundra":
				accent = Color(0.46, 0.84, 0.98)
			elif bname == "mountain":
				accent = Color(0.82, 0.78, 0.70)
			elif bname == "town":
				accent = Color(0.74, 0.78, 0.84)
			elif bname == "countryside":
				accent = Color(0.68, 0.88, 0.34)
			elif bname == "forest":
				accent = Color(0.24, 0.76, 0.42)
			elif bname == "outback":
				accent = Color(0.92, 0.44, 0.24)
			_style_button(btn, accent, Color(0.18, 0.21, 0.16, 0.98))
		else:
			_style_button(btn, Color(0.25, 0.28, 0.25), Color(0.09, 0.11, 0.10, 0.92))

	if emit_signal:
		sector_selected.emit(map_id)

func select_sector_external(map_id: String) -> void:
	_select_sector(map_id, false)

func _select_difficulty(d: WaveData.Difficulty) -> void:
	_selected_diff = d
	for key in _diff_btns.keys():
		var cfg := WaveData.get_difficulty_config(key)
		var btn: Button = _diff_btns[key]
		if key == d:
			_style_button(btn, cfg["accent"], Color(0.18, 0.22, 0.17, 0.98))
		else:
			_style_button(btn, Color(0.25, 0.28, 0.25), Color(0.09, 0.11, 0.10, 0.92))

func _build_end_overlay() -> void:
	_end_overlay = ColorRect.new()
	_end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_overlay.color = Color(0.02, 0.03, 0.02, 0.80)
	_end_overlay.visible = false
	_root.add_child(_end_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 260)
	card.add_theme_stylebox_override("panel", _make_box(COL_BG_DARK, COL_AMBER, 6, 2, 26, 22))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	_end_title = Label.new()
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(_end_title)

	_end_summary = Label.new()
	_end_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_summary.add_theme_font_size_override("font_size", 14)
	_end_summary.add_theme_color_override("font_color", COL_TEXT)
	vbox.add_child(_end_summary)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var retry_btn := Button.new()
	retry_btn.text = "RETURN TO BRIEFING"
	retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_btn.custom_minimum_size = Vector2(0, 42)
	retry_btn.add_theme_font_size_override("font_size", 14)
	_style_button(retry_btn, COL_AMBER, Color(0.18, 0.16, 0.10, 0.96))
	retry_btn.pressed.connect(func():
		_end_overlay.visible = false
		restart_requested.emit()
	)
	btn_row.add_child(retry_btn)

	_end_next_btn = Button.new()
	_end_next_btn.text = "NEXT SECTOR >"
	_end_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_next_btn.custom_minimum_size = Vector2(0, 42)
	_end_next_btn.add_theme_font_size_override("font_size", 14)
	_style_button(_end_next_btn, COL_GREEN, Color(0.11, 0.24, 0.13, 0.98))
	_end_next_btn.pressed.connect(func():
		_end_overlay.visible = false
		next_sector_requested.emit()
	)
	btn_row.add_child(_end_next_btn)

	_end_secret_btn = Button.new()
	_end_secret_btn.text = "★ INTERCEPTED SIGNAL ★"
	_end_secret_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_end_secret_btn.custom_minimum_size = Vector2(0, 42)
	_end_secret_btn.add_theme_font_size_override("font_size", 13)
	_style_button(_end_secret_btn, Color(0.98, 0.30, 0.28), Color(0.26, 0.08, 0.10, 0.98))
	_end_secret_btn.visible = false
	_end_secret_btn.pressed.connect(func():
		_end_overlay.visible = false
		if _secret_map_id != "":
			secret_sector_requested.emit(_secret_map_id)
	)
	btn_row.add_child(_end_secret_btn)

func show_menu() -> void:
	_menu_overlay.visible = true
	_end_overlay.visible = false
	_inspector_panel.visible = false

func hide_menu() -> void:
	_menu_overlay.visible = false

func get_selected_difficulty() -> WaveData.Difficulty:
	return _selected_diff

func show_end_screen(victory: bool, sector_name: String, waves_cleared: int, total_waves: int, kills: int, diff_name: String, has_next_sector: bool, secret_event: Dictionary = {}) -> void:
	_end_overlay.visible = true
	_end_title.text = "SECTOR SECURED" if victory else "COMMAND HQ BREACHED"
	_end_title.add_theme_color_override("font_color", COL_GREEN if victory else COL_RED)
	_end_summary.text = "%s\nDifficulty: %s\nWaves Cleared: %d / %d\nHostiles Destroyed: %d" % [sector_name, diff_name, waves_cleared, total_waves, kills]
	_end_next_btn.visible = (victory and has_next_sector)
	if (not victory) and not secret_event.is_empty():
		_secret_map_id = String(secret_event["map_id"])
		_end_secret_btn.text = "★ %s ★" % String(secret_event["title"])
		_end_secret_btn.visible = true
	else:
		_secret_map_id = ""
		_end_secret_btn.visible = false

func show_wave_banner(text: String) -> void:
	_banner_label.text = text
	_banner_panel.visible = true
	_banner_panel.modulate.a = 1.0
	_banner_timer = 3.2

func update_top_bar(sector_name: String, cash: int, lives: int, max_lives: int, wave_num: int, total_waves: int, diff_cfg: Dictionary, paused: bool, speed: float, muted: bool) -> void:
	_sector_label.text = sector_name
	_cash_label.text = "$ %d" % cash
	_lives_label.text = "HQ %d / %d" % [lives, max_lives]
	if lives <= max_lives * 0.3:
		_lives_label.add_theme_color_override("font_color", COL_RED)
	elif lives <= max_lives * 0.6:
		_lives_label.add_theme_color_override("font_color", COL_AMBER)
	else:
		_lives_label.add_theme_color_override("font_color", COL_GREEN)

	_wave_label.text = "WAVE %d / %d" % [wave_num, total_waves]
	_diff_label.text = "[%s]" % String(diff_cfg["name"])
	_diff_label.add_theme_color_override("font_color", diff_cfg["accent"])

	_pause_btn.text = ">" if paused else "||"
	_style_button_cached(_pause_btn, "paused" if paused else "run", COL_AMBER if paused else COL_BORDER)
	_mute_btn.text = "MUTE" if muted else "SFX"
	_style_button_cached(_mute_btn, "muted" if muted else "unmuted", COL_RED if muted else COL_BORDER)

	for spd_key in _speed_btns.keys():
		var btn: Button = _speed_btns[spd_key]
		var active := is_equal_approx(float(spd_key), speed) and not paused
		_style_button_cached(
			btn,
			"on" if active else "off",
			COL_GREEN if active else COL_BORDER,
			Color(0.12, 0.22, 0.14, 0.96) if active else Color(0.10, 0.12, 0.11, 0.95)
		)

func update_dock(cash: int, placing_type: Variant, airstrike_cd: float, airstrike_max_cd: float, airstrike_aiming: bool, can_call_next: bool, next_wave_num: int, early_bonus: int, all_launched: bool) -> void:
	for t_type in _turret_btns.keys():
		var btn: Button = _turret_btns[t_type]
		var cfg := TurretData.get_config(t_type)
		var cost: int = int(cfg["base_cost"])
		var affordable := cash >= cost
		var selected: bool = (placing_type != null and placing_type == t_type)
		if selected:
			_style_button_cached(btn, "sel", Color.WHITE, Color(0.18, 0.26, 0.18, 0.98), COL_TEXT)
		elif affordable:
			_style_button_cached(btn, "ok", cfg["accent"], Color(0.11, 0.14, 0.12, 0.95), COL_TEXT)
		else:
			_style_button_cached(btn, "poor", Color(0.28, 0.24, 0.22), Color(0.09, 0.09, 0.09, 0.85), Color(0.55, 0.45, 0.42))

	if airstrike_cd <= 0.0:
		_airstrike_btn.disabled = false
		_airstrike_bar.visible = false
		_airstrike_bar.value = 100.0
		_airstrike_btn.text = "[Q] AIMING...\nCLICK MAP" if airstrike_aiming else "[Q] AIR STRIKE\nREADY"
		_style_button_cached(
			_airstrike_btn,
			"aim" if airstrike_aiming else "ready",
			Color.WHITE if airstrike_aiming else COL_RED,
			Color(0.36, 0.14, 0.10, 0.98) if airstrike_aiming else Color(0.22, 0.10, 0.08, 0.95)
		)
	else:
		_airstrike_btn.disabled = true
		var pct := clampf((1.0 - airstrike_cd / maxf(1.0, airstrike_max_cd)) * 100.0, 0.0, 100.0)
		_airstrike_bar.visible = true
		_airstrike_bar.value = pct
		_airstrike_btn.text = "[Q] AIR STRIKE\nCD %ds" % int(ceil(airstrike_cd))
		_style_button_cached(_airstrike_btn, "cd", COL_RED, Color(0.18, 0.09, 0.08, 0.90))

	if all_launched:
		_next_wave_btn.disabled = true
		_next_wave_btn.text = "FINAL WAVE\nACTIVE"
	elif can_call_next:
		_next_wave_btn.disabled = false
		if early_bonus > 0:
			_next_wave_btn.text = "[N] WAVE %d\nEARLY +$%d" % [next_wave_num, early_bonus]
		else:
			_next_wave_btn.text = "[N] LAUNCH\nWAVE %d" % next_wave_num
	else:
		_next_wave_btn.disabled = true
		_next_wave_btn.text = "WAVE %d\nINBOUND" % (next_wave_num - 1)

func update_inspector(turret: Turret, cash: int) -> void:
	if turret == null or not is_instance_valid(turret):
		_inspector_panel.visible = false
		return
	_inspector_panel.visible = true
	var cfg := turret.config
	var st := turret.get_stats()
	_insp_title.text = "%s  •  LV %d/4   |   KILLS: %d" % [String(cfg["name"]), turret.level + 1, turret.kills]

	var extra := ""
	if float(st["splash"]) > 0.0 and float(st["slow"]) > 0.0:
		extra = "  SLOW %d%%" % int(round(float(st["slow"]) * 100.0))
	elif float(st["splash"]) > 0.0:
		extra = "  AOE %d" % int(round(float(st["splash"])))
	_insp_stats.text = "DMG %.0f   RNG %.0f   ROF %.1f/s%s" % [
		float(st["damage"]),
		float(st["range"]),
		float(st["fire_rate"]),
		extra,
	]

	if turret.can_upgrade():
		var up_cost := turret.get_upgrade_cost()
		_insp_upgrade_btn.text = "UPGRADE ($%d)" % up_cost
		_insp_upgrade_btn.disabled = cash < up_cost
	else:
		_insp_upgrade_btn.text = "MAX LEVEL"
		_insp_upgrade_btn.disabled = true

	_insp_target_btn.text = "TGT: %s" % turret.get_target_mode_label()
	_insp_sell_btn.text = "SELL +$%d" % turret.get_sell_value()
