class_name SuperCutin
extends Control
## Super-Attacken-Auftritt: Polarlicht-Himmel, davor der stark vergroesserte Chibi der Figur (gleitet herein, schwankt, Nachbilder),
## Kinobalken, Funkenflug und der Name der Attacke, die ins Bild schlaegt. Dauer ca. 2,6 s; danach beginnt die eigentliche Attacke.

signal finished

var texture: Texture2D
var title := ""
var subtitle := ""
var _chibi: TextureRect
var _glow: TextureRect
var _bg: ColorRect
var _t := 0.0


func setup(tex: Texture2D, attack_name: String, sub: String) -> void:
	texture = tex
	title = attack_name
	subtitle = sub


func _ready() -> void:
	theme = UiTheme.get_theme()
	position = Vector2.ZERO
	size = Vector2(1280, 720)                      # feste Spielgroesse (Kind eines CanvasLayer hat sonst keine Groesse)
	mouse_filter = Control.MOUSE_FILTER_STOP      # waehrend des Auftritts keine Klicks auf die Karte
	_bg = ColorRect.new()
	_bg.size = Vector2(1280, 720)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/aurora.gdshader")
	_bg.material = m
	_bg.modulate.a = 0.0
	add_child(_bg)

	# weiches Leuchten hinter der Figur
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.9))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 256
	_glow = TextureRect.new()
	_glow.texture = gt
	_glow.size = Vector2(900, 900)
	_glow.position = Vector2(-40, -80)
	_glow.modulate = Color(0.5, 1.0, 0.8, 0.0)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add_mat
	add_child(_glow)

	# Funken
	var sparks := CPUParticles2D.new()
	sparks.position = Vector2(640, 760)
	sparks.amount = 70
	sparks.lifetime = 2.2
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(700, 10)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 12.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 140.0
	sparks.initial_velocity_max = 340.0
	sparks.scale_amount_min = 0.025
	sparks.scale_amount_max = 0.08
	sparks.color = Color(0.7, 1.0, 0.9, 0.8)
	sparks.texture = load("res://assets/fx/fx_star.png")
	sparks.material = add_mat
	add_child(sparks)

	# Figur: stark vergroessert, Fuss unten in der Bildmitte links
	_chibi = TextureRect.new()
	_chibi.texture = texture
	_chibi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chibi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chibi.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_chibi.size = Vector2(620, 620)
	_chibi.pivot_offset = Vector2(310, 620)
	_chibi.position = Vector2(-900, 80)
	_chibi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chibi)

	# Kinobalken
	var bars: Array[ColorRect] = []
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.size = Vector2(1280, 86)
		bar.position = Vector2(0, -86 if top else 720)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		bars.append(bar)

	# Titel
	var box := VBoxContainer.new()
	box.position = Vector2(520, 230)
	box.size = Vector2(740, 260)
	box.pivot_offset = Vector2(370, 80)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate.a = 0.0
	add_child(box)
	var l1 := _label(title.to_upper(), _fit_size(title.to_upper(), 64, 700.0), Color(1.0, 0.97, 0.8))
	var l2 := _label(subtitle, _fit_size(subtitle, 30, 700.0), Color(0.7, 1.0, 0.9))
	box.add_child(l1)
	box.add_child(l2)

	# Ablauf
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bg, "modulate:a", 1.0, 0.3)
	tw.tween_property(bars[0], "position:y", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bars[1], "position:y", 634.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_glow, "modulate:a", 0.75, 0.6).set_delay(0.3)
	tw.tween_property(_chibi, "position:x", 70.0, 0.55).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_ghosts).set_delay(0.35)
	tw.tween_property(box, "modulate:a", 1.0, 0.12).set_delay(0.85)
	box.scale = Vector2(2.4, 2.4)
	tw.tween_property(box, "scale", Vector2.ONE, 0.22).set_delay(0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: _shake(14.0)).set_delay(1.05)
	var end := create_tween()
	end.tween_interval(2.35)
	end.tween_callback(_flash)
	end.tween_interval(0.12)
	end.tween_property(self, "modulate:a", 0.0, 0.25)
	end.tween_callback(func() -> void:
		finished.emit()
		queue_free())


## Groesste Schriftgroesse (hoechstens max_size), bei der der Text in max_width Pixel passt (lange Titel schrumpfen statt aus dem Bild zu laufen).
func _fit_size(text: String, max_size: int, max_width: float) -> int:
	var font := UiTheme.font(UiTheme.F_TITLE)
	var size: int = max_size
	while size > 20 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 24.0 > max_width:
		size -= 2
	return size


func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(UiTheme.F_TITLE))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.12))
	l.add_theme_constant_override("outline_size", 16)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Nachbilder, wenn die Figur hereinschiesst.
func _ghosts() -> void:
	for i in 4:
		var g := TextureRect.new()
		g.texture = texture
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.size = _chibi.size
		g.position = Vector2(-120.0 - i * 90.0, _chibi.position.y)
		g.modulate = Color(0.5, 1.0, 0.9, 0.5 - i * 0.1)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(g)
		move_child(g, _chibi.get_index())
		var tw := create_tween().set_parallel(true)
		tw.tween_property(g, "position:x", 70.0 - 40.0 * (i + 1), 0.4)
		tw.tween_property(g, "modulate:a", 0.0, 0.4)
		tw.chain().tween_callback(g.queue_free)


func _shake(amount: float) -> void:
	var tw := create_tween()
	for i in 6:
		tw.tween_property(self, "position", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)) * (1.0 - i / 6.0), 0.035)
	tw.tween_property(self, "position", Vector2.ZERO, 0.04)


func _flash() -> void:
	var f := ColorRect.new()
	f.color = Color(1, 1, 1, 0.9)
	f.size = Vector2(1280, 720)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	create_tween().tween_property(f, "color:a", 0.0, 0.2)


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_chibi) and _t > 0.8:
		_chibi.rotation = sin(_t * 3.2) * 0.045          # leichtes Taumeln
		_chibi.scale = Vector2.ONE * (1.0 + 0.025 * sin(_t * 5.0))
		_glow.scale = Vector2.ONE * (1.0 + 0.06 * sin(_t * 4.0))
	(_bg.material as ShaderMaterial).set_shader_parameter("energy", 0.5 + 0.5 * sin(_t * 4.0))
