extends "res://scripts/snow_trek.gd"
## Vulkanreise mit derselben Gruppen- und Kamerafahrt wie die Schneereise.

var _mountain: Sprite3D
var _clouds: Array[Sprite3D] = []
var _dead_tree: Sprite3D
const DUST_SHADER := preload("res://shaders/volcano_dust.gdshader")
const LAVA_SHADER := preload("res://shaders/volcano_lava.gdshader")
const MOUNTAIN_POS := Vector3(34.0, 10.5, -110.0)   # fester Platz am Horizont in Laufrichtung (die Gruppe zieht von links nach rechts darauf zu)
const MOUNTAIN_HEIGHT := 44.0                      # Weltgroesse; wirkt aus dieser Entfernung so gross wie vorher
const CLOUD_DIST := 30.0                           # Wolken stehen so weit hinter dem Vulkan
var _cloud_base: Array[Vector3] = []


func _init() -> void:
	cam_ang = Vector2(-0.08, 0.16)    # flacher als im Schneesturm: die Kamera bleibt seitlich, der Vulkan bleibt im Bild


## Statt Wind: bedrohliche Musik (blendet wie der Wind ein und aus, Ueberspringen inklusive) und fernes Donnergrollen.
const MUSIC := "res://assets/audio/vulkan_weg.mp3"
var _next_thunder := 1.6
var _close_thunder := false


func _start_wind() -> void:
	if not ResourceLoader.exists(MUSIC):
		return
	_wind = AudioStreamPlayer.new()
	_wind.stream = load(MUSIC)
	_wind.volume_db = -40.0
	add_child(_wind)
	_wind.play()
	var tw := create_tween()
	tw.tween_property(_wind, "volume_db", -6.0, 1.8)
	tw.tween_interval(maxf(0.0, duration - 4.3))
	tw.tween_property(_wind, "volume_db", -40.0, 2.5)
	tw.tween_callback(func() -> void: _wind.stop())


## Donner: alle paar Sekunden ein fernes Grollen, einmal (gegen Ende, wenn der Vulkan gross im Bild ist) ein naher Schlag.
func _thunder() -> void:
	if _t >= _next_thunder and _t < duration - 1.5:
		_next_thunder = _t + _rng.randf_range(3.2, 5.0)
		Sfx.event("thunder_far")
	if not _close_thunder and _t >= duration * 0.62:
		_close_thunder = true
		Sfx.event("thunder")


func _height(x: float, z: float) -> float:
	var base := 0.035 * x
	var wall := pow(maxf(0.0, absf(z) - 7.0), 1.25) * 0.045
	var trail := smoothstep(2.6, 0.6, absf(z))
	return base + wall + _noise.get_noise_2d(x, z) * 1.1 * (1.0 - trail * 0.85)


