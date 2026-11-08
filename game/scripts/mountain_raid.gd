class_name MountainRaid
extends Control
## Zwischensequenz nach Mission 16 (ch17): Die Gruppe erreicht die verschneiten Berge (Schnee-Biom, Schneetreiben), die Frischlinge rasen aus dem Hinterhalt vorbei,
## schnappen sich den Sack und sind so schnell weg, wie sie gekommen waren. Alles in 3D mit den Chibi-Sprites,
## Kinobalken, Kamerafahrt und Untertiteln fuer die Sprueche. Klick oder Leertaste ueberspringt. Signal finished am Ende.

signal finished

const PARTY := ["maedchen_baer", "ritter", "hund", "elisabeth", "robo"]
const SPEED := 1.35                    # Gehtempo der Gruppe (m/s)
const STOP_T := 9.0                    # ab hier steht die Gruppe
const T_RUSH := 8.6                    # Frischlinge brechen aus dem Hinterhalt
const T_GRAB := 12.0                   # sie schnappen den Sack
const T_GONE := 17.0                   # und sind aus dem Bild
const SPACING := 1.25
const WIND := Vector3(-1.0, -0.10, 0.28)       # Richtung der Schneeflocken
const CAPTIONS := [
	[9.4, 2.4, "Frischling", "Hehe, da isser! Der dicke blaue Sack!", Color(1.0, 0.7, 0.55)],
	[11.7, 1.7, "Sack", "Huch! Ich bin nur ein Sack!", Color(0.6, 0.8, 1.0)],
	[13.1, 2.4, "Frischlinge", "Der Chef wollte was Blaues! Jetzt hat er was Blaues!", Color(1.0, 0.7, 0.55)],
	[15.3, 2.6, "Frischlinge", "Tschüss, ihr alten Fossile! Nich' hauen!", Color(1.0, 0.7, 0.55)],
	[18.4, 2.6, "Sack", "Ich bin pleite, nicht umsonst! Wer zahlt meine Ware?!", Color(0.6, 0.8, 1.0)],
]

var duration := 27.0
var kicker := ""
var title := "Am Fuß der Berge"
var party_ids: Array = PARTY.duplicate()

var _vp: SubViewport
var _cam: Camera3D
var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _done := false
var _skipping := false
var _cam_x := 0.0
var _shake := 0.0
var _figs: Array[Dictionary] = []
var _sack: Dictionary = {}
var _boars: Node3D
var _boar_sprite: Sprite3D
var _black: ColorRect
var _flash: ColorRect
var _cap: Label
var _tweens: Array[Tween] = []
var _next_puff := 0.0
var _said: Dictionary = {}
var _exclaimed := false
var _poofed := false
var _puff_tex: Texture2D
var _shadow_tex: GradientTexture2D
var _snow_near: GPUParticles3D
var _snow_far: GPUParticles3D
var _wind: AudioStreamPlayer
var music_path := "res://assets/audio/frischlinge_jagd.mp3"     # Thema der Frischlinge (Gemini, Variante C: lustig und dramatisch)
const MUSIC_START := 1.5      # Szenenzeit, ab der die Musik leise (schleichender Teil) unter der Wanderung beginnt
const MUSIC_OFFSET := 8.1     # Einstieg in die Datei: der grosse Blechbläser-Schlag (15,5 s) trifft den Ausbruch (T_RUSH + 0,3)
var _music: AudioStreamPlayer


func setup(data := {}) -> void:
	duration = float(data.get("duration", duration))
	kicker = str(data.get("kicker", kicker))
	title = str(data.get("title", title))
	music_path = str(data.get("music", music_path))
	if data.has("party"):
		party_ids = (data["party"] as Array).filter(func(id: String) -> bool: return id != "haendler" and ResourceLoader.exists("res://assets/tokens/%s.png" % id)).slice(0, 6)


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.seed = 21
	_noise.seed = 5
	_noise.frequency = 0.06
	_puff_tex = load("res://assets/fx/fx_smoke.png")
	_shadow_tex = _make_shadow_tex()
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
	_build_cast()
	_build_snow()
	_cam = Camera3D.new()
	_cam.fov = 34.0
	_cam.far = 300.0
	_vp.add_child(_cam)
	_build_overlay()
	_cam_x = _party_center(0.0)
	_step(0.0)
	_start_wind()


