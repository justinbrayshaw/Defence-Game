class_name TurretSpriteCache
extends Node

const BAKE_SIZE: int = 128
const BAKE_SCALE: float = 1.80

var _viewports: Dictionary = {} # "base|head:type:level" -> SubViewport

func get_base_texture(turret_type: TurretData.TurretType, level: int) -> ViewportTexture:
	return _get_or_bake("base", turret_type, level)

func get_head_texture(turret_type: TurretData.TurretType, level: int) -> ViewportTexture:
	return _get_or_bake("head", turret_type, level)

func _get_or_bake(part: String, turret_type: TurretData.TurretType, level: int) -> ViewportTexture:
	var key := "%s:%d:%d" % [part, int(turret_type), level]
	if _viewports.has(key):
		var existing: SubViewport = _viewports[key]
		if is_instance_valid(existing):
			return existing.get_texture()

	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.size = Vector2i(BAKE_SIZE, BAKE_SIZE)
	add_child(vp)

	var dummy := Turret.new()
	dummy.position = Vector2(BAKE_SIZE * 0.5, BAKE_SIZE * 0.5)
	dummy.scale = Vector2(BAKE_SCALE, BAKE_SCALE)
	dummy.setup_for_sprite_bake(turret_type, level, part)
	vp.add_child(dummy)

	_viewports[key] = vp
	return vp.get_texture()

func rebake_all() -> void:
	for vp in _viewports.values():
		if is_instance_valid(vp):
			(vp as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE
