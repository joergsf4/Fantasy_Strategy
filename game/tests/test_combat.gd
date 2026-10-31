extends SceneTree
## godot --headless --path game --script tests/test_combat.gd

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func unit(atk: int, df: int, res := 0, extra := {}) -> Dictionary:
	var u := {"atk": atk, "def": df, "res": res, "hp": 20, "maxhp": 20, "range_min": 1, "range": 1, "dmg_type": "body", "status": [], "cd": {}}
	u.merge(extra, true)
	return u


func _init() -> void:
	# Grundschaden mit Deckung
	var a := unit(8, 2)
	var d := unit(5, 3)
	check(Combat.damage(a, d, 0, 0.0) == 5, "8-3 = 5")
	check(Combat.damage(a, d, 2, 0.0) == 3, "Deckung +2 -> 3")
	check(Combat.damage(unit(1, 0), unit(1, 9), 0, 0.0) == 1, "Mindestschaden 1")
	# Magie nutzt RES
	var m := unit(9, 0, 0, {"dmg_type": "magic"})
	check(Combat.damage(m, unit(5, 9, 2), 0, 0.0) == 7, "Magie ignoriert DEF, nutzt RES")
	# Faehigkeitsfaktor, Positionsbonus, ignorierte Verteidigung
	check(Combat.damage(a, d, 0, 0.0, 1.5) == 9, "x1.5: 12-3")
	check(Combat.damage(a, d, 0, 0.3) == 7, "+30 %: round(10.4)=10 -3")
	check(Combat.damage(a, unit(5, 8), 0, 0.0, 1.0, 0.5) == 4, "50 % DEF ignoriert: 8-4")
	# Rueckenangriff: Verteidiger schaut nach rechts, Angreifer steht links = Ruecken
	var back := Combat.position_bonus(Vector2i(2, 5), Vector2i(3, 5), Vector2i(1, 0), 0.0, 0.0)
	check(is_equal_approx(back["bonus"], 0.30), "Ruecken +30 %%, war %s" % back["bonus"])
	var front := Combat.position_bonus(Vector2i(4, 5), Vector2i(3, 5), Vector2i(1, 0), 0.0, 0.0)
	check(is_equal_approx(front["bonus"], 0.0), "Front kein Bonus")
	var flank := Combat.position_bonus(Vector2i(3, 4), Vector2i(3, 5), Vector2i(1, 0), 0.0, 0.0)
	check(is_equal_approx(flank["bonus"], 0.15), "Flanke +15 %%")
	var high := Combat.position_bonus(Vector2i(4, 5), Vector2i(3, 5), Vector2i(1, 0), 0.6, 0.1)
	check(is_equal_approx(high["bonus"], 0.15), "Hoehe +15 %%")
	var combo := Combat.position_bonus(Vector2i(2, 5), Vector2i(3, 5), Vector2i(1, 0), 0.6, 0.0, true)
	check(is_equal_approx(combo["bonus"], 0.30 + 0.15 + 0.30), "Ruecken + Hoehe + Hinterhalt addieren sich")
	# Fernkampf-Abschlag und Reichweite
	var nin := unit(8, 2, 3, {"range": 2, "ranged_mult": 0.7})
	check(Combat.range_mult(nin, 1) == 1.0 and is_equal_approx(Combat.range_mult(nin, 2), 0.7), "Wurfsterne nur auf Distanz")
	var bow := unit(6, 1, 1, {"range_min": 2, "range": 3})
	check(not Combat.in_range(bow, 1) and Combat.in_range(bow, 2) and Combat.in_range(bow, 3) and not Combat.in_range(bow, 4), "Bogen: Reichweite 2-3")
	check(not Combat.can_counter(bow, 1), "Bogenschuetze kontert im Nahkampf nicht")
	check(Combat.can_counter(a, 1), "Nahkaempfer kontert")
	var stunned := unit(8, 2)
	Status.add(stunned, "stun", 1)
	check(not Combat.can_counter(stunned, 1), "Benommen: kein Gegenschlag")
	# Buffs wirken auf Werte
	var b := unit(8, 2)
	Status.add(b, "buff", 2, {"atk": 3, "def": 2})
	check(Combat.stat(b, "atk") == 11 and Combat.stat(b, "def") == 4, "Buff +3 ATK +2 DEF")
	# Gift: 3, 4, 5 und Heilung entfernt es
	var p := unit(5, 2)
	Status.add(p, "poison", 3)
	var ticks: Array[int] = []
	for i in 3:
		for e: Dictionary in Status.tick_phase_start(p):
			if e["type"] == "poison":
				ticks.append(e["amount"])
	check(ticks == [3, 4, 5], "Gift 3/4/5, war %s" % [ticks])
	check(not Status.has(p, "poison"), "Gift nach 3 Runden vorbei")
	var p2 := unit(5, 2)
	Status.add(p2, "poison", 3)
	check(Status.cleanse(p2) and not Status.has(p2, "poison"), "Heilung entfernt Gift")
	check(not Status.cleanse(p2), "nichts zu entfernen -> false")
	# Abklingzeit sinkt
	var c := unit(5, 2, 0, {"cd": {"x": 3}})
	Status.tick_phase_start(c)
	check(c["cd"]["x"] == 2, "Abklingzeit sinkt")
	# Statusdauer
	var s := unit(5, 2)
	Status.add(s, "stun", 1)
	var ev := Status.tick_phase_start(s)
	check(ev.size() == 1 and ev[0]["type"] == "expire" and not Status.has(s, "stun"), "Benommen laeuft nach einer Phase ab")
	# Verteidigen: halber Schaden (aufgerundet), Tanks x0,4, mindestens 1, kein Gegenschlag
	var big := unit(12, 0)
	var ward := unit(5, 2)
	check(Combat.damage(big, ward, 0, 0.0) == 10, "Ohne Verteidigen: 12 - 2 = 10")
	Status.add(ward, "defend", 1)
	check(Combat.damage(big, ward, 0, 0.0) == 5, "Verteidigen: 10 -> 5")
	var tank := unit(5, 2, 0, {"role": "tank"})
	Status.add(tank, "defend", 1)
	check(Combat.damage(big, tank, 0, 0.0) == 4, "Tank verteidigt: 10 -> 4 (x0,4)")
	check(Combat.damage(unit(1, 0), ward, 0, 0.0) == 1, "Mindestschaden 1 bleibt")
	check(Combat.damage(unit(5, 0), ward, 0, 0.0) == 2, "Aufrunden: 5 - 2 = 3 -> 1,5 -> 2")
	check(not Combat.can_counter(ward, 1), "Verteidigende kontern nicht")
	check(Combat.can_counter(unit(5, 2), 1), "Ohne Verteidigen kontert man")
	# nach einer Runde ist es vorbei
	var ev_def := Status.tick_phase_start(ward)
	check(not Status.has(ward, "defend") and ev_def.size() == 1 and ev_def[0]["type"] == "expire", "Verteidigen endet zu Beginn der eigenen Phase")
	# Warten macht wachsam: haerterer Gegenschlag, Verteidigen bleibt ohne Gegenschlag
	var waiter := unit(8, 2)
	var attacker := unit(6, 3)
	var plain := Combat.damage(waiter, attacker, 0, 0.0)
	Status.add(waiter, "wachsam", 1, {"atk": Combat.WAIT_ATK})
	check(Combat.damage(waiter, attacker, 0, 0.0) == plain + Combat.WAIT_ATK, "wachsam: Gegenschlag +%d Schaden" % Combat.WAIT_ATK)
	check(Combat.can_counter(waiter, 1), "wachsam kontert weiter")
	check(Combat.damage(attacker, waiter, 0, 0.0) == Combat.damage(attacker, unit(8, 2), 0, 0.0), "wachsam aendert die eigene Verteidigung nicht")
	var ev_w := Status.tick_phase_start(waiter)
	check(not Status.has(waiter, "wachsam") and ev_w.size() == 1, "wachsam endet zu Beginn der eigenen Phase")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
