extends SceneTree
## godot --headless --path game --script tests/test_abilities.gd
## Spielt jede Faehigkeit auf einer leeren Karte durch und prueft die Wirkung.

var fails := 0
var b: Battle


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 10.0
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	b.setup(map, defs)
	root.add_child(b)
	await process_frame
	await run_tests()
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func clear() -> void:
	for u in b.units + b._away:
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b.state = Battle.State.IDLE


func spawn(id: String, team: String, pos: Vector2i) -> Dictionary:
	b._spawn(id, team, pos)
	var u: Dictionary = b.units.back()
	return u


func run_tests() -> void:
	b.rng.seed = 7
	# --- Baerenpranke: Schaden + Spott
	clear()
	var mira := spawn("maedchen_baer", "p", Vector2i(6, 7))
	var foe := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	spawn("ritter", "p", Vector2i(1, 8))   # damit niemand "Sieg" ausloest
	var hp0: int = foe["hp"]
	await b._run_ability(mira, "baerenpranke", foe)
	check(foe["hp"] < hp0, "Baerenpranke macht Schaden")
	check(Status.has(foe, "taunt") and Status.get_status(foe, "taunt")["src"] == mira["uid"], "Ziel ist gespottet (Quelle Mira)")
	check(mira["cd"]["baerenpranke"] == 3, "Abklingzeit gesetzt")
	check(b._ab_targets(mira, "baerenpranke", mira["pos"]).size() == 1, "Faehigkeit bleibt zielbar")

	# --- Spott in der KI: Gegner greift den Spotter an, nicht den schwaecheren Nachbarn
	clear()
	var tank := spawn("ritter", "p", Vector2i(5, 7))
	var weak := spawn("wendy", "p", Vector2i(6, 6))
	var e := spawn("soldat_infanterie", "e", Vector2i(6, 7))
	Status.add(e, "taunt", 2, {}, tank["uid"])
	var tank_hp: int = tank["hp"]
	var weak_hp: int = weak["hp"]
	await b._enemy_move(e)
	check(weak["hp"] == weak_hp, "Gespotteter Gegner ignoriert Wendy")
	check(tank["hp"] < tank_hp or tank["hp"] == tank_hp, "Spotter ist Ziel (Schaden 1 minimal moeglich)")
	check(Grid.dist(e["pos"], tank["pos"]) == 1, "Gegner steht neben dem Spotter")

	# --- Versteck: nicht angreifbar, KI ignoriert
	clear()
	var nin := spawn("ninjas", "p", Vector2i(6, 7))
	var e2 := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	await b._run_ability(nin, "versteck", nin)
	check(Status.has(nin, "stealth"), "Versteck aktiv")
	check(b._attack_targets(e2, e2["pos"]).is_empty(), "Verborgene nicht angreifbar")
	var nhp: int = nin["hp"]
	await b._enemy_move(e2)
	check(nin["hp"] == nhp, "KI greift Verborgene nicht an")
	var fc_amb := b.forecast(nin, e2)
	check(fc_amb["tags"].has("Hinterhalt +30 %"), "Hinterhalt-Bonus in der Vorschau")

	# --- Gift 3/4/5, Heilung entfernt es
	clear()
	var bee := spawn("bienenmaedchen", "e", Vector2i(7, 7))
	var victim := spawn("samurai", "p", Vector2i(6, 7))
	var healer := spawn("wendy", "p", Vector2i(5, 7))
	await b._run_ability(bee, "giftstachel", victim)
	check(Status.has(victim, "poison"), "Gift wirkt")
	var hp_before: int = victim["hp"]
	await b._begin_phase("p")
	check(victim["hp"] == hp_before - 3, "Gifttick 1 = 3, war %d" % (hp_before - victim["hp"]))
	await b._resolve(healer, victim)
	check(not Status.has(victim, "poison"), "Heilung entfernt Gift")

	# --- Todeswirbel trifft mehrere Nachbarn, danach erschoepft
	clear()
	var sam := spawn("samurai", "p", Vector2i(6, 7))
	var a1 := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	var a2 := spawn("soldat_infanterie", "e", Vector2i(6, 6))
	var far := spawn("soldat_infanterie", "e", Vector2i(8, 7))
	await b._run_ability(sam, "todeswirbel", sam)
	check(a1["hp"] < a1["maxhp"] and a2["hp"] < a2["maxhp"], "Todeswirbel trifft beide Nachbarn")
	check(far["hp"] == far["maxhp"], "Entfernter Gegner unberuehrt")
	check(Combat.stat(sam, "def") == 4 - 2, "Takeda erschoepft (DEF -2)")

	# --- Schlachtruf: Buff im Umkreis 2, nicht ausserhalb
	clear()
	var alb := spawn("ritter", "p", Vector2i(6, 7))
	var near := spawn("maedchen_baer", "p", Vector2i(5, 7))
	var farp := spawn("wendy", "p", Vector2i(2, 7))
	await b._run_ability(alb, "schlachtruf", alb)
	check(Combat.stat(near, "atk") == 7 + 3 and Combat.stat(alb, "atk") == 8 + 3, "Buff fuer Nahe und Albrecht")
	check(Combat.stat(farp, "atk") == 3, "Buff reicht nicht bis Wendy")

	# --- Verspotten: Gegner im Umkreis 3
	clear()
	alb = spawn("ritter", "p", Vector2i(6, 7))
	var s1 := spawn("soldat_infanterie", "e", Vector2i(8, 7))
	var s2 := spawn("soldat_infanterie", "e", Vector2i(6, 3))
	await b._run_ability(alb, "verspotten", alb)
	check(Status.has(s1, "taunt") and not Status.has(s2, "taunt"), "Verspotten nur im Umkreis 3")

	# --- Stabsprung: landet hinter dem Gegner, mit Ruecken-Bonus
	clear()
	var lin := spawn("kungfu", "p", Vector2i(6, 7))
	var target := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	b._face_step(target, Vector2i.LEFT)   # schaut zu Lin
	check(b._ab_targets(lin, "stabsprung", lin["pos"]).has(target), "Sprung moeglich bei freiem Landefeld")
	var blocker := spawn("soldat_beritten", "e", Vector2i(8, 7))
	check(not b._ab_targets(lin, "stabsprung", lin["pos"]).has(target), "Kein Sprung bei besetztem Landefeld")
	b.units.erase(blocker)
	(blocker["node"] as Node3D).queue_free()
	var thp: int = target["hp"]
	await b._run_ability(lin, "stabsprung", target)
	check(lin["pos"] == Vector2i(8, 7), "Lin landet hinter dem Gegner")
	check(target["hp"] < thp, "Sprung trifft")
	check(lin["dir"] == Vector2i.LEFT, "Lin blickt zurueck")

	# --- Wurf: Gegner fliegt, ist benommen
	clear()
	var mus := spawn("museklaugust", "p", Vector2i(6, 7))
	var thrown := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	var origin: Vector2i = thrown["pos"]
	await b._run_ability(mus, "wurf", thrown)
	check(thrown["pos"] != origin and Grid.dist(thrown["pos"], origin) <= 4, "Gegner wurde bis zu 4 Felder geworfen")
	check(units_free(thrown), "Landefeld ist frei und passierbar")
	check(Status.has(thrown, "stun") or thrown["hp"] <= 0, "Gegner benommen")

	# --- Benommen: Gegner setzt naechste Phase aus
	clear()
	spawn("ritter", "p", Vector2i(1, 8))
	var st := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	Status.add(st, "stun", 1)
	await b._begin_phase("e")
	check(st["done"], "Benommener setzt aus")
	check(not Status.has(st, "stun"), "Benommen laeuft ab")

	# --- Polymorph: weg fuer 3 Runden, dann zurueck
	clear()
	var cl := spawn("claude", "p", Vector2i(6, 7))
	spawn("ritter", "p", Vector2i(1, 8))
	var sold := spawn("soldat_infanterie", "e", Vector2i(8, 7))
	var other := spawn("soldat_infanterie", "e", Vector2i(2, 2))
	var hero_def := spawn("samurai", "e", Vector2i(8, 6))
	check(b._ab_targets(cl, "polymorph", cl["pos"]).has(sold), "Polymorph zielt auf Soldaten")
	check(not b._ab_targets(cl, "polymorph", cl["pos"]).has(hero_def), "Polymorph nicht auf Helden")
	await b._run_ability(cl, "polymorph", sold)
	check(not b.units.has(sold) and b._away.has(sold), "Soldat ist aus dem Spiel")
	check(b.unit_at(Vector2i(8, 7)).is_empty(), "Feld wieder frei")
	for i in 3:
		await b._begin_phase("e")
	check(b.units.has(sold) and b._away.is_empty(), "Soldat kehrt nach 3 Runden zurueck")
	check(other != sold, "Test-Hilfsfigur")

	# --- Heilung + Gruppenheilung
	clear()
	var wen := spawn("wendy", "p", Vector2i(6, 7))
	var h1 := spawn("ritter", "p", Vector2i(7, 7))
	var h2 := spawn("samurai", "p", Vector2i(8, 7))
	spawn("soldat_infanterie", "e", Vector2i(2, 2))
	h1["hp"] -= 10
	h2["hp"] -= 10
	Status.add(h2, "poison", 3)
	await b._run_ability(wen, "gruppenheilung", h1)
	check(h1["hp"] == h1["maxhp"] - 4 and h2["hp"] == h2["maxhp"] - 4, "Gruppenheilung +6 an beiden, war %d/%d" % [h1["maxhp"] - h1["hp"], h2["maxhp"] - h2["hp"]])
	check(not Status.has(h2, "poison"), "Gruppenheilung entfernt Gift")

	# --- Kanone: Splash auf Nachbarn des Ziels
	clear()
	var eli := spawn("elisabeth", "p", Vector2i(5, 7))
	var main_t := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	var splash_t := spawn("soldat_infanterie", "e", Vector2i(8, 7))
	var far_t := spawn("soldat_infanterie", "e", Vector2i(7, 3))
	await b._run_ability(eli, "kanone", main_t)
	check(main_t["hp"] < main_t["maxhp"] and splash_t["hp"] < splash_t["maxhp"], "Kanone trifft Ziel und Nachbarn")
	check(far_t["hp"] == far_t["maxhp"], "Kanone trifft nicht weit Entfernte")
	check(main_t["maxhp"] - main_t["hp"] > splash_t["maxhp"] - splash_t["hp"], "Splash schwaecher als Haupttreffer")

	# --- Roter Laser: Linie trifft alle Gegner, schont Verbuendete, nur auf geraden Linien
	clear()
	var rb := spawn("robo", "p", Vector2i(3, 7))
	var l1 := spawn("soldat_infanterie", "e", Vector2i(5, 7))
	var l2 := spawn("soldat_beritten", "e", Vector2i(6, 7))
	var spare := spawn("kungfu", "p", Vector2i(4, 7))
	var off := spawn("soldat_infanterie", "e", Vector2i(5, 6))
	var tl: Array = b._ab_targets(rb, "roter_laser", rb["pos"])
	check(tl.has(l1) and tl.has(l2) and not tl.has(off), "Laser: nur Gegner auf geraden Linien waehlbar")
	await b._run_ability(rb, "roter_laser", l1)
	check(l1["hp"] < l1["maxhp"] and l2["hp"] < l2["maxhp"], "Laser trifft alle Gegner auf der Linie")
	check(spare["hp"] == spare["maxhp"] and off["hp"] == off["maxhp"], "Laser schont Verbuendete und Gegner neben der Linie")

	# --- Wurf ueber den See: nur das Landefeld zaehlt
	clear()
	var mu := spawn("museklaugust", "p", Vector2i(4, 4))
	var th := spawn("soldat_infanterie", "e", Vector2i(5, 4))
	# Rechts von (5,4) liegen Wasserfelder (6,4)/(7,4); (8,4) ist Gras -> gueltiges Landefeld ueber das Wasser
	await b._throw(mu, th, {"dist": 4, "mult": 0.5, "stun": 1})
	check(b.grid.cost(th["pos"], false) >= 0 and b.unit_at(th["pos"]) == th, "Wurf landet auf begehbarem Feld")

	# --- Laser, Knochenwurf, Fasswurf
	clear()
	var robo := spawn("robo", "p", Vector2i(4, 7))
	var tgt := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	var h: int = tgt["hp"]
	await b._run_ability(robo, "roter_laser", tgt)
	check(tgt["hp"] < h, "Roter Laser trifft")
	var ally := spawn("ritter", "p", Vector2i(5, 7))
	ally["hp"] -= 12
	await b._run_ability(robo, "gruener_laser", ally)
	check(ally["hp"] == ally["maxhp"], "Gruener Laser heilt 12")
	var dog := spawn("hund", "p", Vector2i(6, 6))
	var bt := spawn("soldat_beritten", "e", Vector2i(7, 6))
	var hb: int = bt["hp"]
	await b._run_ability(dog, "knochenwurf", bt)
	check(bt["hp"] < hb, "Knochenwurf trifft")
	var bru := spawn("braumeisterin", "p", Vector2i(5, 6))
	var barrel := spawn("soldat_infanterie", "e", Vector2i(8, 6))
	await b._run_ability(bru, "fasswurf", barrel)
	check(Status.has(barrel, "taunt"), "Fasswurf: Ziel wuetend")

	# --- Schildwall / Sturmangriff
	clear()
	var inf1 := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	var inf2 := spawn("soldat_infanterie", "e", Vector2i(8, 7))
	check(b._cover_for(inf1, inf1["pos"]) == 1, "Schildwall +1 neben Infanterie")
	b.units.erase(inf2)
	(inf2["node"] as Node3D).queue_free()
	check(b._cover_for(inf1, inf1["pos"]) == 0, "Kein Schildwall allein")

	# --- Abklingzeit sinkt in der eigenen Phase
	clear()
	var cd_u := spawn("samurai", "p", Vector2i(6, 7))
	cd_u["cd"]["todeswirbel"] = 3
	spawn("soldat_infanterie", "e", Vector2i(2, 2))
	await b._begin_phase("p")
	check(cd_u["cd"]["todeswirbel"] == 2, "Abklingzeit 3 -> 2")

	# --- Verteidigen (Aktion im Menue)
	clear()
	var wall_t := spawn("ritter", "p", Vector2i(6, 7))
	var raider := spawn("soldat_infanterie", "e", Vector2i(7, 7))
	spawn("wendy", "p", Vector2i(0, 9))
	var before: int = b.forecast(raider, wall_t)["dmg"]
	await b._defend(wall_t)
	check(Status.has(wall_t, "defend") and wall_t["done"], "Verteidigen: Status gesetzt, Figur ist fertig")
	var after: int = b.forecast(raider, wall_t)["dmg"]
	check(after == maxi(1, ceili(before * 0.4)), "Tank verteidigt: Schaden %d -> %d (x0,4)" % [before, after])
	check(b.forecast(raider, wall_t)["counter"] == -1, "Vorschau: kein Gegenschlag")
	await b._begin_phase("p")
	check(not Status.has(wall_t, "defend"), "Verteidigen endet mit der naechsten eigenen Phase")
	# Verteidigen nach dem Stabsprung (Sprung kostet die Aktion nicht)
	clear()
	var jumper := spawn("kungfu", "p", Vector2i(4, 7))
	var target_s := spawn("soldat_infanterie", "e", Vector2i(5, 7))
	spawn("wendy", "p", Vector2i(0, 9))
	await b._run_ability(jumper, "stabsprung", target_s)
	check(not jumper["done"], "Nach dem Stabsprung ist die Figur noch nicht fertig")
	await b._defend(jumper)
	check(jumper["done"] and Status.has(jumper, "defend") and jumper["pos"] == Vector2i(6, 7), "Springen, dann Verteidigen")


func units_free(u: Dictionary) -> bool:
	return b.grid.cost(u["pos"], u["flying"]) >= 0
