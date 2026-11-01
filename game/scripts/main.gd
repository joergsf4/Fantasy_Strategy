extends Node
## Spielablauf Kapitel 1: Titel -> Dialog -> Kampf -> Dialog -> Ende. Alles spielt auf derselben Karte (Stage).

const TITLE_MUSIC := "res://assets/audio/title_theme.mp3"
const BATTLE_MUSIC := "res://assets/audio/battle_theme.mp3"
const WIN_MUSIC := "res://assets/audio/sieg_statistik.mp3"
const DEFEAT_MUSIC := "res://assets/audio/niederlage_statistik.mp3"
const CHAPTERS := ["ch1", "ch2", "ch3", "ch4", "ch5", "ch6", "ch7"]
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
	n["waisenkinder"] = "Die Waisenkinder"
	n["mutter"] = "Lieselotte"     # Geisel aus Mission 4 (Platzhaltername), keine Kampfeinheit
	return n


func _run() -> void:
	party = Party.load_from()          # Spielstand fortsetzen, falls vorhanden (entkommene Gegner, Gold, Ausruestung)
	var resumed := party != null and party.chapter > 1
	if party == null:
		party = Party.new_game()
	stage = Stage.new()
	stage.setup(map, units)
	stage.party = party
	stage.dialogue_runner = _battle_dialogue
	stage.secret_runner = _secret_scene
	stage.super_music = _duck_music
	add_child(stage)
	_play_music(TITLE_MUSIC)
	var cheat: bool = await _title(mini(party.chapter, CHAPTERS.size()) if resumed else 0)
	if cheat:
		resumed = false          # Testmenue: die Kapitelwahl bestimmt, wo es weitergeht
	var pick: Array = await _choose_level() if cheat else await _resume_pick(resumed)
	for i in range(int(pick[0]), CHAPTERS.size()):
		party.chapter = i + 1
		var nxt: String = CHAPTERS[i + 1] if i + 1 < CHAPTERS.size() else ""
		await _chapter(CHAPTERS[i], bool(pick[1]) and i == int(pick[0]), nxt)
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var end := Label.new()
	end.theme = UiTheme.get_theme()
	end.text = "Ende von Kapitel %d\n(Prototyp)" % CHAPTERS.size()
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


## Kampfmusik waehrend einer Super-Attacke leiser stellen (on) bzw. wieder auf Normallautstaerke bringen.
func _duck_music(on: bool) -> void:
	if _music == null or not is_instance_valid(_music):
		return
	create_tween().tween_property(_music, "volume_db", -32.0 if on else MUSIC_DB, 0.5)


func _fade_music(seconds := 2.5) -> void:
	if _music == null or not is_instance_valid(_music):
		return
	var old := _music
	_music = null
	var tw := create_tween()
	tw.tween_property(old, "volume_db", -50.0, seconds)
	tw.tween_callback(old.queue_free)


## Hauptmenue. Rueckgabe: true, wenn die Kapitelwahl per Cheat ("brumm") freigeschaltet wurde. N-N im Menue startet ein neues Spiel.
func _title(save_chapter := 0) -> bool:
	var t := TitleScreen.new()
	t.save_chapter = save_chapter
	t.new_game_requested.connect(func() -> void:
		Party.delete_save()
		party = Party.new_game()
		stage.party = party)
	add_child(t)
	t.fading_out.connect(func() -> void: _fade_music())
	await t.started
	var cheat := t.cheat
	t.queue_free()
	return cheat


## Normales Spiel ohne Kapitelwahl: dort weitermachen, wo man aufgehoert hat (nach einem Spielstand erst ins Lager).
func _resume_pick(resumed: bool) -> Array:
	var idx := clampi(party.chapter - 1, 0, CHAPTERS.size() - 1)
	if resumed and idx > 0:
		await _camp(Mission.load_mission(CHAPTERS[idx]))
	return [idx, false]


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
	ls.save_info = party.summary()
	ls.new_game_requested.connect(func() -> void:
		Party.delete_save()
		party = Party.new_game()
		stage.party = party
		ls.save_info = party.summary() + " (neues Spiel)"
		ls.refresh_info())
	layer.add_child(ls)
	var res: Array = await ls.chosen
	layer.queue_free()
	return res


