class_name SimSetup
extends RefCounted
## Baut aus einer Beschreibung (spec) einen SimBattle: Karte, Aufstellung, Staerkefaktoren, KI-Parameter.
## spec = {map: "open"|"ch1", players: [{id, hp, atk}], enemies: [...], disabled: {...}, p_ai: {...}, e_ai: {...}}

const HEROES := ["maedchen_baer", "ritter", "samurai", "kungfu", "ninjas", "elisabeth", "museklaugust",
	"robo", "hund", "wendy", "claude", "bienenmaedchen", "braumeisterin"]
const SOLDIERS := ["soldat_infanterie", "soldat_beritten", "soldat_bogenschuetze", "soldat_priester"]

static var _ch1: Dictionary = {}


static var _missions: Dictionary = {}


## Karte einer Mission (ch1, ch2, ch3) samt Objekten.
static func mission_map(name: String) -> Dictionary:
	if not _missions.has(name):
		_missions[name] = Mission.load_mission(name)
	return _missions[name]


static func ch1() -> Dictionary:
	if _ch1.is_empty():
		_ch1 = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	return _ch1


## Zufaellige 12x10-Karte: Wiese mit Waldstuecken, ein bis zwei Bergen und einem See. Startzonen bleiben frei.
static func random_rows(rng: RandomNumberGenerator) -> Array:
	var w := 12
	var h := 10
	var g: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			row.append("G")
		g.append(row)
	var put := func(cx: int, cy: int, r: int, ch: String, p: float) -> void:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var x := cx + dx
				var y := cy + dy
				if absi(dx) + absi(dy) <= r and x >= 3 and x <= w - 4 and y >= 0 and y < h and rng.randf() < p:
					g[y][x] = ch
	for i in rng.randi_range(3, 6):
		put.call(rng.randi_range(3, w - 4), rng.randi_range(0, h - 1), 1, "F", 0.8)
	for i in rng.randi_range(1, 2):
		put.call(rng.randi_range(4, w - 5), rng.randi_range(1, h - 2), 1, "M", 0.55)
	put.call(rng.randi_range(4, 7), rng.randi_range(2, 7), rng.randi_range(1, 2), "W", 0.85)
	var rows: Array = []
	for y in h:
		rows.append("".join(g[y]))
	return rows


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


static func _start_tiles(b: SimBattle, x0: int, x1: int, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for y in b.grid.height:
		for x in range(x0, x1 + 1):
			var p := Vector2i(x, y)
			if b.grid.cost(p, false) >= 0:
				out.append(p)
	_shuffle(out, rng)
	return out


static func build(spec: Dictionary, seed_: int) -> SimBattle:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 2654435761 + 17
	var mname: String = spec.get("map", "open")
	var use_ch1: bool = mname in ["ch1", "ch2", "ch3", "ch5"]
	var mdata: Dictionary = mission_map(mname) if use_ch1 else {}
	var rows: Array = mdata["rows"] if use_ch1 else random_rows(rng)
	var b := SimBattle.new(rows, seed_)
	if use_ch1:
		b.setup_world(mdata.get("objects", []))
	for k: String in spec.get("disabled", {}):          # {Held: [Faehigkeiten]} -> {Held: {Faehigkeit: true}}
		var set := {}
		for a: String in spec["disabled"][k]:
			set[a] = true
		b.disabled[k] = set
	b.ai_cfg["p"] = spec.get("p_ai", {})
	b.ai_cfg["e"] = spec.get("e_ai", {})
	b.inventory["p"] = (spec.get("inventory", {}) as Dictionary).duplicate()
	var players: Array = spec["players"]
	var enemies: Array = spec["enemies"]
	if use_ch1:
		var m: Dictionary = mdata
		var pi := 0
		for e: Dictionary in m["players"]:
			var d: Dictionary = players[pi] if pi < players.size() else {}
			b.spawn(d.get("id", e["id"]), "p", Vector2i(e["pos"][0], e["pos"][1]), d.get("hp", 1.0), d.get("atk", 1.0), d.get("equip", []))
			pi += 1
		var ei := 0
		for e: Dictionary in m["enemies"]:
			var d2: Dictionary = enemies[ei] if ei < enemies.size() else {}
			var base_hp: float = float(d2.get("hp", 1.0))
			if e.has("hp"):   # Karte setzt absolute Leben (Stachelia 34): als Faktor auf die Grundwerte
				base_hp *= float(e["hp"]) / float(SimBattle.defs()[d2.get("id", e["id"])]["hp"])
			b.spawn(d2.get("id", e["id"]), "e", Vector2i(e["pos"][0], e["pos"][1]), base_hp, d2.get("atk", 1.0))
			ei += 1
		for k in range(ei, enemies.size()):   # zusaetzliche Gegner: freie Felder rechts
			var free := _start_tiles(b, b.grid.width - 4, b.grid.width - 1, rng)
			for p: Vector2i in free:
				if b.unit_at(p).is_empty():
					b.spawn(enemies[k]["id"], "e", p, enemies[k].get("hp", 1.0), enemies[k].get("atk", 1.0))
					break
		return b
	var left := _start_tiles(b, 0, 2, rng)
	var right := _start_tiles(b, b.grid.width - 3, b.grid.width - 1, rng)
	for i in players.size():
		b.spawn(players[i]["id"], "p", left[i], players[i].get("hp", 1.0), players[i].get("atk", 1.0), players[i].get("equip", []))
	for i in enemies.size():
		b.spawn(enemies[i]["id"], "e", right[i], enemies[i].get("hp", 1.0), enemies[i].get("atk", 1.0))
	return b
