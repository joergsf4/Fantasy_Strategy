class_name FxNew
extends RefCounted
## Animationen der 14 neuen Faehigkeiten (docs/faehigkeiten_plan.md) und ihrer Status. Wie FxAbilities:
## Anlauf -> Wirkung -> Einschlag -> Nachspiel, aus den Bausteinen von fx.gd zusammengesetzt.

var fx: Fx
var battle: Battle


func _init(f: Fx) -> void:
	fx = f
	battle = f.battle


func _wait(t: float) -> void:
	await fx.get_tree().create_timer(t).timeout


func _pos(u: Dictionary) -> Vector3:
	return (u["node"] as Node3D).position


func _dust(p: Vector3, tint: Color) -> void:
	fx.particles("fx_smoke", p, 6, 1.6, 0.5, 0.7, -0.2, tint, false, 90.0, false)


# ------------------------------------------------------------------ Anlauf

func windup(id: String, u: Dictionary, target: Dictionary) -> void:
	match id:
		"wollmantel":
			fx.hop(u, 0.3, 0.3)
			await fx.projectile("fx_wolle", fx.chest(u, 0.8), fx.chest(target, 0.7), 0.45, 1.1, 0.7, 6.0)
		"baerengebruell":
			fx.squash(u, 0.9, 1.22, 0.45)
			battle._popup(u, "GRAAAH!", Color(1.0, 0.65, 0.3))
			var dir: Vector3 = (_pos(target) - _pos(u)).normalized()
			var roar := fx.make_sprite("fx_bruell", fx.chest(u, 0.9) + dir * 0.7, 0.9, false, Color.WHITE, 3)
			fx.pop(roar, 2.4, 0.6, 0.0, 0.0, 0.3)
			for k in 3:
				fx.shockwave(_pos(u), 0.9 + k * 0.6, Color(1.0, 0.7, 0.35, 0.7), 0.5)
				await _wait(0.12)
			fx.shake(0.16, 0.35)
			await _wait(0.2)
		"stabwirbel":
			fx.squash(u, 1.1, 0.8, 0.3)
			await _wait(0.25)
		"wutanfall":
			fx.squash(u, 1.25, 0.8, 0.5)
			fx.flash_unit(u, Color(2.2, 0.5, 0.4), 0.6)
			fx.shockwave(_pos(u), 1.6, Color(1.0, 0.2, 0.15, 0.8), 0.6)
			fx.light_flash(fx.chest(u, 0.9), Color(1.0, 0.25, 0.2), 3.5, 5.0, 0.6)
			fx.particles("fx_dampf", fx.chest(u, 1.3), 6, 1.2, 0.5, 0.9, -0.8, Color.WHITE, false, 70.0)
			fx.shake(0.1, 0.4)
			await _wait(0.5)
		"bienenkorb":
			fx.hop(u, 0.3, 0.3)
			await _wait(0.25)
		"prost":
			fx.hop(u, 0.15, 0.25)
			await fx.projectile("fx_bierkrug", fx.chest(u, 0.6), fx.chest(target, 0.6), 0.4, 0.5, 0.5, 2.0)
		"bearhug":
			fx.squash(u, 1.2, 0.85, 0.3)
			await _wait(0.2)
		"kyujutsu":
			battle._popup(u, "…", Color(1, 1, 0.8))
			fx.squash(u, 0.9, 1.08, 0.5)
			var gl := fx.make_sprite("soft", fx.chest(u, 0.7), 0.7, true, Color(1.0, 0.95, 0.6, 0.8), 2)
			fx.pop(gl, 0.1, 0.5, 0.0, 0.0, 0.5)
			await _wait(0.45)
		"brandbombe":
			fx.hop(u, 0.2, 0.25)
			fx.particles("fx_star", fx.chest(u, 0.9), 6, 1.5, 0.2, 0.4, 2.0, Color(1.0, 0.7, 0.3), true, 90.0)
			await _wait(0.25)
		"flucht":
			battle._popup(u, "Genug!", Color(0.9, 0.9, 0.9))
			await fx.squash(u, 1.15, 0.85, 0.3)
		"tonikum":
			fx.hop(u, 0.3, 0.3)
			await _wait(0.25)
		"hinterhalt":
			await _shadow_dash(u, target)
		"bellen":
			fx.hop(u, 0.45, 0.35)
			var wuff := fx.make_sprite("fx_wuff", fx.chest(u, 1.7), 0.8, false, Color.WHITE, 3)
			fx.pop(wuff, 1.6, 0.7, 0.0, 0.3, 0.4)
			for k in 3:
				fx.shockwave(_pos(u), 1.0 + k * 0.7, Color(1.0, 1.0, 0.8, 0.6), 0.5)
				await _wait(0.1)
			await _wait(0.2)
		"sternschnuppe":
			fx.hop(u, 0.4, 0.4)
			fx.particles("fx_star", fx.chest(u, 1.2), 10, 2.0, 0.25, 0.8, -0.5, Color(1.0, 0.8, 0.95), true, 180.0)
			fx.light_flash(fx.chest(u, 1.0), Color(1.0, 0.7, 0.9), 2.5, 4.0, 0.6)
			battle._popup(u, "✦", Color(1.0, 0.75, 0.95))
			await _wait(0.3)


