class_name FxAbilities
extends RefCounted
## Animationen der Spezialfaehigkeiten (ausser den drei in fx.gd). Jede Funktion beschreibt einen kurzen,
## lesbaren Ablauf: Anlauf -> Wirkung -> Einschlag -> Nachspiel. Zeiten und Farben stehen in data/fx.json.

var fx: Fx
var battle: Battle


func _init(f: Fx) -> void:
	fx = f
	battle = f.battle


func _wait(t: float) -> void:
	await fx.get_tree().create_timer(t).timeout


func _col(id: String, default: Array) -> Color:
	var a: Array = fx.c(id, "color", default)
	return Color(a[0], a[1], a[2], a[3])


func _pos(u: Dictionary) -> Vector3:
	return (u["node"] as Node3D).position


# ------------------------------------------------------------------ Anlauf

func windup(id: String, u: Dictionary, target: Dictionary) -> void:
	match id:
		"baerenpranke":
			battle._popup(u, "GRRR!", Color(1.0, 0.7, 0.3))
			fx.squash(u, 1.12, 0.82, 0.3)
			await _wait(0.28)
		"schlachtruf":
			fx.hop(u, 0.3, 0.3)
			fx.light_flash(fx.chest(u, 0.9), Color(1, 0.85, 0.4), 3.0, 5.0, 0.5)
			fx.shockwave(_pos(u), 1.1, Color(1.0, 0.85, 0.4, 0.8), 0.45)
			await _wait(0.25)
		"todeswirbel":
			fx.squash(u, 1.1, 0.8, 0.3)
			fx.light_flash(fx.chest(u, 0.7), Color(0.7, 0.85, 1.0), 2.0, 3.0, 0.35)
			await _wait(0.28)
		"versteck":
			await _smoke_bomb(u)
		"roter_laser":
			await _laser_charge(u, target)
		"gruener_laser":
			fx.light_flash(fx.chest(u, 0.9), Color(0.4, 1, 0.6), 2.0, 3.0, 0.3)
			await _wait(0.25)
		"gruppenheilung":
			fx.light_flash(fx.chest(u, 1.0), Color(0.6, 1, 0.7), 2.2, 4.0, 0.5)
			fx.particles("fx_leaf", fx.chest(u, 0.2), 8, 2.0, 0.3, 1.0, 1.5, Color(0.8, 1, 0.8), false, 60.0)
			await fx.squash(u, 0.92, 1.1, 0.3)
		"polymorph":
			fx.hop(u, 0.2, 0.3)
			fx.particles("fx_star", fx.chest(u, 0.9), 8, 1.5, 0.2, 0.7, -0.5, Color(0.75, 0.5, 1.0), true, 90.0)
			await _wait(0.3)
		"giftstachel":
			fx.hop(u, 0.35, 0.35)
			await fx.squash(u, 0.92, 1.1, 0.3)
		"fasswurf":
			await _barrel_up(u)


## Wellen/Flaechen/Strahlen, die vor den Treffern ablaufen.
func cast(id: String, u: Dictionary, target: Dictionary, tiles: Array[Vector2i]) -> void:
	match id:
		"schlachtruf":
			await fx.tile_wave(u["pos"], tiles, _col(id, [1.0, 0.8, 0.25, 0.55]), 0.07, 0.45, true)
		"gruppenheilung":
			await fx.tile_wave(target["pos"], tiles, _col(id, [0.5, 1.0, 0.65, 0.55]), 0.08, 0.5, true)
		"todeswirbel":
			await _spin(u)
		"roter_laser":
			await _laser_fire(u, target)
		"gruener_laser":
			await _green_beam(u, target)


func before_hit(id: String, u: Dictionary, v: Dictionary, _i: int) -> void:
	match id:
		"baerenpranke":
			fx.lunge(u, _pos(v), 0.6, 0.22)
			await _wait(0.12)
		"giftstachel":
			battle._turn_towards(u, v["pos"])
			await fx.projectile("fx_glob", fx.chest(u, 0.65), fx.chest(v, 0.5), 0.4, 0.6, 0.55, 2.0, "fx_bubble")
		"fasswurf":
			await _barrel_throw(u, v)


func on_hit(id: String, u: Dictionary, v: Dictionary, _i: int) -> void:
	match id:
		"baerenpranke":
			_claw(u, v)
		"todeswirbel":
			_slash_hit(u, v)
		"roter_laser":
			_laser_hit(u, v)
		"giftstachel":
			_splat(u, v)
		"fasswurf":
			_barrel_burst(u, v)


