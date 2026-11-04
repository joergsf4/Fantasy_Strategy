class_name Mission
extends RefCounted
## Missionsformat: Karte (map_*.json) plus Ziele, Ausloeser (Runde / Feld betreten) und Briefing.
##
## Ziele (goals): {type: "rout"} alle Gegner besiegen | {type: "survive", turns: N} N Runden durchhalten
##                | {type: "reach", tile: [x, y]} ein Held erreicht das Feld.
## Verloren ist immer: alle Helden gefallen.
## Ausloeser (triggers): {when: {turn: N} | {enter: [x, y]}, do: [{popup: "Text"}, {dialogue: [...]}, {spawn: [{id, pos, carry}]}]}
## Jeder Ausloeser feuert hoechstens einmal. Verstaerkung ist immer fest geskriptet, nie zufaellig.

const DIR := "res://data/missions/"


## Mission laden: die Karte aus "map" wird mit den Missionsfeldern zusammengefuehrt (Mission gewinnt).
static func load_mission(id: String) -> Dictionary:
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + id + ".json"))
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(m["map"]))
	map.merge(m, true)
	if not map.has("goals"):
		map["goals"] = [{"type": "rout"}]
	if not map.has("triggers"):
		map["triggers"] = []
	return map


## Alle Figuren, die in dieser Mission sprechen (Einleitung, Abschluss, Kampfdialoge, Rueckzug). Sie sind in der Gruppe fest,
## alle anderen Helden der Gruppe duerfen vor der Mission gewechselt werden.
## Stimmen: eine Zeile kann "voices" tragen, eine Liste [{id, text, expr?}] nach Vorrang. Die Zeile selbst ist die Rueckfallstimme (spricht immer).
## Ist ein Held aus der Liste in der Gruppe, spricht er statt der Rueckfallstimme, mit eigenem Text (und Gesichtsausdruck).
static func voiced(lines: Array, squad: Array) -> Array:
	var out: Array = []
	for l: Dictionary in lines:
		var c := l.duplicate()
		c.erase("voices")
		for v: Dictionary in l.get("voices", []):
			var side: String = "left" if l.get("speaker", "") == l.get("left", "") else "right"
			var other: String = l.get("right" if side == "left" else "left", "")
			if not squad.has(v.get("id", "")) or v["id"] == other:
				continue
			c[side] = v["id"]
			c["speaker"] = v["id"]
			c["text"] = v.get("text", "")
			c.erase("text_by")
			if v.get("expr", "") != "":
				c[side + "_expr"] = v["expr"]
			else:
				c.erase(side + "_expr")
			break
		out.append(c)
	return out


static func dialogue_ids(id: String) -> Array:
	var ids := {}
	var add_lines := func(lines: Array) -> void:
		for l: Dictionary in lines:
			if not l.get("story", false):      # nur Story-Gespraeche legen Figuren fest, Fluff laesst die Gruppenwahl frei
				continue
			for k in ["left", "right", "speaker"]:
				if l.has(k):
					ids[l[k]] = true
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_%s.json" % id))
	add_lines.call(story.get("intro", []))
	add_lines.call(story.get("outro", []))
	var m := load_mission(id)
	for t: Dictionary in m.get("triggers", []):
		for step: Dictionary in t.get("do", []):
			add_lines.call(step.get("dialogue", []))
	for lines: Array in (m.get("flee", {}) as Dictionary).values():
		add_lines.call(lines)
	if m.get("fixed_squad", false):      # Kapitel mit festem Trupp (z. B. Stachelia und ihre Bienen): kein Austausch
		for pe: Dictionary in m["players"]:
			ids[pe["id"]] = true
	ids.erase("$hero")
	ids.erase("")
	return ids.keys()


## Anzeigetext des Ziels, mit Fortschritt.
static func goal_text(goal: Dictionary, enemies_left: int, turn: int, extra := {}) -> String:
	match goal.get("type", "rout"):
		"capture":
			if not extra.get("present", false):
				return str(goal.get("wait_text", "Ziel: Sichert die Oase (bald rollt etwas heran)"))
			return "Ziel: Bleibt %d Runden neben %s (%d/%d)" % [int(goal.get("turns", 3)), extra.get("name", "dem Panzer"), int(extra.get("progress", 0)), int(goal.get("turns", 3))]
		"free_all":
			return str(goal.get("text", "Ziel: Befreit alle Gefangenen"))
		"defeat":
			return str(goal.get("text", "Ziel: Besiegt den Anführer"))
		"survive":
			return "Ziel: Haltet durch (Runde %d von %d)" % [mini(turn, int(goal["turns"])), int(goal["turns"])]
		"free":
			return "Ziel: Befreit die Geisel"
		"reach":
			return "Ziel: Erreicht das markierte Feld"
		_:
			return "Ziel: Besiegt alle Gegner (%d übrig)" % enemies_left
