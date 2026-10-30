class_name SimBattle
extends RefCounted
## Grafikfreie Kampfsimulation. Gleiche Regeln wie scripts/battle.gd (Combat, Status, Grid, abilities.json),
## aber ohne Szene, Tweens und Wartezeiten, damit tausende Kaempfe in Minuten laufen.
## Unterschiede zum Spiel: Hoehe = feste Tabelle je Gelaendetyp (TerrainView.H) statt Hoehenfeld,
## beide Seiten werden von SimAI gesteuert (Spott wirkt auch auf die Spielerseite).

const MAX_TURNS := 40

static var _unit_defs: Dictionary = {}
static var _ability_defs: Dictionary = {}

var grid: Grid
var units: Array[Dictionary] = []
var away: Array[Dictionary] = []          # verwandelte Einheiten (aus dem Spiel)
var everyone: Array[Dictionary] = []      # alle je gespawnten (fuer Statistik)
var rng := RandomNumberGenerator.new()
var turn := 1
var disabled: Dictionary = {}             # Einheit-ID -> {Faehigkeit-ID: true} oder {"*": true}
var ai_cfg := {"p": {}, "e": {}}
var inventory := {"p": {}, "e": {}}      # Rucksack je Team: {Gegenstand: Anzahl}
var _uid := 1
var world := World.new([])                # Weltobjekte (Feuer, Haeuser ...); leer = keine
var flammable: Dictionary = {}            # Waldfelder


static func defs() -> Dictionary:
	if _unit_defs.is_empty():
		_unit_defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	return _unit_defs


## Fuer Experimente: die Dauer von Statuseffekten einzelner Faehigkeiten setzen, z. B. {"verspotten": 3}.
static func override_status_turns(map: Dictionary) -> void:
	for id: String in map:
		for ef: Dictionary in ab_defs()[id]["effects"]:
			if ef["type"] == "status":
				ef["turns"] = int(map[id])


static func reset_defs() -> void:
	_ability_defs = {}


static func ab_defs() -> Dictionary:
	if _ability_defs.is_empty():
		_ability_defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
		for k: String in _ability_defs:
			_ability_defs[k]["id"] = k
	return _ability_defs


func _init(map_rows: Array, seed_ := 1) -> void:
	grid = Grid.new(map_rows)
	rng.seed = seed_


# ------------------------------------------------------------------ Aufbau

func setup_world(objs: Array) -> void:
	world = World.new(objs)
	grid.blocked = world.blocked()
	for y in grid.height:
		for x in grid.width:
			if grid.terrain(Vector2i(x, y)) == "F":
				flammable[Vector2i(x, y)] = true


## Feuerphase (zu Beginn der Gegnerphase), wie Battle._fire_phase.
func fire_phase() -> void:
	for o in world.objects:
		if world.is_burning(o):
			world.tick_fire(flammable)
			grid.blocked = world.blocked()
			return


func douse(u: Dictionary, o: Dictionary) -> void:
	world.apply(o, "extinguish")
	var s := _ab_stat(u, "_douse")
	s["uses"] += 1
	s["status"] += 1


## Objekte, auf die die Faehigkeit id (Marke "extinguish") von Feld pos aus wirkt.
func obj_targets(u: Dictionary, id: String, pos: Vector2i) -> Array[Dictionary]:
	var ab: Dictionary = ab_defs()[id]
	var out: Array[Dictionary] = []
	if not (ab.get("caps", []) as Array).has("extinguish") or ab["target"] == "self":
		return out
	var r: Array = ab["range"]
	for o in world.objects:
		var d := Grid.dist(pos, o["pos"])
		if world.is_burning(o) and d >= r[0] and d <= r[1]:
			out.append(o)
	return out


