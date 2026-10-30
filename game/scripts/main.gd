extends Node
## Spielablauf Kapitel 1: Titel -> Dialog -> Kampf -> Dialog -> Ende. Alles spielt auf derselben Karte (Stage).

const TITLE_MUSIC := "res://assets/audio/title_theme.mp3"
const BATTLE_MUSIC := "res://assets/audio/battle_theme.mp3"
const CHAPTERS := ["ch1", "ch2", "ch3"]
const MUSIC_DB := -6.0

var units: Dictionary
var story: Dictionary
var map: Dictionary
var stage: Stage
var party: Party
var _music: AudioStreamPlayer


func _load_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _ready() -> void:
	units = _load_json("res://data/units.json")
	story = _load_json("res://data/story_ch1.json")
	map = Mission.load_mission("ch1")
	if OS.get_environment("SHOT") != "":
		_screenshot_mode()
		return
	_run()


func _names() -> Dictionary:
	var n := {}
	for id: String in units:
		n[id] = units[id]["name"]
	return n


func _run() -> void:
	party = Party.new_game()
	stage = Stage.new()
	stage.setup(map, units)
	stage.party = party
	stage.dialogue_runner = _battle_dialogue
	add_child(stage)
	_play_music(TITLE_MUSIC)
	await _title()
	var pick: Array = await _choose_level()
	for i in range(int(pick[0]), CHAPTERS.size()):
		party.chapter = i + 1
		await _chapter(CHAPTERS[i], bool(pick[1]) and i == int(pick[0]))
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var end := Label.new()
	end.theme = UiTheme.get_theme()
	end.text = "Ende von Kapitel 3\n(Prototyp)"
	end.add_theme_font_override("font", UiTheme.font(UiTheme.F_TITLE))
	end.add_theme_font_size_override("font_size", 56)
	end.add_theme_color_override("font_color", UiTheme.GOLD)
	end.add_theme_constant_override("outline_size", 14)
	end.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(end)


## Musik wechseln: der alte Titel blendet aus, der neue blendet ein (fade = 0: sofort).
func _play_music(path: String, fade := 0.0) -> void:
	_fade_music(fade if fade > 0.0 else 0.8)
	var stream: AudioStreamMP3 = load(path)
	stream.loop = true
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -50.0 if fade > 0.0 else MUSIC_DB
	add_child(p)
	p.play()
	_music = p
	if fade > 0.0:
		create_tween().tween_property(p, "volume_db", MUSIC_DB, fade)


func _fade_music(seconds := 2.5) -> void:
	if _music == null or not is_instance_valid(_music):
		return
	var old := _music
	_music = null
	var tw := create_tween()
	tw.tween_property(old, "volume_db", -50.0, seconds)
	tw.tween_callback(old.queue_free)


func _title() -> void:
	var t := TitleScreen.new()
	add_child(t)
	t.fading_out.connect(func() -> void: _fade_music())
	await t.started
	t.queue_free()


## Ein Kapitel: Einleitung, Kampf (bei Niederlage neuer Versuch), Belohnung, Abschluss, Lager.
## Kapitelwahl (Testmenue). Rueckgabe: [Index, Einleitung ueberspringen].
func _choose_level() -> Array:
	var list: Array = []
	for cid: String in CHAPTERS:
		list.append({"id": cid, "title": Mission.load_mission(cid)["title"]})
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var ls := LevelSelect.new()
	ls.setup(list)
	layer.add_child(ls)
	var res: Array = await ls.chosen
	layer.queue_free()
	return res


func _chapter(cid: String, skip_intro := false) -> void:
	var m := Mission.load_mission(cid)
	var story_c := _load_json("res://data/story_%s.json" % cid)
	if stage.map_data.get("id", "") != cid:
		stage.map_data = m
		stage.new_battle()
	stage.set_mode("dialog")
	if not skip_intro:
		await _dialogue(story_c["intro"])
	_play_music(BATTLE_MUSIC, 2.5)
	while true:
		await stage.start_battle()
		var won: bool = await stage.battle.finished
		if won:
			break
		stage.new_battle()   # Niederlage: neuer Versuch auf frischem Schlachtfeld
	_fade_music(3.0)
	stage.backdrop_again()
	var res := stage.battle.results()
	await _reward(res)
	party.absorb(res)
	party.save()
	await _dialogue(story_c["outro"])
	await _camp(m)
	party.save()


