class_name Camp
extends Control
## Lager zwischen Kapiteln. Aufbau: Kopfzeile (naechste Mission, Gold), links die Seitenleiste mit den Bereichen und dem
## Knopf zum Aufbrechen, rechts der gewaehlte Bereich. Die Uebersicht zeigt die naechste Mission mit ihren Bonuszielen und
## was vor dem Aufbruch noch offen ist (freie Talentpunkte, leere Ausruestungsplaetze). Aenderungen gehen direkt in den Party-Zustand.

signal closed

const PAGES := ["uebersicht", "haendler", "ausruestung", "aufstellung", "talente", "geheimnisse"]
const PAGE_NAMES := {"uebersicht": "Übersicht", "haendler": "Händler", "ausruestung": "Ausrüstung", "aufstellung": "Aufstellung",
	"talente": "Talente", "geheimnisse": "Geheimnisse"}
const SLOTS := {"waffe": "Waffe", "ruestung": "Rüstung", "talisman": "Talisman"}
const GROUPS := ["Verbrauch", "Waffen", "Rüstungen", "Talismane"]
const GOLD_COL := Color(1.0, 0.83, 0.42)
const DIM_COL := Color(0.78, 0.76, 0.68)
const OK_COL := Color(0.55, 0.9, 0.55)
const TODO_COL := Color(1.0, 0.72, 0.25)
const BODY_W := 980      # nutzbare Breite des Inhaltsbereichs

var party: Party
var unit_defs: Dictionary
var squad: Array = []
var mission: Dictionary = {}        # naechste Mission, deren Gruppe man hier waehlt (leer = nur anzeigen)
var _pick := -1                     # Platz, fuer den gerade ein Ersatz gewaehlt wird
var _page := "uebersicht"
var _hero := ""
var _quip := ""
var _sell := false                  # Haendler: Verkaufen statt Kaufen
var _auto_gear_message := ""
var _gold: Label
var _body: VBoxContainer
var _nav: Dictionary = {}           # Seite -> Knopf der Seitenleiste
var _badges: Dictionary = {}        # Seite -> Zahl rechts im Knopf (z. B. freie Talentpunkte)


func setup(p: Party, defs: Dictionary, squad_ids: Array, next_mission := {}) -> void:
	party = p
	unit_defs = defs
	squad = squad_ids
	mission = next_mission
	_hero = squad_ids[0] if not squad_ids.is_empty() else ""
	var mer := party.merchant()
	_quip = str((mer["quips"] as Array)[0]) if not mer.is_empty() else ""


## Seite wechseln (auch von aussen, z. B. fuer Bildschirmfotos und Tests).
func show_page(page: String) -> void:
	_page = page
	_pick = -1
	_auto_gear_message = ""
	_refresh()


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# Kopfzeile
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(24, 8, 24, 8), 0.95))
	top.position = Vector2(16, 10)
	top.custom_minimum_size = Vector2(1248, 56)
	top.size = Vector2(1248, 56)
	add_child(top)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 20)
	top.add_child(bar)
	bar.add_child(_label("Lager", UiTheme.F_TITLE, 30, GOLD_COL))
	var next := _label(_mission_line(), UiTheme.F_HEAD, 17, UiTheme.CREAM)
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next.clip_text = true
	bar.add_child(next)
	_gold = _label("", UiTheme.F_HEAD, 20, GOLD_COL)
	bar.add_child(_gold)
	# Seitenleiste
	var rail := PanelContainer.new()
	rail.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(12, 14, 12, 14), 0.95))
	rail.position = Vector2(16, 74)
	rail.custom_minimum_size = Vector2(216, 632)
	rail.size = Vector2(216, 632)
	add_child(rail)
	var nav := VBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	rail.add_child(nav)
	for page: String in PAGES:
		var b := _button(PAGE_NAMES[page], func() -> void: show_page(page), Vector2(192, 42))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var badge := _label("", UiTheme.F_HEAD, 14, GOLD_COL)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.position = Vector2(118, 10)
		badge.size = Vector2(62, 22)
		b.add_child(badge)
		nav.add_child(b)
		_nav[page] = b
		_badges[page] = badge
	(_nav["haendler"] as Button).visible = not party.merchant().is_empty()      # kein Haendler im Lager (Sack ist entfuehrt)
	(_nav["aufstellung"] as Button).visible = not mission.is_empty()
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_child(gap)
	var go := _button("Aufbrechen", func() -> void:
		closed.emit()
		queue_free(), Vector2(192, 48))
	go.add_theme_font_size_override("font_size", 19)
	go.tooltip_text = "Weiter zum nächsten Kapitel"
	nav.add_child(go)
	# Inhalt
	var content := PanelContainer.new()
	content.add_theme_stylebox_override("panel", UiTheme.box("panel_dark_s.png", 24, Vector4(22, 16, 22, 16), 0.95))
	content.position = Vector2(240, 74)
	content.custom_minimum_size = Vector2(1024, 632)
	content.size = Vector2(1024, 632)
	content.clip_contents = true
	add_child(content)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	content.add_child(_body)
	_refresh()


func _mission_line() -> String:
	if mission.is_empty():
		return ""
	return "Als Nächstes:  " + str(mission.get("title", ""))


# ------------------------------------------------------------------ Bausteine

func _label(text: String, font: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	return l


## Textzeile; mit width > 0 bricht sie um (feste Breite, sonst kollabiert ein umbrechendes Label).
func _text(text: String, size := 20, color := UiTheme.CREAM, width := 0) -> Label:
	var l := _label(text, UiTheme.F_BODY, size, color)
	if width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(width, 0)
	return l


func _button(text: String, cb: Callable, min_size := Vector2(150, 32)) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 16)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, UiTheme.soft_button(st))
	b.pressed.connect(cb)
	return b


## Flache Karte fuer Abschnitte innerhalb einer Seite.
func _flat(bg := Color(0.09, 0.1, 0.17, 0.85), border := Color(0.55, 0.45, 0.25, 0.7)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	return sb


func _card(min_size := Vector2.ZERO) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _flat())
	p.custom_minimum_size = min_size
	return p


## Klickbare Karte mit freiem Inhalt: der Inhalt liegt als Kind im Knopf und laesst Klicks durch.
func _card_button(min_size: Vector2, cb: Callable, inner: Control) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = min_size
	var normal := _flat()
	var hover := _flat(Color(0.16, 0.17, 0.28, 0.95), Color(1.0, 0.83, 0.42, 0.95))
	var off := _flat(Color(0.2, 0.17, 0.1, 0.95), Color(1.0, 0.83, 0.42, 1.0))
	off.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", off)
	b.pressed.connect(cb)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.position = Vector2(6, 4)
	inner.size = min_size - Vector2(12, 8)
	b.add_child(inner)
	_ignore_mouse(inner)
	return b


func _ignore_mouse(node: Node) -> void:
	for c in node.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _portrait_path(id: String) -> String:
	var pid := str((unit_defs.get(id, {}) as Dictionary).get("portrait", id))
	for path: String in ["res://assets/portraits/%s.png" % pid, "res://assets/portraits/%s.png" % id, "res://assets/tokens/%s.png" % id]:
		if ResourceLoader.exists(path):
			return path
	return ""


func _portrait(id: String, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var path := _portrait_path(id)
	if path != "":
		t.texture = load(path)
	t.custom_minimum_size = size
	return t


func _section(text: String) -> Label:
	return _label(text, UiTheme.F_HEAD, 16, GOLD_COL)


func _reward_text(r: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(r.get("gold", 0)) > 0:
		parts.append("%d Gold" % int(r["gold"]))
	for id: String in r.get("items", {}):
		parts.append("%s ×%d" % [Items.item_name(id), int(r["items"][id])])
	for id: String in r.get("equipment", []):
		parts.append(Items.item_name(id))
	return ", ".join(parts)


func _inventory_text() -> String:
	var inv: PackedStringArray = []
	for id: String in party.inventory:
		if int(party.inventory[id]) > 0:
			inv.append("%s ×%d" % [Items.item_name(id), int(party.inventory[id])])
	return ", ".join(inv) if not inv.is_empty() else "leer"


## Helden der Gruppe mit freien Talentpunkten.
func _heroes_with_points() -> Array:
	return squad.filter(func(id: String) -> bool: return unit_defs.has(id) and unit_defs[id].get("hero", false) and party.points(id) > 0)


## [leere Plaetze, davon mit passendem Stueck im Lager] ueber die ganze Gruppe.
func _open_slots() -> Array:
	var empty := 0
	var fillable := 0
	for id: String in squad:
		if not unit_defs.has(id) or not unit_defs[id].get("hero", false):
			continue
		for slot: String in SLOTS:
			if party.worn_in(id, slot) != "":
				continue
			empty += 1
	if empty > 0 and not party.pool.is_empty():      # so viele Plaetze wuerde "Automatisch ausruesten" jetzt fuellen (an einer Kopie probiert)
		fillable = Party.from_dict(party.to_dict()).auto_equip(squad, unit_defs)
	return [empty, fillable]


func _secret_list() -> Array:
	var out: Array = []
	for sec: Dictionary in (JSON.parse_string(FileAccess.get_file_as_string("res://data/secrets.json")) as Dictionary)["secrets"]:
		if sec.has("trigger"):      # reine Ideen sind im Spiel nicht aktiv
			out.append(sec)
	return out


func _refresh() -> void:
	if _body == null:
		return
	if not (_nav[_page] as Button).visible:
		_page = "uebersicht"
	for page: String in _nav:
		(_nav[page] as Button).disabled = page == _page
	_gold.text = "%d Gold" % party.gold
	var pts := 0
	for id: String in _heroes_with_points():
		pts += party.points(id)
	(_badges["talente"] as Label).text = str(pts) if pts > 0 else ""
	var open := _open_slots()
	(_badges["ausruestung"] as Label).text = str(open[1]) if int(open[1]) > 0 else ""
	var secs := _secret_list()
	var seen := secs.filter(func(s: Dictionary) -> bool: return party.secrets_seen.has(s["id"])).size()
	(_badges["geheimnisse"] as Label).text = "%d/%d" % [seen, secs.size()]
	_clear(_body)
	match _page:
		"uebersicht":
			_build_overview()
		"haendler":
			_build_shop()
		"ausruestung":
			_build_gear()
		"aufstellung":
			_build_squad()
		"talente":
			_build_talents()
		"geheimnisse":
			_build_secrets()


# ------------------------------------------------------------------ Uebersicht

func _build_overview() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)
	# links: die naechste Mission
	var left := _card(Vector2(560, 0))
	row.add_child(left)
	var lc := VBoxContainer.new()
	lc.add_theme_constant_override("separation", 6)
	left.add_child(lc)
	if mission.is_empty():
		lc.add_child(_section("Rast"))
		lc.add_child(_text("Die Gruppe ruht sich aus. Rüstet eure Helden aus und verteilt Talentpunkte.", 19, UiTheme.CREAM, 530))
	else:
		lc.add_child(_section("Nächste Mission"))
		var title := _label(str(mission.get("title", "")), UiTheme.F_HEAD, 22, UiTheme.CREAM)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.custom_minimum_size = Vector2(530, 0)
		lc.add_child(title)
		var brief := str(mission.get("briefing", ""))
		if brief != "":
			lc.add_child(_text(brief, 17, Color(0.88, 0.86, 0.78), 530))
		var objs: Array = mission.get("objectives", [])
		if not objs.is_empty():
			lc.add_child(_section("Bonusziele"))
			for o: Dictionary in objs:
				var rew := _reward_text(o.get("reward", {}))
				lc.add_child(_text("– %s%s" % [o["text"], ("   (" + rew + ")") if rew != "" else ""], 17, UiTheme.CREAM, 530))
	# rechts: was vor dem Aufbruch noch offen ist
	var right := _card(Vector2(400, 0))
	row.add_child(right)
	var rc := VBoxContainer.new()
	rc.add_theme_constant_override("separation", 9)
	right.add_child(rc)
	rc.add_child(_section("Vor dem Aufbruch"))
	var with_points := _heroes_with_points()
	if with_points.is_empty():
		rc.add_child(_todo(true, "Alle Talentpunkte sind verteilt."))
	else:
		var n := 0
		for id: String in with_points:
			n += party.points(id)
		rc.add_child(_todo(false, "%d %s frei (%d %s)" % [n, "Talentpunkt" if n == 1 else "Talentpunkte", with_points.size(), "Held" if with_points.size() == 1 else "Helden"],
			"Verteilen", func() -> void: show_page("talente")))
	var open := _open_slots()
	if int(open[0]) == 0:
		rc.add_child(_todo(true, "Alle Helden sind voll ausgerüstet."))
	elif int(open[1]) > 0:
		rc.add_child(_todo(false, "%d %s leer, %d davon lassen sich aus dem Lager füllen." % [int(open[0]), "Platz" if int(open[0]) == 1 else "Plätze", int(open[1])], "Ausrüsten", func() -> void:
			party.auto_equip(squad, unit_defs)
			_refresh()))
	else:
		rc.add_child(_todo(true, "%d %s leer, nichts Passendes im Lager." % [int(open[0]), "Platz" if int(open[0]) == 1 else "Plätze"], "Ansehen", func() -> void: show_page("ausruestung")))
	var mer := party.merchant()
	if mer.is_empty():
		rc.add_child(_todo(true, "Kein Händler im Lager."))
	else:
		var can := party.stock().filter(func(w: Dictionary) -> bool: return party.can_buy(w["id"])).size()
		rc.add_child(_todo(can == 0, "%s: %d %s kannst du dir leisten." % [mer["name"], can, "Ware" if can == 1 else "Waren"] if can > 0 else "%s: Für nichts reicht das Gold." % mer["name"],
			"Einkaufen", func() -> void: show_page("haendler")))
	if not mission.is_empty():
		var fixed: Array = Mission.dialogue_ids(mission["id"])
		var free := squad.filter(func(id: String) -> bool: return not fixed.has(id)).size()
		if free > 0:
			rc.add_child(_todo(true, "%d %s der Gruppe frei wählbar." % [free, "Platz" if free == 1 else "Plätze"], "Aufstellung", func() -> void: show_page("aufstellung")))
	rc.add_child(_section("Rucksack"))
	rc.add_child(_text(_inventory_text(), 17, UiTheme.CREAM, 370))
	# unten: die Gruppe
	_body.add_child(_section("Eure Gruppe  (Klick: Ausrüstung)"))
	_body.add_child(_hero_strip("", func(id: String) -> void:
		_hero = id
		show_page("ausruestung")))


## Zeile der Liste "Vor dem Aufbruch": Punkt (gruen = erledigt, orange = offen), Text, optional ein Knopf dorthin.
func _todo(done: bool, text: String, action := "", cb := Callable()) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(14, 24)
	var dot := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = OK_COL if done else TODO_COL
	sb.set_corner_radius_all(6)
	dot.add_theme_stylebox_override("panel", sb)
	dot.custom_minimum_size = Vector2(12, 12)
	holder.add_child(dot)
	line.add_child(holder)
	var t := _text(text, 17, DIM_COL if done else UiTheme.CREAM, 216)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(t)
	if action != "":
		line.add_child(_button(action, cb, Vector2(124, 30)))
	return line


## Leiste mit den Helden der Gruppe: Bild, Name, drei Punkte fuer Waffe, Ruestung und Talisman (gold = belegt), freie Talentpunkte.
func _hero_strip(current: String, cb: Callable) -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 8)
	var w := clampi((BODY_W - 8 * (squad.size() - 1)) / maxi(1, squad.size()), 110, 190)
	for id: String in squad:
		var inner := HBoxContainer.new()
		inner.add_theme_constant_override("separation", 6)
		inner.add_child(_portrait(id, Vector2(46, 56)))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := _label(unit_defs[id]["name"], UiTheme.F_HEAD, 11, GOLD_COL if id == current else UiTheme.CREAM)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.add_theme_constant_override("line_spacing", -3)
		nm.custom_minimum_size = Vector2(w - 70, 0)
		col.add_child(nm)
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 4)
		for slot: String in SLOTS:
			var pip := Panel.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = GOLD_COL if party.worn_in(id, slot) != "" else Color(0.25, 0.25, 0.32)
			sb.set_corner_radius_all(2)
			pip.add_theme_stylebox_override("panel", sb)
			pip.custom_minimum_size = Vector2(12, 8)
			pips.add_child(pip)
		var pts := party.points(id) if unit_defs[id].get("hero", false) else 0
		if pts > 0:
			pips.add_child(_label("+%d" % pts, UiTheme.F_HEAD, 11, Color(0.7, 0.95, 1.0)))
		col.add_child(pips)
		inner.add_child(col)
		var b := _card_button(Vector2(w, 64), func() -> void: cb.call(id), inner)
		b.disabled = id == current
		b.tooltip_text = "%s: Punkte = Waffe, Rüstung, Talisman" % unit_defs[id]["name"]
		strip.add_child(b)
	return strip


# ------------------------------------------------------------------ Haendler

func _group_of(id: String) -> String:
	if Items.consumables().has(id):
		return "Verbrauch"
	return {"waffe": "Waffen", "ruestung": "Rüstungen", "talisman": "Talismane"}.get(str(Items.equipment()[id]["slot"]), "Talismane")


## So viele Stuecke dieser Sorte besitzt die Gruppe schon (Rucksack bzw. Lager und getragen).
func _owned(id: String) -> int:
	if Items.consumables().has(id):
		return int(party.inventory.get(id, 0))
	var n := party.pool.count(id)
	for hero: String in party.equipment:
		n += (party.equipment[hero] as Array).count(id)
	return n


func _build_shop() -> void:
	var mer := party.merchant()
	if mer.is_empty():
		_body.add_child(_text("Kein Händler im Lager.", 20))
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.add_child(_portrait(str(mer["portrait"]), Vector2(220, 240)))
	var nm := _label(str(mer["name"]) + " (Händler)", UiTheme.F_HEAD, 18, GOLD_COL)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(nm)
	left.add_child(_text("„%s“" % _quip, 17, Color(0.9, 0.95, 0.8), 220))
	left.add_child(_section("Rucksack"))
	left.add_child(_text(_inventory_text(), 16, UiTheme.CREAM, 220))
	row.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var mode := HBoxContainer.new()
	mode.add_theme_constant_override("separation", 8)
	right.add_child(mode)
	var buy_tab := _button("Kaufen", func() -> void:
		_sell = false
		_refresh(), Vector2(150, 32))
	buy_tab.disabled = not _sell
	mode.add_child(buy_tab)
	var sell_tab := _button("Verkaufen (%d)" % party.pool.size(), func() -> void:
		_sell = true
		_refresh(), Vector2(190, 32))
	sell_tab.disabled = _sell
	mode.add_child(sell_tab)
	mode.add_child(_text("Halber Preis, nur Stücke aus dem Lager." if _sell else "Begrenzter Vorrat, im nächsten Lager wieder voll.", 15, DIM_COL))
	var sc := ScrollContainer.new()      # das Sortiment waechst mit den Kapiteln: scrollbar statt endloser Seite
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	if _sell:
		_fill_sell(list)
		return
	var stock := party.stock()
	for group: String in GROUPS:
		var wares := stock.filter(func(w: Dictionary) -> bool: return _group_of(w["id"]) == group)
		if wares.is_empty():
			continue
		list.add_child(_section(group))
		for w: Dictionary in wares:
			var id: String = w["id"]
			var item: Dictionary = Items.consumables().get(id, Items.equipment().get(id, {}))
			var owned := _owned(id)
			var state := "Kaufen"
			if int(w["left"]) <= 0:
				state = "Ausverkauft"
			elif not party.can_afford(int(w["price"])):
				state = "Zu teuer"
			var note := "noch %d da" % int(w["left"]) if int(w["left"]) > 0 else "ausverkauft"
			if owned > 0:
				note += ", du hast %d" % owned
			list.add_child(_ware_row(str(item["name"]), str(item.get("text", "")), note, int(w["price"]), state, func() -> void:
				if party.buy(id):
					_quip = str((mer["quips"] as Array)[randi() % (mer["quips"] as Array).size()])
				_refresh(), party.can_buy(id)))


func _fill_sell(list: VBoxContainer) -> void:
	var kinds := {}          # Lagerbestand verkaufen (halber Preis): eine Zeile je Sorte
	for pid: String in party.pool:
		kinds[pid] = int(kinds.get(pid, 0)) + 1
	if kinds.is_empty():
		list.add_child(_text("Im Lager liegt nichts. Getragene Ausrüstung zuerst unter „Ausrüstung“ ablegen.", 18, DIM_COL, 640))
		return
	for pid: String in kinds:
		var it: Dictionary = Items.equipment()[pid]
		list.add_child(_ware_row("%s ×%d" % [it["name"], kinds[pid]], str(it.get("text", "")), "im Lager", Party.sell_price(pid), "Verkaufen", func() -> void:
			party.sell(pid)
			_refresh(), true))


## Zeile einer Ware: Name und Wirkung, Hinweis (Vorrat, Besitz), Preis, Knopf.
func _ware_row(title: String, effect: String, note: String, price: int, action: String, cb: Callable, enabled: bool) -> Control:
	var card := PanelContainer.new()
	var sb := _flat(Color(0.09, 0.1, 0.17, 0.6), Color(0.55, 0.45, 0.25, 0.35))
	sb.content_margin_top = 4
	sb.content_margin_bottom = 5
	card.add_theme_stylebox_override("panel", sb)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	card.add_child(line)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(_text(title, 19, UiTheme.CREAM if enabled else DIM_COL))
	info.add_child(_text(effect, 15, DIM_COL, 300))
	line.add_child(info)
	var nt := _text(note, 15, DIM_COL)
	nt.custom_minimum_size = Vector2(150, 0)
	nt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(nt)
	var pr := _text("%d Gold" % price, 19, GOLD_COL if enabled or action == "Ausverkauft" else Color(0.95, 0.5, 0.45))
	pr.custom_minimum_size = Vector2(84, 0)
	pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(pr)
	var b := _button(action, cb, Vector2(136, 30))
	b.disabled = not enabled
	line.add_child(b)
	return card


# ------------------------------------------------------------------ Talente

## Talentpunkte verteilen (nur fuer Helden der naechsten Mission; wer nicht dabei ist, wird erst aufgelevelt, wenn er in der Gruppe ist).
func _build_talents() -> void:
	var tp := TalentPanel.new()
	tp.setup(party, unit_defs, squad)
	tp.text_w = 500
	tp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(tp)
	tp.changed.connect(_refresh_badges)


func _refresh_badges() -> void:
	var pts := 0
	for id: String in _heroes_with_points():
		pts += party.points(id)
	(_badges["talente"] as Label).text = str(pts) if pts > 0 else ""


# ------------------------------------------------------------------ Ausruestung

func _effective(hero: String) -> String:
	var d: Dictionary = unit_defs[hero]
	var u := {"atk": d["atk"], "def": d["def"], "res": d.get("res", 0), "hp": d["hp"], "maxhp": d["hp"], "move": d["move"],
		"range": d["range"], "dmg_type": d.get("dmg_type", "body")}
	var tl := party.ranks(hero)
	u["maxhp"] += Talents.hp_bonus(tl)
	u["hp"] += Talents.hp_bonus(tl)
	u["atk"] += Talents.atk_bonus(tl)
	Items.apply_equipment(u, party.equipment.get(hero, []))
	return "Leben %d   Angriff %d   Vert %d   Res %d   Bew %d   Reichweite %d" % [u["maxhp"], u["atk"], u["def"], u["res"], u["move"], u["range"]]


func _build_gear() -> void:
	if _hero == "" or not squad.has(_hero):
		_hero = squad[0] if not squad.is_empty() else ""
	if _hero == "":
		return
	_body.add_child(_hero_strip(_hero, func(id: String) -> void:
		_hero = id
		_auto_gear_message = ""
		_refresh()))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)
	row.add_child(_portrait(_hero, Vector2(170, 230)))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	right.add_child(head)
	var nm := _label(unit_defs[_hero]["name"], UiTheme.F_HEAD, 22, GOLD_COL)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	head.add_child(_button("Automatisch ausrüsten", func() -> void:
		var count := party.auto_equip(squad, unit_defs)
		_auto_gear_message = ("%d %s ausgerüstet." % [count, "freier Platz" if count == 1 else "freie Plätze"]) if count > 0 else "Keine passenden Gegenstände für freie Plätze im Lager."
		_refresh(), Vector2(230, 32)))
	right.add_child(_text(_effective(_hero), 18, Color(0.9, 0.9, 0.8)))
	right.add_child(_text(_auto_gear_message if _auto_gear_message != "" else "Links das getragene Stück, darunter alles Passende aus dem Lager. Ein Klick legt es an.", 15, OK_COL if _auto_gear_message != "" else DIM_COL))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(cols)
	for slot: String in SLOTS:
		cols.add_child(_slot_column(slot))


## Spalte eines Ausruestungsplatzes: oben das getragene Stueck (Klick legt es ab), darunter die Stuecke aus dem Lager.
func _slot_column(slot: String) -> Control:
	var card := _card(Vector2(254, 0))
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	card.add_child(col)
	col.add_child(_section(SLOTS[slot]))
	var d: Dictionary = unit_defs[_hero]
	var cur := party.worn_in(_hero, slot)
	if cur != "":
		var it: Dictionary = Items.equipment()[cur]
		col.add_child(_text(str(it["name"]), 19, UiTheme.CREAM, 228))
		col.add_child(_text(str(it["text"]), 15, OK_COL, 228))
		col.add_child(_button("Ablegen", func() -> void:
			party.unequip(_hero, slot)
			_auto_gear_message = ""
			_refresh(), Vector2(120, 28)))
	else:
		col.add_child(_text("– leer –", 19, DIM_COL, 228))
	col.add_child(_text("Im Lager", 14, DIM_COL))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	sc.add_child(list)
	var kinds := {}
	for id: String in party.pool:
		if Items.equipment()[id]["slot"] == slot:
			kinds[id] = int(kinds.get(id, 0)) + 1
	var ids: Array = kinds.keys()
	var wearable := func(id: String) -> bool:
		return Items.can_equip({"dmg_type": d.get("dmg_type", "body"), "range": int(d.get("range", 1))}, id)
	ids.sort_custom(func(a: String, b: String) -> bool:      # Tragbares zuerst, dann die hoehere Stufe
		if wearable.call(a) != wearable.call(b):
			return wearable.call(a)
		return int(Items.equipment()[a].get("tier", 1)) > int(Items.equipment()[b].get("tier", 1)))
	for id: String in ids:
		var it: Dictionary = Items.equipment()[id]
		var ok: bool = wearable.call(id)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 0)
		inner.add_child(_text("%s%s" % [it["name"], " ×%d" % kinds[id] if int(kinds[id]) > 1 else ""], 16, UiTheme.CREAM if ok else DIM_COL))
		var sub := _text(str(it["text"]) if ok else "nicht tragbar", 13, DIM_COL)
		sub.clip_text = true
		sub.custom_minimum_size = Vector2(206, 0)
		inner.add_child(sub)
		var b := _card_button(Vector2(222, 46), func() -> void:
			party.equip(_hero, id, d)
			_auto_gear_message = ""
			_refresh(), inner)
		b.tooltip_text = "%s: %s" % [it["name"], it["text"]]
		if not ok:
			b.disabled = true
			b.add_theme_stylebox_override("disabled", _flat(Color(0.08, 0.08, 0.1, 0.6), Color(0.3, 0.3, 0.3, 0.5)))
		list.add_child(b)
	if ids.is_empty():
		list.add_child(_text("Nichts für diesen Platz. Beim Händler oder in Truhen finden.", 15, DIM_COL, 216))
	return card


# ------------------------------------------------------------------ Aufstellung

func _build_squad() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_body.add_child(col)
	var fixed: Array = Mission.dialogue_ids(mission["id"]) if not mission.is_empty() else squad
	col.add_child(_text("Diese Helden ziehen ins nächste Kapitel. Wer im Kapitel spricht (fest), muss mit; alle anderen lassen sich tauschen. Ausrüstung von Zurückbleibenden wandert ins Lager.", 18, DIM_COL, BODY_W - 20))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	col.add_child(grid)
	var w := clampi((BODY_W - 10 * (squad.size() - 1)) / maxi(1, squad.size()), 110, 154)
	for i in squad.size():
		var id: String = squad[i]
		var card := VBoxContainer.new()
		card.add_child(_portrait(id, Vector2(w, 170)))
		var nm := _label(unit_defs[id]["name"], UiTheme.F_HEAD, 13, GOLD_COL)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.add_theme_constant_override("line_spacing", -3)
		nm.custom_minimum_size = Vector2(w, 34)
		card.add_child(nm)
		var gear: PackedStringArray = []
		for g: String in party.equipment.get(id, []):
			gear.append(Items.item_name(g))
		var gt := _text(", ".join(gear) if not gear.is_empty() else "ohne Ausrüstung", 14, Color(0.85, 0.85, 0.8), w)
		gt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gt.custom_minimum_size = Vector2(w, 50)
		card.add_child(gt)
		if not mission.is_empty():
			var locked: bool = fixed.has(id)
			var sw := _button("fest" if locked else ("Abbrechen" if _pick == i else "Tauschen"), func() -> void:
				_pick = -1 if _pick == i else i
				_refresh(), Vector2(w, 30))
			sw.disabled = locked
			card.add_child(sw)
		grid.add_child(card)
	if _pick >= 0:
		var no := int(str(mission["id"]).substr(2))
		col.add_child(_section("Ersatz für %s" % unit_defs[squad[_pick]]["name"]))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 8)
		row.add_theme_constant_override("v_separation", 6)
		col.add_child(row)
		for id: String in Party.roster(unit_defs, no, false, party.recruited):
			if squad.has(id):
				continue
			row.add_child(_button(unit_defs[id]["name"], func() -> void:
				if party.set_squad_member(mission, _pick, id):
					squad = party.squad_for(mission)
					_hero = squad[0]
				_pick = -1
				_refresh(), Vector2(210, 32)))


# ------------------------------------------------------------------ Geheimnisse

## Album der geheimen Interaktionen: entdeckte mit den Beteiligten in Farbe und der Wirkung, unentdeckte als Schattenriss mit einem Geruecht.
## Die Texte stehen in data/secret_hints.json. Geheimnisse bleiben ausserhalb des Balancings, das Album soll nur neugierig machen.
func _build_secrets() -> void:
	var secs := _secret_list()
	var hints: Dictionary = {}
	if FileAccess.file_exists("res://data/secret_hints.json"):
		hints = JSON.parse_string(FileAccess.get_file_as_string("res://data/secret_hints.json"))
	var seen := secs.filter(func(s: Dictionary) -> bool: return party.secrets_seen.has(s["id"])).size()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	_body.add_child(head)
	head.add_child(_section("Entdeckt: %d von %d" % [seen, secs.size()]))
	head.add_child(_text("Manche Helden können im Kampf mehr, wenn sie zusammenarbeiten. Die Gerüchte verraten, wo es sich zu probieren lohnt.", 15, DIM_COL))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(grid)
	for sec: Dictionary in secs:
		var known: bool = party.secrets_seen.has(sec["id"])
		var info: Dictionary = hints.get(sec["id"], {})
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _flat(Color(0.14, 0.12, 0.08, 0.9), Color(1.0, 0.83, 0.42, 0.9)) if known else _flat())
		card.custom_minimum_size = Vector2(189, 174)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 3)
		card.add_child(col)
		var faces := HBoxContainer.new()
		faces.alignment = BoxContainer.ALIGNMENT_CENTER
		faces.add_theme_constant_override("separation", 6)
		for cid: String in (sec.get("characters", []) as Array).slice(0, 2):
			var face := _portrait(cid, Vector2(60, 66))
			if not known:
				face.modulate = Color(0.03, 0.03, 0.06)      # Schattenriss
			faces.add_child(face)
		col.add_child(faces)
		var nm := _label(str(sec["name"]) if known else "? ? ?", UiTheme.F_HEAD, 12, GOLD_COL if known else DIM_COL)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.custom_minimum_size = Vector2(165, 0)
		col.add_child(nm)
		var txt := str(info.get("text" if known else "hint", "Zwei, die sich gut kennen, können gemeinsam mehr." if not known else ""))
		var body := _text(txt, 13, UiTheme.CREAM if known else DIM_COL, 165)
		body.add_theme_constant_override("line_spacing", -2)
		col.add_child(body)
		grid.add_child(card)