## Ninja verschwindet kurz im Schatten und schlaegt von hinten zu.
func _shadow_dash(u: Dictionary, target: Dictionary) -> void:
	var sp := u["sprite"] as Sprite3D
	fx.particles("fx_smoke", fx.chest(u, 0.4), 6, 1.4, 0.5, 0.6, -0.3, Color(0.25, 0.2, 0.35), false, 120.0)
	var tw := fx.create_tween()
	tw.tween_property(sp, "modulate:a", 0.15, 0.2)
	await tw.finished
	var ghost := fx.make_sprite("soft", fx.chest(target, 0.5), 1.2, false, Color(0.1, 0.05, 0.2, 0.7), 2)
	fx.pop(ghost, 0.2, 0.4, 0.0, 0.0, 0.2)
	await fx.lunge(u, _pos(target), 0.8, 0.2)
	var tw2 := fx.create_tween()
	tw2.tween_property(sp, "modulate:a", 1.0, 0.12)


# ------------------------------------------------------------------ Flaechen, Wellen

func cast(id: String, u: Dictionary, target: Dictionary, tiles: Array[Vector2i]) -> void:
	match id:
		"stabwirbel":
			await _spin_staff(u)
		"bellen":
			await fx.tile_wave(u["pos"], tiles, Color(1.0, 1.0, 0.75, 0.5), 0.08, 0.5, true)
		"tonikum":
			var p := fx.ground(battle.to_world(target["pos"]), 0.1)
			await fx.projectile("fx_flasche", fx.chest(u, 0.8), p + Vector3(0, 0.3, 0), 0.5, 1.8, 0.5, 8.0)
			fx.light_flash(p + Vector3(0, 0.5, 0), Color(0.5, 1.0, 0.5), 2.5, 4.0, 0.5)
			fx.shockwave(p, 1.6, Color(0.55, 1.0, 0.55, 0.6), 0.5)
			fx.particles("fx_smoke", p + Vector3(0, 0.2, 0), 10, 1.5, 0.6, 1.0, -0.3, Color(0.55, 0.85, 0.5), false, 90.0)
			for t: Vector2i in tiles:
				var tp := fx.ground(battle.to_world(t), 0.1)
				fx.particles("fx_bubble", tp, 4, 0.8, 0.28, 1.4, -1.2, Color(0.6, 1.0, 0.6), false, 30.0)
			await fx.tile_wave(target["pos"], tiles, Color(0.5, 1.0, 0.5, 0.5), 0.08, 0.6, true)


func _spin_staff(u: Dictionary) -> void:
	var n: Node3D = u["node"]
	var center := n.position + Vector3(0, 0.55, 0)
	var blade := fx.make_sprite("fx_stab", center + Vector3(0.9, 0, 0), 1.5, false, Color.WHITE, 3)
	var sp := u["sprite"] as Sprite3D
	var flip0 := sp.flip_h
	var last := [-1.0]
	var tw := fx.create_tween()
	tw.tween_method(func(t: float) -> void:
		var ang := t * TAU * 2.0
		blade.position = center + Vector3(cos(ang), 0.0, sin(ang)) * 0.9
		fx._sp(blade, "roll", -ang)
		if is_instance_valid(sp):
			sp.flip_h = (int(t * 16.0) % 2 == 0)
		if t - last[0] > 0.06:
			last[0] = t
			var g := fx.make_sprite("fx_slash", blade.position, 1.4, true, Color(1, 1, 1, 0.6), 2)
			fx._sp(g, "roll", -ang)
			fx.pop(g, 1.0, 0.25, 0.0, 0.0, 0.0), 0.0, 1.0, 0.65)
	await tw.finished
	blade.queue_free()
	if is_instance_valid(sp):
		sp.flip_h = flip0
	fx.shockwave(n.position, 1.3, Color(0.9, 0.95, 1.0, 0.7), 0.4)
	fx.shake(0.05, 0.2)


