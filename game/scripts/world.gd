class_name World
extends RefCounted
## Weltobjekte einer Mission: Mauer, Tor, Schalter. Reine Logik ohne Szene (testbar).
## Faehigkeiten wirken ueber Marken ("caps", in abilities.json) auf Objekte; Typen und Loesungen in data/objects.json.

static var _defs: Dictionary = {}

var objects: Array[Dictionary] = []


static func defs() -> Dictionary:
	if _defs.is_empty():
		_defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/objects.json"))
	return _defs


func _init(list: Array = []) -> void:
	for e: Dictionary in list:
		var d: Dictionary = defs()[e["type"]]
		var pos := Vector2i(e["pos"][0], e["pos"][1])
		objects.append({
			"id": e.get("id", "%s_%d_%d" % [e["type"], pos.x, pos.y]), "type": e["type"], "pos": pos,
			"state": e.get("state", d["start"]), "hp": int(d.get("hp", 0)), "maxhp": int(d.get("hp", 0)), "age": 0,
			"link": e.get("link", []), "dir": e.get("dir", "v"),
		})


func at(p: Vector2i) -> Dictionary:
	for o in objects:
		if o["pos"] == p:
			return o
	return {}


func by_id(id: String) -> Dictionary:
	for o in objects:
		if o["id"] == id:
			return o
	return {}


func is_blocking(o: Dictionary) -> bool:
	return (defs()[o["type"]]["blocks"] as Array).has(o["state"])


## Gesperrte Felder fuer Fussvolk (fuettert Grid.blocked).
func blocked() -> Dictionary:
	var out := {}
	for o in objects:
		if is_blocking(o):
			out[o["pos"]] = true
	return out


## Welche Marke aus caps loest das Objekt? {"cap", "effect"} oder {} (nur im aktiven Zustand).
func solution(o: Dictionary, caps: Array) -> Dictionary:
	var d: Dictionary = defs()[o["type"]]
	if o["state"] != d["active"]:
		return {}
	for cap: String in caps:
		if (d["solutions"] as Dictionary).has(cap):
			return {"cap": cap, "effect": d["solutions"][cap]}
	return {}


## Wirkung anwenden. Rueckgabe: alle Objekte, deren Zustand sich geaendert hat (Schalter oeffnet verknuepfte Tore).
func apply(o: Dictionary, effect: String) -> Array[Dictionary]:
	var changed: Array[Dictionary] = []
	match effect:
		"break":
			o["state"] = "broken"
			changed.append(o)
		"open":
			o["state"] = "open"
			changed.append(o)
		"free":
			o["state"] = "free"
			changed.append(o)
		"extinguish":
			o["age"] = 0
			o["state"] = "out" if o["type"] == "fire" else "intact"
			changed.append(o)
		"toggle":
			o["state"] = "on"
			changed.append(o)
			for gid: String in o["link"]:
				var g := by_id(gid)
				if not g.is_empty() and g["state"] == "closed":
					g["state"] = "open"
					changed.append(g)
	return changed


## Normaler Schaden auf ein Tor (z. B. Angriff). true = zerstoert. Zerstoert wird es erst bei 0 Leben.
func damage(o: Dictionary, amount: int) -> bool:
	o["hp"] = maxi(0, int(o["hp"]) - amount)
	if o["hp"] <= 0:
		o["state"] = "broken"
		return true
	return false


## Angriffsschaden gegen ein Objekt (Verteidigung des Objekts, mindestens 1).
static func hit_damage(o: Dictionary, atk: int) -> int:
	return maxi(1, atk - int(defs()[o["type"]].get("def", 0)))


## Kann ein normaler Angriff das Objekt zerstoeren? (Sicherheitsnetz: so bleibt jede Gruppe nie haengen.)
static func attackable(o: Dictionary) -> bool:
	return int(defs()[o["type"]].get("hp", 0)) > 0 and o["state"] == defs()[o["type"]]["active"]


# ------------------------------------------------------------------ Feuer

const BURN_TURNS := 3          # so viele Gegnerphasen brennt ein Feld, dann Asche bzw. Ruine
const DIRS4 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


func is_burning(o: Dictionary) -> bool:
	return (o["type"] == "fire" or o["type"] == "house") and o["state"] == "burning"


func burning_tiles() -> Dictionary:
	var out := {}
	for o in objects:
		if o["type"] == "fire" and o["state"] == "burning":
			out[o["pos"]] = true       # Schaden nur auf freien Feuerfeldern (Haeuser sind unbegehbar)
	return out


## Felder, die in der naechsten Feuerphase Feuer fangen (fuer die Vorschau).
func ignition_preview(flammable: Dictionary) -> Dictionary:
	var out := {}
	for o in objects:
		if not is_burning(o):
			continue
		for d: Vector2i in DIRS4:
			var p: Vector2i = o["pos"] + d
			if _can_ignite(p, flammable):
				out[p] = true
	return out


func _can_ignite(p: Vector2i, flammable: Dictionary) -> bool:
	var o := at(p)
	if not o.is_empty():
		return o["type"] == "house" and o["state"] == "intact"
	return flammable.has(p)          # Feld ohne Objekt: nur brennbares Gelaende (Wald), und nur einmal


## Eine Feuerphase (zu Beginn der Gegnerphase): zuerst Ausbreitung von dem, was jetzt brennt, dann Alterung.
## Rueckgabe: alle Objekte, deren Zustand sich geaendert hat (auch neu entstandene Feuer).
func tick_fire(flammable: Dictionary) -> Array[Dictionary]:
	var changed: Array[Dictionary] = []
	var targets := ignition_preview(flammable)
	for o in objects.duplicate():
		if not is_burning(o):
			continue
		o["age"] = int(o["age"]) + 1
		if o["age"] >= BURN_TURNS:
			o["state"] = "out" if o["type"] == "fire" else "ruin"
			changed.append(o)
	for p: Vector2i in targets:
		var h := at(p)
		if not h.is_empty():
			h["state"] = "burning"
			h["age"] = 0
			changed.append(h)
		else:
			var f := {"id": "fire_%d_%d" % [p.x, p.y], "type": "fire", "pos": p, "state": "burning", "hp": 0, "maxhp": 0, "age": 0, "link": [], "dir": "v", "spawned": true}
			objects.append(f)
			changed.append(f)
	return changed


func houses_lost() -> int:
	var n := 0
	for o in objects:
		if o["type"] == "house" and o["state"] == "ruin":
			n += 1
	return n
