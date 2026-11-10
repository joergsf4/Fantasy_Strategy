extends SceneTree
## godot --headless --path game --script tests/test_spielspass.gd
## Gefahrenzone der Gegner, neue Bonusziele (kind), Chronik (Medaillen im Spielstand), Lager-Seiten und Album der Geheimnisse.

var fails := 0
var defs: Dictionary


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func make_battle(objectives: Array, chests: Array = []) -> Battle:
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	map["players"] = []
	map["enemies"] = []
	map["chests"] = chests
	map["villages"] = []
	map["rewards"] = {}
	map["objectives"] = objectives
	var b := Battle.new()
	b.setup(map, defs)
	b.loadout = {"inventory": {"heiltrank": 1}, "equipment": {}}
	root.add_child(b)
	return b


func done(b: Battle, id: String) -> bool:
	for o: Dictionary in b.results()["objectives"]:
		if o["id"] == id:
			return o["done"]
	return false


func _initialize() -> void:
	Engine.time_scale = 12.0
	defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	await test_threat()
	await test_objectives()
	test_records()
	await test_camp()
	test_data()
	Engine.time_scale = 1.0
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func test_threat() -> void:
	var b := make_battle([])
	await process_frame
	b._spawn("ritter", "p", Vector2i(1, 8))
	b._spawn("soldat_infanterie", "e", Vector2i(8, 8))
	var foe: Dictionary = b.units.back()
	var t := b._threat_of(foe)
	var near := Vector2i(6, 8)                  # ein Schritt nach links, dann Reichweite 1
	var far := Vector2i(8, 8 - Combat.move_of(foe) - 1)      # gerade nach Norden (nur Gras): volle Bewegung plus Reichweite 1
	check(t["hit"].has(near) and t["hit"].has(far) and not t["hit"].has(far + Vector2i.UP), "Gefahrenzone: Bewegung plus Reichweite, nicht weiter")
	check(not t["hit"].has(Vector2i(1, 8)), "Gefahrenzone: der ferne Held ist nicht bedroht")
	check((t["wake"] as Dictionary).is_empty(), "Keine Wache: keine Weckzone")
	foe["guard"] = true
	var g := b._threat_of(foe)
	check(g["wake"].has(Vector2i(8, 5)) and not g["wake"].has(Vector2i(8, 4)), "Wache: Weckzone ist der Alarmradius 3")
	check(g["hit"].has(near) and not g["hit"].has(far), "Wache: bedroht nur Felder in der Weckzone")
	foe["guard"] = false
	Status.add(foe, "stun", 1)
	check((b._threat_of(foe)["hit"] as Dictionary).is_empty(), "Benommener Gegner bedroht nichts")
	Status.remove(foe, "stun")
	b._toggle_threat(foe)
	check(b._threat_pick.has(foe["uid"]) and b._threat_root.get_child_count() > 0, "Klick auf Gegner: Zone wird gezeichnet")
	check(b._threat_names(near) == foe["name"], "Feldauskunft nennt den Gegner")
	b._toggle_threat(foe)
	await process_frame
	check(not b._threat_pick.has(foe["uid"]), "Zweiter Klick blendet aus")
	b._toggle_threat_all()
	check(b._threat_all, "Taste G: alle Zonen an")
	b._toggle_threat_all()
	# Zeitraffer: nur in der Gegnerphase, danach wieder normal
	Engine.time_scale = 1.0
	b._enemy_phase = true
	b.state = Battle.State.BUSY
	Settings.set_value("enemy_speed", 1)
	b._apply_speed()
	check(is_equal_approx(Engine.time_scale, 2.0), "Option Schnell: Gegnerphase mit doppeltem Tempo")
	b._talk = 1
	b._apply_speed()
	check(is_equal_approx(Engine.time_scale, 1.0), "Waehrend einer Szene kein Zeitraffer")
	b._talk = 0
	b._enemy_phase = false
	b._apply_speed()
	check(is_equal_approx(Engine.time_scale, 1.0), "Nach der Gegnerphase wieder normales Tempo")
	Settings.set_value("enemy_speed", 0)
	b.state = Battle.State.IDLE
	Engine.time_scale = 12.0
	b.queue_free()
	await process_frame