## Mission laden und die vom Spieler gewaehlte Gruppe einsetzen (Plaetze der Karte bleiben, nur die Helden wechseln).
func _mission_with_squad(cid: String) -> Dictionary:
	var m := Mission.load_mission(cid)
	var ids := party.squad_for(m)
	for i in (m["players"] as Array).size():
		m["players"][i]["id"] = ids[i]
	party.release_absent(ids)
	return m


func _chapter(cid: String, skip_intro := false, next_cid := "") -> void:
	var m := _mission_with_squad(cid)
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
		await _reward(stage.battle.defeat_summary())     # Niederlage: Statistik mit trauriger Musik, dann neuer Versuch
		stage.new_battle()                               # frisches Schlachtfeld
		_play_music(BATTLE_MUSIC, 2.0)
	_fade_music(3.0)
	stage.backdrop_again()
	var res := stage.battle.results()
	await _reward(res)
	party.absorb(res)
	party.save()
	await _dialogue(story_c["outro"])
	await _camp(Mission.load_mission(next_cid) if next_cid != "" else m)   # Lager: Gruppe der naechsten Mission waehlen
	party.save()


func _camp(m: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var c := Camp.new()
	c.setup(party, units, party.squad_for(m), m)
	layer.add_child(c)
	await c.closed
	layer.queue_free()


func _reward(res: Dictionary) -> void:
	_play_music(DEFEAT_MUSIC if res.get("defeat", false) else WIN_MUSIC, 1.0)      # froehlich nach dem Sieg, traurig nach der Niederlage
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var r := RewardScreen.new()
	r.setup(res)
	layer.add_child(r)
	await r.closed
	layer.queue_free()
	_fade_music(1.2)


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


## Szene einer geheimen Interaktion (Sonderbild, Banner, Dialog) ueber der abgedunkelten Karte.
func _secret_scene(sec: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var d := SecretScene.new()
	d.setup_secret(sec, _names())
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
	if mode == "trailer3":   # Trailer 3 (ca. 30 Sekunden): tools/make_trailer.sh trailer3
		var tr3 := Trailer3.new()
		tr3.setup(map, units)
		add_child(tr3)
		return
	if mode == "trailer2":   # Trailer 2 (ca. 2 Minuten): tools/make_trailer.sh trailer2
		var tr2 := Trailer2.new()
		tr2.setup(map, units)
		add_child(tr2)
		return
	if mode == "aurora":   # Polarlicht-Shader allein ansehen
		var ar := ColorRect.new()
		ar.set_anchors_preset(Control.PRESET_FULL_RECT)
		var arm := ShaderMaterial.new()
		arm.shader = load("res://shaders/aurora.gdshader")
		ar.material = arm
		add_child(ar)
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
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
	if mode == "secret":   # Szene einer geheimen Interaktion: SHOT_DELAY = Sekunden bis zum Bild (Banner ca. 1,3 s, Dialog ab ca. 3,2 s)
		stage = Stage.new()
		stage.setup(map, units)
		add_child(stage)
		stage.start_battle()
		var sl := CanvasLayer.new()
		sl.layer = 8
		add_child(sl)
		var sdim := ColorRect.new()
		sdim.color = Color(0.02, 0.03, 0.08, 0.5)
		sdim.set_anchors_preset(Control.PRESET_FULL_RECT)
		sl.add_child(sdim)
		var ss := SecretScene.new()
		ss.setup_secret(Secrets.by_id("betrunkener_meister"), _names())
		sl.add_child(ss)
		await get_tree().create_timer(float(OS.get_environment("SHOT_DELAY")) if OS.get_environment("SHOT_DELAY") != "" else 4.0).timeout
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
	if mode == "defeat":   # Niederlage-Bildschirm vor der Karte
		var bd0 := Battle.new()
		bd0.setup(map, units)
		add_child(bd0)
		await get_tree().process_frame
		bd0.enter_title_mode()
		var dl := CanvasLayer.new()
		dl.layer = 6
		add_child(dl)
		var ds := RewardScreen.new()
		ds.setup({"defeat": true, "turns": 5, "objectives": [], "stats": {"rows": [
				{"id": "ritter", "name": "Ser Albrecht", "alive": false, "hp": 0, "maxhp": 34, "dealt": 18, "taken": 34, "healed": 0, "kills": 1, "abs": 1, "bonus": 0},
				{"id": "wendy", "name": "Wendy Wolle", "alive": false, "hp": 0, "maxhp": 18, "dealt": 2, "taken": 18, "healed": 14, "kills": 0, "abs": 2, "bonus": 0}],
				"awards": [{"title": "Prügelknabe", "name": "Ser Albrecht", "text": "34 Schaden eingesteckt"}]}})
		dl.add_child(ds)
		for i in 40:
			await get_tree().process_frame
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
			"objectives": [{"id": "a", "text": "Kein Held fällt", "done": true, "reward": {"gold": 60}}, {"id": "b", "text": "In 6 Runden gewonnen", "done": false, "reward": {}}],
			"turns": 7, "stats": {"rows": [
				{"id": "ritter", "name": "Ser Albrecht", "alive": true, "hp": 12, "maxhp": 34, "dealt": 41, "taken": 22, "healed": 0, "kills": 3, "abs": 2, "bonus": 1},
				{"id": "wendy", "name": "Wendy Wolle", "alive": true, "hp": 18, "maxhp": 18, "dealt": 6, "taken": 3, "healed": 27, "kills": 0, "abs": 4, "bonus": 0},
				{"id": "samurai", "name": "Takeda", "alive": false, "hp": 0, "maxhp": 24, "dealt": 30, "taken": 24, "healed": 0, "kills": 2, "abs": 1, "bonus": 3}],
				"awards": [{"title": "Schlagkräftigster", "name": "Ser Albrecht", "text": "41 Schaden ausgeteilt"}, {"title": "Sanitäter", "name": "Wendy Wolle", "text": "27 Leben geheilt"},
					{"title": "Knapp davongekommen", "name": "Ser Albrecht", "text": "mit 12 von 34 Leben"}]}})
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
		var cm := Mission.load_mission("ch5")
		var sq: Array = pc.squad_for(cm)
		var cl := CanvasLayer.new()
		cl.layer = 6
		add_child(cl)
		var cp := Camp.new()
		cp.setup(pc, units, sq, cm)
		if OS.get_environment("SHOT_PICK") != "":
			cp._pick = int(OS.get_environment("SHOT_PICK"))
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
	if mode == "kap":   # beliebiges Kapitel ansehen: SHOT_CH=ch3
		var bk := Battle.new()
		bk.setup(Mission.load_mission(OS.get_environment("SHOT_CH")), units)
		bk.loadout = Items.defs()["loadout_chapter1"]
		add_child(bk)
		await get_tree().process_frame
		for i in 30:
			await get_tree().process_frame
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "wueste":   # Mission 7 (Sandhafen)
		var bw7 := Battle.new()
		bw7.setup(Mission.load_mission("ch7"), units)
		bw7.loadout = Items.defs()["loadout_chapter1"]
		add_child(bw7)
		await get_tree().process_frame
		for i in 30:
			await get_tree().process_frame
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode.begins_with("hafen"):   # Mission 6: hafen | hafen_breitseite (Schuss vom Schiff im Flug)
		var bh := Battle.new()
		bh.setup(Mission.load_mission("ch6"), units)
		bh.loadout = Items.defs()["loadout_chapter1"]
		add_child(bh)
		await get_tree().process_frame
		if mode == "hafen_breitseite":
			var eli: Dictionary = bh._find("elisabeth")
			bh._run_ability(eli, "breitseite", bh._find("soldat_infanterie"))
			await get_tree().create_timer(0.75).timeout
		else:
			for i in 30:
				await get_tree().process_frame
			await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode.begins_with("waisenhaus"):   # Mission 5: waisenhaus | waisenhaus_menu (Glocke läuten) | waisenhaus_stock (Schwarm nach 4 Phasen)
		var bw := Battle.new()
		bw.setup(Mission.load_mission("ch5"), units)
		bw.loadout = Items.defs()["loadout_chapter1"]
		add_child(bw)
		await get_tree().process_frame
		if mode == "waisenhaus_menu":
			var hw: Dictionary = bw._find("maedchen_baer")
			hw["pos"] = Vector2i(4, 3)
			(hw["node"] as Node3D).position = bw.to_world(hw["pos"])
			bw._select(hw)
			bw._enter_action()
		if mode == "waisenhaus_stock":
			for n in 4:
				await bw._hive_phase()
		for i in 30:
			await get_tree().process_frame
		await get_tree().create_timer(0.8).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode == "soundlab":
		var lab := SoundLab.new()
		add_child(lab)
		for i in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_OUT"))
		get_tree().quit()
		return
	if mode.begins_with("teehaus"):   # Mission 4: teehaus | teehaus_menu (Befreien-Menue) | teehaus_gebiss (Gebiss im Flug) | teehaus_frei (Mutter rennt davon)
		var bt := Battle.new()
		bt.setup(Mission.load_mission("ch4"), units)
		bt.loadout = Items.defs()["loadout_chapter1"]
		add_child(bt)
		await get_tree().process_frame
		var lin: Dictionary = bt._find("kungfu")
		if mode == "teehaus_menu" or mode == "teehaus_frei":
			lin["pos"] = Vector2i(6, 2)
			(lin["node"] as Node3D).position = bt.to_world(lin["pos"])
		if mode == "teehaus_menu":
			bt._select(lin)
			bt._enter_action()
		if mode == "teehaus_frei":
			bt._free_hostage(lin, bt.world.by_id("geisel"))
			await get_tree().create_timer(0.9).timeout
		if mode == "teehaus_gebiss":
			var xl: Dictionary = bt._find("xiulan")
			bt.fx.before_hit("gebiss", xl, lin, 0)
			await get_tree().create_timer(0.2).timeout
		for i in (0 if mode == "teehaus_gebiss" else 30):
			await get_tree().process_frame
		await get_tree().create_timer(0.0 if mode == "teehaus_gebiss" else 0.6).timeout
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
	"wollmantel": {"u": ["wendy", "p", [3, 7]], "t": ["ritter", "p", [5, 7]], "more": [["soldat_infanterie", "e", [7, 7]]]},
	"baerengebruell": {"u": ["maedchen_baer", "p", [4, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": []},
	"stabwirbel": {"u": ["kungfu", "p", [5, 7]], "t": "self", "more": [["soldat_infanterie", "e", [6, 7]], ["soldat_infanterie", "e", [5, 6]], ["soldat_beritten", "e", [4, 8]]]},
	"wutanfall": {"u": ["elisabeth", "p", [4, 7]], "t": "self", "more": [["soldat_infanterie", "e", [7, 7]]]},
	"bienenkorb": {"u": ["bienenmaedchen", "p", [4, 7]], "tile": [6, 7], "more": [["soldat_infanterie", "e", [9, 7]]]},
	"prost": {"u": ["braumeisterin", "p", [4, 7]], "t": ["ritter", "p", [5, 7], {"hp": 14}], "more": []},
	"bearhug": {"u": ["museklaugust", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": []},
	"kyujutsu": {"u": ["samurai", "p", [2, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": []},
	"brandbombe": {"u": ["oskar", "p", [3, 7]], "t": ["soldat_infanterie", "e", [6, 7]], "more": []},
	"flucht": {"u": ["maja", "e", [5, 7]], "t": "self", "more": [["ritter", "p", [4, 7]]]},
	"tonikum": {"u": ["quacksalber", "p", [3, 7]], "tile": [5, 7], "more": [["ritter", "p", [5, 7]], ["soldat_infanterie", "e", [6, 7]], ["soldat_infanterie", "e", [5, 6]]]},
	"hinterhalt": {"u": ["ninjas", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7], {"dir": [1, 0]}], "more": []},
	"bellen": {"u": ["hund", "p", [5, 7]], "t": "self", "more": [["soldat_infanterie", "e", [7, 7]], ["soldat_infanterie", "e", [5, 5]], ["soldat_beritten", "e", [3, 8]]]},
	"drunken_strike": {"u": ["kungfu", "p", [4, 7]], "t": ["soldat_infanterie", "e", [5, 7]], "more": []},
	"sternschnuppe": {"u": ["magical_girl", "p", [2, 7]], "t": ["soldat_infanterie", "e", [8, 7]], "more": []},
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
	var tgt: Dictionary = {"pos": Vector2i(sc["tile"][0], sc["tile"][1]), "tile": true} if sc.has("tile") else (hero if str(sc["t"]) == "self" else _fx_spawn(b, sc["t"]))
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
		if o.has("dir"):
			u["dir"] = Vector2i(o["dir"][0], o["dir"][1])
		for s: String in o.get("status", []):
			Status.add(u, s, 3)
		b._refresh_unit(u)
	return u
