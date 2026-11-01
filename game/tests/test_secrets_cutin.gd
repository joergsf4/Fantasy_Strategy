extends SceneTree
## godot --headless --path game --script tests/test_secrets_cutin.gd
## Erkennungszeichen: Jedes aktive Geheimnis hat den Polarlicht-Auftritt (effects.cutin).

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var units: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	for sec: Dictionary in Secrets.all():
		var ci: Dictionary = sec["effects"].get("cutin", {})
		check(not ci.is_empty() and units.has(ci.get("unit", "")) and str(ci.get("title", "")) != "", "%s hat den Polarlicht-Auftritt als Erkennungszeichen" % sec["id"])
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
