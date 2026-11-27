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
signal pause_menu_requested()
signal pause_menu_resumed()
signal mute_toggled()
signal audio_settings_changed(master_muted: bool, sfx_volume: float, sfx_muted: bool, music_volume: float, music_muted: bool)
signal avatar_style_changed(style: String)
signal reset_save_requested()
signal restart_requested()
signal replay_sector_requested()
signal upgrade_requested()
signal target_mode_requested()
signal sell_requested()
signal drone_hold_toggled()
signal drone_assign_requested()

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
var _insp_drone_row: HBoxContainer
var _insp_drone_hold_btn: Button
var _insp_drone_assign_btn: Button

var _banner_panel: PanelContainer
var _banner_label: Label
var _banner_timer: float = 0.0

const SECTORS_PER_PAGE: int = 8
const GAME_TITLE := "STATIONARY AUTOMATED WEAPON PLACEMENT ON SOVEREIGN TACTICAL BASTIONS FOR THE PREVENTION OF UNAUTHORIZED VEHICULAR AND AERIAL INCURSION INTO COMMAND HEADQUARTERS"

var _menu_overlay: ColorRect
var _menu_title: Label
var _menu_sub: Label
var _menu_brief: Label
var _menu_record_label: Label
var _menu_medals_btn: Button
var _menu_reset_btn: Button
var _selected_map_id: String = "iron_valley"
var _all_maps: Array[Dictionary] = []
var _sector_records: Dictionary = {}
var _sector_page: int = 0
var _sector_page_count: int = 1
var _sector_grid: GridContainer
var _sector_page_label: Label
var _sector_prev_btn: Button
var _sector_next_btn: Button
var _sector_page_btns: Array[Button] = []
var _sector_btns: Dictionary = {}
var _selected_diff: WaveData.Difficulty = WaveData.Difficulty.NORMAL
var _diff_btns: Dictionary = {}

# Next-wave preview strip
var _wave_preview_panel: PanelContainer
var _preview_wave_lbl: Label
var _preview_tags_box: HBoxContainer
var _preview_units_lbl: Label
var _last_preview_key: String = ""

# Pause & Audio overlays
var _pause_overlay: ColorRect
var _pause_sub: Label
var _pause_medals_btn: Button
var _pause_restart_btn: Button
var _pause_briefing_btn: Button
var _audio_overlay: ColorRect

# Hall of Decorations (North Korean General) overlay & award toast
var _medals_overlay: ColorRect
var _general_view: GeneralMedalsView
var _avatar_male_btn: Button
var _avatar_female_btn: Button
var _avatar_style: String = "male"
var _medals_count_lbl: Label
var _medals_weight_lbl: Label
var _about_overlay: ColorRect
var _about_dossier_btn: Button
var _about_manual_btn: Button
var _about_dossier_scroll: ScrollContainer
var _about_manual_scroll: ScrollContainer
var _medal_detail_panel: PanelContainer
var _medal_detail_title: Label
var _medal_detail_meta: Label
var _medal_detail_desc: Label
var _medal_detail_citation: Label
var _medal_list_box: VBoxContainer
var _medal_list_btns: Dictionary = {}
var _unlocked_medals: Array[String] = []
var _career_stats: Dictionary = {}
var _selected_medal_id: String = ""

var _medal_toast_panel: PanelContainer
var _medal_toast_title: Label
var _medal_toast_body: Label
var _medal_toast_queue: Array[String] = []
var _medal_toast_timer: float = 0.0
var _audio_control_sets: Array[Dictionary] = []
var _syncing_audio_ui: bool = false
var _audio_master_muted: bool = false
var _audio_sfx_vol: float = 0.85
var _audio_sfx_muted: bool = false
var _audio_music_vol: float = 0.50
var _audio_music_muted: bool = false

# 2-click confirmation timers (real seconds)
var _confirm_restart_timer: float = 0.0
var _confirm_briefing_timer: float = 0.0
var _confirm_reset_save_timer: float = 0.0

var _end_overlay: ColorRect
var _end_title: Label
var _end_rank_panel: PanelContainer
var _end_rank_header: Label
var _end_rank_title: Label
var _end_new_best_lbl: Label
var _end_summary: Label
var _end_next_btn: Button
var _end_secret_btn: Button
var _secret_map_id: String = ""
var _btn_style_cache: Dictionary = {}

func _ready() -> void:
	layer = 10
	_build_ui()

func _process(delta: float) -> void:
	var real_delta: float = delta / maxf(0.01, Engine.time_scale)
	if _banner_timer > 0.0:
		_banner_timer -= real_delta
		if _banner_timer <= 0.6:
			_banner_panel.modulate.a = clampf(_banner_timer / 0.6, 0.0, 1.0)
		if _banner_timer <= 0.0:
			_banner_panel.visible = false

	if _confirm_restart_timer > 0.0:
		_confirm_restart_timer -= real_delta
		if _confirm_restart_timer <= 0.0:
			_reset_pause_confirms()

	if _confirm_briefing_timer > 0.0:
		_confirm_briefing_timer -= real_delta
		if _confirm_briefing_timer <= 0.0:
			_reset_pause_confirms()

	if _confirm_reset_save_timer > 0.0:
		_confirm_reset_save_timer -= real_delta
		if _confirm_reset_save_timer <= 0.0:
			_reset_save_confirm_btn()

	# Medal awarded toast queue
	if _medal_toast_timer > 0.0:
		_medal_toast_timer -= real_delta
		if _medal_toast_timer <= 0.5:
			_medal_toast_panel.modulate.a = clampf(_medal_toast_timer / 0.5, 0.0, 1.0)
		if _medal_toast_timer <= 0.0:
			_medal_toast_panel.visible = false
	elif not _medal_toast_queue.is_empty():
		var next_id: String = _medal_toast_queue.pop_front()
		var def := MedalData.get_medal_by_id(next_id)
		if not def.is_empty():
			var mcol: Color = def.get("metal", COL_AMBER)
			_medal_toast_panel.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.10, 0.08, 0.96), mcol, 5, 2, 14, 8))
			_medal_toast_title.text = "★ DECORATION AWARDED ★"
			_medal_toast_title.add_theme_color_override("font_color", mcol)
			_medal_toast_body.text = "%s  (+%dg to General's chest)" % [String(def["name"]), int(def.get("weight_g", 250))]
			_medal_toast_panel.visible = true
			_medal_toast_panel.modulate.a = 1.0
			_medal_toast_timer = 4.2

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

func _style_button_cached(btn: Button, state_key: String, accent: Color = COL_BORDER, bg: Color = Color(0.12, 0.15, 0.13, 0.95), font_col: Color = COL_TEXT, pad_x: int = 10, pad_y: int = 6) -> void:
	if _btn_style_cache.get(btn, "") == state_key:
		return
	_btn_style_cache[btn] = state_key
	_style_button(btn, accent, bg, pad_x, pad_y)
	btn.add_theme_color_override("font_color", font_col)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_top_bar()
	_build_wave_banner()
	_build_wave_preview()
	_build_bottom_dock()
	_build_inspector()
	_build_pause_overlay()
	_build_menu_overlay()
	_build_audio_overlay()
	_build_end_overlay()
	_build_medals_overlay()
	_build_about_overlay()
	_build_medal_toast()

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
	_mute_btn.text = "AUDIO"
	_mute_btn.custom_minimum_size = Vector2(58, 28)
	_style_button(_mute_btn)
	_mute_btn.pressed.connect(func(): mute_toggled.emit())
	hbox.add_child(_mute_btn)

	var menu_btn := Button.new()
	menu_btn.text = "MENU"
	menu_btn.custom_minimum_size = Vector2(58, 28)
	_style_button(menu_btn, Color(0.55, 0.45, 0.28))
	menu_btn.pressed.connect(func(): pause_menu_requested.emit())
	hbox.add_child(menu_btn)

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
	dock.add_theme_stylebox_override("panel", _make_box(COL_BG, COL_BORDER, 5, 1, 6, 7))
	_root.add_child(dock)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	dock.add_child(hbox)

	for t_type in TurretData.get_all_types():
		var cfg := TurretData.get_config(t_type)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(86, 66)
		btn.text = "[%s] %s\n$%d\n%s" % [cfg["hotkey"], cfg["short"], int(cfg["base_cost"]), cfg["role"]]
		btn.add_theme_font_size_override("font_size", 10)
		_style_button(btn, cfg["accent"], Color(0.12, 0.15, 0.13, 0.95), 4, 3)
		btn.pressed.connect(func(): turret_card_selected.emit(t_type))
		hbox.add_child(btn)
		_turret_btns[t_type] = btn

	var sep := VSeparator.new()
	hbox.add_child(sep)

	# Hellfire Air Strike slot — matches adjacent card height flush, with integrated cooldown strip
	_airstrike_btn = Button.new()
	_airstrike_btn.custom_minimum_size = Vector2(96, 66)
	_airstrike_btn.text = "[Q] AIR STRIKE\nREADY"
	_airstrike_btn.add_theme_font_size_override("font_size", 10)
	_style_button(_airstrike_btn, COL_RED, Color(0.22, 0.10, 0.08, 0.95), 5, 4)
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
	_next_wave_btn.custom_minimum_size = Vector2(94, 66)
	_next_wave_btn.text = "[N] START\nWAVE 1"
	_next_wave_btn.add_theme_font_size_override("font_size", 10)
	_style_button(_next_wave_btn, COL_GREEN, Color(0.10, 0.20, 0.12, 0.95), 5, 4)
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

	# Drone Pad tactical command row (visible only when a Drone Pad is inspected)
	_insp_drone_row = HBoxContainer.new()
	_insp_drone_row.add_theme_constant_override("separation", 6)
	_insp_drone_row.visible = false
	vbox.add_child(_insp_drone_row)

	_insp_drone_hold_btn = Button.new()
	_insp_drone_hold_btn.custom_minimum_size = Vector2(124, 24)
	_insp_drone_hold_btn.add_theme_font_size_override("font_size", 11)
	_style_button(_insp_drone_hold_btn, COL_AMBER, Color(0.12, 0.15, 0.13, 0.95), 8, 3)
	_insp_drone_hold_btn.pressed.connect(func(): drone_hold_toggled.emit())
	_insp_drone_row.add_child(_insp_drone_hold_btn)

	_insp_drone_assign_btn = Button.new()
	_insp_drone_assign_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_insp_drone_assign_btn.custom_minimum_size = Vector2(0, 24)
	_insp_drone_assign_btn.add_theme_font_size_override("font_size", 11)
	_style_button(_insp_drone_assign_btn, Color(0.56, 0.90, 0.30), Color(0.12, 0.22, 0.12, 0.95), 8, 3)
	_insp_drone_assign_btn.pressed.connect(func(): drone_assign_requested.emit())
	_insp_drone_row.add_child(_insp_drone_assign_btn)

