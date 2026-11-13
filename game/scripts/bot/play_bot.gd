class_name PlayBot
extends RefCounted
## Spieltest-Bot: spielt einen laufenden Kampf (Battle) auf der Spielerseite, nur ueber die Wege eines Spielers:
## Figur anklicken, Feld anklicken, Knopf im Aktionsmenue druecken, Ziel anklicken (Battle._click, Battle._menu).
## Die Entscheidung trifft BotEval (Bewertung) mit BotGoals (Missionsziel). Aufbau: BotSetup.
##
## Benutzung (in einem SceneTree-Skript):
##   var b := await BotSetup.build(root, defs, "ch5")
##   var bot := PlayBot.new(b)
##   var res: Dictionary = await bot.play()
## Ergebnis: {won, reason, turns, survivors, fallen, hp_ratio, abilities_used, abilities_offered, items_used, menu_used,
##            mismatches, story_lost, wall_s, last_actions}

var b: Battle
var style := {"caution": 1.0}
var max_turns := 30
var time_limit := 120.0          # Sekunden Echtzeit je Kampf
var hang_limit := 25.0           # Sekunden Echtzeit am Stueck im Zustand BUSY
var banned: Dictionary = {}      # {Held: [Faehigkeiten]} oder {"*": [Faehigkeiten]}
var hints: Dictionary = {}       # Missionshinweise aus data/bot_hints.json
var reason := ""
var mismatches: Array = []
var used: Dictionary = {}        # {Held: {Faehigkeit: n}}
var offered: Dictionary = {}     # {Held: {Faehigkeit: true}}
var items_used: Dictionary = {}
var menu_used: Dictionary = {}
var last_actions: Array = []
var _won: Array = []
var _repeat: Dictionary = {}


func _init(battle: Battle, opts := {}) -> void:
	b = battle
	style = opts.get("style", style)
	banned = opts.get("banned", {})
	var all_hints: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/bot_hints.json")) if FileAccess.file_exists("res://data/bot_hints.json") else {}
	hints = (all_hints.get("_default", {}) as Dictionary).duplicate(true)
	hints.merge(all_hints.get(str(b.map_data.get("id", "")), {}), true)
	max_turns = int(opts.get("max_turns", hints.get("max_turns", 30)))
	if b.goal.get("type", "") == "survive":
		max_turns = int(b.goal["turns"]) + 2
	time_limit = float(opts.get("time_limit", time_limit))
	b.finished.connect(func(w: bool) -> void: _won.append(w))


func is_banned(u: Dictionary, id: String) -> bool:
	return (banned.get(u["id"], []) as Array).has(id) or (banned.get("*", []) as Array).has(id)


func note_offered(u: Dictionary, id: String) -> void:
	if not offered.has(u["id"]):
		offered[u["id"]] = {}
	offered[u["id"]][id] = true


## Kampf bis zum Ende spielen. Mit await aufrufen.
func play() -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var tree := b.get_tree()
	var decisions := 0
	var last_turn := b.turn
	while true:
		if not await _settle():
			reason = "haengt"
			break
		if b.state == Battle.State.OVER:
			break
		if b.turn > max_turns:
			reason = "rundenlimit"
			break
		if float(Time.get_ticks_msec() - t0) / 1000.0 > time_limit:
			reason = "zeitlimit"
			break
		if b.turn != last_turn:
			last_turn = b.turn
			decisions = 0
		decisions += 1
		if decisions > 60:
			reason = "schleife"
			break
		match b.state:
			Battle.State.IDLE:
				await _next_unit()
			Battle.State.ACTION:
				await _second_action()
			_:
				b._cancel()
				await tree.process_frame
	if b.state != Battle.State.OVER:
		b.state = Battle.State.OVER
	var w := 0
	while _won.is_empty() and w < 400 and reason == "":
		await tree.process_frame
		w += 1
	var won: bool = not _won.is_empty() and bool(_won[0]) and reason == ""
	if reason == "":
		reason = "sieg" if won else "niederlage"
	var survivors: Array = []
	var hp := 0.0
	var maxhp := 0.0
	for u in b.units:
		if u["team"] == "p":
			survivors.append(u["id"])
			hp += float(u["hp"])
			maxhp += float(u["maxhp"])
	var fallen: Array = []
	for u in b.all_units:
		if u["team"] == "p" and not b.units.has(u):
			fallen.append(u["id"])
	return {"won": won, "reason": reason, "turns": b.turn, "survivors": survivors, "fallen": fallen,
		"hp_ratio": hp / maxhp if maxhp > 0.0 else 0.0, "abilities_used": used, "abilities_offered": offered,
		"items_used": items_used, "menu_used": menu_used, "mismatches": mismatches, "story_lost": b.story_lost,
		"wall_s": float(Time.get_ticks_msec() - t0) / 1000.0, "last_actions": last_actions.slice(-12)}


