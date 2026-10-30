extends SceneTree
## godot --headless --path game --script tests/test_events.gd
## Ereignisse im Kampf: Heilung trifft N Verbuendete, Faehigkeit, Gegner besiegt, Held gefallen, Leben unter X,
## Naehe zweier Figuren, Gegner uebrig. Mit Bedingungen (present/absent) und "$hero" im Dialog.

var fails := 0
var b: Battle
var defs: Dictionary
var talk: Array = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	Engine.time_scale = 12.0
	defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	var m := Mission.load_mission("ch1")
	m["players"] = []
	m["enemies"] = []
	m["triggers"] = []
	b.setup(m, defs)
	b.dialogue_runner = func(lines: Array) -> void: talk.append(lines)
	root.add_child(b)
	await process_frame
	await run_tests()
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)


func line(speaker: String, text := "x") -> Array:
	return [{"left": "$hero", "right": "ritter", "speaker": speaker, "text": text}]


func setup_scene(trig: Array, heroes: Array, foes := []) -> Array:
	for u in b.units + b._away:
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	b._away.clear()
	b.state = Battle.State.IDLE
	b.triggers = trig.duplicate(true)
	b._notes.clear()
	b.kills_total = 0
	talk.clear()
	var out: Array = []
	for h: Array in heroes:
		b._spawn(h[0], "p", Vector2i(h[1][0], h[1][1]))
		out.append(b.units.back())
	b._spawn("soldat_infanterie", "e", Vector2i(11, 0))   # ein ferner Gegner: der Kampf ist nie gewonnen
	for f: Array in foes:
		b._spawn(f[0], "e", Vector2i(f[1][0], f[1][1]))
		out.append(b.units.back())
	return out


