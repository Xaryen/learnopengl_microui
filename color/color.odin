package color

import "base:intrinsics"
import "core:math"

hsv_from_rgb :: proc(rgb: $T/[3]$E) -> (T) where intrinsics.type_is_float(E) {
	r := rgb.r
	g := rgb.g
	b := rgb.b

	h, s, v: E

	rgb_max := max(r, g, b)
	if rgb_max == 0 {
		return 0
	}

	rgb_min := min(r, g, b)
	rgb_delta := rgb_max - rgb_min
	
	s = rgb_delta / rgb_max
	v = rgb_max

	if rgb_delta == 0 {
		h = 0
	} else if r == rgb_max {
		h = (g - b) / rgb_delta
	} else if g == rgb_max {
		h = 2 + (b - r) / rgb_delta
	} else {
		h = 4 + (r - g) / rgb_delta
	}

	h *= (1.0 / 6)
	if h < 0 {
		h += 1
	}
	return {h, s, v}
}


rgb_from_hsv :: proc(hsv: $T/[3]$E) -> T where intrinsics.type_is_float(E) {
	h := hsv.x
	s := hsv.y
	v := hsv.z

	r, g, b: E

	if s == 0 {
		return v
	}

	h *= 6
	i := i32(math.floor(h))
	f := h - E(i)
	i = i % 6 if i >= 0 else (i % 6) + 6

	p := v * (1 - s)
	q := v * (1 - s * f)
	t := v * (1 - s * (1 - f))

	switch i {
	case 0:
		r, g, b = v, t, p
	case 1:
		r, g, b = q, v, p
	case 2:
		r, g, b = p, v, t
	case 3:
		r, g, b = p, q, v
	case 4:
		r, g, b = t, p, v
	case 5:
		r, g, b = v, p, q
	}

	return {r, g, b}
}
