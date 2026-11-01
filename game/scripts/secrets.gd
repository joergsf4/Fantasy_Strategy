class_name Secrets
extends RefCounted
## Geheime Interaktionen (data/secrets.json): Eine Figur setzt eine Faehigkeit auf einen Verbuendeten ein und schaltet damit
## fuer den Rest des Kampfes einen Bonus und ggf. eine Sonderfaehigkeit frei. Die Szene dazu laeuft nur beim ersten Mal.

static var _list: Array = []


static func all() -> Array:
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


static func by_id(id: String) -> Dictionary:
	for s: Dictionary in all():
		if s["id"] == id:
			return s
	return {}
