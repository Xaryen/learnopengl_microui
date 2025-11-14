package learnopengl

import "core:log"

import mu  "vendor:microui"
import gl  "vendor:OpenGL"
import glm "core:math/linalg/glsl"


UI_Vertex :: struct {
        pos:   [2]f32, 
        uv:    [2]f32, 
        color: [4]u8,  
}

UI_BUFFER_SIZE :: 16384

@(private="file")
g_ui_vertices  := [UI_BUFFER_SIZE*4]UI_Vertex{}
@(private="file")
g_ui_indices   := [UI_BUFFER_SIZE*6]u32{}
@(private="file")
g_ui_ctx       := mu.Context{}

ui_r_init :: proc(ctx: ^Program) {
        shader_init(&ctx.ui.renderer.shader, "shaders/ui.vert", "shaders/ui.frag")

        ctx.ui.renderer.vertices = g_ui_vertices[:]
        ctx.ui.renderer.indices  = g_ui_indices[:]

        ctx.ui.ctx  = &g_ui_ctx


        gl.GenVertexArrays(1, &ctx.ui.renderer.vao)
        gl.GenBuffers(1, &ctx.ui.renderer.vbo)
        gl.GenBuffers(1, &ctx.ui.renderer.ebo)

        gl.BindVertexArray(ctx.ui.renderer.vao)
        gl.BindBuffer(gl.ARRAY_BUFFER, ctx.ui.renderer.vbo)
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ctx.ui.renderer.ebo)

        gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(UI_Vertex), offset_of(UI_Vertex, pos))
        gl.EnableVertexAttribArray(0) // pos
        gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(UI_Vertex), offset_of(UI_Vertex, uv))
        gl.EnableVertexAttribArray(1) // uv
        gl.VertexAttribPointer(2, 4, gl.UNSIGNED_BYTE, gl.TRUE, size_of(UI_Vertex), offset_of(UI_Vertex, color))
        gl.EnableVertexAttribArray(2) // color


        gl.GenTextures(1, &ctx.ui.renderer.ui_texture)
        gl.BindTexture(gl.TEXTURE_2D, ctx.ui.renderer.ui_texture)
        gl.TexImage2D(
                gl.TEXTURE_2D,
                0,
                gl.RED,
                mu.DEFAULT_ATLAS_WIDTH,
                mu.DEFAULT_ATLAS_HEIGHT,
                0,
                gl.RED,
                gl.UNSIGNED_BYTE,
                raw_data(mu.default_atlas_alpha[:]),
        )
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)


        gl.BindTexture(gl.TEXTURE_2D, 0)
        gl.BindVertexArray(0)
        gl.BindBuffer(gl.ARRAY_BUFFER, 0)
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
}

ui_r_flush :: proc(ctx: ^Program) {
        if ctx.ui.renderer.buf_idx == 0 do return

        shader_use(ctx.ui.renderer.shader)
        gl.BindVertexArray(ctx.ui.renderer.vao)

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, ctx.ui.renderer.ui_texture)

        shader_set_uniform(ctx.ui.renderer.shader, "uTex", 0)

        gl.Disable(gl.DEPTH_TEST)
        gl.Enable(gl.BLEND)
        gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)


        proj := glm.mat4Ortho3d(
                0,
                f32(ctx.window.size.x), 
                f32(ctx.window.size.y), // swapped top and bottom here 
                0,                      // to flip the coords
                -1,
                +1,
        )

        shader_set_uniform(ctx.ui.renderer.shader, "uProj", false, &proj)

        gl.BindBuffer(gl.ARRAY_BUFFER, ctx.ui.renderer.vbo)
        gl.BufferData(
                gl.ARRAY_BUFFER,
                int(ctx.ui.renderer.buf_idx) * 4 * size_of(UI_Vertex),
                &ctx.ui.renderer.vertices[0],
                gl.STREAM_DRAW,
        )

        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ctx.ui.renderer.ebo)
        gl.BufferData(
                gl.ELEMENT_ARRAY_BUFFER,
                int(ctx.ui.renderer.buf_idx) * 6 * size_of(u32),
                &ctx.ui.renderer.indices[0],
                gl.STREAM_DRAW,
        )


        gl.DrawElements(
                gl.TRIANGLES,
                ctx.ui.renderer.buf_idx * 6,
                gl.UNSIGNED_INT,
                nil,
        )

        gl.BindVertexArray(0)
        ctx.ui.renderer.buf_idx = 0
}

