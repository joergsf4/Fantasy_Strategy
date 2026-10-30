extends SceneTree
## godot --headless --path game --script tests/test_sim.gd
## Paritaet: derselbe Aufbau, einmal im echten Battle und einmal im SimBattle, muss dieselben Lebenspunkte,
## Positionen und Status ergeben. So bleibt die Simulation eine verlaessliche Grundlage fuers Balancing.

var fails := 0
var b: Battle
var map: Dictionary
var defs: Dictionary


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	map = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	b.setup(map, defs)
	root.add_child(b)
	await process_frame
	await run_tests()
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func clear_battle() -> void:
	for u in b.units + b._away:
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b.state = Battle.State.IDLE


## Baut dieselbe Aufstellung in beiden Welten. spec: [[id, team, [x, y], {hp:, status:[...]}], ...]
func build(spec: Array) -> Array:
	clear_battle()
	var s := SimBattle.new(map["rows"], 5)
	var pair: Array = []
	for e: Array in spec:
		var pos := Vector2i(e[2][0], e[2][1])
		b._spawn(e[0], e[1], pos)
		var bu: Dictionary = b.units.back()
		b._face_step(bu, Vector2i.RIGHT if e[1] == "p" else Vector2i.LEFT)
		var su := s.spawn(e[0], e[1], pos)
		if e.size() > 3:
			for w in [bu, su]:
				if e[3].has("hp"):
					w["hp"] = e[3]["hp"]
				for st: String in e[3].get("status", []):
					Status.add(w, st, 3)
		pair.append([bu, su])
	return [s, pair]


func same(label: String, pair: Array, sim: SimBattle) -> void:
	for p: Array in pair:
		var bu: Dictionary = p[0]
		var su: Dictionary = p[1]
		var alive_b: bool = b.units.has(bu)
		var alive_s: bool = sim.units.has(su)
		check(alive_b == alive_s, "%s: %s lebt (Spiel %s, Sim %s)" % [label, su["id"], alive_b, alive_s])
		if alive_b and alive_s:
			check(bu["hp"] == su["hp"], "%s: %s HP Spiel %d, Sim %d" % [label, su["id"], bu["hp"], su["hp"]])
			check(bu["pos"] == su["pos"], "%s: %s Position Spiel %s, Sim %s" % [label, su["id"], bu["pos"], su["pos"]])
			var sb: Array = []
			var ss: Array = []
			for x: Dictionary in bu["status"]:
				sb.append(x["id"] + str(x["turns"]))
			for x: Dictionary in su["status"]:
				ss.append(x["id"] + str(x["turns"]))
			sb.sort()
			ss.sort()
			check(sb == ss, "%s: %s Status Spiel %s, Sim %s" % [label, su["id"], sb, ss])


func ability_case(label: String, ab: String, spec: Array, actor: int, target: int) -> void:
	var r := build(spec)
	var s: SimBattle = r[0]
	var pair: Array = r[1]
	await b._run_ability(pair[actor][0], ab, pair[target][0])
	s.run_ability(pair[actor][1], ab, pair[target][1])
	same(label, pair, s)


