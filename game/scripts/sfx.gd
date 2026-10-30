class_name Sfx
extends Node
## Soundeffekte. Kampfgeraeusche entstehen aus Schichten: Schwung + Waffe (Holz/Metall/Faust) + Ziel (Ruestung/Holz/Fleisch/Stein).
## Alle Zuordnungen stehen in data/sfx.json, die Klaenge in assets/sfx/<name>_<n>.wav (erzeugt von tools/make_sfx.py).
## Eine Angabe ("spec") in sfx.json ist ein Name, ein Objekt {s, db, pitch, delay} oder eine Liste davon; "@melee" = Waffe/Ziel-Schichten.

const DIR := "res://assets/sfx/"
const BUS := "SFX"
const POOL := 24

static var _inst: Sfx = null
static var muted := false          # z. B. fuer Tests, die nichts abspielen sollen

var cfg: Dictionary = {}
var played: Array[String] = []     # Protokoll der letzten Klaenge (fuer Tests und das Soundlabor)
var _cache: Dictionary = {}        # Name -> Array[AudioStream]
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _rng := RandomNumberGenerator.new()


static func get_inst() -> Sfx:
	if _inst != null and is_instance_valid(_inst):
		return _inst
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	_inst = Sfx.new()
	_inst.name = "Sfx"
	tree.root.add_child.call_deferred(_inst)
	return _inst


func _init() -> void:
	cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json"))
	_rng.randomize()
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS), float(cfg.get("volume_db", -2.0)))
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		_players.append(p)


func _ready() -> void:
	for p in _players:
		add_child(p)
	get_tree().node_added.connect(_on_node_added)


## Alle Buttons bekommen Klick- und Hover-Ton, egal in welchem Bildschirm.
func _on_node_added(n: Node) -> void:
	if n is BaseButton:
		var b := n as BaseButton
		b.pressed.connect(func() -> void: play("ui_click"))
		b.mouse_entered.connect(func() -> void: play("ui_hover"))


func _streams(name: String) -> Array:
	if not _cache.has(name):
		var list: Array = []
		for i in range(1, 6):
			var path := "%s%s_%d.wav" % [DIR, name, i]
			if ResourceLoader.exists(path):
				list.append(load(path))
		_cache[name] = list
	return _cache[name]


# ------------------------------------------------------------------ Abspielen

## Einen Klang abspielen (zufaellige Variante, leicht verstimmt).
static func play(name: String, db := 0.0, pitch := 1.0, delay := 0.0) -> void:
	var s := get_inst()
	if s != null:
		s._play(name, db, pitch, delay)


func _play(name: String, db: float, pitch: float, delay: float) -> void:
	played.append(name)
	if played.size() > 40:
		played.pop_front()
	if muted or not is_inside_tree():
		return
	var list := _streams(name)
	if list.is_empty():
		return
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(func() -> void: _play(name, db, pitch, 0.0))
		played.pop_back()
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = list[_rng.randi() % list.size()]
	p.volume_db = db + _rng.randf_range(-1.0, 0.5)
	p.pitch_scale = pitch * _rng.randf_range(0.94, 1.06)
	p.play()


## Angabe aus sfx.json abspielen. u/v: Angreifer/Ziel fuer "@melee".
static func spec(s: Variant, u := {}, v := {}, accent := false) -> void:
	if s == null:
		return
	if s is Array:
		for e: Variant in s:
			spec(e, u, v, accent)
	elif s is Dictionary:
		var d := s as Dictionary
		if d["s"] == "@melee":
			melee(u, v, accent)
		else:
			play(d["s"], float(d.get("db", 0.0)), float(d.get("pitch", 1.0)), float(d.get("delay", 0.0)))
	elif s == "@melee":
		melee(u, v, accent)
	else:
		play(String(s))


static func _cfg() -> Dictionary:
	var s := get_inst()
	return s.cfg if s != null else {}


# ------------------------------------------------------------------ Kampf

static func _mark(u: Dictionary, key: String, default: String) -> String:
	return String(u.get(key, default))


## Nahkampftreffer: Schicht der Waffe des Angreifers + Schicht des Ziels (+ Akzent bei Positionsbonus).
static func melee(att: Dictionary, def: Dictionary, accent := false) -> void:
	var c := _cfg()
	var w := _mark(att, "weapon", "fist")
	var b := _mark(def, "body", "flesh")
	var combo: Dictionary = c.get("combo", {})
	if combo.has(w + "+" + b):
		spec(combo[w + "+" + b])
	else:
		spec((c.get("weapon", {}) as Dictionary).get(w))
		spec((c.get("body", {}) as Dictionary).get(b))
	if accent:
		spec(c.get("accent"))


## Schwung beim Ausholen (Nahkampf).
static func swing(att: Dictionary) -> void:
	spec((_cfg().get("swing", {}) as Dictionary).get(_mark(att, "weapon", "fist"), "whoosh_s"))


## Normaler Fernangriff: Abschuss.
static func shot(att: Dictionary) -> void:
	var r: Dictionary = _cfg().get("ranged", {})
	spec((r.get(att["id"], r.get("default", {})) as Dictionary).get("shot"))


## Treffer eines normalen Fernangriffs.
static func shot_hit(att: Dictionary, def: Dictionary, accent := false) -> void:
	var r: Dictionary = _cfg().get("ranged", {})
	spec((r.get(att["id"], r.get("default", {})) as Dictionary).get("hit"), att, def, accent)


## Fahigkeit: phase = windup | cast | shot | hit | heal | after.
static func ability(id: String, phase: String, u := {}, v := {}) -> void:
	var a: Dictionary = (_cfg().get("abilities", {}) as Dictionary).get(id, {})
	if a.has(phase):
		spec(a[phase], u, v)
	elif phase == "hit" and not a.has("hit"):
		pass


## Ereignis (death, flee, defend, wall_break ...) aus "events".
static func event(name: String) -> void:
	spec((_cfg().get("events", {}) as Dictionary).get(name))
