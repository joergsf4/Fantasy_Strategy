class_name Fx
extends Node3D
## Kampfanimationen in 3D auf der Karte: Pixel-Sprites (aus assets/fx/), die fliegen, wachsen und verglimmen,
## dazu Licht, Kamerawackeln und Hitstop. Parameter pro Faehigkeit stehen in data/fx.json.

const FX_DIR := "res://assets/fx/"

var battle: Battle
var terrain: TerrainView
var cfg: Dictionary = {}
var _quad: QuadMesh
var _shader_mix: Shader
var _shader_add: Shader
var _tex_cache: Dictionary = {}
var _soft: Texture2D
var _ring: Texture2D
var _hitstop_busy := false
var ab: FxAbilities
var nw: FxNew


func setup(b: Battle) -> void:
	battle = b
	terrain = b.terrain
	cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/fx.json"))
	_quad = QuadMesh.new()
	_quad.size = Vector2.ONE
	var src := FileAccess.get_file_as_string("res://shaders/fx_sprite.gdshader")
	_shader_mix = Shader.new()
	_shader_mix.code = src
	_shader_add = Shader.new()
	_shader_add.code = src.replace("blend_mix", "blend_add")
	_soft = _make_soft()
	_ring = _make_ring()
	ab = FxAbilities.new(self)
	nw = FxNew.new(self)


## Hat diese Faehigkeit eine eigene Animation?
func has_fx(id: String) -> bool:
	return cfg.has(id)


func c(id: String, key: String, default: Variant) -> Variant:
	return cfg.get(id, {}).get(key, default)


# ------------------------------------------------------------------ Texturen und Sprites

func _make_soft() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 32.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)


func _make_ring() -> Texture2D:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var d := Vector2(x - 63.5, y - 63.5).length() / 64.0
			var a := clampf(1.0 - absf(d - 0.82) / 0.14, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)


func tex(name: String) -> Texture2D:
	if name == "soft":
		return _soft
	if name == "ring":
		return _ring
	if _tex_cache.has(name):
		return _tex_cache[name]
	var p := FX_DIR + name + ".png"
	var t: Texture2D = load(p) if ResourceLoader.exists(p) else _soft
	_tex_cache[name] = t
	return t


## Billboard-Sprite im Raum. size = laengste Kante in Welteinheiten.
func make_sprite(name: String, pos: Vector3, size: float, additive := false, tint := Color.WHITE, priority := 0, parent: Node = null) -> MeshInstance3D:
	var t := tex(name)
	var mi := MeshInstance3D.new()
	mi.mesh = _quad
	var m := ShaderMaterial.new()
	m.shader = _shader_add if additive else _shader_mix
	m.set_shader_parameter("tex", t)
	m.set_shader_parameter("tint", tint)
	m.render_priority = priority
	mi.material_override = m
	mi.position = pos
	var s := t.get_size()
	var k := size / maxf(s.x, s.y)
	mi.scale = Vector3(s.x * k, s.y * k, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent != null else self).add_child(mi)
	return mi