func extinguish_ability(u: Dictionary, id: String, o: Dictionary) -> void:
	var ab: Dictionary = ab_defs()[id]
	u["cd"][id] = Items.cooldown_for(u, int(ab["cd"]))
	var s := _ab_stat(u, id)
	s["uses"] += 1
	for other in world.objects:
		if world.is_burning(other) and Grid.dist(other["pos"], o["pos"]) <= 1:
			world.apply(other, "extinguish")
			s["status"] += 1


func spawn(id: String, team: String, pos: Vector2i, hp_mult := 1.0, atk_mult := 1.0, equip: Array = []) -> Dictionary:
	var d: Dictionary = defs()[id]
	var hp := maxi(1, roundi(float(d["hp"]) * hp_mult))
	var u := {
		"id": id, "name": d["name"], "team": team, "pos": pos,
		"hp": hp, "maxhp": hp, "atk": maxi(1, roundi(float(d["atk"]) * atk_mult)),
		"def": int(d["def"]), "res": int(d.get("res", 0)),
		"move": int(d["move"]), "range": int(d["range"]), "range_min": int(d.get("range_min", 1)),
		"dmg_type": d.get("dmg_type", "body"), "role": d.get("role", ""), "tags": d.get("tags", []),
		"abilities": d.get("abilities", []), "passives": d.get("passives", []),
		"ranged_mult": float(d.get("ranged_mult", 1.0)), "flying": d.get("flying", false),
		"heal": int(d.get("heal", 0)), "done": false, "status": [], "cd": {},
		"dir": Vector2i.RIGHT if team == "p" else Vector2i.LEFT,
		"uid": str(_uid), "charge": 0,
		"st": {"dealt": 0, "taken": 0, "healed": 0, "kills": 0, "ab": {}},
	}
	_uid += 1
	if not equip.is_empty():
		Items.apply_equipment(u, equip)
	units.append(u)
	everyone.append(u)
	return u


# ------------------------------------------------------------------ Hilfen

func height(p: Vector2i) -> float:
	return TerrainView.H[grid.terrain(p)]


func unit_at(p: Vector2i) -> Dictionary:
	for u in units:
		if u["pos"] == p:
			return u
	return {}


func team_tiles(team: String) -> Dictionary:
	var d := {}
	for u in units:
		if u["team"] == team:
			d[u["pos"]] = true
	return d


func tile_free(p: Vector2i, mover: Dictionary) -> bool:
	return grid.inside(p) and unit_at(p).is_empty() and grid.cost(p, mover["flying"]) >= 0


