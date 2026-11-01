class_name SecretScene
extends Dialogue
## Szene einer geheimen Interaktion: bekanntes Dialogformat (links ein Charakter, rechts der zweite), dazu ein Sonderbild mit
## Tiefenwirkung: zwei Charakterebenen und ein fliegendes Vordergrundobjekt verschieben sich gegeneinander
## (Maus und leichtes Schwanken), vorneweg ein Titelbanner "Geheime Interaktion".

var secret: Dictionary = {}
var quick := false          # kuerzerer Titelauftritt (Trailer)
var _fore: Control
var _intro_done := false
var _t := 0.0
var _base := {}
var _breath := 0.0


func setup_secret(sec: Dictionary, unit_names: Dictionary) -> void:
	secret = sec
	var sc: Dictionary = sec["scene"]
	var by: String = sec["trigger"]["by"]
	var on: String = sec["trigger"].get("target", sec["trigger"].get("via", ""))
	var nm := unit_names.duplicate()
	nm[sc["left"]] = unit_names.get(by, by)
	nm[sc["right"]] = unit_names.get(on, on)
	var out: Array = []
	for l: Dictionary in sc["lines"]:
		out.append({"speaker": sc["left"] if l["speaker"] == by else sc["right"], "left": sc["left"], "right": sc["right"], "text": l["text"]})
	setup(out, nm)
	voices = {sc["left"]: by, sc["right"]: on}      # Brabbel-Laut der Figuren statt der Portraitnamen


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	super._ready()
	_left.position = Vector2(-40, 60)       # breitere Buehne: Brunhildes Pose samt Fass braucht Platz
	_left.size = Vector2(900, 540)
	_right.position = Vector2(700, 40)
	_right.size = Vector2(620, 560)
	_base = {"l": _left.position, "r": _right.position}
	_left.pivot_offset = _left.size * Vector2(0.5, 1.0)
	_right.pivot_offset = _right.size * Vector2(0.5, 1.0)
	_fore = Control.new()
	_fore.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fore)
	_play_intro()


## Die erste Zeile startet erst nach dem Titelbanner (super._ready ruft _advance schon einmal auf).
func _advance() -> void:
	if not _intro_done:
		return
	super._advance()


func _play_intro() -> void:
	Sfx.event("secret")
	_set_portrait(_left, str(secret["scene"]["left"]))
	_set_portrait(_right, str(secret["scene"]["right"]))
	# Charaktere gleiten von aussen herein
	_left.position = _base["l"] + Vector2(-420, 0)
	_right.position = _base["r"] + Vector2(420, 0)
	_left.modulate.a = 0.0
	_right.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "_breath", 1.0, 0.9)
	tw.tween_property(_left, "modulate:a", 1.0, 0.5).set_delay(0.3)
	tw.tween_property(_right, "modulate:a", 1.0, 0.5).set_delay(0.5)
	# Vordergrund: Fass fliegt durchs Bild und zerplatzt am rechten Charakter
	var barrel := TextureRect.new()
	barrel.texture = load("res://assets/fx/fx_barrel.png")
	barrel.size = Vector2(190, 190)
	barrel.pivot_offset = barrel.size * 0.5
	barrel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	barrel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	barrel.position = Vector2(-260, 360)
	barrel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fore.add_child(barrel)
	var fl := create_tween().set_parallel(true)
	fl.tween_property(barrel, "position", Vector2(820, 300), 0.8).set_delay(0.3 if quick else 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fl.tween_property(barrel, "rotation", TAU * 1.5, 0.8).set_delay(0.3 if quick else 0.55)
	fl.chain().tween_callback(func() -> void:
		barrel.queue_free()
		_splash(Vector2(860, 360)))
	# Banner
	var banner := VBoxContainer.new()
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(0, 70)
	banner.size = Vector2(1280, 120)
	banner.alignment = BoxContainer.ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.modulate.a = 0.0
	add_child(banner)
	var l1 := _banner_label("✦  GEHEIME INTERAKTION  ✦", 24, Color(1.0, 0.85, 0.5))
	var l2 := _banner_label(str(secret["name"]), 54, Color(1.0, 0.96, 0.82))
	banner.add_child(l1)
	banner.add_child(l2)
	var bt := create_tween()
	bt.tween_property(banner, "modulate:a", 1.0, 0.3).set_delay(0.55 if quick else 1.1)
	bt.tween_interval(0.8 if quick else 1.3)
	bt.tween_property(banner, "modulate:a", 0.0, 0.5)
	bt.tween_callback(func() -> void:
		banner.queue_free()
		_intro_done = true
		super._advance())


func _banner_label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.04, 0.02))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _splash(at: Vector2) -> void:
	Sfx.event("barrel_splash")
	var foam := TextureRect.new()
	foam.texture = load("res://assets/fx/fx_foam.png")
	foam.size = Vector2(120, 120)
	foam.pivot_offset = foam.size * 0.5
	foam.position = at - foam.size * 0.5
	foam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foam.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fore.add_child(foam)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(foam, "scale", Vector2(5.5, 5.5), 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(foam, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tw.chain().tween_callback(foam.queue_free)
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.85, 0.5, 0.55)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fore.add_child(flash)
	var ft := create_tween()
	ft.tween_property(flash, "color:a", 0.0, 0.5)
	ft.tween_callback(flash.queue_free)


## Tiefenwirkung: je naeher eine Ebene, desto staerker verschiebt sie sich gegen die Maus; dazu ruhiges Schwanken.
func _process(delta: float) -> void:
	_t += delta
	var vp := get_viewport_rect().size
	var m := (get_viewport().get_mouse_position() / vp - Vector2(0.5, 0.5)) if vp.x > 0 else Vector2.ZERO
	var sway := Vector2(sin(_t * 0.9), cos(_t * 1.3) * 0.6)
	if _breath >= 1.0 or _intro_done:
		_left.position = _base["l"] - m * 38.0 + sway * 7.0
		_right.position = _base["r"] - m * 52.0 - Vector2(sway.x, -sway.y) * 9.0
		_left.scale = Vector2.ONE * (1.0 + 0.008 * sin(_t * 1.7))
		_right.scale = Vector2.ONE * (1.0 + 0.008 * sin(_t * 1.5 + 1.0))
	else:
		var k := _breath
		_left.position = _base["l"] + Vector2(-420, 0) * (1.0 - k)
		_right.position = _base["r"] + Vector2(420, 0) * (1.0 - k)
	_fore.position = -m * 90.0
