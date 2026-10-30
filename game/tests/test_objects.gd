extends SceneTree
## godot --headless --path game --script tests/test_objects.gd
## Mission "Der Hohlweg" (waagerechte Mauer in Reihe y=4, Tor bei (5,4), Helden unten, Gegner oben):
## Faehigkeiten und Angriffe auf Mauer, Tor und Schalter, Sprung, Wurf auf Verbuendete, Tor von innen oeffnen.

var fails := 0
var b: Battle
var defs: Dictionary
var talk: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	var m := Mission.load_mission("ch2")
	m["players"] = []
	m["enemies"] = []
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void: talk.append(lines)
	root.add_child(b)
	await process_frame
	await run_tests()
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


## Frische Aufstellung. Ein Held steht immer weit weg und ein Gegner ebenso, damit "alle fertig" bzw. "gewonnen" nie ausloest.
func scene(heroes: Array, foes := []) -> Array:
	for u in b.units + b._away:
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b.state = Battle.State.IDLE
	b.world = World.new(Mission.load_mission("ch2")["objects"])
	b.grid.blocked = b.world.blocked()
	# nur die Tor-Ereignisse (Objekt/Feld); Kampfereignisse (Naehe, Gegner uebrig ...) gehoeren in test_events.gd
	b.triggers = (Mission.load_mission("ch2")["triggers"] as Array).filter(func(t: Dictionary) -> bool: return t["when"].has("object") or t["when"].has("enter")).duplicate(true)
	talk.clear()
	var out: Array = []
	for h: Array in heroes:
		b._spawn(h[0], "p", Vector2i(h[1][0], h[1][1]))
		out.append(b.units.back())
	b._spawn("wendy", "p", Vector2i(11, 9))
	b._spawn("soldat_infanterie", "e", Vector2i(11, 0))
	for f: Array in foes:
		b._spawn(f[0], "e", Vector2i(f[1][0], f[1][1]))
	return out


