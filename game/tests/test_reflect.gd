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

	# --- Futter fuer Brumm (mode "catch"): Mira steht auf der Flugbahn des Knochenwurfs
	clear()
	scenes.clear()
	var hund := spawn("hund", "p", Vector2i(2, 5))
	var mira := spawn("maedchen_baer", "p", Vector2i(3, 5))
	var gegner := spawn("soldat_infanterie", "e", Vector2i(4, 5))
	var ref_foe := spawn("soldat_infanterie", "e", Vector2i(4, 8))
	mira["hp"] = 20
	gegner["hp"] = 100
	gegner["maxhp"] = 100
	check(not b._beam_blocker(hund, "knochenwurf", gegner).is_empty(), "Mira steht auf der Flugbahn")
	var normal_dmg := 0
	for h in 3:
		normal_dmg += Combat.damage(hund, gegner, b._cover_for(gegner, gegner["pos"]), 0.0, 0.5)
	await b._run_ability(hund, "knochenwurf", gegner)
	check(mira["hp"] == 28, "Mira und Brumm werden um 8 geheilt (%d)" % mira["hp"])
	check(Status.has(mira, "satt") and int(Status.get_status(mira, "satt")["turns"]) == 3, "Satt fuer 3 Runden")
	check(100 - gegner["hp"] >= normal_dmg - 3, "der Angriff selbst bleibt unveraendert (%d statt %d)" % [100 - gegner["hp"], normal_dmg])
	check(scenes == ["futter_fuer_brumm"], "Szene beim ersten Mal")
	var strong := {"atk": 30, "dmg_type": "body", "status": []}
	var raw := Combat.damage(strong, hund, 0, 0.0)
	var with_satt := Combat.damage(strong, mira, 0, 0.0)
	Status.remove(mira, "satt")
	var without_satt := Combat.damage(strong, mira, 0, 0.0)
	check(with_satt < without_satt and with_satt == maxi(1, ceili(without_satt * 0.75)), "Satt: 25 %% weniger Schaden (%d statt %d)" % [with_satt, without_satt])
	Status.add(mira, "satt", 3, {"reduce_pct": 25})
	check(raw > 0, "Gegenprobe ok")
	# zweites Mal: keine Szene, Effekt bleibt
	scenes.clear()
	hund["cd"] = {}
	mira["hp"] = 10
	await b._run_ability(hund, "knochenwurf", gegner)
	check(scenes.is_empty() and mira["hp"] == 18, "spaeter ohne Szene, Heilung bleibt")
	# andere Figur im Weg: nichts
	clear()
	var h2 := spawn("hund", "p", Vector2i(2, 5))
	var knight := spawn("ritter", "p", Vector2i(3, 5))
	var g2 := spawn("soldat_infanterie", "e", Vector2i(4, 5))
	knight["hp"] = 10
	await b._run_ability(h2, "knochenwurf", g2)
	check(knight["hp"] == 10 and not Status.has(knight, "satt"), "andere Figur im Weg faengt nichts auf")

	# --- Shuriken Regen: Muskelaugust wirft die Ninja-Schwestern
	clear()
	scenes.clear()
	var aug := spawn("museklaugust", "p", Vector2i(2, 5))
	var nin := spawn("ninjas", "p", Vector2i(3, 5))
	var f1 := spawn("soldat_infanterie", "e", Vector2i(7, 5))        # im Umkreis 2 um das Landefeld (6, 5)
	var f2 := spawn("soldat_beritten", "e", Vector2i(7, 6))
	var f3 := spawn("soldat_infanterie", "e", Vector2i(10, 9))       # weit weg
	for f: Dictionary in [f1, f2, f3]:
		f["hp"] = 100
		f["maxhp"] = 100
	check(not Secrets.find_throw("museklaugust", "wurf", "ninjas").is_empty() and Secrets.find_throw("museklaugust", "wurf", "ritter").is_empty(), "Wurf-Geheimnis nur fuer die Ninjas")
	b.sel = aug
	b._landing_ally = nin
	b._cur_ab = "wurf"
	var expect := Combat.damage(nin, f1, b._cover_for(f1, f1["pos"]), 0.0, 0.75)
	await b._do_throw_ally(Vector2i(6, 5))
	check(nin["pos"] == Vector2i(6, 5), "die Ninjas landen auf dem Zielfeld")
	check(100 - f1["hp"] == expect and 100 - f2["hp"] > 0, "Gegner im Umkreis bekommen den Regen (%d, erwartet %d)" % [100 - f1["hp"], expect])
	check(f3["hp"] == 100, "weit entfernte Gegner nicht")
	check(nin["hp"] == nin["maxhp"] and aug["hp"] == aug["maxhp"], "keine Verbuendeten getroffen")
	check(nin["st"]["dealt"] > 0, "Statistik zaehlt fuer die Ninjas")
	check(scenes == ["shuriken_regen"], "Szene beim ersten Mal")
	# ein anderer Verbuendeter fliegt normal
	clear()
	scenes.clear()
	var a2 := spawn("museklaugust", "p", Vector2i(2, 5))
	var kn := spawn("ritter", "p", Vector2i(3, 5))
	var e2 := spawn("soldat_infanterie", "e", Vector2i(7, 5))
	b.sel = a2
	b._landing_ally = kn
	b._cur_ab = "wurf"
	await b._do_throw_ally(Vector2i(6, 5))
	check(e2["hp"] == e2["maxhp"] and scenes.is_empty(), "andere Figuren verteilen keinen Regen")

	# --- Woll im Ueberfluss: Wendy steht neben Elisabeth, wenn diese die Kanone abfeuert
	clear()
	scenes.clear()
	var eli := spawn("elisabeth", "p", Vector2i(3, 5))
	var wen := spawn("wendy", "p", Vector2i(3, 6))
	var nahe_fig := spawn("ritter", "p", Vector2i(4, 7))       # im Umkreis 2 um Wendy
	var weitweg := spawn("kungfu", "p", Vector2i(8, 6))      # ausserhalb
	var ziel := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	ziel["hp"] = 100
	ziel["maxhp"] = 100
	await b._run_ability(eli, "kanone", ziel)
	check(Status.has(wen, "schild") and Status.has(nahe_fig, "schild") and Status.has(eli, "schild"), "Wollmantel auf alle Verbuendeten im Umkreis (Wendy, Ritter, Elisabeth)")
	check(not Status.has(weitweg, "schild"), "Ausserhalb des Umkreises kein Wollmantel")
	check(int(wen["cd"].get("wollmantel", 0)) == 3, "Wendys normale Abklingzeit ist ausgeloest")
	check(100 - ziel["hp"] > 0, "die Kanone trifft wie sonst")
	check(scenes == ["woll_im_ueberfluss"], "Szene beim ersten Mal")
	# Wendy nicht bereit: keine Reaktion
	clear()
	scenes.clear()
	var wo_e2 := spawn("elisabeth", "p", Vector2i(3, 5))
	var wo_w2 := spawn("wendy", "p", Vector2i(3, 6))
	var wo_z2 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	wo_w2["cd"]["wollmantel"] = 2
	await b._run_ability(wo_e2, "kanone", wo_z2)
	check(not Status.has(wo_w2, "schild") and not Status.has(wo_e2, "schild"), "Wendy hat die Faehigkeit nicht bereit: kein Wollmantel")
	# nicht benachbart: keine Reaktion
	clear()
	var wo_e3 := spawn("elisabeth", "p", Vector2i(3, 5))
	var wo_w3 := spawn("wendy", "p", Vector2i(3, 7))
	var wo_z3 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	await b._run_ability(wo_e3, "kanone", wo_z3)
	check(not Status.has(wo_w3, "schild"), "Wendy nicht auf einem Nachbarfeld: kein Wollmantel")
	# zweites Mal: ohne Szene
	clear()
	scenes.clear()
	var wo_e4 := spawn("elisabeth", "p", Vector2i(3, 5))
	var wo_w4 := spawn("wendy", "p", Vector2i(2, 5))
	var wo_z4 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	await b._run_ability(wo_e4, "kanone", wo_z4)
	check(Status.has(wo_w4, "schild") and scenes.is_empty(), "spaeter ohne Szene, Wollmantel weiterhin")

	# --- Inspiration von oben: Albrecht steht neben dem Gegner, den Lumis Sternschnuppe trifft
	clear()
	scenes.clear()
	var lumi2 := spawn("magical_girl", "p", Vector2i(0, 0))
	var albrecht := spawn("ritter", "p", Vector2i(6, 6))
	var abseits := spawn("kungfu", "p", Vector2i(9, 9))
	var opfer := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	opfer["hp"] = 100
	opfer["maxhp"] = 100
	var atk_vor: int = Combat.stat(albrecht, "atk")
	await b._run_ability(lumi2, "sternschnuppe", opfer)
	check(Status.has(albrecht, "inspiriert") and int(Status.get_status(albrecht, "inspiriert")["turns"]) == 2, "Albrecht ist 2 Runden inspiriert")
	check(Combat.stat(albrecht, "atk") == atk_vor + maxi(1, roundi(atk_vor * 0.25)), "25 %% mehr Angriff (%d -> %d)" % [atk_vor, Combat.stat(albrecht, "atk")])
	check(not Status.has(abseits, "inspiriert") and not Status.has(lumi2, "inspiriert"), "nur wer neben dem Getroffenen steht")
	check(100 - opfer["hp"] > 0 and scenes == ["inspiration_von_oben"], "Sternschnuppe trifft wie sonst, Szene beim ersten Mal")
	# nicht daneben: keine Inspiration
	clear()
	scenes.clear()
	var l3 := spawn("magical_girl", "p", Vector2i(0, 0))
	var a3 := spawn("ritter", "p", Vector2i(9, 9))
	var o3 := spawn("soldat_infanterie", "e", Vector2i(6, 5))
	await b._run_ability(l3, "sternschnuppe", o3)
	check(not Status.has(a3, "inspiriert"), "Albrecht steht nicht neben dem Gegner: nichts")
	# andere Faehigkeit von Lumi (Heilung) loest nichts aus
	clear()
	var l4 := spawn("magical_girl", "p", Vector2i(0, 0))
	var a4 := spawn("ritter", "p", Vector2i(2, 0))
	a4["hp"] = 10
	await b._run_ability(l4, "sternensegen", a4)
	check(not Status.has(a4, "inspiriert"), "Sternensegen inspiriert nicht")

	# --- Idee ohne trigger tut nichts
	var only_idea := Secrets.find_beam("robo", "roter_laser", "kungfu")
	check(only_idea.is_empty(), "ohne Eintrag keine Umlenkung")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
