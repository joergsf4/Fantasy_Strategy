class_name Stage
extends Node
## Die Spielkarte als Buehne: Titelbild und Dialoge laufen davor (Tilt-Shift, schwebende Kamera, Abdunklung),
## danach wird dieselbe Karte zum Schlachtfeld.

var map_data: Dictionary
var unit_defs: Dictionary
var battle: Battle
var super_music := Callable()      # von main gesetzt: func(on: bool)
var secret_runner := Callable()     # von main gesetzt: async func(secret)
var dialogue_runner := Callable()   # von main gesetzt: async func(lines)
var party: Party         # Zustand der Heldengruppe (Rucksack, Ausruestung); null = Standardausstattung
var mode := "title"
var _t := 22.0
var _fx_layer: CanvasLayer
var _fx_mat: ShaderMaterial
var _dim: ColorRect
var _flyover_clouds: Node3D


func setup(map: Dictionary, defs: Dictionary) -> void:
	map_data = map
	unit_defs = defs


func _ready() -> void:
	_fx_layer = CanvasLayer.new()
	_fx_layer.layer = 1
	add_child(_fx_layer)
	var fx := ColorRect.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_mat = ShaderMaterial.new()
	_fx_mat.shader = load("res://shaders/tilt_shift.gdshader")
	fx.material = _fx_mat
	_fx_layer.add_child(fx)
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.color = Color(0.02, 0.03, 0.08, 0.0)
	_fx_layer.add_child(_dim)
	new_battle()
	set_mode("title")


## Frisches Schlachtfeld (auch fuer einen neuen Versuch nach einer Niederlage).
func new_battle() -> void:
	if battle != null:
		battle.queue_free()
	battle = Battle.new()
	battle.setup(map_data, unit_defs)
	battle.dialogue_runner = dialogue_runner
	battle.secret_runner = secret_runner
	battle.super_music = super_music
	battle.loadout = party.loadout() if party != null else Items.defs().get("loadout_chapter1", {})
	add_child(battle)
	battle.enter_title_mode()


func set_mode(m: String) -> void:
	mode = m
	match m:
		"title":
			_dim.color.a = 0.0
			_set_fx(0.55, 0.22, 1.5, 1.12)
		"dialog":
			_dim.color.a = 0.34
			_set_fx(0.5, 0.26, 1.3, 1.04)
		"flyover":
			_dim.color.a = 0.0
			mission_one_flyover_at(0.0)
			_create_flyover_clouds()
	_fx_layer.visible = m not in ["battle", "flyover", "cutscene"] and Settings.tilt_on()


func mission_one_flyover_at(progress: float) -> void:
	var focus := Vector3(5.5, 0.0, 7.0).lerp(Vector3(9.0, 0.0, 2.7), clampf(progress, 0.0, 1.0))
	battle.cam.fov = 40.0
	battle.cam.position = focus + Vector3(-1.5, 3.8, 7.8)
	battle.cam.look_at(focus + Vector3(0, 0.5, 0))


func mission_twenty_one_camera() -> void:
	set_mode("cutscene")
	var focus := Vector3(6.3, 0.0, 3.4)
	battle.cam.fov = 38.0
	battle.cam.position = focus + Vector3(0.0, 7.0, 8.5)
	battle.cam.look_at(focus + Vector3(0.0, 0.4, 0.0))


func restore_dialog_camera() -> void:
	_flyover_clouds.queue_free()
	_flyover_clouds = null
	set_mode("dialog")
	_update_camera(0.0)


## Nachthimmel fuer den flachen Hafenblick (Blick nach Suedwesten): fest in der Welt hinter den Huegeln (innerhalb der Sichtweite der Kamera, cam.far = 120), damit beim Schwenk nichts mitwandert.
## Farbverlauf (tiefes Nachtblau bis fahler Horizont), Mond mit Lichthof, dunkle Regenwolken (vorhandene Schaefchenwolken, eingefaerbt).
var _night_sky: Node3D

func _create_night_sky() -> void:
	# Fest in der Welt, senkrecht zur mittleren Blickrichtung (Suedwesten): Mitte bei Steg + 80 Einheiten Richtung (-0.82, 0.57)
	_night_sky = Node3D.new()
	battle.add_child(_night_sky)
	_night_sky.position = Vector3(-57.0, 26.0, 52.0)
	_night_sky.rotation_degrees = Vector3(0, 125.0, 0)      # Vorderseite (lokal +z) zeigt zum Steg: Mond und Wolken liegen davor, lokal +x ist im Bild rechts
	var grad := Gradient.new()
	grad.set_color(0, Color(0.03, 0.04, 0.1))
	grad.set_color(1, Color(0.2, 0.24, 0.36))
	grad.add_point(0.75, Color(0.1, 0.12, 0.24))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	_night_sky.add_child(_sky_quad(gt, Vector3(0, 0, 0), Vector2(320.0, 90.0), Color.WHITE))
	var glow := Gradient.new()
	glow.set_color(0, Color(1.0, 0.98, 0.88, 1.0))
	glow.set_color(1, Color(0.6, 0.7, 1.0, 0.0))
	glow.add_point(0.16, Color(0.98, 0.96, 0.86, 1.0))
	glow.add_point(0.2, Color(0.7, 0.78, 1.0, 0.35))
	var gm := GradientTexture2D.new()
	gm.gradient = glow
	gm.fill = GradientTexture2D.FILL_RADIAL
	gm.fill_from = Vector2(0.5, 0.5)
	gm.fill_to = Vector2(1.0, 0.5)
	_night_sky.add_child(_sky_quad(gm, Vector3(MOON_X, -15.0, 2.8), Vector2(26.0, 26.0), Color.WHITE))
	var clouds: Texture2D = load("res://assets/fx/fx_schaefchenwolken.png")
	var spots := [[Vector3(42.0, -4.0, 2.0), 44.0, 0.85], [Vector3(2.0, -10.0, 2.5), 52.0, 0.85], [Vector3(MOON_X + 4.0, -19.0, 3.2), 26.0, 0.35], [Vector3(70.0, -12.0, 2.0), 46.0, 0.8], [Vector3(-20.0, -2.0, 2.2), 40.0, 0.7]]
	for c: Array in spots:
		var w: float = c[1]
		_night_sky.add_child(_sky_quad(clouds, c[0], Vector2(w, w * clouds.get_height() / clouds.get_width()), Color(0.3, 0.34, 0.48, c[2])))