func _build_wave_preview() -> void:
	_wave_preview_panel = PanelContainer.new()
	_wave_preview_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_wave_preview_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_wave_preview_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_wave_preview_panel.offset_left = 10
	_wave_preview_panel.offset_right = 10
	_wave_preview_panel.offset_top = -124
	_wave_preview_panel.offset_bottom = -96
	_wave_preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_preview_panel.add_theme_stylebox_override("panel", _make_box(Color(0.07, 0.09, 0.08, 0.88), COL_BORDER, 4, 1, 10, 4))
	_wave_preview_panel.visible = false
	_root.add_child(_wave_preview_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_preview_panel.add_child(hbox)

	_preview_wave_lbl = Label.new()
	_preview_wave_lbl.add_theme_font_size_override("font_size", 11)
	_preview_wave_lbl.add_theme_color_override("font_color", COL_AMBER)
	_preview_wave_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_preview_wave_lbl)

	_preview_tags_box = HBoxContainer.new()
	_preview_tags_box.add_theme_constant_override("separation", 4)
	_preview_tags_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_preview_tags_box)

	_preview_units_lbl = Label.new()
	_preview_units_lbl.add_theme_font_size_override("font_size", 11)
	_preview_units_lbl.add_theme_color_override("font_color", COL_TEXT)
	_preview_units_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_preview_units_lbl)

func _build_audio_controls(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "AUDIO CONTROLS"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", COL_AMBER)
	parent.add_child(title)

	# SFX Row
	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 8)
	parent.add_child(sfx_row)

	var sfx_lbl := Label.new()
	sfx_lbl.text = "SFX"
	sfx_lbl.custom_minimum_size = Vector2(54, 0)
	sfx_lbl.add_theme_font_size_override("font_size", 12)
	sfx_lbl.add_theme_color_override("font_color", COL_TEXT)
	sfx_row.add_child(sfx_lbl)

	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0
	sfx_slider.value = round(_audio_sfx_vol * 100.0)
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sfx_slider.focus_mode = Control.FOCUS_NONE
	sfx_row.add_child(sfx_slider)

	var sfx_pct := Label.new()
	sfx_pct.text = "%d%%" % int(round(_audio_sfx_vol * 100.0))
	sfx_pct.custom_minimum_size = Vector2(40, 0)
	sfx_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sfx_pct.add_theme_font_size_override("font_size", 12)
	sfx_pct.add_theme_color_override("font_color", COL_MUTED)
	sfx_row.add_child(sfx_pct)

	var sfx_mute_btn := Button.new()
	sfx_mute_btn.text = "ON"
	sfx_mute_btn.custom_minimum_size = Vector2(54, 26)
	sfx_mute_btn.add_theme_font_size_override("font_size", 11)
	_style_button(sfx_mute_btn, COL_GREEN, Color(0.11, 0.19, 0.12, 0.95), 6, 2)
	sfx_row.add_child(sfx_mute_btn)

	# MUSIC Row
	var mus_row := HBoxContainer.new()
	mus_row.add_theme_constant_override("separation", 8)
	parent.add_child(mus_row)

	var mus_lbl := Label.new()
	mus_lbl.text = "MUSIC"
	mus_lbl.custom_minimum_size = Vector2(54, 0)
	mus_lbl.add_theme_font_size_override("font_size", 12)
	mus_lbl.add_theme_color_override("font_color", COL_TEXT)
	mus_row.add_child(mus_lbl)

	var mus_slider := HSlider.new()
	mus_slider.min_value = 0.0
	mus_slider.max_value = 110.0
	mus_slider.step = 1.0
	mus_slider.value = round(_audio_music_vol * 100.0)
	mus_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mus_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mus_slider.focus_mode = Control.FOCUS_NONE
	mus_row.add_child(mus_slider)

	var mus_pct := Label.new()
	mus_pct.text = "%d%%" % int(round(_audio_music_vol * 100.0))
	mus_pct.custom_minimum_size = Vector2(44, 0)
	mus_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mus_pct.add_theme_font_size_override("font_size", 12)
	mus_pct.add_theme_color_override("font_color", COL_MUTED)
	mus_row.add_child(mus_pct)

	var mus_mute_btn := Button.new()
	mus_mute_btn.text = "ON"
	mus_mute_btn.custom_minimum_size = Vector2(54, 26)
	mus_mute_btn.add_theme_font_size_override("font_size", 11)
	_style_button(mus_mute_btn, COL_GREEN, Color(0.11, 0.19, 0.12, 0.95), 6, 2)
	mus_row.add_child(mus_mute_btn)

	sfx_slider.value_changed.connect(func(v: float):
		if _syncing_audio_ui:
			return
		_audio_sfx_vol = clampf(v / 100.0, 0.0, 1.0)
		if _audio_sfx_vol > 0.0 and _audio_sfx_muted:
			_audio_sfx_muted = false
		_sync_audio_ui_controls()
		_emit_audio_changed()
	)
	sfx_mute_btn.pressed.connect(func():
		_audio_sfx_muted = not _audio_sfx_muted
		_sync_audio_ui_controls()
		_emit_audio_changed()
	)
	mus_slider.value_changed.connect(func(v: float):
		if _syncing_audio_ui:
			return
		_audio_music_vol = clampf(v / 100.0, 0.0, 1.10)
		if _audio_music_vol > 0.0 and _audio_music_muted:
			_audio_music_muted = false
		_sync_audio_ui_controls()
		_emit_audio_changed()
	)
	mus_mute_btn.pressed.connect(func():
		_audio_music_muted = not _audio_music_muted
		_sync_audio_ui_controls()
		_emit_audio_changed()
	)

	_audio_control_sets.append({
		"sfx_slider": sfx_slider,
		"sfx_pct": sfx_pct,
		"sfx_mute_btn": sfx_mute_btn,
		"mus_slider": mus_slider,
		"mus_pct": mus_pct,
		"mus_mute_btn": mus_mute_btn,
	})

func _emit_audio_changed() -> void:
	audio_settings_changed.emit(_audio_master_muted, _audio_sfx_vol, _audio_sfx_muted, _audio_music_vol, _audio_music_muted)

func set_audio_state(master_muted: bool, sfx_vol: float, sfx_muted: bool, music_vol: float, music_muted: bool) -> void:
	_audio_master_muted = master_muted
	_audio_sfx_vol = clampf(sfx_vol, 0.0, 1.0)
	_audio_sfx_muted = sfx_muted
	_audio_music_vol = clampf(music_vol, 0.0, 1.10)
	_audio_music_muted = music_muted
	_sync_audio_ui_controls()

func _sync_audio_ui_controls() -> void:
	_syncing_audio_ui = true
	for s in _audio_control_sets:
		var sfx_slider: HSlider = s["sfx_slider"]
		var sfx_pct: Label = s["sfx_pct"]
		var sfx_btn: Button = s["sfx_mute_btn"]
		var mus_slider: HSlider = s["mus_slider"]
		var mus_pct: Label = s["mus_pct"]
		var mus_btn: Button = s["mus_mute_btn"]

		sfx_slider.value = round(_audio_sfx_vol * 100.0)
		sfx_pct.text = "%d%%" % int(round(_audio_sfx_vol * 100.0))
		sfx_btn.text = "MUTE" if _audio_sfx_muted else "ON"
		_style_button(
			sfx_btn,
			COL_RED if _audio_sfx_muted else COL_GREEN,
			Color(0.24, 0.10, 0.09, 0.95) if _audio_sfx_muted else Color(0.11, 0.19, 0.12, 0.95),
			6, 2
		)

		var mus_pct_val: int = int(round(_audio_music_vol * 100.0))
		mus_slider.value = float(mus_pct_val)
		mus_pct.text = "%d%%" % mus_pct_val
		mus_btn.text = "MUTE" if _audio_music_muted else "ON"
		_style_button(
			mus_btn,
			COL_RED if _audio_music_muted else COL_GREEN,
			Color(0.24, 0.10, 0.09, 0.95) if _audio_music_muted else Color(0.11, 0.19, 0.12, 0.95),
			6, 2
		)
	_syncing_audio_ui = false

func _build_pause_overlay() -> void:
	_pause_overlay = ColorRect.new()
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.color = Color(0.02, 0.03, 0.02, 0.78)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_overlay.visible = false
	_root.add_child(_pause_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(440, 330)
	card.add_theme_stylebox_override("panel", _make_box(COL_BG_DARK, COL_AMBER, 6, 2, 24, 20))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "TACTICAL PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", COL_AMBER)
	vbox.add_child(title)

	_pause_sub = Label.new()
	_pause_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_sub.add_theme_font_size_override("font_size", 12)
	_pause_sub.add_theme_color_override("font_color", COL_MUTED)
	vbox.add_child(_pause_sub)

	vbox.add_child(HSeparator.new())
	_build_audio_controls(vbox)
	vbox.add_child(HSeparator.new())

	var resume_btn := Button.new()
	resume_btn.text = "RESUME MISSION  [ESC]"
	resume_btn.custom_minimum_size = Vector2(0, 42)
	resume_btn.add_theme_font_size_override("font_size", 14)
	_style_button(resume_btn, COL_GREEN, Color(0.11, 0.24, 0.13, 0.98))
	resume_btn.pressed.connect(func():
		hide_pause_menu()
		pause_menu_resumed.emit()
	)
	vbox.add_child(resume_btn)

	_pause_medals_btn = Button.new()
	_pause_medals_btn.text = "★ DECORATIONS (0/36)"
	_pause_medals_btn.custom_minimum_size = Vector2(0, 36)
	_pause_medals_btn.add_theme_font_size_override("font_size", 13)
	_style_button(_pause_medals_btn, COL_AMBER, Color(0.16, 0.14, 0.09, 0.96))
	_pause_medals_btn.pressed.connect(func(): show_medals_hall())
	vbox.add_child(_pause_medals_btn)

	_pause_restart_btn = Button.new()
	_pause_restart_btn.text = "RESTART SECTOR"
	_pause_restart_btn.custom_minimum_size = Vector2(0, 38)
	_pause_restart_btn.add_theme_font_size_override("font_size", 13)
	_style_button(_pause_restart_btn, COL_AMBER, Color(0.18, 0.15, 0.10, 0.96))
	_pause_restart_btn.pressed.connect(_on_pause_restart_clicked)
	vbox.add_child(_pause_restart_btn)

	_pause_briefing_btn = Button.new()
	_pause_briefing_btn.text = "RETURN TO BRIEFING"
	_pause_briefing_btn.custom_minimum_size = Vector2(0, 38)
	_pause_briefing_btn.add_theme_font_size_override("font_size", 13)
	_style_button(_pause_briefing_btn, Color(0.65, 0.34, 0.30), Color(0.18, 0.10, 0.10, 0.95))
	_pause_briefing_btn.pressed.connect(_on_pause_briefing_clicked)
	vbox.add_child(_pause_briefing_btn)