func on_status(_id: String, u: Dictionary, v: Dictionary, status: String) -> void:
	match status:
		"buff":
			fx.hop(v, 0.2, 0.2)
			fx.particles("fx_arrow_up", fx.chest(v, 0.2), 3, 1.2, 0.35, 0.9, -1.2, Color(1, 0.9, 0.5), true, 25.0)
			fx.light_flash(fx.chest(v, 0.8), Color(1, 0.85, 0.4), 1.5, 3.0, 0.3)
			await _wait(0.04)
		"tired":
			fx.particles("fx_sweat", fx.chest(u, 1.3), 4, 0.8, 0.3, 0.8, 4.0, Color.WHITE, false, 40.0)
			fx.particles("fx_smoke", fx.chest(u, 0.9), 4, 0.8, 0.3, 0.6, -0.4, Color(1, 1, 1, 0.6), false, 60.0)
			battle._popup(v, "Erschöpft", Color(1, 0.8, 0.5))
			await fx.squash(v, 1.0, 0.88, 0.5)
		"poison":
			battle._popup(v, "Gift", Color(0.6, 1.0, 0.4))
			await _wait(0.1)
		_:
			battle._popup(v, Status.NAMES.get(status, status), Color(1, 0.7, 0.3))
			await _wait(0.1)


func after(id: String, u: Dictionary, target: Dictionary) -> void:
	if id == "stabsprung" and battle.units.has(target):
		# Der Gegner merkt erst nach dem Treffer, dass Lin hinter ihm steht (der Rueckenbonus gilt vorher).
		battle._turn_towards(target, u["pos"])
		battle._popup(target, "?", Color(1, 0.95, 0.5))
		fx.hop(target, 0.2, 0.22)
		await _wait(0.25)
	if id == "fasswurf":   # neues Fass: "plopp"
		var b := fx.make_sprite("fx_barrel", fx.chest(u, 1.2), 0.1)
		fx.pop(b, 7.0, 0.3, 0.0, 0.1, 0.65)
		await _wait(0.2)


# ------------------------------------------------------------------ Heilung