func run_tests() -> void:
	# --- Wendy heilt 3 Verbuendete -> Lob der Gruppe (nur wenn mindestens 3 geheilt werden)
	var trig := [{"when": {"heal": {"by": "wendy", "targets": 3}}, "if": {"present": ["ritter"]},
		"do": [{"dialogue": [{"left": "ritter", "right": "wendy", "speaker": "ritter", "text": "Gut gemacht, Wendy!"}]}]}]
	var s := setup_scene(trig, [["wendy", [4, 7]], ["ritter", [5, 7]], ["kungfu", [5, 8]], ["samurai", [6, 7]]])
	for i in [1, 2, 3]:
		s[i]["hp"] -= 8
	await b._run_ability(s[0], "gruppenheilung", s[1])
	check(b._notes.size() >= 1 and b._notes[-1]["kind"] == "heal" and b._notes[-1]["healed"].size() == 3, "Gruppenheilung: Ereignis mit 3 Geheilten gemerkt")
	await b._flush_events()
	check(talk.size() == 1 and talk[0][0]["text"] == "Gut gemacht, Wendy!", "Lob wird gespielt")
	check(b._notes.is_empty(), "Ereignisse nach der Pruefung geleert")
	await b._flush_events()
	check(talk.size() == 1, "Ausloeser feuert nur einmal")
	# nur 2 geheilt: kein Lob
	s = setup_scene(trig, [["wendy", [4, 7]], ["ritter", [5, 7]], ["kungfu", [5, 8]], ["samurai", [6, 7]]])
	s[1]["hp"] -= 8
	s[2]["hp"] -= 8
	await b._run_ability(s[0], "gruppenheilung", s[1])
	await b._flush_events()
	check(talk.is_empty(), "Nur 2 Verbuendete geheilt: kein Lob")
	# falsche Heilerin loest nicht aus
	s = setup_scene(trig, [["robo", [4, 7]], ["ritter", [5, 7]], ["wendy", [0, 9]]])
	s[1]["hp"] -= 5
	await b._run_ability(s[0], "gruener_laser", s[1])
	await b._flush_events()
	check(talk.is_empty(), "Heilung durch Robo (nicht Wendy): kein Lob")
	# present: fehlt der Lobende, kommt kein Dialog (und der Ausloeser bleibt erhalten)
	s = setup_scene(trig, [["wendy", [4, 7]], ["kungfu", [5, 8]], ["samurai", [6, 7]], ["hund", [5, 7]]])
	for i in [1, 2, 3]:
		s[i]["hp"] -= 8
	await b._run_ability(s[0], "gruppenheilung", s[3])
	await b._flush_events()
	check(talk.is_empty() and not b.triggers[0].get("fired", false), "Albrecht fehlt: kein Dialog, Ausloeser bleibt")

	# --- Fasswurf zum ersten Mal: Spruch mit $hero
	trig = [{"when": {"ability": {"id": "fasswurf"}}, "do": [{"dialogue": line("$hero", "Prost!")}]}]
	s = setup_scene(trig, [["braumeisterin", [3, 7]]], [["soldat_infanterie", [5, 7]]])
	await b._run_ability(s[0], "fasswurf", s[1])
	await b._flush_events()
	check(talk.size() == 1 and talk[0][0]["left"] == "braumeisterin" and talk[0][0]["speaker"] == "braumeisterin", "Faehigkeit: $hero ist Brunhilde")

	# --- Gegner besiegt: bestimmter Gegner, erster Kill, Anzahl
	trig = [
		{"when": {"first_kill": true}, "do": [{"dialogue": line("$hero", "Der erste!")}]},
		{"when": {"kill": {"id": "bienenmaedchen"}}, "do": [{"dialogue": line("$hero", "Die Biene ist erledigt.")}]},
		{"when": {"kill": {"count": 3}}, "do": [{"dialogue": line("$hero", "Drei!")}]}]
	s = setup_scene(trig, [["samurai", [3, 7]]], [["soldat_infanterie", [4, 7]], ["soldat_infanterie", [4, 6]], ["bienenmaedchen", [4, 8]]])
	s[1]["hp"] = 1
	await b._strike(s[0], s[1])
	await b._flush_events()
	check(talk.size() == 1 and talk[0][0]["text"] == "Der erste!", "Erster besiegter Gegner")
	s[2]["hp"] = 1
	await b._strike(s[0], s[2])
	await b._flush_events()
	check(talk.size() == 1, "Zweiter Kill: weder Biene noch drei")
	s[3]["hp"] = 1
	await b._strike(s[0], s[3])
	await b._flush_events()
	var texts := talk.map(func(l: Array) -> String: return l[0]["text"])
	check(texts.has("Die Biene ist erledigt.") and texts.has("Drei!"), "Biene und dritter Kill: beide Ausloeser, Texte %s" % [texts])
	check(talk[1][0]["left"] == "samurai", "Dialog mit dem Sieger (Takeda) als $hero")

	# --- Held faellt
	trig = [{"when": {"fall": {"id": "wendy"}}, "do": [{"dialogue": line("ritter", "Wendy! Nein!")}]}]
	s = setup_scene(trig, [["wendy", [4, 7]], ["ritter", [5, 7]]], [["soldat_infanterie", [4, 6]]])
	s[0]["hp"] = 1
	await b._strike(s[2], s[0])
	await b._flush_events()
	check(talk.size() == 1 and talk[0][0]["text"] == "Wendy! Nein!", "Wendy faellt: Reaktion")

	# --- Leben unter 50 %
	trig = [{"when": {"hp_below": {"id": "ritter", "ratio": 0.5}}, "do": [{"dialogue": line("ritter", "Ich halte durch!")}]}]
	s = setup_scene(trig, [["ritter", [4, 7]]])
	s[0]["hp"] = 20
	await b._flush_events()
	check(talk.is_empty(), "Albrecht bei 20/34: noch ueber 50 %")
	s[0]["hp"] = 16
	await b._flush_events()
	check(talk.size() == 1, "Albrecht bei 16/34: unter 50 %, Dialog")

	# --- Naehe: Mira trifft auf Stachelia
	trig = [{"when": {"near": {"a": "maedchen_baer", "b": "bienenmaedchen", "dist": 3}}, "do": [{"dialogue": line("$hero", "Brumm riecht Honig.")}]}]
	s = setup_scene(trig, [["maedchen_baer", [4, 7]]], [["bienenmaedchen", [9, 7]]])
	await b._flush_events()
	check(talk.is_empty(), "Stachelia 5 Felder weg: kein Dialog")
	s[1]["pos"] = Vector2i(6, 7)
	await b._flush_events()
	check(talk.size() == 1 and talk[0][0]["left"] == "maedchen_baer", "Stachelia 2 Felder weg: Dialog, Mira spricht")
	# "any_enemy"
	trig = [{"when": {"near": {"a": "ritter", "b": "any_enemy", "dist": 2}}, "do": [{"dialogue": line("$hero", "Feind in Sicht!")}]}]
	s = setup_scene(trig, [["ritter", [4, 7]]], [["soldat_beritten", [5, 7]]])
	await b._flush_events()
	check(talk.size() == 1, "any_enemy in Reichweite 2: Dialog")

	# --- Gegner uebrig
	trig = [{"when": {"enemies_left": 2}, "do": [{"dialogue": line("$hero", "Fast geschafft.")}]}]
	s = setup_scene(trig, [["ritter", [4, 7]]], [["soldat_infanterie", [6, 7]], ["soldat_infanterie", [7, 7]]])
	await b._flush_events()
	check(talk.is_empty(), "Drei Gegner uebrig: noch nichts")
	b.units.erase(s[1])
	await b._flush_events()
	check(talk.size() == 1, "Zwei Gegner uebrig: Dialog")

	# --- absent
	trig = [{"when": {"enemies_left": 5}, "if": {"absent": ["wendy"]}, "do": [{"dialogue": line("ritter", "Ohne Wendy.")}]}]
	s = setup_scene(trig, [["ritter", [4, 7]], ["wendy", [5, 7]]])
	await b._flush_events()
	check(talk.is_empty() and not b.triggers[0].get("fired", false), "absent: Wendy lebt, kein Dialog")
	b.units.erase(s[1])
	await b._flush_events()
	check(talk.size() == 1, "absent: Wendy weg, Dialog")

	# --- Reihenfolge im Spielablauf: _finish_unit_after fuehrt Ereignisse aus, Eingabe ist waehrenddessen gesperrt
	trig = [{"when": {"ability": {"id": "verspotten"}}, "do": [{"dialogue": line("ritter", "Zu mir!")}]}]
	s = setup_scene(trig, [["ritter", [4, 7]], ["wendy", [0, 9]]], [["soldat_infanterie", [6, 7]]])
	await b._run_ability(s[0], "verspotten", s[0])
	await b._finish_unit_after(s[0])
	check(talk.size() == 1 and b.state == Battle.State.IDLE and s[0]["done"], "Nach der Aktion: Ereignis gespielt, danach wieder bedienbar")
