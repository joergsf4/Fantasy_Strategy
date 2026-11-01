class_name Secrets
extends RefCounted
## Geheime Interaktionen (data/secrets.json): Eine Figur setzt eine Faehigkeit auf einen Verbuendeten ein und schaltet damit
## fuer den Rest des Kampfes einen Bonus und ggf. eine Sonderfaehigkeit frei. Die Szene dazu laeuft nur beim ersten Mal.

static var _list: Array = []


static func all() -> Array:
	if _list.is_empty():
		_list = (JSON.parse_string(FileAccess.get_file_as_string("res://data/secrets.json")) as Dictionary)["secrets"]
	return _list


## Das Geheimnis, das "by" mit "ability" auf "target" ausloest, oder {}.
static func find(by: String, ability: String, target: String) -> Dictionary:
	for s: Dictionary in all():
		var t: Dictionary = s["trigger"]
		if t["by"] == by and t["ability"] == ability and t["target"] == target:
			return s
	return {}


static func by_id(id: String) -> Dictionary:
	for s: Dictionary in all():
		if s["id"] == id:
			return s
	return {}
