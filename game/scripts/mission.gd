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
static func dialogue_ids(id: String) -> Array:
	var ids := {}
	var add_lines := func(lines: Array) -> void:
		for l: Dictionary in lines:
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
	ids.erase("$hero")
	return ids.keys()


## Anzeigetext des Ziels, mit Fortschritt.
static func goal_text(goal: Dictionary, enemies_left: int, turn: int) -> String:
	match goal.get("type", "rout"):
		"survive":
			return "Ziel: Haltet durch (Runde %d von %d)" % [mini(turn, int(goal["turns"])), int(goal["turns"])]
		"free":
			return "Ziel: Befreit die Geisel"
		"reach":
			return "Ziel: Erreicht das markierte Feld"
		_:
			return "Ziel: Besiegt alle Gegner (%d übrig)" % enemies_left
