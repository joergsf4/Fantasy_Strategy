class_name Party
extends RefCounted
## Zustand der Heldengruppe ueber Kapitel hinweg: Gold, Rucksack, Zutaten, Ausruestung. Wird gespeichert.
## Nichts fuellt sich von selbst auf: verbrauchte Gegenstaende sind weg, Beute kommt aus festen Quellen.

const SAVE_PATH := "user://save.json"

var chapter := 1
var gold := 0
var inventory: Dictionary = {}     # Verbrauchsgegenstaende {id: Anzahl}
var materials: Dictionary = {}     # Zutaten {id: Anzahl}
var equipment: Dictionary = {}     # getragen: {Held: [Ausruestung]}
var pool: Array = []               # besitzt, aber nicht getragen
var squads: Dictionary = {}              # {Mission: [Helden]}: vom Spieler geaenderte Aufstellung vor der Mission
var nemesis: Array = []            # entkommene Gegner, tauchen in spaeteren Missionen wieder auf
var bought: Dictionary = {}        # im aktuellen Lager gekauft {id: Anzahl} (Haendler hat nur festen Vorrat)


static func new_game() -> Party:
	var p := Party.new()
	var lo: Dictionary = Items.defs().get("loadout_chapter1", {})
	p.inventory = (lo.get("inventory", {}) as Dictionary).duplicate()
	p.equipment = (lo.get("equipment", {}) as Dictionary).duplicate(true)
	return p


## Was ein Kampf zu Beginn bekommt.
func loadout() -> Dictionary:
	return {"inventory": inventory.duplicate(), "equipment": equipment.duplicate(true), "nemesis": nemesis.duplicate()}


static func _add(into: Dictionary, from: Dictionary) -> void:
	for k: String in from:
		into[k] = int(into.get(k, 0)) + int(from[k])


## Ergebnis eines gewonnenen Kampfes uebernehmen (Rucksack-Rest + Beute + Belohnungen).
func absorb(results: Dictionary) -> void:
	inventory = (results["inventory"] as Dictionary).duplicate()
	_add(materials, results["materials"])
	gold += int(results["gold"])
	pool.append_array(results["equipment"])
	for id: String in results.get("fled", []):
		if not nemesis.has(id):
			nemesis.append(id)
	chapter += 1
	bought = {}


## Zutaten und Gold ausgeben, Gegenstand erhalten. false = nicht moeglich (zu wenig).
func can_afford(price: int) -> bool:
	return gold >= price


func spend(price: int) -> bool:
	if gold < price:
		return false
	gold -= price
	return true


func to_dict() -> Dictionary:
	return {"chapter": chapter, "gold": gold, "inventory": inventory, "materials": materials, "equipment": equipment, "pool": pool, "bought": bought, "nemesis": nemesis, "squads": squads}


static func from_dict(d: Dictionary) -> Party:
	var p := Party.new()
	p.chapter = int(d.get("chapter", 1))
	p.gold = int(d.get("gold", 0))
	p.inventory = _ints(d.get("inventory", {}))
	p.materials = _ints(d.get("materials", {}))
	p.equipment = (d.get("equipment", {}) as Dictionary).duplicate(true)
	p.pool = (d.get("pool", []) as Array).duplicate()
	p.bought = _ints(d.get("bought", {}))
	p.nemesis = (d.get("nemesis", []) as Array).duplicate()
	p.squads = (d.get("squads", {}) as Dictionary).duplicate(true)
	return p


static func _ints(d: Dictionary) -> Dictionary:
	var out := {}
	for k: String in d:
		out[k] = int(d[k])
	return out


