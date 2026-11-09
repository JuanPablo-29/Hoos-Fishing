shader_type canvas_item;
// Pixel-art water reflection.
//
// Put this on a COPY of a sprite that has been mirrored (scale.y = -1) so it hangs below the
// mirror line. The shader then:
//   * throws away anything on the wrong side of the mirror line,
//   * wobbles each pixel row sideways (in whole art pixels, so it stays crisp),
//   * fades the reflection out with depth and tints it toward the water colour,
//   * breaks it into horizontal slices that get more broken the deeper you go.
//
// Two ways of measuring "depth below the mirror line":
//   use_world_depth = false : from the sprite's own local space (scenery layers; axis_local_y).
//   use_world_depth = true  : from a world-space y (things that move, e.g. the boat; axis_y).

uniform bool use_world_depth = false;
uniform float axis_local_y = -17.0;   // sprite-local y of the mirror line (scenery)
uniform float axis_y = 0.0;           // world y of the mirror line (boat). Set from script.
uniform float pixel_size : hint_range(1.0, 4.0) = 1.0;  // size of one art pixel on screen
uniform float min_depth = 0.0;        // also hide anything shallower than this (e.g. parts that the hull covers)

uniform float fade_depth = 56.0;      // depth (px) at which the reflection has fully faded
uniform float max_alpha : hint_range(0.0, 1.0) = 0.5;
uniform vec4 water_tint : source_color = vec4(0.27, 0.32, 0.62, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.5;

uniform float ripple_px = 3.0;        // sideways wobble at full depth, in screen px
uniform float ripple_speed = 0.45;   // lower = slower, calmer wobble
uniform float ripple_freq = 0.75;
uniform float gap_amount : hint_range(0.0, 1.0) = 0.55;  // how broken-up the deep part gets

varying float v_depth;
varying vec4 v_mod;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void vertex() {
	v_mod = COLOR; // node modulate (incl. day/night tint); re-applied at the end
	if (use_world_depth) {
		v_depth = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y - axis_y;
	} else {
		v_depth = axis_local_y - VERTEX.y;
	}
}

void fragment() {
	float depth = v_depth;
	if (depth < 0.0 || depth < min_depth) {
		discard;
	}

	float row = floor(depth / pixel_size);
	float k = clamp(depth / fade_depth, 0.0, 1.0);

	// Sideways wobble, quantised to whole art pixels.
	float w = sin(row * ripple_freq + TIME * ripple_speed)
		+ 0.6 * sin(row * ripple_freq * 2.3 - TIME * ripple_speed * 1.7);
	float amp = ripple_px * mix(0.35, 1.0, k);
	float dx_texels = round(w / 1.6 * amp / pixel_size);   // whole art pixels

	vec2 uv = UV + vec2(dx_texels * TEXTURE_PIXEL_SIZE.x, 0.0);
	vec4 tex = texture(TEXTURE, uv);

	// Fade with depth, with a little shimmer on the fade itself.
	float alpha = max_alpha * (1.0 - smoothstep(0.0, 1.0, k));

	// Broken-up slices: deeper rows drop out more often, and the pattern slowly crawls.
	float cut = hash11(row * 3.17 + floor(TIME * ripple_speed * 0.25 + row * 0.37));
	if (cut < gap_amount * k) {
		alpha *= 0.25;
	}

	vec3 rgb = mix(tex.rgb, water_tint.rgb, tint_amount);
	COLOR = vec4(rgb, tex.a * alpha) * v_mod;
}
