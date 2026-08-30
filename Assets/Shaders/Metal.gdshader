shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Godot 4: structural recreation of the supplied Blender material graph.
// Independent gradient-noise implementation: NOT Blender-identical noise.
// Both color ramps receive Noise Color converted to luminance. Roughness
// receives the fine Noise Factor. No normal, bump, or displacement is added.
//
// Setup: assign to a ShaderMaterial on a MeshInstance3D. No scripts,
// programmatically supplied parameters, UVs, or mesh bounds are required.
// All uniforms have defaults and can optionally be edited in the Inspector.
// The noise uses local mesh coordinates and moves with the mesh. Unlike
// Blender Generated coordinates, it is not normalized to each mesh's bounds.
// Larger geometry in mesh-local units contains more repetitions; scaling the
// node stretches the texture with it. Adjust texture_scale in the Inspector
// if you want a different pattern density.
//
// All ramp colors, unselected stop positions, and hidden BSDF settings are
// estimates. Replace them with the original values for a closer match.

group_uniforms Coordinates;
uniform vec3 texture_scale = vec3(1.0);
uniform vec3 texture_offset = vec3(0.0);

group_uniforms Noise;
uniform float fine_scale : hint_range(0.0, 100.0, 0.1) = 38.8;
uniform float coarse_scale : hint_range(0.0, 10.0, 0.01) = 1.1;
uniform float noise_roughness : hint_range(0.0, 1.0, 0.001) = 0.828;
uniform float noise_lacunarity : hint_range(1.0, 4.0, 0.01) = 2.0;
// Detail = 2 is implemented as a base octave plus two detail octaves.
// Normalize is on; distortion is zero, matching both nodes.
// Standard linear-sRGB luminance coefficients; custom Blender working
// color spaces may use different coefficients.
uniform vec3 luminance_weights = vec3(0.2126, 0.7152, 0.0722);

group_uniforms FineColorRamp;
// Colors estimated from the screenshot's displayed sRGB swatches.
uniform vec4 fine_dark : source_color = vec4(0.337255, 0.223529, 0.160784, 1.0);
uniform vec4 fine_light : source_color = vec4(0.658824, 0.505882, 0.388235, 1.0);
uniform float fine_start : hint_range(0.0, 1.0, 0.001) = 0.170; // Estimated.
uniform float fine_end : hint_range(0.0, 1.0, 0.001) = 0.571; // Visible.

group_uniforms CoarseColorRamp;
uniform vec4 coarse_dark : source_color = vec4(0.337255, 0.313725, 0.301961, 1.0);
uniform vec4 coarse_light : source_color = vec4(0.525490, 0.372549, 0.309804, 1.0);
uniform float coarse_start : hint_range(0.0, 1.0, 0.001) = 0.490; // Estimated.
uniform float coarse_end : hint_range(0.0, 1.0, 0.001) = 0.832; // Visible.

group_uniforms RoughnessRamp;
// Three LINEAR stops: black, gray, white. Keep positions ascending.
// The gray swatch looks approximately sRGB 0.737, or LINEAR 0.5.
// Roughness is numeric data: do not use source_color for these values.
uniform float rough_start : hint_range(0.0, 1.0, 0.001) = 0.130; // Estimated.
uniform float rough_mid : hint_range(0.0, 1.0, 0.001) = 0.316; // Visible.
uniform float rough_end : hint_range(0.0, 1.0, 0.001) = 1.0; // Estimated.
uniform float rough_low_value : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float rough_mid_value : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float rough_high_value : hint_range(0.0, 1.0, 0.001) = 1.0;

group_uniforms Surface;
uniform float color_mix : hint_range(0.0, 1.0, 0.001) = 0.730;
uniform float metallic : hint_range(0.0, 1.0, 0.001) = 0.900;
// Default dielectric specular level: approximately IOR 1.5 in Godot.
// This does not recreate every setting of Blender's Principled BSDF.
uniform float specular : hint_range(0.0, 1.0, 0.001) = 0.5;
group_uniforms;

varying vec3 local_position;

// Deterministic lattice hashing, independent of Blender's noise hash.
uint lattice_hash(ivec3 cell) {
	uvec3 v = uvec3(cell);
	uint h = (v.x * 1597334677u) ^ (v.y * 3812015801u) ^ (v.z * 2798796415u);
	h = (h ^ (h >> 16u)) * 2246822519u;
	h = (h ^ (h >> 13u)) * 3266489917u;
	return h ^ (h >> 16u);
}