# ------------------------------------------------------------------ Geschosse, Treffer

func before_hit(id: String, u: Dictionary, v: Dictionary, _i: int) -> void:
	match id:
		"bearhug":
			battle._turn_towards(u, v["pos"])
			fx.lunge(u, _pos(v), 0.5, 0.25)
			await fx.squash(v, 1.25, 0.7, 0.3)
		"kyujutsu":
			battle._turn_towards(u, v["pos"])
			await fx.projectile("fx_arrow", fx.chest(u, 0.7), fx.chest(v, 0.55), 0.3, 0.35, 0.8, 0.0, "fx_smoke")
		"brandbombe":
			battle._turn_towards(u, v["pos"])
			await fx.projectile("fx_bombe", fx.chest(u, 0.8), fx.chest(v, 0.5), 0.5, 1.7, 0.45, 9.0, "fx_smoke")
		"sternschnuppe":
			var to := fx.chest(v, 0.5)
			var from := to + Vector3(-5.0, 9.0, -3.0)
			var star := fx.make_sprite("fx_sternschnuppe", from, 1.5, true, Color.WHITE, 3)
			var tw := fx.create_tween()
			var last := [0.0]
			tw.tween_method(func(t: float) -> void:
				star.position = from.lerp(to, t * t)
				if t - last[0] > 0.04:
					last[0] = t
					fx.particles("fx_star", star.position, 2, 0.6, 0.3, 0.5, 0.5, Color(1.0, 0.8, 0.95), true, 180.0), 0.0, 1.0, 0.55)
			await tw.finished
			star.queue_free()


func on_hit(id: String, u: Dictionary, v: Dictionary, _i: int) -> void:
	var p := fx.chest(v, 0.5)
	match id:
		"stabwirbel":
			var sl := fx.make_sprite("fx_slash", p, 1.1, true)
			fx.pop(sl, 1.4, 0.25, 0.5)
			fx.flash_unit(v, Color(2, 2, 2), 0.12)
		"bearhug":
			var k := fx.make_sprite("fx_krack", p + Vector3(0, 0.5, 0), 1.2, false, Color.WHITE, 4)
			fx.pop(k, 1.5, 0.7, 0.0, 0.3, 0.5)
			fx.particles("fx_star", p, 10, 3.0, 0.3, 0.6, 3.0, Color(1.0, 0.9, 0.5), true, 180.0)
			fx.shake(0.18, 0.3)
			fx.hitstop(0.12)
			fx.squash(v, 1.3, 0.65, 0.4)
		"kyujutsu":
			fx.particles("fx_star", p, 5, 2.0, 0.22, 0.4, 2.0, Color(1.0, 0.95, 0.7), true, 120.0)
			fx.flash_unit(v, Color(2, 2, 2), 0.1)
			fx.knockback(v, _pos(u), 0.2, 0.2)
		"brandbombe":
			fx._explosion(p, 0.8)
			fx.shake(0.1, 0.25)
		"sternschnuppe":
			fx.shockwave(_pos(v), 1.5, Color(1.0, 0.75, 0.95, 0.8), 0.5)
			fx.light_flash(p, Color(1.0, 0.75, 0.95), 3.0, 5.0, 0.5)
			fx.particles("fx_star", p, 14, 3.5, 0.3, 0.8, 2.0, Color(1.0, 0.85, 0.95), true, 180.0)
			fx.shake(0.1, 0.25)
			fx.flash_unit(v, Color(2.2, 1.6, 2.0), 0.2)


# ------------------------------------------------------------------ Status

