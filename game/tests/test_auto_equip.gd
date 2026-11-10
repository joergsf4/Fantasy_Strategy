extends SceneTree

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var p := Party.new()
	p.equipment = {"robo": ["eisenschwert"], "ritter": ["kettenhemd"]}
	p.pool = ["fernrohr", "kristallstab", "stahlklinge", "lederwams", "lederwams", "zauberlampe"]
	var squad := ["ritter", "magical_girl", "robo", "wendy"]
	var original_count := p.pool.size()
	var count := p.auto_equip(squad, defs)
	check(count == original_count and p.pool.is_empty(), "Vorhandene Gegenstaende einmalig verteilt")
	check(p.worn_in("robo", "waffe") == "eisenschwert" and p.worn_in("ritter", "ruestung") == "kettenhemd", "Bereits angelegte Stuecke bleiben unveraendert")
	check(p.worn_in("robo", "talisman") == "fernrohr" or p.worn_in("magical_girl", "talisman") == "fernrohr", "Fernrohr geht an geeigneten Fernkaempfer")
	check(p.worn_in("magical_girl", "waffe") == "kristallstab" or p.worn_in("wendy", "waffe") == "kristallstab", "Magierstab geht an passenden Magier")
	check(p.worn_in("ritter", "waffe") == "stahlklinge", "Allgemeine Waffe bleibt fuer Nichtmagier")
	check(p.auto_equip(squad, defs) == 0, "Wiederholter Aufruf veraendert nichts")

	var robo_party := Party.new()
	robo_party.pool = ["fernrohr"]
	check(robo_party.auto_equip(["ritter", "wendy", "robo"], defs) == 1 and robo_party.worn_in("robo", "talisman") == "fernrohr", "Fernrohr fuer Robo statt Nahkaempfer oder Heilerin")
	check(robo_party.equipment.size() == 1, "Nicht zur Gruppe gehoerende Figuren bleiben unberuehrt")

	var blocked := Party.new()
	blocked.pool = ["fernrohr", "kristallstab", "zauberlampe"]
	var no_abilities := {"name": "Ohne Faehigkeiten", "dmg_type": "body", "range": 1, "role": "tank", "abilities": []}
	check(blocked.auto_equip(["test"], {"test": no_abilities}) == 0 and blocked.pool.size() == 3, "Untragbare und unbrauchbare Gegenstaende bleiben im Lager")
	check(blocked.auto_equip([], defs) == 0, "Leere Gruppe ist erlaubt")

	var path := "user://test_auto_equip.json"
	p.save(path)
	var loaded := Party.load_from(path)
	check(loaded.equipment == p.equipment and loaded.pool == p.pool, "Automatische Ausruestung bleibt beim Speichern erhalten")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var ui_party := Party.new()
	ui_party.pool = ["fernrohr"]
	var camp := Camp.new()
	camp.setup(ui_party, defs, ["robo"])
	root.add_child(camp)
	camp.show_page("ausruestung")
	await process_frame
	var auto_button: Button
	for node: Node in camp.find_children("*", "Button", true, false):
		if (node as Button).text == "Automatisch ausrüsten":
			auto_button = node as Button
			break
	check(auto_button != null, "Automatik-Knopf im Ausruestungsreiter")
	if auto_button != null:
		auto_button.pressed.emit()
		check(ui_party.worn_in("robo", "talisman") == "fernrohr", "Knopf ruestet aktuelle Gruppe aus")
		check(camp._auto_gear_message == "1 freier Platz ausgerüstet.", "Rueckmeldung nach Ausruesten")
	camp.queue_free()
	await process_frame
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
