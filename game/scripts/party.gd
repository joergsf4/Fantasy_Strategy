class_name Party
extends RefCounted
## Zustand der Heldengruppe ueber Kapitel hinweg: Gold, Rucksack, Ausruestung. Wird gespeichert.
## Nichts fuellt sich von selbst auf: verbrauchte Gegenstaende sind weg, Beute kommt aus festen Quellen.

const SAVE_PATH := "user://save.json"
const ORDER := 1      # Version der Kapitelreihenfolge im Spielstand (1: Zwischenspiel nach Mission 16 eingefuegt, alte Kapitel 17 und 18 sind jetzt 18 und 19)

var chapter := 1
var gold := 0
var inventory: Dictionary = {}     # Verbrauchsgegenstaende {id: Anzahl}
var equipment: Dictionary = {}     # getragen: {Held: [Ausruestung]}
var pool: Array = []               # besitzt, aber nicht getragen
var squads: Dictionary = {}              # {Mission: [Helden]}: vom Spieler geaenderte Aufstellung vor der Mission
var nemesis: Array = []            # entkommene Gegner, tauchen in spaeteren Missionen wieder auf
var secrets_seen: Array = []     # gesehene Geheimnis-Szenen (Szene laeuft nur beim ersten Mal)
var test_run := false              # Teststart (START_CH, Testlabor): wird nie gespeichert
var recruited: Array = []          # in einer Mission gewonnene Verbuendete (z. B. Alphawolf), nur dann waehlbar (recruit_only)
var pending_interlude: Dictionary = {}
var earned := 0                    # geschaffte Kampfmissionen; daraus ergeben sich Gruppenstufe und Talentpunkte (alle levels_per_point Stufen einer)
var prompted: Dictionary = {}      # {Held: Stufe}, ab der der Aufstiegsbildschirm fuer ihn schon gezeigt wurde
var talents: Dictionary = {}       # verteilte Punkte je Held {id: {hp, atk, a1, a2}} (Talents)
var bought: Dictionary = {}        # im aktuellen Lager gekauft {id: Anzahl} (Haendler hat nur festen Vorrat)


## Testgruppe: bisherige feste Belohnungen und ein Teil optionaler Goldbeute finanzieren Einkaeufe beim jeweils verfuegbaren Haendler.
## Wird nie gespeichert (test_run).
static func for_chapter(defs: Dictionary, n: int) -> Party:
	var p := Party.new_game()
	p.test_run = true
	p.chapter = n
	p.earned = Progression.missions_done_before(n)
	var squad: Array = (Mission.load_mission("ch%d" % n)["players"] as Array).map(func(e: Dictionary) -> String: return e["id"])
	for id: String in defs:
		if not defs[id].get("hero", false):
			continue
		p.talents[id] = Talents.default_allocation(points_for(p.earned))
	p.release_absent(squad)
	p.auto_equip(squad, defs)
	for completed in range(1, n):
		var m := Mission.load_mission("ch%d" % completed)
		if not m.get("stub", false):
			p.gold += int((m.get("rewards", {}) as Dictionary).get("gold", 0))
			var optional := 0
			for chest: Dictionary in m.get("chests", []):
				optional += int((chest.get("reward", {}) as Dictionary).get("gold", 0))
			for objective: Dictionary in m.get("objectives", []):
				optional += int((objective.get("reward", {}) as Dictionary).get("gold", 0))
			p.gold += optional / 2
		p.chapter = completed + 1
		p.bought.clear()
		var next_m := Mission.load_mission("ch%d" % p.chapter)
		if (not m.get("stub", false) and not next_m.get("stub", false)) or (m.get("stub", false) and m.get("camp_after", false)):
			p._test_shop(squad, defs)
	p.chapter = n
	return p


