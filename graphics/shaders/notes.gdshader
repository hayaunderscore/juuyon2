shader_type canvas_item;

const int DATA_ROW = 256;
const int DATA_PART = 4;

uniform sampler2D atlas : filter_nearest, repeat_disable;
uniform sampler2D note_data : filter_nearest, repeat_disable;

uniform float t;
uniform float lane_width = 795;

varying flat vec4 rect;

void vertex() {
	ivec2 data_loc = ivec2((INSTANCE_ID % DATA_ROW) * DATA_PART, INSTANCE_ID / DATA_ROW);
	vec4 timing_data = texelFetch(note_data, data_loc, 0);
	vec4 player_data = INSTANCE_CUSTOM;
	rect = texelFetch(note_data, data_loc + ivec2(1, 0), 0);
	
	// scroll * (lane_width / 4) * (bpm / 60)
	vec2 vel = vec2(timing_data.x * (lane_width * 0.25) * (timing_data.w / 60.0), timing_data.y * (lane_width * 0.25) * (timing_data.w / 60.0));
	float ms = timing_data.z;
	
	if (player_data.x == 1.0) {
		VERTEX = vec2(1e9);
	} else {
		VERTEX = VERTEX * rect.zw + (vel * (ms - t));
	}
}

void fragment() {
	vec2 px = rect.xy + UV * rect.zw;
	COLOR = texture(atlas, px / vec2(textureSize(atlas, 0)));
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