# ------------------------------------------------------------------ Aufbau

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.4, 0.48, 0.6)
	sm.sky_horizon_color = Color(0.8, 0.84, 0.92)
	sm.ground_horizon_color = Color(0.76, 0.8, 0.9)
	sm.ground_bottom_color = Color(0.5, 0.55, 0.65)
	sm.sun_angle_max = 25.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	env.fog_enabled = true
	env.fog_light_color = Color(0.74, 0.79, 0.88)
	env.fog_density = 0.017
	env.fog_sky_affect = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -35, 0)      # fahles Licht hinter dem Schleier der Wolken
	sun.light_color = Color(0.74, 0.8, 0.95)
	sun.light_energy = 0.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	_vp.add_child(sun)
	var land := MeshInstance3D.new()
	land.mesh = _terrain_mesh()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.metallic_specular = 0.0
	land.material_override = m
	_vp.add_child(land)
	var rocks := [load("res://assets/fx/fx_eisfels.png"), load("res://assets/fx/fx_eisfels.png")]
	var trees := [load("res://assets/fx/fx_schneefichte1.png"), load("res://assets/fx/fx_schneefichte2.png"), load("res://assets/fx/fx_schneehaufen.png")]
	for i in 110:      # Kulissen hinter dem Weg: Felsen, Fichten, Buesche (die Bahn z in -4..6 bleibt frei, die Kamera faehrt davor)
		var x := _rng.randf_range(-30.0, 100.0)
		var z := _rng.randf_range(-18.0, -5.5)
		if _rng.randf() < 0.4:
			_add_prop(rocks[_rng.randi() % 2], Vector3(x, _height(x, z), z), _rng.randf_range(1.6, 4.2), Color(0.8, 0.86, 0.98))
		else:
			_add_prop(trees[_rng.randi() % 3], Vector3(x, _height(x, z), z), _rng.randf_range(1.6, 3.6), Color(0.82, 0.88, 0.98))
	for i in 26:       # Gipfel: nahe Felsmassive und ferne im Dunst, damit die Berge ueber dem Pfad aufragen
		var fx := -30.0 + float(i) * 5.5
		var fz := -20.0 - float(i % 3) * 6.0 - _rng.randf_range(0.0, 3.0)
		_add_prop(rocks[i % 2], Vector3(fx, _height(fx, fz) - 1.0, fz), _rng.randf_range(14.0, 24.0) + float(i % 3) * 5.0, Color(0.62, 0.7, 0.86).lerp(Color(0.5, 0.58, 0.78), float(i % 3) / 2.0))


func _add_prop(tex: Texture2D, pos: Vector3, size: float, tint: Color) -> void:
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = size / maxf(tex.get_width(), tex.get_height())
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.shaded = false
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.offset = Vector2(0, tex.get_height() / 2.0 - 6.0)
	sp.modulate = tint
	sp.position = pos
	_vp.add_child(sp)


## Gelaende: flacher Pfad entlang x, hinten (negatives z) steigt die Gebirgswand an, vorn niedrige Huegel.
func _height(x: float, z: float) -> float:
	var base := 0.035 * x
	var back := pow(maxf(0.0, -z - 4.5), 1.2) * 0.17
	var front := pow(maxf(0.0, z - 9.5), 1.3) * 0.3
	var rough := _noise.get_noise_2d(x, z) * 1.4
	var trail := smoothstep(2.8, 0.8, absf(z))
	return base + back + front + rough * (1.0 - trail * 0.9)


