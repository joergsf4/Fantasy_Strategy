extends SceneTree
## godot --headless --path game --script tests/test_aufstieg.gd
## Fortschritt: Ausruestung in Stufen im Sortiment je Kapitel, Verkauf zum halben Preis, Gegnerstaerke je Mission, Erfahrung und Stufen der Helden.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _ids(p: Party) -> Array:
	return p.stock().map(func(w: Dictionary) -> String: return w["id"])


func _initialize() -> void:
	var p := Party.new_game()
	p.chapter = 1
	var early := _ids(p)
	check(early.has("eisenschwert") and not early.has("meisterklinge") and not early.has("runenschwert"), "Kapitel 1: nur Stufe 1")
	p.chapter = 7
	var mid := _ids(p)
	check(mid.has("meisterklinge") and mid.has("schuppenpanzer") and not mid.has("eisenschwert"), "Kapitel 7: Stufe 3, Eisenschwert ausgelaufen")
	p.chapter = 12
	var late := _ids(p)
	check(late.has("runenschwert") and late.has("mithrilhemd") and late.has("drachenzahn") and not late.has("stahlklinge"), "Kapitel 12: Stufe 4")
	var tiers := {}
	for id: String in Items.equipment():
		var t: int = Items.equipment()[id]["tier"]
		tiers[t] = int(tiers.get(t, 0)) + 1
	check(tiers.size() == 4, "vier Stufen vorhanden: %s" % [tiers])
	# Hoehere Stufen sind teurer und besser
	var e: Dictionary = Items.equipment()
	check(int(e["runenschwert"]["price"]) > int(e["meisterklinge"]["price"]) and int(e["meisterklinge"]["price"]) > int(e["stahlklinge"]["price"]) and int(e["stahlklinge"]["price"]) > int(e["eisenschwert"]["price"]), "Waffenpreise steigen mit der Stufe")
	check(int(e["runenschwert"]["mods"]["atk"]) > int(e["meisterklinge"]["mods"]["atk"]) and int(e["meisterklinge"]["mods"]["atk"]) > int(e["eisenschwert"]["mods"]["atk"]), "Waffen werden staerker")
	# Verkauf
	p.pool.append("eisenschwert")
	p.gold = 0
	check(p.sell("eisenschwert") and p.gold == 35 and not p.pool.has("eisenschwert"), "Verkauf: halber Preis (35)")
	check(not p.sell("eisenschwert"), "nichts mehr zu verkaufen")
	# Geld darf knapp sein: nicht alles auf einmal kaufbar
	p.chapter = 8
	var all := 0
	for w: Dictionary in p.stock():
		all += int(w["price"]) * int(w["n"])
	check(all > 1000, "Sortiment kostet deutlich mehr als eine Mission einbringt (%d Gold)" % all)
	# Stufen: Erfahrung, Boni, Speichern
	check(Progression.level_for_xp(0) == 1 and Progression.level_for_xp(19) == 1 and Progression.level_for_xp(20) == 2 and Progression.level_for_xp(140) == 5, "Stufen nach Erfahrung")
	check(Progression.xp_for_next(0) == 20 and Progression.xp_for_next(140) == -1, "naechste Stufe / hoechste Stufe")
	var tank := {"dmg_type": "body"}
	check(Progression.bonus(5, tank) == {"hp": 9, "atk": 2, "def": 1, "res": 0, "heal": 0}, "Stufe 5: +9 Leben, +2 Angriff, +1 Verteidigung")
	var heal := {"dmg_type": "magic", "heal": 6}
	check(Progression.bonus(5, heal) == {"hp": 9, "atk": 2, "def": 0, "res": 1, "heal": 2}, "Heiler: Magieresistenz und Heilung")
	var u := {"hp": 20, "maxhp": 20, "atk": 8, "def": 3, "res": 1, "heal": 0}
	Progression.apply_level(u, 3, tank)
	check(u["maxhp"] == 23 and u["atk"] == 9 and u["def"] == 3, "Stufe 3 angewendet")
	var q := Party.new_game()
	q.chapter = 3
	var res := {"stats": {"rows": [{"id": "ritter"}, {"id": "hund"}]}}
	var gain := q.xp_gain(res, ["ritter", "wendy"])
	check(int(gain["ritter"]["gain"]) == 12 and int(gain["wendy"]["gain"]) == 6 and gain["hund"]["gain"] == 12, "Gruppe voll, Wartende halb")
	q.xp["ritter"] = 19
	var up := q.xp_gain(res, [])
	check(int(up["ritter"]["old"]) == 1 and int(up["ritter"]["new"]) == 2, "Stufenaufstieg wird gemeldet")
	q.absorb({"inventory": {}, "materials": {}, "gold": 0, "equipment": [], "xp": up})
	check(q.level_of("ritter") == 2 and q.level_of("hund") == 1, "Erfahrung verbucht")
	var back := Party.from_dict(q.to_dict())
	check(back.level_of("ritter") == 2, "Erfahrung wird gespeichert")
	check(q.loadout()["levels"]["ritter"] == 2, "Kampf bekommt die Stufen")
	# Gegnerstaerke je Mission
	check(Progression.enemy_scale("ch1") == {"hp": 1.0, "atk": 1.0} and Progression.enemy_scale("ch13")["hp"] > Progression.enemy_scale("ch5")["hp"] and Progression.enemy_scale("unbekannt")["hp"] == 1.0, "Gegnerfaktoren je Mission")
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var b := Battle.new()
	var m13 := Mission.load_mission("ch13")
	b.setup(m13, defs)
	b.loadout = {"levels": {"hund": 3}}
	root.add_child(b)
	await process_frame
	var cw := b._find("kugelblitz")
	var sc13 := Progression.enemy_scale("ch13")
	check(cw["maxhp"] == roundi(55.0 * float(sc13["hp"])) and cw["atk"] == roundi(9.0 * float(sc13["atk"])), "Mission 13: Gegner skaliert (%d Leben, %d Angriff)" % [cw["maxhp"], cw["atk"]])
	print("aufstieg: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