## Warten, bis der Kampf wieder Eingaben annimmt. false = haengt.
func _settle() -> bool:
	var tree := b.get_tree()
	var t0 := Time.get_ticks_msec()
	await tree.process_frame
	while b.state == Battle.State.BUSY:
		await tree.process_frame
		if float(Time.get_ticks_msec() - t0) / 1000.0 > hang_limit:
			return false
	return true


## Beste Figur waehlen und ihren Plan ausfuehren.
func _next_unit() -> void:
	var best: Dictionary = {}
	for u in b.units:
		if u["team"] != "p" or u["done"]:
			continue
		var plan := BotEval.best_plan(self, u)
		if plan.is_empty():
			continue
		if best.is_empty() or float(plan["score"]) > float(best["score"]):
			best = plan
	if best.is_empty():
		b._end_player_turn()
		return
	await _execute(best)


## Nach einer Faehigkeit ohne Zugende (Stabsprung) noch einmal handeln, ohne zu ziehen.
func _second_action() -> void:
	if b.sel.is_empty():
		_press("Warten")
		return
	var plan := BotEval.best_plan(self, b.sel, true)
	plan["no_move"] = true
	await _execute(plan)


func _log(text: String) -> void:
	last_actions.append("R%d %s" % [b.turn, text])
	if OS.get_environment("SPIEL_DEBUG") != "":
		print("  [bot] R%d %s  (%.1f s)" % [b.turn, text, float(Time.get_ticks_msec()) / 1000.0])
	if last_actions.size() > 40:
		last_actions.pop_front()


func _mismatch(text: String) -> void:
	mismatches.append("R%d %s" % [b.turn, text])
	_log("ABWEICHUNG " + text)


func _execute(plan: Dictionary) -> void:
	var u: Dictionary = plan["unit"]
	var tile: Vector2i = plan.get("tile", u["pos"])
	var key := "%d|%s|%s|%s|%s" % [b.turn, u["uid"], tile, plan["kind"], plan.get("ab", plan.get("menu", ""))]
	_repeat[key] = int(_repeat.get(key, 0)) + 1
	if _repeat[key] > 2:      # dieselbe Entscheidung immer wieder: warten statt drehen
		plan = {"kind": "wait", "unit": u, "tile": u["pos"]}
	if not plan.get("no_move", false):
		b._click(u["pos"])
		if b.state != Battle.State.SELECTED or b.sel != u:
			_mismatch("%s laesst sich nicht waehlen" % u["id"])
			b._cancel()
			u["done"] = true
			return
		if tile != u["pos"] and not (b.reach.has(tile) and b.unit_at(tile).is_empty() and (b._hide_allowed.is_empty() or b._hide_allowed.has(tile))):
			_mismatch("%s: Feld %s nicht erreichbar" % [u["id"], tile])
			tile = u["pos"]
			plan = {"kind": "wait", "unit": u}
		b._click(tile)
		if not await _settle():
			return
		if b.state == Battle.State.OVER:
			return
		if b.state != Battle.State.ACTION:
			_mismatch("%s: nach dem Zug kein Aktionsmenue (Zustand %d)" % [u["id"], b.state])
			return
	_log("%s -> %s %s %s" % [u["id"], tile, plan["kind"], plan.get("ab", plan.get("item", plan.get("menu", "")))])
	match str(plan["kind"]):
		"attack", "attack_obj":
			if _press("Angriff"):
				_click_target(plan)
		"heal":
			if _press("Heilen"):
				_click_target(plan)
		"ability", "ability_obj", "ability_tile":
			var id: String = plan["ab"]
			if _press("Fähigkeit") and _press_index(u["abilities"].find(id)):
				if not used.has(u["id"]):
					used[u["id"]] = {}
				used[u["id"]][id] = int(used[u["id"]].get(id, 0)) + 1
				if plan["kind"] == "ability_tile":
					var p: Vector2i = plan["tile_target"]
					if b._landing_tiles.has(p):
						b._click(p)
					else:
						_mismatch("%s: Zielfeld %s fuer %s nicht waehlbar" % [u["id"], p, id])
						_back_and_wait()
				else:
					_click_target(plan)
		"item":
			var it: String = plan["item"]
			if _press("Gegenstand") and _press(str(Items.consumables()[it]["name"])):
				items_used[it] = int(items_used.get(it, 0)) + 1
				_click_target(plan)
		"douse":
			if _press("Feuer löschen"):
				_click_target(plan)
		"menu":
			var m: String = plan["menu"]
			if _press(m):
				menu_used[m] = int(menu_used.get(m, 0)) + 1
		"defend":
			_press("Verteidigen")
		_:
			_press("Warten")
	await _settle()


