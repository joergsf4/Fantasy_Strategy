class_name RendererChoice
extends Control
## Auswahl der Grafikschnittstelle beim Spielstart (nur macOS): Metal (Mobile-Renderer) oder OpenGL (Compatibility-Renderer).
## Godot legt den Renderer beim Programmstart fest. Die Wahl steht darum in user://grafik_start.cfg, die Godot ueber
## application/config/project_settings_override (project.godot) vor dem Start liest. Wer etwas anderes waehlt als das
## laufende, startet das Spiel einmal neu. Farbabgleich zwischen beiden: siehe Farbraum.

signal done(restarting: bool)

const OVERRIDE := "user://grafik_start.cfg"
const METAL := "mobile"
const OPENGL := "gl_compatibility"


## Dialog zeigen? Nur auf dem Mac im normalen Spiel (nicht headless, nicht in Screenshot-Laeufen).
static func wanted() -> bool:
	return OS.get_name() == "macOS" and DisplayServer.get_name() != "headless" and OS.get_environment("SHOT") == ""


static func current() -> String:
	return RenderingServer.get_current_rendering_method()


## Wahl fuer den naechsten Start merken.
static func remember(method: String) -> void:
	var cf := ConfigFile.new()
	cf.set_value("rendering", "renderer/rendering_method", method)
	cf.save(OVERRIDE)


## Mit dem anderen Renderer neu starten: gleiche Startargumente, nur ohne ein --rendering-method von der Kommandozeile.
static func restart() -> void:
	var args: PackedStringArray = []
	var skip := false
	for a in OS.get_cmdline_args():
		if skip:
			skip = false
			continue
		if a == "--rendering-method":
			skip = true
			continue
		args.append(a)
	OS.set_restart_on_exit(true, args)
	(Engine.get_main_loop() as SceneTree).quit()


var _buttons: Dictionary = {}


func _ready() -> void:
	theme = UiTheme.get_theme()
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(44, 30, 44, 30), 0.96))
	panel.custom_minimum_size = Vector2(540, 0)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	panel.add_child(col)
	col.add_child(_label("Grafikschnittstelle", UiTheme.F_TITLE, 34, UiTheme.GOLD))
	col.add_child(_label("Womit soll das Spiel zeichnen?", UiTheme.F_BODY, 20, UiTheme.CREAM))
	var cur := current()
	var is_metal := cur != OPENGL
	_buttons[METAL] = _button("Metal" + ("  (aktiv)" if is_metal else ""), "schneller, der Rechner bleibt kühler", METAL)
	_buttons[OPENGL] = _button("OpenGL" + ("" if is_metal else "  (aktiv)"), "bewährt, wie in den bisherigen Versionen", OPENGL)
	col.add_child(_buttons[METAL])
	col.add_child(_buttons[OPENGL])
	col.add_child(_label("Ein Wechsel startet das Spiel einmal neu.", UiTheme.F_BODY, 16, Color(UiTheme.CREAM, 0.7)))
	panel.reset_size()
	panel.position = (Vector2(1280, 720) - panel.size) / 2.0
	(_buttons[METAL if is_metal else OPENGL] as Button).grab_focus.call_deferred()


func _label(text: String, font: String, fsize: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _button(title: String, sub: String, method: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(440, 78)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button("hover" if st == "focus" else st))
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	for l: Label in [_label(title, UiTheme.F_HEAD, 22, UiTheme.CREAM), _label(sub, UiTheme.F_BODY, 17, Color(UiTheme.CREAM, 0.85))]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(l)
	b.pressed.connect(_pick.bind(method))
	return b


func _pick(method: String) -> void:
	for b: Button in _buttons.values():
		b.disabled = true
	remember(method)
	var switch := (method == OPENGL) != (current() == OPENGL)
	done.emit(switch)
	if switch:
		restart()
