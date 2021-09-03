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







// credits: Dave_Hoskins Hash functions: https://www.shadertoy.com/view/4djSRW

const float PI = 3.141592654;

vec3 hash32(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec4 hash42(vec2 p) {
  vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
  p4 += dot(p4, p4.wzxy + 33.33);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}


// returns { RGB, dist to edge (0 = edge, 1 = center) }
vec4 disco(vec2 uv) {
    float v = abs(cos(uv.x * PI * 2.) + cos(uv.y *PI * 2.)) * .5;
    uv.x -= .5;
    vec3 cid2 = hash32(vec2(floor(uv.x - uv.y), floor(uv.x + uv.y))); // generate a color
    return vec4(cid2, v);
}

mat2 rot2D(float r) { return mat2(cos(r), sin(r), -sin(r), cos(r)); }

void mainImage( out vec4 o, in vec2 fragCoord)
{
    vec2 R = iResolution.xy;
    vec2 uv = fragCoord / max(R.x,R.y);

  vec4 hscene = hash42(vec2(sceneCell / 500.));

    float t = iTime * mix(.3,.6, hscene.x); //t = 0.;
    uv *= mix(2.,19., hscene.z);
    uv -= vec2(t*.5, -t*.3);
    
        uv -= hscene.zw;// offset rotation origin
    float rotation = -(iTime+40.)*mix(0.005,0.02,hscene.x) * sign(hscene.y - .5);
    //uv += iMouse.xy *.1 / iResolution.xy;
    uv *= rot2D(rotation);// rot

    o = vec4(1);
    float s = 1.;
    for(float i = 1.; i <= 4.; ++i) {
        uv /= i*.9;
        vec4 d = disco(uv);
        float curv = pow(d.a, .44-((1./i)*.3));
        curv = pow(curv, .8+(d.b * 2.));
        o *= clamp(d * curv,.35, 1.);
        uv += t*(i+.3)*s*hscene.y*3.;
        s = -s;
    }
    
    // post
    o = clamp(o,.0,1.);
    vec2 N = (fragCoord / R )- .5;
    o = 1.-pow(1.-o, vec4(30.));// curve
    o.rgb += (hash32(fragCoord + iTime).r-.5)*.1;//noise
    o *= hscene;
    o *= 1.1-smoothstep(.4,.402,abs(N.y));
    o *= 1.0-dot(N,N*1.7);// vingette
    o.a = 1.;
}






void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
