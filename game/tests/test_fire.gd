extends SceneTree
## godot --headless --path game --script tests/test_fire.gd
## Feuer: Ausbreitung nur auf brennbare Felder und Haeuser, 3 Phasen brennen, Asche/Ruine, Loeschen, Vorschau.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	# Wald auf (3,2) (3,3), Haeuser auf (1,2) (1,3), Wiese sonst. Feuer startet auf (2,2).
	var flam := {Vector2i(3, 2): true, Vector2i(3, 3): true}
	var w := World.new([
		{"id": "f0", "type": "fire", "pos": [2, 2]},
		{"id": "h1", "type": "house", "pos": [1, 2]},
		{"id": "h2", "type": "house", "pos": [1, 3]},
		{"id": "h3", "type": "house", "pos": [9, 9]}])
	check(w.at(Vector2i(2, 2))["state"] == "burning" and w.at(Vector2i(1, 2))["state"] == "intact", "Start: Feuer brennt, Haeuser intakt")
	check(w.blocked().has(Vector2i(1, 2)) and not w.blocked().has(Vector2i(2, 2)), "Haeuser sperren, Feuerfeld nicht")
	check(w.burning_tiles().has(Vector2i(2, 2)), "Feuerfeld ist brennend (Schaden)")
	# Vorschau: Nachbarn von (2,2): Haus (1,2), Wald (3,2); (2,1) und (2,3) sind Wiese
	var pv := w.ignition_preview(flam)
	check(pv.has(Vector2i(1, 2)) and pv.has(Vector2i(3, 2)) and not pv.has(Vector2i(2, 1)) and not pv.has(Vector2i(2, 3)), "Vorschau: Haus und Wald fangen Feuer, Wiese nicht")
	check(not pv.has(Vector2i(1, 3)), "Haus (1,3) ist kein direkter Nachbar von (2,2)")
	# Phase 1
	var ch := w.tick_fire(flam)
	check(w.at(Vector2i(1, 2))["state"] == "burning" and w.at(Vector2i(3, 2))["type"] == "fire" and w.at(Vector2i(3, 2))["state"] == "burning", "Phase 1: Haus und Wald brennen")
	check(w.at(Vector2i(2, 1)).is_empty() and w.at(Vector2i(2, 3)).is_empty(), "Wiese brennt nie")
	check(w.at(Vector2i(2, 2))["age"] == 1 and ch.size() == 2, "Altes Feuer ist 1 Phase alt, zwei neue Brandherde")
	check(w.at(Vector2i(9, 9))["state"] == "intact", "Fernes Haus unberuehrt")
	# Phase 2: Feuer springt weiter auf (1,3) (Haus) und (3,3) (Wald)
	w.tick_fire(flam)
	check(w.at(Vector2i(1, 3))["state"] == "burning" and w.at(Vector2i(3, 3))["state"] == "burning", "Phase 2: weitere Haeuser/Wald")
	# Phase 3: das erste Feuer (age 3) erlischt, das Haus (1,2) ist noch nicht dran
	w.tick_fire(flam)
	check(w.at(Vector2i(2, 2))["state"] == "out", "Phase 3: erstes Feuer ist erloschen (Asche)")
	check(w.at(Vector2i(1, 2))["state"] == "burning" and w.at(Vector2i(1, 2))["age"] == 2, "Haus (1,2) brennt seit 2 Phasen")
	# Erloschenes Feld faengt nicht wieder Feuer
	var again := w.ignition_preview(flam)
	check(not again.has(Vector2i(2, 2)) and not again.has(Vector2i(3, 2)), "Asche brennt nicht noch einmal")
	# Phase 4: Haus (1,2) wird nach 3 Phasen zur Ruine
	w.tick_fire(flam)
	check(w.at(Vector2i(1, 2))["state"] == "ruin" and w.houses_lost() >= 1, "Phase 4: Haus (1,2) ist eine Ruine")
	check(not w.blocked().has(Vector2i(1, 2)), "Ruine sperrt nicht mehr")
	# Loeschen
	var w2 := World.new([{"id": "f", "type": "fire", "pos": [2, 2]}, {"id": "h", "type": "house", "pos": [1, 2]}])
	w2.tick_fire(flam)    # Haus brennt, Wald (3,2) brennt
	var house := w2.by_id("h")
	check(w2.solution(house, ["extinguish"]).get("effect") == "extinguish", "Brennendes Haus: Marke 'extinguish' loest es")
	check(w2.solution(w2.at(Vector2i(2, 2)), ["smash"]).is_empty(), "Feuer: nur extinguish hilft")
	w2.apply(house, "extinguish")
	check(house["state"] == "intact" and house["age"] == 0, "Haus gerettet (wieder intakt)")
	check(w2.solution(house, ["extinguish"]).is_empty(), "Intaktes Haus braucht keine Loesung")
	w2.apply(w2.at(Vector2i(3, 2)), "extinguish")
	check(w2.at(Vector2i(3, 2))["state"] == "out", "Feuerfeld geloescht")
	check(w2.ignition_preview(flam).has(Vector2i(1, 2)), "Brennt das Nachbarfeuer noch, bedroht es das gerettete Haus wieder")
	# Alles geloescht: keine Ausbreitung
	var w3 := World.new([{"id": "f", "type": "fire", "pos": [2, 2]}, {"id": "h", "type": "house", "pos": [1, 2]}])
	w3.apply(w3.by_id("f"), "extinguish")
	check(w3.ignition_preview(flam).is_empty() and w3.tick_fire(flam).is_empty(), "Ohne Feuer keine Ausbreitung")
	await battle_tests()


