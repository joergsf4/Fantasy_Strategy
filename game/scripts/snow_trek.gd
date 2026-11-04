class_name SnowTrek
extends Control
## Zwischensequenz im Schnee-Biom (Proof of Concept): Die Gruppe stapft im Gaensemarsch durch einen Schneesturm einen Pass hinauf, wie der Weg am
## Caradhras. Alles in 3D mit den Chibi-Sprites (ohne Animationsphasen: nur Stapf-Wippen), flache Kamera mit Fahrt, Schneetreiben, Nebel und Boeen.
## Klick oder Leertaste ueberspringt. Aufruf: SnowTrek.new(), setup({...}), als Control einhaengen; Signal finished am Ende.

signal finished

const PARTY := ["maedchen_baer", "ritter", "hund", "wendy", "bienenmaedchen", "robo"]
const SKY := Color(0.56, 0.61, 0.70)
const WIND := Vector3(-1.0, -0.22, 0.34)       # Richtung der Schneeflocken (von rechts hinten nach links vorn)

var duration := 24.0
var kicker := "Kapitel 3"
var title := "Der Pass im Schneesturm"
var _vp: SubViewport
var _cam: Camera3D
var _env: Environment
var _sun: DirectionalLight3D
var _figs: Array[Dictionary] = []
var _snow_near: GPUParticles3D
var _snow_far: GPUParticles3D
var _gust: ColorRect
var _black: ColorRect
var _bars: Array[ColorRect] = []
var _t := 0.0
var _age := 0.0
var _done := false
var _rng := RandomNumberGenerator.new()
var _noise := FastNoiseLite.new()
var _next_gust := 2.0
var _gust_k := 0.0              # 0 bis 1: wie stark die aktuelle Boee ist
var _cam_shake := 0.0


func setup(data := {}) -> void:
	duration = float(data.get("duration", duration))
	kicker = str(data.get("kicker", kicker))
	title = str(data.get("title", title))


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.seed = 7
	_noise.seed = 11
	_noise.frequency = 0.07
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.size = Vector2(1280, 720)
	add_child(holder)
	_vp = SubViewport.new()
	_vp.size = Vector2i(1280, 720)
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	holder.add_child(_vp)
	_build_world()
	_build_party()
	_build_snow()
	_build_overlay()
	_cam = Camera3D.new()
	_cam.fov = 34.0
	_cam.far = 220.0
	_vp.add_child(_cam)
	_step(0.0)


# ------------------------------------------------------------------ Aufbau

func _build_world() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = SKY
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.78, 0.84, 0.95)
	_env.ambient_light_energy = 0.62
	_env.fog_enabled = true
	_env.fog_light_color = SKY
	_env.fog_density = 0.021
	_env.fog_sky_affect = 1.0
	var we := WorldEnvironment.new()
	we.environment = _env
	_vp.add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-38, -35, 0)
	_sun.light_color = Color(0.85, 0.9, 1.0)
	_sun.light_energy = 1.1
	_vp.add_child(_sun)
	var land := MeshInstance3D.new()
	land.mesh = _terrain_mesh()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.metallic_specular = 0.0
	land.material_override = m
	_vp.add_child(land)
	# Kulissen: Schneefichten und Felsbrocken an den Haengen, im Nebel nur halb zu sehen
	var textures := [load("res://assets/fx/fx_schneefichte1.png"), load("res://assets/fx/fx_schneefichte2.png"), load("res://assets/fx/fx_eisfels.png"), load("res://assets/fx/fx_schneehaufen.png")]
	for i in 230:
		var x := _rng.randf_range(-25.0, 130.0)
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var z := side * _rng.randf_range(6.8, 16.0) if side < 0.0 else _rng.randf_range(11.5, 17.0)      # die Kamerabahn (z bis 9) bleibt frei
		var kind := _rng.randi_range(0, 3)
		if _rng.randf() < 0.45:
			kind = 2 if _rng.randf() < 0.5 else 0
		var size := _rng.randf_range(2.0, 5.0) if kind < 2 else (_rng.randf_range(2.0, 6.5) if kind == 2 else _rng.randf_range(0.7, 1.6))
		_add_prop(textures[kind], Vector3(x, _height(x, z), z), size)
	for i in 26:       # ferne dunkle Felsmassive (Caradhras): im Nebel nur Silhouetten
		var fx := _rng.randf_range(-20.0, 130.0)
		var fz := (1.0 if i % 2 == 0 else -1.0) * _rng.randf_range(19.0, 23.0)
		_add_prop(textures[2], Vector3(fx, _height(fx, fz) - 1.0, fz), _rng.randf_range(12.0, 22.0), Color(0.40, 0.43, 0.50))
	# Naechste Kulissen entlang des Weges (damit auch in der Naehe etwas steht)
	for i in 36:
		var x := -10.0 + float(i) * 3.6 + _rng.randf_range(-1.0, 1.0)
		var z := -_rng.randf_range(3.2, 6.3)           # nur hinter der Gruppe (Kameraseite bleibt frei, nichts verdeckt die Figuren)
		_add_prop(textures[_rng.randi_range(0, 2)], Vector3(x, _height(x, z), z), _rng.randf_range(1.6, 3.2))