func _on_pause_restart_clicked() -> void:
	if _confirm_restart_timer > 0.0:
		_reset_pause_confirms()
		hide_pause_menu()
		replay_sector_requested.emit()
	else:
		_reset_pause_confirms()
		_confirm_restart_timer = 3.5
		_pause_restart_btn.text = "CONFIRM RESTART SECTOR? (CLICK AGAIN)"
		_style_button(_pause_restart_btn, COL_RED, Color(0.34, 0.10, 0.09, 0.98))

func _on_pause_briefing_clicked() -> void:
	if _confirm_briefing_timer > 0.0:
		_reset_pause_confirms()
		hide_pause_menu()
		restart_requested.emit()
	else:
		_reset_pause_confirms()
		_confirm_briefing_timer = 3.5
		_pause_briefing_btn.text = "CONFIRM EXIT TO BRIEFING? (CLICK AGAIN)"
		_style_button(_pause_briefing_btn, COL_RED, Color(0.34, 0.10, 0.09, 0.98))

func _reset_pause_confirms() -> void:
	_confirm_restart_timer = 0.0
	_confirm_briefing_timer = 0.0
	if _pause_restart_btn != null:
		_pause_restart_btn.text = "RESTART SECTOR"
		_style_button(_pause_restart_btn, COL_AMBER, Color(0.18, 0.15, 0.10, 0.96))
	if _pause_briefing_btn != null:
		_pause_briefing_btn.text = "RETURN TO BRIEFING"
		_style_button(_pause_briefing_btn, Color(0.65, 0.34, 0.30), Color(0.18, 0.10, 0.10, 0.95))

func show_pause_menu(sector_name: String, diff_name: String) -> void:
	_reset_pause_confirms()
	_pause_sub.text = "%s  •  [%s]" % [sector_name, diff_name]
	_sync_audio_ui_controls()
	_pause_overlay.visible = true

func hide_pause_menu() -> void:
	_reset_pause_confirms()
	_pause_overlay.visible = false

func is_pause_menu_visible() -> bool:
	return _pause_overlay != null and _pause_overlay.visible

func _build_audio_overlay() -> void:
	_audio_overlay = ColorRect.new()
	_audio_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_audio_overlay.color = Color(0.02, 0.03, 0.02, 0.78)
	_audio_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_audio_overlay.visible = false
	_root.add_child(_audio_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_audio_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 210)
	card.add_theme_stylebox_override("panel", _make_box(COL_BG_DARK, COL_AMBER, 6, 2, 24, 20))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	_build_audio_controls(vbox)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 38)
	close_btn.add_theme_font_size_override("font_size", 13)
	_style_button(close_btn, COL_GREEN, Color(0.11, 0.24, 0.13, 0.98))
	close_btn.pressed.connect(func(): _audio_overlay.visible = false)
	vbox.add_child(close_btn)

func is_audio_overlay_visible() -> bool:
	return _audio_overlay != null and _audio_overlay.visible

func hide_audio_overlay() -> void:
	if _audio_overlay != null:
		_audio_overlay.visible = false

func _build_medal_toast() -> void:
	_medal_toast_panel = PanelContainer.new()
	_medal_toast_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_medal_toast_panel.offset_left = -370
	_medal_toast_panel.offset_right = -12
	_medal_toast_panel.offset_top = 60
	_medal_toast_panel.offset_bottom = 114
	_medal_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_medal_toast_panel.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.10, 0.08, 0.95), COL_AMBER, 5, 2, 14, 8))
	_medal_toast_panel.visible = false
	_root.add_child(_medal_toast_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_medal_toast_panel.add_child(vbox)

	_medal_toast_title = Label.new()
	_medal_toast_title.add_theme_font_size_override("font_size", 12)
	_medal_toast_title.add_theme_color_override("font_color", COL_AMBER)
	vbox.add_child(_medal_toast_title)

	_medal_toast_body = Label.new()
	_medal_toast_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_medal_toast_body.add_theme_font_size_override("font_size", 11)
	_medal_toast_body.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_medal_toast_body)

func queue_medal_toasts(medal_ids: Array[String]) -> void:
	for mid in medal_ids:
		_medal_toast_queue.append(mid)

func _build_medals_overlay() -> void:
	_medals_overlay = ColorRect.new()
	_medals_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_medals_overlay.color = Color(0.02, 0.03, 0.02, 0.85)
	_medals_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_medals_overlay.visible = false
	_root.add_child(_medals_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_medals_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(960, 590)
	card.add_theme_stylebox_override("panel", _make_box(COL_BG_DARK, COL_AMBER, 6, 2, 20, 16))
	center.add_child(card)

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 10)
	card.add_child(root_v)

	# Header bar
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	root_v.add_child(hdr)

	var title := Label.new()
	title.text = "HALL OF SOVEREIGN DECORATIONS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COL_AMBER)
	hdr.add_child(title)

	var av_lbl := Label.new()
	av_lbl.text = "GENERAL:"
	av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av_lbl.add_theme_font_size_override("font_size", 11)
	av_lbl.add_theme_color_override("font_color", COL_MUTED)
	hdr.add_child(av_lbl)

	_avatar_male_btn = Button.new()
	_avatar_male_btn.text = "MALE"
	_avatar_male_btn.custom_minimum_size = Vector2(68, 28)
	_avatar_male_btn.add_theme_font_size_override("font_size", 11)
	_avatar_male_btn.pressed.connect(func(): _on_avatar_style_clicked("male"))
	hdr.add_child(_avatar_male_btn)

	_avatar_female_btn = Button.new()
	_avatar_female_btn.text = "FEMALE"
	_avatar_female_btn.custom_minimum_size = Vector2(74, 28)
	_avatar_female_btn.add_theme_font_size_override("font_size", 11)
	_avatar_female_btn.pressed.connect(func(): _on_avatar_style_clicked("female"))
	hdr.add_child(_avatar_female_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE  [ESC]"
	close_btn.custom_minimum_size = Vector2(108, 30)
	close_btn.add_theme_font_size_override("font_size", 12)
	_style_button(close_btn, COL_AMBER, Color(0.16, 0.14, 0.09, 0.96), 8, 3)
	close_btn.pressed.connect(func(): hide_medals_hall())
	hdr.add_child(close_btn)

	# Main 2-column showcase
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	root_v.add_child(cols)

	# Left column: The Sovereign General portrait + weight readout
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(410, 0)
	left_col.add_theme_constant_override("separation", 6)
	cols.add_child(left_col)

	_general_view = GeneralMedalsView.new()
	_general_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_general_view.custom_minimum_size = Vector2(410, 456)
	_general_view.medal_selected.connect(_on_medal_selected)
	left_col.add_child(_general_view)

	_medals_count_lbl = Label.new()
	_medals_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_medals_count_lbl.add_theme_font_size_override("font_size", 13)
	_medals_count_lbl.add_theme_color_override("font_color", COL_AMBER)
	left_col.add_child(_medals_count_lbl)

	_medals_weight_lbl = Label.new()
	_medals_weight_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_medals_weight_lbl.add_theme_font_size_override("font_size", 11)
	_medals_weight_lbl.add_theme_color_override("font_color", COL_MUTED)
	left_col.add_child(_medals_weight_lbl)

	# Right column: Selected Decoration Citation Plaque + Scrollable Directory
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 8)
	cols.add_child(right_col)

	_medal_detail_panel = PanelContainer.new()
	_medal_detail_panel.custom_minimum_size = Vector2(0, 126)
	_medal_detail_panel.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.10, 0.08, 0.96), COL_AMBER, 5, 1, 14, 10))
	right_col.add_child(_medal_detail_panel)

	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 4)
	_medal_detail_panel.add_child(dbox)

	_medal_detail_title = Label.new()
	_medal_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_medal_detail_title.add_theme_font_size_override("font_size", 15)
	_medal_detail_title.add_theme_color_override("font_color", COL_AMBER)
	dbox.add_child(_medal_detail_title)

	_medal_detail_meta = Label.new()
	_medal_detail_meta.add_theme_font_size_override("font_size", 11)
	_medal_detail_meta.add_theme_color_override("font_color", COL_GREEN)
	dbox.add_child(_medal_detail_meta)

	_medal_detail_desc = Label.new()
	_medal_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_medal_detail_desc.add_theme_font_size_override("font_size", 12)
	_medal_detail_desc.add_theme_color_override("font_color", COL_TEXT)
	dbox.add_child(_medal_detail_desc)

	_medal_detail_citation = Label.new()
	_medal_detail_citation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_medal_detail_citation.add_theme_font_size_override("font_size", 11)
	_medal_detail_citation.add_theme_color_override("font_color", COL_MUTED)
	dbox.add_child(_medal_detail_citation)

	var dir_lbl := Label.new()
	dir_lbl.text = "ALL 36 DECORATIONS  (CLICK ANY MEDAL ON THE GENERAL OR BELOW TO INSPECT)"
	dir_lbl.add_theme_font_size_override("font_size", 10)
	dir_lbl.add_theme_color_override("font_color", COL_MUTED)
	right_col.add_child(dir_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_col.add_child(scroll)

	_medal_list_box = VBoxContainer.new()
	_medal_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_medal_list_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_medal_list_box)

	for m in MedalData.get_all_medals():
		var mid: String = String(m["id"])
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 28)
		btn.add_theme_font_size_override("font_size", 11)
		_style_button(btn, COL_BORDER, Color(0.10, 0.12, 0.10, 0.94), 10, 3)
		btn.pressed.connect(func(): _on_medal_selected(mid))
		_medal_list_box.add_child(btn)
		_medal_list_btns[mid] = btn