func battle_tests() -> void:
	Engine.time_scale = 12.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var m := Mission.load_mission("ch3")
	check(m["title"] == "Mühlbach in Flammen" and (m["objects"] as Array).size() == 6, "Mission 3 geladen: 4 Haeuser, 2 Feuer")
	var b := Battle.new()
	var m2 := m.duplicate(true)
	m2["players"] = []
	m2["enemies"] = []
	b.setup(m2, defs)
	root.add_child(b)
	await process_frame
	# Grundzustand: nur zwei Feuerfelder, Haeuser intakt, Waldfelder brennbar
	check(b.world.burning_tiles().size() == 2 and b.world.by_id("h2")["state"] == "intact", "Start: zwei Feuer, Haeuser intakt")
	check(b._flammable.has(Vector2i(5, 1)) and not b._flammable.has(Vector2i(4, 2)), "Wald brennbar, Wiese nicht")
	# eigene Einheiten, ein weit entfernter Gegner (damit nie "gewonnen")
	b._spawn("braumeisterin", "p", Vector2i(3, 7))
	var bru: Dictionary = b.units.back()
	b._spawn("maedchen_baer", "p", Vector2i(3, 5))
	var mira: Dictionary = b.units.back()
	b._spawn("wendy", "p", Vector2i(0, 9))
	b._spawn("soldat_infanterie", "e", Vector2i(11, 0))
	# eine Feuerphase: zwei Haeuser und Wald fangen Feuer, Haeuser sperren, Karte bleibt begehbar
	await b._fire_phase()
	check(b.world.by_id("h2")["state"] == "burning" and b.world.by_id("h4")["state"] == "burning", "Phase 1: Haeuser (3,2) und (3,4) brennen")
	check(b._obj_nodes.has("fire_5_2"), "Neues Feuerfeld im Wald hat eine Darstellung")
	# Brandschaden: wer auf einem Feuerfeld steht, bekommt 4 zu Beginn seiner Phase, Flieger nicht
	var tile := Vector2i(4, 4)
	check(b.world.burning_tiles().has(tile), "Feld (4,4) brennt noch")
	mira["pos"] = tile
	var hp0: int = mira["hp"]
	await b._begin_phase("p")
	check(mira["hp"] == hp0 - Battle.FIRE_DAMAGE, "Auf dem Feuerfeld: -4 Leben (%d -> %d)" % [hp0, mira["hp"]])
	mira["pos"] = Vector2i(3, 5)
	var hp1: int = mira["hp"]
	await b._begin_phase("p")
	check(mira["hp"] == hp1, "Neben dem Feuer: kein Schaden")
	# Fasswurf auf das brennende Haus (3,4): Haus gerettet, Feuer (4,4) im Umkreis geloescht
	check(b._obj_targets(bru, "fasswurf", bru["pos"]).has(b.world.by_id("h4")), "Fasswurf: brennendes Haus in Reichweite ist Ziel")
	check(not b._obj_targets(bru, "fasswurf", bru["pos"]).has(b.world.by_id("h1")), "Fasswurf: intaktes Haus ist kein Ziel")
	await b._use_on_object(bru, "fasswurf", b.world.by_id("h4"))
	check(b.world.by_id("h4")["state"] == "intact" and b.world.by_id("f2")["state"] == "out", "Haus gerettet, Feuerfeld (4,4) im Umkreis auch geloescht")
	check(b.world.by_id("h2")["state"] == "burning", "Haus (3,2) ausserhalb des Umkreises brennt weiter")
	check(bru["cd"]["fasswurf"] == 3, "Abklingzeit gesetzt")
	# Jede Figur kann loeschen (Sicherheitsnetz): Mira neben dem brennenden Feuer (4,2)? -> (3,3) liegt neben (3,2) und (4,3)
	mira["pos"] = Vector2i(3, 3)
	check(b._douse_targets(mira).has(b.world.by_id("h2")), "Feuer loeschen: brennendes Nachbarhaus ist Ziel")
	check(b._douse_targets(bru).is_empty(), "Feuer loeschen: nichts in Reichweite -> kein Ziel")
	await b._douse(mira, b.world.by_id("h2"))
	check(b.world.by_id("h2")["state"] == "intact", "Mira loescht das Haus von Hand")
	# Ohne Loeschen werden Haeuser zu Ruinen, das Bonusziel faellt
	b.state = Battle.State.IDLE
	for i in 6:
		await b._fire_phase()
	check(b.world.houses_lost() >= 1, "Nach mehreren Feuerphasen sind Haeuser Ruinen")
	var res := b.results()
	var ok := false
	for o: Dictionary in res["objectives"]:
		if o["id"] == "haeuser":
			ok = not o["done"]
	check(ok, "Bonusziel 'Kein Haus brennt ab' ist verpasst")
	# Gegner stellen sich nicht ins Feuer: Mira steht so, dass sie nur von dem Feuerfeld (4,4) aus erreichbar waere
	b.world = World.new(m["objects"])
	b.grid.blocked = b.world.blocked()
	for u in b.units.duplicate():
		units_clear(b, u)
	b._spawn("maedchen_baer", "p", Vector2i(4, 3))
	b._spawn("wendy", "p", Vector2i(5, 3))
	b._spawn("soldat_infanterie", "e", Vector2i(6, 4))
	var foe: Dictionary = b.units.back()
	check(b.world.burning_tiles().has(Vector2i(4, 4)), "Vorbedingung: (4,4) brennt")
	await b._enemy_move(foe)
	check(foe["pos"] != Vector2i(4, 4) and not b.world.burning_tiles().has(foe["pos"]), "Gegner steht nicht im Feuer (steht bei %s)" % foe["pos"])
	# Bier loescht ein brennendes Nachbarfeld
	b.world = World.new(m["objects"])
	b.grid.blocked = b.world.blocked()
	for u in b.units.duplicate():
		units_clear(b, u)
	b._spawn("braumeisterin", "p", Vector2i(4, 3))
	var drinker: Dictionary = b.units.back()
	b._spawn("wendy", "p", Vector2i(0, 9))
	b._spawn("soldat_infanterie", "e", Vector2i(11, 0))
	b.inventory = {"bier": 2, "heiltrank": 1}
	check(not b._douse_targets(drinker).is_empty() and Items.consumables()["bier"].get("douse", false), "Bier: Feuer in Reichweite, Gegenstand kann loeschen")
	check(not Items.consumables()["heiltrank"].get("douse", false), "Heiltrank loescht nicht")
	var fire_o: Dictionary = b._douse_targets(drinker)[0]
	await b._use_item_on_object(drinker, "bier", fire_o)
	check(b.inventory["bier"] == 1 and (fire_o["state"] == "out" or fire_o["state"] == "intact"), "Bier: Feuer aus, ein Bier weniger (Rest %d)" % b.inventory["bier"])
	await parity(defs, m)
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