## Flache Scheibe auf dem Boden (Ring, Brandfleck, Schatten).
func make_flat(name: String, pos: Vector3, size: float, color: Color, additive := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	mi.rotation_degrees = Vector3(-90, 0, 0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.albedo_texture = tex(name)
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func ground(p: Vector3, lift := 0.06) -> Vector3:
	return Vector3(p.x, maxf(terrain.height_at(p.x, p.z), TerrainView.WATER_LEVEL) + lift, p.z)


func chest(u: Dictionary, h := 0.75) -> Vector3:
	return (u["node"] as Node3D).position + Vector3(0, h, 0)


func _sp(mi: MeshInstance3D, key: String, v: Variant) -> void:
	if is_instance_valid(mi):
		(mi.material_override as ShaderMaterial).set_shader_parameter(key, v)


# ------------------------------------------------------------------ Bausteine

## Sprite wachsen, drehen, steigen und ausblenden lassen; raeumt sich selbst auf.
func pop(mi: MeshInstance3D, grow := 1.5, time := 0.4, roll := 0.0, rise := 0.0, fade_from := 0.4) -> Tween:
	var s0 := mi.scale
	var p0 := mi.position
	var tw := create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", s0 * grow, time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if rise != 0.0:
		tw.tween_property(mi, "position", p0 + Vector3(0, rise, 0), time)
	if roll != 0.0:
		tw.tween_method(func(v: float) -> void: _sp(mi, "roll", v), 0.0, roll, time)
	tw.tween_method(func(v: float) -> void: _sp(mi, "alpha", v), 1.0, 0.0, time * (1.0 - fade_from)).set_delay(time * fade_from)
	tw.finished.connect(mi.queue_free)
	return tw


## Geschoss auf einer Parabel (Schatten am Boden, optional Rauchspur). Wartet bis zum Einschlag.
func projectile(name: String, from: Vector3, to: Vector3, time: float, arc: float, size: float, spin := 0.0, trail := "") -> void:
	var mi := make_sprite(name, from, size)
	var shadow := make_flat("soft", ground(from), size * 1.3, Color(0, 0, 0, 0.4))
	var tw := create_tween()
	var last := 0.0
	tw.tween_method(func(t: float) -> void:
		var p := from.lerp(to, t)
		p.y += sin(t * PI) * arc
		mi.position = p
		_sp(mi, "roll", spin * t)
		var g := ground(Vector3(p.x, 0, p.z))
		shadow.position = g
		shadow.scale = Vector3.ONE * clampf(1.2 - (p.y - g.y) * 0.15, 0.5, 1.2)
		if trail != "" and t - last > 0.07:
			last = t
			var puff := make_sprite(trail, p, size * 0.8, false, Color(1, 1, 1, 0.8))
			pop(puff, 1.7, 0.45, 0.3, 0.15, 0.2), 0.0, 1.0, time)
	await tw.finished
	mi.queue_free()
	shadow.queue_free()


## Felder leuchten nach Entfernung vom Zentrum nacheinander auf (zeigt die echte Rautenform).
func tile_wave(origin: Vector2i, tiles: Array[Vector2i], color: Color, step := 0.09, life := 0.5, additive := true) -> void:
	if tiles.is_empty():
		return
	var tw := create_tween().set_parallel(true)
	for p in tiles:
		var mi := MeshInstance3D.new()
		mi.mesh = terrain.tile_mesh(p, 0.49, 0.05)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
		m.albedo_color = Color(color.r, color.g, color.b, 0.0)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		var delay := float(Grid.dist(origin, p)) * step
		tw.tween_property(m, "albedo_color:a", color.a, life * 0.3).set_delay(delay)
		tw.tween_property(m, "albedo_color:a", 0.0, life * 0.7).set_delay(delay + life * 0.3)
		tw.tween_callback(mi.queue_free).set_delay(delay + life)
	await tw.finished


## Schockring, der auf dem Boden nach aussen laeuft.
func shockwave(pos: Vector3, radius: float, color: Color, time := 0.45) -> void:
	var mi := make_flat("ring", ground(pos, 0.08), 0.4, color, true)
	var m := mi.material_override as StandardMaterial3D
	var tw := create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * (radius * 2.0 / 0.4), time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, time).set_delay(time * 0.25)
	tw.finished.connect(mi.queue_free)


## Dunkler Fleck, der langsam verschwindet (Brandfleck, Bierlache ...).
func scorch(pos: Vector3, size: float, color: Color, time := 3.0) -> void:
	var mi := make_flat("soft", ground(pos, 0.045), size, color)
	var m := mi.material_override as StandardMaterial3D
	var tw := create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, time).set_delay(time * 0.3)
	tw.finished.connect(mi.queue_free)


func light_flash(pos: Vector3, color: Color, energy := 3.0, range_ := 4.0, time := 0.35) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_
	l.position = pos
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.0, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.finished.connect(l.queue_free)


## Splitter/Funken/Staub als Partikel (CPUParticles3D laeuft im Compatibility-Renderer sicher).
func particles(name: String, pos: Vector3, count: int, speed: float, size: float, life := 0.7, gravity := 6.0, tint := Color.WHITE, additive := false, spread := 180.0, up := true) -> void:
	var p := CPUParticles3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	var m := ShaderMaterial.new()
	m.shader = _shader_add if additive else _shader_mix
	m.set_shader_parameter("tex", tex(name))
	mesh.material = m
	p.mesh = mesh
	p.position = pos
	p.amount = count
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3.UP if up else Vector3.ZERO
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -gravity, 0)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var g := Gradient.new()
	g.set_color(0, Color(tint.r, tint.g, tint.b, 1.0))
	g.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)


func shake(amount: float, time := 0.3) -> void:
	var cam := battle.cam
	if cam == null:
		return
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		var k := (1.0 - t) * amount
		cam.h_offset = randf_range(-k, k)
		cam.v_offset = randf_range(-k, k), 0.0, 1.0, time)
	tw.tween_callback(func() -> void:
		cam.h_offset = 0.0
		cam.v_offset = 0.0)


## Kurzes Einfrieren beim Treffer (laeuft in Echtzeit, unabhaengig vom Zeitmassstab).
func hitstop(real_time := 0.06) -> void:
	if _hitstop_busy:
		return
	_hitstop_busy = true
	var prev := Engine.time_scale
	Engine.time_scale = 0.04
	await get_tree().create_timer(real_time, true, false, true).timeout
	Engine.time_scale = prev
	_hitstop_busy = false


# ------------------------------------------------------------------ Einheiten bewegen/faerben

