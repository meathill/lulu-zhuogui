extends Node3D

## 第 1 关轿厢。天花板角落的监控，大约 45° 俯视对着门。
## 符位仍走灰盒的 slot id，这里只负责看得见的三维和点击射线。

var _world: Node3D
var _camera: Camera3D
var _bound: bool = false
var _papers: Dictionary = {}
var _blobs: Dictionary = {}
var _hits: Dictionary = {}
var _shot: bool = false
var _grade: ColorRect
var _seam_mesh: Dictionary = {}
var _seam_color: Dictionary = {}


func setup() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_world = self
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.09)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_world.add_child(world_env)

	_build_shell()
	_build_doors()
	_build_fixtures()
	_build_slots()

	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.fov = 56.0
	_camera.near = 0.04
	_camera.far = 30.0
	_world.add_child(_camera)
	# 后右上角，看向门下沿。水平距离和落差接近，俯角约 45°。
	_camera.look_at_from_position(Vector3(0.38, 1.92, 0.48), Vector3(-0.02, 0.55, -1.05), Vector3.UP)
	_camera.current = true
	_add_grade()
	print("轿厢机位已摆好")


func _add_grade() -> void:
	# 轻度像素化，只盖在三维上。教程和符力条在更高的 CanvasLayer，不会被糊掉。
	var rect := ColorRect.new()
	rect.name = "CabinGrade"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1, 1, 1, 0)
	_grade = rect
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
	float px = 2.0;
	vec2 block = SCREEN_PIXEL_SIZE * px;
	vec2 uv = floor(SCREEN_UV / block) * block + block * 0.5;
	vec3 col = texture(screen_tex, uv).rgb;
	col *= vec3(0.86, 0.95, 0.88);
	COLOR = vec4(col, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	get_parent().add_child(rect)


func bind() -> void:
	_bound = true
	_shot = OS.get_cmdline_user_args().has("--shot-cabin")
	if _shot:
		_capture_sequence()
	var phone := _arg_value("--shot-phone")
	if phone != "":
		_capture_phone(phone)


func _process(_delta: float) -> void:
	_fit_grade()
	if not _bound or _camera == null:
		return
	_sync_slots()
	_sync_spirits()
	_pulse_seams()


func pick(screen_pos: Vector2) -> String:
	if _camera == null:
		return ""
	var origin := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)
	var best_id := ""
	var best_t := 100000.0
	for slot_id in _hits.keys():
		var hit: AABB = _hits[slot_id]
		var dist := _ray_aabb(origin, dir, hit)
		if dist >= 0.0 and dist < best_t:
			best_t = dist
			best_id = str(slot_id)
	return best_id


func _build_shell() -> void:
	var floor_c := Color(0.40, 0.44, 0.41)
	var wall_c := Color(0.55, 0.58, 0.55)
	var far_c := Color(0.46, 0.50, 0.48)
	var ceil_c := Color(0.30, 0.33, 0.32)
	var trim_c := Color(0.16, 0.17, 0.16)
	# 地面、天花、左右和后墙。门那一侧单独留洞。
	_box(Vector3(0, -0.06, -0.05), Vector3(2.36, 0.12, 2.50), floor_c)
	_box(Vector3(0, 0.012, -0.05), Vector3(1.86, 0.012, 1.90), Color(0.34, 0.37, 0.35))
	_box(Vector3(0, 2.38, -0.05), Vector3(2.36, 0.10, 2.50), ceil_c)
	_box(Vector3(-1.16, 1.16, -0.05), Vector3(0.12, 2.32, 2.50), wall_c)
	_box(Vector3(1.16, 1.16, -0.05), Vector3(0.12, 2.32, 2.50), wall_c)
	_box(Vector3(0, 1.16, 1.12), Vector3(2.20, 2.32, 0.12), wall_c)
	# 门洞左右柱和门楣。底下故意留空，那是门下缝。
	_box(Vector3(-0.90, 1.16, -1.18), Vector3(0.52, 2.32, 0.12), far_c)
	_box(Vector3(0.90, 1.16, -1.18), Vector3(0.52, 2.32, 0.12), far_c)
	_box(Vector3(0, 2.16, -1.18), Vector3(1.28, 0.32, 0.12), far_c)
	_box(Vector3(-1.10, 0.06, -0.05), Vector3(0.04, 0.12, 2.10), trim_c)
	_box(Vector3(1.10, 0.06, -0.05), Vector3(0.04, 0.12, 2.10), trim_c)
	_box(Vector3(0, 0.06, 1.02), Vector3(2.10, 0.12, 0.04), trim_c)
	# 地砖缝，帮透视读出地面。
	_box(Vector3(0, 0.02, -0.05), Vector3(0.02, 0.008, 1.90), Color(0.22, 0.24, 0.23))
	_box(Vector3(0, 0.02, -0.35), Vector3(1.86, 0.008, 0.02), Color(0.22, 0.24, 0.23))