## Spiel und Simulation muessen Feuer, Brandschaden und Loeschen gleich berechnen.
func parity(defs: Dictionary, m: Dictionary) -> void:
	var m2 := m.duplicate(true)
	m2["players"] = []
	m2["enemies"] = []
	var g := Battle.new()
	g.setup(m2, defs)
	root.add_child(g)
	await process_frame
	var s := SimBattle.new(m["rows"], 4)
	s.setup_world(m["objects"])
	g._spawn("maedchen_baer", "p", Vector2i(4, 4))
	g._spawn("braumeisterin", "p", Vector2i(3, 7))
	g._spawn("soldat_infanterie", "e", Vector2i(11, 0))
	var gm: Dictionary = g.units[0]
	var gb: Dictionary = g.units[1]
	var sm := s.spawn("maedchen_baer", "p", Vector2i(4, 4))
	var sb := s.spawn("braumeisterin", "p", Vector2i(3, 7))
	s.spawn("soldat_infanterie", "e", Vector2i(11, 0))
	for phase in 3:
		await g._fire_phase()
		s.fire_phase()
		check(_same_world(g.world, s.world), "Parity Feuerphase %d: gleiche Objektzustaende" % (phase + 1))
	await g._begin_phase("p")
	s.begin_phase("p")
	check(gm["hp"] == sm["hp"], "Parity Brandschaden: Spiel %d, Sim %d" % [gm["hp"], sm["hp"]])
	await g._use_on_object(gb, "fasswurf", g.world.by_id("h4"))
	s.extinguish_ability(sb, "fasswurf", s.world.by_id("h4"))
	check(_same_world(g.world, s.world), "Parity Fasswurf: gleiche Objektzustaende")
	check(gb["cd"]["fasswurf"] == sb["cd"]["fasswurf"], "Parity Abklingzeit Fasswurf")
	await g._douse(gm, g.world.by_id("h2"))
	s.douse(sm, s.world.by_id("h2"))
	check(_same_world(g.world, s.world), "Parity Loeschen von Hand")
	check(g.world.houses_lost() == s.world.houses_lost(), "Parity verlorene Haeuser")


func _same_world(a: World, b: World) -> bool:
	if a.objects.size() != b.objects.size():
		return false
	for o in a.objects:
		var p := b.by_id(o["id"])
		if p.is_empty() or p["state"] != o["state"] or p["age"] != o["age"]:
			return false
	return true


func units_clear(b: Battle, u: Dictionary) -> void:
	b.units.erase(u)
	(u["node"] as Node3D).queue_free()
