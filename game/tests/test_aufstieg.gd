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
	# Talentpunkte
	var q := Party.new_game()
	check(q.points("ritter") == 0, "Am Anfang keine Punkte")
	q.absorb({"inventory": {}, "materials": {}, "gold": 0, "equipment": []})
	q.absorb({"inventory": {}, "materials": {}, "gold": 0, "equipment": []})
	check(q.points("ritter") == 2 and q.points("wendy") == 2 and q.points("hund") == 2, "Jeder Held bekommt je Mission einen Punkt, egal ob dabei")
	check(q.spend_point("ritter", "hp") and q.spend_point("ritter", "a1") and not q.spend_point("ritter", "atk"), "zwei Punkte ausgeben, dritter fehlt")
	check(q.points("ritter") == 0 and q.points("hund") == 2, "Punkte gehoerem dem einzelnen Helden")
	check(q.refund_point("ritter", "hp") and q.points("ritter") == 1 and not q.refund_point("ritter", "atk"), "Punkt zurueckholen, leeres Feld geht nicht")
	for i in 5:
		q.earned += 1
		q.spend_point("hund", "atk")
	check(q.ranks("hund")["atk"] == 3, "hoechstens Rang 3")
	check(Party.from_dict(q.to_dict()).ranks("hund")["atk"] == 3 and Party.from_dict(q.to_dict()).earned == q.earned, "Talente werden gespeichert")
	check((q.loadout()["talents"] as Dictionary).has("ritter"), "Kampf bekommt die Talente")
	# Bonus und Faehigkeits-Raenge
	var tl := {"hp": 2, "atk": 3, "a1": 0, "a2": 0}
	check(Talents.hp_bonus(tl) == 8 and Talents.atk_bonus(tl) == 3 and Talents.spent(tl) == 5, "Leben +4, Angriff +1 je Rang")
	var ab := {"name": "Test", "cd": 3, "range": [2, 4], "effects": [{"type": "damage", "mult": 1.6}]}
	var r1 := Talents.ranked(ab, 1)
	var r2 := Talents.ranked(ab, 2)
	var r3 := Talents.ranked(ab, 3)
	check(r1["cd"] == 2 and r1["effects"][0]["mult"] == 1.6, "Rang 1: Abklingzeit -1")
	check(r2["cd"] == 2 and is_equal_approx(r2["effects"][0]["mult"], 2.0), "Rang 2: Wirkung +25 %")
	check(r3["range"] == [2, 5], "Rang 3: Reichweite +1")
	check(ab["cd"] == 3 and ab["effects"][0]["mult"] == 1.6, "Original bleibt unveraendert")
	var heal := {"name": "Heil", "cd": 2, "target": "ally", "range": [1, 2], "effects": [{"type": "heal", "amount": 8}]}
	check(Talents.ranked(heal, 2)["effects"][0]["amount"] == 10, "Heilung steigt")
	check(Talents.next_rank_text(ab, 0).begins_with("Abklingzeit 3"), "Text fuer den naechsten Rang: %s" % Talents.next_rank_text(ab, 0))
	check(Talents.next_rank_text(ab, 3) == "Höchster Rang", "Rang 3 ist das Maximum")
	var table := {"kanone": {"id": "kanone", "cd": 3, "range": [2, 3], "effects": [{"type": "damage", "mult": 1.4}]}, "x": {"id": "x", "cd": 3, "effects": []}}
	Talents.apply_to_abilities(table, {"a1": 1, "a2": 0}, {"abilities": ["kanone", "x"]}, [])
	check(table["kanone"]["cd"] == 2 and table["x"]["cd"] == 3, "Rang wirkt nur auf das gewaehlte Feld")
	Talents.apply_to_abilities(table, {"a1": 2}, {"abilities": ["kanone"]}, ["kanone"])
	check(table["kanone"]["cd"] == 2, "ausgeschlossene Faehigkeit (auch von Gegnern genutzt) bleibt")
	check(Talents.default_allocation(5) == {"hp": 2, "atk": 1, "a1": 1, "a2": 1}, "Standardverteilung: %s" % [Talents.default_allocation(5)])
	check(Talents.default_allocation(99) == {"hp": 3, "atk": 3, "a1": 3, "a2": 3}, "Standardverteilung hoechstens Rang 3")
	# Gegnerstaerke je Mission
	check(Progression.enemy_scale("ch1") == {"hp": 1.0, "atk": 1.0} and Progression.enemy_scale("ch13")["hp"] > Progression.enemy_scale("ch5")["hp"] and Progression.enemy_scale("unbekannt")["hp"] == 1.0, "Gegnerfaktoren je Mission")
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var b := Battle.new()
	var m13 := Mission.load_mission("ch13")
	b.setup(m13, defs)
	b.loadout = {"talents": {"hund": {"hp": 2, "atk": 1, "a1": 1, "a2": 0}}}
	root.add_child(b)
	await process_frame
	var cw := b._find("kugelblitz")
	var sc13 := Progression.enemy_scale("ch13")
	check(cw["maxhp"] == roundi(55.0 * float(sc13["hp"])) and cw["atk"] == roundi(9.0 * float(sc13["atk"])), "Mission 13: Gegner skaliert (%d Leben, %d Angriff)" % [cw["maxhp"], cw["atk"]])
	# Kampf: Held mit Talenten
	var b2 := Battle.new()
	var m1 := Mission.load_mission("ch12")
	b2.setup(m1, defs)
	b2.loadout = {"talents": {"hund": {"hp": 2, "atk": 1, "a1": 1, "a2": 0}}}
	root.add_child(b2)
	await process_frame
	var hu := b2._find("hund")
	check(not hu.is_empty(), "Hund ist in Mission 12 dabei")
	if not hu.is_empty():
		check(hu["maxhp"] == int(defs["hund"]["hp"]) + 8 and hu["atk"] == int(defs["hund"]["atk"]) + 1, "Kampf: Leben +8, Angriff +1 (%d, %d)" % [hu["maxhp"], hu["atk"]])
		check(b2.abilities["knochenwurf"]["cd"] < JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))["knochenwurf"]["cd"], "Kampf: Faehigkeit 1 hat Rang 1 (Abklingzeit kuerzer)")
	print("aufstieg: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