func set_medals_data(unlocked: Array[String], stats: Dictionary, sector_records: Dictionary) -> void:
	_unlocked_medals = unlocked.duplicate()
	_career_stats = stats.duplicate(true)
	_sector_records = sector_records.duplicate(true)
	var total := MedalData.get_all_medals().size()
	var cnt := _unlocked_medals.size()
	if _menu_medals_btn != null:
		_menu_medals_btn.text = "★ MEDALS (%d/%d)" % [cnt, total]
	if _pause_medals_btn != null:
		_pause_medals_btn.text = "★ DECORATIONS (%d/%d)" % [cnt, total]
	if _medals_overlay != null and _medals_overlay.visible:
		_refresh_medals_hall()

func show_medals_hall() -> void:
	if _selected_medal_id == "":
		if not _unlocked_medals.is_empty():
			_selected_medal_id = _unlocked_medals[_unlocked_medals.size() - 1]
		else:
			_selected_medal_id = String(MedalData.get_all_medals()[0]["id"])
	_refresh_medals_hall()
	_medals_overlay.visible = true

func hide_medals_hall() -> void:
	if _medals_overlay != null:
		_medals_overlay.visible = false

func is_medals_hall_visible() -> bool:
	return _medals_overlay != null and _medals_overlay.visible

func _on_medal_selected(medal_id: String) -> void:
	_selected_medal_id = medal_id
	_general_view.set_selected_medal(medal_id)
	_refresh_medal_detail()
	_refresh_medal_list_styles()

func set_general_avatar(style: String) -> void:
	_avatar_style = "female" if style == "female" else "male"
	if _general_view != null:
		_general_view.set_avatar_style(_avatar_style)
	_refresh_avatar_toggle_btns()
	if _medals_overlay != null and _medals_overlay.visible:
		_refresh_medals_hall()

func _on_avatar_style_clicked(style: String) -> void:
	if _avatar_style == style:
		return
	set_general_avatar(style)
	avatar_style_changed.emit(_avatar_style)

func _refresh_avatar_toggle_btns() -> void:
	if _avatar_male_btn == null or _avatar_female_btn == null:
		return
	var is_f := (_avatar_style == "female")
	_style_button(_avatar_male_btn, COL_AMBER if not is_f else COL_BORDER, Color(0.20, 0.22, 0.14, 0.98) if not is_f else Color(0.10, 0.12, 0.11, 0.92), 8, 2)
	_style_button(_avatar_female_btn, COL_AMBER if is_f else COL_BORDER, Color(0.20, 0.22, 0.14, 0.98) if is_f else Color(0.10, 0.12, 0.11, 0.92), 8, 2)

func _refresh_medals_hall() -> void:
	var all_medals := MedalData.get_all_medals()
	var cnt := _unlocked_medals.size()
	var total := all_medals.size()
	_general_view.set_avatar_style(_avatar_style)
	_general_view.set_medals(_unlocked_medals, _selected_medal_id)
	_refresh_avatar_toggle_btns()
	_medals_count_lbl.text = "DECORATIONS PINNED: %d / %d" % [cnt, total]

	var grams := 0
	for mid in _unlocked_medals:
		var d := MedalData.get_medal_by_id(mid)
		grams += int(d.get("weight_g", 250))
	var kg: float = float(grams) / 1000.0
	var advisory := "TRAGICALLY AERODYNAMIC"
	if cnt >= 35:
		advisory = "CAP-MOUNTED — GRAVITATIONAL ANOMALY"
	elif cnt >= 30:
		advisory = ("SKIRT-MOUNTED — FORKLIFT ADVISED" if _avatar_style == "female" else "TROUSER-MOUNTED — FORKLIFT ADVISED")
	elif cnt >= 24:
		advisory = "SLEEVE OVERFLOW — SPINAL WARNING"
	elif cnt >= 16:
		advisory = "DUAL-CHEST ARMOR — TAILOR WEEPING"
	elif cnt >= 8:
		advisory = "HEAVILY DECORATED — MILD SWAGGER"
	elif cnt >= 1:
		advisory = "REGULATION POLISH — ROOM FOR MORE"
	_medals_weight_lbl.text = "UNIFORM HARDWARE: %.1f kg  •  %s" % [kg, advisory]

	for m in all_medals:
		var mid: String = String(m["id"])
		var btn: Button = _medal_list_btns[mid]
		var earned: bool = _unlocked_medals.has(mid)
		var prog := MedalData.get_progress(mid, _career_stats, _sector_records)
		var badge := "★" if earned else "○"
		var status := "EARNED" if earned else String(prog["label"])
		btn.text = "%s  [%s]  %s   —   %s" % [badge, String(m["category"]), String(m["name"]), status]

	_refresh_medal_detail()
	_refresh_medal_list_styles()

func _refresh_medal_list_styles() -> void:
	for m in MedalData.get_all_medals():
		var mid: String = String(m["id"])
		var btn: Button = _medal_list_btns[mid]
		var earned: bool = _unlocked_medals.has(mid)
		var is_sel: bool = (mid == _selected_medal_id)
		var mcol: Color = m.get("metal", COL_AMBER)
		if is_sel:
			_style_button(btn, Color.WHITE, Color(0.18, 0.22, 0.16, 0.98), 10, 3)
			btn.add_theme_color_override("font_color", Color.WHITE)
		elif earned:
			_style_button(btn, mcol.darkened(0.25), Color(0.12, 0.15, 0.11, 0.96), 10, 3)
			btn.add_theme_color_override("font_color", mcol.lightened(0.15))
		else:
			_style_button(btn, Color(0.22, 0.24, 0.22), Color(0.08, 0.09, 0.08, 0.90), 10, 3)
			btn.add_theme_color_override("font_color", COL_MUTED)

func _refresh_medal_detail() -> void:
	var def := MedalData.get_medal_by_id(_selected_medal_id)
	if def.is_empty():
		return
	var earned: bool = _unlocked_medals.has(_selected_medal_id)
	var prog := MedalData.get_progress(_selected_medal_id, _career_stats, _sector_records)
	var mcol: Color = def.get("metal", COL_AMBER)
	_medal_detail_panel.add_theme_stylebox_override(
		"panel",
		_make_box(Color(0.09, 0.11, 0.09, 0.97), mcol if earned else COL_BORDER, 5, 2 if earned else 1, 14, 10)
	)
	_medal_detail_title.text = "%s %s" % ["★" if earned else "○", String(def["name"])]
	_medal_detail_title.add_theme_color_override("font_color", mcol if earned else COL_TEXT)
	var slot_note := ""
	if earned:
		var slot_idx := _unlocked_medals.find(_selected_medal_id)
		if slot_idx >= 34:
			slot_note = "  •  PINNED ON PEAKED CAP"
		elif slot_idx >= 30:
			slot_note = "  •  PINNED ON DRESS SKIRT" if _avatar_style == "female" else "  •  PINNED ON TROUSERS"
		elif slot_idx >= 26:
			slot_note = "  •  PINNED ON SLEEVE"
		elif slot_idx >= 22:
			slot_note = "  •  PINNED ON SASH"
		elif slot_idx >= 16:
			slot_note = "  •  LOWER TORSO"
		elif slot_idx >= 8:
			slot_note = "  •  RIGHT CHEST"
		else:
			slot_note = "  •  LEFT CHEST"
	_medal_detail_meta.text = "%s  •  %s  •  %dg HARDWARE%s" % [
		String(def["category"]),
		"EARNED" if earned else ("PROGRESS: " + String(prog["label"])),
		int(def.get("weight_g", 250)),
		slot_note,
	]
	_medal_detail_meta.add_theme_color_override("font_color", COL_GREEN if earned else COL_AMBER)
	_medal_detail_desc.text = "Requirement: %s" % String(def["desc"])
	_medal_detail_citation.text = "\"%s\"" % String(def["citation"])