## Knopf im Aktionsmenue druecken (Textanfang). false und Warten, wenn er fehlt oder gesperrt ist.
func _press(prefix: String) -> bool:
	var btn := _button(func(x: Button) -> bool: return x.text.begins_with(prefix))
	if btn == null:
		_mismatch("Menuepunkt '%s' fehlt oder ist gesperrt (%s)" % [prefix, b.sel.get("id", "?")])
		_back_and_wait()
		return false
	btn.pressed.emit()
	return true


func _press_index(i: int) -> bool:
	if b._menu == null or not is_instance_valid(b._menu) or i < 0:
		_mismatch("Faehigkeit nicht im Menue")
		_back_and_wait()
		return false
	var box := b._menu.get_child(0)
	if i >= box.get_child_count() or (box.get_child(i) as Button).disabled:
		_mismatch("Faehigkeit %d gesperrt (%s)" % [i, b.sel.get("id", "?")])
		_back_and_wait()
		return false
	(box.get_child(i) as Button).pressed.emit()
	return true


func _button(pred: Callable) -> Button:
	if b._menu == null or not is_instance_valid(b._menu):
		return null
	for c in b._menu.get_child(0).get_children():
		var btn := c as Button
		if btn != null and not btn.disabled and pred.call(btn):
			return btn
	return null


## Ziel anklicken (Figur oder Objekt); ist es nicht waehlbar: zurueck ins Menue und warten.
func _click_target(plan: Dictionary) -> void:
	if b.state != Battle.State.TARGETING:
		return
	var p: Vector2i
	if plan.has("target"):
		var t: Dictionary = plan["target"]
		if not b._target_units.has(t):
			_mismatch("%s: Ziel %s nicht waehlbar (%s)" % [b.sel.get("id", "?"), t.get("id", "?"), plan["kind"]])
			_back_and_wait()
			return
		p = t["pos"]
	else:
		var o: Dictionary = plan["obj"]
		if not b._target_objs.has(o):
			_mismatch("%s: Objekt %s nicht waehlbar (%s)" % [b.sel.get("id", "?"), o.get("id", "?"), plan["kind"]])
			_back_and_wait()
			return
		p = o["pos"]
	b._click(p)


func _back_and_wait() -> void:
	if b.state == Battle.State.TARGETING:
		b._cancel()
	if b.state == Battle.State.ACTION:
		if b._menu != null and is_instance_valid(b._menu) and _button(func(x: Button) -> bool: return x.text.begins_with("Zurück")) != null:
			_button(func(x: Button) -> bool: return x.text.begins_with("Zurück")).pressed.emit()
		var wb := _button(func(x: Button) -> bool: return x.text.begins_with("Warten"))
		if wb != null:
			wb.pressed.emit()