func squash(u: Dictionary, sx: float, sy: float, time := 0.2) -> void:
	var sp := u["sprite"] as Sprite3D
	var tw := create_tween()
	tw.tween_property(sp, "scale", Vector3(sx, sy, 1.0), time * 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(sp, "scale", Vector3.ONE, time * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished


## Verteidigen: kurzes Zusammenducken, blauer Lichtblitz und Ring.
func defend_fx(u: Dictionary) -> void:
	Sfx.event("defend")
	squash(u, 1.12, 0.86, 0.3)
	light_flash(chest(u, 0.7), Color(0.4, 0.65, 1.0), 2.0, 3.0, 0.4)
	shockwave((u["node"] as Node3D).position, 0.9, Color(0.45, 0.7, 1.0, 0.8), 0.4)


func hop(u: Dictionary, h := 0.3, time := 0.25) -> void:
	var sp := u["sprite"] as Sprite3D
	var y0 := sp.position.y
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		if is_instance_valid(sp):
			sp.position.y = y0 + sin(t * PI) * h, 0.0, 1.0, time)
	tw.tween_callback(func() -> void:
		if is_instance_valid(sp):
			sp.position.y = y0)
	await tw.finished


func lunge(u: Dictionary, toward: Vector3, dist: float, time := 0.18) -> void:
	var n := u["node"] as Node3D
	var d := toward - n.position
	d.y = 0.0
	var start := n.position
	var tw := create_tween()
	tw.tween_property(n, "position", start + d.normalized() * dist, time * 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "position", start, time * 0.55).set_ease(Tween.EASE_IN)
	await tw.finished


func knockback(u: Dictionary, from_pos: Vector3, dist := 0.25, time := 0.25) -> void:
	var n := u["node"] as Node3D
	var d := n.position - from_pos
	d.y = 0.0
	var start := n.position
	var tw := create_tween()
	tw.tween_property(n, "position", start + d.normalized() * dist, time * 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "position", start, time * 0.7).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func flash_unit(u: Dictionary, color := Color(3, 3, 3), time := 0.18) -> void:
	var sp := u["sprite"] as Sprite3D
	var prev := sp.modulate
	sp.modulate = color
	var tw := create_tween()
	tw.tween_property(sp, "modulate", prev, time)
	await tw.finished


# ------------------------------------------------------------------ Hooks aus battle.gd

## Anlauf: Pose, Zielmarkierung, Funkeln.
func windup(id: String, u: Dictionary, target: Dictionary) -> void:
	Sfx.ability(id, "windup", u, target)
	match id:
		"kanone", "rakete", "breitseite":
			await _kanone_windup(u, target)
		"verspotten":
			await _verspotten_windup(u)
		"knochenwurf", "gebiss":
			await squash(u, 0.88, 1.14, 0.3)
		_:
			await ab.windup(id, u, target)


## Fluegel/Wellen vor den Treffern (nur Faehigkeiten mit Flaeche).
func cast(id: String, u: Dictionary, _target: Dictionary, tiles: Array[Vector2i]) -> void:
	Sfx.ability(id, "cast", u, _target)
	match id:
		"verspotten":
			var col: Array = c(id, "color", [1, 0.25, 0.15, 0.6])
			await tile_wave(u["pos"], tiles, Color(col[0], col[1], col[2], col[3]), 0.07, 0.4, false)
		_:
			await ab.cast(id, u, _target, tiles)


## Vor jedem einzelnen Treffer: Geschoss fliegt los (wartet bis zum Einschlag).
func before_hit(id: String, u: Dictionary, v: Dictionary, i: int) -> void:
	Sfx.ability(id, "shot", u, v)
	match id:
		"kanone", "rakete", "breitseite":
			await _kanone_shot(u, v, id)
		"knochenwurf":
			await _bone_shot(u, v, i)
		"gebiss":
			await _gebiss_shot(u, v)
		_:
			await ab.before_hit(id, u, v, i)


## Im Moment des Einschlags (nicht blockierend): Explosion, Funken, Reaktion.
func on_hit(id: String, u: Dictionary, v: Dictionary, i: int) -> void:
	Sfx.ability(id, "hit", u, v)
	match id:
		"kanone", "rakete", "breitseite":
			_explosion(chest(v, 0.4), 1.0)
			for o in battle.units:
				if o != v and o["team"] != u["team"] and Grid.dist(o["pos"], v["pos"]) == 1:
					var pos := chest(o, 0.4)
					get_tree().create_timer(0.12).timeout.connect(func() -> void: _explosion(pos, 0.55))
		"knochenwurf":
			_bonk(u, v, i)
		"gebiss":
			_gebiss_hit(u, v)
		_:
			ab.on_hit(id, u, v, i)


func on_splash(_id: String, _u: Dictionary, _v: Dictionary) -> void:
	pass   # die Nachbar-Explosionen laufen schon im Moment des Haupttreffers (on_hit)


## Nach dem Setzen eines Status.
func on_status(id: String, u: Dictionary, v: Dictionary, status: String) -> void:
	if status == "taunt":
		await _taunt_reaction(u, v)
	else:
		await ab.on_status(id, u, v, status)


# ------------------------------------------------------------------ Kanone

func _kanone_windup(u: Dictionary, target: Dictionary) -> void:
	# Fadenkreuz-Ring zieht sich auf dem Zielfeld zusammen
	var pos := ground((target["node"] as Node3D).position, 0.09)
	var ring := make_flat("ring", pos, 2.6, Color(1.0, 0.2, 0.15, 0.0), true)
	var m := ring.material_override as StandardMaterial3D
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m, "albedo_color:a", 0.9, 0.15)
	tw.tween_property(ring, "scale", Vector3.ONE * 0.45, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.1).set_delay(0.4)
	tw.finished.connect(ring.queue_free)
	squash(u, 1.1, 0.9, 0.3)
	await get_tree().create_timer(0.4).timeout


