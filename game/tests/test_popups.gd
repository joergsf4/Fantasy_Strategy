extends SceneTree
## godot --headless --path game --script tests/test_popups.gd
## Anzeige ueber den Koepfen: Lebensbalken statt Zahl, Details nur bei Auswahl/Hover/Alt, Status-Symbole in einer Reihe, gestaffelte Meldungen.

var fails := 0
var b: Battle


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func live_count(u: Dictionary) -> int:
	return (b._popup_live.get(u["uid"], []) as Array).size()


func _initialize() -> void:
	Engine.time_scale = 1.0
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map_ch1.json"))
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	b = Battle.new()
	b.setup(map, defs)
	root.add_child(b)
	await process_frame
	await process_frame
	var u: Dictionary = b.units.filter(func(x: Dictionary) -> bool: return x["team"] == "p")[0]
	var other: Dictionary = b.units.filter(func(x: Dictionary) -> bool: return x["team"] == "e")[0]
	# --- Balken und Details
	var bar := u["bar"] as MeshInstance3D
	check(bar.visible, "Lebensbalken ist sichtbar")
	check(not (u["label"] as Label3D).visible, "Standard: keine Zahl und keine Statusnamen ueber dem Kopf")
	u["hp"] = u["maxhp"] / 2
	b._refresh_unit(u)
	check(is_equal_approx(float(((bar.material_override as ShaderMaterial).get_shader_parameter("ratio"))), 0.5), "Balken zeigt den Lebensanteil")
	b.sel = u
	b._sync_labels()
	check((u["label"] as Label3D).visible and (u["label"] as Label3D).text.begins_with("%d/%d" % [u["hp"], u["maxhp"]]), "ausgewaehlte Figur zeigt Details")
	b.sel = {}
	b._sync_labels()
	check(not (u["label"] as Label3D).visible, "ohne Auswahl wieder nur der Balken")
	b._hover_unit = other
	b._sync_labels()
	check((other["label"] as Label3D).visible and not (u["label"] as Label3D).visible, "Hover zeigt Details der Figur unter dem Zeiger")
	b._hover_unit = {}
	var alt := InputEventKey.new()
	alt.keycode = KEY_ALT
	alt.pressed = true
	b._input(alt)
	check(b.units.all(func(x: Dictionary) -> bool: return (x["label"] as Label3D).visible), "Alt: alle Details sichtbar")
	alt.pressed = false
	b._input(alt)
	check(b.units.all(func(x: Dictionary) -> bool: return not (x["label"] as Label3D).visible), "Alt losgelassen: wieder nur Balken")

	# --- Status-Symbole in einer Reihe
	for s in ["stun", "taunt", "wut", "tempo", "uebel"]:
		Status.add(u, s, 3)
	b._refresh_unit(u)
	b._place_overlays()
	var xs: Array[float] = []
	var visible_icons := 0
	for id: String in ["stun", "taunt", "wut", "tempo", "uebel"]:
		var holder: Node3D = u["fx_nodes"].get(id)
		check(holder != null, "Symbol fuer %s existiert" % id)
		var ic := holder.get_node("icon") as Node3D
		if ic.visible:
			visible_icons += 1
			xs.append(float(ic.get_meta("slot")))
			var up := b.cam.global_transform.basis.y.normalized()
			check(ic.position.dot(up) > (u["bar"] as Node3D).position.dot(up) + 0.2, "Symbol liegt ueber dem Balken (Kamera-Hochachse)")
	check(visible_icons == 3, "hoechstens drei Symbole sichtbar (%d)" % visible_icons)
	xs.sort()
	check(xs.size() == 3 and xs[1] - xs[0] >= 0.99 and xs[2] - xs[1] >= 0.99, "Symbole stehen nebeneinander ohne Ueberlappung: %s" % [xs])
	check(u.get("more") != null and (u["more"] as Label3D).visible and (u["more"] as Label3D).text == "+2", "Rest als +2")
	check(((u["fx_nodes"]["stun"] as Node3D).get_node("icon/turns") as Label3D).text == "3", "kleine Zahl zeigt die Restdauer")

	# --- Meldungen: Warteschlange, Zusammenfassen, Obergrenze, getrennte Seiten
	var texts := ["-5", "+3", "Gestärkt", "Gift", "Benommen"]
	for t in texts:
		b._popup(u, t, Color.WHITE)
	await create_timer(0.02).timeout
	check(live_count(u) <= Battle.POPUP_MAX, "hoechstens %d gleichzeitig (%d)" % [Battle.POPUP_MAX, live_count(u)])
	var maxlive := 0
	for i in 40:
		await create_timer(0.05).timeout
		maxlive = maxi(maxlive, live_count(u))
	check(maxlive <= Battle.POPUP_MAX, "waehrend des Ablaufs nie mehr als %d (%d)" % [Battle.POPUP_MAX, maxlive])
	await create_timer(1.5).timeout
	check(live_count(u) == 0, "Warteschlange laeuft leer")
	b._popup(other, "Gift", Color.GREEN)
	b._popup(other, "Gift", Color.GREEN)
	b._popup(other, "Gift", Color.GREEN)
	await create_timer(0.05).timeout
	var live := b._popup_live[other["uid"]] as Array
	check(live.size() == 1 and (live[0]["label"] as Label3D).text == "Gift ×3", "gleiche Meldungen werden zusammengefasst: %s" % [live.map(func(e: Dictionary) -> String: return e["label"].text)])
	await create_timer(1.6).timeout
	# Seiten wechseln
	var sides: Array[float] = []
	var p0: Vector3 = (u["node"] as Node3D).position
	b._popup(u, "-1", Color.RED)
	await create_timer(0.3).timeout
	b._popup(u, "-2", Color.RED)
	await create_timer(0.05).timeout
	for e: Dictionary in b._popup_live[u["uid"]]:
		sides.append(signf((e["label"] as Label3D).position.x - p0.x))
	check(sides.size() == 2 and sides[0] != sides[1], "aufeinanderfolgende Meldungen erscheinen auf verschiedenen Seiten: %s" % [sides])
	# Banner
	b._banner("Wollmantel")
	check(b._banner_label != null and b._banner_label.text == "Wollmantel", "Faehigkeitsname laeuft ueber das Banner")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
