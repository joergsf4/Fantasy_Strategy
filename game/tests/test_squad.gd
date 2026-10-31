extends SceneTree
## godot --headless --path game --script tests/test_squad.gd
## Gruppe vor der Mission: Gespraechsfiguren fest, andere tauschbar, Ausruestung Abwesender wird frei, Speichern.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch5")
	var fixed := Mission.dialogue_ids("ch5")
	check(fixed.has("maedchen_baer") and fixed.has("wendy") and fixed.has("ritter") and not fixed.has("$hero"), "Sprecher der Mission sind fest: %s" % [fixed])
	var party := Party.new_game()
	var base: Array = (m["players"] as Array).map(func(e: Dictionary) -> String: return e["id"])
	check(party.squad_for(m) == base, "ohne Auswahl gilt die Vorgabe der Karte")
	# ein freier Platz (spricht nicht) laesst sich tauschen
	var free_i := -1
	for i in base.size():
		if not fixed.has(base[i]):
			free_i = i
	check(free_i >= 0, "es gibt einen freien Platz in Kapitel 5")
	var old: String = base[free_i]
	party.equipment[old] = ["eisenschwert"]
	var roster := Party.roster(defs, 5)
	check(roster.has("ritter") and not roster.has("hund") and Party.roster(defs, 6).has("hund"), "Hundsfreund ist erst ab Kapitel 6 waehlbar")
	var cand: String = ""
	for id: String in roster:
		if not base.has(id):
			cand = id
			break
	check(party.set_squad_member(m, free_i, cand), "freier Platz laesst sich tauschen")
	check(party.squad_for(m)[free_i] == cand, "neue Gruppe enthaelt den Ersatz")
	check(party.pool.has("eisenschwert") and not party.equipment.has(old), "Ausruestung des Zurueckbleibenden wird frei")
	# feste Plaetze und Doppelte werden abgelehnt
	var fixed_i := -1
	for i in base.size():
		if fixed.has(base[i]):
			fixed_i = i
	check(not party.set_squad_member(m, fixed_i, cand), "fester Platz bleibt")
	check(not party.set_squad_member(m, free_i, base[fixed_i]), "wer schon dabei ist, kommt nicht doppelt")
	# Speichern und Laden behaelt die Auswahl
	var back := Party.from_dict(party.to_dict())
	check(back.squad_for(m)[free_i] == cand, "Auswahl bleibt im Spielstand")
	# Kampf bekommt die gewaehlte Gruppe
	var mm := Mission.load_mission("ch5")
	var ids := back.squad_for(mm)
	for i in (mm["players"] as Array).size():
		mm["players"][i]["id"] = ids[i]
	var b := Battle.new()
	b.setup(mm, defs)
	root.add_child(b)
	await process_frame
	check(not b._find(cand).is_empty() and b._find(old).is_empty(), "Kampf startet mit der gewaehlten Gruppe")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
