extends SceneTree
## godot --headless --path game --script tests/test_stats.gd
## Kampfstatistik: Schaden, Gegenschlag, Heilung, Besiegte, Auszeichnungen, Anzeige im Belohnungsbildschirm.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	Sfx.muted = true
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var b := Battle.new()
	var m := Mission.load_mission("ch1")
	m["players"] = []
	m["enemies"] = []
	m["triggers"] = []
	b.setup(m, defs)
	root.add_child(b)
	await process_frame
	b._spawn("ritter", "p", Vector2i(2, 5))
	var rit: Dictionary = b.units.back()
	b._spawn("wendy", "p", Vector2i(1, 5))
	var wen: Dictionary = b.units.back()
	b._spawn("soldat_infanterie", "e", Vector2i(3, 5))
	var sold: Dictionary = b.units.back()
	rit["hp"] = 20
	var hp_sold: int = sold["hp"]
	await b._resolve(rit, sold)
	check(rit["st"]["dealt"] == hp_sold - sold["hp"] and rit["st"]["dealt"] > 0, "Schaden des Angriffs wird gezaehlt")
	check(sold["st"]["taken"] == rit["st"]["dealt"], "erlittener Schaden des Gegners stimmt")
	check(rit["st"]["taken"] == 20 - rit["hp"] and sold["st"]["dealt"] == rit["st"]["taken"], "Gegenschlag wird gezaehlt")
	await b._resolve(wen, rit)
	check(wen["st"]["healed"] == mini(wen["heal"], rit["maxhp"] - 20 + rit["st"]["taken"]) or wen["st"]["healed"] > 0, "Heilung wird gezaehlt")
	sold["hp"] = 1
	await b._resolve(rit, sold)
	check(rit["st"]["kills"] == 1, "Besiegter Gegner zaehlt als Sieg des Angreifers")
	var st: Dictionary = b.stats()
	check((st["rows"] as Array).size() == 2, "Statistik listet beide Helden")
	var titles: Array = (st["awards"] as Array).map(func(a: Dictionary) -> String: return a["title"])
	check(titles.has("Schlagkräftigster") and titles.has("Sanitäter") and titles.has("Gegnerschreck"), "Auszeichnungen: %s" % [titles])
	check(b.results().has("stats"), "Ergebnis enthaelt die Statistik")
	var rs := RewardScreen.new()
	rs.setup(b.results())
	root.add_child(rs)
	await process_frame
	check(rs.find_children("*", "GridContainer", true, false).size() == 1, "Belohnungsbildschirm zeigt die Statistik-Tabelle")
	# Niederlage: nur Statistik, keine Beute
	var ds: Dictionary = b.defeat_summary()
	check(ds["defeat"] and ds["gold"] == 0 and (ds["stats"]["rows"] as Array).size() == 2, "Niederlage-Bilanz: Statistik ohne Beute")
	var dr := RewardScreen.new()
	dr.setup(ds)
	root.add_child(dr)
	await process_frame
	check(dr.find_children("*", "GridContainer", true, false).size() == 1, "Niederlage-Bildschirm zeigt die Statistik-Tabelle")
	var texts: Array = dr.find_children("*", "Button", true, false).map(func(x: Button) -> String: return x.text)
	check(texts.has("Noch einmal versuchen"), "Niederlage-Bildschirm: Knopf zum neuen Versuch")
	var labels: Array = dr.find_children("*", "Label", true, false).map(func(x: Label) -> String: return x.text)
	check(labels.has("Niederlage …") and not labels.has("Beute"), "Niederlage-Bildschirm ohne Beute")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
