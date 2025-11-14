package learnopengl

import "core:math"
import "core:math/linalg"
import glm "core:math/linalg/glsl"

Camera :: struct {
	pos:      [3]f32,
	front:    [3]f32,
	up:       [3]f32,
	right:    [3]f32,
	world_up: [3]f32,

	fov:  f32,
	ar:   f32,
	zoom: f32,

	pitch: f32,
	yaw:   f32,
	roll:  f32,

	movement_speed:    f32,
	mouse_sensitivity: f32,
}

camera_init :: proc(
	camera: ^Camera,
	window: Window,

	pos : [3]f32 = {0, 0, 0},

	up    : Maybe([3]f32) = nil,
	pitch : Maybe(f32)    = nil,
	yaw   : Maybe(f32)    = nil,
) {
	DEFAULT_YAW         :: -90.0 
	DEFAULT_PITCH       :: 0.0
	DEFAULT_SPEED       :: 2.5
	DEFAULT_SENSITIVITY :: 0.1
	DEFAULT_ZOOM        :: 45.0

	camera.pos   = pos
	camera.world_up = up.([3]f32) if up != nil else {0, 1, 0}

	camera.movement_speed    = DEFAULT_SPEED
	camera.mouse_sensitivity = DEFAULT_SENSITIVITY
	camera.zoom              = DEFAULT_ZOOM

	camera.yaw   = yaw.(f32)   if yaw   != nil else DEFAULT_YAW
	camera.pitch = pitch.(f32) if pitch != nil else DEFAULT_PITCH

	_update_camera_vectors(camera)

	camera.fov = 45
	camera.ar  = f32(window.size.x)/f32(window.size.y)

}

_update_camera_vectors :: proc "contextless" (camera: ^Camera) {
	front: [3]f32
	front.x = math.cos(math.to_radians(camera.yaw)) * math.cos(math.to_radians(camera.pitch))
	front.y = math.sin(math.to_radians(camera.pitch))
	front.z = math.sin(math.to_radians(camera.yaw)) * math.cos(math.to_radians(camera.pitch))
	camera.front = glm.normalize(front)

	camera.right = glm.normalize(glm.cross(camera.front, camera.world_up))
	camera.up    = glm.normalize(glm.cross(camera.right, camera.front))

}

camera_get_view_matrix :: proc(camera: ^Camera) -> glm.mat4 {
	// return glm.mat4LookAt(camera.pos, camera.pos + camera.front, camera.up)
	return ex_LookAt(camera.pos, camera.pos + camera.front, camera.up)
}

ex_LookAt :: proc(pos, tar, wup: [3]f32) -> matrix[4,4]f32 {
	dir   := linalg.normalize(pos - tar)
	right := linalg.normalize(linalg.cross(wup, dir))
	up    := linalg.cross(dir, right)

	rotation := matrix[4,4]f32{
		right.x, right.y, right.z, 0,
		up.x,    up.y,    up.z,    0,
		dir.x,   dir.y,   dir.z,   0,
		0,       0,       0,       1,
	}

	translation := matrix[4,4]f32{
		1, 0, 0, -pos.x,
		0, 1, 0, -pos.y,
		0, 0, 1, -pos.z,
		0, 0, 0, 1,
	}

	return rotation * translation
}

Camera_Direction :: enum {
	Forward,
	Backward,
	Left,
	Right,
	Up,
	Down,
}

camera_move :: proc(camera: ^Camera, direction: Camera_Direction, delta_time: f32) {
	velocity := camera.movement_speed * delta_time
	switch direction {
	case .Forward:  camera.pos += camera.front * velocity
	case .Backward: camera.pos -= camera.front * velocity
	case .Left:     camera.pos -= camera.right * velocity
	case .Right:    camera.pos += camera.right * velocity
	case .Up:       camera.pos += camera.world_up * velocity
	case .Down:     camera.pos -= camera.world_up * velocity
	}
}

camera_look :: proc "contextless" (camera: ^Camera, x_offset, y_offset: f32, constrain_pitch: bool) {

	x_offset := x_offset
	y_offset := y_offset

	x_offset *= camera.mouse_sensitivity
	y_offset *= camera.mouse_sensitivity

	camera.yaw   += x_offset
	camera.pitch += y_offset

	if constrain_pitch {
		if camera.pitch >  89 do camera.pitch = 89
		if camera.pitch < -89 do camera.pitch = -89
	}
	_update_camera_vectors(camera)
}

camera_zoom :: proc "contextless" (camera: ^Camera, y_offset: f32) {
	camera.fov -= y_offset
	if camera.fov < 1   do camera.fov = 1
	if camera.fov > 120 do camera.fov = 120
}

