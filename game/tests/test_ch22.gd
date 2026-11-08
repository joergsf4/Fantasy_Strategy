extends SceneTree
## godot --headless --path game --script tests/test_ch22.gd
## Mission 22 "Die Zwergenmine": drei Zwerge in einem Zug befreien (nicht mit Wache daneben), Wart steht unangreifbar und untaetig
## am Stollen und schickt nach jeder besiegten Welle die naechste (reihum), gewonnen ist nur durch Befreien.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _clear_wave(b: Battle) -> void:
	for e in b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e" and u["id"] != "cyborg_wart"):
		b.units.erase(e)


func _initialize() -> void:
	Engine.time_scale = 20.0
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	check(FileAccess.get_file_as_string("res://scripts/main.gd").contains('"ch21", "ch22"'), "Mission 22 steht in der Kapitelliste")
	var m := Mission.load_mission("ch22")
	check(m["title"] == "Die Zwergenmine" and m["goals"][0]["type"] == "free_all", "Titel und Ziel")
	for f in ["zwerg_alt", "zwerg_jung", "zwerg_kraeftig"]:
		check(ResourceLoader.exists("res://assets/tokens/%s.png" % f), "Sprite " + f)
	var b := Battle.new()
	b.setup(m, defs)
	b.dialogue_runner = func(_lines: Array) -> void: pass
	root.add_child(b)
	await process_frame
	var wart := b._find("cyborg_wart")
	check(not wart.is_empty() and wart["idle"] and not b._hittable(wart), "Wart ist untaetig und unangreifbar")
	var dwarves := b.world.objects.filter(func(o: Dictionary) -> bool: return o["type"] == "hostage")
	check(dwarves.size() == 3, "drei Zwerge")
	var west: Dictionary = b.world.by_id("zwerg1")
	check(not b._hostage_option(west)["enabled"], "mit Wache daneben kein Befreien")
	# Wellen: erste Welle weg -> naechste kommt, auch beim zweiten und dritten Mal, reihum andere
	var seen: Array = []
	for i in 3:
		_clear_wave(b)
		await b._flush_events()
		var wave := b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e" and u["id"] != "cyborg_wart")
		check(wave.size() >= 3, "Welle %d kommt (%d Gegner)" % [i + 1, wave.size()])
		seen.append(",".join(wave.map(func(u: Dictionary) -> String: return u["id"])))
	check(seen[0] != seen[1], "Wellen wechseln sich ab: %s" % [seen])
	check(not b.goal_met(), "nur Wellen besiegen gewinnt nicht")
	# Befreien in einem Zug
	_clear_wave(b)
	var hero: Dictionary = b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "p")[0]
	check(b._hostage_option(west)["text"] == "Befreien" and b._hostage_option(west)["enabled"], "ohne Wache: Befreien in einem Zug")
	await b._free_hostage(hero, west)
	await create_timer(3.0).timeout      # die naechste Welle (alle Wachen waren weg) erscheint mit Einblendungen
	check(west["state"] == "free", "Zwerg ist nach einem Zug frei")
	for o: Dictionary in dwarves:
		if o["state"] != "free":
			b.world.apply(o, "free")
	check(b.goal_met(), "alle drei frei: Mission gewonnen, auch wenn Wart noch steht")
	var got := []
	b.finished.connect(func(w: bool) -> void: got.append(w))
	await b._check_end()
	check(got == [true], "Mission gewonnen")
	check(b.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e").is_empty() and b.retreated.has("cyborg_wart"), "Wart blaest zum Rueckzug: er und alle Wachen ziehen ab")
	# Missionen 4 und 13 bleiben bei zwei Schritten
	var b4 := Battle.new()
	b4.setup(Mission.load_mission("ch4"), defs)
	root.add_child(b4)
	await process_frame
	var g: Dictionary = b4.world.by_id("geisel")
	for e in b4.units.filter(func(u: Dictionary) -> bool: return u["team"] == "e"):
		b4.units.erase(e)
	check(b4._hostage_option(g)["text"] == "Fesseln lösen (1/2)", "Mission 4: weiter zwei Schritte")
	print("ch22: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
