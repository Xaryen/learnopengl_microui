package learnopengl 

import "core:log"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

Texture :: struct {
	id: u32,
	width, height: i32,
	channels: i32,
}

Format :: enum {
	RGB,
	RGBA
}

load_texture :: proc(bytes: []byte, format: Format, flip: b32) -> Texture {
	width, height, channels: i32
	
	stbi.set_flip_vertically_on_load(i32(flip))
	data := stbi.load_from_memory(&bytes[0], i32(len(bytes)), &width, &height, &channels, 0 )

	log.info("loaded image", width, height, channels)

	texture: u32
	gl.GenTextures(1, &texture)

	gl.BindTexture(gl.TEXTURE_2D, texture)

	// REPEAT
	// MIRRORED_REPEAT
	// CLAMP_TO_EDGE
	// CLAMP_TO_BORDER
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl_format: i32

	switch format {
	case .RGB:  gl_format = gl.RGB
	case .RGBA: gl_format = gl.RGBA
	}

	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		gl_format,
		width, height,
		0,
		cast(u32)gl_format,
		gl.UNSIGNED_BYTE,
		&data[0]
	)

	gl.GenerateMipmap(gl.TEXTURE_2D)

	stbi.image_free(data)

	return 	Texture{
		id = texture,
		width = width,
		height = height,
		channels = channels,		
	}

}

