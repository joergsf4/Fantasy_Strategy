extends SceneTree
## godot --headless --path game --script tests/test_stachelia.gd
## Kapitel 11: Stachelia steht allein mit Drohnen und Bienenkoerben, haelt Runden aus; faellt sie, flieht sie (erzaehlte Niederlage),
## die Mission gilt als geschafft; Bonus "8 Runden ausgehalten" nur bei Durchhalten.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _make(defs: Dictionary) -> Battle:
	var b := Battle.new()
	b.setup(Mission.load_mission("ch11"), defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b)
	return b


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch11")
	check(m["goals"][0]["type"] == "survive" and m.get("story_loss", "") == "bienenmaedchen", "Kapitel 11: Durchhalten, erzaehlte Niederlage")
	for id: String in Mission.dialogue_ids("ch11"):
		check(defs.has(id), "Sprecher %s existiert" % id)
	check(Mission.dialogue_ids("ch11").has("bienenkrieger"), "Trupp ist fest (Stachelia und Drohnen)")
	for id in ["lotte", "lotte_lachend", "lotte_wuetend"]:
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % id), "Portrait %s" % id)
	var b := _make(defs)
	await process_frame
	check(b._count_team("p") == 3 and b._count_team("e") == 0, "Stachelia und zwei Drohnen, keine Gegner zu Beginn")
	var hives := b.world.objects.filter(func(o: Dictionary) -> bool: return o["type"] == "hive_p")
	check(hives.size() == 4 and hives.all(func(o: Dictionary) -> bool: return o["perm"]), "vier dauerhafte Bienenkoerbe")
	# Bienenkoerbe lassen Drohnen schluepfen und loesen sich nicht auf
	for i in 8:
		await b._player_hive_phase()
	check(hives.all(func(o: Dictionary) -> bool: return o["state"] == "active"), "Koerbe bleiben stehen")
	check(b.units.filter(func(u: Dictionary) -> bool: return u["id"] == "bienenkrieger" and u["team"] == "p").size() == 4, "hoechstens vier Drohnen (drone_cap)")
	# Stachelia faellt in Runde 3: sie flieht, Mission gilt als geschafft, kein Bonus
	b.turn = 3
	var st := b._find("bienenmaedchen")
	st["hp"] = 0
	b.units.erase(st)
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._down(st)
	check(b.story_lost and b.fallen.is_empty(), "Stachelia ist geflohen, nicht gefallen")
	await b._check_end()
	check(got == [true], "Mission gilt als geschafft")
	check(said.has("oskar"), "Abschlussszene mit den Zwillingen lief: %s" % [said])
	var r := b.results()
	check(r["objectives"][0]["done"] == false, "ohne 8 Runden kein Bonus")
	# Durchgehalten: Ziel erreicht, Szene, Bonus
	var b2 := _make(defs)
	await process_frame
	said.clear()
	b2.turn = 9
	check(b2.goal_met(), "Runde 9: Ziel erreicht")
	var got2 := []
	b2.finished.connect(func(w: bool) -> void: got2.append(w))
	await b2._check_end()
	check(got2 == [true] and said.has("oskar"), "Szene nach dem Durchhalten")
	check(b2.results()["objectives"][0]["done"] == true, "Bonus: 8 Runden ausgehalten")
	check(b2.world.objects.filter(func(o: Dictionary) -> bool: return o["type"] == "hive_p" and o["state"] == "active").is_empty(), "Koerbe brennen nieder")
	print("stachelia: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