func _kanone_shot(u: Dictionary, v: Dictionary, id := "kanone") -> void:
	var from := chest(u, 0.55)
	if id == "breitseite":     # Schuss kommt vom Schiff in der Bucht, nicht von der Kapitaenin
		for o in battle.world.objects:
			if o["type"] == "ship":
				from = battle.to_world(o["pos"]) + Vector3(0, 0.9, 0)
	var to := chest(v, 0.35)
	var dir := (to - from)
	dir.y = 0.0
	dir = dir.normalized()
	var muzzle := from + dir * 0.55
	# Muendungsfeuer, Rauch, Rueckstoss
	var fire := make_sprite(c("kanone", "fire", "fx_fireball"), muzzle, 0.8, true)
	pop(fire, 1.6, 0.22, 0.5)
	particles(c("kanone", "smoke", "fx_smoke"), muzzle, 7, 1.4, 0.7, 0.8, -0.6, Color(0.85, 0.85, 0.85), false, 70.0)
	light_flash(muzzle, Color(1.0, 0.7, 0.3), 2.5, 3.0, 0.2)
	shake(0.04, 0.15)
	if id != "breitseite":
		knockback(u, to, 0.25, 0.3)
	await projectile(c("kanone", "ball", "fx_cannonball"), muzzle, to, float(c("kanone", "time", 0.62)), float(c("kanone", "arc", 2.4)), 0.45, 4.0, c("kanone", "smoke", "fx_smoke"))


func _explosion(pos: Vector3, scale_: float) -> void:
	var boom := float(c("kanone", "boom", 2.6)) * scale_
	# Reihenfolge von hinten nach vorn: Rauch, Glut, Feuerball (hoechste Prioritaet)
	for k in 3:
		var puff := make_sprite(c("kanone", "smoke", "fx_smoke"), pos + Vector3(randf_range(-0.35, 0.35), 0.15, randf_range(-0.3, 0.3)), 0.55 * scale_, false, Color(0.75, 0.72, 0.7, 0.8), 0)
		pop(puff, 2.4, 0.8, randf_range(-0.5, 0.5), 0.5, 0.2)
	var glow := make_sprite("soft", pos, boom * 0.55, true, Color(1.0, 0.5, 0.12, 0.55), 1)
	pop(glow, 1.4, 0.3, 0.0, 0.0, 0.1)
	var fire := make_sprite(c("kanone", "fire", "fx_fireball"), pos, boom * 0.3, false, Color.WHITE, 3)
	pop(fire, 3.3, 0.45, 0.25, 0.2, 0.5)
	particles("soft", pos, int(12 * scale_) + 4, 4.5 * scale_, 0.15, 0.7, 9.0, Color(0.45, 0.32, 0.2), false, 80.0)
	particles(c("kanone", "fire", "fx_fireball"), pos, int(8 * scale_) + 2, 5.0 * scale_, 0.1, 0.45, 8.0, Color(1.0, 0.7, 0.3), true, 120.0)
	shockwave(pos, 1.6 * scale_, Color(1.0, 0.7, 0.35, 0.7), 0.4)
	scorch(pos, 1.4 * scale_, Color(0.05, 0.03, 0.02, 0.65), 3.0)
	light_flash(pos + Vector3(0, 0.4, 0), Color(1.0, 0.6, 0.25), 3.5 * scale_, 5.0, 0.35)
	if scale_ >= 0.9:
		shake(float(c("kanone", "shake", 0.14)), 0.35)
		hitstop(0.07)


# ------------------------------------------------------------------ Verspotten

func _verspotten_windup(u: Dictionary) -> void:
	var pos := chest(u, 0.7)
	hop(u, 0.25, 0.25)
	await get_tree().create_timer(0.14).timeout
	# Schlag auf den Schild: Funkenstern, Klong-Ring, kurzes Wackeln
	var star := make_sprite(c("verspotten", "spark", "fx_star"), pos + Vector3(0.25, 0, 0), 0.9, true)
	pop(star, 1.8, 0.28, 0.4)
	shockwave(u["node"].position, 0.9, Color(1.0, 0.35, 0.2, 0.9), 0.35)
	light_flash(pos, Color(1.0, 0.55, 0.3), 2.0, 3.0, 0.25)
	shake(0.05, 0.2)
	await get_tree().create_timer(0.1).timeout


## Opfer dreht sich zum Spotter, rotes "!" poppt auf, Dampf.
func _taunt_reaction(src: Dictionary, v: Dictionary) -> void:
	battle._turn_towards(v, src["pos"])
	var head := (v["node"] as Node3D).position + Vector3(0, 1.75, 0)
	var icon := make_sprite(c("verspotten", "icon", "fx_exclaim"), head, 0.05)
	var tw := create_tween()
	tw.tween_property(icon, "scale", icon.scale * 16.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(t: float) -> void: _sp(icon, "roll", sin(t * 28.0) * 0.18 * (1.0 - t)), 0.0, 1.0, 0.5)
	tw.tween_method(func(t: float) -> void: _sp(icon, "alpha", 1.0 - t), 0.0, 1.0, 0.25)
	tw.finished.connect(icon.queue_free)
	particles("fx_smoke", head - Vector3(0, 0.4, 0), 5, 1.0, 0.35, 0.7, -0.8, Color(1, 0.85, 0.8), false, 60.0)
	hop(v, 0.18, 0.2)
	await get_tree().create_timer(0.12).timeout


