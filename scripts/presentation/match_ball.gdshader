shader_type spatial;

void fragment() {
	float ribbon = sin(UV.x * TAU * 3.0 + sin(UV.y * TAU) * 1.6);
	float panel = smoothstep(0.28, 0.34, ribbon);
	float seam = 1.0 - smoothstep(0.015, 0.085, abs(ribbon - 0.30));
	vec3 blue = vec3(0.025, 0.20, 0.72);
	vec3 gold = vec3(1.0, 0.67, 0.045);
	vec3 pale = vec3(0.94, 0.94, 0.82);
	ALBEDO = mix(mix(pale, blue, smoothstep(0.59, 0.62, UV.y + 0.1 * ribbon)), gold, panel);
	ALBEDO *= 1.0 - 0.24 * seam;
	ROUGHNESS = 0.72;
}
