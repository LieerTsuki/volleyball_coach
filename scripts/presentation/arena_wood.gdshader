shader_type spatial;

varying vec2 floor_position;

void vertex() {
	floor_position = VERTEX.xz;
}

void fragment() {
	vec2 plank = floor_position / vec2(0.24, 2.15);
	plank.y += mod(floor(plank.x), 4.0) * 0.25;
	vec2 tile = floor(plank);
	vec2 edge = fract(plank);
	float tone = fract(sin(dot(tile, vec2(42.7, 23.3))) * 12893.37);
	float grain = sin(floor_position.x * 38.0 + sin(floor_position.y * 1.9 + tone * 6.28) * 1.4);
	float seam = smoothstep(0.0, max(0.035, fwidth(plank.x)), min(edge.x, 1.0 - edge.x))
		* smoothstep(0.0, max(0.006, fwidth(plank.y)), min(edge.y, 1.0 - edge.y));
	ALBEDO = mix(vec3(0.48, 0.214, 0.09), vec3(0.76, 0.45, 0.20), 0.75 + tone * 0.20 + grain * 0.026);
	ALBEDO *= mix(0.83, 1.0, seam);
	ROUGHNESS = 0.66;
}
