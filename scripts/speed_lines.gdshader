shader_type canvas_item;

uniform float line_count : hint_range(10.0, 100.0) = 30.0;
uniform float speed : hint_range(1.0, 20.0) = 10.0;
uniform float line_width : hint_range(0.001, 0.05) = 0.01;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 0.8, 0.8);

void fragment() {
	// Use UV coordinates (0-1 range)
	vec2 uv = UV;
	vec2 center = vec2(0.5, 0.5);

	// Adjust for aspect ratio to keep effect circular
	vec2 aspect_corrected = uv - center;
	aspect_corrected.x *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;

	// Calculate distance and direction
	float dist = length(aspect_corrected);
	vec2 norm_dir = normalize(aspect_corrected);

	// Create radial lines
	float angle = atan(norm_dir.y, norm_dir.x);
	float line = sin(angle * line_count + TIME * speed) * 0.5 + 0.5;

	// Make lines fade out near center and edges
	// Adjusted distance ranges to work with aspect-corrected coordinates
	float fade = smoothstep(0.0, 0.15, dist) * smoothstep(0.8, 0.5, dist);

	// Create sharp lines
	line = step(1.0 - line_width, line);

	// Apply color and fade
	COLOR = line_color * line * fade;
}
