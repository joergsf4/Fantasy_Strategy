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


## Anzeigetext des Ziels, mit Fortschritt.
static func goal_text(goal: Dictionary, enemies_left: int, turn: int) -> String:
	match goal.get("type", "rout"):
		"survive":
			return "Ziel: Haltet durch (Runde %d von %d)" % [mini(turn, int(goal["turns"])), int(goal["turns"])]
		"reach":
			return "Ziel: Erreicht das markierte Feld"
		_:
			return "Ziel: Besiegt alle Gegner (%d übrig)" % enemies_left