func run_tests() -> void:
	var inf := "soldat_infanterie"
	await ability_case("Baerenpranke", "baerenpranke", [["maedchen_baer", "p", [4, 7]], [inf, "e", [5, 7]]], 0, 1)
	await ability_case("Giftstachel", "giftstachel", [["bienenmaedchen", "p", [3, 7]], [inf, "e", [5, 7]]], 0, 1)
	await ability_case("Todeswirbel", "todeswirbel", [["samurai", "p", [5, 7]], [inf, "e", [6, 7]], [inf, "e", [5, 6]], ["soldat_beritten", "e", [5, 8]]], 0, 0)
	await ability_case("Kanone", "kanone", [["elisabeth", "p", [3, 7]], [inf, "e", [6, 7]], [inf, "e", [7, 7]], ["soldat_beritten", "e", [6, 6]]], 0, 1)
	await ability_case("Roter Laser", "roter_laser", [["robo", "p", [3, 7]], ["kungfu", "p", [4, 7]], [inf, "e", [5, 7]], ["soldat_beritten", "e", [6, 7]]], 0, 2)
	await ability_case("Gruppenheilung", "gruppenheilung", [["wendy", "p", [4, 7]], ["ritter", "p", [5, 7], {"hp": 16}], ["kungfu", "p", [5, 6], {"hp": 8, "status": ["poison"]}], ["samurai", "p", [6, 7], {"hp": 10}]], 0, 1)
	await ability_case("Knochenwurf", "knochenwurf", [["hund", "p", [4, 7]], [inf, "e", [6, 7]]], 0, 1)
	await ability_case("Stabsprung", "stabsprung", [["kungfu", "p", [4, 7]], [inf, "e", [5, 7]]], 0, 1)
	await ability_case("Fasswurf", "fasswurf", [["braumeisterin", "p", [3, 7]], [inf, "e", [6, 7]]], 0, 1)
	await ability_case("Schlachtruf", "schlachtruf", [["ritter", "p", [4, 7]], ["kungfu", "p", [3, 7]], ["wendy", "p", [8, 8]]], 0, 0)
	await ability_case("Verspotten", "verspotten", [["ritter", "p", [4, 7]], [inf, "e", [6, 7]], [inf, "e", [9, 7]]], 0, 0)
	await ability_case("Gruener Laser", "gruener_laser", [["robo", "p", [3, 7]], ["ritter", "p", [5, 7], {"hp": 14, "status": ["poison"]}]], 0, 1)
	await ability_case("Versteck", "versteck", [["ninjas", "p", [5, 7]], [inf, "e", [7, 7]]], 0, 0)
	await ability_case("Polymorph", "polymorph", [["claude", "p", [3, 7]], [inf, "e", [6, 7]]], 0, 1)

	# Normaler Angriff samt Gegenschlag, Ruecken-/Flankenbonus, Sturmangriff, Deckung (Wald)
	var r := build([["ritter", "p", [4, 7]], [inf, "e", [5, 7]]])
	await b._resolve(r[1][0][0], r[1][1][0])
	(r[0] as SimBattle).attack(r[1][0][1], r[1][1][1])
	same("Angriff mit Gegenschlag", r[1], r[0])
	r = build([["samurai", "p", [3, 7]], [inf, "e", [4, 7]]])
	b._face_step(r[1][1][0], Vector2i.RIGHT)
	(r[1][1][1] as Dictionary)["dir"] = Vector2i.RIGHT   # Gegner schaut weg -> Ruecken
	await b._resolve(r[1][0][0], r[1][1][0])
	(r[0] as SimBattle).attack(r[1][0][1], r[1][1][1])
	same("Rueckenangriff", r[1], r[0])
	r = build([["museklaugust", "p", [2, 7]], ["soldat_infanterie", "e", [1, 7]]])
	r = build([["samurai", "p", [3, 7]], [inf, "e", [3, 6]]])
	await b._resolve(r[1][1][0], r[1][0][0])    # Gegner greift an, Takeda steht auf Wiese
	(r[0] as SimBattle).attack(r[1][1][1], r[1][0][1])
	same("Gegner greift an", r[1], r[0])
	r = build([["samurai", "p", [1, 6]], [inf, "e", [2, 6]]])   # Wald (F) auf (1,6)
	await b._resolve(r[1][1][0], r[1][0][0])
	(r[0] as SimBattle).attack(r[1][1][1], r[1][0][1])
	same("Deckung im Wald", r[1], r[0])

	# Gegenstaende: Spiel und Simulation muessen gleich rechnen
	for item_id: String in ["heiltrank", "gegengift", "aether", "rauchbombe", "bier"]:
		r = build([["ritter", "p", [4, 7], {"hp": 12, "status": ["poison"]}], ["kungfu", "p", [5, 7], {"hp": 9}], [inf, "e", [9, 3]]])
		var ritter_b: Dictionary = r[1][0][0]
		var ritter_s: Dictionary = r[1][0][1]
		ritter_b["cd"]["schlachtruf"] = 3
		ritter_s["cd"]["schlachtruf"] = 3
		b.inventory = {item_id: 2}
		(r[0] as SimBattle).inventory["p"] = {item_id: 2}
		await b._use_item(ritter_b, item_id, r[1][1][0])
		(r[0] as SimBattle).use_item(ritter_s, item_id, r[1][1][1])
		same("Gegenstand " + item_id, r[1], r[0])
		check(b.inventory[item_id] == (r[0] as SimBattle).inventory["p"][item_id], "Rucksack gleich nach " + item_id)
		check(ritter_b["cd"]["schlachtruf"] == ritter_s["cd"]["schlachtruf"], "Abklingzeit gleich nach " + item_id)
	# Aether auf sich selbst, Heiltrank auf sich selbst
	r = build([["ritter", "p", [4, 7], {"hp": 12}], [inf, "e", [9, 3]]])
	b.inventory = {"heiltrank": 1}
	(r[0] as SimBattle).inventory["p"] = {"heiltrank": 1}
	await b._use_item(r[1][0][0], "heiltrank", r[1][0][0])
	(r[0] as SimBattle).use_item(r[1][0][1], "heiltrank", r[1][0][1])
	same("Heiltrank auf sich selbst", r[1], r[0])
	# Ausruestung aus dem Loadout des Spiels gleich wie in der Simulation
	var sb := SimBattle.new(map["rows"], 5)
	var su := sb.spawn("elisabeth", "p", Vector2i(3, 7), 1.0, 1.0, ["fernrohr", "lederwams", "zauberlampe"])
	b.loadout = {"equipment": {"elisabeth": ["fernrohr", "lederwams", "zauberlampe"]}}
	clear_battle()
	b._spawn("elisabeth", "p", Vector2i(3, 7))
	var bu: Dictionary = b.units.back()
	check(bu["range"] == su["range"] and bu["def"] == su["def"] and bu["maxhp"] == su["maxhp"] and bu.get("cd_bonus", 0) == su.get("cd_bonus", 0), "Ausruestung: Spiel und Sim gleich (Reichweite %d/%d, DEF %d/%d, HP %d/%d)" % [bu["range"], su["range"], bu["def"], su["def"], bu["maxhp"], su["maxhp"]])
	b.loadout = {}
	b.inventory = {}

	# Gift tickt in der eigenen Phase
	r = build([["samurai", "p", [3, 7], {"status": ["poison"]}], [inf, "e", [9, 3]]])
	await b._begin_phase("p")
	(r[0] as SimBattle).begin_phase("p")
	same("Gifttick", r[1], r[0])
	# Benommen setzt aus
	r = build([["samurai", "p", [3, 7], {"status": ["stun"]}], [inf, "e", [9, 3]]])
	await b._begin_phase("p")
	(r[0] as SimBattle).begin_phase("p")
	check(r[1][0][0]["done"] == r[1][0][1]["done"] and r[1][0][1]["done"], "Benommen: Sim und Spiel setzen aus")

	# Verteidigen: gleiche Rechnung in Spiel und Simulation (Angriff, kein Gegenschlag)
	r = build([["ritter", "p", [3, 7]], [inf, "e", [4, 7]]])
	b._face_step(r[1][1][0], Vector2i.LEFT)
	Status.add(r[1][0][0], "defend", 1)
	Status.add(r[1][0][1], "defend", 1)
	await b._resolve(r[1][1][0], r[1][0][0])
	(r[0] as SimBattle).attack(r[1][1][1], r[1][0][1])
	same("Verteidigender wird angegriffen", r[1], r[0])
	check(r[1][1][0]["hp"] == r[1][1][1]["hp"] and r[1][1][0]["hp"] == r[1][1][0]["maxhp"], "Verteidigender kontert nicht (Angreifer unverletzt)")