func _terrain_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0 := -50.0
	var x1 := 120.0
	var z0 := -50.0
	var z1 := 16.0
	var step := 1.2
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
				for v: Vector3 in tri:
					var n := _normal_at(v.x, v.z)
					st.set_color(_ground_color(v, n))
					st.set_normal(n)
					st.add_vertex(v)
	return st.commit()


## Bodenfarbe je Eckpunkt (nicht je Dreieck: sonst entstehen Zackenmuster): Gras, Fels mit der Hoehe, Staubpfad.
func _ground_color(v: Vector3, n: Vector3) -> Color:
	var rock := smoothstep(0.8, 0.5, n.y)
	var high := smoothstep(1.0, 7.0, v.y)
	var col := Color(0.78, 0.83, 0.93).lerp(Color(0.62, 0.68, 0.82), clampf(high, 0.0, 1.0) * 0.6)      # Schnee, in der Hoehe blaeulicher
	col = col.lerp(Color(0.3, 0.32, 0.4), rock * 0.85)                                              # steile Flaechen zeigen dunklen Fels
	col = col.lerp(Color(0.62, 0.68, 0.8), smoothstep(-7.0, -14.0, v.z) * 0.5)                        # ferne Haenge im Dunst
	return col.lerp(Color(0.66, 0.72, 0.84), smoothstep(2.4, 1.0, absf(v.z)) * 0.8)                  # festgetretene Spur


func _normal_at(x: float, z: float) -> Vector3:
	var e := 0.4
	return Vector3(_height(x - e, z) - _height(x + e, z), 2.0 * e, _height(x, z - e) - _height(x, z + e)).normalized()


## Schneetreiben: feine schnelle Flocken und grosse weiche Fetzen nah an der Kamera (folgen der Kamera, siehe _step).
func _flake_mesh(size: float) -> QuadMesh:
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
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = gt
	m.albedo_color = Color(1, 1, 1, 0.85)
	m.vertex_color_use_as_albedo = true
	q.material = m
	return q


