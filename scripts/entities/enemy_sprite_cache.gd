class_name EnemySpriteCache
extends Node

const BAKE_SIZE: int = 256
const BAKE_SCALE: float = 1.75

var _viewports: Dictionary = {} # "type:festive" -> SubViewport

func get_texture(enemy_type: EnemyData.EnemyType, festive_mode: bool) -> ViewportTexture:
	var key := "%d:%d" % [int(enemy_type), 1 if festive_mode else 0]
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

	var dummy := Enemy.new()
	dummy.position = Vector2(BAKE_SIZE * 0.5, BAKE_SIZE * 0.5)
	dummy.scale = Vector2(BAKE_SCALE, BAKE_SCALE)
	dummy.setup_for_sprite_bake(enemy_type, festive_mode)
	vp.add_child(dummy)

	_viewports[key] = vp
	return vp.get_texture()

func rebake_all() -> void:
	for vp in _viewports.values():
		if is_instance_valid(vp):
			(vp as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE
