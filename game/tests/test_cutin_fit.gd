extends SceneTree
## godot --headless --path game --script tests/test_cutin_fit.gd
## Der Titel des Polarlicht-Auftritts muss in die Textspalte passen (vorher lief "Inspiration von oben" rechts aus dem Bild).

var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var c := SuperCutin.new()
	root.add_child(c)
	var font := UiTheme.font(UiTheme.F_TITLE)
	for title in ["DRUNKEN STRIKE", "INSPIRATION VON OBEN", "WOLLE IM ÜBERFLUSS", "LASER-REFLEKTOR", "EIN SEHR LANGER GEHEIMNISNAME MIT VIELEN WÖRTERN"]:
		var size := c._fit_size(title, 64, 700.0)
		var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		check(w <= 700.0 and size >= 20, "%s passt (Schrift %d, Breite %d)" % [title, size, int(w)])
	check(c._fit_size("KURZ", 64, 700.0) == 64, "kurze Titel behalten die volle Groesse")
	print("Tests fertig, Fehler: ", fails)
	quit(1 if fails > 0 else 0)
