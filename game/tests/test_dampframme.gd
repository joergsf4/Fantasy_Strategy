extends SceneTree
## godot --headless --path game --script tests/test_dampframme.gd
## Robinas Dampframme: vier Felder geradeaus, Feinde im Weg bekommen Schaden und werden zur Seite gestossen. Stachelia ist ab Mission 15 Heldin.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	check((defs["panzer"]["abilities"] as Array) == ["breitseite", "dampframme"], "Robina: Breitseite und Dampframme")
	check(defs["bienenmaedchen"].get("hero", false) and int(defs["bienenmaedchen"]["from"]) == 15 and (defs["bienenmaedchen"]["abilities"] as Array).size() == 2, "Stachelia: Heldin ab Mission 15 mit zwei Faehigkeiten")
	check(Party.roster(defs, 15, true).has("bienenmaedchen") and not Party.roster(defs, 14, true).has("bienenmaedchen"), "Stachelia wird erst in Mission 15 waehlbar")
	var m := Mission.load_mission("ch1")
	m["enemies"] = []
	var b := Battle.new()
	b.setup(m, defs)
	root.add_child(b)
	await process_frame
	for u in b.units.duplicate():
		b.units.erase(u)
		(u["node"] as Node3D).queue_free()
	b._spawn("panzer", "p", Vector2i(3, 7))
	var rob: Dictionary = b.units.back()
	b._spawn("soldat_infanterie", "e", Vector2i(5, 7))
	var s1: Dictionary = b.units.back()
	b._spawn("soldat_infanterie", "e", Vector2i(6, 7))
	var s2: Dictionary = b.units.back()
	var tiles := b._ab_tiles(rob, "dampframme", rob["pos"])
	check(tiles.has(Vector2i(7, 7)) and not tiles.has(Vector2i(8, 7)), "Zielfelder: bis vier Felder geradeaus (%s)" % [tiles])
	check(not tiles.has(Vector2i(4, 8)), "nur gerade Linien")
	var hp1: int = s1["hp"]
	var hp2: int = s2["hp"]
	await b._run_ability(rob, "dampframme", {"pos": Vector2i(7, 7), "tile": true})
	check(rob["pos"] == Vector2i(7, 7), "Robina steht am Zielfeld (%s)" % [rob["pos"]])
	check(s1["hp"] < hp1 and s2["hp"] < hp2, "beide Feinde im Weg bekommen Schaden")
	check(s1["pos"].x == 5 and s1["pos"].y != 7 and s2["pos"].x == 6 and s2["pos"].y != 7, "beide wurden zur Seite gestossen (%s, %s)" % [s1["pos"], s2["pos"]])
	check(int(rob["cd"].get("dampframme", 0)) == 4, "Abklingzeit 4")
	# Verbuendeter beendet die Linie
	b._spawn("hund", "p", Vector2i(7, 9))
	var ally: Dictionary = b.units.back()
	b._spawn("panzer", "p", Vector2i(9, 9))
	var rob2: Dictionary = b.units.back()
	var t2 := b._ab_tiles(rob2, "dampframme", rob2["pos"])
	check(not t2.has(Vector2i(7, 9)) and t2.has(Vector2i(8, 9)), "Verbuendeter im Weg beendet die Linie")
	# Rang-Text
	var tx := Talents.next_rank_text(b.abilities["dampframme"], 0)
	check(tx.begins_with("Schaden ×1,2 → ×1,44"), "Rang 1 verstaerkt die Wirkung: %s" % tx)
	print("dampframme: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
