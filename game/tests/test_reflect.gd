extends SceneTree
## godot --headless --path game --script tests/test_reflect.gd
## Geheimnis "Laser-Reflektor": Takeda auf der Linie lenkt Robos Laser um (Umkreis 2 um Takeda, 75 %), Szene nur beim ersten Mal.

var fails := 0
var b: Battle
var scenes: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func clear() -> void:
	for u in b.units + b._away:
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b.state = Battle.State.IDLE


func spawn(id: String, team: String, pos: Vector2i) -> Dictionary:
	b._spawn(id, team, pos)
	var u: Dictionary = b.units.back()
	u["dir"] = Vector2i.RIGHT
	return u


func _initialize() -> void:
	Engine.time_scale = 10.0
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	map["rows"] = []
	for y in 12:
		(map["rows"] as Array).append("GGGGGGGGGGGG")
	for k in ["objects", "chests", "triggers", "decor"]:
		if map.has(k):
			map[k] = []
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	b.setup(map, defs)
	b.secret_runner = func(sec: Dictionary) -> void: scenes.append(sec["id"])
	b.super_music = func(_on: bool) -> void: pass
	root.add_child(b)
	await process_frame
	b.rng.seed = 3
	var sec := Secrets.by_id("laser_reflektor")
	check(not sec.is_empty() and sec["trigger"]["type"] == "beam_via_ally", "Geheimnis ist aktiv (Typ beam_via_ally)")
	check(not Secrets.find_beam("robo", "roter_laser", "samurai").is_empty() and not Secrets.find_beam("robo", "gruener_laser", "samurai").is_empty(), "beide Laser sind verknuepft")
	check(Secrets.find_beam("robo", "roter_laser", "ritter").is_empty(), "andere Figur lenkt nicht um")
	check(Secrets.find("robo", "roter_laser", "samurai").is_empty(), "find() liefert nur ability_on_ally")

	# --- Roter Laser: Takeda zwischen Robo und Ziel
	clear()
	var robo := spawn("robo", "p", Vector2i(2, 5))
	var tak := spawn("samurai", "p", Vector2i(4, 5))
	var target := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	var nahe := spawn("soldat_infanterie", "e", Vector2i(4, 3))        # im Umkreis 2 um Takeda
	var weit := spawn("soldat_infanterie", "e", Vector2i(8, 5))        # 4 Felder von Takeda: ausser Reichweite
	target["hp"] = 100
	target["maxhp"] = 100
	nahe["hp"] = 100
	nahe["maxhp"] = 100
	weit["hp"] = 100
	weit["maxhp"] = 100
	var dm: Dictionary = b.abilities["roter_laser"]["effects"][0]
	var expected := Combat.damage(robo, nahe, b._cover_for(nahe, nahe["pos"]), 0.0, float(dm["mult"]) * 0.75, float(dm["ignore_def"]))
	check(not b._beam_blocker(robo, "roter_laser", target).is_empty(), "Takeda steht im Weg")
	await b._run_ability(robo, "roter_laser", target)
	check(100 - nahe["hp"] > 0, "Gegner im Umkreis 2 um Takeda werden getroffen (%d)" % (100 - nahe["hp"]))
	check(target["hp"] < 100 and 100 - target["hp"] > 0, "Das Ziel steht im Umkreis (2 Felder von Takeda) und wird getroffen")
	check(weit["hp"] == 100, "Der Gegner ausserhalb des Umkreises bleibt unversehrt")
	check(tak["hp"] == tak["maxhp"] and robo["hp"] == robo["maxhp"], "Die Reflexion trifft keine Verbuendeten")
	check(scenes == ["laser_reflektor"], "beim ersten Mal laeuft die Szene")
	check(b.secrets_seen.has("laser_reflektor"), "Szene ist gemerkt")
	check(int(robo["cd"]["roter_laser"]) == 3, "Abklingzeit gesetzt")
	check(robo["st"]["dealt"] > 0 and robo["st"]["abs"] == 1, "Statistik zaehlt fuer Robo")
	check(abs((100 - nahe["hp"]) - expected) <= 3, "Schaden ~ 75 %% der Normalwirkung (%d, erwartet %d)" % [100 - nahe["hp"], expected])

	# --- Zweites Mal: keine Szene mehr, Effekt bleibt
	scenes.clear()
	robo["cd"] = {}
	var hp_before: int = nahe["hp"]
	await b._run_ability(robo, "roter_laser", target)
	check(scenes.is_empty() and nahe["hp"] < hp_before, "spaeter: keine Szene, Effekt weiter")

	# --- ohne Takeda auf der Linie: normale Wirkung (Linie trifft alle Gegner)
	clear()
	var r2 := spawn("robo", "p", Vector2i(2, 5))
	var k2 := spawn("ritter", "p", Vector2i(4, 5))
	var t2 := spawn("soldat_infanterie", "e", Vector2i(5, 5))
	var t3 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	check(b._beam_blocker(r2, "roter_laser", t2).is_empty(), "ein anderer Verbuendeter im Weg lenkt nicht um")
	var hp2: int = t3["hp"]
	await b._run_ability(r2, "roter_laser", t2)
	check(t3["hp"] < hp2 and k2["hp"] == k2["maxhp"], "normale Linienwirkung trifft auch den Gegner dahinter, Verbuendete bleiben heil")

	# --- Takeda nicht auf der Linie (diagonal versetzt)
	clear()
	var r3 := spawn("robo", "p", Vector2i(2, 5))
	spawn("samurai", "p", Vector2i(4, 6))
	var t4 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	check(b._beam_blocker(r3, "roter_laser", t4).is_empty(), "Takeda neben der Linie lenkt nicht um")

	# --- Gruener Laser: Takeda zwischen Robo und verletztem Ziel, Verbuendete im Umkreis werden geheilt
	clear()
	scenes.clear()
	var r4 := spawn("robo", "p", Vector2i(2, 5))
	var tk := spawn("samurai", "p", Vector2i(3, 5))
	var verl := spawn("ritter", "p", Vector2i(4, 5))
	var daneben := spawn("wendy", "p", Vector2i(3, 3))
	var fern := spawn("kungfu", "p", Vector2i(3, 9))
	for h: Dictionary in [tk, verl, daneben, fern]:
		h["hp"] = 5
		Status.add(h, "poison", 3)
	await b._run_ability(r4, "gruener_laser", verl)
	check(verl["hp"] == 14 and tk["hp"] == 14 and daneben["hp"] == 14, "Verbuendete im Umkreis +9 (75 %% von 12): %d, %d, %d" % [verl["hp"], tk["hp"], daneben["hp"]])
	check(not Status.has(verl, "poison") and not Status.has(tk, "poison"), "Gegengift wirkt mit")
	check(fern["hp"] == 5 and Status.has(fern, "poison"), "Ausserhalb des Umkreises keine Heilung")
	check(scenes.is_empty() and b.secrets_seen.has("laser_reflektor"), "Szene war schon gesehen (gemeinsames Geheimnis)")
	check(r4["st"]["healed"] >= 27, "Heilung zaehlt fuer Robo")

	# --- Idee ohne trigger tut nichts
	var only_idea := Secrets.find_beam("robo", "roter_laser", "kungfu")
	check(only_idea.is_empty(), "ohne Eintrag keine Umlenkung")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
