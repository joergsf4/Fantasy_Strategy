extends SceneTree

const VolcanoTrek := preload("res://scripts/volcano_trek.gd")
var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	var mission := Mission.load_mission("ch20")
	var data: Dictionary = mission["interlude_after"].duplicate()
	check(data["scene"] == "volcano", "Vulkanreise ist fuer Hogsmeat eingetragen")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var camp_pos := main_source.find('await _camp(Mission.load_mission(next_cid) if next_cid != "" else m)')
	var interlude_pos := main_source.find('await _play_pending_interlude()', camp_pos)
	var end_pos := main_source.find('end.text = "Ende von Kapitel')
	var reveal_pos := main_source.find("await _cover_out(0.7)", end_pos)
	check(camp_pos >= 0 and interlude_pos > camp_pos and end_pos >= 0 and reveal_pos > end_pos, "Reise nach Lager, Endbildschirm nach Schwarzblende sichtbar")
	var party := Party.new_game()
	party.squads["ch20"] = ["maedchen_baer", "wendy", "elisabeth", "robo", "ritter", "bienenmaedchen"]
	data["party"] = party.squad_for(mission)
	var trek := VolcanoTrek.new()
	trek.setup(data)
	root.add_child(trek)
	await process_frame
	check(trek._figs.size() == data["party"].size(), "gewaehlte Gruppe laeuft mit")
	check(trek._mountain.texture.resource_path == "res://assets/fx/fx_vulkanberg.png" and trek._snow_near.amount < 1000, "Freigegebenes Vulkan-Sprite und dezente Glut")
	check(not trek._mountain.no_depth_test, "Vulkan liegt hinter dem Gebirgskamm statt davor")
	check(trek._dead_tree.texture.resource_path == "res://assets/fx/fx_vulkantotbaum.png", "Freigegebener toter Baum ist vorhanden")
	check(is_equal_approx(trek._dead_tree.position.y, trek._height(trek._dead_tree.position.x, trek._dead_tree.position.z)), "Baum steht auf dem Boden")
	var tree_position := trek._dead_tree.position
	check(trek._clouds.size() == 2 and trek._clouds[0].texture.resource_path == "res://assets/fx/fx_vulkanwolken.png", "Freigegebene Wolken am Himmel")
	var cloud_position := trek._clouds[0].position
	var lava := trek._mountain.material_override as ShaderMaterial
	check(lava != null and lava.shader.resource_path == "res://shaders/volcano_lava.gdshader", "Vulkan verwendet animierten Lava-Shader")
	for member: Dictionary in trek._figs:
		if member["fly"]:
			check(not member.has("dust"), "Stachelia hat keinen Staub")
		else:
			check(member["dust"] is ColorRect and (member["dust"] as ColorRect).material is ShaderMaterial, "Laufende Figuren haben 2D-Shaderstaub")
	var puff: ColorRect = trek._figs[0]["dust"]
	var dust_shader := puff.material as ShaderMaterial
	var old_time: float = dust_shader.get_shader_parameter("elapsed")
	trek._t += 0.4
	trek._step(0.0)
	check(trek._dead_tree.position == tree_position, "Baum bleibt in der Landschaft stehen")
	check(trek._clouds[0].position.distance_to(cloud_position) > 0.01, "Wolken ziehen langsam")
	check(trek._clouds[0].position.distance_to(trek._cam.position) > trek._mountain.position.distance_to(trek._cam.position), "Wolken hinter dem Vulkan")
	for cloud: Sprite3D in trek._clouds:
		var cloud_material := cloud.material_override as ShaderMaterial
		check(cloud_material != null and cloud_material.shader == lava.shader and is_equal_approx(float(cloud_material.get_shader_parameter("elapsed")), trek._t), "Wolkenfarben werden mit der Szenenzeit animiert")
		check(is_equal_approx(float(cloud_material.get_shader_parameter("strength")), 0.3), "Wolkengluehen ist dezenter als Lava")
	check(is_equal_approx(float(dust_shader.get_shader_parameter("elapsed")) - old_time, 0.4), "Noise-Shader wird animiert")
	check(is_equal_approx(float(lava.get_shader_parameter("elapsed")), trek._t), "Lava wird mit der Szenenzeit animiert")
	var mountain_pos := trek._mountain.position
	var m_screen := trek._cam.unproject_position(mountain_pos)
	var t_screen := trek._cam.unproject_position(trek._dead_tree.position)
	trek._t += 6.0
	trek._lead += 7.5
	trek._step(0.0)
	check(trek._mountain.position == mountain_pos, "Vulkan steht fest in der Welt (wandert nicht mit der Kamera)")
	var m_shift := trek._cam.unproject_position(mountain_pos).x - m_screen.x
	var t_shift := trek._cam.unproject_position(trek._dead_tree.position).x - t_screen.x
	check(signf(m_shift) == signf(t_shift) and absf(m_shift) < absf(t_shift), "Vulkan zieht gleichsinnig, aber langsamer als der Baum (Parallaxe): %.0f / %.0f" % [m_shift, t_shift])
	var root_pos: Vector3 = (trek._figs[0]["root"] as Node3D).global_position
	var foot := trek._cam.unproject_position(root_pos)
	check(puff.visible and puff.get_rect().has_point(foot), "Staub folgt dem projizierten Fuss")
	var last := -999.0
	for i in 30:
		await process_frame
		var figure: Node3D = trek._figs[0]["root"]
		check(figure.position.x >= last, "Gruppe bewegt sich vorwaerts")
		last = figure.position.x
		check(figure.position.y >= trek._height(figure.position.x, figure.position.z), "Fuesse versinken nicht im Schnee")
	var done := [0]
	trek.finished.connect(func() -> void: done[0] += 1)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	trek._age = 1.0
	trek._input(click)
	await create_timer(0.7).timeout
	check(done[0] == 1 and trek._black.modulate.a >= 0.99, "Ueberspringen endet einmal mit Schwarzblende")
	trek.queue_free()
	await process_frame

	Engine.time_scale = 10.0
	var normal := VolcanoTrek.new()
	normal.setup({"duration": 6.0, "party": ["maedchen_baer", "hund"]})
	root.add_child(normal)
	var completed := [0]
	normal.finished.connect(func() -> void: completed[0] += 1)
	await create_timer(7.0).timeout
	check(completed[0] == 1 and normal._black.modulate.a >= 0.99, "Normales Ende mit Schwarzblende")
	normal.queue_free()
	await process_frame
	Engine.time_scale = 1.0
	print("volcano_trek: ", "OK" if fails == 0 else "%d Fehler" % fails)
	quit(fails)
