class_name BotSetup
extends RefCounted
## Aufbau eines Kampfes fuer den Spieltest-Bot (PlayBot): Spielstand eines Kapitels wie in Party.for_chapter, Gruppe wie
## main.gd _mission_with_squad, dazu Varianten fuer den langen Lauf (tools/spielbarkeit.py).
##
## Variante (alle Felder optional):
##   squad: [Helden]        statt der Kartengruppe (Plaetze der Karte bleiben, nur die Figuren wechseln)
##   gear: "expected" | "none" | "best"
##   talents: {"mode": "expected" | "zero" | "atk", "delta": -1}
##   inventory: "expected" | "none"
##   nemesis: "expected" | "none" | [IDs]
##   seed: int              Zufall im Kampf (Wurfrichtung, Statuschance)

const FLASHBACK_HOST := {"rb_takeda": 3}      # Rueckblende -> Kapitel, nach dem sie spielt


static func defs() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))


## Kapitelnummer einer Mission (Rueckblende: Kapitel danach, also mit dem Aufstieg aus dem Kapitel davor).
static func chapter_no(cid: String) -> int:
	if FLASHBACK_HOST.has(cid):
		return int(FLASHBACK_HOST[cid]) + 1
	return int(cid.substr(2))


## Kampfmissionen in Spielreihenfolge (ohne Kapitel ohne Kampf), Rueckblenden direkt nach ihrem Kapitel.
static func battle_missions() -> Array:
	var out: Array = []
	var n := 1
	while FileAccess.file_exists("res://data/missions/ch%d.json" % n):
		var m := Mission.load_mission("ch%d" % n)
		if not m.get("stub", false):
			out.append("ch%d" % n)
		if m.has("flashback"):
			out.append(str(m["flashback"]))
		n += 1
	return out


## Benannte Gegner, die in den Missionen vor Kapitel n fliehen (im echten Spiel sterben sie nie): kehren spaeter zurueck.
static func expected_nemesis(defs_: Dictionary, n: int) -> Array:
	var out: Array = []
	for k in range(1, n):
		var path := "res://data/missions/ch%d.json" % k
		if not FileAccess.file_exists(path):
			continue
		var m := Mission.load_mission("ch%d" % k)
		var no_flee: Array = m.get("no_flee", [])
		var ids: Array = (m.get("enemies", []) as Array).map(func(e: Dictionary) -> String: return e["id"])
		for t: Dictionary in m.get("triggers", []):
			for step: Dictionary in t.get("do", []):
				for sp: Dictionary in step.get("spawn", []):
					if sp.get("team", "e") == "e":
						ids.append(sp["id"])
		for id: String in ids:
			if defs_.get(id, {}).get("flees", false) and not no_flee.has(id) and not out.has(id):
				out.append(id)
	return out


## Spielstand und Mission fuer cid und eine Variante. Rueckgabe {party, mission, squad}.
static func prepare(defs_: Dictionary, cid: String, variant := {}) -> Dictionary:
	var n := chapter_no(cid)
	var party := Party.for_chapter(defs_, n if not FLASHBACK_HOST.has(cid) else n - 1)
	if FLASHBACK_HOST.has(cid):      # die Rueckblende laeuft nach Kapitel n-1: mit dessen Aufstieg
		party.earned += 1
	var m := Mission.load_mission(cid)
	var ids: Array = variant.get("squad", [])
	if ids.is_empty() or m.get("fixed_squad", false):
		ids = party.squad_for(m) if not m.get("fixed_squad", false) else (m["players"] as Array).map(func(e: Dictionary) -> String: return e["id"])
	for i in mini(ids.size(), (m["players"] as Array).size()):
		m["players"][i]["id"] = ids[i]
	var tal: Dictionary = variant.get("talents", {})
	var pts := Party.points_for(party.earned) + int(tal.get("delta", 0))
	if str(tal.get("mode", "expected")) == "zero":
		pts = 0
	for id: String in defs_:
		if defs_[id].get("hero", false):
			party.talents[id] = _allocation(maxi(0, pts), str(tal.get("mode", "expected")))
	party.release_absent(ids)
	match str(variant.get("gear", "expected")):
		"none":
			party.equipment = {}
		"best":
			party.equipment = {}
			for id: String in ids:
				if defs_.has(id):
					party.equipment[id] = Progression.gear_for(defs_[id], 4.0)
		_:
			party.auto_equip(ids, defs_)
	if str(variant.get("inventory", "expected")) == "none":
		party.inventory = {}
	var nem: Variant = variant.get("nemesis", "expected")
	if nem is Array:
		party.nemesis = (nem as Array).duplicate()
	elif str(nem) == "none":
		party.nemesis = []
	else:
		party.nemesis = expected_nemesis(defs_, n)
	return {"party": party, "mission": m, "squad": ids}


## Talentverteilung: Standard (Talents.default_allocation) oder alles in den Angriff.
static func _allocation(points: int, mode: String) -> Dictionary:
	if mode == "atk":
		return {"hp": 0, "atk": points, "a1": 0, "a2": 0}
	return Talents.default_allocation(points)


## Kampf aufbauen und starten (headless, ohne Dialoge und Szenen). Mit await aufrufen.
static func build(root: Node, defs_: Dictionary, cid: String, variant := {}) -> Battle:
	var prep := prepare(defs_, cid, variant)
	var party: Party = prep["party"]
	Settings.set_value("difficulty", 1)
	Settings.set_value("enemy_speed", 0)
	var b := Battle.new()
	b.setup(prep["mission"], defs_)
	b.loadout = party.loadout()
	b.fast = true
	b.dialogue_runner = func(_lines: Array) -> void: pass
	root.add_child(b)
	var tree := Engine.get_main_loop() as SceneTree
	await tree.process_frame
	await tree.process_frame
	b.rng.seed = int(variant.get("seed", 1))
	return b
