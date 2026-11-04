class_name Secrets
extends RefCounted
## Geheime Interaktionen (data/secrets.json): Eine Figur setzt eine Faehigkeit auf einen Verbuendeten ein und schaltet damit
## fuer den Rest des Kampfes einen Bonus und ggf. eine Sonderfaehigkeit frei. Die Szene dazu laeuft nur beim ersten Mal.

static var _list: Array = []
static var fired: Array = []       # in diesem Kampf schon ausgeloeste Geheimnisse: jedes wirkt pro Kampf (Level) nur einmal (sonst waere es mit Aether beliebig oft abrufbar)


## Markiert ein Geheimnis als ausgeloest (gilt bis zum naechsten Kampf).
static func fire(id: String) -> void:
	if not fired.has(id):
		fired.append(id)


static func all() -> Array:
	if not fired.is_empty():
		return _all_loaded().filter(func(s: Dictionary) -> bool: return not fired.has(s["id"]))
	return _all_loaded()


static func _all_loaded() -> Array:
	if _list.is_empty():
		_list = []
		for sec: Dictionary in (JSON.parse_string(FileAccess.get_file_as_string("res://data/secrets.json")) as Dictionary)["secrets"]:
			if sec.has("trigger"):      # reine Ideen (nur Freitext) sind im Spiel nicht aktiv
				_list.append(sec)
	return _list


## Das Geheimnis, das "by" mit "ability" auf "target" ausloest, oder {}.
static func find(by: String, ability: String, target: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "ability_on_ally") == "ability_on_ally" and t["by"] == by and t["ability"] == ability and t["target"] == target:
			return s
	return {}


## Das Geheimnis, bei dem "by" mit dem Strahl "ability" von der Figur "via" auf der Linie umgelenkt wird (Typ beam_via_ally), oder {}.
static func find_beam(by: String, ability: String, via: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "") == "beam_via_ally" and t["by"] == by and t["via"] == via and (t["abilities"] as Array).has(ability):
			return s
	return {}


## Das Geheimnis, bei dem "by" mit dem Wurf "ability" die Verbuendete "target" wirft (Typ throw_ally), oder {}.
static func find_throw(by: String, ability: String, target: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "") == "throw_ally" and t["by"] == by and t["ability"] == ability and t["target"] == target:
			return s
	return {}


## Das Geheimnis, bei dem "near" erschrickt/reagiert, wenn "by" die Faehigkeit "ability" einsetzt und "near" auf einem Nachbarfeld steht (Typ ability_near_ally), oder {}.
static func find_near(by: String, ability: String, near: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "") == "ability_near_ally" and t["by"] == by and t["ability"] == ability and t["near"] == near:
			return s
	return {}


## Das Geheimnis, bei dem "near" neben einem Gegner steht, den die Faehigkeit "ability" von "by" trifft (Typ hit_near_ally), oder {}.
static func find_hitnear(by: String, ability: String, near: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "") == "hit_near_ally" and t["by"] == by and t["ability"] == ability and t["near"] == near:
			return s
	return {}


## Das Geheimnis, bei dem "by" die Faehigkeit "ability" einsetzt, waehrend neben "by" ein Objekt dieser Art steht (Typ ability_near_object), oder {}.
static func find_object(by: String, ability: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "") == "ability_near_object" and t["by"] == by and t["ability"] == ability:
			return s
	return {}


## Das Geheimnis, bei dem die Verbuendete "ally" im Wirkbereich der Faehigkeit "ability" von "by" steht (Typ ability_area_ally), oder {}.
static func find_area(by: String, ability: String, ally: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "") == "ability_area_ally" and t["by"] == by and t["ability"] == ability and t["ally"] == ally:
			return s
	return {}


## Das Geheimnis, bei dem "by" ihren Schuetzling "unit" beschuetzt, wenn dessen Leben unter die Grenze faellt (Typ hp_below_near), oder {}.
static func find_protect(by: String, unit: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "") == "hp_below_near" and t["by"] == by and t["unit"] == unit:
			return s
	return {}


## Die zweite beteiligte Figur eines Geheimnisses (je nach Typ target, via, near, owner, ally oder unit).
static func partner(trigger: Dictionary) -> String:
	for k in ["target", "via", "near", "owner", "ally", "unit"]:
		if trigger.has(k):
			return str(trigger[k])
	return ""


## Alle Geheimnisse, bei denen "by" die gefallene Figur "unit" ins Leben zurueckholt (Typ ally_fallen_near).
static func find_revives(unit: String) -> Array:
	var out: Array = []
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t.get("type", "") == "ally_fallen_near" and t["unit"] == unit:
			out.append(s)
	return out


static func by_id(id: String) -> Dictionary:
	for s: Dictionary in all():
		if s["id"] == id:
			return s
	return {}