func test_objectives() -> void:
	var objs := [
		{"id": "t", "kind": "taktik", "count": 1, "text": "", "reward": {"gold": 10}},
		{"id": "r", "kind": "ruecken", "count": 1, "text": "", "reward": {}},
		{"id": "ru", "kind": "ruecken", "unit": "soldat_bogenschuetze", "text": "", "reward": {}},
		{"id": "z", "kind": "zuerst", "unit": "soldat_infanterie", "text": "", "reward": {}},
		{"id": "f", "kind": "faehigkeit", "count": 1, "text": "", "reward": {}},
		{"id": "o", "kind": "ohne_traenke", "text": "", "reward": {}},
		{"id": "c", "kind": "truhen", "text": "", "reward": {}},
		{"id": "alle_leben", "text": "", "reward": {}}]
	var b := make_battle(objs, [{"pos": [4, 7], "reward": {"gold": 5}}])
	await process_frame
	b._spawn("ritter", "p", Vector2i(3, 7))
	var hero: Dictionary = b.units.back()
	b._spawn("soldat_infanterie", "e", Vector2i(4, 6))
	var foe: Dictionary = b.units.back()
	hero["pos"] = Vector2i(4, 5)                # Held steht noerdlich, der Gegner blickt nach Sueden: Treffer in den Ruecken
	b._face_step(foe, Vector2i.DOWN)
	foe["hp"] = 1
	await b._strike(hero, foe)
	check(not b.units.has(foe) and int(b.feats["back_kills"]) == 1, "Rueckentreffer besiegt den Gegner: gezaehlt")
	b._spawn("soldat_bogenschuetze", "e", Vector2i(6, 6))
	var archer: Dictionary = b.units.back()
	archer["hp"] = 1
	hero["pos"] = Vector2i(6, 7)
	b._face_step(archer, Vector2i.DOWN)         # von vorn
	await b._strike(hero, archer)
	check(int(b.feats["back_kills"]) == 1, "Treffer von vorn zaehlt nicht als Rueckentreffer")
	check(b.feats["order"] == ["soldat_infanterie", "soldat_bogenschuetze"], "Reihenfolge der besiegten Gegner")
	check(done(b, "t") and done(b, "r") and done(b, "z") and done(b, "o") and done(b, "alle_leben"), "Taktik, Ruecken, Zuerst, ohne Traenke, kein Held faellt: erfuellt")
	check(not done(b, "ru") and not done(b, "f") and not done(b, "c"), "Bogenschuetze von vorn, keine Faehigkeit, Truhe zu: nicht erfuellt")
	check(int(b.results()["gold"]) == 10, "Belohnung nur fuer erfuellte Ziele")
	b.queue_free()
	await process_frame
	var b2 := make_battle([{"id": "o", "kind": "ohne_traenke", "text": "", "reward": {}}, {"id": "f", "kind": "faehigkeit", "count": 1, "text": "", "reward": {}},
		{"id": "c", "kind": "truhen", "text": "", "reward": {}}], [{"pos": [4, 7], "reward": {"gold": 5}}])
	await process_frame
	b2._spawn("ritter", "p", Vector2i(4, 7))
	var h2: Dictionary = b2.units.back()
	await b2._collect(h2, b2._chest_at(Vector2i(4, 7)), "chest")
	h2["hp"] -= 3
	await b2._use_item(h2, "heiltrank", h2)
	b2._spawn("soldat_infanterie", "e", Vector2i(5, 7))
	var f2: Dictionary = b2.units.back()
	f2["hp"] = 1
	b2._actor = h2
	b2._cur_ability = "schlachtruf"             # als liefe gerade eine Faehigkeit des Helden
	await b2._deal(f2, 5, "")
	b2._cur_ability = ""
	check(not done(b2, "o") and done(b2, "f") and done(b2, "c"), "Trank benutzt, Gegner per Faehigkeit besiegt, Truhe offen")
	b2.queue_free()
	await process_frame