func _camp(m: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var squad: Array = []
	for e: Dictionary in m["players"]:
		squad.append(e["id"])
	var c := Camp.new()
	c.setup(party, units, squad)
	layer.add_child(c)
	await c.closed
	layer.queue_free()


func _reward(res: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var r := RewardScreen.new()
	r.setup(res)
	layer.add_child(r)
	await r.closed
	layer.queue_free()


## Dialog mitten im Kampf: ueber der abgedunkelten Karte, ohne die Buehne zu wechseln.
func _battle_dialogue(lines: Array) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var d := Dialogue.new()
	d.setup(lines, _names())
	layer.add_child(d)
	await d.finished
	layer.queue_free()


func _dialogue(lines: Array) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var d := Dialogue.new()
	d.setup(lines, _names())
	layer.add_child(d)
	await d.finished
	layer.queue_free()


## SHOT=<modus> SHOT_OUT=<png>: Screenshot nach kurzer Wartezeit, dann beenden (Entwicklungshilfe).
func _screenshot_mode() -> void:
	var mode := OS.get_environment("SHOT")
	if mode == "trailer":   # Aufnahme: siehe tools/make_trailer.sh
		var tr := Trailer.new()
		tr.setup(map, units)
		add_child(tr)
		return
	if mode == "flow":  # Ablauf-Test: Titel -> (simulierter Tastendruck) -> Dialog
		_run()
		await get_tree().create_timer(5.0).timeout
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = KEY_ENTER
		Input.parse_input_event(ev)
		await get_tree().create_timer(3.0).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "title" or mode == "dialog":
		stage = Stage.new()
		stage.setup(map, units)
		add_child(stage)
		if mode == "title":
			add_child(TitleScreen.new())
		else:
			stage.set_mode("dialog")
			var layer := CanvasLayer.new()
			layer.layer = 2
			add_child(layer)
			var d := Dialogue.new()
			d.setup(story["intro"].slice(int(OS.get_environment("SHOT_LINE"))), _names())
			layer.add_child(d)
		var delay := OS.get_environment("SHOT_DELAY")
		await get_tree().create_timer(float(delay) if delay != "" else 6.0).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "itemmenu" or mode == "itemtarget":   # Gegenstandsmenue bzw. Zielwahl mit Rucksack
		var bi := Battle.new()
		bi.setup(map, units)
		bi.loadout = Items.defs()["loadout_chapter1"]
		add_child(bi)
		await get_tree().process_frame
		var hero_i: Dictionary = bi.unit_at(Vector2i(2, 8))
		var friend: Dictionary = bi.unit_at(Vector2i(1, 8))
		friend["hp"] = 9
		Status.add(friend, "poison", 3)
		bi._refresh_unit(friend)
		bi._select(hero_i)
		await bi._move_player(Vector2i(2, 8))
		bi._enter_action(false, true)
		if mode == "itemtarget":
			bi._begin_item("heiltrank")
			bi._hover(Vector2i(1, 8))
		for i in 30:
			await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "reward":   # Belohnungsbildschirm vor der Karte
		var br := Battle.new()
		br.setup(map, units)
		add_child(br)
		await get_tree().process_frame
		br.enter_title_mode()
		var rl := CanvasLayer.new()
		rl.layer = 6
		add_child(rl)
		var rs := RewardScreen.new()
		rs.setup({"gold": 205, "items": {"heiltrank": 1, "gegengift": 1, "aether": 1}, "materials": {"kraut": 3, "hopfen": 1}, "equipment": [],
			"objectives": [{"id": "a", "text": "Kein Held fällt", "done": true, "reward": {"gold": 60}}, {"id": "b", "text": "In 6 Runden gewonnen", "done": false, "reward": {}}]})
		rl.add_child(rs)
		for i in 40:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "camp":   # Lager: SHOT_TAB=0..3, SHOT_GOLD=n
		var bc := Battle.new()
		bc.setup(map, units)
		add_child(bc)
		await get_tree().process_frame
		bc.enter_title_mode()
		var pc := Party.new_game()
		pc.gold = int(OS.get_environment("SHOT_GOLD")) if OS.get_environment("SHOT_GOLD") != "" else 205
		pc.materials = {"kraut": 3, "hopfen": 1, "kristall": 2}
		pc.pool = ["eisenschwert", "schwere_axt", "plattenpanzer", "rubinring"]
		var sq: Array = []
		for e: Dictionary in map["players"]:
			sq.append(e["id"])
		var cl := CanvasLayer.new()
		cl.layer = 6
		add_child(cl)
		var cp := Camp.new()
		cp.setup(pc, units, sq)
		cl.add_child(cp)
		cp._tab = int(OS.get_environment("SHOT_TAB"))
		if cp._tab == 2:
			cp._hero = "braumeisterin"
			cp._slot = "waffe"
		cp._refresh()
		for i in 40:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "midtalk":   # Dialog mitten im Kampf (Ausloeser Runde 3), mit Zielanzeige
		var st := Stage.new()
		st.setup(map, units)
		st.dialogue_runner = _battle_dialogue
		add_child(st)
		await get_tree().process_frame
		await st.start_battle()
		var bt := st.battle
		bt.turn = 3
		bt._run_triggers("turn", 3)
		for i in 120:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode.begins_with("hohlweg"):   # Mission 2: hohlweg | hohlweg_target | hohlweg_after
		var bh := Battle.new()
		bh.setup(Mission.load_mission("ch2"), units)
		bh.loadout = Items.defs()["loadout_chapter1"]
		add_child(bh)
		await get_tree().process_frame
		if mode == "hohlweg_target":
			var el: Dictionary = bh.unit_at(Vector2i(2, 8))
			bh._select(el)
			await bh._move_player(Vector2i(3, 6))
			bh._begin_ability("kanone")
			bh._hover(Vector2i(3, 4))
		elif mode == "hohlweg_after":
			bh._after_world_change(bh.world.apply(bh.world.at(Vector2i(2, 4)), "break"))
			bh._after_world_change(bh.world.apply(bh.world.at(Vector2i(8, 4)), "break"))
			bh._after_world_change(bh.world.apply(bh.world.by_id("gate1"), "open"))
			await get_tree().create_timer(1.5).timeout
		for i in 40:
			await get_tree().process_frame
		await get_tree().create_timer(1.2).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "ch2flow":   # Kapitelwechsel: Buehne bekommt die Karte von Kapitel 2 und startet den Kampf
		var stg := Stage.new()
		stg.setup(map, units)
		stg.party = Party.new_game()
		stg.dialogue_runner = _battle_dialogue
		add_child(stg)
		await get_tree().process_frame
		stg.map_data = Mission.load_mission("ch2")
		stg.new_battle()
		stg.set_mode("dialog")
		await get_tree().create_timer(1.5).timeout
		await stg.start_battle()
		await get_tree().create_timer(1.0).timeout
		print("Gate: ", stg.battle.world.by_id("gate1")["state"], " Helden: ", stg.battle._count_team("p"), " Gegner: ", stg.battle._count_team("e"))
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "flow2":   # Ablauftest: Titel -> Enter -> Kapitel 2 direkt in den Kampf
		_run()
		await get_tree().create_timer(5.0).timeout
		var ev2 := InputEventKey.new()
		ev2.pressed = true
		ev2.keycode = KEY_ENTER
		Input.parse_input_event(ev2)
		await get_tree().create_timer(3.0).timeout
		var sel_node := get_tree().root.find_children("*", "LevelSelect", true, false)
		print("LevelSelect gefunden: ", sel_node.size())
		(sel_node[0] as LevelSelect).pick(1, true)
		await get_tree().create_timer(6.0).timeout
		print("Karte: ", stage.battle.map_data.get("title", "?"), " | Tor: ", stage.battle.world.by_id("gate1")["state"], " | Kapitel in Party: ", party.chapter)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "clicktest":   # Fenstertest: schaltet ein Linksklick den Dialog weiter?
		var stc := Stage.new()
		stc.setup(map, units)
		add_child(stc)
		stc.set_mode("dialog")
		var lc := CanvasLayer.new()
		lc.layer = 2
		add_child(lc)
		var dc := Dialogue.new()
		dc.setup(story["intro"], _names())
		lc.add_child(dc)
		await get_tree().create_timer(1.5).timeout
		print("Dialog size=", dc.size, " mouse_filter=", dc.mouse_filter, " idx=", dc._idx)
		for n in 4:
			for pressed in [true, false]:
				var ev := InputEventMouseButton.new()
				ev.button_index = MOUSE_BUTTON_LEFT
				ev.pressed = pressed
				ev.position = Vector2(640, 360)
				ev.global_position = Vector2(640, 360)
				Input.parse_input_event(ev)
			await get_tree().create_timer(0.4).timeout
			print("nach Klick ", n + 1, ": idx=", dc._idx, " tippt=", dc._typing)
		get_tree().quit()
		return
	if mode == "clickflow":   # Fenstertest: Titel -> Enter -> Kapitel 1 mit Einleitung -> nur mit Linksklicks durch den Dialog
		_run()
		var click_ev := func() -> void:
			for pressed in [true, false]:
				var e := InputEventMouseButton.new()
				e.button_index = MOUSE_BUTTON_LEFT
				e.pressed = pressed
				e.position = Vector2(640, 300)
				e.global_position = Vector2(640, 300)
				Input.parse_input_event(e)
		await get_tree().create_timer(5.0).timeout
		var ek := InputEventKey.new()
		ek.pressed = true
		ek.keycode = KEY_ENTER
		Input.parse_input_event(ek)
		await get_tree().create_timer(3.0).timeout
		(get_tree().root.find_children("*", "LevelSelect", true, false)[0] as LevelSelect).pick(0, false)
		await get_tree().create_timer(3.5).timeout
		var dlg := get_tree().root.find_children("*", "Dialogue", true, false)
		print("Dialoge gefunden: ", dlg.size())
		var total: int = (dlg[0] as Dialogue).lines.size()
		var clicks := 0
		while is_instance_valid(dlg[0]) and clicks < 40:
			click_ev.call()
			clicks += 1
			await get_tree().create_timer(0.25).timeout
		print("Zeilen: ", total, " Klicks bis Ende: ", clicks, " Dialog beendet: ", not is_instance_valid(dlg[0]) or (dlg[0] as Node).is_queued_for_deletion())
		get_tree().quit()
		return
	if mode == "defendmenu" or mode == "defended":   # Menue mit "Verteidigen" bzw. Figur im Verteidigungszustand
		var bd := Battle.new()
		bd.setup(map, units)
		bd.loadout = Items.defs()["loadout_chapter1"]
		add_child(bd)
		await get_tree().process_frame
		var hd: Dictionary = bd.unit_at(Vector2i(1, 8))
		bd._select(hd)
		await bd._move_player(Vector2i(1, 8))
		if mode == "defended":
			bd._close_menu()
			bd._defend(hd)
			await get_tree().create_timer(1.0).timeout
			bd._hover(Vector2i(1, 8))
		for i in 30:
			await get_tree().process_frame
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode.begins_with("brand"):   # Mission 3: brand | brand_ph (nach 2 Feuerphasen) | brand_wurf (Fasswurf) | brand_ende (Ruinen)
		var bf := Battle.new()
		bf.setup(Mission.load_mission("ch3"), units)
		bf.loadout = Items.defs()["loadout_chapter1"]
		add_child(bf)
		await get_tree().process_frame
		if mode == "brand_ph" or mode == "brand_ende":
			for n in (2 if mode == "brand_ph" else 5):
				await bf._fire_phase()
		if mode == "brand_wurf":
			var bru: Dictionary = bf.unit_at(Vector2i(2, 8))
			bf._select(bru)
			await bf._move_player(Vector2i(3, 6))
			bf._begin_ability("fasswurf")
			bf._hover(Vector2i(4, 4))
		for i in 40:
			await get_tree().process_frame
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "ch3flow":   # Kapitelwechsel nach Kapitel 3: Buehne bekommt die Karte, Feuerphase laeuft
		var s3 := Stage.new()
		s3.setup(map, units)
		s3.party = Party.new_game()
		s3.dialogue_runner = _battle_dialogue
		add_child(s3)
		await get_tree().process_frame
		s3.map_data = Mission.load_mission("ch3")
		s3.new_battle()
		await get_tree().create_timer(1.0).timeout
		await s3.start_battle()
		var b3 := s3.battle
		await b3._end_player_turn()
		var burning := 0
		for o in b3.world.objects:
			if b3.world.is_burning(o):
				burning += 1
		print("Karte: ", b3.map_data.get("title"), " | brennend: ", burning, " | Runde: ", b3.turn, " | Helden: ", b3._count_team("p"), " Gegner: ", b3._count_team("e"))
		get_tree().quit()
		return
	if mode == "mapshot":   # Karte ohne Oberflaeche (z. B. als Hintergrund fuer ein Thumbnail)
		var bm := Battle.new()
		bm.setup(map, units)
		add_child(bm)
		await get_tree().process_frame
		bm.enter_title_mode()
		var f := Vector3(5.5, 0.0, 4.2)
		bm.cam.fov = 34.0
		bm.cam.position = f + Vector3(1.0, 8.5, 8.2)
		bm.cam.look_at(f + Vector3(0, 0.2, 0))
		for i in 40:
			await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "closeup":   # Nahaufnahme einer Kachel: SHOT_TILE="x,y"
		var b0 := Battle.new()
		b0.setup(map, units)
		add_child(b0)
		await get_tree().process_frame
		var tp := OS.get_environment("SHOT_TILE").split(",")
		var c0 := Vector3(float(tp[0]), 0.35, float(tp[1]))
		if OS.get_environment("SHOT_OFFSET") != "":
			b0.cam_home = b0.cam_home
		b0._enter_close_view()
		b0.cam.fov = 30.0
		b0.cam.position = c0 + Vector3(0.5, 2.6, 3.4)
		b0.cam.look_at(c0)
		for i in 40:
			await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "fxstrip":
		await _fx_strip(OS.get_environment("SHOT_ABILITY"))
		get_tree().quit()
		return
	var b := Battle.new()
	b.setup(map, units)
	add_child(b)
	if mode == "select":  # Figur waehlen, Reichweite zeigen
		await get_tree().process_frame
		b._select(b.unit_at(Vector2i(2, 8)))
	if mode == "menu" or mode == "target":  # Aktionsmenue bzw. Zielwahl mit Schadensvorschau
		await get_tree().process_frame
		var hero: Dictionary = b.unit_at(Vector2i(2, 8))
		var foe: Dictionary = b.unit_at(Vector2i(8, 5))
		foe["pos"] = Vector2i(3, 8)
		(foe["node"] as Node3D).position = b.to_world(Vector2i(3, 8))
		b._face_step(foe, Vector2i.RIGHT)
		b._select(hero)
		await b._move_player(Vector2i(2, 8))
		if mode == "target":
			b._begin_targeting("attack")
			b._hover(Vector2i(3, 8))
	if mode == "abmenu" or mode == "abtarget":  # Faehigkeitsmenue bzw. Flaechenvorschau (Verspotten)
		await get_tree().process_frame
		var hero2: Dictionary = b.unit_at(Vector2i(1, 8))
		var foe2: Dictionary = b.unit_at(Vector2i(8, 5))
		foe2["pos"] = Vector2i(3, 6)
		(foe2["node"] as Node3D).position = b.to_world(Vector2i(3, 6))
		b._select(hero2)
		await b._move_player(Vector2i(1, 8))
		if mode == "abmenu":
			b._enter_action(true)
		else:
			b._begin_ability("verspotten")
			b._hover(Vector2i(3, 6))
	if mode == "sim":  # Gegnerphasen durchspielen
		for r in 3:
			await get_tree().create_timer(0.5).timeout
			b._end_player_turn()
			while b.state == Battle.State.BUSY:
				await get_tree().process_frame
	for i in 30:
		await get_tree().process_frame
	await get_tree().create_timer(2.5).timeout
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
	get_tree().quit()


## Aufbau pro Faehigkeit fuer die Bildstreifen: [Wirkende Figur, Ziel, weitere Figuren]
const FX_SCENES := {
	"kanone": {"u": ["elisabeth", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [7, 7]], ["soldat_beritten", "e", [6, 6]]]},
	"verspotten": {"u": ["ritter", "p", [4, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [5, 5]], ["soldat_beritten", "e", [8, 7]]]},
	"knochenwurf": {"u": ["hund", "p", [4, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": []},
	"baerenpranke": {"u": ["maedchen_baer", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": []},
	"schlachtruf": {"u": ["ritter", "p", [4, 7]], "t": "self", "more": [["kungfu", "p", [3, 7]], ["wendy", "p", [5, 6]], ["soldat_infanterie", "e", [8, 7]]]},
	"todeswirbel": {"u": ["samurai", "p", [5, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": [["soldat_infanterie", "e", [5, 6]], ["soldat_beritten", "e", [5, 8]]]},
	"stabsprung": {"u": ["kungfu", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": []},
	"versteck": {"u": ["ninjas", "p", [5, 7]], "t": "self", "more": [["soldat_infanterie", "e", [7, 7]]]},
	"wurf": {"u": ["museklaugust", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": []},
	"roter_laser": {"u": ["robo", "p", [3, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": [["soldat_beritten", "e", [6, 7]], ["kungfu", "p", [4, 7]]]},
	"gruener_laser": {"u": ["robo", "p", [3, 7]], "t": ["ritter", "p", [5, 7], {"hp": 14, "status": ["poison"]}], "more": []},
	"gruppenheilung": {"u": ["wendy", "p", [4, 7]], "t": ["ritter", "p", [5, 7], {"hp": 16}], "more": [["kungfu", "p", [5, 6], {"hp": 8, "status": ["poison"]}], ["samurai", "p", [6, 7], {"hp": 10}]]},
	"polymorph": {"u": ["claude", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": []},
	"giftstachel": {"u": ["bienenmaedchen", "p", [3, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": []},
	"fasswurf": {"u": ["braumeisterin", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": []},
}


## Spielt eine Faehigkeit auf einer kleinen Buehne ab und speichert alle 0,15 s ein Bild nach SHOT_OUT/<id>_NN.png.
func _fx_strip(id: String) -> void:
	var out_dir := OS.get_environment("SHOT_OUT")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var b := Battle.new()
	b.setup(map, units)
	add_child(b)
	await get_tree().process_frame
	for u in b.units.duplicate():
		(u["node"] as Node3D).queue_free()
	b.units.clear()
	var sc: Dictionary = FX_SCENES[id]
	var hero := _fx_spawn(b, sc["u"])
	var tgt: Dictionary = hero if str(sc["t"]) == "self" else _fx_spawn(b, sc["t"])
	for o: Array in sc["more"]:
		_fx_spawn(b, o)
	# Kamera naeher ans Geschehen
	var mid: Vector3 = (b.to_world(hero["pos"]) + b.to_world(tgt["pos"]) + Vector3(0.0, 0.0, 0.0)) * 0.5
	if tgt == hero:
		mid = b.to_world(hero["pos"]) + Vector3(1.2, 0, 0)
	b.cam.fov = 34.0
	b.cam.position = mid + Vector3(0, 5.2, 5.6)
	b.cam.look_at(mid + Vector3(0, 0.4, 0))
	b._enter_close_view()
	for i in 20:
		await get_tree().process_frame
	var done := [false]
	var run := func() -> void:
		await b._run_ability(hero, id, tgt)
		done[0] = true
	run.call()
	var n := 0
	while not done[0] and n < 60:
		get_viewport().get_texture().get_image().save_png("%s/%s_%02d.png" % [out_dir, id, n])
		n += 1
		await get_tree().create_timer(0.15).timeout
	for k in 3:   # Nachspiel
		get_viewport().get_texture().get_image().save_png("%s/%s_%02d.png" % [out_dir, id, n])
		n += 1
		await get_tree().create_timer(0.2).timeout
	print("frames: ", n)


func _fx_spawn(b: Battle, spec: Array) -> Dictionary:
	b._spawn(spec[0], spec[1], Vector2i(spec[2][0], spec[2][1]))
	var u: Dictionary = b.units.back()
	if spec.size() > 3:
		var o: Dictionary = spec[3]
		if o.has("hp"):
			u["hp"] = o["hp"]
		for s: String in o.get("status", []):
			Status.add(u, s, 3)
		b._refresh_unit(u)
	return u
