shader_type spatial;
// The runner's ground: Io sulphur flats with a packed track down the lanes.
// Everything is drawn in world space, so the pattern stays put while the car
// drives over it. That is what makes the ground read as moving.

uniform sampler2D noise_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 flat_dark : source_color = vec3(0.17, 0.12, 0.05);
uniform vec3 flat_light : source_color = vec3(0.52, 0.42, 0.14);
uniform vec3 track_color : source_color = vec3(0.13, 0.11, 0.09);
uniform float track_half_width = 10.4;
uniform float track_edge = 2.5;
uniform float patch_size = 70.0;   // metres per repeat of the large patches
uniform float grain_size = 9.0;   // metres per repeat of the fine grain

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float patches = texture(noise_tex, p / patch_size).r;
	float grain = texture(noise_tex, p / grain_size + vec2(0.37, 0.11)).r;
	float tone = smoothstep(0.25, 0.75, patches) * 0.7 + smoothstep(0.3, 0.7, grain) * 0.3;
	vec3 flats = mix(flat_dark, flat_light, tone);

	// Packed track under the lanes, with a ragged edge and tyre-worn streaks.
	float edge = track_half_width + (grain - 0.5) * 1.6;
	float on_track = 1.0 - smoothstep(edge, edge + track_edge, abs(p.x));
	float streak = texture(noise_tex, vec2(p.x / 3.0, p.y / 60.0)).r;
	vec3 track = track_color * (0.75 + 0.5 * streak);

	ALBEDO = mix(flats, track, on_track);
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
