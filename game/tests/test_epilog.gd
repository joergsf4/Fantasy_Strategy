extends SceneTree
## godot --headless --path game --script tests/test_epilog.gd
## Epilog (Kapitel 26): Zwischenspiel ohne Kampf am Waisenhaus, ohne Standbild, mit flacher Kamerafahrt ueber die Karte.
## Feste Zeilen (Kinder, Hundsfreund, Lotte, Bianca, Morgrim, Mira) plus vier zufaellig gewaehlte Heldenzeilen;
## die Kinder schauen froehlich. Danach Schwarzblende mit "Für Elisabeth" und zurueck zum Hauptmenue.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_src.contains('"ch25", "ch26"]'), "Epilog ist das letzte Kapitel")
	var m := Mission.load_mission("ch26")
	check(m.get("stub", false) and not m.has("interlude"), "Epilog ohne Kampf und ohne Standbild")
	check(m.get("dialog_cam", "") == "waisenhaus" and float(m.get("flight", 0.0)) > 0.0, "flache Kamerafahrt ueber die Karte")
	check(m.get("dedication", "") == "Für Elisabeth" and main_src.contains("func _dedication"), "Widmung am Ende")
	check(not ResourceLoader.exists("res://scripts/credits.gd"), "kein Abspann mehr")
	check((m["enemies"] as Array).is_empty(), "keine Gegner")
	check(Progression.missions_done_before(27) == Progression.missions_done_before(26), "Epilog zaehlt nicht als Kampfmission")
	var grid := Grid.new(m["rows"])
	for p: Dictionary in m["players"]:
		check(defs.has(p["id"]), "Figur bekannt: " + str(p["id"]))
		check(grid.cost(Vector2i(p["pos"][0], p["pos"][1])) >= 0, "Figur steht auf festem Boden: " + str(p["id"]))
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_ch26.json"))
	var lines: Array = story["intro"]
	for l: Dictionary in lines:
		if l.get("left", "") == "waisenkinder":
			check(l.get("left_expr", "") == "lachend", "Kinder froehlich: " + str(l["text"]))
		if l.get("right", "") == "waisenkinder":
			check(l.get("right_expr", "") == "lachend", "Kinder froehlich: " + str(l["text"]))
	for id in ["morgrim", "lotte", "mutter", "hund", "maedchen_baer"]:
		check(lines.any(func(l: Dictionary) -> bool: return l["speaker"] == id and not l.has("group")), "%s spricht immer" % id)
	for i in 5:
		var picked := Mission.pick_groups(lines, int(m["random_pick"]))
		var groups := {}
		for l: Dictionary in picked:
			if l.has("group"):
				groups[l["group"]] = true
		check(groups.size() == 4, "vier zufaellige Heldengruppen (%d)" % groups.size())
		check(picked.filter(func(l: Dictionary) -> bool: return not l.has("group")).size() == lines.filter(func(l: Dictionary) -> bool: return not l.has("group")).size(), "feste Zeilen bleiben")
		var bee := picked.filter(func(l: Dictionary) -> bool: return l.get("group", "") == "stachelia")
		check(bee.is_empty() or bee.size() == 2, "Stachelias Wortwechsel bleibt zusammen")
	for f in ["portraits/morgrim", "portraits/morgrim_lachend", "tokens/morgrim"]:
		check(ResourceLoader.exists("res://assets/%s.png" % f), "Bild " + f)
	print("epilog: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