## Greift nur auf Waren und Stueckzahlen der damaligen Lager zu; ein Teil des Goldes bleibt als Reserve.
func _test_shop(squad: Array, defs: Dictionary) -> void:
	release_absent([])
	auto_equip(squad, defs)
	var tier: float = float(((Progression.data()["missions"] as Dictionary).get("ch%d" % chapter, {}) as Dictionary).get("gear_tier", 1.0))
	var caps := {"waffe": ceili(tier), "ruestung": maxi(1, floori(tier)), "talisman": maxi(1, floori(tier))}
	var reserve := gold / 5
	while true:
		var best := {}
		var best_value := 0.0
		for ware: Dictionary in stock():
			var id: String = ware["id"]
			if int(ware["left"]) <= 0 or int(ware["price"]) > gold - reserve or not Items.equipment().has(id):
				continue
			var item: Dictionary = Items.equipment()[id]
			var slot: String = item["slot"]
			if int(item["tier"]) > int(caps[slot]):
				continue
			for hero: String in squad:
				if not defs.has(hero) or not defs[hero].get("hero", false):
					continue
				var d: Dictionary = defs[hero]
				if not Items.can_equip({"dmg_type": d.get("dmg_type", "body"), "range": int(d.get("range", 1))}, id):
					continue
				if slot == "ruestung" and ((item["mods"] as Dictionary).has("res") != (d.get("dmg_type", "body") == "magic")):
					continue
				var old := worn_in(hero, slot)
				var old_score := Items.auto_equip_score(d, old) if old != "" else 0
				var gain := Items.auto_equip_score(d, id) - old_score
				var value := float(gain) / float(10 + old_score) if gain > 0 else 0.0
				if value > best_value:
					best_value = value
					best = {"id": id, "hero": hero}
		if best.is_empty():
			break
		if not buy(best["id"]) or not equip(best["hero"], best["id"], defs[best["hero"]]):
			push_error("Testausruestung konnte nicht gekauft oder angelegt werden: %s" % best)
			break


static func new_game() -> Party:
	var p := Party.new()
	var lo: Dictionary = Items.defs().get("loadout_chapter1", {})
	p.inventory = (lo.get("inventory", {}) as Dictionary).duplicate()
	p.equipment = (lo.get("equipment", {}) as Dictionary).duplicate(true)
	return p


## Was ein Kampf zu Beginn bekommt.
func loadout() -> Dictionary:
	return {"inventory": inventory.duplicate(), "equipment": equipment.duplicate(true), "nemesis": nemesis.duplicate(), "secrets_seen": secrets_seen.duplicate(), "talents": talents.duplicate(true)}


## Gruppenstufe: 1 am Anfang, +1 je geschaffter Kampfmission.
func level() -> int:
	return earned + 1


## Talentpunkte, die ein Held auf dieser Stufe insgesamt verdient hat (alle levels_per_point Stufen einer, fuer alle gleich).
static func points_for(missions_done: int) -> int:
	return missions_done / int(Talents.cfg()["levels_per_point"])


## Freie Talentpunkte dieses Helden: verdiente minus verteilte.
func points(id: String) -> int:
	return points_for(earned) - Talents.spent(talents.get(id, {}))


## Soll der Aufstiegsbildschirm fuer diesen Helden gezeigt werden? Punkt frei und auf dieser Stufe noch nicht gezeigt.
func needs_prompt(id: String) -> bool:
	return points(id) > 0 and int(prompted.get(id, 0)) < level()


func mark_prompted(id: String) -> void:
	prompted[id] = level()


func ranks(id: String) -> Dictionary:
	var t: Dictionary = talents.get(id, {})
	return {"hp": int(t.get("hp", 0)), "atk": int(t.get("atk", 0)), "a1": int(t.get("a1", 0)), "a2": int(t.get("a2", 0))}


## Einen Punkt in hp, atk, a1 oder a2 stecken. false = keine Punkte frei oder Rang schon am Maximum.
func spend_point(id: String, key: String) -> bool:
	var t := ranks(id)
	if points(id) <= 0 or int(t[key]) >= Talents.max_rank():
		return false
	t[key] = int(t[key]) + 1
	talents[id] = t
	return true


## Punkt zurueckholen (jederzeit im Lager, neu verteilen ist erlaubt).
func refund_point(id: String, key: String) -> bool:
	var t := ranks(id)
	if int(t[key]) <= 0:
		return false
	t[key] = int(t[key]) - 1
	talents[id] = t
	return true


