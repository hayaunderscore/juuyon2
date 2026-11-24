shader_type canvas_item;

const int DATA_ROW = 256;
const int DATA_PART = 4;

uniform sampler2D atlas : filter_nearest, repeat_disable;
uniform sampler2D note_data : filter_nearest, repeat_disable;
uniform sampler2D branch_data : filter_nearest, repeat_disable;

uniform float t;
uniform float lane_width = 795;

varying flat vec4 rect;

void vertex() {
	ivec2 data_loc = ivec2((INSTANCE_ID % DATA_ROW) * DATA_PART, INSTANCE_ID / DATA_ROW);
	vec4 timing_data = texelFetch(note_data, data_loc, 0);
	vec4 player_data = INSTANCE_CUSTOM;
	vec4 misc_note_data = texelFetch(note_data, data_loc + ivec2(2, 0), 0);
	vec4 roll_tail_timing_data = texelFetch(note_data, data_loc + ivec2(3, 0), 0);
	
	ivec2 branch_data_loc = ivec2((INSTANCE_ID % DATA_ROW), INSTANCE_ID / DATA_ROW);
	vec4 note_branch_data = texelFetch(branch_data, branch_data_loc, 0);
	
	rect = texelFetch(note_data, data_loc + ivec2(1, 0), 0);
	
	// scroll * (lane_width / 4) * (bpm / 60)
	vec2 vel = vec2(timing_data.x * (lane_width * 0.25) * (timing_data.w / 60.0), timing_data.y * (lane_width * 0.25) * (timing_data.w / 60.0));
	float ms = timing_data.z;
	int note_type = int(floor(misc_note_data.x));
	int other_note_type = int(floor(misc_note_data.y));
	
	if (player_data.x == 1.0 || (misc_note_data.z > 0.0 && t >= misc_note_data.z && (note_type == 7 || other_note_type == 7))) {
		VERTEX = vec2(1e9);
	} else if (note_branch_data.x > -1.0 && !(int(note_branch_data.x) == int(player_data.y) && int(note_branch_data.y) == int(player_data.z))) {
		VERTEX = vec2(1e9);
	} else {
		// This is a roll body, handle things differently
		if (note_type == 1003) {
			vec2 tail_vel = roll_tail_timing_data.xy * (lane_width * 0.25) * (roll_tail_timing_data.w / 60.0);
			float tail_ms = roll_tail_timing_data.z;
			
			vec2 head = (vel * (ms - t));
			vec2 tail = (tail_vel * (tail_ms - t));
			
			vec2 dir = tail - head;
			float len = length(dir);
			if (len < 0.001) {
				VERTEX = head;
			} else {
				vec2 u = dir / len;
				if (u.x < -0.0001) u = -u;
				vec2 p = vec2(-u.y, u.x);
				VERTEX = (head + tail) * 0.5 + u * (VERTEX.x * len) + p * (VERTEX.y * rect.w);
			}
		} else if (note_type == 8) { // Roll tails are adjusted
			if (other_note_type == 7) { // Just move this to the note head
				// roll_tail is actually roll_head here lmao
				vel = roll_tail_timing_data.xy * (lane_width * 0.25) * (roll_tail_timing_data.w / 60.0);
				ms = roll_tail_timing_data.z;
				vec2 pos = (vel * (ms - (t >= ms ? min(t, ms) : t)));
				VERTEX = VERTEX * rect.zw + pos;
				VERTEX.x += rect.z;
			} else {
				VERTEX = VERTEX * rect.zw + (vel * (ms - t));
				VERTEX.x += rect.z / 2.0; // TODO: Flip this when needed
			}
		} else {
			float th = t;
			if (note_type == 7) {
				th = (t >= ms ? min(t, ms) : t);
			}
			vec2 pos = (vel * (ms - th));
			VERTEX = VERTEX * rect.zw + pos;
		}
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