## Nach dem Setzen eines Status. true = hier erledigt (kein Standard-Popup).
func status(id: String, u: Dictionary, v: Dictionary, status_id: String) -> bool:
	var p := fx.chest(v, 0.6)
	match status_id:
		"schild":
			var puff := fx.make_sprite("fx_wolle", fx.chest(v, 0.7), 0.8, false, Color.WHITE, 3)
			fx.pop(puff, 2.0, 0.6, 0.0, 0.1, 0.5)
			fx.particles("fx_smoke", p, 8, 1.4, 0.4, 0.8, -0.3, Color(1, 1, 0.95, 0.9), false, 140.0)
			fx.particles("fx_flower", p, 5, 1.6, 0.18, 0.9, 0.5, Color(1, 1, 1), false, 160.0)
			fx.light_flash(p, Color(1.0, 0.97, 0.9), 1.8, 3.0, 0.35)
			battle._popup(v, "Wollmantel", Color(0.95, 0.95, 0.85))
			await fx.squash(v, 1.15, 0.88, 0.3)
			return true
		"angst":
			fx.particles("fx_sweat", fx.chest(v, 1.3), 5, 1.0, 0.25, 0.8, 4.0, Color.WHITE, false, 60.0)
			var ex := fx.make_sprite("fx_exclaim", fx.chest(v, 1.9), 0.45, false, Color(0.7, 0.8, 1.0))
			fx.pop(ex, 1.4, 0.6, 0.0, 0.2, 0.4)
			battle._popup(v, "Angst!", Color(0.7, 0.8, 1.0))
			await scared_shiver(v)
			return true
		"wut":
			battle._popup(u, "Wutanfall!", Color(1.0, 0.3, 0.25))
			return true
		"brennen":
			fx.particles("fx_flamme", fx.chest(v, 0.2), 8, 1.8, 0.45, 0.8, -1.5, Color.WHITE, true, 50.0)
			fx.light_flash(p, Color(1.0, 0.55, 0.15), 2.5, 4.0, 0.5)
			battle._popup(v, "Brennt!", Color(1.0, 0.6, 0.2))
			await fx.squash(v, 0.9, 1.15, 0.3)
			return true
		"tempo":
			var boot := fx.make_sprite("fx_fluegelschuh", fx.chest(v, 0.2), 0.45, false, Color.WHITE, 3)
			fx.pop(boot, 1.6, 0.8, 0.0, 1.2, 0.5)
			fx.particles("fx_arrow_up", fx.chest(v, 0.1), 3, 1.2, 0.3, 0.9, -1.2, Color(0.7, 1.0, 0.7), true, 25.0)
			fx.hop(v, 0.3, 0.3)
			battle._popup(v, "Beflügelt", Color(0.6, 1.0, 0.7))
			await _wait(0.15)
			return true
		"uebel":
			var sick := fx.make_sprite("fx_uebel", fx.chest(v, 1.9), 0.5, false, Color.WHITE, 3)
			fx.pop(sick, 1.5, 0.9, 0.0, 0.2, 0.5)
			fx.particles("fx_bubble", fx.chest(v, 0.3), 6, 1.0, 0.25, 1.2, -1.0, Color(0.6, 1.0, 0.4), false, 40.0)
			fx.flash_unit(v, Color(0.7, 1.4, 0.6), 0.5)
			battle._popup(v, "Übel", Color(0.6, 0.95, 0.35))
			await _wait(0.1)
			return true
	return false


func scared_shiver(v: Dictionary) -> void:
	var sp := v["sprite"] as Sprite3D
	var x0 := sp.position.x
	var tw := fx.create_tween()
	tw.tween_method(func(t: float) -> void:
		if is_instance_valid(sp):
			sp.position.x = x0 + sin(t * 40.0) * 0.06 * (1.0 - t), 0.0, 1.0, 0.45)
	tw.tween_callback(func() -> void:
		if is_instance_valid(sp):
			sp.position.x = x0)
	await tw.finished


func on_heal(id: String, u: Dictionary, v: Dictionary) -> void:
	if id == "prost":
		fx.particles("fx_foam", fx.chest(v, 0.9), 10, 2.5, 0.3, 0.7, 4.0, Color.WHITE, false, 120.0)
		fx.particles("fx_star", fx.chest(v, 0.7), 6, 1.4, 0.2, 0.7, -0.5, Color(1.0, 0.85, 0.3), true, 120.0)
		fx.squash(v, 1.1, 0.9, 0.35)


# ------------------------------------------------------------------ Einzelne Ablaeufe