func _build_about_overlay() -> void:
	_about_overlay = ColorRect.new()
	_about_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_about_overlay.color = Color(0.02, 0.03, 0.02, 0.85)
	_about_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_about_overlay.visible = false
	_root.add_child(_about_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_about_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(760, 540)
	card.add_theme_stylebox_override("panel", _make_box(COL_BG_DARK, COL_AMBER, 6, 2, 24, 18))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vbox.add_child(hdr)

	var title := Label.new()
	title.text = "OFFICIAL STRATEGIC DOSSIER & FIELD MANUAL"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", COL_AMBER)
	hdr.add_child(title)

	_about_dossier_btn = Button.new()
	_about_dossier_btn.text = "DOSSIER"
	_about_dossier_btn.custom_minimum_size = Vector2(88, 28)
	_about_dossier_btn.add_theme_font_size_override("font_size", 11)
	_about_dossier_btn.pressed.connect(func(): _set_about_tab(0))
	hdr.add_child(_about_dossier_btn)

	_about_manual_btn = Button.new()
	_about_manual_btn.text = "FIELD MANUAL"
	_about_manual_btn.custom_minimum_size = Vector2(112, 28)
	_about_manual_btn.add_theme_font_size_override("font_size", 11)
	_about_manual_btn.pressed.connect(func(): _set_about_tab(1))
	hdr.add_child(_about_manual_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE  [ESC]"
	close_btn.custom_minimum_size = Vector2(108, 28)
	close_btn.add_theme_font_size_override("font_size", 11)
	_style_button(close_btn, COL_AMBER, Color(0.16, 0.14, 0.09, 0.96), 8, 2)
	close_btn.pressed.connect(func(): hide_about_overlay())
	hdr.add_child(close_btn)

	var sub_bar := PanelContainer.new()
	sub_bar.add_theme_stylebox_override("panel", _make_box(Color(0.09, 0.12, 0.09, 0.95), COL_BORDER, 4, 1, 12, 6))
	vbox.add_child(sub_bar)

	var sub_lbl := Label.new()
	sub_lbl.text = "★★★★★ 5.0 / 5.0  (4,812,904 MANDATORY CITIZEN REVIEWS)   •   MINISTRY OF INFORMATION APPROVED   •   SHORT CODE: S.A.W.P."
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", COL_GREEN)
	sub_bar.add_child(sub_lbl)

	_about_dossier_scroll = ScrollContainer.new()
	_about_dossier_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_about_dossier_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_about_dossier_scroll)

	var content_v := VBoxContainer.new()
	content_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_v.add_theme_constant_override("separation", 12)
	_about_dossier_scroll.add_child(content_v)

	var sections: Array[Array] = [
		[
			"WHO YOU ARE: AN UNBELIEVABLY IMPRESSIVE SPECIMEN OF LEADERSHIP",
			"You are a heroic, battle-hardened Supreme Tactical Commander of peerless intellect, chiselled resolve and impeccable posture. You are a summa cum laude graduate of the Royal Academy of Pointing Sternly at Maps, an undefeated scratch golfer (having recorded seven consecutive holes-in-one during a single nine-hole charity tournament witnessed exclusively by loyal junior officers), a three-time Regional Competitive Hot Dog Consumption Laureate and the reigning Head Librarian of the Sovereign Municipal Annex (zero overdue books since 1997).\n\nIn your sparse leisure hours, you are also a certified forklift philosopher, undefeated neighbourhood croquet autocrat, inventor of the ergonomic trench clipboard, honorary Grand Admiral of a strictly landlocked duck pond, master artisanal sourdough tactician, provincial yodelling adjudicator and the only living officer documented to have folded a fitted bedsheet into a regulation cube under sustained artillery fire. Small birds pause mid-flight merely to salute your moustache.",
		],
		[
			"OUR RADIANT, AGGRESSIVELY PEACE-LOVING HOMELAND",
			"You stand as the solitary concrete-pouring guardian of our gloriously tranquil, harmony-obsessed Sovereign Republic — a serene utopia of courteous roundabouts, award-winning municipal jam cooperatives, deeply polite swans, punctual fortnightly recycling collection, exquisitely fair zoning bylaws and gentle citizens who have never once raised their voices above a respectful library whisper.",
		],
		[
			"THE UNSPEAKABLY EVIL, TYRANNICAL ENEMY",
			"Now, this fragile paradise of jam and well-behaved waterfowl is imperilled by the Unspeakably Evil, Tyrannical, Queue-Jumping, Library-Book-Dog-Earing, Unauthorized-Parking-Encouraging Coalition of Nefarious Despots! Driven by pure cartoon-grade malice, these ruthless, unshaven warmongers despise proper concrete foundations, loathe orderly roundabouts, listen to videos on public transit without headphones and seek to roll their thoroughly unauthorized vehicles and deeply impolite aircraft straight across our freshly painted crosswalks into Command Headquarters!",
		],
		[
			"YOUR SACRED CONSTITUTIONAL DUTY",
			"Only YOU — armed with boundless charisma, a suspiciously immaculate golf handicap and an unlimited municipal concrete stipend — can preserve democracy, preserves and strict airspace zoning by executing:\n\nSTATIONARY AUTOMATED WEAPON PLACEMENT ON SOVEREIGN TACTICAL BASTIONS FOR THE PREVENTION OF UNAUTHORIZED VEHICULAR AND AERIAL INCURSION INTO COMMAND HEADQUARTERS.\n\n• 16 Sovereign Theaters of Operations — from tranquil Alpine valleys and Australian outback highways to Mars, Europa and hostile alien exoplanets (all equally in need of firm parking enforcement).\n• 7 Aggressively Automated Weapon Systems — Vulcan rotary cannons, Cryo chillers, Howitzers, SAM batteries, autonomous Hunter-Killer Drones, Dragonfire directed-energy lasers and HIMARS thermobaric rocket salvos.\n• 50 Escalating Military Ranks — beginning with humble real-world titles before rapidly spiralling into glorious bureaucratic-imperial nonsense.\n• 36 Heavy Brass Decorations — pinned directly onto your Commanding General until their uniform collapses into a gravitational hazard.",
		],
		[
			"VERIFIED CITIZEN TESTIMONIALS (VOLUNTARILY SUBMITTED)",
			"★★★★★  \"My spine has yielded beneath 13 kilograms of solid brass medals and I have never felt more sovereign.\"  — Rear-Admiral of Municipal Hedges\n★★★★★  \"I tried to park my BTR armoured personnel carrier in a loading zone and was immediately vaporized by a directed-energy laser. Fair policy.\"  — Reformed Invader\n★★★★★  \"Seven consecutive holes-in-one on a nine-hole course is mathematically improbable yet deeply inspiring.\"  — Chief Municipal Caddie",
		],
	]

	for sec in sections:
		var sh := Label.new()
		sh.text = String(sec[0])
		sh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sh.add_theme_font_size_override("font_size", 13)
		sh.add_theme_color_override("font_color", COL_AMBER)
		content_v.add_child(sh)

		var sb := Label.new()
		sb.text = String(sec[1])
		sb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sb.add_theme_font_size_override("font_size", 12)
		sb.add_theme_color_override("font_color", COL_TEXT)
		content_v.add_child(sb)

	# Tab 2: Field Manual (tactical reference of all 7 turrets & 9+1 hostiles in deadpan prose, zero Oxford commas)
	_about_manual_scroll = ScrollContainer.new()
	_about_manual_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_about_manual_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_about_manual_scroll.visible = false
	vbox.add_child(_about_manual_scroll)

	var man_v := VBoxContainer.new()
	man_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	man_v.add_theme_constant_override("separation", 8)
	_about_manual_scroll.add_child(man_v)

	var t_hdr := Label.new()
	t_hdr.text = "AUTHORIZED STATIONARY AUTOMATED WEAPON SYSTEMS (7)"
	t_hdr.add_theme_font_size_override("font_size", 13)
	t_hdr.add_theme_color_override("font_color", COL_AMBER)
	man_v.add_child(t_hdr)

	var turret_notes: Array[String] = [
		"[1] VULCAN MG ($70 • GND+AIR) — High-rate rotary cannon ideal for light convoys, Shahed FPV drones and early gunships. Low armor penetration against main battle tanks.",
		"[2] CRYO EMITTER ($100 • SLOW+AOE) — Liquid-nitrogen projector chilling ground and air columns up to 64% at Lv 4. Multiplies kill-zone time for every neighbouring turret.",
		"[3] HOWITZER CANNON ($120 • GND+AOE) — Heavy armor-piercing lead-aiming shells (up to 100% AP at Lv 4) that shatter clustered APCs and tanks. Cannot engage aircraft.",
		"[4] SAM BATTERY ($140 • AA+HEAVY) — Long-range homing missiles that automatically prioritize aircraft in range with a 1.65x air damage bonus and strong armor penetration.",
		"[5] HUNTER DRONE PAD ($150 • MAP HUNT) — Launches an autonomous orbiting UAV that relentlessly pursues its target across the entire map until destroyed. Use [H] to hold on pad and [F] to assign a specific high-value target.",
		"[6] DRAGONFIRE HEL ($160 • BEAM+APS) — Ramping directed-energy laser (up to 2.75x peak DPS at Lv 4). Completely ignores armor and deals 2x damage against Trophy APS shields.",
		"[7] HIMARS MLRS ($185 • SALVO+FIRE) — Ultra-long-range rocket battery saturating ground highways with explosive salvos and lingering thermobaric fire pools. Cannot hit aircraft.",
	]
	for line in turret_notes:
		var lbl := Label.new()
		lbl.text = "• " + line
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", COL_TEXT)
		man_v.add_child(lbl)

	var e_hdr := Label.new()
	e_hdr.text = "\nKNOWN UNAUTHORIZED INCURSION CLASSES (9 + UAV SUB-UNITS)"
	e_hdr.add_theme_font_size_override("font_size", 13)
	e_hdr.add_theme_color_override("font_color", COL_AMBER)
	man_v.add_child(e_hdr)

	var enemy_notes: Array[String] = [
		"RECON HUMVEE (Light Ground • 5% Armor • 1 HQ) — Brisk scout vehicle. Trivially discouraged by Vulcan MGs.",
		"BTR ARMORED APC (Medium Ground • 22% Armor • 1 HQ) — Travels in stubborn columns. Pair Cryo slowing with Howitzer or MLRS splash.",
		"MAIN BATTLE TANK (Heavy Ground • 55% Armor • 2 HQ) — Thick sloped armor shrugs off low-AP gunfire. Counter with Howitzers, Dragonfire Lasers or SAMs.",
		"TROPHY APS TANK (Shielded Ground • 50% Armor • 2 HQ) — Protected by a regenerating Active Protection shield. Dragonfire Lasers deal 2x shield damage and melt it rapidly.",
		"MOBILE UAV CARRIER (Support Ground • 28% Armor • 2 HQ) — Periodically catapults $0-bounty Shahed FPV Drones straight into the air lane. Snipe early with Hunter Drones or Lasers.",
		"SHAHED FPV DRONE (Fast Air • $0 Bounty • 1 HQ) — Swarming micro-drones launched by UAV Carriers. Keep a Vulcan or Cryo covering the air corridor.",
		"ATTACK GUNSHIP (Fast Air • 12% Armor • 2 HQ) — Bypasses roads entirely along the direct air vector. Counter with SAM Batteries and Vulcans.",
		"HEAVY STRIKER JET (Armored Air • 30% Armor • 3 HQ) — Durable strike aircraft demanding dedicated SAM Batteries or Dragonfire Lasers.",
		"SIEGE JUGGERNAUT (Ground Boss • 66% Armor • 5 HQ) — Colossal rolling fortress. Slow with Cryo and focus-fire with Dragonfire Lasers, maxed Howitzers and Hellfire Air Strikes.",
		"HEAVY ASSAULT GUNSHIP / SKY FORTRESS (Air Boss • 48% Armor • 4 HQ) — Twin-rotor aerial dreadnought. Prioritize upgraded SAM Batteries, Dragonfire Lasers and Cryo emitters.",
	]
	for line in enemy_notes:
		var lbl := Label.new()
		lbl.text = "• " + line
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", COL_TEXT)
		man_v.add_child(lbl)

	var tip_lbl := Label.new()
	tip_lbl.text = "\nTACTICAL NOTE: Turrets earn veteran chevrons at 15 (DECORATED), 35 (TENURED) and 60 (EMERITUS) kills. Calling waves early with [N] awards bonus funding and improves your final sector efficiency valuation."
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_lbl.add_theme_font_size_override("font_size", 11)
	tip_lbl.add_theme_color_override("font_color", COL_GREEN)
	man_v.add_child(tip_lbl)

	_set_about_tab(0)

func _set_about_tab(tab_idx: int) -> void:
	var is_dossier := (tab_idx == 0)
	_about_dossier_scroll.visible = is_dossier
	_about_manual_scroll.visible = not is_dossier
	_style_button(_about_dossier_btn, COL_AMBER if is_dossier else COL_BORDER, Color(0.20, 0.22, 0.14, 0.98) if is_dossier else Color(0.10, 0.12, 0.11, 0.92), 8, 2)
	_style_button(_about_manual_btn, COL_AMBER if not is_dossier else COL_BORDER, Color(0.20, 0.22, 0.14, 0.98) if not is_dossier else Color(0.10, 0.12, 0.11, 0.92), 8, 2)

func show_about_overlay() -> void:
	if _about_overlay != null:
		_set_about_tab(0)
		_about_overlay.visible = true

func hide_about_overlay() -> void:
	if _about_overlay != null:
		_about_overlay.visible = false

func is_about_overlay_visible() -> bool:
	return _about_overlay != null and _about_overlay.visible

func _build_menu_overlay() -> void:
	_menu_overlay = ColorRect.new()
	_menu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.color = Color(0.03, 0.04, 0.03, 0.76)
	_root.add_child(_menu_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(840, 445)
	card.add_theme_stylebox_override("panel", _make_box(COL_BG_DARK, COL_AMBER, 6, 2, 24, 18))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	_menu_title = Label.new()
	_menu_title.text = GAME_TITLE
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_title.add_theme_font_size_override("font_size", 16)
	_menu_title.add_theme_color_override("font_color", COL_AMBER)
	vbox.add_child(_menu_title)

	_menu_sub = Label.new()
	_menu_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_sub.add_theme_font_size_override("font_size", 12)
	_menu_sub.add_theme_color_override("font_color", COL_MUTED)
	vbox.add_child(_menu_sub)

	_all_maps = MapData.get_all_maps()
	_sector_page_count = maxi(1, int(ceil(float(_all_maps.size()) / float(SECTORS_PER_PAGE))))
	_sector_page = 0

	var sector_header := HBoxContainer.new()
	sector_header.add_theme_constant_override("separation", 6)
	vbox.add_child(sector_header)

	_sector_page_label = Label.new()
	_sector_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sector_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sector_page_label.add_theme_font_size_override("font_size", 12)
	_sector_page_label.add_theme_color_override("font_color", COL_AMBER)
	sector_header.add_child(_sector_page_label)

	_sector_prev_btn = Button.new()
	_sector_prev_btn.text = "< PREV"
	_sector_prev_btn.custom_minimum_size = Vector2(66, 24)
	_sector_prev_btn.add_theme_font_size_override("font_size", 11)
	_style_button(_sector_prev_btn, COL_AMBER, Color(0.12, 0.14, 0.12, 0.95), 8, 2)
	_sector_prev_btn.pressed.connect(func(): _set_sector_page(_sector_page - 1))
	sector_header.add_child(_sector_prev_btn)

	_sector_page_btns.clear()
	for p_idx in range(_sector_page_count):
		var pb := Button.new()
		pb.text = "%d" % (p_idx + 1)
		pb.custom_minimum_size = Vector2(28, 24)
		pb.add_theme_font_size_override("font_size", 11)
		_style_button(pb, COL_BORDER, Color(0.10, 0.12, 0.11, 0.94), 6, 2)
		var target_p: int = p_idx
		pb.pressed.connect(func(): _set_sector_page(target_p))
		sector_header.add_child(pb)
		_sector_page_btns.append(pb)

	_sector_next_btn = Button.new()
	_sector_next_btn.text = "NEXT >"
	_sector_next_btn.custom_minimum_size = Vector2(66, 24)
	_sector_next_btn.add_theme_font_size_override("font_size", 11)
	_style_button(_sector_next_btn, COL_AMBER, Color(0.12, 0.14, 0.12, 0.95), 8, 2)
	_sector_next_btn.pressed.connect(func(): _set_sector_page(_sector_page + 1))
	sector_header.add_child(_sector_next_btn)

	_menu_medals_btn = Button.new()
	_menu_medals_btn.text = "★ MEDALS (0/36)"
	_menu_medals_btn.custom_minimum_size = Vector2(118, 24)
	_menu_medals_btn.add_theme_font_size_override("font_size", 11)
	_style_button(_menu_medals_btn, COL_AMBER, Color(0.18, 0.15, 0.09, 0.96), 8, 2)
	_menu_medals_btn.pressed.connect(func(): show_medals_hall())
	sector_header.add_child(_menu_medals_btn)

	var audio_btn := Button.new()
	audio_btn.text = "AUDIO"
	audio_btn.custom_minimum_size = Vector2(60, 24)
	audio_btn.add_theme_font_size_override("font_size", 11)
	_style_button(audio_btn, COL_BORDER, Color(0.11, 0.14, 0.12, 0.95), 8, 2)
	audio_btn.pressed.connect(func():
		_sync_audio_ui_controls()
		_audio_overlay.visible = true
	)
	sector_header.add_child(audio_btn)

	_menu_reset_btn = Button.new()
	_menu_reset_btn.text = "RESET SAVE"
	_menu_reset_btn.custom_minimum_size = Vector2(86, 24)
	_menu_reset_btn.add_theme_font_size_override("font_size", 10)
	_style_button(_menu_reset_btn, Color(0.52, 0.28, 0.26), Color(0.14, 0.09, 0.09, 0.92), 6, 2)
	_menu_reset_btn.pressed.connect(_on_menu_reset_save_clicked)
	sector_header.add_child(_menu_reset_btn)

	_sector_grid = GridContainer.new()
	_sector_grid.columns = 4
	_sector_grid.custom_minimum_size = Vector2(0, 108)
	_sector_grid.add_theme_constant_override("h_separation", 8)
	_sector_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(_sector_grid)

	for m in _all_maps:
		var mid: String = String(m["id"])
		var b := Button.new()
		b.text = "%02d %s\n%s" % [int(m["index"]), String(m["short_name"]), String(m["tag"])]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 50)
		b.add_theme_font_size_override("font_size", 11)
		_style_button(b, COL_AMBER)
		b.pressed.connect(func(): _select_sector(mid, true))
		_sector_grid.add_child(b)
		_sector_btns[mid] = b

	_menu_brief = Label.new()
	_menu_brief.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_brief.add_theme_font_size_override("font_size", 13)
	_menu_brief.add_theme_color_override("font_color", COL_TEXT)
	vbox.add_child(_menu_brief)

	_menu_record_label = Label.new()
	_menu_record_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_record_label.add_theme_font_size_override("font_size", 11)
	_menu_record_label.add_theme_color_override("font_color", COL_MUTED)
	vbox.add_child(_menu_record_label)

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
	controls.text = "CONTROLS:  [1-7] Select Turret  •  [LMB] Build / Inspect  •  [RMB] Cancel  •  [ESC] Cancel / Pause Menu\n[Q] Hellfire Air Strike  •  [F/H] Drone Assign & Hold  •  [N] Next Wave  •  [WASD / RMB Drag / Wheel] Pan & Zoom  •  [SPACE] Tactical Freeze"
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

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 8)
	vbox.add_child(footer_row)

	var left_pad := Control.new()
	left_pad.custom_minimum_size = Vector2(72, 0)
	footer_row.add_child(left_pad)

	var active_season := SeasonalData.get_active_seasonal_event()
	if not active_season.is_empty():
		var hint_lbl := Label.new()
		hint_lbl.text = String(active_season["hint"])
		hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint_lbl.add_theme_font_size_override("font_size", 11)
		hint_lbl.add_theme_color_override("font_color", Color(0.98, 0.44, 0.38, 0.92))
		footer_row.add_child(hint_lbl)
	else:
		var mid_spacer := Control.new()
		mid_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer_row.add_child(mid_spacer)

	var about_btn := Button.new()
	about_btn.text = "ABOUT"
	about_btn.custom_minimum_size = Vector2(72, 24)
	about_btn.add_theme_font_size_override("font_size", 11)
	_style_button(about_btn, COL_BORDER, Color(0.11, 0.14, 0.12, 0.95), 8, 2)
	about_btn.pressed.connect(func(): show_about_overlay())
	footer_row.add_child(about_btn)

	_set_sector_page(0)
	_select_sector("iron_valley", false)
	_select_difficulty(WaveData.Difficulty.NORMAL)

