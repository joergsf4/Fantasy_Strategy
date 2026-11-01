class_name Stage
extends Node
## Die Spielkarte als Buehne: Titelbild und Dialoge laufen davor (Tilt-Shift, schwebende Kamera, Abdunklung),
## danach wird dieselbe Karte zum Schlachtfeld.

var map_data: Dictionary
var unit_defs: Dictionary
var battle: Battle
var secret_runner := Callable()     # von main gesetzt: async func(secret)
var dialogue_runner := Callable()   # von main gesetzt: async func(lines)
var party: Party         # Zustand der Heldengruppe (Rucksack, Ausruestung); null = Standardausstattung
var mode := "title"
var _t := 22.0
var _fx_layer: CanvasLayer
var _fx_mat: ShaderMaterial
var _dim: ColorRect


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
	_fx_layer.visible = m != "battle"


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
	if mode == "battle" or battle == null or battle.cam == null:
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
	else:
		# Dialog: naeher dran, langsamer Schwenk ueber das Schlachtfeld
		var u2 := 0.5 - 0.5 * cos(_t * TAU / 170.0)
		var focus2 := Vector3(lerpf(2.0, w - 3.0, u2), 0.0, (h - 1.0) * 0.55 + sin(_t * 0.06) * 0.8)
		cam.fov = 34.0
		cam.position = focus2 + Vector3(sin(_t * 0.08) * 0.5, 6.2, 7.0)
		cam.look_at(focus2 + Vector3(0, 0.3, 0))