func _snow_layer(amount: int, size: float, speed_min: float, speed_max: float, box: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 3.0
	p.preprocess = 3.0
	p.local_coords = false
	p.visibility_aabb = AABB(-box * 2.0, box * 4.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = WIND.normalized()
	pm.spread = 10.0
	pm.initial_velocity_min = speed_min
	pm.initial_velocity_max = speed_max
	pm.gravity = Vector3(-1.5, -0.8, 0.3)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.6
	pm.turbulence_noise_scale = 1.4
	pm.scale_min = 0.5
	pm.scale_max = 1.5
	p.process_material = pm
	p.draw_pass_1 = _flake_mesh(size)
	return p


func _build_snow() -> void:
	_snow_near = _snow_layer(3500, 0.1, 3.5, 6.0, Vector3(11, 4, 6))
	_snow_far = _snow_layer(260, 0.34, 2.0, 3.5, Vector3(12, 4, 8))
	_vp.add_child(_snow_near)
	_vp.add_child(_snow_far)


## Windrauschen (assets/audio/wind_sturm.wav): blendet ein und am Ende wieder aus.
func _start_wind() -> void:
	var st: AudioStreamWAV = load("res://assets/audio/wind_sturm.wav")
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_end = int(st.get_length() * st.mix_rate)
	_wind = AudioStreamPlayer.new()
	_wind.stream = st
	_wind.volume_db = -40.0
	add_child(_wind)
	_wind.play()
	var tw := _tween()
	tw.tween_property(_wind, "volume_db", -16.0, 2.5)
	tw.tween_interval(maxf(0.0, duration - 5.5))
	tw.tween_property(_wind, "volume_db", -40.0, 2.5)
	tw.tween_callback(func() -> void: _wind.stop())


func _make_shadow_tex() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.55))
	g.set_color(1, Color(0, 0, 0, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _make_figure(id: String, size: float) -> Dictionary:
	var tex: Texture2D = load("res://assets/tokens/%s.png" % id)
	var root := Node3D.new()
	_vp.add_child(root)
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = size / maxf(tex.get_width(), tex.get_height())
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.shaded = false
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.offset = Vector2(0, tex.get_height() / 2.0)
	sp.modulate = Color(0.9, 0.95, 1.0)
	root.add_child(sp)
	var shadow := Sprite3D.new()
	shadow.texture = _shadow_tex
	shadow.pixel_size = size * 0.9 / 64.0
	shadow.rotation_degrees = Vector3(-90, 0, 0)
	shadow.shaded = false
	shadow.transparent = true
	shadow.position = Vector3(0, 0.03, 0)
	root.add_child(shadow)
	return {"root": root, "sprite": sp, "shadow": shadow, "phase": _rng.randf() * TAU}


func _build_cast() -> void:
	for i in party_ids.size():
		var f := _make_figure(party_ids[i], 1.45)
		f["slot"] = i
		_figs.append(f)
	_sack = _make_figure("haendler", 1.2)
	_sack["slot"] = party_ids.size()
	_figs.append(_sack)
	_boars = Node3D.new()
	_vp.add_child(_boars)
	var bf := _make_figure("frischlinge", 1.5)
	_vp.remove_child(bf["root"])
	_boars.add_child(bf["root"])
	_boar_sprite = bf["sprite"]
	_boars.visible = false
	var e := _boar_end()      # Felsmassiv, in das die Schweine hineinrennen
	var rock_tex: Array = [load("res://assets/fx/fx_eisfels.png"), load("res://assets/fx/fx_eisfels.png")]
	_add_prop(rock_tex[0], Vector3(e.x - 0.6, _height(e.x, e.z - 1.1), e.z - 1.1), 8.0, Color(0.78, 0.84, 0.96))
	_add_prop(rock_tex[1], Vector3(e.x + 2.2, _height(e.x + 2.2, e.z - 0.9), e.z - 0.9), 5.5, Color(0.82, 0.88, 0.98))
	_add_prop(rock_tex[1], Vector3(e.x - 3.0, _height(e.x - 3.0, e.z - 0.8), e.z - 0.8), 5.0, Color(0.74, 0.8, 0.94))


func _build_overlay() -> void:
	var vg := GradientTexture2D.new()
	var vgrad := Gradient.new()
	vgrad.set_color(0, Color(0, 0, 0, 0.0))
	vgrad.set_color(1, Color(0, 0, 0, 0.62))
	vgrad.add_point(0.6, Color(0, 0, 0, 0.0))
	vg.gradient = vgrad
	vg.fill = GradientTexture2D.FILL_RADIAL
	vg.fill_from = Vector2(0.5, 0.5)
	vg.fill_to = Vector2(1.05, 0.95)
	vg.width = 256
	vg.height = 144
	var vtex := TextureRect.new()
	vtex.texture = vg
	vtex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vtex.stretch_mode = TextureRect.STRETCH_SCALE
	vtex.size = Vector2(1280, 720)
	vtex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vtex)
	_flash = ColorRect.new()
	_flash.color = Color(1, 0.95, 0.8, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	for k in 2:       # Kinobalken 2,39:1
		var b := ColorRect.new()
		b.color = Color.BLACK
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.size = Vector2(1280, 92)
		b.position = Vector2(0, 0 if k == 0 else 720 - 92)
		add_child(b)
	_cap = _label("", 30, Color.WHITE, UiTheme.F_BODY)
	_cap.position = Vector2(0, 596)
	_cap.size = Vector2(1280, 90)
	_cap.modulate.a = 0.0
	_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cap)
	var box := VBoxContainer.new()
	box.position = Vector2(0, 500)
	box.size = Vector2(1280, 120)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.modulate.a = 0.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	if kicker != "":
		box.add_child(_label(kicker, 30, UiTheme.GOLD, UiTheme.F_TITLE))
	box.add_child(_label(title, 52, Color(1.0, 0.97, 0.9), UiTheme.F_TITLE))
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	var fin := _tween()
	fin.tween_property(_black, "modulate:a", 0.0, 1.5).from(1.0)
	var tt := _tween()
	tt.tween_interval(1.6)
	tt.tween_property(box, "modulate:a", 1.0, 1.0)
	tt.tween_interval(3.4)
	tt.tween_property(box, "modulate:a", 0.0, 1.0)
	var out := _tween()
	out.tween_interval(duration - 1.6)
	out.tween_property(_black, "modulate:a", 1.0, 1.6)
	out.tween_callback(_finish)


func _tween() -> Tween:
	var tw := create_tween()
	_tweens.append(tw)
	return tw


func _label(text: String, size: int, color: Color, font: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08))
	return l