func _set_sector_page(page_idx: int) -> void:
	_sector_page = clampi(page_idx, 0, _sector_page_count - 1)
	var start_i: int = _sector_page * SECTORS_PER_PAGE
	var end_i: int = mini(_all_maps.size(), start_i + SECTORS_PER_PAGE)

	for i in range(_all_maps.size()):
		var mid: String = String(_all_maps[i]["id"])
		var btn: Button = _sector_btns[mid]
		btn.visible = (i >= start_i and i < end_i)

	var theater: String = ""
	if _sector_page == 0:
		theater = "  •  EARTH THEATER"
	elif _sector_page == 1:
		theater = "  •  EXTREME & OFF-WORLD"
	_sector_page_label.text = "SELECT SECTOR  —  PAGE %d / %d%s" % [_sector_page + 1, _sector_page_count, theater]

	_sector_prev_btn.disabled = (_sector_page <= 0)
	_sector_next_btn.disabled = (_sector_page >= _sector_page_count - 1)
	for i in range(_sector_page_btns.size()):
		var pb: Button = _sector_page_btns[i]
		if i == _sector_page:
			_style_button(pb, COL_AMBER, Color(0.20, 0.22, 0.14, 0.98), 6, 2)
		else:
			_style_button(pb, Color(0.25, 0.28, 0.25), Color(0.09, 0.11, 0.10, 0.92), 6, 2)

func _on_menu_reset_save_clicked() -> void:
	if _confirm_reset_save_timer > 0.0:
		_reset_save_confirm_btn()
		reset_save_requested.emit()
	else:
		_confirm_reset_save_timer = 3.5
		_menu_reset_btn.text = "CONFIRM?"
		_style_button(_menu_reset_btn, COL_RED, Color(0.36, 0.10, 0.09, 0.98), 6, 2)

