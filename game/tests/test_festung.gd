extends SceneTree
## godot --headless --path game --script tests/test_festung.gd
## Kapitel 9: Ziel "defeat" (Wart), Frischlinge laufen weg, danach tritt der Regent auf (Ziel-Abschlussszene "then").

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch9")
	check(m["goals"][0]["type"] == "defeat" and (m["no_flee"] as Array).has("wart"), "Kapitel 9: Wart muss besiegt werden und flieht nicht")
	var f9 := Mission.dialogue_ids("ch9")
	check(f9.has("maedchen_baer") and not f9.has("hund"), "Mission 9: nur Mira ist fest (der Hinweis auf das blaue Ungetuem wurde wieder gestrichen): %s" % [f9])
	for id: String in f9:
		check(defs.has(id), "Sprecher %s existiert" % id)
	for e in ["fuerst_weinerlich", "frischlinge", "frischlinge_lachend", "frischlinge_wuetend", "wart_sterbend"]:
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % e), "Portrait %s" % e)
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(l["speaker"] + ":" + str(l.get("right_expr", "")))
	root.add_child(b)
	await process_frame
	check(not b.goal_met() and Mission.goal_text(b.goal, 7, 1).begins_with("Ziel: Besiegt Wart"), "Ziel zu Beginn offen")
	check(b._find("frischlinge").size() > 0 and not b._find("frischlinge").has("x"), "Frischlinge sind eine Figur")
	var wart := b._find("wart")
	b.units.erase(wart)
	check(b.goal_met(), "Ziel erreicht, sobald Wart fehlt")
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._check_end()
	check(got == [true], "Mission gewonnen")
	check(b._find("frischlinge").is_empty() and b.retreated.has("frischlinge"), "Frischlinge sind weggelaufen")
	check(b.retreated.has("fuerst"), "Regent ist aufgetreten und abgezogen")
	check(said.has("fuerst:weinerlich"), "weinerliches Portrait in der Szene")
	check(said.has("wart:sterbend") and said.has("frischlinge:wuetend"), "Todesszene und wuetender Racheschwur: %s" % [said])
	print("festung: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
