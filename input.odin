package learnopengl

import     "vendor:glfw"
import mu  "vendor:microui"

Mouse :: struct {
	last_x: f64,
	last_y: f64,

	first: bool,
}

Mouse_Button :: enum {
	Left,
	Right,
	Middle,
}

Key :: enum {
	Space,
}

process_input :: proc(ctx: ^Program) {

	if glfw.GetKey(ctx.window.handle, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(ctx.window.handle, true)
	}
	if glfw.GetKey(ctx.window.handle, glfw.KEY_W) == glfw.PRESS {
		camera_move(&ctx.camera, .Forward, f32(ctx.delta_time))
	}
	if glfw.GetKey(ctx.window.handle, glfw.KEY_S) == glfw.PRESS {
		camera_move(&ctx.camera, .Backward, f32(ctx.delta_time))
	}
	if glfw.GetKey(ctx.window.handle, glfw.KEY_A) == glfw.PRESS {
		camera_move(&ctx.camera, .Left, f32(ctx.delta_time))
	}
	if glfw.GetKey(ctx.window.handle, glfw.KEY_D) == glfw.PRESS {
		camera_move(&ctx.camera, .Right, f32(ctx.delta_time))
	}
	if glfw.GetKey(ctx.window.handle, glfw.KEY_E) == glfw.PRESS {
		camera_move(&ctx.camera, .Up, f32(ctx.delta_time))
	}
	if glfw.GetKey(ctx.window.handle, glfw.KEY_Q) == glfw.PRESS {
		camera_move(&ctx.camera, .Down, f32(ctx.delta_time))
	}
	if glfw.GetKey(ctx.window.handle, glfw.KEY_SPACE) == glfw.PRESS {
		ctx.keys_down += {.Space}
	}
	if .Space in ctx.keys_down &&
	(glfw.GetKey(ctx.window.handle, glfw.KEY_SPACE) == glfw.RELEASE) {
		ctx.keys_down -= {.Space}
		ctx.ui.open = !ctx.ui.open
		ctx.ui.update_open = true
	}


	if glfw.GetMouseButton(ctx.window.handle, glfw.MOUSE_BUTTON_2) == glfw.PRESS {
		ctx.mb_down += {.Right}
	}
	if glfw.GetMouseButton(ctx.window.handle, glfw.MOUSE_BUTTON_2) == glfw.RELEASE {
		ctx.mb_down -= {.Right}
	}


	if .Left not_in ctx.mb_down && (glfw.GetMouseButton(ctx.window.handle, glfw.MOUSE_BUTTON_1) == glfw.PRESS) {
		ctx.mb_down += {.Left}
		x, y := glfw.GetCursorPos(ctx.window.handle)
		mu.input_mouse_down(ctx.ui.ctx, i32(x), i32(y), .LEFT)
	}
	if .Left in ctx.mb_down && (glfw.GetMouseButton(ctx.window.handle, glfw.MOUSE_BUTTON_1) == glfw.RELEASE) {
		
		ctx.mb_down -= {.Left}
		x, y := glfw.GetCursorPos(ctx.window.handle)
		mu.input_mouse_up(ctx.ui.ctx, i32(x), i32(y), .LEFT)
	}
}


mouse_callback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64) {
	ctx := (^Program)(glfw.GetWindowUserPointer(window))
	if .Right in ctx.mb_down {
	
		if ctx.mouse.first {
			ctx.mouse.last_x = xpos
			ctx.mouse.last_y = ypos
			ctx.mouse.first = false
		}

		xoffset := xpos - ctx.mouse.last_x
		yoffset := ctx.mouse.last_y - ypos

		ctx.mouse.last_x = xpos
		ctx.mouse.last_y = ypos

		camera_look(&ctx.camera, f32(xoffset), f32(yoffset), true)
	} else {
		input_mouse_move :: proc "contextless"(ctx: ^mu.Context, x, y: i32) {
			ctx.mouse_pos = mu.Vec2{x, y}
		}
		input_mouse_move(ctx.ui.ctx, i32(xpos), i32(ypos))
		ctx.mouse.first = true
	}
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
	ctx := (^Program)(glfw.GetWindowUserPointer(window))

	camera_zoom(&ctx.camera, f32(yoffset))
}