func _reset_save_confirm_btn() -> void:
	_confirm_reset_save_timer = 0.0
	if _menu_reset_btn != null:
		_menu_reset_btn.text = "RESET SAVE"
		_style_button(_menu_reset_btn, Color(0.52, 0.28, 0.26), Color(0.14, 0.09, 0.09, 0.92), 6, 2)

func set_sector_records(records: Dictionary) -> void:
	_sector_records = records.duplicate(true)
	_refresh_sector_cards()
	_refresh_selected_sector_record()

func _refresh_sector_cards() -> void:
	for m in _all_maps:
		var mid: String = String(m["id"])
		if not _sector_btns.has(mid):
			continue
		var btn: Button = _sector_btns[mid]
		var rec: Dictionary = _sector_records.get(mid, {})
		if bool(rec.get("cleared", false)):
			var rank_num: int = int(rec.get("best_rank_num", 1))
			var medal := RankData.get_medal_info(rank_num)
			var d_idx: int = clampi(int(rec.get("best_difficulty", 1)), 0, 3)
			var d_name: String = String(WaveData.get_difficulty_config(d_idx as WaveData.Difficulty)["name"])
			btn.text = "%02d %s  %s\nCLEARED [%s] • R%d" % [int(m["index"]), String(m["short_name"]), String(medal["short"]), d_name, rank_num]
		else:
			btn.text = "%02d %s\n%s" % [int(m["index"]), String(m["short_name"]), String(m["tag"])]
	# Re-apply border styling so cleared cards highlight subtly
	_select_sector(_selected_map_id, false)

func _refresh_selected_sector_record() -> void:
	if _menu_record_label == null:
		return
	var rec: Dictionary = _sector_records.get(_selected_map_id, {})
	if bool(rec.get("cleared", false)):
		var rank_num: int = int(rec.get("best_rank_num", 1))
		var medal := RankData.get_medal_info(rank_num)
		var d_idx: int = clampi(int(rec.get("best_difficulty", 1)), 0, 3)
		var d_name: String = String(WaveData.get_difficulty_config(d_idx as WaveData.Difficulty)["name"])
		var pct: float = float(rec.get("best_pct", 0.0))
		var worth: int = int(rec.get("best_net_worth", 0))
		var r_title: String = String(rec.get("best_rank_title", "Private"))
		_menu_record_label.text = "BEST RECORD: %s %s  •  [%s]  •  %.1f%%  •  NET $%d  •  RANK %d/50: %s" % [
			String(medal["stars"]), String(medal["id"]), d_name, pct, worth, rank_num, r_title
		]
		_menu_record_label.add_theme_color_override("font_color", medal["color"])
	else:
		_menu_record_label.text = "SECTOR STATUS: UNCLEARED  •  NO SOVEREIGN CITATION ON FILE"
		_menu_record_label.add_theme_color_override("font_color", COL_MUTED)

func _select_sector(map_id: String, emit_signal: bool) -> void:
	_selected_map_id = map_id
	var m := MapData.get_map_by_id(map_id)
	_menu_title.text = "%s: %s" % [GAME_TITLE, String(m["short_name"])]
	_menu_sub.text = "SECTOR %02d  •  %s" % [int(m["index"]), String(m["tag"])]
	_menu_brief.text = String(m["briefing"])
	_refresh_selected_sector_record()

	for key in _sector_btns.keys():
		var btn: Button = _sector_btns[key]
		var rec: Dictionary = _sector_records.get(String(key), {})
		var is_cleared: bool = bool(rec.get("cleared", false))
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
			elif bname == "tropical":
				accent = Color(0.18, 0.88, 0.86)
			elif bname == "volcanic":
				accent = Color(1.0, 0.42, 0.14)
			elif bname == "swamp":
				accent = Color(0.54, 0.82, 0.32)
			elif bname == "cyberpunk":
				accent = Color(0.96, 0.24, 0.78)
			elif bname == "moon":
				accent = Color(0.84, 0.88, 0.94)
			elif bname == "mars":
				accent = Color(0.96, 0.46, 0.26)
			elif bname == "europa":
				accent = Color(0.32, 0.88, 1.0)
			elif bname == "alien":
				accent = Color(0.88, 0.32, 1.0)
			_style_button(btn, accent, Color(0.18, 0.21, 0.16, 0.98))
		elif is_cleared:
			var medal := RankData.get_medal_info(int(rec.get("best_rank_num", 1)))
			var mcol: Color = medal["color"]
			_style_button(btn, mcol.darkened(0.22), Color(0.11, 0.15, 0.12, 0.95))
		else:
			_style_button(btn, Color(0.25, 0.28, 0.25), Color(0.09, 0.11, 0.10, 0.92))

	if emit_signal:
		sector_selected.emit(map_id)

func select_sector_external(map_id: String) -> void:
	for i in range(_all_maps.size()):
		if String(_all_maps[i]["id"]) == map_id:
			_set_sector_page(i / SECTORS_PER_PAGE)
			break
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
	card.custom_minimum_size = Vector2(580, 340)
	card.add_theme_stylebox_override("panel", _make_box(COL_BG_DARK, COL_AMBER, 6, 2, 26, 22))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	_end_title = Label.new()
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(_end_title)

	_end_rank_panel = PanelContainer.new()
	_end_rank_panel.add_theme_stylebox_override("panel", _make_box(Color(0.10, 0.12, 0.09, 0.96), COL_AMBER, 5, 1, 14, 10))
	vbox.add_child(_end_rank_panel)

	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 4)
	_end_rank_panel.add_child(rbox)

	_end_rank_header = Label.new()
	_end_rank_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_rank_header.add_theme_font_size_override("font_size", 12)
	_end_rank_header.add_theme_color_override("font_color", COL_AMBER)
	rbox.add_child(_end_rank_header)

	_end_rank_title = Label.new()
	_end_rank_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_rank_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_rank_title.add_theme_font_size_override("font_size", 16)
	_end_rank_title.add_theme_color_override("font_color", Color.WHITE)
	rbox.add_child(_end_rank_title)

	_end_new_best_lbl = Label.new()
	_end_new_best_lbl.text = "★ NEW SECTOR PERSONAL BEST! ★"
	_end_new_best_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_new_best_lbl.add_theme_font_size_override("font_size", 11)
	_end_new_best_lbl.add_theme_color_override("font_color", COL_GREEN)
	_end_new_best_lbl.visible = false
	rbox.add_child(_end_new_best_lbl)

	_end_summary = Label.new()
	_end_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_summary.add_theme_font_size_override("font_size", 13)
	_end_summary.add_theme_color_override("font_color", COL_TEXT)
	vbox.add_child(_end_summary)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var briefing_btn := Button.new()
	briefing_btn.text = "BRIEFING"
	briefing_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	briefing_btn.custom_minimum_size = Vector2(0, 42)
	briefing_btn.add_theme_font_size_override("font_size", 14)
	_style_button(briefing_btn, COL_BORDER, Color(0.12, 0.14, 0.12, 0.96))
	briefing_btn.pressed.connect(func():
		_end_overlay.visible = false
		restart_requested.emit()
	)
	btn_row.add_child(briefing_btn)

	var replay_btn := Button.new()
	replay_btn.text = "REPLAY SECTOR"
	replay_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay_btn.custom_minimum_size = Vector2(0, 42)
	replay_btn.add_theme_font_size_override("font_size", 14)
	_style_button(replay_btn, COL_AMBER, Color(0.18, 0.16, 0.10, 0.96))
	replay_btn.pressed.connect(func():
		_end_overlay.visible = false
		replay_sector_requested.emit()
	)
	btn_row.add_child(replay_btn)

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
	_pause_overlay.visible = false
	_audio_overlay.visible = false
	_about_overlay.visible = false
	_inspector_panel.visible = false
	_wave_preview_panel.visible = false
	_reset_save_confirm_btn()

func hide_menu() -> void:
	_menu_overlay.visible = false
	_audio_overlay.visible = false
	_about_overlay.visible = false

func get_selected_difficulty() -> WaveData.Difficulty:
	return _selected_diff

func show_end_screen(
	victory: bool,
	sector_name: String,
	waves_cleared: int,
	total_waves: int,
	kills: int,
	diff_name: String,
	has_next_sector: bool,
	eval_res: Dictionary = {},
	is_new_best: bool = false,
	secret_event: Dictionary = {}
) -> void:
	_pause_overlay.visible = false
	_wave_preview_panel.visible = false
	_end_overlay.visible = true
	_end_title.text = "SECTOR SECURED" if victory else "COMMAND HQ BREACHED"
	_end_title.add_theme_color_override("font_color", COL_GREEN if victory else COL_RED)

	if victory:
		var mcol: Color = eval_res.get("medal_color", COL_AMBER)
		_end_rank_panel.add_theme_stylebox_override("panel", _make_box(Color(0.09, 0.12, 0.09, 0.96), mcol, 5, 2, 14, 10))
		_end_rank_header.text = "RANK %d / %d   •   %s %s MEDAL   •   %.1f%% EFFICIENCY" % [
			int(eval_res.get("rank_num", 1)),
			int(eval_res.get("rank_total", 50)),
			String(eval_res.get("medal_stars", "★")),
			String(eval_res.get("medal_id", "BRONZE")),
			float(eval_res.get("efficiency_pct", 0.0)),
		]
		_end_rank_header.add_theme_color_override("font_color", mcol)
		_end_rank_title.text = String(eval_res.get("rank_title", "Private"))
		_end_rank_title.add_theme_color_override("font_color", Color.WHITE)
		_end_new_best_lbl.visible = is_new_best
		_end_summary.text = "%s  •  Difficulty: %s\nWaves Cleared: %d / %d   •   Hostiles Destroyed: %d   •   HQ Integrity: %d / %d\nCash: $%d   •   Bastion Assets: $%d   •   Net Valuation: $%d / $%d Max" % [
			sector_name,
			diff_name,
			waves_cleared,
			total_waves,
			kills,
			int(eval_res.get("lives", 0)),
			int(eval_res.get("max_lives", 20)),
			int(eval_res.get("cash", 0)),
			int(eval_res.get("turrets_sell_value", 0)),
			int(eval_res.get("net_worth", 0)),
			int(eval_res.get("max_cash", 1)),
		]
	else:
		_end_rank_panel.add_theme_stylebox_override("panel", _make_box(Color(0.15, 0.07, 0.07, 0.96), COL_RED, 5, 2, 14, 10))
		_end_rank_header.text = "BADGE OF SHAME   •   COMMAND DEMOTION CITATION"
		_end_rank_header.add_theme_color_override("font_color", COL_RED)
		_end_rank_title.text = String(eval_res.get("shame_title", "Dishonorably Demoted to Sandbag"))
		_end_rank_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.78))
		_end_new_best_lbl.visible = false
		_end_summary.text = "%s  •  Difficulty: %s\nWaves Cleared: %d / %d   •   Hostiles Destroyed: %d\nUnspent Cash: $%d   •   Bastion Assets Lost: $%d" % [
			sector_name,
			diff_name,
			waves_cleared,
			total_waves,
			kills,
			int(eval_res.get("cash", 0)),
			int(eval_res.get("turrets_sell_value", 0)),
		]

	_end_next_btn.visible = (victory and has_next_sector)
	if (not victory) and not secret_event.is_empty():
		_secret_map_id = String(secret_event["map_id"])
		_end_secret_btn.text = "★ %s ★" % String(secret_event["title"])
		_end_secret_btn.visible = true
	else:
		_secret_map_id = ""
		_end_secret_btn.visible = false

