class_name Grid
extends RefCounted
## Logik der Rasterkarte (4-Nachbarschaft). Kennt keine 3D-Darstellung.

const TERRAIN := {
	"G": {"name": "Gras", "cost": 1, "def": 0},
	"F": {"name": "Wald", "cost": 2, "def": 1},
	"M": {"name": "Berg", "cost": 3, "def": 2},
	"W": {"name": "Wasser", "cost": -1, "def": 0},
	"V": {"name": "Dorf", "cost": 1, "def": 1},
	"C": {"name": "Burg", "cost": 1, "def": 2},
	"P": {"name": "Holzsteg", "cost": 1, "def": 0},
	"D": {"name": "Düne", "cost": 2, "def": 0},
}
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var width := 0
var height := 0
var rows: Array = []
var blocked: Dictionary = {}   # Felder, die Weltobjekte (Mauer, geschlossenes Tor) fuer Fussvolk sperren; Flieger kommen ueber alles


func _init(map_rows: Array = []) -> void:
	rows = map_rows
	height = rows.size()
	width = String(rows[0]).length() if height > 0 else 0


func inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func terrain(p: Vector2i) -> String:
	return String(rows[p.y])[p.x]


func def_bonus(p: Vector2i) -> int:
	return TERRAIN[terrain(p)]["def"]


## Bewegungskosten fuer eine Kachel, -1 = nicht betretbar. Fliegende ignorieren das Gelaende.
func cost(p: Vector2i, flying := false) -> int:
	var c: int = TERRAIN[terrain(p)]["cost"]
	if flying:
		return 1
	if blocked.has(p):
		return -1
	return c


static func dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Dijkstra. blocked: Kacheln, die nicht durchquert werden duerfen (Feinde).
## Rueckgabe: {Vector2i: Kosten} aller erreichbaren Kacheln inkl. Start.
func reachable(start: Vector2i, move: int, flying := false, blocked := {}) -> Dictionary:
	var best := {start: 0}
	var open: Array[Vector2i] = [start]
	while not open.is_empty():
		open.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return best[a] < best[b])
		var cur: Vector2i = open.pop_front()
		for d in DIRS:
			var n: Vector2i = cur + d
			if not inside(n) or blocked.has(n):
				continue
			var c := cost(n, flying)
			if c < 0:
				continue
			var total: int = best[cur] + c
			if total > move or (best.has(n) and best[n] <= total):
				continue
			best[n] = total
			if not open.has(n):
				open.append(n)
	return best


## Kachelweg von start nach goal innerhalb einer Reichweiten-Tabelle (rueckwaerts ueber Kosten).
func path_to(start: Vector2i, goal: Vector2i, reach: Dictionary, flying := false) -> Array[Vector2i]:
	var path: Array[Vector2i] = [goal]
	var cur := goal
	while cur != start:
		var prev := cur
		for d in DIRS:
			var n: Vector2i = cur + d
			if reach.has(n) and reach[n] + cost(cur, flying) == reach[cur]:
				prev = n
				break
		if prev == cur:
			break
		cur = prev
		path.push_front(cur)
	return path
