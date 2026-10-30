extends SceneTree
## godot --headless --path game --script tests/test_sfx.gd
## Soundsystem: alle in sfx.json genannten Klaenge existieren, Schichten je Waffe/Ziel, Zuordnung der Figuren.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _names(spec: Variant, out: Array) -> void:
	if spec is Array:
		for e: Variant in spec:
			_names(e, out)
	elif spec is Dictionary:
		_names((spec as Dictionary)["s"], out)
	elif spec is String and spec != "@melee":
		out.append(spec)


func _initialize() -> void:
	var s := Sfx.get_inst()
	await process_frame
	Sfx.muted = true
	var cfg: Dictionary = s.cfg
	# jeder genannte Klang hat eine Datei
	var names: Array = []
	for key in ["weapon", "body", "combo", "swing", "ranged", "abilities", "events"]:
		for k: String in cfg[key]:
			var v: Variant = cfg[key][k]
			if v is Dictionary and key in ["ranged", "abilities"]:
				for ph: String in v:
					_names(v[ph], names)
			else:
				_names(v, names)
	_names(cfg["accent"], names)
	for n: String in names:
		check(ResourceLoader.exists("%s%s_1.wav" % [Sfx.DIR, n]), "Klang %s existiert" % n)
	# Schichten
	s.played.clear()
	Sfx.melee({"weapon": "wood"}, {"body": "armor"})
	check(s.played == ["w_wood", "t_armor"], "Holz auf Metall: %s" % [s.played])
	s.played.clear()
	Sfx.melee({"weapon": "metal"}, {"body": "armor"})
	check(s.played == ["w_metal", "t_armor"], "Metall auf Metall: %s" % [s.played])
	s.played.clear()
	Sfx.melee({"weapon": "fist"}, {"body": "flesh"})
	check(s.played == ["w_fist", "t_face"], "Faust auf Gesicht: %s" % [s.played])
	s.played.clear()
	Sfx.melee({"weapon": "metal"}, {"body": "flesh"}, true)
	check(s.played == ["w_metal", "t_flesh", "crit"], "Akzent bei Positionsbonus: %s" % [s.played])
	# Figuren haben Marken, die zu Klaengen passen
	var units: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	for id: String in units:
		if id.begins_with("_"):
			continue
		check(cfg["weapon"].has(units[id].get("weapon", "fist")) and cfg["body"].has(units[id].get("body", "flesh")), "%s: Waffen-/Koerpermarke bekannt" % id)
	# Faehigkeiten: jede hat Klaenge
	var abs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	for id: String in abs:
		if not id.begins_with("_"):
			check((cfg["abilities"] as Dictionary).has(id), "Faehigkeit %s hat Klaenge" % id)
	# Fernkampf
	s.played.clear()
	Sfx.shot({"id": "soldat_bogenschuetze"})
	Sfx.shot_hit({"id": "soldat_bogenschuetze"}, {"body": "flesh"})
	check(s.played == ["bow_shot", "arrow_hit", "t_flesh"], "Bogenschuetze: %s" % [s.played])
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
