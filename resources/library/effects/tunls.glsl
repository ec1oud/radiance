#property description a square tunnel
#property frequency 1

// from https://en.wikipedia.org/wiki/Shadertoy

void main( )
{
    // get back to default OpenGL coordinates
    vec2 p = uv * 2. - vec2(1., 1.);

    // angle of each pixel to the center of the screen
    float a = atan(p.y,p.x);

    // modified distance metric
    float r = pow( pow(p.x*p.x,4.0) + pow(p.y*p.y,4.0), 1.0/8.0 );

    // index texture by (animated inverse) radious and angle
    vec2 q = vec2( 1.0/r + 0.2*iTime* iFrequency, a );

    // pattern: cosines
    float f = cos(12.0*q.x)*cos(6.0*q.y);

    // color fetch: palette
    vec4 col = 0.5 + 0.5*sin( 3.1416*f + iAudio * 3. );

    // lighting: darken at the center
    col = col*r;

    // output: pixel color
	fragColor = composite(texture(iInput, uv), col * iIntensity);
}
