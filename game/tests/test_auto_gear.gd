extends SceneTree
## godot --headless --path game --script tests/test_auto_gear.gd
## Gruppenwahl-Option "Ausrüstung automatisch verteilen": Wer die Gruppe verlaesst, gibt seine Ausruestung ins Lager; Neue bekommen
## freie Stuecke daraus (angelegte Ausruestung bleibt). Die Option wird gespeichert, ab Werk an.

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var p := Party.new_game()
	check(p.auto_gear, "Option ab Werk an")
	p.pool = []
	p.equipment = {"ritter": ["eisenschwert", "kettenhemd"]}
	# Ritter verlaesst die Gruppe, Takeda kommt neu
	var squad := ["maedchen_baer", "samurai"]
	p.release_absent(squad)
	check(p.pool.has("eisenschwert") and p.pool.has("kettenhemd") and not p.equipment.has("ritter"), "Ausruestung des Ritters liegt im Lager")
	var n := p.auto_equip(squad, defs)
	check(n > 0 and (p.worn_in("samurai", "waffe") != "" or p.worn_in("samurai", "ruestung") != "" or p.worn_in("maedchen_baer", "ruestung") != ""), "Neue bekommen freie Stuecke aus dem Lager (%d angelegt)" % n)
	var d := p.to_dict()
	d["auto_gear"] = false
	var q := Party.from_dict(d)
	check(not q.auto_gear, "Option wird gespeichert")
	check(Party.from_dict({"chapter": 3}).auto_gear, "Alter Spielstand: Option an")
	var src := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(src.contains("party.test_run or party.auto_gear"), "Missionsstart verteilt bei eingeschalteter Option")
	print("auto_gear: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
