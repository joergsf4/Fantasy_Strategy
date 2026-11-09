extends SceneTree
## Run with a graphical renderer: godot --path game --windowed --script res://tests/test_volcano_lava_render.gd


func _initialize() -> void:
	if DisplayServer.get_name() == "headless":      # braucht einen echten Renderer; ohne Fenster ueberspringen statt haengen
		print("uebersprungen (ohne Fenster): ", get_script().resource_path.get_file())
		quit(0)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 320)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.0
	camera.position = Vector3(0, 0, 5)
	viewport.add_child(camera)
	camera.current = true
	var mountain := Sprite3D.new()
	mountain.texture = load("res://assets/fx/fx_vulkanberg.png")
	mountain.pixel_size = 1.8 / mountain.texture.get_height()
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/volcano_lava.gdshader")
	material.set_shader_parameter("tex", mountain.texture)
	mountain.material_override = material
	viewport.add_child(mountain)
	material.set_shader_parameter("elapsed", 0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var first := viewport.get_texture().get_image()
	material.set_shader_parameter("elapsed", 0.7)
	await process_frame
	await RenderingServer.frame_post_draw
	var second := viewport.get_texture().get_image()
	var fire_changed := 0
	var rock_changed := 0
	var rock_pixels := 0
	for y in range(320):
		for x in range(320):
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			var diff := absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
			if a.r > 0.4 and a.r - a.g > 0.12 and a.r - a.b > 0.18 and diff > 0.015:
				fire_changed += 1
			if a.r < 0.3 and absf(a.r - a.g) < 0.08 and absf(a.r - a.b) < 0.08:
				rock_pixels += 1
				if diff > 0.015:
					rock_changed += 1
	print("lava_render: %d animierte Feuerpixel, %d von %d neutralen Pixeln veraendert" % [fire_changed, rock_changed, rock_pixels])
	viewport.queue_free()
	await process_frame
	quit(0 if fire_changed > 100 and rock_pixels > 1000 and rock_changed == 0 else 1)
