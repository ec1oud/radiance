#property description walker-like dancers
#property frequency 1

// Created by c.Kleinhuis - VJSpackOMat/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://www.facebook.com/VJSpackOMat
// http://www.fractalforums.com
// https://www.shadertoy.com/view/MsBSzW
#define PI 3.14159265359
#define PI2 PI*2.0

vec2 cosey(float t)
{
	t=mod(t,PI2);
	return vec2(0,-clamp(cos(t),0.0,1.0));
}

float circle(vec2 center,float radius)
{
	float result=1.0;
	float l=length(center);
	l-=radius;
	if (l>radius) result=0.0;
	return result;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
	vec3 pa = p - a, ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float sdCapsule( vec2 p, vec2 a, vec2 b, float r )
{
	vec2 pa = p - a, ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float capsule( vec2 p, vec2 a, vec2 b, float r )
{
	if(sdCapsule(p,a,b,r)<0.0)return 1.0;
	return 0.0;
}

float cos3Big(float t)
{
	return (cos(t)+cos(t*2.0)*0.5+cos(PI/4.0+t*4.0)*0.25)/3.0;
}

float circleHalve(vec2 center,float radius)
{
	float result=1.0;
	float l=length(center);
	l-=radius;
	if(center.y<0.0)result=0.0;
	if(l>radius)result=0.0;
	return result;
}

float walkingDude(vec2 uv,float time)
{
	float val=0.0;
	float floorHeight= (-0.5 );
	time=time+floor((uv.x+1.5)/3.0-1.5) *112.00;
	uv.x=mod(uv.x,3.0)-1.5;

	//body
	vec2 bodyPos=vec2(0.0,sin(time*8.0)*.15+.55-floorHeight);
	val+=circle((uv-bodyPos)*vec2(1.25,1.0),.2);

	vec2 headPos=bodyPos+vec2(cos3Big(time)*0.2,0.4+cos3Big(time*1.12)*0.2);
	val+=circle(uv-headPos,.1);

	vec2 footDist=vec2(0.35,0);
	vec2 footLeft=footDist+cosey(PI/2.0+time*4.0+PI)*0.4;
	float footLeftRadius=cos(time*4.0+PI)*0.05+0.15;
	val+=circleHalve(uv+footLeft,footLeftRadius);

	footDist=vec2(-0.35,0.0);
	vec2 footRightPos=footDist+cosey(PI/2.0+time*4.0)*0.4 ;
	val+=circleHalve(uv+footRightPos,cos(time*4.0)*0.05+0.15);

	val+=capsule(uv,bodyPos,-footRightPos+vec2(0,0.1),0.1);

	val+=capsule(uv,bodyPos,-footLeft+vec2(0,0.1),0.1);

	vec2 handDist=bodyPos+vec2(-0.6,-2.25);
	vec2 handLeft=handDist+vec2(-cos3Big(PI/2.0+time*1.3+PI)*0.2,cos3Big(PI/2.0+time*1.11+PI)*0.25);
	float handLeftRadius=0.05;
	val+=circle(uv+handLeft,handLeftRadius);
	val+=capsule(uv,bodyPos+vec2(0,0.2),-handLeft ,0.05);

	handDist=bodyPos+vec2(0.6,-2.25);;
	vec2 handRight=handDist+vec2(cos3Big(PI/2.0+time*1.3+PI)*0.2,cos3Big(PI/2.0+time*1.11+PI)*0.25);
	float handRightRadius=0.05;
	val+=circle(uv+handRight,handLeftRadius);
	val+=capsule(uv,bodyPos+vec2(0,0.2),-handRight ,0.05);

	val=clamp(val,0.0,1.0);

	return val;
}

float walkingDudeScaled(vec2 uv,float time,float scale)
{
	return walkingDude(uv*scale+vec2(0,scale),time);
}

void main( void )
{
	float val=0.0;
	vec2 p = uv;
	float t = iTime * iFrequency;

	p.x+=t * 0.5;
	p.y -= 1.;
	val=walkingDudeScaled(p,t * iFrequency,1.0)* 0.5;
	p.x=uv.x+t*-.25;
	val+=max(val,walkingDudeScaled(p+vec2(-1.0,0.0),345.0+t*1.0,2.0)*0.25);
	val+=walkingDudeScaled(p+vec2(1,0),2314+t*1,2)*0.35;
	p.x=uv.x+t*.125;
	val+=walkingDudeScaled(p+vec2(-1.5,0),7655+t,4)*0.15;

	vec4 color=vec4(0.,0.,1.0,1.0) * val;

	fragColor = composite(texture(iInput, uv), color * iIntensity);
}