# ------------------------------------------------------------------ Ablauf

func _lead_x(t: float) -> float:
	return SPEED * minf(t, STOP_T)


func _slot_x(slot: int, t: float) -> float:
	return _lead_x(t) - float(slot) * SPACING


func _party_center(t: float) -> float:
	return _lead_x(t) - float(_figs.size() - 1) * SPACING / 2.0


## Ziel der Flucht: ein Felsmassiv am Fuss der Berge (die Schweine rennen hinein).
func _boar_end() -> Vector3:
	return Vector3(_slot_x(_figs.size() - 1, STOP_T) + 1.1 - 12.0, 0.0, -7.2)


func _boar_pos(t: float) -> Vector3:
	var sack_x := _slot_x(_figs.size() - 1, STOP_T)
	var target := sack_x + 1.1
	if t < T_RUSH:
		return Vector3(target + 24.0, 0.0, -1.3)
	if t < T_GRAB - 0.4:
		var k := smoothstep(0.0, 1.0, (t - T_RUSH) / (T_GRAB - 0.4 - T_RUSH))
		return Vector3(lerpf(target + 24.0, target, k), 0.0, -1.3)
	var e := _boar_end()
	var k2 := clampf((t - (T_GRAB + 0.3)) / (T_GONE - 0.4 - (T_GRAB + 0.3)), 0.0, 1.0)
	k2 = k2 * (0.55 + 0.45 * k2)      # nimmt Fahrt auf
	return Vector3(lerpf(target, e.x, k2), 0.0, lerpf(-1.3, e.z, k2))


func _put(root: Node3D, x: float, z: float, lift := 0.0) -> void:
	root.position = Vector3(x, _height(x, z) + lift, z)