func save(path := SAVE_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()


## Helden, die man in Mission cid (Nummer ab 1) in die Gruppe holen kann: alle mit "hero": true und "from" <= Missionsnummer.
static func roster(defs: Dictionary, mission_no: int) -> Array:
	var out: Array = []
	for id: String in defs:
		if defs[id].get("hero", false) and int(defs[id].get("from", 1)) <= mission_no:
			out.append(id)
	return out


## Gruppe fuer eine Mission: die Vorgabe der Karte (players), darueber die gespeicherte Auswahl des Spielers.
## Gespraechsfiguren bleiben immer drin, die Auswahl wird auf gueltige Plaetze zurechtgestutzt.
func squad_for(m: Dictionary) -> Array:
	var base: Array = (m["players"] as Array).map(func(e: Dictionary) -> String: return e["id"])
	var saved: Array = squads.get(m.get("id", ""), [])
	if saved.size() != base.size():
		return base
	var fixed: Array = Mission.dialogue_ids(m["id"])
	var out: Array = []
	for i in base.size():
		var id: String = base[i] if fixed.has(base[i]) else saved[i]
		out.append(id if not out.has(id) else base[i])
	return out


## Wechselt Platz i der Gruppe von Mission m auf Held id. false, wenn der Platz fest ist oder der Held schon dabei ist.
func set_squad_member(m: Dictionary, i: int, id: String) -> bool:
	var cur := squad_for(m)
	if Mission.dialogue_ids(m["id"]).has(cur[i]) or cur.has(id):
		return false
	cur[i] = id
	squads[m["id"]] = cur
	release_absent(cur)
	return true


## Ausruestung aller Helden, die nicht in dieser Gruppe sind, geht in den Lager-Vorrat zurueck und kann neu verteilt werden.
func release_absent(squad: Array) -> void:
	for hero: String in equipment.keys():
		if squad.has(hero):
			continue
		for w: String in equipment[hero]:
			pool.append(w)
		equipment.erase(hero)


## Kurzbeschreibung fuer die Kapitelwahl.
func summary() -> String:
	var names := {"wart": "Wart", "oskar": "Oskar", "maja": "Maja", "xiulan": "Xiùlán", "bienenmaedchen": "Stachelia", "dummy": "Trainingsattrappe"}
	var fled: Array = nemesis.map(func(id: String) -> String: return names.get(id, id))
	return "Spielstand: Gold %d%s" % [gold, ", entkommen: " + ", ".join(fled) if not fled.is_empty() else ""]


static func delete_save(path := SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func load_from(path := SAVE_PATH) -> Party:
	if not FileAccess.file_exists(path):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Party.from_dict(d) if d is Dictionary else null


# ------------------------------------------------------------------ Haendler, Brauen, Ausruestung

static func shop_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))


static func recipes() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes.json"))


## Waren des Haendlers fuer das aktuelle Kapitel: [{id, price, n, left}]
func stock() -> Array:
	var out: Array = []
	for w: Dictionary in shop_data().get("chapter%d" % chapter, shop_data().get("chapter1", [])):
		var left := int(w["n"]) - int(bought.get(w["id"], 0))
		out.append({"id": w["id"], "price": int(w["price"]), "n": int(w["n"]), "left": left})
	return out


func can_buy(id: String) -> bool:
	for w: Dictionary in stock():
		if w["id"] == id:
			return w["left"] > 0 and gold >= w["price"]
	return false


## Kaufen: Verbrauchsgut -> Rucksack, Ausruestung -> Lager. false = nicht moeglich.
func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	for w: Dictionary in stock():
		if w["id"] == id:
			gold -= w["price"]
	bought[id] = int(bought.get(id, 0)) + 1
	if Items.consumables().has(id):
		inventory[id] = int(inventory.get(id, 0)) + 1
	else:
		pool.append(id)
	return true


func can_brew(id: String) -> bool:
	var r: Dictionary = recipes().get(id, {})
	if r.is_empty():
		return false
	for m: String in r["cost"]:
		if int(materials.get(m, 0)) < int(r["cost"][m]):
			return false
	return true


func brew(id: String) -> bool:
	if not can_brew(id):
		return false
	var r: Dictionary = recipes()[id]
	for m: String in r["cost"]:
		materials[m] = int(materials[m]) - int(r["cost"][m])
	inventory[id] = int(inventory.get(id, 0)) + 1
	return true


## Ausruestung eines Helden anlegen (aus dem Lager). Ein Stueck pro Platz: das alte geht zurueck ins Lager.
## unit_def = Eintrag aus units.json (fuer Einschraenkungen wie "nur Magier").
func equip(hero: String, id: String, unit_def: Dictionary) -> bool:
	var i := pool.find(id)
	if i < 0:
		return false
	if not Items.can_equip({"dmg_type": unit_def.get("dmg_type", "body"), "range": int(unit_def.get("range", 1))}, id):
		return false
	var slot: String = Items.equipment()[id]["slot"]
	var worn: Array = (equipment.get(hero, []) as Array).duplicate()
	for w: String in worn.duplicate():
		if Items.equipment()[w]["slot"] == slot:
			worn.erase(w)
			pool.append(w)
	pool.remove_at(pool.find(id))
	worn.append(id)
	equipment[hero] = worn
	return true


func unequip(hero: String, slot: String) -> void:
	var worn: Array = (equipment.get(hero, []) as Array).duplicate()
	for w: String in worn.duplicate():
		if Items.equipment()[w]["slot"] == slot:
			worn.erase(w)
			pool.append(w)
	equipment[hero] = worn


func worn_in(hero: String, slot: String) -> String:
	for w: String in equipment.get(hero, []):
		if Items.equipment()[w]["slot"] == slot:
			return w
	return ""
