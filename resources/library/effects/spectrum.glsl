#property description spectrum analyzer waveform

void main(void) {
	float amplitude = texture(iSpectrum, uv.x).r * iIntensity;
	float aaWidth = 0.04  * iIntensity;
	vec4 fill = vec4(0., 0.5, 0., 0.5) * smoothstep(uv.y - aaWidth, uv.y + aaWidth, amplitude);
	vec4 peak = vec4(0., 1., 1., 1.) * smoothstep(-aaWidth, 0., uv.y - amplitude) * smoothstep(0., aaWidth, amplitude - uv.y) * 2.;
	fragColor = composite(texture(iInput, uv), fill + peak);
}