// Perlin-style gradients: pick two axes and independently choose signs.
float gradient_dot(ivec3 cell, vec3 delta) {
	uint h = lattice_hash(cell);
	uint axis = h % 3u;
	vec2 components = delta.xy;
	if (axis == 1u) {
		components = delta.yz;
	} else if (axis == 2u) {
		components = delta.zx;
	}
	float a = ((h & 8u) == 0u) ? components.x : -components.x;
	float b = ((h & 16u) == 0u) ? components.y : -components.y;
	return a + b;
}

float gradient_noise(vec3 p) {
	ivec3 cell = ivec3(floor(p));
	vec3 f = fract(p);
	// Quintic interpolation belongs to noise, NOT to the linear color ramps.
	vec3 fade = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float n000 = gradient_dot(cell, f);
	float n100 = gradient_dot(cell + ivec3(1, 0, 0), f - vec3(1.0, 0.0, 0.0));
	float n010 = gradient_dot(cell + ivec3(0, 1, 0), f - vec3(0.0, 1.0, 0.0));
	float n110 = gradient_dot(cell + ivec3(1, 1, 0), f - vec3(1.0, 1.0, 0.0));
	float n001 = gradient_dot(cell + ivec3(0, 0, 1), f - vec3(0.0, 0.0, 1.0));
	float n101 = gradient_dot(cell + ivec3(1, 0, 1), f - vec3(1.0, 0.0, 1.0));
	float n011 = gradient_dot(cell + ivec3(0, 1, 1), f - vec3(0.0, 1.0, 1.0));
	float n111 = gradient_dot(cell + ivec3(1, 1, 1), f - vec3(1.0, 1.0, 1.0));
	float lower = mix(mix(n000, n100, fade.x), mix(n010, n110, fade.x), fade.y);
	float upper = mix(mix(n001, n101, fade.x), mix(n011, n111, fade.x), fade.y);
	return mix(lower, upper, fade.z);
}

float normalized_fbm(vec3 p) {
	float total = 0.0;
	float amplitude = 1.0;
	float amplitude_sum = 0.0;
	for (int octave = 0; octave < 3; octave++) {
		total += gradient_noise(p) * amplitude;
		amplitude_sum += amplitude;
		amplitude *= noise_roughness;
		p *= noise_lacunarity;
	}
	return clamp(0.5 + 0.5 * total / amplitude_sum, 0.0, 1.0);
}

vec3 noise_color(vec3 p) {
	// Red is also the scalar Factor. Green/blue use decorrelated samples.
	// These offsets, like the lattice hash, do not match Blender's seeds.
	return vec3(
		normalized_fbm(p),
		normalized_fbm(p + vec3(19.19, 73.73, 41.41)),
		normalized_fbm(p + vec3(47.47, 11.11, 97.97))
	);
}

float ramp_factor(float value, float start, float end) {
	return clamp((value - start) / max(end - start, 0.00001), 0.0, 1.0);
}

float roughness_ramp(float value) {
	if (value < rough_mid) {
		return mix(rough_low_value, rough_mid_value,
			ramp_factor(value, rough_start, rough_mid));
	}
	return mix(rough_mid_value, rough_high_value,
		ramp_factor(value, rough_mid, rough_end));
}

void vertex() {
	// VERTEX is already in local mesh coordinates in the vertex stage.
	local_position = VERTEX;
}

void fragment() {
	vec3 p = local_position * texture_scale + texture_offset;
	vec3 fine = noise_color(p * fine_scale);
	vec3 coarse = noise_color(p * coarse_scale);
	float fine_color_factor = dot(fine, luminance_weights);
	float coarse_color_factor = dot(coarse, luminance_weights);

	vec3 color_a = mix(fine_dark.rgb, fine_light.rgb,
		ramp_factor(fine_color_factor, fine_start, fine_end));
	vec3 color_b = mix(coarse_dark.rgb, coarse_light.rgb,
		ramp_factor(coarse_color_factor, coarse_start, coarse_end));

	ALBEDO = mix(color_a, color_b, clamp(color_mix, 0.0, 1.0));
	METALLIC = metallic;
	ROUGHNESS = clamp(roughness_ramp(fine.r), 0.0, 1.0);
	SPECULAR = specular;
	// Leave ALPHA unwritten: the graph is opaque, and writing it in Godot
	// would unnecessarily move this material into the transparent pipeline.
}