func test_records() -> void:
	var p := Party.new_game()
	var objs := [{"id": "a", "done": true}, {"id": "b", "done": false}]
	p.record("ch3", {"objectives": objs, "turns": 9}, 1)
	p.record("ch3", {"objectives": [{"id": "a", "done": false}, {"id": "b", "done": true}], "turns": 12}, 2)
	var r: Dictionary = p.records["ch3"]
	check(r["won"] and r["goals"] == ["a", "b"] and int(r["turns"]) == 9 and r["hard"], "Chronik: Bonusziele sammeln sich, beste Rundenzahl, Schwer bleibt")
	p.record("ch4", {"objectives": [], "turns": 5, "skipped": true}, 1)
	check(not p.records.has("ch4"), "Uebersprungene Mission bekommt keinen Eintrag")
	p.completed = true
	var l := Party.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check(l.completed and l.records["ch3"]["goals"] == ["a", "b"] and int(l.records["ch3"]["turns"]) == 9, "Chronik uebersteht Speichern und Laden")
	var m := {"objectives": [{"id": "a"}, {"id": "b"}, {"id": "x"}]}
	check(Chronicle.medals(m, l.records["ch3"]) == [4, 5], "Medaillen: Sieg, zwei Ziele, Schwer von fuenf")
	check(Chronicle.medals(m, {}) == [0, 5], "Ohne Sieg keine Medaille")


func test_camp() -> void:
	var p := Party.new_game()
	p.gold = 300
	p.earned = 3
	p.pool = ["eisenschwert", "rubinring"]
	p.secrets_seen = ["betrunkener_meister"]
	var m := Mission.load_mission("ch5")
	var camp := Camp.new()
	camp.setup(p, defs, p.squad_for(m), m)
	root.add_child(camp)
	await process_frame
	check(camp._page == "uebersicht", "Lager beginnt mit der Uebersicht")
	check((camp._badges["talente"] as Label).text == "6", "Seitenleiste zeigt freie Talentpunkte")
	check((camp._badges["geheimnisse"] as Label).text.begins_with("1/"), "Seitenleiste zeigt entdeckte Geheimnisse")
	for page: String in Camp.PAGES:
		camp.show_page(page)
		await process_frame
		check(camp._body.get_child_count() > 0, "Lager-Seite %s hat Inhalt" % page)
	camp.show_page("geheimnisse")
	await process_frame
	var cards := camp.find_children("*", "GridContainer", true, false)
	check(not cards.is_empty() and (cards[0] as GridContainer).get_child_count() == camp._secret_list().size(), "Album: eine Karte je Geheimnis")
	camp.queue_free()
	await process_frame


func test_data() -> void:
	var hints: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/secret_hints.json"))
	for sec: Dictionary in (JSON.parse_string(FileAccess.get_file_as_string("res://data/secrets.json")) as Dictionary)["secrets"]:
		if sec.has("trigger"):
			check(hints.has(sec["id"]) and hints[sec["id"]].has("hint") and hints[sec["id"]].has("text"), "Album-Texte fuer Geheimnis %s" % sec["id"])
	var kinds := ["alle_leben", "schnell", "haeuser", "praxis", "keine_stiche", "alle_gegner", "ueberzeugt", "friedlich", "maschine_zerstoert", "durchgehalten",
		"taktik", "ruecken", "zuerst", "faehigkeit", "ohne_traenke", "truhen"]
	for i in range(1, 27):
		var m := Mission.load_mission("ch%d" % i)
		var ids := {}
		for o: Dictionary in m.get("objectives", []):
			check(kinds.has(str(o.get("kind", o["id"]))), "ch%d: Bonusziel %s hat eine bekannte Art" % [i, o["id"]])
			check(not ids.has(o["id"]), "ch%d: Bonusziel-id %s ist eindeutig" % [i, o["id"]])
			ids[o["id"]] = true
			if str(o.get("kind", "")) == "truhen":
				check(not (m.get("chests", []) as Array).is_empty(), "ch%d: Ziel Truhen braucht Truhen" % i)
			if o.has("unit") and str(o.get("kind", "")) in ["ruecken", "zuerst"]:
				check((m["enemies"] as Array).any(func(e: Dictionary) -> bool: return e["id"] == o["unit"]), "ch%d: Zielgegner %s steht auf der Karte" % [i, o["unit"]])
		var grid := Grid.new(m["rows"])
		for c: Dictionary in m.get("chests", []):
			var p := Vector2i(c["pos"][0], c["pos"][1])
			check(grid.inside(p) and grid.cost(p) > 0, "ch%d: Truhe %s liegt auf begehbarem Feld" % [i, p])
