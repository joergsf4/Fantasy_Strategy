extends SceneTree
## Run with a graphical renderer: godot --path game --windowed --script res://tests/test_volcano_cloud_render.gd


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
	var scene := preload("res://scripts/volcano_trek.gd").new()
	scene.setup({"party": []})
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	var cloud: Sprite3D = scene._clouds[0]
	cloud.get_parent().remove_child(cloud)
	viewport.add_child(cloud)
	cloud.position = Vector3.ZERO
	cloud.pixel_size = 1.8 / cloud.texture.get_width()
	var material := cloud.material_override as ShaderMaterial
	material.set_shader_parameter("elapsed", 0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var first := viewport.get_texture().get_image()
	material.set_shader_parameter("elapsed", 0.7)
	await process_frame
	await RenderingServer.frame_post_draw
	var second := viewport.get_texture().get_image()
	var changed := 0
	var largest := 0.0
	for y in range(320):
		for x in range(320):
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			var diff := absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
			largest = maxf(largest, diff)
			if diff > 0.005:
				changed += 1
	var grey := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	grey.fill(Color(0.35, 0.35, 0.35, 1.0))
	material.set_shader_parameter("tex", ImageTexture.create_from_image(grey))
	material.set_shader_parameter("elapsed", 0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var neutral_before := viewport.get_texture().get_image().get_pixel(160, 160)
	material.set_shader_parameter("elapsed", 0.7)
	await process_frame
	await RenderingServer.frame_post_draw
	var neutral_after := viewport.get_texture().get_image().get_pixel(160, 160)
	print("cloud_render: %d animierte Pixel, maximale Differenz %.3f, Neutralfarbe unveraendert: %s" % [changed, largest, neutral_before == neutral_after])
	scene.queue_free()
	viewport.queue_free()
	await process_frame
	quit(0 if changed > 100 and neutral_before == neutral_after and largest < 0.09 else 1)