## Ergebnis eines gewonnenen Kampfes uebernehmen (Rucksack-Rest + Beute + Belohnungen).
func absorb(results: Dictionary) -> void:
	inventory = (results["inventory"] as Dictionary).duplicate()
	gold += int(results["gold"])
	pool.append_array(results["equipment"])
	for id: String in results.get("fled", []):
		if not nemesis.has(id):
			nemesis.append(id)
	for id: String in results.get("secrets_seen", []):
		if not secrets_seen.has(id):
			secrets_seen.append(id)
	for rid: String in results.get("recruited", []):
		if not recruited.has(rid):
			recruited.append(rid)
	earned += 1      # eine Stufe mehr; Talentpunkte gibt es alle levels_per_point Stufen (fuer alle gleich, verteilt wird nur fuer Helden in der Gruppe)
	chapter += 1
	bought = {}


## Gold ausgeben. false = nicht moeglich (zu wenig).
func can_afford(price: int) -> bool:
	return gold >= price


func spend(price: int) -> bool:
	if gold < price:
		return false
	gold -= price
	return true


func to_dict() -> Dictionary:
	return {"order": ORDER, "chapter": chapter, "gold": gold, "inventory": inventory, "equipment": equipment, "pool": pool, "bought": bought, "nemesis": nemesis, "squads": squads, "secrets_seen": secrets_seen, "earned": earned, "talents": talents, "prompted": prompted, "recruited": recruited, "pending_interlude": pending_interlude}


static func from_dict(d: Dictionary) -> Party:
	var p := Party.new()
	p.chapter = int(d.get("chapter", 1))
	p.earned = int(d.get("earned", 0))
	p.recruited = (d.get("recruited", []) as Array).duplicate()
	p.pending_interlude = (d.get("pending_interlude", {}) as Dictionary).duplicate(true)
	p.prompted = _ints(d.get("prompted", {}))
	p.talents = (d.get("talents", {}) as Dictionary).duplicate(true)
	p.gold = int(d.get("gold", 0))
	p.inventory = _ints(d.get("inventory", {}))
	p.equipment = (d.get("equipment", {}) as Dictionary).duplicate(true)
	p.pool = (d.get("pool", []) as Array).duplicate()
	p.bought = _ints(d.get("bought", {}))
	p.nemesis = (d.get("nemesis", []) as Array).duplicate()
	p.squads = (d.get("squads", {}) as Dictionary).duplicate(true)
	p.secrets_seen = (d.get("secrets_seen", []) as Array).duplicate()
	if int(d.get("order", 0)) < 1:      # alter Spielstand: Kapitel ab dem alten 17 (Woelfe) ruecken um eins nach hinten
		_migrate_order0(p)
	return p


static func _ints(d: Dictionary) -> Dictionary:
	var out := {}
	for k: String in d:
		out[k] = int(d[k])
	return out


func save(path := SAVE_PATH) -> void:
	if test_run:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()


## Ab dieser Mission kennt der Spieler den Helden und darf ihn waehlen: "from" (wenn gesetzt, z. B. wenn er erst nach seinem ersten
## Auftritt beitritt), sonst "intro" (erstes Auftreten in der Geschichte). Ohne beides ist er noch nie aufgetreten: nicht waehlbar.
static func join_mission(def: Dictionary) -> int:
	if def.has("from"):
		return int(def["from"])
	if def.has("intro"):
		return int(def["intro"])
	return 9999


## Helden, die man in Mission mission_no (ab 1) in die Gruppe holen kann: nur wer schon kennengelernt ist ("hero": true und join_mission <= Nummer).
## after_intro = false (Lager vor der Mission): nur Helden, die schon in frueheren Missionen aufgetreten sind (join_mission < Nummer);
## true (Gruppenwahl nach der Einleitung der Mission): auch wer in der Einleitung dieser Mission auftritt.
static func roster(defs: Dictionary, mission_no: int, after_intro := true, recruited: Array = []) -> Array:
	var out: Array = []
	for id: String in defs:
		if not defs[id].get("hero", false):
			continue
		if defs[id].get("recruit_only", false) and not recruited.has(id):
			continue      # nur waehlbar, wenn in einer Mission gewonnen
		var j := join_mission(defs[id])
		if j < mission_no or (after_intro and j == mission_no):
			out.append(id)
	return out


