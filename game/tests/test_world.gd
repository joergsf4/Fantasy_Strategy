extends SceneTree
## godot --headless --path game --script tests/test_world.gd
## Weltobjekte: Zustaende, Loesungen per Marke, Sperren fuer Fussvolk (Flieger nicht), Schalter, Tor-Schaden.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var w := World.new([
		{"id": "w1", "type": "wall", "pos": [3, 2]},
		{"id": "g1", "type": "gate", "pos": [3, 3]},
		{"id": "s1", "type": "switch", "pos": [5, 3], "link": ["g1"]}])
	check(w.at(Vector2i(3, 2))["state"] == "intact" and w.at(Vector2i(3, 3))["state"] == "closed" and w.at(Vector2i(5, 3))["state"] == "off", "Startzustaende")
	check(w.at(Vector2i(0, 0)).is_empty() and w.by_id("zzz").is_empty(), "Leeres Feld / unbekannte ID")
	check(w.blocked().has(Vector2i(3, 2)) and w.blocked().has(Vector2i(3, 3)) and not w.blocked().has(Vector2i(5, 3)), "Mauer und Tor sperren, Schalter nicht")
	# Marken -> Loesungen
	check(w.solution(w.by_id("w1"), ["blast"]).get("effect") == "break", "Kanone (blast) zerstoert die Mauer")
	check(w.solution(w.by_id("w1"), ["melt"]).is_empty(), "Laser (melt) hilft gegen die Mauer nicht")
	check(w.solution(w.by_id("w1"), ["leap"]).get("effect") == "pass", "Sprung ueber die Mauer")
	check(w.solution(w.by_id("w1"), ["throw_ally"]).get("effect") == "pass", "Verbuendeten ueber die Mauer werfen")
	check(w.solution(w.by_id("g1"), ["melt"]).get("effect") == "open", "Laser oeffnet das Tor")
	check(w.solution(w.by_id("g1"), ["smash"]).get("effect") == "break", "Pranke bricht das Tor")
	check(w.solution(w.by_id("g1"), ["cut"]).is_empty(), "Todeswirbel hilft gegen das Tor nicht")
	check(w.solution(w.by_id("s1"), ["ranged_hit"]).get("effect") == "toggle", "Fernwurf trifft den Schalter")
	check(w.solution(w.by_id("w1"), ["smash", "blast"]).get("cap") == "smash" or w.solution(w.by_id("w1"), ["smash", "blast"]).get("cap") == "blast", "Mehrere Marken: eine passt")
	# Schalter oeffnet das verknuepfte Tor
	var ch := w.apply(w.by_id("s1"), "toggle")
	check(w.by_id("s1")["state"] == "on" and w.by_id("g1")["state"] == "open" and ch.size() == 2, "Schalter an: Tor offen, zwei Aenderungen")
	check(not w.blocked().has(Vector2i(3, 3)) and w.blocked().has(Vector2i(3, 2)), "Offenes Tor sperrt nicht mehr, Mauer weiter")
	check(w.solution(w.by_id("s1"), ["ranged_hit"]).is_empty(), "Schalter schon an: keine Loesung mehr")
	check(w.solution(w.by_id("g1"), ["melt"]).is_empty(), "Offenes Tor braucht keine Loesung")
	# Mauer sprengen
	w.apply(w.by_id("w1"), "break")
	check(not w.blocked().has(Vector2i(3, 2)), "Zerstoerte Mauer sperrt nicht")
	# Tor-Schaden als Sicherheitsnetz
	var w2 := World.new([{"id": "g", "type": "gate", "pos": [1, 1]}])
	var g: Dictionary = w2.by_id("g")
	check(World.attackable(g) and World.hit_damage(g, 10) == 7 and World.hit_damage(g, 2) == 1, "Tor: Schaden = Angriff - 3, mindestens 1")
	check(not w2.damage(g, 20) and g["hp"] == 16, "Tor 36 -> 16")
	check(w2.damage(g, 16) and g["state"] == "broken" and not w2.is_blocking(g), "Tor bei 0 zerstoert, sperrt nicht mehr")
	check(not World.attackable(g) and not World.attackable(w.by_id("w1")), "Zerstoertes Tor und Mauer nicht angreifbar")
	# Sperre im Grid: Fussvolk ja, Flieger nein
	var grid := Grid.new(["GGGGGG", "GGGGGG", "GGGGGG", "GGGGGG"])
	var w3 := World.new([{"type": "wall", "pos": [2, 0]}, {"type": "wall", "pos": [2, 1]}, {"type": "wall", "pos": [2, 2]}, {"type": "wall", "pos": [2, 3]}])
	grid.blocked = w3.blocked()
	check(grid.cost(Vector2i(2, 1)) == -1 and grid.cost(Vector2i(2, 1), true) == 1, "Grid: Mauerfeld fuer Fussvolk -1, fuer Flieger 1")
	check(not grid.reachable(Vector2i(0, 0), 10).has(Vector2i(4, 0)), "Fussvolk kommt nicht durch die Mauerlinie")
	check(grid.reachable(Vector2i(0, 0), 10, true).has(Vector2i(4, 0)), "Flieger kommen drueber")
	w3.apply(w3.at(Vector2i(2, 1)), "break")
	grid.blocked = w3.blocked()
	check(grid.reachable(Vector2i(0, 0), 10).has(Vector2i(4, 0)), "Loch in der Mauer: Fussvolk kommt durch")
	# Marken in abilities.json
	var ab: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	check((ab["kanone"]["caps"] as Array).has("blast") and (ab["roter_laser"]["caps"] as Array).has("melt") and (ab["stabsprung"]["caps"] as Array).has("leap") and (ab["wurf"]["caps"] as Array).has("throw_ally"), "Fahigkeitsmarken eingetragen")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
