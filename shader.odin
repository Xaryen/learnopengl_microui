package learnopengl

import "core:os"
import "core:log"
import "core:strings"
import gl "vendor:OpenGL"

Shader :: u32

shader_set_uniform :: proc {
	shader_set_uniform_mat4,
	shader_set_uniform_float,
	shader_set_uniform_vec3_color,
	shader_set_uniform_vec3,
	shader_set_uniform_vec2,
	shader_set_uniform_bool,
	shader_set_uniform_int,
}

shader_set_uniform_mat4 :: proc(
	shader:    Shader,
	name:      cstring,
	transpose: bool = false,
	val:       ^matrix[4, 4]f32,
	) {
	
	gl_transpose := gl.TRUE if transpose else gl.FALSE

	gl.UniformMatrix4fv(
		gl.GetUniformLocation(shader, name),
		1,
		gl_transpose,
		&val[0][0]
	)
}

shader_set_uniform_float :: proc(shader: Shader, name: cstring, val:f32) {
	gl.Uniform1f(gl.GetUniformLocation(shader, name), val)
}

shader_set_uniform_vec3_color :: proc(shader: Shader, name: cstring, val:^Color32f) {
	gl.Uniform3fv(gl.GetUniformLocation(shader, name), 1, &val[0])
}

shader_set_uniform_vec3 :: proc(shader: Shader, name: cstring, val:^[3]f32) {
	gl.Uniform3fv(gl.GetUniformLocation(shader, name), 1, &val[0])
}

shader_set_uniform_vec2 :: proc(shader: Shader, name: cstring, val:^[2]f32) {
	gl.Uniform2fv(gl.GetUniformLocation(shader, name), 1, &val[0])
}

shader_set_uniform_bool :: proc(shader: Shader, name: cstring, val:b32) {
	gl.Uniform1i(gl.GetUniformLocation(shader, name), i32(val))
}
shader_set_uniform_int :: proc(shader: Shader, name: cstring, val:i32) {
	gl.Uniform1i(gl.GetUniformLocation(shader, name), val)
}

shader_use :: proc(shader_program: u32) {
	gl.UseProgram(shader_program)
}

shader_init :: proc(shader: ^Shader, vertex_path, fragment_path: string) {
	vertex_data, v_ok   := os.read_entire_file_from_filename(vertex_path)
	fragment_data, f_ok := os.read_entire_file_from_filename(fragment_path)

	if !v_ok do log.error("Failed to load vertex shader code", vertex_path)
	if !f_ok do log.error("Failed to load fragment shader code", fragment_path)

	vertex_shader_code   := strings.clone_to_cstring(string(vertex_data))
	fragment_shader_code := strings.clone_to_cstring(string(fragment_data))

	vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertex_shader, 1, &vertex_shader_code, nil)
	gl.CompileShader(vertex_shader)
	_get_shader_compilation_log(vertex_shader)

	fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragment_shader, 1, &fragment_shader_code, nil)
	gl.CompileShader(fragment_shader)
	_get_shader_compilation_log(fragment_shader)

	shader_program := gl.CreateProgram()

	gl.AttachShader(shader_program, vertex_shader)
	gl.AttachShader(shader_program, fragment_shader)
	gl.LinkProgram(shader_program)
	_get_shader_linking_log(shader_program)

	delete(vertex_data)
	delete(fragment_data)
	delete(vertex_shader_code)
	delete(fragment_shader_code)
	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)

	shader^ = shader_program
}

_get_shader_compilation_log :: proc(shader: u32) {
	success: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetShaderInfoLog(shader, 512, nil, &info_log[0])
		log.errorf("%s", info_log)
	}
}

_get_shader_linking_log :: proc(shader_program: u32) {
	success: i32
	gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		gl.GetProgramInfoLog(shader_program, 512, nil, &info_log[0])
		log.errorf("%s", info_log)
	}
}