func _build_doors() -> void:
	# 门后的暗井，缝和门缝都透出这块黑。
	_box(Vector3(0, 1.02, -1.48), Vector3(1.20, 2.10, 0.36), Color(0.015, 0.016, 0.018))
	var door := Color(0.64, 0.66, 0.64)
	var inset := Color(0.50, 0.53, 0.51)
	# 两扇门悬在地面以上，底下留一条能看见的黑缝。
	_box(Vector3(-0.36, 1.12, -1.20), Vector3(0.50, 1.84, 0.06), door)
	_box(Vector3(0.36, 1.12, -1.20), Vector3(0.50, 1.84, 0.06), door)
	_box(Vector3(-0.36, 1.16, -1.16), Vector3(0.34, 1.20, 0.02), inset)
	_box(Vector3(0.36, 1.16, -1.16), Vector3(0.34, 1.20, 0.02), inset)
	_box(Vector3(-0.36, 0.42, -1.155), Vector3(0.42, 0.14, 0.015), Color(0.40, 0.38, 0.34))
	_box(Vector3(0.36, 0.42, -1.155), Vector3(0.42, 0.14, 0.015), Color(0.40, 0.38, 0.34))
	# 门槛，贴在缝前面，不把缝挡住。
	_box(Vector3(0, 0.02, -1.02), Vector3(1.24, 0.015, 0.08), Color(0.55, 0.52, 0.46))


func _build_fixtures() -> void:
	# 灯管贴在门上沿前方，刚好落在抬头下沿。
	_box(Vector3(0.0, 1.22, -1.02), Vector3(0.86, 0.08, 0.08), Color(0.22, 0.24, 0.23))
	_box(Vector3(0.0, 1.20, -0.98), Vector3(0.70, 0.05, 0.04), Color(0.95, 0.99, 0.88))
	# 左侧扶手。
	_rail(Vector3(-1.02, 0.96, -0.15), 1.35)
	_box(Vector3(-1.06, 0.78, -0.70), Vector3(0.06, 0.36, 0.04), Color(0.40, 0.36, 0.30))
	_box(Vector3(-1.06, 0.78, 0.40), Vector3(0.06, 0.36, 0.04), Color(0.40, 0.36, 0.30))
	# 右侧楼层板和按钮，按钮是色块不是字。
	_box(Vector3(1.08, 1.28, -0.48), Vector3(0.04, 0.78, 0.42), Color(0.28, 0.30, 0.29))
	_box(Vector3(1.05, 1.50, -0.48), Vector3(0.02, 0.22, 0.30), Color(0.10, 0.28, 0.30))
	_box(Vector3(1.035, 1.54, -0.54), Vector3(0.012, 0.06, 0.06), Color(0.55, 0.82, 0.62))
	_box(Vector3(1.035, 1.46, -0.40), Vector3(0.012, 0.04, 0.10), Color(0.70, 0.82, 0.72))
	var colors: Array[Color] = [
		Color(0.72, 0.22, 0.18), Color(0.78, 0.62, 0.22), Color(0.28, 0.55, 0.36),
		Color(0.75, 0.76, 0.72), Color(0.25, 0.38, 0.62), Color(0.55, 0.28, 0.42),
	]
	var i := 0
	for row in 2:
		for col in 3:
			var y := 1.12 - float(row) * 0.14
			var z := -0.60 + float(col) * 0.12
			_box(Vector3(1.05, y, z), Vector3(0.02, 0.07, 0.07), colors[i])
			i += 1
	# 广告屏在左墙靠门一侧，鬼往这边爬。没有字。
	_box(Vector3(-1.07, 1.38, -0.58), Vector3(0.03, 0.46, 0.36), Color(0.10, 0.11, 0.12))
	_box(Vector3(-1.05, 1.40, -0.58), Vector3(0.012, 0.32, 0.26), Color(0.14, 0.30, 0.34))
	_box(Vector3(-1.04, 1.46, -0.64), Vector3(0.01, 0.08, 0.10), Color(0.32, 0.50, 0.48))


