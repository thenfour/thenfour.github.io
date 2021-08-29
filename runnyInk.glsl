precision lowp float;
//out vec4 fragColor;
#define fragColor gl_FragColor
uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iMouse;
uniform float sceneCell;
uniform vec4 iSceneHash;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

const float PI = 3.141592654;

// see https://glslsandbox.com/e#39159.0
// there's not much way to make it 100% reliable and uniform, but scaling back the inputs can help.
vec4 hash42(vec2 p) {
  vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
  p4 += dot(p4, p4.wzxy + 19.19);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

vec3 hash32(vec2 p){
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec4 disco(vec2 uv) {
    float v = abs(cos(uv.x * PI * 2.) + cos(uv.y *PI * 2.)) * .5;
    uv.x -= .5;
    vec3 cid2 = hash32(vec2(floor(uv.x - uv.y), floor(uv.x + uv.y)));
    return vec4(cid2, v);
}

float nsin(float t) {return sin(t)*.5+.5; }

void mainImage( out vec4 o, in vec2 fragCoord)
{
    vec2 R = iResolution.xy;
    vec2 uv = fragCoord / R - .5;
    uv.x *= R.x / R.y;

    vec4 hscene = hash42(vec2(sceneCell));

    float t = (iTime + 129.) * .6; //t = 0.;
    uv = uv.yx;
    uv *= mix(1.5, 3.0, hscene.w)+sin(t)*.2;
    uv.x += t*hscene.x;
    //uv.yx += iMouse.xy *.1 / iResolution.xy;
    
    o = vec4(1);
    float sgn = -1.;
    for(float i = 1.; i <= 5.; ++i) {
        vec4 d = disco(uv);
        float curv = pow(d.a, .5-((1./i)*.3));
        curv = pow(curv, .8+(d.b * 2.));
        curv = smoothstep(nsin(t)*.3+.2,.8,curv);
        o += sgn * d * curv;
        o *= d.a;
        sgn = -sgn;
        uv += 100.;// move to a different cell
        uv += sin(d.ar*7.33+t*1.77)*(nsin(t*.7)*.1+.04);
    }
    
    // post
   	o.gb *= vec2(1.,.5) * hscene.z;//tint
    vec2 N = (fragCoord / R )- .5;
    o = clamp(o,.0,1.);
    o = pow(o, vec4(.2));
    o.rgb -= hash32(fragCoord + iTime).r*(1./255.);
    
    N = pow(abs(N), vec2(2.5));
    N *= 7.;
    o *= 1.5-length(N);// ving
    o = clamp(o,.0,1.);
    o.a = 1.;
}



void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