const MOON_X := 20.0      # Mond auf der Himmelsflaeche (lokal): rechts oberhalb der Gruppe


func _sky_quad(tex: Texture2D, pos: Vector3, size: Vector2, tint: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex
	m.albedo_color = tint
	m.disable_fog = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	return mi


func _create_flyover_clouds() -> void:
	_flyover_clouds = Node3D.new()
	battle.add_child(_flyover_clouds)
	var texture: Texture2D = load("res://assets/fx/fx_schaefchenwolken.png")
	var cam := battle.cam
	var sky := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(180.0, 100.0)
	sky.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.37, 0.65, 0.92)
	sky.material_override = material
	sky.transform = Transform3D(cam.basis, cam.position - cam.basis.z * 100.0)
	_flyover_clouds.add_child(sky)
	for i in 3:
		var cloud := Sprite3D.new()
		cloud.texture = texture
		cloud.pixel_size = 18.0 / texture.get_width()
		cloud.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		cloud.shaded = false
		cloud.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		cloud.flip_h = i == 1
		cloud.position = cam.position - cam.basis.z * 80.0 + cam.basis.x * (float(i - 1) * 26.0) + cam.basis.y * 27.0
		_flyover_clouds.add_child(cloud)


func _set_fx(y: float, width: float, blur: float, sat: float) -> void:
	_fx_mat.set_shader_parameter("focus_y", y)
	_fx_mat.set_shader_parameter("focus_width", width)
	_fx_mat.set_shader_parameter("blur_max", blur)
	_fx_mat.set_shader_parameter("saturation", sat)


## Hinter die Dialoge nach dem Kampf: Karte mit den Ueberlebenden.
func backdrop_again() -> void:
	battle.enter_title_mode()
	set_mode("dialog")


func start_battle() -> void:
	set_mode("battle")
	await battle.exit_title_mode()


func _process(delta: float) -> void:
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	if mode in ["battle", "flyover", "cutscene"] or battle == null or battle.cam == null:
		return
	_t += delta
	var cam := battle.cam
	var w := float(battle.grid.width)
	var h := float(battle.grid.height)
	if mode == "title":
		var u := 0.5 - 0.5 * cos(_t * TAU / 110.0)
		var focus := Vector3(lerpf(1.5, w - 2.5, u), 0.0, (h - 1.0) * 0.5 + sin(_t * 0.09) * 1.3)
		cam.fov = 32.0
		cam.position = focus + Vector3(sin(_t * 0.11) * 0.8, 8.4 + sin(_t * 0.07) * 0.5, 8.2)
		cam.look_at(focus + Vector3(0, 0.2, 0))
	elif battle.map_data.get("dialog_cam", "") == "flach":
		# Kartenfeld "dialog_cam": "flach" (Hafen in Kapitel 2): flacher Blick wie beim Einstieg in Mission 1,
		# von Westen ueber das Dorf aufs Meer und den Horizont, langsamer Schwenk entlang der Kueste
		if _night_sky == null or not is_instance_valid(_night_sky):
			_create_night_sky()
		var u3 := 0.5 - 0.5 * cos(_t * TAU / 150.0)
		# Die Gruppe steht am Steg (Reihe 6), gerade vom Schiff (11, 7) gekommen: Kamera von Nordosten ueber dem Wasser,
		# Gruppe in der Mitte, Schiff links vorn, dahinter das Dorf und der Nachthimmel
		var focus3 := Vector3(lerpf(8.3, 7.6, u3), 0.0, lerpf(5.6, 6.2, u3))
		cam.fov = 40.0
		cam.position = focus3 + Vector3(6.4, 2.6, -4.4)
		cam.look_at(focus3 + Vector3(0.9, 1.1, 1.3))      # Blickpunkt links neben der Gruppe: sie steht rechts im Bild, neben dem Sprecher-Portrait
	else:
		# Dialog: naeher dran, langsamer Schwenk ueber das Schlachtfeld
		var u2 := 0.5 - 0.5 * cos(_t * TAU / 170.0)
		var focus2 := Vector3(lerpf(2.0, w - 3.0, u2), 0.0, (h - 1.0) * 0.55 + sin(_t * 0.06) * 0.8)
		cam.fov = 34.0
		cam.position = focus2 + Vector3(sin(_t * 0.08) * 0.5, 6.2, 7.0)
		cam.look_at(focus2 + Vector3(0, 0.3, 0))