func _build_slots() -> void:
	# 门下缝：门底整条黑槽，略探进轿厢，监控能看见。
	var bottom_c := Color(0.01, 0.012, 0.014)
	var bottom := _box(Vector3(0, 0.09, -1.22), Vector3(1.16, 0.16, 0.20), bottom_c)
	bottom.name = "DoorBottomSeam"
	_remember_seam("door-bottom-seam", bottom, bottom_c)
	# 点击体积比看见的缝宽一圈，指尖能点中。外观不改。
	_hits["door-bottom-seam"] = AABB(Vector3(-0.85, -0.08, -1.55), Vector3(1.70, 0.58, 0.95))
	_papers["door-bottom-seam"] = _paper(Vector3(0, 0.035, -1.02), Vector3(-90, 0, 0), Vector2(0.42, 0.18))
	# 两扇门中间的门缝。
	var crack_c := Color(0.01, 0.01, 0.012)
	var crack := _box(Vector3(0, 1.12, -1.16), Vector3(0.10, 1.78, 0.10), crack_c)
	crack.name = "DoorCrack"
	_remember_seam("door-seam", crack, crack_c)
	_hits["door-seam"] = AABB(Vector3(-0.32, 0.18, -1.48), Vector3(0.64, 1.90, 0.55))
	_papers["door-seam"] = _paper(Vector3(0, 0.95, -1.12), Vector3(0, 0, 0), Vector2(0.16, 0.36))
	# 楼层板中间那条横缝。
	var panel_c := Color(0.01, 0.01, 0.012)
	var panel := _box(Vector3(1.03, 1.50, -0.48), Vector3(0.03, 0.045, 0.32), panel_c)
	panel.name = "FloorPanelSeam"
	_remember_seam("floor-panel", panel, panel_c)
	_hits["floor-panel"] = AABB(Vector3(0.78, 1.18, -0.85), Vector3(0.40, 0.62, 0.74))
	_papers["floor-panel"] = _paper(Vector3(1.02, 1.42, -0.48), Vector3(0, -90, 8), Vector2(0.20, 0.14))


func _sync_slots() -> void:
	var slots: Variant = get_parent().get("slots")
	if not slots is Dictionary:
		return
	for slot_id in _papers.keys():
		var slot: Variant = (slots as Dictionary).get(slot_id)
		var warded := slot != null and str(slot.talisman) == "ward"
		(_papers[slot_id] as Node3D).visible = warded


func _sync_spirits() -> void:
	var actors: Variant = get_parent().get("actors")
	if not actors is Array:
		return
	var alive: Dictionary = {}
	for actor in actors:
		var id := str(actor.actor_id)
		alive[id] = true
		actor.modulate = Color(1, 1, 1, 0)
		var blob: Node3D = _blobs.get(id) as Node3D
		if blob == null:
			blob = _make_blob()
			_world.add_child(blob)
			_blobs[id] = blob
		var gone := bool(actor.dead) or bool(actor.resolved) or not bool(actor.visible)
		blob.visible = not gone
		if gone:
			continue
		blob.position = _actor_pos(actor)
		var ratio := 1.0
		if float(actor.max_hp) > 0.0:
			ratio = clampf(float(actor.hp) / float(actor.max_hp), 0.15, 1.0)
		var bulk := 1.45 if float(actor.max_hp) >= 300.0 else 0.92
		if str(actor.blocked_by) != "":
			bulk *= 0.45 + 0.55 * ratio
		blob.scale = Vector3(bulk, bulk * 0.62, bulk)
	for id in _blobs.keys():
		if not alive.has(id):
			(_blobs[id] as Node3D).visible = false