func _step(delta: float) -> void:
	var t := _t
	var sack_idx := _figs.size() - 1
	var walking := t < STOP_T
	for f: Dictionary in _figs:
		var slot: int = f["slot"]
		var x := _slot_x(slot, t)
		var z := 0.35 if slot % 2 == 0 else -0.3
		var lift := 0.0
		var sp: Sprite3D = f["sprite"]
		if walking:
			lift = absf(sin(t * 7.0 + float(f["phase"]))) * 0.07
		var hop := 0.0
		if t >= T_GRAB - 0.5 and f != _sack:       # alle fahren herum und huepfen vor Schreck
			hop = absf(sin((t - T_GRAB + 0.5) * 9.0 + float(f["phase"]))) * 0.22 * clampf(1.0 - (t - T_GRAB) / 2.6, 0.0, 1.0)
			sp.flip_h = true
		lift += hop
		if f == _sack:
			if t >= T_GRAB + 0.1:      # wird hinter den Schweinen hergezogen: rechts von ihnen, etwas davor, kippt nach hinten
				var bp := _boar_pos(t)
				x = bp.x + 0.8
				z = bp.z + 0.12
				lift = absf(sin(t * 17.0 + 1.0)) * 0.1
				sp.rotation_degrees.z = -22.0 + sin(t * 13.0) * 6.0
				sp.flip_h = false
			elif t > 10.4 and t < 10.9:
				lift += sin((t - 10.4) / 0.5 * PI) * 0.4      # Sack merkt etwas: hoppst
		_put(f["root"], x, z, lift)
		if f == _sack:
			var fa := 1.0 - smoothstep(T_GONE - 0.6, T_GONE - 0.1, t)      # verschwindet mit den Schweinen im Fels
			sp.modulate.a = fa
			(f["root"] as Node3D).visible = t < T_GONE
	# Frischlinge
	if t >= T_RUSH and t < T_GONE:
		_boars.visible = true
		var bp2 := _boar_pos(t)
		var bounce := absf(sin(t * 17.0)) * 0.22
		if t > T_GRAB - 0.4 and t < T_GRAB + 0.3:
			bounce = sin((t - (T_GRAB - 0.4)) / 0.7 * PI) * 0.9      # Sprung auf den Sack
		_put(_boars, bp2.x, bp2.z, bounce)
		_boar_sprite.flip_h = true
		_boar_sprite.modulate.a = 1.0 - smoothstep(T_GONE - 0.6, T_GONE - 0.1, t)
		if t > T_GONE - 0.7 and not _said.has("arrive"):
			_said["arrive"] = true
			Sfx.play("crunch", -4)
			for i in 5:
				_dust(Vector3(bp2.x + _rng.randf_range(-0.7, 0.7), _height(bp2.x, bp2.z) + 0.4, bp2.z + 0.3), 1.6)
		if t >= _next_puff:
			_next_puff = t + 0.07
			_dust(Vector3(bp2.x + 0.8, _height(bp2.x, bp2.z) + 0.25, bp2.z + 0.15), 0.9)
	else:
		_boars.visible = false
	# Ereignisse
	if t >= MUSIC_START and _music == null:
		_start_music()
	if t >= T_RUSH and not _said.has("music_up"):
		_said["music_up"] = true
		_music_up()
	if t >= T_RUSH + 0.3 and not _said.has("rush"):
		_said["rush"] = true
		Sfx.play("v_grunt", -4)
		Sfx.play("v_grunt", -6, 1.15, 0.25)
	if t >= T_GRAB and not _poofed:
		_poofed = true
		_shake = 0.5
		Sfx.play("poof", -2)
		Sfx.play("v_sack", -2, 1.4)
		for i in 8:
			_dust(Vector3(_boar_pos(t).x + _rng.randf_range(-0.6, 0.6), _height(_boar_pos(t).x, -1.3) + 0.5, -1.0), 1.7)
		var fl := _tween()
		fl.tween_property(_flash, "color:a", 0.5, 0.05)
		fl.tween_property(_flash, "color:a", 0.0, 0.5)
	if t >= T_GRAB + 0.2 and not _exclaimed:
		_exclaimed = true
		for f: Dictionary in _figs:
			if f != _sack:
				_exclaim(f)
	for c: Array in CAPTIONS:
		if t >= float(c[0]) and not _said.has(c[0]):
			_said[c[0]] = true
			_caption(c)
	# Kamera
	var target := _party_center(t)
	var rate := 2.0
	var cz := 8.6
	var cy := 1.75
	if t >= T_RUSH - 1.0 and t < T_GRAB:
		var k := smoothstep(T_RUSH - 1.0, T_GRAB, t)
		target = lerpf(_party_center(t), _slot_x(sack_idx, t) + 1.5, k)
		cz = lerpf(8.6, 6.4, k)
		cy = lerpf(1.75, 1.15, k)
		rate = 3.0
	elif t >= T_GRAB and t < T_GONE + 1.0:
		target = clampf(_boar_pos(t).x + 3.0, -12.0, _party_center(STOP_T))
		cz = lerpf(6.4, 8.0, smoothstep(T_GRAB, T_GONE, t))
		cy = lerpf(1.15, 1.7, smoothstep(T_GRAB, T_GONE, t))
		rate = 3.2
	elif t >= T_GONE + 1.0:
		target = _party_center(STOP_T) - 1.0
		var k2 := smoothstep(T_GONE + 1.0, duration - 1.0, t)
		cz = lerpf(8.0, 10.0, k2)
		cy = lerpf(1.7, 2.6, k2)
		rate = 1.2
	_cam_x += (target - _cam_x) * (1.0 - exp(-rate * delta))
	var sh := Vector3.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		sh = Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), 0) * _shake * 0.35
	var g := _height(_cam_x, cz)
	_cam.position = Vector3(_cam_x, maxf(cy, g + 0.9) + sh.y, cz) + Vector3(sh.x, 0, 0)
	_cam.look_at(Vector3(_cam_x + sh.x, _cam.position.y - 0.1, 0.0), Vector3.UP)
	_snow_near.position = _cam.position + Vector3(2.0, 1.5, -5.0)
	_snow_far.position = _cam.position + Vector3(2.0, 1.5, -2.5)