func _build_world() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.18, 0.105, 0.10)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.48, 0.31, 0.27)
	_env.ambient_light_energy = 0.75
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.22, 0.13, 0.12)
	_env.fog_density = 0.008
	var world := WorldEnvironment.new()
	world.environment = _env
	_vp.add_child(world)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-38, -35, 0)
	_sun.light_color = Color(1.0, 0.57, 0.37)
	_sun.light_energy = 0.8
	_vp.add_child(_sun)

	var land := MeshInstance3D.new()
	land.mesh = _terrain_mesh()
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley;
void fragment() {
	float shade = clamp(COLOR.r, 0.0, 1.0);
	ALBEDO = mix(vec3(0.075, 0.055, 0.055), vec3(0.27, 0.19, 0.17), shade);
	ROUGHNESS = 1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	land.material_override = material
	_vp.add_child(land)

	var rocks := [load("res://assets/fx/fx_fels1.png"), load("res://assets/fx/fx_fels2.png")]
	for i in 115:
		var x := _rng.randf_range(-25.0, 90.0)
		var z := -_rng.randf_range(5.5, 16.0) if i % 2 == 0 else _rng.randf_range(11.0, 17.0)
		_add_prop(rocks[i % rocks.size()], Vector3(x, _height(x, z), z), _rng.randf_range(1.2, 2.8), Color(0.48, 0.36, 0.31))

	_dead_tree = Sprite3D.new()
	_dead_tree.texture = load("res://assets/fx/fx_vulkantotbaum.png")
	_dead_tree.pixel_size = 3.0 / _dead_tree.texture.get_height()
	_dead_tree.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_dead_tree.shaded = false
	_dead_tree.transparent = true
	_dead_tree.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_dead_tree.offset = Vector2(0, _dead_tree.texture.get_height() / 2.0)
	_dead_tree.position = Vector3(9.0, _height(9.0, -3.2), -3.2)     # nah am Weg auf flachem Boden: Fuss bleibt sichtbar, kaum Nebel
	_vp.add_child(_dead_tree)

	_mountain = Sprite3D.new()
	_mountain.texture = load("res://assets/fx/fx_vulkanberg.png")
	_mountain.pixel_size = MOUNTAIN_HEIGHT / _mountain.texture.get_height()
	_mountain.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mountain.shaded = false
	_mountain.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var lava_material := ShaderMaterial.new()
	lava_material.shader = LAVA_SHADER
	lava_material.set_shader_parameter("tex", _mountain.texture)
	_mountain.material_override = lava_material
	_mountain.position = MOUNTAIN_POS
	_vp.add_child(_mountain)
	var cloud_texture: Texture2D = load("res://assets/fx/fx_vulkanwolken.png")
	for i in 2:
		var cloud := Sprite3D.new()
		cloud.texture = cloud_texture
		cloud.pixel_size = 110.0 / cloud_texture.get_width()
		cloud.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		cloud.flip_h = i == 1
		cloud.shaded = false
		cloud.transparent = true
		cloud.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var cloud_material := ShaderMaterial.new()
		cloud_material.shader = LAVA_SHADER
		cloud_material.set_shader_parameter("tex", cloud_texture)
		cloud_material.set_shader_parameter("strength", 0.3)
		cloud_material.set_shader_parameter("phase", float(i) * 2.0)
		cloud_material.set_shader_parameter("red_green_threshold", Vector2(0.02, 0.08))
		cloud_material.set_shader_parameter("red_blue_threshold", Vector2(0.02, 0.08))
		cloud_material.set_shader_parameter("brightness_threshold", Vector2(0.025, 0.10))
		cloud_material.set_shader_parameter("tint", Color(0.7, 0.65, 0.65, 0.85))
		cloud.material_override = cloud_material
		cloud.position = MOUNTAIN_POS + Vector3((-1.0 if i == 0 else 1.0) * 48.0, 30.0 + float(i) * 2.0, -CLOUD_DIST)
		_cloud_base.append(cloud.position)
		_vp.add_child(cloud)
		_clouds.append(cloud)


func _build_party() -> void:
	super._build_party()
	for figure: Dictionary in _figs:
		var sprite: Sprite3D = figure["sprite"]
		sprite.modulate = Color(0.94, 0.83, 0.77)
		if figure["fly"]:
			continue
		var dust := ColorRect.new()
		dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader = DUST_SHADER
		material.set_shader_parameter("phase", figure["phase"])
		dust.material = material
		add_child(dust)
		figure["dust"] = dust


func _feet_puffs() -> GPUParticles3D:
	var particles := super._feet_puffs()
	particles.emitting = false
	return particles


func _build_snow() -> void:
	_snow_near = _snow_layer(180, 0.08, 0.4, 1.2, Vector3(13, 5, 11), 0.7)
	_snow_far = _snow_layer(45, 0.14, 0.2, 0.7, Vector3(15, 5, 13), 0.35)
	for particles: GPUParticles3D in [_snow_near, _snow_far]:
		var process := particles.process_material as ParticleProcessMaterial
		process.direction = Vector3(0.3, 1.0, 0.1)
		process.gravity = Vector3(0.1, 0.15, 0.0)
		process.spread = 40.0
		((particles.draw_pass_1 as QuadMesh).material as StandardMaterial3D).albedo_color = Color(1.0, 0.4, 0.12, 0.6)
		_vp.add_child(particles)
	_next_gust = 1000000.0


func _step(delta: float) -> void:
	super._step(delta)
	if delta > 0.0:
		_thunder()
	var camera_forward := -_cam.global_basis.z
	_cam.look_at(_cam.position + camera_forward * 10.0 + Vector3(0, 0.9, 0))
	for figure: Dictionary in _figs:
		var root: Node3D = figure["root"]
		if figure["fly"]:
			continue
		root.position.y += SINK
		var dust: ColorRect = figure["dust"]
		dust.visible = not _cam.is_position_behind(root.global_position)
		var foot := _cam.unproject_position(root.global_position)
		var top := _cam.unproject_position(root.global_position + Vector3.UP * 1.45)
		var height := foot.distance_to(top)
		dust.size = Vector2(height * 1.5, height * 0.62)
		dust.position = foot - Vector2(dust.size.x * 0.5, dust.size.y * 0.72)
		(dust.material as ShaderMaterial).set_shader_parameter("elapsed", _t)
	_env.fog_density = 0.008
	# Vulkan und Wolken stehen fest in der Welt (nicht an der Kamera): so ziehen sie mit Parallaxe wie Felsen und Baum, nur langsamer
	(_mountain.material_override as ShaderMaterial).set_shader_parameter("elapsed", _t)
	for i in _clouds.size():
		_clouds[i].position = _cloud_base[i] + Vector3(sin(_t * 0.12 + float(i)) * 3.0, 0.0, 0.0)
		(_clouds[i].material_override as ShaderMaterial).set_shader_parameter("elapsed", _t)
