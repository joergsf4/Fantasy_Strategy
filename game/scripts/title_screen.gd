class_name TitleScreen
extends Node
## Startbildschirm: Spielkarte als lebendiger Hintergrund (Tilt-Shift, Kamera schwebt langsam darueber),
## Titel in Fantasy-Schrift und "Press Start".

signal started
signal fading_out

const FONT_TITLE := "res://assets/fonts/CinzelDecorative-Black.ttf"
const FONT_UI := "res://assets/fonts/CinzelDecorative-Bold.ttf"
const GOLD := Color(1.0, 0.83, 0.42)
const OUTLINE := Color(0.16, 0.08, 0.03)

var _t := 0.0
var _ready_for_input := false
var _done := false
var _fade: ColorRect
var _title_box: Control
var _start_label: Label


func _ready() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 2
	add_child(ui)
	_build_ui(ui)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 3
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	_intro()


func _label(text: String, font_path: String, size: int, color: Color, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", load(font_path))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", OUTLINE)
		l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1280, size * 1.4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_ui(ui: CanvasLayer) -> void:
	# weicher dunkler Schleier hinter dem Titel, damit er auf jedem Kartenausschnitt lesbar bleibt
	var grad := Gradient.new()
	grad.set_color(0, Color(0.03, 0.04, 0.08, 0.62))
	grad.set_color(1, Color(0.03, 0.04, 0.08, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var veil := TextureRect.new()
	veil.texture = gt
	veil.position = Vector2(80, 40)
	veil.size = Vector2(1120, 460)
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(veil)

	_title_box = Control.new()
	_title_box.size = Vector2(1280, 720)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_title_box)
	for part: Array in [["Strategy", 104, 120], ["Fantasy", 150, 232]]:
		var y: float = part[2]
		var shadow := _label(part[0], FONT_TITLE, part[1], Color(0, 0, 0, 0.55), 18)
		shadow.position = Vector2(0, y + 8)
		_title_box.add_child(shadow)
		var main := _label(part[0], FONT_TITLE, part[1], GOLD, 14)
		main.position = Vector2(0, y)
		_title_box.add_child(main)
		# heller Verlauf-Eindruck: oberer Teil etwas heller durch zweites, geclipptes Label
		var hi := Control.new()
		hi.position = Vector2(0, y)
		hi.size = Vector2(1280, part[1] * 0.62)
		hi.clip_contents = true
		hi.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hl := _label(part[0], FONT_TITLE, part[1], Color(1.0, 0.95, 0.72))
		hi.add_child(hl)
		_title_box.add_child(hi)
	var orn := Ornament.new()
	orn.position = Vector2(640 - 260, 428)
	orn.size = Vector2(520, 24)
	orn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.add_child(orn)
	var sub := _label("Ein Abenteuer in Runden", FONT_UI, 26, Color(0.93, 0.88, 0.76), 6)
	sub.position = Vector2(0, 458)
	_title_box.add_child(sub)

	_start_label = _label("Press Start", FONT_UI, 44, Color(1, 0.96, 0.85), 10)
	_start_label.position = Vector2(0, 590)
	_start_label.modulate.a = 0.0
	ui.add_child(_start_label)

	var foot := _label("Arbeitstitel  ·  Prototyp", FONT_UI, 16, Color(1, 1, 1, 0.55), 4)
	foot.position = Vector2(-20, 684)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(foot)


func _intro() -> void:
	_title_box.modulate.a = 0.0
	_title_box.position.y = -24.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 1.4)
	tw.parallel().tween_property(_title_box, "modulate:a", 1.0, 1.8).set_delay(0.7)
	tw.parallel().tween_property(_title_box, "position:y", 0.0, 1.8).set_delay(0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_start_label, "modulate:a", 1.0, 0.8)
	tw.tween_callback(func() -> void:
		_ready_for_input = true
		var blink := create_tween().set_loops()
		blink.tween_property(_start_label, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
		blink.tween_property(_start_label, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE))


func _unhandled_input(event: InputEvent) -> void:
	if _done or not _ready_for_input:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventJoypadButton and event.pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	_done = true
	fading_out.emit()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.8)
	tw.tween_callback(func() -> void: started.emit())


## Zierlinie mit Raute in der Mitte.
class Ornament:
	extends Control

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		var gold := Color(1.0, 0.83, 0.42)
		var dark := Color(0.16, 0.08, 0.03)
		for pass_i in 2:
			var col := dark if pass_i == 0 else gold
			var wd := 6.0 if pass_i == 0 else 2.0
			draw_line(Vector2(0, c.y), Vector2(c.x - 26, c.y), col, wd, true)
			draw_line(Vector2(c.x + 26, c.y), Vector2(size.x, c.y), col, wd, true)
		var d := PackedVector2Array([c + Vector2(0, -11), c + Vector2(14, 0), c + Vector2(0, 11), c + Vector2(-14, 0)])
		draw_colored_polygon(d, dark)
		var d2 := PackedVector2Array([c + Vector2(0, -8), c + Vector2(10, 0), c + Vector2(0, 8), c + Vector2(-10, 0)])
		draw_colored_polygon(d2, gold)
		for s in [-1, 1]:
			draw_circle(c + Vector2(s * 40, 0), 3.0, gold)