## Gruppe fuer eine Mission: die Vorgabe der Karte (players), darueber die gespeicherte Auswahl des Spielers.
## Gespraechsfiguren bleiben immer drin, die Auswahl wird auf gueltige Plaetze zurechtgestutzt.
func squad_for(m: Dictionary) -> Array:
	var base: Array = (m["players"] as Array).map(func(e: Dictionary) -> String: return e["id"])
	var saved: Array = squads.get(m.get("id", ""), [])
	if saved.size() != base.size():
		var previous: String = m.get("squad_from", "")
		if previous == "":
			return base
		saved = squad_for(Mission.load_mission(previous))
		if saved.size() != base.size() and not m.get("squad_resize", false):
			return base
	var fixed: Array = Mission.dialogue_ids(m["id"])
	var out: Array = []
	for i in base.size():
		if fixed.has(base[i]):
			out.append(base[i])
			continue
		var saved_at_slot: String = saved[i] if i < saved.size() else base[i]
		var candidates := [saved_at_slot] + saved + base if m.get("squad_resize", false) else [saved_at_slot, base[i]] + saved + base
		for candidate: String in candidates:
			if not fixed.has(candidate) and not out.has(candidate):
				out.append(candidate)
				break
	return out


## Wechselt Platz i der Gruppe von Mission m auf Held id. false, wenn der Platz fest ist oder der Held schon dabei ist.
func set_squad_member(m: Dictionary, i: int, id: String) -> bool:
	var cur := squad_for(m)
	if Mission.dialogue_ids(m["id"]).has(cur[i]) or cur.has(id):
		return false
	cur[i] = id
	squads[m["id"]] = cur
	release_absent(cur)
	return true


## Ausruestung aller Helden, die nicht in dieser Gruppe sind, geht in den Lager-Vorrat zurueck und kann neu verteilt werden.
func release_absent(squad: Array) -> void:
	for hero: String in equipment.keys():
		if squad.has(hero):
			continue
		for w: String in equipment[hero]:
			pool.append(w)
		equipment.erase(hero)


## Kurzbeschreibung fuer die Kapitelwahl.
func summary() -> String:
	var names := {"wart": "Wart", "oskar": "Oskar", "maja": "Maja", "xiulan": "Xiùlán", "bienenmaedchen": "Stachelia", "dummy": "Trainingsattrappe"}
	var fled: Array = nemesis.map(func(id: String) -> String: return names.get(id, id))
	return "Spielstand: Gold %d%s" % [gold, ", entkommen: " + ", ".join(fled) if not fled.is_empty() else ""]


