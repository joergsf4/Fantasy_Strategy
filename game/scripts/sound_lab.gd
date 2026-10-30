class_name SoundLab
extends Control
## Soundlabor (Testmenue): alle Klaenge einzeln anhoeren, Nahkampf als Waffe x Ziel, Faehigkeiten mit ihren Phasen.

signal closed

const WEAPONS := {"wood": "Holz (Stab)", "metal": "Metall (Schwert)", "fist": "Faust"}
const BODIES := {"armor": "Rüstung", "wood": "Holz/Schild", "flesh": "Fleisch/Gesicht", "stone": "Stein"}
const PHASES := ["windup", "cast", "shot", "hit", "heal"]


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 30)
	scroll.size = Vector2(1160, 660)
	add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size = Vector2(1130, 0)
	scroll.add_child(col)
	col.add_child(_label("Soundlabor", 34, UiTheme.GOLD))
	col.add_child(_button("Zurück", func() -> void:
		closed.emit()
		queue_free()))

	col.add_child(_label("Nahkampf: Waffe (Zeile) trifft Ziel (Spalte), mit Schwung davor", 20, UiTheme.CREAM))
	for w: String in WEAPONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var l := _label(WEAPONS[w], 18, Color(0.85, 0.85, 0.8))
		l.custom_minimum_size = Vector2(190, 0)
		row.add_child(l)
		for b: String in BODIES:
			row.add_child(_button(BODIES[b], func() -> void: _melee(w, b, false)))
		row.add_child(_button("+ Akzent (Rücken/Flanke)", func() -> void: _melee(w, "flesh", true)))
		col.add_child(row)

	col.add_child(_label("Fernkampf (normaler Angriff)", 20, UiTheme.CREAM))
	var rr := HFlowContainer.new()
	rr.add_theme_constant_override("h_separation", 8)
	for id: String in (Sfx._cfg().get("ranged", {}) as Dictionary):
		if id != "default":
			rr.add_child(_button(id, func() -> void: _ranged(id)))
	rr.add_child(_button("Standard (Zauberkugel)", func() -> void: _ranged("default")))
	col.add_child(rr)

	col.add_child(_label("Fähigkeiten (Aufbau, Abschuss, Treffer nacheinander)", 20, UiTheme.CREAM))
	var ar := HFlowContainer.new()
	ar.add_theme_constant_override("h_separation", 8)
	ar.add_theme_constant_override("v_separation", 6)
	for id: String in (Sfx._cfg().get("abilities", {}) as Dictionary):
		ar.add_child(_button(id, func() -> void: _ability(id)))
	col.add_child(ar)

	col.add_child(_label("Ereignisse", 20, UiTheme.CREAM))
	var er := HFlowContainer.new()
	er.add_theme_constant_override("h_separation", 8)
	er.add_theme_constant_override("v_separation", 6)
	for id: String in (Sfx._cfg().get("events", {}) as Dictionary):
		er.add_child(_button(id, func() -> void: Sfx.event(id)))
	col.add_child(er)

	col.add_child(_label("Alle Rohklänge", 20, UiTheme.CREAM))
	var raw := HFlowContainer.new()
	raw.add_theme_constant_override("h_separation", 6)
	raw.add_theme_constant_override("v_separation", 6)
	for n in _raw_names():
		raw.add_child(_button(n, func() -> void: Sfx.play(n)))
	col.add_child(raw)


## Rohklaenge: alle Dateinamen ohne Nummer. Im Export liegen nur ".wav.import"-Dateien, daher beides beachten.
func _raw_names() -> Array[String]:
	var seen := {}
	for f in DirAccess.get_files_at(Sfx.DIR):
		var base := f.trim_suffix(".import")
		if base.ends_with(".wav"):
			var nm := base.trim_suffix(".wav")
			nm = nm.substr(0, nm.rfind("_"))
			seen[nm] = true
	var out: Array[String] = []
	for k: String in seen:
		out.append(k)
	out.sort()
	return out


func _melee(w: String, b: String, accent: bool) -> void:
	Sfx.swing({"weapon": w})
	await get_tree().create_timer(0.15).timeout
	Sfx.melee({"weapon": w}, {"body": b}, accent)


func _ranged(id: String) -> void:
	Sfx.shot({"id": id})
	await get_tree().create_timer(0.4).timeout
	Sfx.shot_hit({"id": id}, {})


func _ability(id: String) -> void:
	for ph: String in PHASES:
		if (Sfx._cfg()["abilities"][id] as Dictionary).has(ph):
			Sfx.ability(id, ph, {"weapon": "fist"}, {"body": "flesh"})
			await get_tree().create_timer(0.55).timeout


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font(UiTheme.F_HEAD))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 32)
	b.add_theme_font_size_override("font_size", 15)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(cb)
	return b
