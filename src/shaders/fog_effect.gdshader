shader_type canvas_item;

uniform sampler2D noise_texture: repeat_enable, filter_nearest;
uniform float density: hint_range(0.0, 1.0) = 0.25;
uniform vec2 speed = vec2(0.2, 0.1);
uniform float particle_size = 1.0;

uniform float contrast = 1.5; // Controls fog sharpness
uniform float brightness = 1.0; // Controls overall fog density

void fragment() {
	// Scale UV based on resolution to make particles appropriately sized
    vec2 scaled_uv = UV * vec2(1.0, 1.0) * particle_size;

    // Animate the fog
    vec2 uv = scaled_uv + speed * TIME * 0.1;

	//vec2 uv = UV * speed * TIME;

	//float noise = texture(noise_texture, -UV).r;
	float noise = texture(noise_texture, uv).r;
    //noise += texture(noise_texture, uv * 2.0 + vec2(TIME * 0.3)).r * 0.5;
    //noise += texture(noise_texture, uv * 4.0 - vec2(TIME * 0.1)).r * 0.25;
    //noise /= 1.75; // Normalize
	//float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);

	// Adjust contrast and brightness
    noise = pow(noise, contrast);
    noise *= brightness;

    // Apply density
    float fog = clamp(noise * density, 0.0, 1.0);

	COLOR.a *= fog;
}