static func delete_save(path := SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func load_from(path := SAVE_PATH) -> Party:
	if not FileAccess.file_exists(path):
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Party.from_dict(d) if d is Dictionary else null


# ------------------------------------------------------------------ Haendler, Ausruestung

static func _migrate_order0(p: Party) -> void:
	if p.chapter >= 17:
		p.chapter += 1
	for k: String in ["ch18", "ch17"]:      # absteigend, damit nichts doppelt verschoben wird
		if p.squads.has(k):
			p.squads["ch%d" % (int(k.substr(2)) + 1)] = p.squads[k]
			p.squads.erase(k)


static func shop_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/shop.json"))


## Haendler im Lager dieses Kapitels (shop.json "merchants": id, name, portrait, quips, from/until). {} = keiner da.
static func merchant_at(chapter_no: int) -> Dictionary:
	for m: Dictionary in shop_data().get("merchants", []):
		if int(m.get("from", 1)) <= chapter_no and chapter_no <= int(m.get("until", 9999)):
			return m
	return {}


func merchant() -> Dictionary:
	return merchant_at(chapter)


## Waren des Haendlers fuer das aktuelle Kapitel: [{id, price, n, left}]. Jede Ware gehoert einem Haendler ("for", Standard sack).
func stock() -> Array:
	var out: Array = []
	var mid: String = str(merchant().get("id", ""))
	if mid == "":
		return out
	for w: Dictionary in shop_data().get("stock", []):
		if str(w.get("for", "sack")) != mid:
			continue
		if int(w.get("from", 1)) > chapter or (w.has("until") and int(w["until"]) < chapter):
			continue      # noch nicht oder nicht mehr im Sortiment (Ausruestung nach Stufen, siehe shop.json)
		var left := int(w["n"]) - int(bought.get(w["id"], 0))
		out.append({"id": w["id"], "price": int(w["price"]), "n": int(w["n"]), "left": left})
	return out


func can_buy(id: String) -> bool:
	for w: Dictionary in stock():
		if w["id"] == id:
			return w["left"] > 0 and gold >= w["price"]
	return false


## Kaufen: Verbrauchsgut -> Rucksack, Ausruestung -> Lager. false = nicht moeglich.
func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	for w: Dictionary in stock():
		if w["id"] == id:
			gold -= w["price"]
	bought[id] = int(bought.get(id, 0)) + 1
	if Items.consumables().has(id):
		inventory[id] = int(inventory.get(id, 0)) + 1
	else:
		pool.append(id)
	return true


## Verkaufspreis eines Lagerstuecks: die Haelfte des Listenpreises (items.json "price").
static func sell_price(id: String) -> int:
	return int(Items.equipment()[id].get("price", 0)) / 2


## Ausruestung aus dem Lager verkaufen. false = nicht im Lager.
func sell(id: String) -> bool:
	var i := pool.find(id)
	if i < 0:
		return false
	pool.remove_at(i)
	gold += Party.sell_price(id)
	return true


## Ausruestung eines Helden anlegen (aus dem Lager). Ein Stueck pro Platz: das alte geht zurueck ins Lager.
## unit_def = Eintrag aus units.json (fuer Einschraenkungen wie "nur Magier").
func equip(hero: String, id: String, unit_def: Dictionary) -> bool:
	var i := pool.find(id)
	if i < 0:
		return false
	if not Items.can_equip({"dmg_type": unit_def.get("dmg_type", "body"), "range": int(unit_def.get("range", 1))}, id):
		return false
	var slot: String = Items.equipment()[id]["slot"]
	var worn: Array = (equipment.get(hero, []) as Array).duplicate()
	for w: String in worn.duplicate():
		if Items.equipment()[w]["slot"] == slot:
			worn.erase(w)
			pool.append(w)
	pool.remove_at(pool.find(id))
	worn.append(id)
	equipment[hero] = worn
	return true


## Nur freie Plaetze der aktuellen Gruppe belegen; pro Platz die beste Gesamtverteilung ermitteln.
func auto_equip(squad: Array, unit_defs: Dictionary) -> int:
	var equipped := 0
	for slot: String in ["waffe", "ruestung", "talisman"]:
		var heroes: Array = []
		for hero: String in squad:
			if unit_defs.has(hero) and not heroes.has(hero) and worn_in(hero, slot) == "":
				heroes.append(hero)
		# Bitmaske der bereits versorgten Helden -> Gesamtwert und Zuordnung.
		var states := {0: {"score": 0, "assignments": []}}
		for id: String in pool:
			if not Items.equipment().has(id) or Items.equipment()[id]["slot"] != slot:
				continue
			var next := states.duplicate()
			for mask: int in states:
				var state: Dictionary = states[mask]
				for i in heroes.size():
					var bit := 1 << i
					if mask & bit:
						continue
					var d: Dictionary = unit_defs[heroes[i]]
					if not Items.can_equip({"dmg_type": d.get("dmg_type", "body"), "range": int(d.get("range", 1))}, id):
						continue
					var value := Items.auto_equip_score(d, id)
					if value <= 0:
						continue
					var new_mask := mask | bit
					var total := int(state["score"]) + value
					if not next.has(new_mask) or total > int(next[new_mask]["score"]):
						var assignments: Array = (state["assignments"] as Array).duplicate()
						assignments.append([heroes[i], id])
						next[new_mask] = {"score": total, "assignments": assignments}
			states = next
		var best: Dictionary = states[0]
		for state: Dictionary in states.values():
			if int(state["score"]) > int(best["score"]):
				best = state
		for assignment: Array in best["assignments"]:
			if equip(assignment[0], assignment[1], unit_defs[assignment[0]]):
				equipped += 1
			else:
				push_error("Automatische Ausruestung fehlgeschlagen: %s fuer %s" % [assignment[1], assignment[0]])
	return equipped


func unequip(hero: String, slot: String) -> void:
	var worn: Array = (equipment.get(hero, []) as Array).duplicate()
	for w: String in worn.duplicate():
		if Items.equipment()[w]["slot"] == slot:
			worn.erase(w)
			pool.append(w)
	equipment[hero] = worn


func worn_in(hero: String, slot: String) -> String:
	for w: String in equipment.get(hero, []):
		if Items.equipment()[w]["slot"] == slot:
			return w
	return ""
