class_name Interlude
extends Control
## Reisebild zwischen zwei Abschnitten: ein Standbild mit langsamem Zoom und Schwenk (Ken Burns), Titelkarte
## ("Kapitel 2" und Titel), Ein- und Ausblenden von Schwarz. Klick oder Leertaste ueberspringt.

signal finished

var image_path := "res://assets/ui/reise_schiff.jpg"
var kicker := ""
var title := ""
var duration := 8.0
var zoom_to := 1.16
var pan := Vector2(-40, -14)       # Verschiebung in Pixeln waehrend des Zooms
var scene3d := ""                  # "sea": Schiff faehrt in 3D ueber das Wasser (statt Standbild mit Ken Burns)
var _pic: TextureRect
var _cam: Camera3D
var _ship: MeshInstance3D
var _foam: Array = []
var _t := 0.0
var _sea_mat: ShaderMaterial
var _black: ColorRect
var _done := false
var _age := 0.0


func setup(data: Dictionary) -> void:
	image_path = data.get("image", image_path)
	kicker = data.get("kicker", "")
	title = data.get("title", "")
	scene3d = data.get("scene", "")
	duration = float(data.get("duration", duration))
	zoom_to = float(data.get("zoom", zoom_to))
	if data.has("pan"):
		pan = Vector2(data["pan"][0], data["pan"][1])


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if scene3d == "sea":
		_build_sea()
	else:
		_pic = TextureRect.new()
		_pic.texture = load(image_path)
		_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_pic.position = Vector2.ZERO
		_pic.size = Vector2(1280, 720)
		_pic.pivot_offset = Vector2(640, 360)
		add_child(_pic)
	var box := VBoxContainer.new()
	box.position = Vector2(0, 560)
	box.size = Vector2(1280, 130)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.modulate.a = 0.0
	add_child(box)
	box.add_child(_label(kicker, 34, UiTheme.GOLD))
	box.add_child(_label(title, _fit_size(title, 58, 1100.0), Color(1.0, 0.97, 0.85)))
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	var tw := create_tween()
	tw.tween_property(_black, "modulate:a", 0.0, 1.2).from(1.0)
	if _pic != null:
		var kb := create_tween().set_parallel(true)
		kb.tween_property(_pic, "scale", Vector2(zoom_to, zoom_to), duration).from(Vector2.ONE).set_trans(Tween.TRANS_SINE)
		kb.tween_property(_pic, "position", pan, duration).from(Vector2.ZERO).set_trans(Tween.TRANS_SINE)
	var tt := create_tween()
	tt.tween_interval(2.0)
	tt.tween_property(box, "modulate:a", 1.0, 1.0)
	tt.tween_interval(duration - 5.8)
	tt.tween_property(box, "modulate:a", 0.0, 0.8)
	var out := create_tween()
	out.tween_interval(duration - 1.2)
	out.tween_property(_black, "modulate:a", 1.0, 1.2)
	out.tween_callback(_finish)


func _process(delta: float) -> void:
	_age += delta
	if _cam != null:
		_t += delta
		_sail()


func _unhandled_input(event: InputEvent) -> void:
	if _age < 0.6:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo):
		get_viewport().set_input_as_handled()
		_finish()