# ------------------------------------------------------------------ Knochenwurf

func _bone_shot(u: Dictionary, v: Dictionary, i: int) -> void:
	if i > 0:
		await get_tree().create_timer(float(c("knochenwurf", "gap", 0.13))).timeout
	battle._turn_towards(u, v["pos"])
	var from := chest(u, 0.7)
	var to := chest(v, 0.55) + Vector3(randf_range(-0.12, 0.12), randf_range(-0.1, 0.15), 0.0)
	hop(u, 0.12, 0.15)
	await projectile(c("knochenwurf", "bone", "fx_bone"), from, to, float(c("knochenwurf", "time", 0.32)), 0.7 + 0.2 * i, 0.75, 9.0 + 3.0 * i)


## Xiulans Gebiss: fliegt wirbelnd im Bogen zum Ziel und beisst zu.
func _gebiss_shot(u: Dictionary, v: Dictionary) -> void:
	battle._turn_towards(u, v["pos"])
	hop(u, 0.15, 0.18)
	await projectile(c("gebiss", "sprite", "fx_gebiss"), chest(u, 0.7), chest(v, 0.55), float(c("gebiss", "time", 0.45)), 1.4, 0.8, 12.0)


func _gebiss_hit(u: Dictionary, v: Dictionary) -> void:
	var pos := chest(v, 0.55)
	var star := make_sprite("fx_star", pos, 0.6, true)
	pop(star, 1.9, 0.26, 0.4)
	particles("soft", pos, 6, 2.2, 0.1, 0.4, 5.0, Color(1.0, 0.95, 0.85), true, 100.0)
	shake(0.04, 0.12)
	flash_unit(v, Color(2.2, 2.0, 2.0), 0.14)
	knockback(v, (u["node"] as Node3D).position, 0.18, 0.2)


## "Bonk": Funkenstern, Ruck am Ziel, der Knochen prallt ab und faellt zu Boden.
func _bonk(u: Dictionary, v: Dictionary, i: int) -> void:
	var pos := chest(v, 0.55)
	var star := make_sprite(c("knochenwurf", "spark", "fx_star"), pos, 0.6, true)
	pop(star, 1.9, 0.26, 0.5 * (1.0 if i % 2 == 0 else -1.0))
	particles("soft", pos, 6, 2.2, 0.1, 0.4, 5.0, Color(1.0, 0.95, 0.7), true, 100.0)
	shake(0.03, 0.12)
	flash_unit(v, Color(2.2, 2.2, 2.2), 0.14)
	knockback(v, (u["node"] as Node3D).position, 0.15, 0.18)
	# abprallender Knochen
	var bone := make_sprite(c("knochenwurf", "bone", "fx_bone"), pos, 0.5)
	var land := ground(pos + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.2, 0.5)), 0.12)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		var p := pos.lerp(land, t)
		p.y += sin(t * PI) * 0.45
		bone.position = p
		_sp(bone, "roll", t * 6.0), 0.0, 1.0, 0.45)
	tw.tween_method(func(t: float) -> void: _sp(bone, "alpha", 1.0 - t), 0.0, 1.0, 0.25).set_delay(0.2)
	tw.finished.connect(bone.queue_free)


# ------------------------------------------------------------------ weitere Bausteine

## Leuchtender Strahl (Kern, Mantel, Glut) mit Aufblitzen an beiden Enden.
func beam(from: Vector3, to: Vector3, color: Color, width: float, time: float) -> void:
	var length := from.distance_to(to)
	var dir := (to - from).normalized()
	var root := Node3D.new()
	root.position = (from + to) * 0.5
	root.basis = Basis(Quaternion(Vector3.UP, dir))
	add_child(root)
	var layers := [[width, Color(color.r, color.g, color.b, 0.4)], [width * 0.5, Color(color.r, color.g, color.b, 0.85)], [width * 0.2, Color(1, 1, 1, 1)]]
	for l in layers:
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 0.5
		cyl.height = length
		cyl.radial_segments = 8
		cyl.rings = 1
		mi.mesh = cyl
		mi.scale = Vector3(l[0], 1.0, l[0])
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = l[1]
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	for e in [from, to]:
		var flare := make_sprite("soft", e, width * 4.0, true, Color(color.r, color.g, color.b, 0.9), 2)
		pop(flare, 1.3, time, 0.0, 0.0, 0.3)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		var w := minf(1.0, t * 6.0) * (1.0 - smoothstep(0.65, 1.0, t)) * (0.9 + 0.1 * sin(t * 90.0))
		root.scale = Vector3(w, 1.0, w), 0.0, 1.0, time)
	await tw.finished
	root.queue_free()


