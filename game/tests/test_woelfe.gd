extends SceneTree
## godot --headless --path game --script tests/test_woelfe.gd
## Mission 17 (Schnee, Woelfe): Angst bei allen Woelfen schickt das Rudel weg und der Alphawolf schliesst sich an; faellt vorher ein Wolf, bleibt der Kampf normal.
## Geheimnis Klebekanone: Kanone neben Stachelias Bienenkorb klebt Gegner im Umkreis 2 Runden fest.

var fails := 0
var said: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _make(defs: Dictionary, mission: Dictionary) -> Battle:
	var b := Battle.new()
	b.setup(mission, defs)
	b.dialogue_runner = func(lines: Array) -> void:
		for l: Dictionary in lines:
			said.append(str(l["speaker"]))
	root.add_child(b)
	return b


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch17")
	check(m.get("biome", "") == "schnee" and m.get("mood", "") == "nacht_schnee", "Schnee-Biom, Nacht mit Schneefall")
	for id: String in Mission.dialogue_ids("ch17"):
		check(defs.has(id), "Sprecher %s existiert" % id)
	for id in ["alphawolf", "alphawolf_lachend", "alphawolf_wuetend"]:
		check(ResourceLoader.exists("res://assets/portraits/%s.png" % id), "Portrait %s" % id)
	for id in ["fx_schneefichte1", "fx_schneefichte2", "fx_eisfels", "fx_schneehaufen", "fx_kleber"]:
		check(ResourceLoader.exists("res://assets/fx/%s.png" % id), "Sprite %s" % id)
	check(ResourceLoader.exists("res://assets/tokens/wolf.png") and ResourceLoader.exists("res://assets/tokens/alphawolf.png"), "Karten-Figuren Wolf und Alphawolf")
	# Alphawolf: nur waehlbar, wenn gewonnen
	check(not Party.roster(defs, 18, true).has("alphawolf") and Party.roster(defs, 18, true, ["alphawolf"]).has("alphawolf"), "Alphawolf nur waehlbar, wenn er sich angeschlossen hat")
	check((defs["alphawolf"]["abilities"] as Array).size() == 2, "Alphawolf hat zwei Faehigkeiten")
	# --- Friedlicher Weg: alle Woelfe erschrecken
	var b := _make(defs, m)
	await process_frame
	check(Grid.TERRAIN["G"]["cost"] == 1 and b.terrain.biome == "schnee", "Gelaende kennt das Biom")
	var wolves := b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e")
	check(wolves.size() == 6 and not b._find("alphawolf").is_empty(), "fuenf Woelfe und der Alphawolf")
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	for i in wolves.size() - 1:
		Status.add(wolves[i], "angst", 2)
		wolves[i]["fright"] = true
	await b._flush_events()
	check(not b._find("alphawolf").is_empty() and b.recruited.is_empty(), "Noch nicht alle erschreckt: Kampf geht weiter")
	wolves[wolves.size() - 1]["fright"] = true
	await b._flush_events()
	check(b.recruited == ["alphawolf"] and b.peace_win, "Alle erschreckt: Alphawolf schliesst sich an, friedlicher Sieg")
	check(b._find("wolf").is_empty() and b._find("alphawolf").is_empty(), "das Rudel ist weg")
	await b._check_end()
	check(got == [true], "Mission gewonnen: %s" % [got])
	var res := b.results()
	check((res["recruited"] as Array).has("alphawolf") and res["objectives"][1]["done"] == true, "Ergebnis: rekrutiert, Bonus friedlich")
	var q := Party.new_game()
	q.absorb(res)
	check(q.recruited.has("alphawolf") and Party.roster(defs, 18, true, q.recruited).has("alphawolf") and Party.from_dict(q.to_dict()).recruited.has("alphawolf"), "Rekrutierung wird verbucht und gespeichert")
	# --- Normaler Weg: ein Wolf faellt, danach geht es nicht mehr friedlich
	said.clear()
	var b2 := _make(defs, m)
	await process_frame
	var w2 := b2.units.filter(func(u: Dictionary) -> bool: return u["id"] == "wolf")
	b2.kills_total = 1
	w2[0]["hp"] = 0
	b2.units.erase(w2[0])
	for u in b2.units:
		if u["team"] == "e":
			u["fright"] = true
	await b2._flush_events()
	check(b2.recruited.is_empty() and not b2.peace_win and not b2._find("alphawolf").is_empty(), "Nach einem Todesfall zieht das Rudel nicht mehr friedlich ab")
	# --- Klebekanone
	var sec := Secrets.find_object("elisabeth", "kanone")
	check(not sec.is_empty() and sec["trigger"]["owner"] == "bienenmaedchen", "Geheimnis Klebekanone ist aktiv")
	var m1 := Mission.load_mission("ch1")
	m1["enemies"] = []
	var b3 := _make(defs, m1)
	await process_frame
	for u in b3.units.duplicate():
		b3.units.erase(u)
		(u["node"] as Node3D).queue_free()
	b3.secrets_seen.append("klebekanone")      # Szene und Auftritt ueberspringen
	b3._spawn("elisabeth", "p", Vector2i(3, 7))
	var eli: Dictionary = b3.units.back()
	b3._spawn("bienenmaedchen", "p", Vector2i(2, 7))
	var bee: Dictionary = b3.units.back()
	var hive := b3.world.add_object("hive_p", Vector2i(3, 8), {"owner": bee["uid"]})
	b3._make_object(hive)
	b3._spawn("soldat_infanterie", "e", Vector2i(6, 7))
	var s1: Dictionary = b3.units.back()
	b3._spawn("soldat_infanterie", "e", Vector2i(7, 7))
	var s2: Dictionary = b3.units.back()
	b3._spawn("soldat_infanterie", "e", Vector2i(10, 7))
	var s3: Dictionary = b3.units.back()
	for x in [s1, s2, s3]:
		x["hp"] = 200
		x["maxhp"] = 200
	await b3._run_ability(eli, "kanone", s1)
	check(Status.has(s1, "klebrig") and Status.has(s2, "klebrig") and not Status.has(s3, "klebrig"), "Klebekanone: Gegner im Umkreis 2 des Einschlags festgeklebt, der weit entfernte nicht")
	check(Combat.move_of(s1) == 0 and b3.grid.reachable(s1["pos"], Combat.move_of(s1), false).size() == 1, "Festgeklebte koennen sich nicht bewegen")
	# ohne Bienenkorb daneben: kein Kleber
	var eli2: Dictionary = b3._find("elisabeth")
	eli2["pos"] = Vector2i(5, 3)
	eli2["cd"] = {}
	b3._spawn("soldat_infanterie", "e", Vector2i(8, 3))
	var s4: Dictionary = b3.units.back()
	s4["hp"] = 200
	await b3._run_ability(eli2, "kanone", s4)
	check(not Status.has(s4, "klebrig"), "Ohne Bienenkorb neben Elisabeth: normale Kanone")
	print("woelfe: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