## Offenes Meer in 3D: Wasser-Shader der Karten, das Schiff (Sprite mit Wasserlinie) faehrt nach rechts, die Kamera
## gleitet in einem weiten Bogen mit, tief ueber dem Wasser, dahinter die tiefe Abendsonne.
func _build_sea() -> void:
	var holder := SubViewportContainer.new()
	holder.stretch = true
	holder.position = Vector2.ZERO
	holder.size = Vector2(1280, 720)
	add_child(holder)
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	holder.add_child(vp)
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.45, 0.72)
	sky_mat.sky_horizon_color = Color(1.0, 0.76, 0.5)
	sky_mat.ground_horizon_color = Color(0.95, 0.7, 0.48)
	sky_mat.ground_bottom_color = Color(0.2, 0.34, 0.45)
	sky_mat.sun_angle_max = 40.0
	sky_mat.sky_curve = 0.12
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.96, 0.72, 0.5)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-7, 20, 0)
	sun.light_color = Color(1.0, 0.8, 0.55)
	sun.light_energy = 1.4
	vp.add_child(sun)
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(170, 170)
	plane.subdivide_width = 340
	plane.subdivide_depth = 340
	water.mesh = plane
	var wm := ShaderMaterial.new()
	wm.shader = load("res://shaders/sea.gdshader")
	_sea_mat = wm
	water.material_override = wm
	vp.add_child(water)
	var ship_tex: Texture2D = load("res://assets/fx/fx_schiff.png")
	_ship = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_ship.mesh = quad
	var ts := ship_tex.get_size()
	_ship.scale = Vector3(ts.x / maxf(ts.x, ts.y) * 5.2, ts.y / maxf(ts.x, ts.y) * 5.2, 1.0)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/ship_sprite.gdshader")
	sm.set_shader_parameter("tex", ship_tex)
	sm.render_priority = 2
	_ship.material_override = sm
	_ship.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vp.add_child(_ship)
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.0))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	grad.add_point(0.78, Color(1, 1, 1, 0.5))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	for k in 3:       # Bugwelle und Kielwasser als weiche Schaumringe
		var f := MeshInstance3D.new()
		var fq := QuadMesh.new()
		fq.size = Vector2(4.0 + k * 1.6, 4.0 + k * 1.6)
		f.mesh = fq
		f.rotation_degrees = Vector3(-90, 0, 0)
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.render_priority = 1
		fm.albedo_texture = gt
		fm.albedo_color = Color(1, 1, 1, 0.7 - k * 0.2)
		f.material_override = fm
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		vp.add_child(f)
		_foam.append(f)
	_cam = Camera3D.new()
	_cam.fov = 36
	_cam.far = 400.0
	vp.add_child(_cam)
	_sail()


## Wellenhoehe an dieser Stelle, dieselbe Formel wie sea_h() in shaders/sea.gdshader.
func sea_height(p: Vector2, t: float) -> float:
	return 0.30 * sin(p.dot(Vector2(0.55, 0.20)) + t * 1.3) + 0.18 * sin(p.dot(Vector2(-0.35, 0.80)) + t * 1.05 + 1.7) + 0.10 * sin(p.dot(Vector2(1.10, 0.60)) + t * 1.9 + 0.6)


func _sail() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	_sea_mat.set_shader_parameter("t_sea", _t)
	var x := 5.0 - _t * 0.9                                       # der Bug zeigt nach links: das Schiff faehrt nach links
	var h := sea_height(Vector2(x, 0.0), _t)
	_ship.position = Vector3(x, 1.9 + h * 0.9, 0.0)
	for i in _foam.size():
		var f: MeshInstance3D = _foam[i]
		f.position = Vector3(x + 0.5 * i, 0.04 + h * 0.9, 0.1)
		f.scale = Vector3(1.0 + 0.05 * sin(_t * 1.5 + i), 0.42, 1.0)
	var a := lerpf(0.55, -0.25, smoothstep(0.0, 1.0, k))          # Bogen: erst von vorn links, dann hinter dem Schiff vorbei
	var focus := Vector3(x - 0.6, 1.9, 0.0)
	_cam.position = focus + Vector3(-sin(a) * 8.5, 0.5 + k * 0.7, cos(a) * 8.5)
	_cam.position.y += sea_height(Vector2(_cam.position.x, _cam.position.z), _t) * 0.6
	_cam.look_at(focus)


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(UiTheme.F_TITLE))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 12)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
	return l


func _fit_size(text: String, max_size: int, max_width: float) -> int:
	var font := UiTheme.font(UiTheme.F_TITLE)
	var size: int = max_size
	while size > 24 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 24.0 > max_width:
		size -= 2
	return size
