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
	var f6 := Mission.dialogue_ids("ch6")
	check(f6.has("hund") and f6.has("elisabeth") and not f6.has("ritter") and not f6.has("robo"), "nur Story-Gespraeche legen fest, Fluff nicht: %s" % [f6])
	var f3 := Mission.dialogue_ids("ch3")
	check(f3.has("maedchen_baer") and f3.has("quacksalber") and not f3.has("wendy") and not f3.has("braumeisterin") and not f3.has("ritter"), "Kapitel 3: nur Mira und Dr. Humbug fest: %s" % [f3])
	var vl := Mission.voiced([{"left": "maedchen_baer", "right": "", "speaker": "maedchen_baer", "text": "Mira", "voices": [{"id": "wendy", "text": "Wendy", "expr": "lachend"}, {"id": "ritter", "text": "Ritter"}]}], ["maedchen_baer", "ritter", "wendy"])
	check(vl[0]["speaker"] == "wendy" and vl[0]["left"] == "wendy" and vl[0]["text"] == "Wendy" and vl[0]["left_expr"] == "lachend" and not vl[0].has("voices"), "erste anwesende Stimme spricht: %s" % [vl])
	vl = Mission.voiced([{"left": "maedchen_baer", "right": "", "speaker": "maedchen_baer", "text": "Mira", "voices": [{"id": "wendy", "text": "Wendy"}]}], ["maedchen_baer", "robo"])
	check(vl[0]["speaker"] == "maedchen_baer" and vl[0]["text"] == "Mira", "ohne passende Stimme spricht die Rueckfallstimme")
	var roster := Party.roster(defs, 5)
	check(roster.has("ritter") and not roster.has("hund") and Party.roster(defs, 6).has("hund"), "Hundsfreund ist erst ab Kapitel 6 waehlbar")
	# nur kennengelernte Helden
	var r1 := Party.roster(defs, 1)
	check(r1.size() == 6 and r1.has("maedchen_baer") and r1.has("ritter") and r1.has("kungfu") and r1.has("elisabeth") and r1.has("wendy") and r1.has("braumeisterin"), "Kapitel 1: nur die sechs Startfiguren: %s" % [r1])
	check(not Party.roster(defs, 2).has("samurai") and Party.roster(defs, 3).has("samurai") and Party.roster(defs, 4).has("ninjas") and not Party.roster(defs, 3).has("ninjas"), "Takeda ab Kapitel 3, Kage-Schwestern ab Kapitel 4")
	check(Party.roster(defs, 2).has("robo") and not Party.roster(defs, 2, false).has("robo") and Party.roster(defs, 3, false).has("robo"), "im Lager vor Kapitel 2 ist Robo noch unbekannt, nach der Einleitung bekannt")
	check(not Party.roster(defs, 9).has("claude"), "Claude ist in der Geschichte noch nie aufgetreten: nicht waehlbar")
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