## Sprite um die Blickachse drehen (Salto, Wurf): Billboard aus, Drehpunkt in die Mitte.
func tumble_begin(u: Dictionary) -> void:
	var sp := u["sprite"] as Sprite3D
	var h := sp.pixel_size * float(sp.texture.get_height())
	u["_tb"] = {"off": sp.offset, "y": sp.position.y, "bb": sp.billboard}
	sp.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sp.offset = Vector2.ZERO
	sp.position.y += h * 0.5


func tumble_set(u: Dictionary, roll: float) -> void:
	var sp := u["sprite"] as Sprite3D
	if is_instance_valid(sp) and battle.cam != null:
		sp.global_transform = Transform3D(battle.cam.global_transform.basis * Basis(Vector3(0, 0, 1), roll), sp.global_position)


func tumble_end(u: Dictionary) -> void:
	var sp := u["sprite"] as Sprite3D
	if not is_instance_valid(sp) or not u.has("_tb"):
		return
	var tb: Dictionary = u["_tb"]
	sp.billboard = tb["bb"]
	sp.offset = tb["off"]
	sp.position.y = tb["y"]
	sp.rotation = Vector3.ZERO
	u.erase("_tb")


## Sprung in hohem Bogen auf ein Feld, mit Schatten, Landemarke und optionalem Salto.
func leap(u: Dictionary, dest: Vector2i, height: float, time: float, flips := 0.0) -> void:
	var n := u["node"] as Node3D
	var from := n.position
	var to := battle.to_world(dest)
	u["pos"] = dest
	var mark := make_flat("ring", ground(to, 0.09), 1.1, Color(1, 1, 1, 0.0), true)
	var mm := mark.material_override as StandardMaterial3D
	var shadow := make_flat("soft", ground(from), 0.9, Color(0, 0, 0, 0.4))
	if flips > 0.0:
		tumble_begin(u)
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		if not is_instance_valid(n):
			return
		var p := from.lerp(to, t)
		p.y += sin(t * PI) * height
		n.position = p
		var g := ground(p, 0.05)
		shadow.position = g
		shadow.scale = Vector3.ONE * clampf(1.1 - (p.y - g.y) * 0.15, 0.4, 1.1)
		mm.albedo_color.a = 0.75 * minf(1.0, t * 4.0)
		if flips > 0.0:
			tumble_set(u, t * TAU * flips), 0.0, 1.0, time)
	await tw.finished
	if flips > 0.0:
		tumble_end(u)
	mark.queue_free()
	shadow.queue_free()
	if is_instance_valid(n):
		n.position = to
		shockwave(to, 0.9, Color(1, 0.95, 0.8, 0.7), 0.35)
		particles("fx_smoke", ground(to, 0.15), 6, 1.6, 0.45, 0.6, 1.0, Color(0.9, 0.85, 0.75), false, 60.0)
		await squash(u, 1.2, 0.82, 0.18)


func jump_anim(u: Dictionary, target: Dictionary, land: Vector2i) -> void:
	var n := u["node"] as Node3D
	shockwave(n.position, 0.7, Color(1, 1, 1, 0.6), 0.3)
	particles("fx_smoke", ground(n.position, 0.12), 5, 1.2, 0.35, 0.5, 1.0, Color(0.9, 0.85, 0.75), false, 60.0)
	await squash(u, 1.18, 0.78, 0.22)
	await leap(u, land, float(c("stabsprung", "height", 1.5)), float(c("stabsprung", "time", 0.64)), 1.0)


func throw_anim(u: Dictionary, target: Dictionary, valid: Array, chosen_dir: int, landing: Vector2i) -> void:
	await ab.throw_anim(u, target, valid, chosen_dir, landing)


func polymorph_out(u: Dictionary, v: Dictionary) -> void:
	Sfx.event("polymorph_out")
	await ab.polymorph_out(u, v)


func polymorph_in(u: Dictionary) -> void:
	Sfx.event("polymorph_in")
	await ab.polymorph_in(u)


func on_heal(id: String, u: Dictionary, v: Dictionary, amount: int, cured: bool) -> void:
	Sfx.ability(id, "heal", u, v)
	ab.on_heal(id, u, v, amount, cured)
	nw.on_heal(id, u, v)


func secret_reveal(v: Dictionary, sec: Dictionary) -> void:
	await nw.secret_reveal(v, sec)


func catch_bone(u: Dictionary, via: Dictionary) -> void:
	await nw.catch_bone(u, via)


func inspire(v: Dictionary) -> void:
	await nw.inspire(v)


func hover_throw(u: Dictionary, dest: Vector2i, height: float, hover: float) -> void:
	await nw.hover_throw(u, dest, height, hover)


func shuriken_rain(from_unit: Dictionary, dest: Vector2i, victims: Array[Dictionary], tiles: Array[Vector2i]) -> void:
	await nw.shuriken_rain(from_unit, dest, victims, tiles)


func reflect_beam(a: Dictionary, b: Dictionary, color: Color) -> void:
	await nw.reflect_beam(a, b, color)


func reflect_hit(v: Dictionary) -> void:
	nw.reflect_hit(v)


func reflect_spin(via: Dictionary) -> void:
	await nw.reflect_spin(via)


func hive_appear(u: Dictionary, p: Vector3) -> void:
	await nw.hive_appear(u, p)