func update_wave_preview(visible_now: bool, next_wave_num: int, total_waves: int, wave_def: Dictionary) -> void:
	if not visible_now or wave_def.is_empty():
		_wave_preview_panel.visible = false
		_last_preview_key = ""
		return
	_wave_preview_panel.visible = true
	var pkey: String = "%d/%d:%s" % [next_wave_num, total_waves, String(wave_def.get("title", ""))]
	if pkey == _last_preview_key:
		return
	_last_preview_key = pkey

	_preview_wave_lbl.text = "NEXT W%02d:" % next_wave_num

	# Aggregate counts & threat tags across groups
	var counts: Dictionary = {}
	var order: Array[int] = []
	var has_air := false
	var has_heavy := false
	var has_shield := false
	var has_uav := false
	var has_boss := false
	var total_units := 0

	var groups: Array = wave_def.get("groups", [])
	for g in groups:
		var et: int = int(g["type"])
		var cnt: int = int(g.get("count", 0))
		if cnt <= 0:
			continue
		total_units += cnt
		if not counts.has(et):
			counts[et] = 0
			order.append(et)
		counts[et] = int(counts[et]) + cnt
		var cfg := EnemyData.get_config(et as EnemyData.EnemyType)
		if bool(cfg.get("is_air", false)):
			has_air = true
		if float(cfg.get("armor", 0.0)) >= 0.45:
			has_heavy = true
		if float(cfg.get("shield", 0.0)) > 0.0:
			has_shield = true
		if et == int(EnemyData.EnemyType.UAV_CARRIER):
			has_uav = true
		if et == int(EnemyData.EnemyType.JUGGERNAUT) or et == int(EnemyData.EnemyType.SKY_FORTRESS):
			has_boss = true

	# Rebuild compact colored threat tag pills
	for c in _preview_tags_box.get_children():
		c.queue_free()

	var tags: Array[Array] = []
	if has_boss:
		tags.append(["BOSS", Color(0.98, 0.28, 0.24)])
	if has_air:
		tags.append(["AIR", Color(0.36, 0.86, 0.98)])
	if has_shield:
		tags.append(["SHIELD", Color(0.28, 0.78, 0.96)])
	if has_uav:
		tags.append(["UAV", Color(0.96, 0.68, 0.22)])
	if has_heavy:
		tags.append(["HEAVY", Color(0.96, 0.50, 0.24)])
	if total_units >= 18 and not has_boss:
		tags.append(["SWARM", Color(0.58, 0.92, 0.34)])

	for t_item in tags:
		var pill := PanelContainer.new()
		var col: Color = t_item[1]
		pill.add_theme_stylebox_override("panel", _make_box(col.darkened(0.75), col, 3, 1, 5, 1))
		var lbl := Label.new()
		lbl.text = String(t_item[0])
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", col.lightened(0.15))
		pill.add_child(lbl)
		_preview_tags_box.add_child(pill)

	# Build compact unit count breakdown
	var short_names: Dictionary = {
		int(EnemyData.EnemyType.JEEP): "Humvee",
		int(EnemyData.EnemyType.APC): "APC",
		int(EnemyData.EnemyType.TANK): "Tank",
		int(EnemyData.EnemyType.CHOPPER): "Gunship",
		int(EnemyData.EnemyType.BOMBER): "Striker",
		int(EnemyData.EnemyType.JUGGERNAUT): "Juggernaut",
		int(EnemyData.EnemyType.APS_TANK): "APS Tank",
		int(EnemyData.EnemyType.UAV_CARRIER): "UAV Carrier",
		int(EnemyData.EnemyType.FPV_DRONE): "FPV",
		int(EnemyData.EnemyType.SKY_FORTRESS): "Sky Fortress",
	}
	var parts: PackedStringArray = PackedStringArray()
	for et in order:
		parts.append("%dx %s" % [int(counts[et]), String(short_names.get(et, "Hostile"))])
	_preview_units_lbl.text = ", ".join(parts)

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
	_mute_btn.text = "MUTED" if muted else "AUDIO"
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
			_style_button_cached(btn, "sel", Color.WHITE, Color(0.18, 0.26, 0.18, 0.98), COL_TEXT, 4, 3)
		elif affordable:
			_style_button_cached(btn, "ok", cfg["accent"], Color(0.11, 0.14, 0.12, 0.95), COL_TEXT, 4, 3)
		else:
			_style_button_cached(btn, "poor", Color(0.28, 0.24, 0.22), Color(0.09, 0.09, 0.09, 0.85), Color(0.55, 0.45, 0.42), 4, 3)

	if airstrike_cd <= 0.0:
		_airstrike_btn.disabled = false
		_airstrike_bar.visible = false
		_airstrike_bar.value = 100.0
		_airstrike_btn.text = "[Q] AIMING...\nCLICK MAP" if airstrike_aiming else "[Q] AIR STRIKE\nREADY"
		_style_button_cached(
			_airstrike_btn,
			"aim" if airstrike_aiming else "ready",
			Color.WHITE if airstrike_aiming else COL_RED,
			Color(0.36, 0.14, 0.10, 0.98) if airstrike_aiming else Color(0.22, 0.10, 0.08, 0.95),
			COL_TEXT,
			5,
			4
		)
	else:
		_airstrike_btn.disabled = true
		var pct := clampf((1.0 - airstrike_cd / maxf(1.0, airstrike_max_cd)) * 100.0, 0.0, 100.0)
		_airstrike_bar.visible = true
		_airstrike_bar.value = pct
		_airstrike_btn.text = "[Q] AIR STRIKE\nCD %ds" % int(ceil(airstrike_cd))
		_style_button_cached(_airstrike_btn, "cd", COL_RED, Color(0.18, 0.09, 0.08, 0.90), COL_TEXT, 5, 4)

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

func update_inspector(turret: Turret, cash: int, drone_assign_aiming: bool = false) -> void:
	if turret == null or not is_instance_valid(turret):
		_inspector_panel.visible = false
		return
	_inspector_panel.visible = true
	var cfg := turret.config
	var st := turret.get_stats()
	var vet := turret.get_veteran_title()
	var vet_tag := ("  [%s]" % vet) if vet != "" else ""
	_insp_title.text = "%s%s  •  LV %d/4   |   KILLS: %d" % [String(cfg["name"]), vet_tag, turret.level + 1, turret.kills]

	if turret.turret_type == TurretData.TurretType.LASER:
		var base_dps: float = float(st["damage"])
		var max_dps: float = base_dps * float(st.get("max_ramp", 2.2))
		_insp_stats.text = "DPS %.0f-%.0f   RNG %.0f   100%% AP • APS x2" % [base_dps, max_dps, float(st["range"])]
	elif turret.turret_type == TurretData.TurretType.MLRS:
		_insp_stats.text = "SALVO %dx%.0f   RNG %.0f   BURN %.0f/s" % [
			int(st.get("salvo_count", 3)),
			float(st["damage"]),
			float(st["range"]),
			float(st.get("burn_dps", 14.0)),
		]
	elif turret.turret_type == TurretData.TurretType.DRONE:
		_insp_stats.text = "UAV %.0fx%.1f/s   RADAR %.0f   [%s]" % [
			float(st["damage"]),
			float(st["fire_rate"]),
			float(st["range"]),
			turret.get_drone_status_label(),
		]
	else:
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

	var is_drone := (turret.turret_type == TurretData.TurretType.DRONE)
	_insp_drone_row.visible = is_drone
	_inspector_panel.offset_top = -120 if is_drone else -92
	if is_drone:
		_insp_drone_hold_btn.text = "[H] MODE: HOLD" if turret.drone_hold_mode else "[H] MODE: AUTO"
		_style_button_cached(
			_insp_drone_hold_btn,
			"hold" if turret.drone_hold_mode else "auto",
			COL_AMBER if turret.drone_hold_mode else COL_BORDER,
			Color(0.24, 0.19, 0.10, 0.96) if turret.drone_hold_mode else Color(0.12, 0.15, 0.13, 0.95),
			COL_TEXT,
			8,
			3
		)
		var can_launch := turret.can_launch_drone()
		_insp_drone_assign_btn.disabled = not can_launch
		if drone_assign_aiming and can_launch:
			_insp_drone_assign_btn.text = "CLICK HOSTILE..."
			_style_button_cached(_insp_drone_assign_btn, "assign_aim", Color.WHITE, Color(0.18, 0.34, 0.14, 0.98), COL_TEXT, 8, 3)
		elif can_launch:
			_insp_drone_assign_btn.text = "[F] ASSIGN TARGET"
			_style_button_cached(_insp_drone_assign_btn, "assign_ready", Color(0.56, 0.90, 0.30), Color(0.12, 0.22, 0.12, 0.95), COL_TEXT, 8, 3)
		else:
			_insp_drone_assign_btn.text = turret.get_drone_status_label()
			_style_button_cached(_insp_drone_assign_btn, "assign_busy", COL_BORDER, Color(0.10, 0.12, 0.10, 0.85), COL_TEXT, 8, 3)
