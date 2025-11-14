package learnopengl

import "core:fmt"
import "core:reflect"
import mu  "vendor:microui"
import "color"

UI :: struct {
	ctx:      ^mu.Context,
	renderer: struct{
		shader: Shader,
		vao, vbo, ebo, ui_texture: u32,
		vertices: []UI_Vertex,
		indices:  []u32,
		buf_idx:  i32,
	},
	open:        bool,
	update_open: bool,
	// bg: mu.Color,
}

ui_render :: proc(ctx: ^Program) {
	ui_ctx := ctx.ui.ctx
	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(ui_ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			ui_r_draw_text(ctx, cmd.str, cmd.pos, cmd.color)
		case ^mu.Command_Rect:
			ui_r_draw_rect(ctx, cmd.rect, cmd.color)
		case ^mu.Command_Clip:
			ui_r_set_clip_rect(ctx, cmd.rect)
		case ^mu.Command_Icon:
			ui_r_draw_icon(ctx, cmd.id, cmd.rect, cmd.color)
		case ^mu.Command_Jump:
			unreachable()
		}
	}
	// ui_r_clear(ctx.ui.bg)
	ui_r_render(ctx)
}

ui_panel :: proc(ctx: ^Program) {
	ui_ctx := ctx.ui.ctx

	if ctx.ui.update_open {		
		cnt := mu.get_container(ui_ctx, "Control Panel")
		if ctx.ui.open {
			cnt.open = true
		} else {
			cnt.open = false
		}
	}
	ctx.ui.update_open = false

	if mu.window(ui_ctx, "Control Panel", {30, 30, 300, 550}) {

		if .ACTIVE in mu.header(ui_ctx, "Light Params", {.EXPANDED}) {
			light_params_names := reflect.struct_field_names(Light)
			for name in light_params_names {
				mu.layout_row(ui_ctx, {-20, -1}, 68)
				mu.layout_begin_column(ui_ctx)
				field := reflect.struct_field_value_by_name(
					ctx.scene.light,
					name,
				)
				switch &value in field {
				case f32: 
				if .ACTIVE in mu.header(ui_ctx, name, {.EXPANDED}) {
					mu.layout_row(ui_ctx, {0, -1}, 0)
					mu.label(ui_ctx, name)
					mu.slider(
						ui_ctx,
						&value,
						0, 10,
						0, 
						"%.2f",
						{.ALIGN_CENTER},
					) 
				}
				case [3]f32: 
				if .ACTIVE in mu.header(ui_ctx, name, {.EXPANDED}) {
					mu.layout_row(ui_ctx, {0, -1}, 0)
					mu.label(ui_ctx, fmt.tprint(name, " - x"))
					mu.slider(
						ui_ctx,
						&value.x,
						-5, 5,
						0, 
						"%.2f", {.ALIGN_CENTER},
					)
					mu.label(ui_ctx, fmt.tprint(name, " - y"))
					mu.slider(
						ui_ctx,
						&value.y,
						-5, 5,
						0, 
						"%.2f", {.ALIGN_CENTER},
					)
					mu.label(ui_ctx, fmt.tprint(name, " - z"))
					mu.slider(
						ui_ctx,
						&value.z,
						-5, 5,
						0, 
						"%.2f", {.ALIGN_CENTER},
					)
				}
				case Color32f:
				if .ACTIVE in mu.header(ui_ctx, name, {.EXPANDED}) {
					mu.layout_row(ui_ctx, {0, -1}, 0)
					rgba := &value
					rgb := rgba^.rgb

					hsv := color.hsv_from_rgb(rgb)

					mu.push_id(ui_ctx, name)
					mu.label(ui_ctx, fmt.tprint(name, " - H"))
					mu.slider(
						ui_ctx,
						&hsv.x,
						0, 0.99, 0, 
						"%.2f", {.ALIGN_CENTER},
					)
					mu.label(ui_ctx, fmt.tprint(name, "- S"))
					mu.slider(
						ui_ctx,
						&hsv.y,
						0, 1, 0, 
						"%.2f", {.ALIGN_CENTER},
					)
					mu.label(ui_ctx, fmt.tprint(name, "- V"))
					mu.slider(
						ui_ctx,
						&hsv.z,
						0, 1, 0, 
						"%.2f", {.ALIGN_CENTER},
					)
					mu.pop_id(ui_ctx)
					rgb = color.rgb_from_hsv(hsv)
					rgba^.rgb = rgb
				}
				case: 
					// else skip
				}
				mu.layout_end_column(ui_ctx)
			}
		}

	} else {
		ctx.ui.open = false
		ctx.ui.update_open = true
	}
}