func _add_prop(tex: Texture2D, pos: Vector3, size: float, tint := Color(0.88, 0.92, 1.0)) -> void:
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = size / maxf(tex.get_width(), tex.get_height())
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.shaded = false
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.offset = Vector2(0, tex.get_height() / 2.0 - 8.0)
	sp.modulate = tint
	sp.position = pos
	_vp.add_child(sp)


## Hoehe des Passes: steigt entlang des Weges (x), Talwaende links und rechts, in der Spur ist es flacher.
func _height(x: float, z: float) -> float:
	var base := 0.09 * x
	var wall := pow(maxf(0.0, absf(z) - 6.5), 1.5) * 0.5
	var rough := _noise.get_noise_2d(x * 1.0, z * 1.0) * 1.3
	var trail := smoothstep(2.6, 0.6, absf(z))
	return base + wall + rough * (1.0 - trail * 0.85)


func _terrain_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -30.0
	var x1 := 140.0
	var z0 := -22.0
	var z1 := 22.0
	var step := 0.9
	var nx := int((x1 - x0) / step)
	var nz := int((z1 - z0) / step)
	var verts: Array[Vector3] = []
	verts.resize((nx + 1) * (nz + 1))
	for i in nx + 1:
		for j in nz + 1:
			var x := x0 + float(i) * step
			var z := z0 + float(j) * step
			verts[i * (nz + 1) + j] = Vector3(x, _height(x, z), z)
	for i in nx:
		for j in nz:
			var a := verts[i * (nz + 1) + j]
			var b := verts[(i + 1) * (nz + 1) + j]
			var c := verts[(i + 1) * (nz + 1) + j + 1]
			var d := verts[i * (nz + 1) + j + 1]
			for tri: Array in [[a, b, c], [a, c, d]]:
				var n: Vector3 = ((tri[1] - tri[0]) as Vector3).cross(tri[2] - tri[0]).normalized()
				if n.y < 0.0:
					n = -n
				var rock := smoothstep(0.78, 0.45, n.y)         # steile Flaechen zeigen dunklen Fels
				var col := Color(0.88, 0.92, 0.99).lerp(Color(0.26, 0.28, 0.34), rock * 0.9)
				col = col.lerp(Color(0.78, 0.85, 0.96), clampf(0.5 - n.y * 0.3, 0.0, 0.4))
				for v: Vector3 in tri:
					st.set_color(col)
					st.set_normal(n)
					st.add_vertex(v)
	return st.commit()


