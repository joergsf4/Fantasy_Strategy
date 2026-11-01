class_name Items
extends RefCounted
## Ausruestung (3 Plaetze: Waffe, Ruestung, Talisman) und Verbrauchsgegenstaende (Rucksack, pro Team geteilt).
## Reine Regeln ohne Szene: gemeinsam genutzt von Battle (Spiel) und SimBattle (Balancing).
## Ein Gegenstand benutzen kostet die Aktion der Figur (wie ein Angriff); Ziel: Nachbar oder man selbst.

static var _defs: Dictionary = {}


static func defs() -> Dictionary:
	if _defs.is_empty():
		_defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
	return _defs


static func equipment() -> Dictionary:
	return defs()["equipment"]


static func consumables() -> Dictionary:
	return defs()["consumables"]


## Darf u dieses Ausruestungsstueck tragen? (req: "magic" = Magier, "ranged" = Fernkaempfer)
static func can_equip(u: Dictionary, id: String) -> bool:
	var req: String = equipment()[id].get("req", "")
	if req == "magic":
		return u["dmg_type"] == "magic"
	if req == "ranged":
		return u["range"] > 1
	return true


## Werte der Ausruestung auf die Figur anwenden (einmal beim Aufstellen).
static func apply_equipment(u: Dictionary, ids: Array) -> void:
	var worn: Array = []
	var slots := {}
	for id: String in ids:
		if not equipment().has(id) or not can_equip(u, id):
			continue
		var slot: String = equipment()[id]["slot"]
		if slots.has(slot):
			continue   # ein Stueck pro Platz
		slots[slot] = id
		worn.append(id)
		var m: Dictionary = equipment()[id]["mods"]
		for k: String in m:
			var v := int(m[k])
			match k:
				"hp":
					u["maxhp"] += v
					u["hp"] += v
				"move":
					u["move"] = maxi(1, u["move"] + v)
				"range":
					u["range"] += v
				"cd_bonus":
					u["cd_bonus"] = int(u.get("cd_bonus", 0)) + v
				_:
					u[k] = int(u[k]) + v
	u["equip"] = worn


## Abklingzeit nach Einsatz einer Faehigkeit (Zauberlampe senkt sie, mindestens 1).
static func cooldown_for(u: Dictionary, base_cd: int) -> int:
	return maxi(1, base_cd - int(u.get("cd_bonus", 0))) if base_cd > 0 else 0


## Gemeinsame Abklingzeit: Nach einer Faehigkeit sind alle Faehigkeiten der Figur fuer deren Dauer gesperrt.
static func start_cooldown(u: Dictionary, id: String, base_cd: int) -> void:
	var cd := cooldown_for(u, base_cd)
	u["cd"][id] = cd
	if _ability_defs()[id].get("solo", false):
		return
	for other: String in u.get("abilities", []):
		if not _ability_defs()[other].get("solo", false):
			u["cd"][other] = maxi(int(u["cd"].get(other, 0)), cd)


static var _abs: Dictionary = {}

static func _ability_defs() -> Dictionary:
	if _abs.is_empty():
		_abs = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	return _abs


## Mag u (bzw. ein Ziel) diesen Gegenstand sinnvoll bekommen? Fuer Menue und KI.
static func useful_on(id: String, target: Dictionary) -> bool:
	var it: Dictionary = consumables()[id]
	for ef: Dictionary in it["effects"]:
		match ef["type"]:
			"heal":
				if target["hp"] < target["maxhp"] or (ef.get("cleanse", false) and Status.has(target, "poison")):
					return true
			"reset_cd":
				for k: String in target["cd"]:
					if int(target["cd"][k]) > 0:
						return true
			"status":
				return true
	return false


## Wen trifft der Gegenstand? ("area": Nachbarn des Ziels im Radius, nur Verbuendete)
static func victims(id: String, target: Dictionary, team_units: Array) -> Array:
	var it: Dictionary = consumables()[id]
	var out: Array = [target]
	var r := int(it.get("area", 0))
	if r > 0:
		for o in team_units:
			if o != target and Grid.dist(o["pos"], target["pos"]) <= r:
				out.append(o)
	return out


## Wirkung anwenden. team_units = lebende Verbuendete des Anwenders. Rueckgabe: {heal, cured, status, victims}
static func apply_item(id: String, target: Dictionary, team_units: Array) -> Dictionary:
	var it: Dictionary = consumables()[id]
	var res := {"heal": 0, "cured": 0, "status": 0, "victims": victims(id, target, team_units)}
	for ef: Dictionary in it["effects"]:
		match ef["type"]:
			"heal":
				var amount := mini(int(ef["amount"]), target["maxhp"] - target["hp"])
				target["hp"] += amount
				res["heal"] += amount
				if ef.get("cleanse", false) and Status.cleanse(target):
					res["cured"] += 1
			"reset_cd":
				for k: String in target["cd"].keys():
					target["cd"][k] = 0
				res["status"] += 1
			"status":
				var vs: Array = res["victims"] if ef.get("to", "target") == "area_allies" else [target]
				for v: Dictionary in vs:
					Status.add(v, ef["id"], int(ef["turns"]), ef.get("mods", {}))
					res["status"] += 1
	return res


## Anzeigename eines Gegenstands, einer Ausruestung oder einer Zutat.
static func item_name(id: String) -> String:
	for sec: String in ["consumables", "equipment", "materials"]:
		if defs().get(sec, {}).has(id):
			return defs()[sec][id]["name"]
	return id