func hive_appear(u: Dictionary, p: Vector3) -> void:
	var g := fx.ground(p, 0.0)
	var shadow := fx.make_flat("soft", g + Vector3(0, 0.05, 0), 0.9, Color(0, 0, 0, 0.35))
	var hive := fx.make_sprite("fx_bienenstock", g + Vector3(0, 5.0, 0), 1.0, false, Color.WHITE, 3)
	var tw := fx.create_tween()
	tw.tween_property(hive, "position:y", g.y + 0.5, 0.35).set_ease(Tween.EASE_IN)
	await tw.finished
	hive.queue_free()
	shadow.queue_free()
	fx.shockwave(g, 1.4, Color(0.95, 0.8, 0.3, 0.7), 0.4)
	fx.shake(0.1, 0.25)
	_dust(g + Vector3(0, 0.2, 0), Color(0.8, 0.7, 0.5))
	fx.particles("fx_honig", g + Vector3(0, 0.6, 0), 6, 2.0, 0.22, 0.8, 4.0, Color.WHITE, false, 120.0)
	fx.particles("fx_star", g + Vector3(0, 0.8, 0), 10, 2.0, 0.18, 1.2, -0.3, Color(1.0, 0.85, 0.2), true, 180.0)
	await _wait(0.3)


func assassinate(u: Dictionary, v: Dictionary) -> void:
	var p := fx.chest(v, 0.55)
	for k in 2:
		var sl := fx.make_sprite("fx_slash", p, 1.3, true)
		fx.pop(sl, 1.5, 0.3, 0.9 if k == 0 else -0.9)
		await _wait(0.07)
	fx.hitstop(0.1)
	fx.particles("fx_smoke", p, 10, 2.0, 0.6, 0.7, -0.2, Color(0.25, 0.2, 0.3), false, 150.0)
	fx.shake(0.1, 0.2)
	await _wait(0.15)


func rage_burst(u: Dictionary) -> void:
	fx.particles("fx_dampf", fx.chest(u, 1.3), 5, 1.2, 0.5, 0.8, -0.8, Color.WHITE, false, 70.0)
	fx.shockwave(_pos(u), 1.2, Color(1.0, 0.25, 0.2, 0.7), 0.4)
	fx.flash_unit(u, Color(2.0, 0.6, 0.5), 0.25)


func vanish_out(u: Dictionary) -> void:
	var ball := fx.make_sprite("fx_rauchkugel", fx.chest(u, 0.8), 0.4)
	var start := fx.chest(u, 0.8)
	var g := fx.ground(_pos(u), 0.15)
	var tw := fx.create_tween()
	tw.tween_method(func(t: float) -> void:
		ball.position = start.lerp(g, t) + Vector3(0, sin(t * PI) * 0.3, 0), 0.0, 1.0, 0.2)
	await tw.finished
	ball.queue_free()
	var puff := fx.make_sprite("fx_smoke", fx.chest(u, 0.5), 1.1, false, Color(0.7, 0.65, 0.75, 0.95), 3)
	fx.pop(puff, 2.5, 0.9, 0.5, 0.2, 0.4)
	fx.particles("fx_smoke", fx.chest(u, 0.5), 12, 2.2, 0.8, 0.9, -0.3, Color(0.6, 0.55, 0.7), false, 180.0, false)
	fx.shockwave(_pos(u), 1.0, Color(0.75, 0.7, 0.85, 0.6), 0.4)
	var sp := u["sprite"] as Sprite3D
	var tw2 := fx.create_tween()
	tw2.tween_property(sp, "modulate:a", 0.0, 0.2)
	await tw2.finished


func vanish_in(u: Dictionary) -> void:
	var puff := fx.make_sprite("fx_smoke", fx.chest(u, 0.5), 1.1, false, Color(0.7, 0.65, 0.75, 0.95), 3)
	fx.pop(puff, 2.2, 0.8, -0.5, 0.2, 0.4)
	fx.particles("fx_smoke", fx.chest(u, 0.5), 10, 2.0, 0.7, 0.8, -0.3, Color(0.6, 0.55, 0.7), false, 180.0, false)
	var sp := u["sprite"] as Sprite3D
	var tw := fx.create_tween()
	tw.tween_property(sp, "modulate:a", 1.0, 0.25)
	await tw.finished
	fx.particles("fx_star", fx.chest(u, 0.9), 6, 1.5, 0.2, 0.7, -0.5, Color(0.6, 1.0, 0.7), true, 120.0)


# ------------------------------------------------------------------ Dauerhafte Statussymbole