func _build_party() -> void:
	var n := PARTY.size()
	for i in n:
		var id: String = PARTY[i]
		var path := "res://assets/tokens/%s.png" % id
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		var root := Node3D.new()
		_vp.add_child(root)
		var sp := Sprite3D.new()
		sp.texture = tex
		sp.pixel_size = 1.45 / maxf(tex.get_width(), tex.get_height())
		sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sp.shaded = false
		sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sp.offset = Vector2(0, tex.get_height() / 2.0)
		sp.modulate = Color(0.92, 0.95, 1.0)       # leicht bereift
		root.add_child(sp)
		# Schneeverwehung vor den Fuessen: die Figur stapft knietief durch den Schnee
		var drift := Sprite3D.new()
		var dtex: Texture2D = load("res://assets/fx/fx_schneehaufen.png")
		drift.texture = dtex
		drift.pixel_size = 1.05 / maxf(dtex.get_width(), dtex.get_height())
		drift.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		drift.shaded = false
		drift.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		drift.offset = Vector2(0, dtex.get_height() / 2.0)
		drift.modulate = Color(0.94, 0.97, 1.0)
		drift.position = Vector3(0, 0.0, 0.16)
		root.add_child(drift)
		var puff := _feet_puffs()
		root.add_child(puff)
		_figs.append({"root": root, "sprite": sp, "drift": drift, "slot": i, "phase": _rng.randf() * TAU, "fly": id == "bienenmaedchen"})


func _feet_puffs() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 14
	p.lifetime = 1.0
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(-1.0, 0.7, 0.2)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.4
	pm.gravity = Vector3(0, -0.8, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	p.process_material = pm
	p.draw_pass_1 = _flake_mesh(0.22)
	p.position = Vector3(0.0, 0.2, 0.0)
	return p


func _flake_tex() -> Texture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1.0))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	return gt


func _flake_mesh(size: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = _flake_tex()
	m.albedo_color = Color(1, 1, 1, 0.85)
	m.vertex_color_use_as_albedo = true
	q.material = m
	return q


func _snow_layer(amount: int, size: float, speed_min: float, speed_max: float, box: Vector3, alpha: float, streak := false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 3.2
	p.preprocess = 3.2
	p.local_coords = false
	p.visibility_aabb = AABB(-box * 2.0, box * 4.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = WIND.normalized()
	pm.spread = 8.0
	pm.initial_velocity_min = speed_min
	pm.initial_velocity_max = speed_max
	pm.gravity = Vector3(-1.5, -0.6, 0.4)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.4
	pm.turbulence_noise_scale = 1.6
	pm.scale_min = 0.5
	pm.scale_max = 1.6
	pm.particle_flag_align_y = streak            # Flocken als Streifen in Windrichtung (Schneetreiben)
	p.process_material = pm
	var mesh := _flake_mesh(size)
	if streak:
		mesh.size = Vector2(size * 0.45, size * 5.5)
	(mesh.material as StandardMaterial3D).albedo_color = Color(1, 1, 1, alpha)
	p.draw_pass_1 = mesh
	return p


func _build_snow() -> void:
	_snow_near = _snow_layer(3400, 0.1, 17.0, 24.0, Vector3(12, 5, 10), 0.85)         # feine Flocken, schnell
	_snow_far = _snow_layer(300, 0.55, 9.0, 14.0, Vector3(14, 5, 12), 0.35)            # grosse weiche Fetzen nah an der Kamera
	_vp.add_child(_snow_near)
	_vp.add_child(_snow_far)
	if OS.get_environment("SNOW_DEBUG") == "nofar":
		_snow_far.visible = false
	if OS.get_environment("SNOW_DEBUG") == "noterrain":
		_snow_far.visible = false
		_snow_near.visible = false


func _build_overlay() -> void:
	_gust = ColorRect.new()
	_gust.color = Color(0.9, 0.94, 1.0, 0.0)
	_gust.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gust)
	for k in 2:       # Kinobalken 2,39:1
		var b := ColorRect.new()
		b.color = Color.BLACK
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.size = Vector2(1280, 92)
		b.position = Vector2(0, 0 if k == 0 else 720 - 92)
		add_child(b)
		_bars.append(b)
	var box := VBoxContainer.new()
	box.position = Vector2(0, 520)
	box.size = Vector2(1280, 120)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.modulate.a = 0.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.add_child(_label(kicker, 32, UiTheme.GOLD))
	box.add_child(_label(title, 54, Color(1.0, 0.97, 0.9)))
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	create_tween().tween_property(_black, "modulate:a", 0.0, 1.6).from(1.0)
	var tt := create_tween()
	tt.tween_interval(3.0)
	tt.tween_property(box, "modulate:a", 1.0, 1.2)
	tt.tween_interval(4.2)
	tt.tween_property(box, "modulate:a", 0.0, 1.0)
	var out := create_tween()
	out.tween_interval(duration - 1.6)
	out.tween_property(_black, "modulate:a", 1.0, 1.6)
	out.tween_callback(_finish)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(UiTheme.F_TITLE))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.07, 0.1))
	return l