func assassinate(u: Dictionary, v: Dictionary) -> void:
	await nw.assassinate(u, v)


func scared_shiver(v: Dictionary) -> void:
	await nw.scared_shiver(v)


func rage_burst(u: Dictionary) -> void:
	nw.rage_burst(u)


func vanish_out(u: Dictionary) -> void:
	await nw.vanish_out(u)


func vanish_in(u: Dictionary) -> void:
	await nw.vanish_in(u)


func after(id: String, u: Dictionary, target: Dictionary) -> void:
	await ab.after(id, u, target)


## Normaler Fernangriff: Geschoss je nach Figur.
func basic_shot(att: Dictionary, def: Dictionary) -> void:
	Sfx.shot(att)
	var basic: Dictionary = cfg.get("_basic", {})
	var sprite: String = basic.get(att["id"], basic.get("default", "fx_bolt"))
	var spin := 10.0 if sprite == "fx_shuriken" else 0.0
	await projectile(sprite, chest(att, 0.7), chest(def, 0.55), 0.28, 0.5, 0.5, spin)


## Normaler Treffer: Schlagblitz bzw. Funke.
func basic_hit(att: Dictionary, def: Dictionary, accent := false) -> void:
	var pos := chest(def, 0.6)
	if Grid.dist(att["pos"], def["pos"]) <= 1:
		Sfx.melee(att, def, accent)
	else:
		Sfx.shot_hit(att, def, accent)
	if Grid.dist(att["pos"], def["pos"]) <= 1:
		var sl := make_sprite("fx_slash", pos, 1.0, true)
		pop(sl, 1.35, 0.22, randf_range(-0.5, 0.5))
	var st := make_sprite("fx_star", pos, 0.45, true)
	pop(st, 1.8, 0.2, 0.4)
	flash_unit(def, Color(2.0, 2.0, 2.0), 0.12)
	knockback(def, (att["node"] as Node3D).position, 0.12, 0.16)


## Abgang einer besiegten Figur: Rauchwolke, Ausblenden, dann entfernen.
func death(u: Dictionary) -> void:
	Sfx.event("death")
	var n := u["node"] as Node3D
	if not is_instance_valid(n):
		return
	var p := n.position + Vector3(0, 0.6, 0)
	var puff := make_sprite("fx_smoke", p, 0.8, false, Color(0.9, 0.9, 0.9, 0.85))
	pop(puff, 2.2, 0.6, 0.4, 0.4, 0.3)
	var st := make_sprite("fx_star", p, 0.5, true)
	pop(st, 2.0, 0.3, 0.6)
	var sp := u["sprite"] as Sprite3D
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sp, "modulate:a", 0.0, 0.35)
	tw.tween_property(sp, "scale", Vector3(1.15, 1.25, 1.0), 0.35)
	tw.finished.connect(n.queue_free)


# ------------------------------------------------------------------ Dauer-Statussymbole

func sync_status(u: Dictionary) -> void:
	var n := u.get("node") as Node3D
	if not is_instance_valid(n):
		return
	var holders: Dictionary = u.get("fx_nodes", {})
	var want := {}
	for s: Dictionary in u["status"]:
		want[s["id"]] = true
	for id: String in holders.keys():
		if not want.has(id):
			if is_instance_valid(holders[id]):
				(holders[id] as Node).queue_free()
			holders.erase(id)
	for id: String in want:
		if not holders.has(id):
			var h := _status_holder(id, n)
			if h != null:
				holders[id] = h
	u["fx_nodes"] = holders
	_arrange_icons(u, n, holders)


## Kopf-Symbole (Betaeubt, Spott, Wut, Beflügelt, Übel) stehen in einer Reihe ueber dem Lebensbalken (feste Plaetze, hoechstens ICON_MAX,
## der Rest als "+N"), mit kleiner Restdauer. Ohne Ueberlappung mit Balken, Zahl und Meldungen.
const ICON_IDS := ["stun", "taunt", "wut", "tempo", "uebel", "satt", "inspiriert"]
const ICON_MAX := 3
const ICON_STEP := 0.36


func _arrange_icons(u: Dictionary, n: Node3D, holders: Dictionary) -> void:
	var icons: Array[String] = []
	for s: Dictionary in u["status"]:
		if ICON_IDS.has(s["id"]) and not icons.has(s["id"]):
			icons.append(s["id"])
	var shown := mini(icons.size(), ICON_MAX)
	for i in icons.size():
		var h: Node3D = holders.get(icons[i])
		if h == null or not is_instance_valid(h):
			continue
		var ic := h.get_node_or_null("icon") as Node3D
		if ic == null:
			continue
		ic.visible = i < ICON_MAX
		ic.set_meta("slot", float(i) - float(shown - 1) * 0.5)      # Battle._place_overlays setzt die Lage entlang der Kamera
		var tl := ic.get_node_or_null("turns") as Label3D
		if tl != null:
			var turns := int(Status.get_status(u, icons[i]).get("turns", 0))
			tl.text = str(turns) if turns < 50 else ""
	var more := u.get("more") as Label3D
	if more == null and icons.size() > ICON_MAX:
		more = _turns_label()
		more.font_size = 52
		n.add_child(more)
		u["more"] = more
	if more != null and is_instance_valid(more):
		more.visible = icons.size() > ICON_MAX
		more.text = "+%d" % (icons.size() - ICON_MAX)
		more.set_meta("slot", float(shown) * 0.5 + 0.35)