func foes_of(u: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in units:
		if o["team"] != u["team"]:
			out.append(o)
	return out


func visible_foes(u: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in units:
		if o["team"] != u["team"] and not Status.has(o, "stealth"):
			out.append(o)
	return out


func friends_of(u: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in units:
		if o["team"] == u["team"] and o != u:
			out.append(o)
	return out


func taunter(u: Dictionary) -> Dictionary:
	var st := Status.get_status(u, "taunt")
	if st.is_empty():
		return {}
	for o in units:
		if o["uid"] == st["src"]:
			return o
	return {}


func turn_towards(u: Dictionary, target: Vector2i) -> void:
	var d: Vector2i = target - u["pos"]
	if d == Vector2i.ZERO:
		return
	if absi(d.x) >= absi(d.y):
		u["dir"] = Vector2i(signi(d.x), 0)
	else:
		u["dir"] = Vector2i(0, signi(d.y))


func cover_for(u: Dictionary, pos: Vector2i) -> int:
	var c := grid.def_bonus(pos)
	if (u["passives"] as Array).has("schildwall"):
		for o in units:
			if o != u and o["team"] == u["team"] and (o["passives"] as Array).has("schildwall") and Grid.dist(o["pos"], pos) == 1:
				c += 1
				break
	return c


func ready_abilities(u: Dictionary) -> Array:
	var out := []
	var dis: Dictionary = disabled.get(u["id"], {})
	if dis.has("*"):
		return out
	for id: String in u["abilities"]:
		if not dis.has(id) and int(u["cd"].get(id, 0)) <= 0:
			out.append(id)
	return out


## Wo kann die Einheit hinziehen? {Vector2i: Kosten}, ohne belegte Felder (eigenes Feld bleibt).
func reach_tiles(u: Dictionary) -> Dictionary:
	var foe_team := "e" if u["team"] == "p" else "p"
	var reach := grid.reachable(u["pos"], u["move"], u["flying"], team_tiles(foe_team))
	for o in units:
		if o != u:
			reach.erase(o["pos"])
	reach[u["pos"]] = 0
	return reach


# ------------------------------------------------------------------ Schaden und Vorschau

func forecast(att: Dictionary, def: Dictionary, att_pos := Vector2i(-99, -99), mult := 1.0, ignore_def := 0.0) -> Dictionary:
	var pos: Vector2i = att["pos"] if att_pos == Vector2i(-99, -99) else att_pos
	var dist := Grid.dist(pos, def["pos"])
	var pb := Combat.position_bonus(pos, def["pos"], def["dir"], height(pos), height(def["pos"]), Status.has(att, "stealth"))
	var flat: int = att["charge"] if (att["passives"] as Array).has("sturmangriff") and mult == 1.0 else 0
	var dmg := Combat.damage(att, def, cover_for(def, def["pos"]), pb["bonus"], mult * Combat.range_mult(att, dist), ignore_def, flat)
	var counter := -1
	if def["hp"] - dmg > 0 and Combat.can_counter(def, dist):
		var cpb := Combat.position_bonus(def["pos"], pos, att["dir"], height(def["pos"]), height(pos))
		counter = Combat.damage(def, att, cover_for(att, pos), cpb["bonus"], Combat.range_mult(def, dist))
	return {"dmg": dmg, "tags": pb["tags"], "counter": counter, "kill": def["hp"] <= dmg}


func _credit(att: Dictionary, def: Dictionary, dmg: int, tag: String) -> void:
	att["st"]["dealt"] += dmg
	def["st"]["taken"] += dmg
	_ab_stat(att, tag)["dmg"] += dmg


func _ab_stat(u: Dictionary, tag: String) -> Dictionary:
	var m: Dictionary = u["st"]["ab"]
	if not m.has(tag):
		m[tag] = {"uses": 0, "dmg": 0, "heal": 0, "status": 0, "kills": 0}
	return m[tag]


func _kill(by: Dictionary, def: Dictionary, tag: String) -> void:
	units.erase(def)
	away.erase(def)
	if not by.is_empty():
		by["st"]["kills"] += 1
		_ab_stat(by, tag)["kills"] += 1


## Ein Treffer samt Statistik. turn_faces = beide drehen sich zueinander (normaler Angriff).
func strike(att: Dictionary, def: Dictionary, mult := 1.0, ignore_def := 0.0, turn_faces := true, tag := "_attack") -> int:
	var fc := forecast(att, def, att["pos"], mult, ignore_def)
	var dmg: int = mini(fc["dmg"], def["hp"])
	def["hp"] -= dmg
	Status.remove(att, "stealth")
	if turn_faces:
		turn_towards(att, def["pos"])
		turn_towards(def, att["pos"])
	_credit(att, def, dmg, tag)
	if def["hp"] <= 0:
		_kill(att, def, tag)
	return dmg


# ------------------------------------------------------------------ Aktionen

func move_to(u: Dictionary, goal: Vector2i) -> void:
	u["charge"] = 0
	if goal == u["pos"]:
		return
	var foe_team := "e" if u["team"] == "p" else "p"
	var full := grid.reachable(u["pos"], u["move"], u["flying"], team_tiles(foe_team))
	var path := grid.path_to(u["pos"], goal, full, u["flying"])
	var run := 0
	var last := Vector2i.ZERO
	for i in range(1, path.size()):
		var d: Vector2i = path[i] - path[i - 1]
		run = run + 1 if d == last else 1
		last = d
	u["charge"] = mini(run, 3)
	if path.size() > 1:
		var dd: Vector2i = path[path.size() - 1] - path[path.size() - 2]
		u["dir"] = Vector2i(signi(dd.x), signi(dd.y))
	u["pos"] = goal


func attack(u: Dictionary, target: Dictionary) -> void:
	_ab_stat(u, "_attack")["uses"] += 1
	strike(u, target, 1.0, 0.0, true, "_attack")
	var dist := Grid.dist(u["pos"], target["pos"])
	if target["hp"] > 0 and Combat.can_counter(target, dist):
		strike(target, u, 1.0, 0.0, true, "_counter")


func defend(u: Dictionary) -> void:
	Status.add(u, "defend", 1)
	_ab_stat(u, "_defend")["uses"] += 1


func heal_basic(u: Dictionary, target: Dictionary) -> void:
	var amount := mini(u["heal"], target["maxhp"] - target["hp"])
	target["hp"] += amount
	var cured := Status.cleanse(target)
	u["st"]["healed"] += amount
	var s := _ab_stat(u, "_heal")
	s["uses"] += 1
	s["heal"] += amount
	if cured:
		s["status"] += 1


## Gegenstand aus dem Rucksack des Teams benutzen (kostet die Aktion).
func use_item(u: Dictionary, id: String, target: Dictionary) -> void:
	var inv: Dictionary = inventory[u["team"]]
	inv[id] = int(inv.get(id, 0)) - 1
	if target != u:
		turn_towards(u, target["pos"])
	var mine := units.filter(func(o: Dictionary) -> bool: return o["team"] == u["team"])
	var res := Items.apply_item(id, target, mine)
	u["st"]["healed"] += res["heal"]
	var st := _ab_stat(u, "item:" + id)
	st["uses"] += 1
	st["heal"] += res["heal"]
	st["status"] += res["cured"] + res["status"]


func first_effect(ab: Dictionary, type: String) -> Dictionary:
	for ef: Dictionary in ab["effects"]:
		if ef["type"] == type:
			return ef
	return {}


## Gueltige Ziele einer Faehigkeit von Feld pos aus (wie Battle._ab_targets).
func ab_targets(u: Dictionary, id: String, pos: Vector2i) -> Array[Dictionary]:
	var ab: Dictionary = ab_defs()[id]
	var out: Array[Dictionary] = []
	if ab["target"] == "self":
		out.append(u)
		return out
	var r: Array = ab["range"]
	for o in units:
		var dd := Grid.dist(pos, o["pos"])
		if dd < r[0] or dd > r[1]:
			continue
		if ab["target"] == "enemy":
			if o["team"] == u["team"] or Status.has(o, "stealth"):
				continue
			if ab.has("require_tag") and not (o["tags"] as Array).has(ab["require_tag"]):
				continue
			if ab.get("shape", "") == "line" and o["pos"].x != pos.x and o["pos"].y != pos.y:
				continue
			if not first_effect(ab, "jump").is_empty():
				var land: Vector2i = o["pos"] + (o["pos"] - pos)
				if not tile_free(land, u):
					continue
			out.append(o)
		else:
			if o["team"] != u["team"] or (o == u and ab["target"] == "ally"):
				continue
			if ab["target"] == "ally" and not first_effect(ab, "heal").is_empty() \
					and not (o["hp"] < o["maxhp"] or Status.has(o, "poison")):
				continue
			out.append(o)
	return out


func area_tiles(ab: Dictionary, center: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a: Dictionary = ab.get("area", {})
	if a.is_empty():
		return out
	var r: int = int(a.get("r", 1))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var p := center + Vector2i(dx, dy)
			if not grid.inside(p):
				continue
			if a["shape"] == "radius" and absi(dx) + absi(dy) <= r:
				out.append(p)
			elif a["shape"] == "ring8" and maxi(absi(dx), absi(dy)) == 1:
				out.append(p)
	return out


## Wen trifft ein Effekt? pos = Standort des Wirkenden (kann vom echten Feld abweichen, z. B. bei der KI-Bewertung).
func effect_victims(u: Dictionary, ab: Dictionary, target: Dictionary, to: String, pos: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match to:
		"target":
			if units.has(target):
				out.append(target)
		"self":
			out.append(u)
		"line_enemies":
			var d := Vector2i(signi(target["pos"].x - pos.x), signi(target["pos"].y - pos.y))
			for k in range(1, int(ab["range"][1]) + 1):
				var o := unit_at(pos + d * k)
				if not o.is_empty() and o["team"] != u["team"] and not Status.has(o, "stealth"):
					out.append(o)
		"area_enemies", "area_allies":
			var center: Vector2i = pos if ab["target"] == "self" else target["pos"]
			var tiles := area_tiles(ab, center)
			for o in units:
				if not tiles.has(o["pos"]):
					continue
				var enemy: bool = o["team"] != u["team"]
				if (to == "area_enemies" and enemy and not Status.has(o, "stealth")) or (to == "area_allies" and not enemy):
					out.append(o)
	return out


func run_ability(u: Dictionary, id: String, target: Dictionary) -> void:
	var ab: Dictionary = ab_defs()[id]
	u["cd"][id] = Items.cooldown_for(u, int(ab["cd"]))
	_ab_stat(u, id)["uses"] += 1
	if target != u:
		turn_towards(u, target["pos"])
	for ef: Dictionary in ab["effects"]:
		if not units.has(u):
			break
		_apply_effect(u, ab, target, ef)


func _apply_effect(u: Dictionary, ab: Dictionary, target: Dictionary, ef: Dictionary) -> void:
	var id: String = ab["id"]
	var victims := effect_victims(u, ab, target, ef.get("to", "target"), u["pos"])
	match ef["type"]:
		"damage":
			for v in victims:
				for h in int(ef.get("hits", 1)):
					if not units.has(v):
						break
					strike(u, v, ef["mult"], ef.get("ignore_def", 0.0), false, id)
		"splash":
			var near := units.filter(func(o: Dictionary) -> bool:
				return o["team"] != u["team"] and o != target and Grid.dist(o["pos"], target["pos"]) == 1)
			for v in near:
				strike(u, v, ef["mult"], 0.0, false, id)
		"status":
			for v in victims:
				var src: String = u["uid"] if ef["id"] == "taunt" else ""
				Status.add(v, ef["id"], int(ef["turns"]), ef.get("mods", {}), src)
				_ab_stat(u, id)["status"] += 1
		"heal":
			for v in victims:
				var amount := mini(int(ef["amount"]), v["maxhp"] - v["hp"])
				v["hp"] += amount
				if ef.get("cleanse", false) and Status.cleanse(v):
					_ab_stat(u, id)["status"] += 1
				u["st"]["healed"] += amount
				_ab_stat(u, id)["heal"] += amount
		"jump":
			if units.has(target):
				u["pos"] = target["pos"] + (target["pos"] - u["pos"])
				turn_towards(u, target["pos"])
		"throw":
			if units.has(target):
				_throw(u, target, ef, id)
		"polymorph":
			if units.has(target):
				Status.add(target, "polymorph", int(ef["turns"]))
				units.erase(target)
				away.append(target)
				_ab_stat(u, id)["status"] += 1


func _throw(u: Dictionary, target: Dictionary, ef: Dictionary, id: String) -> void:
	var opts: Array[Vector2i] = []
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		for steps in range(int(ef["dist"]), 0, -1):    # weitester gueltiger Landepunkt, die Flugbahn ist egal
			var p: Vector2i = target["pos"] + d * steps
			if tile_free(p, target):
				opts.append(p)
				break
	if not opts.is_empty():
		target["pos"] = opts[rng.randi() % opts.size()]
	var dmg := mini(Combat.damage(u, target, cover_for(target, target["pos"]), 0.0, ef["mult"]), target["hp"])
	target["hp"] -= dmg
	_credit(u, target, dmg, id)
	if target["hp"] <= 0:
		_kill(u, target, id)
	else:
		Status.add(target, "stun", int(ef["stun"]))
		_ab_stat(u, id)["status"] += 1


# ------------------------------------------------------------------ Phasen

func free_tile_near(p: Vector2i, mover: Dictionary) -> Vector2i:
	var seen := {p: true}
	var queue: Array[Vector2i] = [p]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if tile_free(cur, mover):
			return cur
		for d in Grid.DIRS:
			var n: Vector2i = cur + d
			if grid.inside(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	return p


func begin_phase(team: String) -> void:
	for u in (units + away):
		if u["team"] != team:
			continue
		u["done"] = false
		u["charge"] = 0
		var stunned := Status.has(u, "stun")
		for ev: Dictionary in Status.tick_phase_start(u):
			if ev["type"] == "poison":
				var dmg := mini(int(ev["amount"]), u["hp"])
				u["hp"] -= dmg
				u["st"]["taken"] += dmg
				if u["hp"] <= 0:
					units.erase(u)
					away.erase(u)
					break
			elif ev["type"] == "expire" and ev["id"] == "polymorph":
				away.erase(u)
				u["pos"] = free_tile_near(u["pos"], u)
				units.append(u)
		if units.has(u) and not u["flying"] and world.burning_tiles().has(u["pos"]):
			var fd := mini(Battle.FIRE_DAMAGE, u["hp"])
			u["hp"] -= fd
			u["st"]["taken"] += fd
			if u["hp"] <= 0:
				units.erase(u)
				continue
		if units.has(u) and stunned:
			u["done"] = true


func winner() -> String:
	var p := 0
	var e := 0
	for u in units + away:
		if u["team"] == "p":
			p += 1
		else:
			e += 1
	if e == 0:
		return "p"
	if p == 0:
		return "e"
	return ""


## Reihenfolge: Unterstuetzer (Buff/Spott/Versteck) zuerst, dann zufaellig.
func _order(team: String) -> Array[Dictionary]:
	var first: Array[Dictionary] = []
	var rest: Array[Dictionary] = []
	for u in units:
		if u["team"] != team:
			continue
		var support := false
		for id: String in u["abilities"]:
			for ef: Dictionary in ab_defs()[id]["effects"]:
				if ef["type"] == "status" and (ef["id"] in ["buff", "taunt", "stealth"]) and ab_defs()[id]["target"] == "self":
					support = true
		(first if support else rest).append(u)
	for i in range(rest.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := rest[i]
		rest[i] = rest[j]
		rest[j] = tmp
	return first + rest


func act_phase(team: String) -> void:
	for u in _order(team):
		if not units.has(u) or u["done"]:
			continue
		SimAI.take_turn(self, u)
		u["done"] = true
		if winner() != "":
			return


## Spielt bis ein Team gewonnen hat ("p", "e") oder MAX_TURNS erreicht sind ("timeout").
func play(max_turns := MAX_TURNS) -> String:
	var first := true
	while turn <= max_turns:
		if not first:
			begin_phase("p")
			if winner() != "":
				return winner()
		first = false
		act_phase("p")
		if winner() != "":
			return winner()
		begin_phase("e")
		if winner() != "":
			return winner()
		fire_phase()
		act_phase("e")
		if winner() != "":
			return winner()
		turn += 1
	return "timeout"


func result(w: String) -> Dictionary:
	var rows := []
	for u in everyone:
		rows.append({
			"id": u["id"], "team": u["team"], "alive": u["hp"] > 0, "hp": u["hp"] / float(u["maxhp"]),
			"dealt": u["st"]["dealt"], "taken": u["st"]["taken"], "healed": u["st"]["healed"],
			"kills": u["st"]["kills"], "ab": u["st"]["ab"],
		})
	return {"winner": w, "turns": turn, "units": rows, "houses_lost": world.houses_lost(), "houses_total": world.objects.filter(func(o: Dictionary) -> bool: return o["type"] == "house").size()}
