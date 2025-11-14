package learnopengl

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:math"
import "core:mem"
import "core:os"

import     "vendor:glfw"
import mu  "vendor:microui"
import gl  "vendor:OpenGL"
import glm "core:math/linalg/glsl"

WIDTH  	:: 1280
HEIGHT 	:: 720
TITLE 	:: "learn OpenGL"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

Program :: struct {
	ui: UI,

	scene: Scene,

	camera:  Camera,

	mouse: Mouse,

	logger: log.Logger, //callback logging

	window:  Window,

	delta_time: f64,
	last_frame: f64,

	mb_down:   bit_set[Mouse_Button],
	keys_down: bit_set[Key],
}

Window :: struct {
	handle: glfw.WindowHandle,
	size: [2]i32,
}

Scene :: struct {
	light:    Light,
	material: Material,
}

Material :: struct {
	diffuse:   Texture,
	specular:  Texture,
	// ambient:   [3]f32,
	shininess: f32,
}

Color32f :: distinct [3]f32

Light :: struct {
	pos:      [3]f32,

	ambient:  Color32f,
	diffuse:  Color32f,
	specular: Color32f,

	gain: f32,
}

main :: proc() {

	ctx: Program

	log_file, _ := os.open("output.log", os.O_CREATE|os.O_TRUNC)
	context.logger = log.create_multi_logger(
		log.create_console_logger(),
		log.create_file_logger(log_file)
	)
	defer os.close(log_file)

	ctx.logger = context.logger

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		if len(track.allocation_map) > 0 {
			log.warnf("=== %v allocations not freed: ===\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				log.warnf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		}
		if len(track.bad_free_array) > 0 {
			log.errorf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
			for entry in track.bad_free_array {
				log.errorf("- %p @ %v\n", entry.memory, entry.location)
			}
		}
		mem.tracking_allocator_destroy(&track)
	}
	

	ensure(bool(glfw.Init()),"Failed to initialize GLFW")

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION);
 	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION);
 	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);

	ctx.window.handle = glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)
	ctx.window.size = {WIDTH, HEIGHT}

	glfw.MakeContextCurrent(ctx.window.handle)

	defer glfw.Terminate()
	defer glfw.DestroyWindow(ctx.window.handle)

	if ctx.window.handle == nil {
		log.error("GLFW has failed to load the window.")
		return
	}
	
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	framebuffer_resize_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
		ctx := (^Program)(glfw.GetWindowUserPointer(window))
		ctx.window.size = {width, height}
		ctx.camera.ar = f32(width)/f32(height)
		gl.Viewport(0, 0, width, height)
	}

	glfw.SetFramebufferSizeCallback(ctx.window.handle, framebuffer_resize_callback)

	glfw.SetCursorPosCallback(ctx.window.handle, mouse_callback)

	glfw.SetScrollCallback(ctx.window.handle, scroll_callback)

	glfw.SetWindowUserPointer(ctx.window.handle, &ctx)


	ui_r_init(&ctx)
	mu.init(ctx.ui.ctx)
	ctx.ui.ctx.text_width  = mu.default_atlas_text_width
	ctx.ui.ctx.text_height = mu.default_atlas_text_height

	ctx.ui.open = false
	ctx.ui.update_open = true

	log.info("Press spacebar to show UI!")

	object_shader: Shader
	shader_init(&object_shader, "shaders/shader.vert", "shaders/shader.frag")
	
	light_shader: Shader
	shader_init(&light_shader, "shaders/shader.vert", "shaders/light_shader.frag")

	Vertex :: struct {
		pos:    [3]f32,
		normal: [3]f32,
		uv:     [2]f32,
	}

	vertices := [36]Vertex{
	    {{-0.5, -0.5, -0.5}, { 0.0,  0.0, -1.0}, { 0.0, 0.0}},
	    {{ 0.5, -0.5, -0.5}, { 0.0,  0.0, -1.0}, { 1.0, 0.0}},
	    {{ 0.5,  0.5, -0.5}, { 0.0,  0.0, -1.0}, { 1.0, 1.0}},
	    {{ 0.5,  0.5, -0.5}, { 0.0,  0.0, -1.0}, { 1.0, 1.0}},
	    {{-0.5,  0.5, -0.5}, { 0.0,  0.0, -1.0}, { 0.0, 1.0}},
	    {{-0.5, -0.5, -0.5}, { 0.0,  0.0, -1.0}, { 0.0, 0.0}},
	    {{-0.5, -0.5,  0.5}, { 0.0,  0.0,  1.0}, { 0.0, 0.0}},
	    {{ 0.5, -0.5,  0.5}, { 0.0,  0.0,  1.0}, { 1.0, 0.0}},
	    {{ 0.5,  0.5,  0.5}, { 0.0,  0.0,  1.0}, { 1.0, 1.0}},
	    {{ 0.5,  0.5,  0.5}, { 0.0,  0.0,  1.0}, { 1.0, 1.0}},
	    {{-0.5,  0.5,  0.5}, { 0.0,  0.0,  1.0}, { 0.0, 1.0}},
	    {{-0.5, -0.5,  0.5}, { 0.0,  0.0,  1.0}, { 0.0, 0.0}},
	    {{-0.5,  0.5,  0.5}, {-1.0,  0.0,  0.0}, { 1.0, 0.0}},
	    {{-0.5,  0.5, -0.5}, {-1.0,  0.0,  0.0}, { 1.0, 1.0}},
	    {{-0.5, -0.5, -0.5}, {-1.0,  0.0,  0.0}, { 0.0, 1.0}},
	    {{-0.5, -0.5, -0.5}, {-1.0,  0.0,  0.0}, { 0.0, 1.0}},
	    {{-0.5, -0.5,  0.5}, {-1.0,  0.0,  0.0}, { 0.0, 0.0}},
	    {{-0.5,  0.5,  0.5}, {-1.0,  0.0,  0.0}, { 1.0, 0.0}},
	    {{ 0.5,  0.5,  0.5}, { 1.0,  0.0,  0.0}, { 1.0, 0.0}},
	    {{ 0.5,  0.5, -0.5}, { 1.0,  0.0,  0.0}, { 1.0, 1.0}},
	    {{ 0.5, -0.5, -0.5}, { 1.0,  0.0,  0.0}, { 0.0, 1.0}},
	    {{ 0.5, -0.5, -0.5}, { 1.0,  0.0,  0.0}, { 0.0, 1.0}},
	    {{ 0.5, -0.5,  0.5}, { 1.0,  0.0,  0.0}, { 0.0, 0.0}},
	    {{ 0.5,  0.5,  0.5}, { 1.0,  0.0,  0.0}, { 1.0, 0.0}},
	    {{-0.5, -0.5, -0.5}, { 0.0, -1.0,  0.0}, { 0.0, 1.0}},
	    {{ 0.5, -0.5, -0.5}, { 0.0, -1.0,  0.0}, { 1.0, 1.0}},
	    {{ 0.5, -0.5,  0.5}, { 0.0, -1.0,  0.0}, { 1.0, 0.0}},
	    {{ 0.5, -0.5,  0.5}, { 0.0, -1.0,  0.0}, { 1.0, 0.0}},
	    {{-0.5, -0.5,  0.5}, { 0.0, -1.0,  0.0}, { 0.0, 0.0}},
	    {{-0.5, -0.5, -0.5}, { 0.0, -1.0,  0.0}, { 0.0, 1.0}},
	    {{-0.5,  0.5, -0.5}, { 0.0,  1.0,  0.0}, { 0.0, 1.0}},
	    {{ 0.5,  0.5, -0.5}, { 0.0,  1.0,  0.0}, { 1.0, 1.0}},
	    {{ 0.5,  0.5,  0.5}, { 0.0,  1.0,  0.0}, { 1.0, 0.0}},
	    {{ 0.5,  0.5,  0.5}, { 0.0,  1.0,  0.0}, { 1.0, 0.0}},
	    {{-0.5,  0.5,  0.5}, { 0.0,  1.0,  0.0}, { 0.0, 0.0}},
	    {{-0.5,  0.5, -0.5}, { 0.0,  1.0,  0.0}, { 0.0, 1.0}}
	}

	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(vertices[:]), gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, normal))
	gl.EnableVertexAttribArray(1)

	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, uv))
	gl.EnableVertexAttribArray(2)

	light_vao: u32
	gl.GenVertexArrays(1, &light_vao)
	gl.BindVertexArray(light_vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), 0)
	gl.EnableVertexAttribArray(0)


	diffuse_map_bytes := #load("textures/container2.png")
	specular_map_bytes := #load("textures/container2_specular.png")

	ctx.scene.material.diffuse  = load_texture(diffuse_map_bytes, .RGBA, false)
	ctx.scene.material.specular = load_texture(specular_map_bytes, .RGBA, false)


	ctx.mouse.last_x = WIDTH/2
	ctx.mouse.last_y = HEIGHT/2
	ctx.mouse.first  = true

	camera_init(&ctx.camera, ctx.window, {0, 0, 3})

	ctx.scene.light.pos = {1.2, 1.0, 2.0}
	ctx.scene.light.ambient = 0.2
	ctx.scene.light.diffuse = 0.5
	ctx.scene.light.specular = 1
	ctx.scene.light.gain = 1

	ctx.scene.material.shininess = 32
  
	// main loop
	for !glfw.WindowShouldClose(ctx.window.handle) {
		free_all(context.temp_allocator)

		current_frame  := glfw.GetTime()
		ctx.delta_time  = current_frame - ctx.last_frame
		ctx.last_frame  = current_frame

		glfw.PollEvents()

		if .Right in ctx.mb_down {
			glfw.SetInputMode(ctx.window.handle, glfw.CURSOR, glfw.CURSOR_DISABLED)
		} else {
			glfw.SetInputMode(ctx.window.handle, glfw.CURSOR, glfw.CURSOR_NORMAL)
		}


		process_input(&ctx)


		mu.begin(ctx.ui.ctx)
		ui_panel(&ctx)
		mu.end(ctx.ui.ctx)


		gl.ClearColor(0.05, 0.05, 0.05, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT)

		direction: [3]f32
		direction.x = math.cos(glm.radians_f32(ctx.camera.yaw)) * math.cos(glm.radians_f32(ctx.camera.pitch))
		direction.y = math.sin(glm.radians_f32(ctx.camera.pitch))
		direction.z = math.sin(glm.radians_f32(ctx.camera.yaw)) * math.cos(glm.radians_f32(ctx.camera.pitch))
		ctx.camera.front = direction

		gl.Enable(gl.DEPTH_TEST)

		view := camera_get_view_matrix(&ctx.camera)

		proj := glm.mat4Perspective(
			glm.radians_f32(ctx.camera.fov),  // FoV
			ctx.camera.ar,                    // AR
			0.1,                              // near clip
			100.0,                            // far clip
		)

		translation := glm.mat4Translate(0)


		// base cube
		shader_use(object_shader)
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, ctx.scene.material.diffuse.id)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, ctx.scene.material.specular.id)

		shader_set_uniform(object_shader, "diffuse_map", 0)
		shader_set_uniform(object_shader, "specular_map", 1)

		shader_set_uniform(object_shader, "object_color", &([3]f32{1.0, 0.5, 0.31}))

		shader_set_uniform(object_shader, "viewer_pos", &(ctx.camera.pos))

		shader_set_uniform(object_shader, "light_pos",      &(ctx.scene.light.pos))
		shader_set_uniform(object_shader, "light_ambient",  &(ctx.scene.light.ambient))
		shader_set_uniform(object_shader, "light_diffuse",  &(ctx.scene.light.diffuse))
		shader_set_uniform(object_shader, "light_specular", &(ctx.scene.light.specular))

		shader_set_uniform(object_shader, "light_gain", ctx.scene.light.gain)
		
		shader_set_uniform(object_shader, "material_shininess",  ctx.scene.material.shininess)

		gl.BindVertexArray(vao)

		model := glm.mat4(1.0) * translation

		shader_set_uniform(object_shader, "model", false,  &model)
		shader_set_uniform(object_shader, "view", false,  &view)
		shader_set_uniform(object_shader, "projection", false,  &proj)

		gl.DrawArrays(gl.TRIANGLES, 0, 36)


		// light cube
		shader_use(light_shader)
		gl.BindVertexArray(light_vao)

		translation = glm.mat4Translate(ctx.scene.light.pos)

		model = glm.mat4(1.0) * translation * glm.mat4Scale({0.2, 0.2, 0.2})

		shader_set_uniform(light_shader, "light_color_diff", &(ctx.scene.light.diffuse))
		shader_set_uniform(light_shader, "light_color_spec", &(ctx.scene.light.specular))
		shader_set_uniform(light_shader, "gain", ctx.scene.light.gain)

		shader_set_uniform(light_shader, "model", false,  &model)
		shader_set_uniform(light_shader, "view", false,  &view)
		shader_set_uniform(light_shader, "projection", false,  &proj)

		gl.DrawArrays(gl.TRIANGLES, 0, 36)


		ui_render(&ctx)


		glfw.SwapBuffers(ctx.window.handle)
	}
}