class_name UiTheme
extends RefCounted
## Gemeinsames Fantasy-Theme: goldgerahmte Panels, Knoepfe, Leisten (Texturen aus tools/make_ui.py).

const UI := "res://assets/ui/"
const F_HEAD := "res://assets/fonts/CinzelDecorative-Bold.ttf"
const F_TITLE := "res://assets/fonts/CinzelDecorative-Black.ttf"
const F_BODY := "res://assets/fonts/IMFeENrm28P.ttf"
const CREAM := Color(0.96, 0.91, 0.78)
const GOLD := Color(1.0, 0.83, 0.42)
const OUTLINE := Color(0.08, 0.05, 0.1)

static var _theme: Theme


static func font(path: String) -> Font:
	return load(path)


## Neun-Teil-Rahmen aus einer UI-Textur. margin = Rand in Pixeln, content = Innenabstand (l, o, r, u).
static func box(file: String, margin: int, content := Vector4(18, 16, 18, 16), alpha := 1.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.modulate_color = Color(1, 1, 1, alpha)
	sb.texture = load(UI + file)
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	return sb


## Namensband (Burgunder mit Schwalbenschwanz-Enden).
static func plate_box(content := Vector4(64, 12, 64, 12)) -> StyleBoxTexture:
	var sb := box("plate.png", 20, content)
	sb.texture_margin_left = 48
	sb.texture_margin_right = 48
	return sb


static func hp_fill(ratio: float) -> StyleBoxTexture:
	var file := "bar_green.png" if ratio > 0.5 else ("bar_yellow.png" if ratio > 0.25 else "bar_red.png")
	return box(file, 8, Vector4(0, 0, 0, 0))


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font(F_BODY)
	t.default_font_size = 22
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("panel", "PanelContainer", box("panel.png", 48, Vector4(34, 34, 34, 34)))
	t.set_stylebox("panel", "Panel", box("panel.png", 48))
	# Knoepfe
	for state in {"normal": "btn_normal.png", "hover": "btn_hover.png", "pressed": "btn_pressed.png", "disabled": "btn_disabled.png"}:
		var b := box({"normal": "btn_normal.png", "hover": "btn_hover.png", "pressed": "btn_pressed.png", "disabled": "btn_disabled.png"}[state], 24, Vector4(16, 8, 16, 8))
		t.set_stylebox(state, "Button", b)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", font(F_HEAD))
	t.set_font_size("font_size", "Button", 20)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color(1, 0.97, 0.8))
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.57, 0.65))
	t.set_color("font_outline_color", "Button", OUTLINE)
	t.set_constant("outline_size", "Button", 4)
	# Leisten
	t.set_stylebox("background", "ProgressBar", box("bar_bg.png", 8, Vector4(0, 0, 0, 0)))
	t.set_stylebox("fill", "ProgressBar", hp_fill(1.0))
	# Text
	t.set_color("default_color", "RichTextLabel", CREAM)
	t.set_font("normal_font", "RichTextLabel", font(F_BODY))
	t.set_font("bold_font", "RichTextLabel", font(F_HEAD))
	t.set_font_size("normal_font_size", "RichTextLabel", 22)
	_theme = t
	return t


## Dezente Variante fuer die Kampfoberflaeche: feinerer Rahmen, leicht durchsichtig.
static func soft(file := "panel_dark_s.png", content := Vector4(12, 8, 12, 8), alpha := 0.82) -> StyleBoxTexture:
	return box(file, 24, content, alpha)


static func soft_plate(content := Vector4(26, 5, 26, 7), alpha := 0.88) -> StyleBoxTexture:
	var sb := box("plate_s.png", 10, content, alpha)
	sb.texture_margin_left = 24
	sb.texture_margin_right = 24
	return sb


static func soft_button(state: String) -> StyleBoxTexture:
	var f := {"normal": "btn_normal_s.png", "hover": "btn_hover_s.png", "pressed": "btn_pressed_s.png", "disabled": "btn_disabled_s.png"}
	return box(f[state], 12, Vector4(10, 4, 10, 4), 0.9 if state != "hover" else 1.0)