func _actor_pos(actor: Variant) -> Vector3:
	var path: PackedStringArray = actor.path
	if path.is_empty():
		return Vector3(0, 0.16, 0)
	var to_i := clampi(int(actor.path_index), 0, path.size() - 1)
	var from_i := to_i if to_i == 0 else to_i - 1
	var slots: Dictionary = get_parent().get("slots")
	var a2 := _flat(slots, path[from_i])
	var b2 := _flat(slots, path[to_i])
	var a3 := _anchor(path[from_i])
	var b3 := _anchor(path[to_i])
	var denom := a2.distance_to(b2)
	var t := 0.0
	if denom > 1.0:
		t = clampf(a2.distance_to(actor.position) / denom, 0.0, 1.0)
	return a3.lerp(b3, t)


func _flat(slots: Dictionary, slot_id: String) -> Vector2:
	var slot: Variant = slots.get(slot_id)
	if slot == null:
		return Vector2.ZERO
	return slot.position


func _anchor(slot_id: String) -> Vector3:
	match slot_id:
		"door-bottom-seam":
			return Vector3(0.0, 0.16, -1.08)
		"door-seam":
			return Vector3(0.0, 0.16, -1.08)
		"floor-panel":
			return Vector3(0.92, 0.20, -0.48)
		"center":
			return Vector3(-0.72, 0.16, 0.05)
		_:
			return Vector3(0, 0.16, 0)


func _make_blob() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.16
	mesh.height = 0.32
	mesh.radial_segments = 8
	mesh.rings = 4
	body.mesh = mesh
	body.material_override = _solid(Color(0.02, 0.02, 0.028))
	body.scale = Vector3(1.25, 0.7, 1.05)
	root.add_child(body)
	var lump := MeshInstance3D.new()
	var lump_mesh := SphereMesh.new()
	lump_mesh.radius = 0.09
	lump_mesh.height = 0.18
	lump_mesh.radial_segments = 6
	lump_mesh.rings = 3
	lump.mesh = lump_mesh
	lump.position = Vector3(0.02, 0.06, -0.08)
	lump.material_override = _solid(Color(0.05, 0.04, 0.07))
	root.add_child(lump)
	return root


func _paper(pos: Vector3, rot: Vector3, size: Vector2) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees = rot
	root.visible = false
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	sheet.mesh = quad
	var mat := _solid(Color(0.86, 0.70, 0.24))
	mat.albedo_texture = _mark_tex()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sheet.material_override = mat
	root.add_child(sheet)
	var ink := _solid(Color(0.12, 0.07, 0.05))
	var down := MeshInstance3D.new()
	var down_mesh := BoxMesh.new()
	down_mesh.size = Vector3(0.018, size.y * 0.62, 0.008)
	down.mesh = down_mesh
	down.position = Vector3(0, 0, 0.006)
	down.material_override = ink
	root.add_child(down)
	var slash := MeshInstance3D.new()
	var slash_mesh := BoxMesh.new()
	slash_mesh.size = Vector3(size.x * 0.45, 0.016, 0.008)
	slash.mesh = slash_mesh
	slash.position = Vector3(0.01, size.y * 0.08, 0.008)
	slash.rotation_degrees = Vector3(0, 0, -28)
	slash.material_override = ink
	root.add_child(slash)
	_world.add_child(root)
	return root


func _mark_tex() -> ImageTexture:
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.88, 0.72, 0.26, 1))
	for x in 32:
		img.set_pixel(x, 0, Color(0.45, 0.32, 0.10, 1))
		img.set_pixel(x, 47, Color(0.45, 0.32, 0.10, 1))
	for y in 48:
		img.set_pixel(0, y, Color(0.45, 0.32, 0.10, 1))
		img.set_pixel(31, y, Color(0.45, 0.32, 0.10, 1))
		if y > 6 and y < 42:
			img.set_pixel(16, y, Color(0.15, 0.08, 0.04, 1))
	for i in 14:
		var x := 8 + i
		var y := 12 + int(i * 0.7)
		if x < 32 and y < 48:
			img.set_pixel(x, y, Color(0.15, 0.08, 0.04, 1))
			img.set_pixel(24 - i, 30 - int(i * 0.4), Color(0.15, 0.08, 0.04, 1))
	return ImageTexture.create_from_image(img)


