shader_type canvas_item;
// Pixel-art water shimmer: little horizontal glints that twinkle on and off.
//
// Put this on a ColorRect (color = white) that covers the water. Glints are:
//   * snapped to the pixel grid, 1 px tall, longer toward the viewer (perspective),
//   * denser in bands that roll slowly across the water,
//   * quantised to a few brightness steps so they read as pixel art.
// At night the script raises `light_strength` and a warm column of glints appears under the
// lantern (light_screen_x is the lantern's x in viewport pixels).

uniform vec2 area_size = vec2(384.0, 125.0);   // size of the rect in px
uniform vec4 glint_color : source_color = vec4(0.86, 0.94, 1.0, 1.0);
uniform vec4 warm_color : source_color = vec4(1.0, 0.82, 0.5, 1.0);
uniform float density : hint_range(0.0, 0.2) = 0.012;
uniform float twinkle_speed = 0.3;   // lower = slower, calmer glints
uniform float glint_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float glint_len_near = 2.0;   // streak length (px) at the horizon
uniform float glint_len_far = 5.0;    // ... and nearest the viewer
uniform float column_chance = 0.3;    // how many glints the lantern column adds
uniform float column_sigma_near = 3.0; // column half-width (px) at the horizon
uniform float column_sigma_far = 8.0;  // ... and nearest the viewer

uniform float night_visibility : hint_range(0.0, 1.0) = 0.3;  // 0 = glints dim with the night tint, 1 = ignore it

uniform float light_screen_x = -1000.0;
uniform float light_strength : hint_range(0.0, 1.0) = 0.0;

varying vec2 v_local;
varying vec4 v_mod;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	v_local = VERTEX;
	v_mod = COLOR;
}

void fragment() {
	vec2 p = floor(v_local);
	float t = clamp(p.y / area_size.y, 0.0, 1.0);   // 0 at the horizon, 1 nearest the viewer

	float len = floor(mix(glint_len_near, glint_len_far, t));            // glints get longer toward the viewer
	float cx = floor(p.x / len);
	float h = hash21(vec2(cx, p.y));
	float h2 = hash21(vec2(cx + 17.0, p.y + 91.0));

	// Slow rolling bands of activity.
	float wave = 0.5 + 0.5 * sin(p.x * 0.045 + p.y * 0.35 - TIME * twinkle_speed * 0.6);
	float chance = mix(density * 1.7, density * 0.7, t) * (0.35 + 1.3 * wave);

	// Warm glitter column under the lantern.
	float x_screen = SCREEN_UV.x / SCREEN_PIXEL_SIZE.x;
	float sigma = mix(column_sigma_near, column_sigma_far, t);
	float dxl = x_screen - light_screen_x;
	float col = exp(-(dxl * dxl) / (2.0 * sigma * sigma)) * light_strength;
	chance += col * column_chance;

	if (h > chance) {
		discard;
	}

	// Mostly dark, briefly bright.
	float tw = 0.5 + 0.5 * sin(TIME * twinkle_speed * (0.6 + h2) + h2 * 6.2831);
	float b = smoothstep(0.4, 1.0, tw);
	b = floor(b * 3.0 + 0.5) / 3.0;                 // 4 brightness steps
	if (b <= 0.0) {
		discard;
	}

	// Taper the ends of each streak.
	float u = (p.x - cx * len + 0.5) / len;
	if (abs(u * 2.0 - 1.0) > 0.7) {
		b *= 0.5;
	}

	vec3 rgb = mix(glint_color.rgb, warm_color.rgb, clamp(col * 2.0, 0.0, 1.0));
	// Glints are reflected light, so they only partly follow the day/night tint (the lantern's
	// column ignores it almost entirely). Otherwise they vanish at night.
	float keep = clamp(night_visibility + col * 2.0, 0.0, 1.0);
	COLOR = vec4(rgb, b * glint_alpha) * mix(v_mod, vec4(1.0), keep);
}