ui_r_push_quad :: proc(ctx: ^Program, dst, src: mu.Rect, color: mu.Color) {
        if ctx.ui.renderer.buf_idx == UI_BUFFER_SIZE do ui_r_flush(ctx)

        vert_index := ctx.ui.renderer.buf_idx * 4
        idx_index  := ctx.ui.renderer.buf_idx * 6

        x := f32(src.x) / f32(mu.DEFAULT_ATLAS_WIDTH)
        y := f32(src.y) / f32(mu.DEFAULT_ATLAS_HEIGHT)
        w := f32(src.w) / f32(mu.DEFAULT_ATLAS_WIDTH)
        h := f32(src.h) / f32(mu.DEFAULT_ATLAS_HEIGHT)

        v := [4]UI_Vertex{
                {{f32(dst.x), f32(dst.y)},             {x, y},             {color.r, color.g, color.b, color.a} },
                {{f32(dst.x + dst.w), f32(dst.y)},     {x + w, y},         {color.r, color.g, color.b, color.a} },
                {{f32(dst.x), f32(dst.y + dst.h)},     {x, y + h},         {color.r, color.g, color.b, color.a} },
                {{f32(dst.x + dst.w), f32(dst.y + dst.h)}, {x + w, y + h}, {color.r, color.g, color.b, color.a} },
        }

        copy(ctx.ui.renderer.vertices[vert_index:], v[:])

        base := u32(vert_index)
        inds := [6]u32{ base + 0, base + 1, base + 2, base + 2, base + 3, base + 1 }
        copy(ctx.ui.renderer.indices[idx_index:], inds[:])

        ctx.ui.renderer.buf_idx += 1
}

ui_r_clear :: proc(clr: mu.Color) {
        clrf := [4]f32{f32(clr.r), f32(clr.g), f32(clr.b), f32(clr.a)}
        gl.ClearColor(clrf.r / 255.0, clrf.g / 255.0, clrf.b / 255.0, clrf.a / 255.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)
}

ui_r_draw_rect :: proc(ctx: ^Program, rect: mu.Rect, color: mu.Color) {
        ui_r_push_quad(ctx, rect, mu.default_atlas[mu.DEFAULT_ATLAS_WHITE], color)
}


ui_r_draw_text :: proc(ctx: ^Program, text: string, pos: mu.Vec2, color: mu.Color) {
        dst := mu.Rect{pos.x, pos.y, 0, 0}
        for codepoint in text {
                if codepoint&0xc0 == 0x80 do continue

                r     := min(int(codepoint), 127)
                src   := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
                dst.w  = src.w
                dst.h  = src.h
 
                ui_r_push_quad(ctx, dst, src, color)
                dst.x += dst.w
        }
}


ui_r_draw_icon :: proc(ctx: ^Program, id: mu.Icon, rect: mu.Rect, color: mu.Color) {
        src := mu.default_atlas[id]
        x := rect.x + (rect.w - src.w) / 2
        y := rect.y + (rect.h - src.h) / 2
        ui_r_push_quad(ctx, mu.Rect{x, y, src.w, src.h}, src, color)
}

ui_r_set_clip_rect :: proc(ctx: ^Program, rect: mu.Rect) {
        ui_r_flush(ctx)
        gl.Scissor(rect.x, ctx.window.size.y - (rect.y + rect.h), rect.w, rect.h)
}

ui_r_render :: proc(ctx: ^Program) {
        ui_r_flush(ctx)
}