func _turns_label() -> Label3D:
	var tl := Label3D.new()
	tl.name = "turns"
	tl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tl.font = UiTheme.font(UiTheme.F_TITLE)
	tl.font_size = 40
	tl.pixel_size = 0.0046
	tl.outline_size = 12
	tl.no_depth_test = true
	tl.render_priority = 6
	tl.position = Vector3(0.14, -0.15, 0.0)
	return tl


## Symbolknoten eines Status: sync_status schiebt ihn in die Symbolreihe, die kleine Zahl zeigt die Restdauer.
func icon_node(root: Node3D) -> Node3D:
	var ic := Node3D.new()
	ic.name = "icon"
	root.add_child(ic)
	ic.add_child(_turns_label())
	return ic


func _status_holder(id: String, n: Node3D) -> Node3D:
	var root := Node3D.new()
	n.add_child(root)
	match id:
		"defend":   # blauer Schutzschein um die Figur, pulsiert leicht
			var glow := make_sprite("soft", Vector3(0, 0.75, 0), 1.9, true, Color(0.3, 0.55, 1.0, 0.85), 0, root)
			var bubble := make_sprite("ring", Vector3(0, 0.75, 0), 1.7, true, Color(0.6, 0.85, 1.0, 1.0), 1, root)
			var twd := root.create_tween().set_loops()
			twd.tween_property(bubble, "scale", bubble.scale * 1.1, 0.7).set_trans(Tween.TRANS_SINE)
			twd.tween_property(bubble, "scale", bubble.scale, 0.7).set_trans(Tween.TRANS_SINE)
			twd.parallel().tween_property(glow, "scale", glow.scale * 1.08, 0.7).set_trans(Tween.TRANS_SINE)
		"wachsam":   # goldener Ring am Boden, pulsiert leicht
			var wr_ := make_sprite("ring", Vector3(0, 0.07, 0), 0.9, true, Color(1.0, 0.85, 0.3, 0.9), 1, root)
			var tww := root.create_tween().set_loops()
			tww.tween_property(wr_, "scale", wr_.scale * 1.12, 0.8).set_trans(Tween.TRANS_SINE)
			tww.tween_property(wr_, "scale", wr_.scale, 0.8).set_trans(Tween.TRANS_SINE)
		"stun":    # drei Sterne kreisen ueber dem Kopf
			var sic := icon_node(root)
			var stars: Array[MeshInstance3D] = []
			for i in 3:
				stars.append(make_sprite("fx_star", Vector3.ZERO, 0.22, true, Color(1.0, 0.95, 0.5), 0, sic))
			var tw := root.create_tween().set_loops()
			tw.tween_method(func(t: float) -> void:
				for i in 3:
					var a := t * TAU + i * TAU / 3.0
					if is_instance_valid(stars[i]):
						stars[i].position = Vector3(cos(a) * 0.17, sin(a * 2.0) * 0.03, sin(a) * 0.17), 0.0, 1.0, 1.2)
		"poison":
			_loop_particles(root, "fx_bubble", Vector3(0, 0.5, 0), 4, 0.9, 0.22, 1.3, -0.8, Color(0.7, 1.0, 0.7))
		"taunt":
			var ic := make_sprite("fx_exclaim", Vector3.ZERO, 0.3, false, Color.WHITE, 0, icon_node(root))
			var tw2 := root.create_tween().set_loops()
			tw2.tween_property(ic, "scale", ic.scale * 1.18, 0.4).set_trans(Tween.TRANS_SINE)
			tw2.tween_property(ic, "scale", ic.scale, 0.4).set_trans(Tween.TRANS_SINE)
		"buff":
			_loop_particles(root, "fx_arrow_up", Vector3(0, 0.3, 0), 3, 0.9, 0.2, 1.4, -0.4, Color(1.0, 0.9, 0.5), true)
		"tired":
			_loop_particles(root, "fx_sweat", Vector3(0.2, 1.7, 0), 2, 0.5, 0.2, 1.0, 3.0, Color.WHITE)
		_:
			if not nw.status_holder(id, root):
				root.queue_free()
				return null
	return root


## Dauer-Partikel unter einem Knoten.
func _loop_particles(parent: Node3D, name: String, pos: Vector3, count: int, speed: float, size: float, life: float, gravity: float, tint: Color, additive := false) -> void:
	var p := CPUParticles3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	var m := ShaderMaterial.new()
	m.shader = _shader_add if additive else _shader_mix
	m.set_shader_parameter("tex", tex(name))
	mesh.material = m
	p.mesh = mesh
	p.position = pos
	p.amount = count
	p.lifetime = life
	p.direction = Vector3.UP
	p.spread = 35.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -gravity, 0)
	p.scale_amount_min = size * 0.7
	p.scale_amount_max = size
	var g := Gradient.new()
	g.set_color(0, Color(tint.r, tint.g, tint.b, 1.0))
	g.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.emitting = true