func _remember_seam(slot_id: String, mesh: MeshInstance3D, color: Color) -> void:
	_seam_mesh[slot_id] = mesh
	_seam_color[slot_id] = color


func _fit_grade() -> void:
	if _grade == null:
		return
	var vis := get_viewport().get_visible_rect().size
	if vis.x < 2.0 or vis.y < 2.0:
		return
	_grade.position = Vector2.ZERO
	_grade.size = vis


func _pulse_seams() -> void:
	var slots: Variant = get_parent().get("slots")
	var wave := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
	for slot_id in _seam_mesh.keys():
		var mesh := _seam_mesh[slot_id] as MeshInstance3D
		var mat := mesh.material_override as StandardMaterial3D
		if mat == null:
			continue
		var base: Color = _seam_color[slot_id]
		var hot := false
		if slots is Dictionary:
			var slot: Variant = (slots as Dictionary).get(slot_id)
			if slot != null and bool(slot.coached):
				hot = true
		if hot:
			mat.albedo_color = base.lerp(Color(0.92, 0.72, 0.25), 0.16 + 0.28 * wave)
		else:
			mat.albedo_color = base


func _arg_value(name: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(name + "="):
			return arg.trim_prefix(name + "=")
	return ""


func _capture_phone(path: String) -> void:
	for _i in 40:
		await get_tree().process_frame
		var hud: Variant = get_parent().get("hud")
		if hud != null:
			break
	for _i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_shot(path)
	get_tree().quit(0)


func _capture_sequence() -> void:
	for _i in 50:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_shot("/workspace/lulu-zhuogui/apps/game/build/shots/level1-cabin.png")
	get_parent().call("try_place", "ward", "door-bottom-seam")
	for _i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save_shot("/workspace/lulu-zhuogui/apps/game/build/shots/level1-ward.png")
	var slot: Variant = get_parent().call("_slot", "door-bottom-seam")
	var tag := ""
	if slot != null:
		tag = str(slot.talisman)
	print("SHOT ward %s" % tag)
	get_tree().quit(0)


func _save_shot(path: String) -> void:
	DirAccess.make_dir_recursive_absolute("/workspace/lulu-zhuogui/apps/game/build/shots")
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(path)
	print("SHOT save %s %s %sx%s" % [path, err, image.get_width(), image.get_height()])


func _box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = pos
	mesh_node.material_override = _solid(color)
	_world.add_child(mesh_node)
	return mesh_node


func _rail(pos: Vector3, length: float) -> void:
	var mesh_node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.025
	mesh.bottom_radius = 0.025
	mesh.height = length
	mesh.radial_segments = 8
	mesh_node.mesh = mesh
	mesh_node.position = pos
	mesh_node.rotation_degrees = Vector3(90, 0, 0)
	mesh_node.material_override = _solid(Color(0.48, 0.42, 0.34))
	_world.add_child(mesh_node)


func _solid(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _ray_aabb(origin: Vector3, dir: Vector3, box: AABB) -> float:
	var tmin := 0.0
	var tmax := 100000.0
	var bmin := box.position
	var bmax := box.position + box.size
	for axis in 3:
		var o := origin[axis]
		var d := dir[axis]
		var mn := bmin[axis]
		var mx := bmax[axis]
		if absf(d) < 0.0000001:
			if o < mn or o > mx:
				return -1.0
		else:
			var t1 := (mn - o) / d
			var t2 := (mx - o) / d
			if t1 > t2:
				var swap := t1
				t1 = t2
				t2 = swap
			tmin = maxf(tmin, t1)
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return -1.0
	if tmax < 0.0:
		return -1.0
	return tmin