func _dust(at: Vector3, size: float) -> void:
	var sp := Sprite3D.new()
	sp.texture = _puff_tex
	sp.pixel_size = size / maxf(_puff_tex.get_width(), _puff_tex.get_height())
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.transparent = true
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.modulate = Color(0.95, 0.97, 1.0, 0.8)
	sp.position = at
	sp.scale = Vector3.ONE * 0.4
	_vp.add_child(sp)
	var tw := sp.create_tween()
	tw.tween_property(sp, "scale", Vector3.ONE * 1.6, 0.9)
	tw.parallel().tween_property(sp, "modulate:a", 0.0, 0.9)
	tw.parallel().tween_property(sp, "position:y", at.y + 0.5, 0.9)
	tw.tween_callback(sp.queue_free)


func _exclaim(f: Dictionary) -> void:
	var tex: Texture2D = load("res://assets/fx/fx_exclaim.png")
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = 0.55 / maxf(tex.get_width(), tex.get_height())
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.position = Vector3(0, 1.85, 0)
	sp.scale = Vector3.ZERO
	(f["root"] as Node3D).add_child(sp)
	var tw := sp.create_tween()
	tw.tween_property(sp, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(1.4)
	tw.tween_property(sp, "modulate:a", 0.0, 0.3)
	tw.tween_callback(sp.queue_free)


func _caption(c: Array) -> void:
	var col: Color = c[4]
	_cap.text = "%s: %s" % [c[2], c[3]]
	_cap.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.45))
	var tw := _tween()
	tw.tween_property(_cap, "modulate:a", 1.0, 0.15)
	tw.tween_interval(float(c[1]) - 0.4)
	tw.tween_property(_cap, "modulate:a", 0.0, 0.25)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_step(delta)


func _input(event: InputEvent) -> void:
	if _t < 0.6 or _skipping:
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and event.pressed and not event.echo):
		get_viewport().set_input_as_handled()
		_skip()


## Frischlinge-Thema: beginnt leise und schleichend unter der Wanderung, der grosse Schlag faellt auf den Ausbruch.
func _start_music() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)
	if not ResourceLoader.exists(music_path):
		return
	_music.stream = load(music_path)
	_music.volume_db = -36.0
	_music.play(MUSIC_OFFSET)
	_tween().tween_property(_music, "volume_db", -15.0, 2.0)


## Ausbruch: Musik voll, Wind leiser, zum Ende der Szene ausblenden.
func _music_up() -> void:
	if _music == null or not _music.playing:
		return
	var tw := _tween()
	tw.tween_property(_music, "volume_db", -4.0, 0.4)
	tw.tween_interval(maxf(0.0, duration - _t - 3.0))
	tw.tween_property(_music, "volume_db", -40.0, 2.5)
	if _wind != null:
		_tween().tween_property(_wind, "volume_db", -26.0, 0.6)


## Abbrechen: kurz in Schwarz ueberblenden, dann beenden.
func _skip() -> void:
	_skipping = true
	for tw: Tween in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	create_tween().tween_property(_black, "modulate:a", 1.0, 0.45)
	if _wind != null:
		create_tween().tween_property(_wind, "volume_db", -50.0, 0.45)
	if _music != null and _music.playing:
		create_tween().tween_property(_music, "volume_db", -50.0, 0.45)
	await get_tree().create_timer(0.5).timeout
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
