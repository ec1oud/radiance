#property description disco dancefloor
#property frequency 1

// adapted from https://www.shadertoy.com/view/lsBXDW

void main () {
	float t = iTime * iFrequency;
	vec2 frag = uv.xy * vec2(16.0, 9.0);
	float random = rand (floor (frag));
	vec2 black = smoothstep (1.0, 0.8, cos (frag * 3.14159 * 2.0));
	vec3 color = hsv2rgb (vec3 (random, 1., 0.25 + iAudioLow));
	color *= black.x * black.y * smoothstep (1.0, 0.0, length (fract (frag) - 0.5));
	color *= 0.5 + 0.5 * cos (random + random * t + t + 3.14159 * 0.5);
	fragColor = composite(texture(iInput, uv), vec4(color.xyz, 1.) * iIntensity);
}
