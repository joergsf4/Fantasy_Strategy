class_name Status
extends RefCounted
## Statuseffekte als Liste in u["status"]: {id, turns, mods, src, n}. Dauer zaehlt in den Phasen des Betroffenen.

const NAMES := {
	"stun": "Benommen", "poison": "Gift", "taunt": "Spott", "stealth": "Verborgen",
	"buff": "Gestärkt", "tired": "Erschöpft", "polymorph": "Verwandelt", "defend": "Verteidigt", "scared": "Eingeschüchtert", "angst": "Panik", "betrunken": "Bierlaune", "satt": "Satt", "wachsam": "Wachsam",
	"schild": "Wollmantel", "wut": "Wutanfall", "brennen": "Brennt", "tempo": "Beflügelt", "uebel": "Übel",
}
const BURN_DAMAGE := 3
const GOOD := ["satt", "betrunken", "stealth", "buff", "defend", "wachsam", "schild", "wut", "tempo"]


static func add(u: Dictionary, id: String, turns: int, mods := {}, src := "") -> void:
	var list: Array = u.get("status", [])
	for s: Dictionary in list:
		if s["id"] == id:
			s["turns"] = maxi(s["turns"], turns)
			if not mods.is_empty():
				s["mods"] = mods
			if src != "":
				s["src"] = src
			return
	list.append({"id": id, "turns": turns, "mods": mods, "src": src, "n": 0})
	u["status"] = list


static func get_status(u: Dictionary, id: String) -> Dictionary:
	for s: Dictionary in u.get("status", []):
		if s["id"] == id:
			return s
	return {}


static func has(u: Dictionary, id: String) -> bool:
	return not get_status(u, id).is_empty()


static func remove(u: Dictionary, id: String) -> void:
	var list: Array = u.get("status", [])
	for i in range(list.size() - 1, -1, -1):
		if list[i]["id"] == id:
			list.remove_at(i)


## Heilung entfernt Gift. true = es war etwas zu entfernen.
static func cleanse(u: Dictionary) -> bool:
	var had := has(u, "poison")
	remove(u, "poison")
	return had


## Schaden des naechsten Gifttickens: 3, 4, 5, ...
static func poison_damage(s: Dictionary) -> int:
	return 3 + int(s.get("n", 0))


## Beginn der eigenen Phase: Gift tickt, Dauer sinkt, Abklingzeiten sinken.
## Rueckgabe: Ereignisse [{type:"poison", amount:int}, {type:"expire", id:String}]
static func tick_phase_start(u: Dictionary) -> Array:
	var events: Array = []
	var list: Array = u.get("status", [])
	for i in range(list.size() - 1, -1, -1):
		var s: Dictionary = list[i]
		if s["id"] == "poison":
			events.append({"type": "poison", "amount": poison_damage(s)})
			s["n"] = int(s.get("n", 0)) + 1
		elif s["id"] == "brennen":
			events.append({"type": "burn", "amount": BURN_DAMAGE})
		s["turns"] = int(s["turns"]) - 1
		if s["turns"] <= 0:
			events.append({"type": "expire", "id": s["id"]})
			list.remove_at(i)
	var cd: Dictionary = u.get("cd", {})
	for k: String in cd.keys():
		cd[k] = maxi(0, int(cd[k]) - 1)
	return events


static func label(u: Dictionary) -> String:
	var parts: PackedStringArray = []
	for s: Dictionary in u.get("status", []):
		parts.append("%s %d" % [NAMES.get(s["id"], s["id"]), s["turns"]])
	return ", ".join(parts)