func on_heal(id: String, _u: Dictionary, v: Dictionary, _amount: int, cured: bool) -> void:
	var p := fx.chest(v, 0.2)
	fx.particles("fx_cross", p, 5, 1.0, 0.4, 0.9, -1.8, Color.WHITE, true, 25.0)
	fx.light_flash(fx.chest(v, 0.8), Color(0.4, 1, 0.6), 1.6, 3.0, 0.4)
	fx.flash_unit(v, Color(0.8, 1.6, 0.9), 0.3)
	if cured:
		fx.particles("fx_bubble", fx.chest(v, 0.6), 9, 2.2, 0.28, 0.6, 1.0, Color(0.7, 1, 0.7), false, 180.0)
	if id == "gruppenheilung":
		var g := fx.ground(_pos(v), 0.05)
		for k in 3:
			var off := Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.3, 0.3))
			var fl := fx.make_sprite("fx_flower", g + off + Vector3(0, 0.12, 0), 0.05)
			var tw := fx.create_tween()
			tw.tween_property(fl, "scale", fl.scale * 8.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(k * 0.08)
			tw.tween_method(func(t: float) -> void: fx._sp(fl, "alpha", 1.0 - t), 0.0, 1.0, 0.5).set_delay(0.8)
			tw.finished.connect(fl.queue_free)


# ------------------------------------------------------------------ Einzel-Effekte

func _claw(u: Dictionary, v: Dictionary) -> void:
	var pos := fx.chest(v, 0.6)
	var claw := fx.make_sprite(str(fx.c("baerenpranke", "claw", "fx_claw")), pos, 1.5, false, Color.WHITE, 3)
	fx.pop(claw, 1.2, 0.35, -0.25, 0.0, 0.5)
	fx.particles("fx_smoke", fx.ground(_pos(v), 0.15), 6, 1.4, 0.3, 0.5, 1.0, Color(0.85, 0.8, 0.7), false, 60.0)
	fx.shake(0.06, 0.2)
	fx.hitstop(0.06)
	fx.flash_unit(v, Color(2, 2, 2), 0.15)
	fx.knockback(v, _pos(u), 0.22, 0.25)


func _slash_hit(u: Dictionary, v: Dictionary) -> void:
	var sl := fx.make_sprite("fx_slash", fx.chest(v, 0.6), 1.3, true, Color.WHITE, 3)
	fx.pop(sl, 1.3, 0.25, randf_range(-0.8, 0.8))
	fx.flash_unit(v, Color(2, 2, 2), 0.15)
	fx.knockback(v, _pos(u), 0.25, 0.3)
	fx.shake(0.04, 0.12)


func _splat(u: Dictionary, v: Dictionary) -> void:
	var pos := fx.chest(v, 0.5)
	fx.particles("fx_glob", pos, 8, 3.0, 0.2, 0.6, 7.0, Color(0.6, 1, 0.5), false, 120.0)
	fx.particles("fx_bubble", pos, 6, 1.2, 0.25, 1.0, -1.2, Color(0.7, 1, 0.7), false, 40.0)
	fx.flash_unit(v, Color(0.6, 1.4, 0.6), 0.3)
	fx.scorch(_pos(v), 0.9, Color(0.35, 0.8, 0.2, 0.5), 2.0)
	fx.shake(0.03, 0.12)
	fx.knockback(v, _pos(u), 0.12, 0.2)


func _barrel_up(u: Dictionary) -> void:
	var b := fx.make_sprite("fx_barrel", fx.chest(u, 1.2), 0.1, false, Color.WHITE, 2)
	u["_barrel"] = b
	var tw := fx.create_tween().set_parallel(true)
	tw.tween_property(b, "scale", b.scale * 9.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "position:y", b.position.y + 0.5, 0.28)
	fx.squash(u, 0.92, 1.12, 0.3)
	await tw.finished
	await _wait(0.12)


func _barrel_throw(u: Dictionary, v: Dictionary) -> void:
	var held: Variant = u.get("_barrel")
	var from := fx.chest(u, 1.7)
	if held != null and is_instance_valid(held):
		(held as Node).queue_free()
	u.erase("_barrel")
	battle._turn_towards(u, v["pos"])
	await fx.projectile("fx_barrel", from, fx.chest(v, 0.6), 0.5, 1.3, 0.9, 8.0)


func _barrel_burst(_u: Dictionary, v: Dictionary) -> void:
	var pos := fx.chest(v, 0.6)
	fx.particles("fx_barrel", pos, 7, 4.5, 0.28, 0.8, 9.0, Color.WHITE, false, 100.0)
	var foam := fx.make_sprite("fx_foam", pos, 0.8, false, Color.WHITE, 3)
	fx.pop(foam, 2.6, 0.5, 0.2, 0.2, 0.4)
	fx.particles("soft", pos, 14, 3.5, 0.14, 0.7, 8.0, Color(0.9, 0.6, 0.15), false, 110.0)
	fx.scorch(_pos(v), 1.4, Color(0.7, 0.45, 0.1, 0.55), 3.0)
	fx.flash_unit(v, Color(1.5, 1.25, 0.8), 0.3)
	fx.shake(0.08, 0.25)
	fx.hitstop(0.05)


# ------------------------------------------------------------------ Todeswirbel

func _spin(u: Dictionary) -> void:
	var n: Node3D = u["node"]
	var center := n.position + Vector3(0, 0.55, 0)
	var radius := float(fx.c("todeswirbel", "radius", 0.95))
	var spins := float(fx.c("todeswirbel", "spins", 2))
	var time := float(fx.c("todeswirbel", "time", 0.65))
	var blade := fx.make_sprite("fx_slash", center + Vector3(radius, 0, 0), 1.6, true, Color.WHITE, 3)
	var sp := u["sprite"] as Sprite3D
	var flip0 := sp.flip_h
	var last := [-1.0]
	var tw := fx.create_tween()
	tw.tween_method(func(t: float) -> void:
		var ang := t * TAU * spins
		blade.position = center + Vector3(cos(ang), 0.0, sin(ang)) * radius
		fx._sp(blade, "roll", -ang)
		if is_instance_valid(sp):
			sp.flip_h = (int(t * 16.0) % 2 == 0)
		if t - last[0] > 0.05:
			last[0] = t
			var g := fx.make_sprite("fx_slash", blade.position, 1.6, true, Color(1, 1, 1, 0.7), 2)
			fx._sp(g, "roll", -ang)
			fx.pop(g, 1.0, 0.25, 0.0, 0.0, 0.0), 0.0, 1.0, time)
	await tw.finished
	blade.queue_free()
	if is_instance_valid(sp):
		sp.flip_h = flip0
	fx.shockwave(n.position, 1.3, Color(0.8, 0.9, 1.0, 0.7), 0.4)
	fx.particles("fx_leaf", fx.chest(u, 0.1), 10, 3.5, 0.3, 0.9, 4.0, Color.WHITE, false, 120.0)
	fx.particles("fx_smoke", fx.ground(n.position, 0.15), 6, 2.0, 0.4, 0.6, 1.0, Color(0.85, 0.8, 0.7), false, 90.0)
	fx.shake(0.05, 0.2)


# ------------------------------------------------------------------ Versteck

func _smoke_bomb(u: Dictionary) -> void:
	var n: Node3D = u["node"]
	var pos := n.position
	var bomb := fx.make_sprite("fx_cannonball", fx.chest(u, 0.8), 0.28, false, Color(0.55, 0.45, 0.65))
	var start := fx.chest(u, 0.8)
	var tw := fx.create_tween()
	tw.tween_method(func(t: float) -> void:
		bomb.position = start.lerp(fx.ground(pos, 0.15), t) + Vector3(0, sin(t * PI) * 0.4, 0), 0.0, 1.0, 0.25)
	await tw.finished
	bomb.queue_free()
	var puff := fx.make_sprite("fx_smoke", fx.chest(u, 0.5), 1.0, false, Color(0.55, 0.45, 0.7, 0.95), 3)
	fx.pop(puff, 2.4, 0.9, 0.5, 0.2, 0.4)
	fx.particles("fx_smoke", fx.chest(u, 0.5), 12, 2.2, 0.8, 0.9, -0.3, Color(0.5, 0.4, 0.65), false, 180.0, false)
	fx.particles("fx_leaf", fx.chest(u, 0.5), 8, 3.0, 0.25, 1.0, 3.0, Color.WHITE, false, 120.0)
	fx.light_flash(fx.chest(u, 0.6), Color(0.6, 0.4, 1.0), 2.0, 3.0, 0.35)
	fx.shockwave(pos, 1.0, Color(0.7, 0.55, 1.0, 0.6), 0.4)
	await _wait(0.35)


# ------------------------------------------------------------------ Laser

func _line_end(u: Dictionary, target: Dictionary) -> Vector3:
	var rmax := int(battle.abilities["roter_laser"]["range"][1])
	var d := Vector2i(signi(target["pos"].x - u["pos"].x), signi(target["pos"].y - u["pos"].y))
	var end_tile: Vector2i = u["pos"]
	for k in range(1, rmax + 1):
		var p: Vector2i = u["pos"] + d * k
		if battle.grid.inside(p):
			end_tile = p
	return battle.to_world(end_tile)


func _laser_charge(u: Dictionary, target: Dictionary) -> void:
	var from := fx.chest(u, 0.75)
	var glow := fx.make_sprite("soft", from, 0.2, true, Color(1, 0.25, 0.15, 0.9), 2)
	var tw := fx.create_tween().set_parallel(true)
	tw.tween_property(glow, "scale", glow.scale * 5.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(t: float) -> void: fx._sp(glow, "alpha", 0.7 + 0.3 * sin(t * 40.0)), 0.0, 1.0, 0.5)
	tw.finished.connect(glow.queue_free)
	var end := _line_end(u, target)
	fx.beam(from, Vector3(end.x, from.y, end.z), Color(1, 0.2, 0.1), 0.05, 0.5)   # Visierlinie
	fx.particles("fx_smoke", fx.chest(u, 1.1), 4, 0.7, 0.35, 0.8, -0.5, Color(1, 1, 1, 0.6), false, 50.0)
	await _wait(0.5)


func _laser_fire(u: Dictionary, target: Dictionary) -> void:
	var dirw := (_line_end(u, target) - _pos(u))
	dirw.y = 0.0
	dirw = dirw.normalized()
	var from := fx.chest(u, 0.75) + dirw * 0.4
	var end := _line_end(u, target)
	end.y = from.y
	fx.shake(0.07, 0.4)
	fx.light_flash(from, Color(1, 0.3, 0.2), 3.0, 4.0, 0.4)
	for p in battle._line_tiles(u["pos"], target["pos"], int(battle.abilities["roter_laser"]["range"][1])):
		fx.scorch(battle.to_world(p), 0.9, Color(0.05, 0.02, 0.02, 0.6), 3.0)
	await fx.beam(from, end, Color(1.0, 0.2, 0.1), float(fx.c("roter_laser", "width", 0.3)), float(fx.c("roter_laser", "beam_time", 0.4)))


func _laser_hit(u: Dictionary, v: Dictionary) -> void:
	var pos := fx.chest(v, 0.6)
	var st := fx.make_sprite("fx_star", pos, 0.7, true, Color(1, 0.6, 0.4))
	fx.pop(st, 1.8, 0.25, 0.5)
	fx.particles("soft", pos, 8, 3.0, 0.1, 0.5, 6.0, Color(1, 0.7, 0.4), true, 120.0)
	fx.flash_unit(v, Color(2.4, 1.6, 1.4), 0.2)
	fx.knockback(v, _pos(u), 0.18, 0.25)
	fx.hitstop(0.05)


func _green_beam(u: Dictionary, target: Dictionary) -> void:
	var from := fx.chest(u, 0.75)
	var to := fx.chest(target, 0.6)
	for i in 5:
		var p := from.lerp(to, float(i + 1) / 6.0)
		var t := float(i) * 0.05
		fx.get_tree().create_timer(t).timeout.connect(func() -> void:
			var cr := fx.make_sprite("fx_cross", p, 0.35, true)
			fx.pop(cr, 1.5, 0.3, 0.0, 0.2, 0.3))
	await fx.beam(from, to, Color(0.3, 1.0, 0.5), 0.12, 0.35)


# ------------------------------------------------------------------ Wurf

func throw_anim(u: Dictionary, target: Dictionary, valid: Array, chosen_dir: int, landing: Vector2i) -> void:
	var tn := target["node"] as Node3D
	var un := u["node"] as Node3D
	var home := tn.position
	# 1) Greifen und ueber den Kopf stemmen
	var up := un.position + Vector3(0, 1.3, 0)
	fx.squash(u, 1.18, 0.85, 0.3)
	var st := fx.make_sprite("fx_star", fx.chest(u, 0.9) + Vector3(0.3, 0, 0), 0.5, true)
	fx.pop(st, 1.8, 0.3, 0.4)
	var lift := fx.create_tween()
	lift.tween_property(tn, "position", up, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await lift.finished
	# 2) Richtungs-Roulette: vier Pfeile am Boden, die Auswahl rastet ein
	var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	var arrows: Array[MeshInstance3D] = []
	var base := fx.ground(home, 0.1)
	for i in 4:
		var d: Vector2i = dirs[i]
		var a := fx.make_flat("fx_arrow_up", base + Vector3(d.x * 0.75, 0, d.y * 0.75), 0.6, Color(0.5, 0.5, 0.55, 0.0) if not valid[i] else Color(1, 0.85, 0.4, 0.0), false)
		a.rotation = Vector3(-PI / 2.0, atan2(-float(d.x), -float(d.y)), 0.0)
		arrows.append(a)
	var usable: Array[int] = []
	for i in 4:
		if valid[i]:
			usable.append(i)
	for a in arrows:
		var m := a.material_override as StandardMaterial3D
		var tw := fx.create_tween()
		tw.tween_property(m, "albedo_color:a", 0.85, 0.15)
	if not usable.is_empty():
		var seq: Array[int] = []
		var cur := chosen_dir
		for k in 9:
			seq.push_front(cur)
			cur = usable[(usable.find(cur) - 1 + usable.size()) % usable.size()]
		for k in seq.size():
			var a := arrows[seq[k]]
			var m := a.material_override as StandardMaterial3D
			m.albedo_color = Color(1, 1, 0.6, 1)
			a.scale = Vector3.ONE * 1.35
			await _wait(0.05 + 0.012 * k)
			m.albedo_color = Color(1, 0.85, 0.4, 0.85)
			a.scale = Vector3.ONE
		arrows[chosen_dir].scale = Vector3.ONE * 1.5
		(arrows[chosen_dir].material_override as StandardMaterial3D).albedo_color = Color(1, 1, 0.5, 1)
		await _wait(0.15)
	# 3) Wurf
	fx.shake(0.05, 0.15)
	for a in arrows:
		a.queue_free()
	if landing != target["pos"]:
		await fx.leap(target, landing, float(fx.c("wurf", "height", 2.6)), float(fx.c("wurf", "time", 0.7)), 2.0)
	else:
		var drop := fx.create_tween()
		drop.tween_property(tn, "position", home, 0.2).set_ease(Tween.EASE_IN)
		await drop.finished
	# 4) Aufprall
	var at := _pos(target)
	fx.shockwave(at, 1.4, Color(0.8, 0.65, 0.4, 0.8), 0.45)
	fx.scorch(at, 1.2, Color(0.2, 0.12, 0.06, 0.6), 3.0)
	fx.particles("soft", fx.ground(at, 0.2), 14, 4.0, 0.16, 0.7, 9.0, Color(0.45, 0.32, 0.2), false, 80.0)
	fx.particles("fx_smoke", fx.ground(at, 0.2), 6, 2.0, 0.5, 0.7, 0.5, Color(0.85, 0.8, 0.7), false, 70.0)
	fx.shake(0.12, 0.35)
	fx.hitstop(0.07)


# ------------------------------------------------------------------ Polymorph

## Naechster Kartenrand: Ausgangspunkt der Frosch-Flucht und der Rueckkehr.
func _edge_point(p: Vector2i) -> Vector3:
	var w := battle.grid.width
	var h := battle.grid.height
	var best := p.x
	var out := Vector3(-3.5, 0, p.y)
	if w - 1 - p.x < best:
		best = w - 1 - p.x
		out = Vector3(w + 2.5, 0, p.y)
	if p.y < best:
		best = p.y
		out = Vector3(p.x, 0, -3.5)
	if h - 1 - p.y < best:
		out = Vector3(p.x, 0, h + 2.5)
	return out


func _frog_hops(frog: MeshInstance3D, from: Vector3, to: Vector3, hops: int) -> void:
	for i in hops:
		var a := from.lerp(to, float(i) / hops)
		var b := from.lerp(to, float(i + 1) / hops)
		var tw := fx.create_tween()
		tw.tween_method(func(t: float) -> void:
			var p := a.lerp(b, t)
			var g := fx.ground(p, 0.2)
			p.y = g.y + sin(t * PI) * 0.55
			frog.position = p, 0.0, 1.0, 0.3)
		await tw.finished
		await _wait(0.06)


func polymorph_out(_caster: Dictionary, v: Dictionary) -> void:
	var at := _pos(v)
	# Runenscheibe unter dem Ziel
	var rune := fx.make_flat("fx_rune", fx.ground(at, 0.08), 2.0, Color(0.75, 0.45, 1.0, 0.0), true)
	rune.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	var rm := rune.material_override as StandardMaterial3D
	var rt := fx.create_tween().set_parallel(true)
	rt.tween_property(rm, "albedo_color:a", 0.9, 0.3)
	rt.tween_method(func(t: float) -> void: rune.rotation.y = t * 5.0, 0.0, 1.0, 1.1)
	rt.tween_property(rm, "albedo_color:a", 0.0, 0.3).set_delay(0.8)
	rt.finished.connect(rune.queue_free)
	fx.particles("fx_star", fx.ground(at, 0.2), 18, 2.2, 0.2, 0.9, -1.2, Color(0.75, 0.5, 1.0), true, 40.0)
	fx.light_flash(fx.chest(v, 0.6), Color(0.7, 0.45, 1.0), 3.0, 4.0, 0.8)
	await _wait(0.6)
	# Blitz, Puff, Verwandlung
	fx.flash_unit(v, Color(4, 4, 4), 0.2)
	var puff := fx.make_sprite("fx_smoke", fx.chest(v, 0.6), 1.0, false, Color(0.7, 0.55, 1.0, 0.95), 3)
	fx.pop(puff, 2.4, 0.7, 0.4, 0.3, 0.4)
	(v["sprite"] as Sprite3D).visible = false
	var frog := fx.make_sprite("fx_frog", fx.ground(at, 0.2), 0.75, false, Color.WHITE, 2)
	battle._popup(v, "Quak!", Color(0.6, 1, 0.5))
	await _wait(0.4)
	# davonhuepfen
	await _frog_hops(frog, frog.position, _edge_point(v["pos"]), int(fx.c("polymorph", "hops", 3)))
	frog.queue_free()
	(v["sprite"] as Sprite3D).visible = true


func polymorph_in(v: Dictionary) -> void:
	var to := fx.ground(_pos(v), 0.2)
	var frog := fx.make_sprite("fx_frog", _edge_point(v["pos"]), 0.75, false, Color.WHITE, 2)
	await _frog_hops(frog, frog.position, to, int(fx.c("polymorph", "hops", 3)))
	var puff := fx.make_sprite("fx_smoke", fx.chest(v, 0.5), 0.9, false, Color(0.7, 0.55, 1.0, 0.95), 3)
	fx.pop(puff, 2.4, 0.6, 0.4, 0.3, 0.4)
	fx.particles("fx_star", to, 12, 2.0, 0.2, 0.8, -0.6, Color(0.75, 0.5, 1.0), true, 90.0)
	frog.queue_free()
	await _wait(0.1)