# ------------------------------------------------------------------ Ablauf

func _process(delta: float) -> void:
	_age += delta
	_t += delta
	_step(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _age < 0.6:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


## Gruppe, Kamera, Schnee und Boeen zum Zeitpunkt _t. delta = 0 fuer den Aufbau.
func _step(delta: float) -> void:
	var speed := 1.25 * (1.0 - 0.35 * _gust_k)          # in der Boee wird langsamer gestapft
	var lead_x := -4.0 + _t * speed
	# Gruppe im Gaensemarsch: Anfuehrerin vorn, Abstand 1,35 Felder, leichte Schlangenlinie der Spur
	for f in _figs:
		var i: int = f["slot"]
		var x := lead_x - float(i) * 1.05
		var z := sin(x * 0.35) * 0.45 + (0.15 if i % 2 == 0 else -0.15)
		var bob := absf(sin(_t * 3.1 + float(f["phase"]))) * 0.085
		var fly: bool = f["fly"]
		var root: Node3D = f["root"]
		root.position = Vector3(x, _height(x, z) - 0.16 + (0.42 + sin(_t * 2.2) * 0.1 if fly else bob), z)
		var sp: Sprite3D = f["sprite"]
		sp.scale = Vector3(1.0, 1.0 - bob * 0.5, 1.0)
		sp.flip_h = false
		(f["drift"] as Sprite3D).visible = not fly
	# Kamera: flach, erst seitlich dicht am Zug, dann nach vorn wandernd und schliesslich schraeg von vorn
	var k := clampf(_t / duration, 0.0, 1.0)
	var mid_x := lead_x - 2.2
	var side := lerpf(9.0, 7.0, smoothstep(0.0, 0.5, k))
	var ang := lerpf(-0.18, 0.62, smoothstep(0.25, 0.9, k))      # Winkel um die Gruppe
	var cx := mid_x + sin(ang) * side * 1.5
	var cz := cos(ang) * side
	var cy := _height(cx, cz) + lerpf(0.7, 1.05, k)
	cy = maxf(cy, _height(mid_x, 0.0) + 0.8)
	_cam_shake = lerpf(_cam_shake, _gust_k, minf(1.0, delta * 3.0))
	var shake := Vector3(sin(_t * 31.0), sin(_t * 23.0 + 1.0) * 0.7, sin(_t * 27.0 + 2.0)) * 0.018 * (0.4 + _cam_shake * 1.6)
	_cam.position = Vector3(cx, cy, cz) + shake
	var look := Vector3(mid_x + 0.4, _height(mid_x, 0.0) + 0.75, 0.0)
	_cam.look_at(look)
	_cam.fov = lerpf(37.0, 31.0, smoothstep(0.0, 1.0, k))
	# Schnee folgt der Kamera
	_snow_near.position = _cam.position + Vector3(3.5, 2.0, -1.5)
	_snow_far.position = _cam.position + Vector3(2.5, 1.5, -2.0)
	_sun.rotation_degrees.y = -35.0 + sin(_t * 0.4) * 6.0
	# Boeen: kurze Schneewaende, dichter Nebel, Kamerawackeln
	if delta > 0.0:
		_next_gust -= delta
		if _next_gust <= 0.0:
			_next_gust = _rng.randf_range(4.0, 7.0)
			var tw := create_tween()
			tw.tween_property(self, "_gust_k", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
			tw.tween_interval(1.4)
			tw.tween_property(self, "_gust_k", 0.0, 1.8).set_trans(Tween.TRANS_SINE)
			Sfx.play("whoosh_l", -6.0, 0.35)
			Sfx.play("whoosh_l", -9.0, 0.55, 0.4)
	_env.fog_density = 0.021 + 0.05 * _gust_k + 0.004 * sin(_t * 0.7)
	_gust.color.a = 0.40 * _gust_k * (0.8 + 0.2 * sin(_t * 17.0))
	_snow_near.speed_scale = 1.0 + 0.5 * _gust_k