func run_tests() -> void:
	var m := Mission.load_mission("ch2")
	check(m["title"] == "Der Hohlweg" and (m["objects"] as Array).size() == 13, "Mission 2 geladen: 11 Mauerstuecke, Tor, Schalter")
	var gate_o: Dictionary = {}
	for o: Dictionary in m["objects"]:
		if o["id"] == "gate1":
			gate_o = o
	check(int(gate_o["pos"][0]) == 5 and int(gate_o["pos"][1]) == 4 and gate_o["dir"] == "h", "Tor liegt in der waagerechten Mauer bei (5,4)")
	# Karte ist loesbar: Gruppe kommt nur durch das Tor auf die Gegnerseite; ohne Tor nicht
	var g := Grid.new(m["rows"])
	var w := World.new(m["objects"])
	g.blocked = w.blocked()
	var start := Vector2i(m["players"][0]["pos"][0], m["players"][0]["pos"][1])
	var foe := Vector2i(m["enemies"][0]["pos"][0], m["enemies"][0]["pos"][1])
	check(start.y > 4 and foe.y < 4, "Helden unten (unter der Mauer), Gegner oben")
	check(not g.reachable(start, 80).has(foe), "Mit geschlossenem Tor: Gegnerseite fuer Fussvolk nicht erreichbar")
	var gate := w.by_id("gate1")
	check(World.attackable(gate), "Das Tor laesst sich mit normalen Angriffen aufbrechen (Sicherheitsnetz fuer jede Gruppe)")
	w.apply(gate, "break")
	g.blocked = w.blocked()
	check(g.reachable(start, 80).has(foe), "Mit zerstoertem Tor: Gegnerseite erreichbar")

	# Kanone sprengt eine Mauer
	var s := scene([["elisabeth", [3, 6]]])
	var eli: Dictionary = s[0]
	var wall := b.world.at(Vector2i(3, 4))
	check(b._obj_targets(eli, "kanone", eli["pos"]).has(wall), "Kanone: Mauer auf Entfernung 2 ist Ziel")
	check(not b._obj_targets(eli, "kanone", Vector2i(1, 9)).has(wall), "Kanone: zu weit entfernt kein Ziel")
	var free: bool = await b._use_on_object(eli, "kanone", wall)
	check(wall["state"] == "broken" and not b.grid.blocked.has(Vector2i(3, 4)) and b.grid.cost(Vector2i(3, 4)) >= 0, "Mauer gesprengt, Feld frei")
	check(not free and eli["cd"]["kanone"] == 3, "Kanone verbraucht die Aktion, Abklingzeit gesetzt")

	# Laser schmilzt das Tor (nur auf gerader Linie), Ausloeser spielt den Dialog
	s = scene([["robo", [5, 6]], ["maedchen_baer", [3, 6]]])
	var robo: Dictionary = s[0]
	var gt := b.world.at(Vector2i(5, 4))
	check(b._obj_targets(robo, "roter_laser", robo["pos"]).has(gt), "Laser: Tor auf der Linie ist Ziel")
	check(not b._obj_targets(robo, "roter_laser", Vector2i(4, 6)).has(gt), "Laser: nicht auf gerader Linie kein Ziel")
	check(b._obj_targets(robo, "roter_laser", robo["pos"]).size() == 1, "Laser hilft nur gegen das Tor, nicht gegen Mauern")
	await b._use_on_object(robo, "roter_laser", gt)
	check(gt["state"] == "open" and not b.grid.blocked.has(Vector2i(5, 4)), "Tor offen")
	check(talk.size() == 1 and talk[0][0]["speaker"] == "kungfu", "Ausloeser: Dialog bei offenem Tor")

	# Pranke bricht das Tor, anderer Dialog
	s = scene([["maedchen_baer", [5, 5]]])
	var mira: Dictionary = s[0]
	gt = b.world.at(Vector2i(5, 4))
	check(b._obj_targets(mira, "baerenpranke", mira["pos"]).has(gt), "Pranke: angrenzendes Tor ist Ziel")
	await b._use_on_object(mira, "baerenpranke", gt)
	check(gt["state"] == "broken" and talk.size() == 1 and talk[0][0]["speaker"] == "museklaugust", "Tor zerbrochen, passender Dialog")

	# Stabsprung ueber die Mauer: Landefeld muss frei sein
	s = scene([["kungfu", [3, 5]]])
	var lin: Dictionary = s[0]
	var wl := b.world.at(Vector2i(3, 4))
	check(b._obj_targets(lin, "stabsprung", lin["pos"]).has(wl), "Sprung: Mauer mit freiem Landefeld ist Ziel")
	b._spawn("soldat_infanterie", "e", Vector2i(3, 3))
	check(not b._obj_targets(lin, "stabsprung", lin["pos"]).has(wl), "Sprung: besetztes Landefeld, kein Ziel")
	b.units.pop_back().get("node").queue_free()
	var is_free: bool = await b._use_on_object(lin, "stabsprung", wl)
	check(lin["pos"] == Vector2i(3, 3) and wl["state"] == "intact" and is_free, "Lin steht hinter der Mauer, Mauer bleibt, Aktion nicht verbraucht")
	check(lin["cd"]["stabsprung"] == 2, "Stabsprung: Abklingzeit 2")

	# Wurf auf Verbuendete: ueber die Mauer, Landefeld frei und bis 4 Felder weit
	s = scene([["museklaugust", [3, 5]], ["maedchen_baer", [2, 5]]])
	var mus: Dictionary = s[0]
	var ally: Dictionary = s[1]
	check(b._ab_targets(mus, "wurf", mus["pos"]).has(ally), "Wurf: Verbuendeter ist waehlbar")
	b.sel = mus
	b._cur_ab = "wurf"
	b._begin_landing(ally)
	check(b._landing_tiles.has(Vector2i(2, 2)) and b._landing_tiles.has(Vector2i(3, 3)) and not b._landing_tiles.has(Vector2i(2, 4)) and not b._landing_tiles.has(Vector2i(2, 0)), "Landefelder: frei, bis 4 weit, nicht auf der Mauer")
	b.state = Battle.State.TARGETING
	await b._do_throw_ally(Vector2i(2, 2))
	check(ally["pos"] == Vector2i(2, 2) and ally["hp"] == ally["maxhp"] and not Status.has(ally, "stun"), "Mira ueber die Mauer geworfen, unverletzt")
	check(mus["cd"]["wurf"] == 4 and mus["done"], "Wurf: Abklingzeit, Muskelaugust fertig")
	# Feinde werfen funktioniert weiter
	s = scene([["museklaugust", [3, 5]]], [["soldat_infanterie", [3, 6]]])
	check(b._ab_targets(s[0], "wurf", s[0]["pos"]).size() == 1, "Wurf: Gegner bleibt Ziel")

	# Schalter: Held steht darauf, legt um, Tor oeffnet sich
	s = scene([["kungfu", [1, 1]]])
	var sw := b.world.at(Vector2i(1, 1))
	await b._use_switch(s[0], sw)
	check(sw["state"] == "on" and b.world.by_id("gate1")["state"] == "open" and not b.grid.blocked.has(Vector2i(5, 4)), "Schalter: Tor offen")
	check(talk.size() == 1, "Schalter loest den Tor-Dialog aus")
	# Knochenwurf trifft den Schalter aus der Ferne
	s = scene([["hund", [1, 3]]])
	check(b._obj_targets(s[0], "knochenwurf", s[0]["pos"]).has(b.world.at(Vector2i(1, 1))), "Knochenwurf: Schalter auf Entfernung 2 ist Ziel")

	# Normaler Angriff auf das Tor
	s = scene([["maedchen_baer", [5, 5]]])
	gt = b.world.at(Vector2i(5, 4))
	check(b._attack_objs(s[0], s[0]["pos"]).has(gt) and b._attack_objs(s[0], Vector2i(2, 8)).is_empty(), "Angriff: Tor in Reichweite waehlbar, sonst nicht")
	await b._attack_object(s[0], gt)
	check(gt["hp"] == 32 and gt["state"] == "closed", "Mira (ATK 7 - 3) macht 4 Schaden: 36 -> 32")
	gt["hp"] = 3
	await b._attack_object(s[0], gt)
	check(gt["state"] == "broken" and not b.grid.blocked.has(Vector2i(5, 4)), "Tor zerbricht bei 0 Leben")
	check(b._attack_objs(s[0], s[0]["pos"]).is_empty(), "Zerstoertes Tor ist kein Ziel mehr")

	# Flieger und Fussvolk an der Mauer
	s = scene([["bienenmaedchen", [4, 5]], ["maedchen_baer", [3, 5]]])
	var fly := b.grid.reachable(s[0]["pos"], 5, true)
	var walk := b.grid.reachable(s[1]["pos"], 8, false)
	check(fly.has(Vector2i(4, 3)) and not walk.has(Vector2i(3, 3)), "Flieger ueber die Mauer, Fussvolk nicht")

	# Tor von innen: wer auf das Feld hinter dem Tor (5,3) kommt, oeffnet es automatisch (mit Dialog, ohne Extra-Aktion)
	s = scene([["maedchen_baer", [5, 2]]])
	var inner: Dictionary = s[0]
	gt = b.world.at(Vector2i(5, 4))
	await b._run_triggers("enter", Vector2i(5, 5), inner)
	check(gt["state"] == "closed" and talk.is_empty(), "Vor dem Tor (5,5) betreten: Tor bleibt zu")
	await b._run_triggers("enter", Vector2i(5, 3), inner)
	check(gt["state"] == "open" and not b.grid.blocked.has(Vector2i(5, 4)), "Hinter dem Tor (5,3) betreten: Tor oeffnet sich automatisch")
	check(talk.size() == 1 and talk[0][0]["speaker"] == "maedchen_baer" and talk[0][0]["left"] == "maedchen_baer" and "Brumm" in talk[0][0]["text"], "Dialog mit der ausloesenden Figur und ihrem eigenen Text")
	check(not inner["done"], "Keine Extra-Aktion verbraucht: die Figur kann weiter handeln")
	await b._run_triggers("enter", Vector2i(5, 3), inner)
	check(talk.size() == 1, "Zweites Betreten: nichts mehr (Tor ist schon offen)")
	# Standardtext fuer Figuren ohne eigene Zeile
	s = scene([["hund", [5, 2]]])
	await b._run_triggers("enter", Vector2i(5, 3), s[0])
	check(talk.size() == 1 and "allein im Regen" in talk[0][0]["text"] and talk[0][0]["speaker"] == "hund", "Standardzeile fuer andere Figuren")
	# Tor schon offen (z. B. per Laser): Ausloeser bleibt unverbraucht und spielt nichts ab
	s = scene([["hund", [5, 2]]])
	b.world.apply(b.world.by_id("gate1"), "open")
	b.grid.blocked = b.world.blocked()
	await b._run_triggers("enter", Vector2i(5, 3), s[0])
	check(talk.is_empty(), "Tor schon offen: kein Dialog")
	check(not b.triggers[0].get("fired", false), "Ausloeser bleibt fuer spaeter erhalten")
	# Sprung ueber das Tor landet auf (5,3) und oeffnet es gleich
	s = scene([["kungfu", [5, 5]]])
	gt = b.world.at(Vector2i(5, 4))
	check(b._obj_targets(s[0], "stabsprung", s[0]["pos"]).has(gt), "Sprung ueber das geschlossene Tor ist moeglich")
	await b._use_on_object(s[0], "stabsprung", gt)
	check(s[0]["pos"] == Vector2i(5, 3) and gt["state"] == "open" and talk.size() == 1 and talk[0][0]["speaker"] == "kungfu", "Lin landet hinter dem Tor: Tor geht auf, Lin spricht")