## Zornmarke: vier gedrehte Boegen um eine leere Mitte. Gibt den Halter zurueck (skalierbar).
func _anger_mark(parent: Node3D, pos: Vector3, size: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	for k in 4:
		var ang := PI * 0.25 + k * PI * 0.5
		var arc := fx.make_sprite("fx_wutader", Vector3(cos(ang), sin(ang), 0.0) * size * 0.32, size * 0.5, false, Color.WHITE, 1, holder)
		fx._sp(arc, "roll", ang - PI * 0.25)
	return holder


func status_holder(id: String, root: Node3D) -> bool:
	match id:
		"schild":     # flauschige Huelle: weicher Schein und kreisende Wollflocken
			fx.make_sprite("soft", Vector3(0, 0.75, 0), 1.7, true, Color(1.0, 0.97, 0.88, 0.55), 0, root)
			var flocks: Array[MeshInstance3D] = []
			for i in 3:
				flocks.append(fx.make_sprite("fx_wolle", Vector3(0, 0.8, 0), 0.38, false, Color.WHITE, 1, root))
			var tw := root.create_tween().set_loops()
			tw.tween_method(func(t: float) -> void:
				for i in 3:
					var a := t * TAU + i * TAU / 3.0
					if is_instance_valid(flocks[i]):
						flocks[i].position = Vector3(cos(a) * 0.5, 0.7 + sin(a * 2.0) * 0.12, sin(a) * 0.5), 0.0, 1.0, 2.4)
		"wut":        # rote Aura, pochende Ader und Dampf
			var aura := fx.make_sprite("soft", Vector3(0, 0.75, 0), 1.9, true, Color(1.0, 0.2, 0.15, 0.6), 0, root)
			var vein := _anger_mark(root, Vector3(0.25, 1.85, 0), 0.4)
			var tw2 := root.create_tween().set_loops().set_parallel(true)
			tw2.tween_property(vein, "scale", vein.scale * 1.3, 0.28).set_trans(Tween.TRANS_SINE)
			tw2.tween_property(aura, "scale", aura.scale * 1.1, 0.28).set_trans(Tween.TRANS_SINE)
			tw2.chain().tween_property(vein, "scale", vein.scale, 0.28).set_trans(Tween.TRANS_SINE)
			tw2.parallel().tween_property(aura, "scale", aura.scale, 0.28).set_trans(Tween.TRANS_SINE)
			fx._loop_particles(root, "fx_dampf", Vector3(0, 1.5, 0), 2, 0.5, 0.4, 1.0, -0.8, Color.WHITE)
		"brennen":    # Flammen am Koerper
			fx.make_sprite("soft", Vector3(0, 0.5, 0), 1.3, true, Color(1.0, 0.5, 0.12, 0.6), 0, root)
			fx._loop_particles(root, "fx_flamme", Vector3(0, 0.15, 0), 5, 0.7, 0.5, 0.8, -1.6, Color.WHITE, true)
			fx._loop_particles(root, "fx_smoke", Vector3(0, 1.0, 0), 2, 0.4, 0.4, 1.4, -0.5, Color(0.3, 0.3, 0.3, 0.8))
		"tempo":
			var boot := fx.make_sprite("fx_fluegelschuh", Vector3(0, 1.95, 0), 0.36, false, Color.WHITE, 1, root)
			var tw3 := root.create_tween().set_loops()
			tw3.tween_property(boot, "position:y", 2.05, 0.5).set_trans(Tween.TRANS_SINE)
			tw3.tween_property(boot, "position:y", 1.95, 0.5).set_trans(Tween.TRANS_SINE)
		"uebel":
			var sick := fx.make_sprite("fx_uebel", Vector3(0, 1.95, 0), 0.4, false, Color.WHITE, 1, root)
			var tw4 := root.create_tween().set_loops()
			tw4.tween_property(sick, "position:x", 0.07, 0.3).set_trans(Tween.TRANS_SINE)
			tw4.tween_property(sick, "position:x", -0.07, 0.3).set_trans(Tween.TRANS_SINE)
			fx._loop_particles(root, "fx_bubble", Vector3(0, 0.4, 0), 3, 0.7, 0.2, 1.2, -0.9, Color(0.6, 1.0, 0.4))
		"angst":
			fx._loop_particles(root, "fx_sweat", Vector3(0.2, 1.7, 0), 2, 0.5, 0.2, 1.0, 3.0, Color.WHITE)
		_:
			return false
	return true
