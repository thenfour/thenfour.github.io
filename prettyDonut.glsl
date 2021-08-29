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

const float innerh = .17;
const float PI = 3.14159;

vec3 dtoa(vec3  d, float amount){
    vec3 a = clamp(1.0 / (clamp(d, 1.0/amount, 1.0)*amount), 0.,1.);
    return a;
}
mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}
float nsin(float x) { return sin(x)*.5+.5;}

// see https://glslsandbox.com/e#39159.0
// there's not much way to make it 100% reliable and uniform, but scaling back the inputs can help.
vec4 hash42(vec2 p) {
  vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
  p4 += dot(p4, p4.wzxy + 19.19);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

void mainImage( out vec4 O, in vec2 P)
{
    float t = iTime + 100.;
    vec2 R = iResolution.xy;
    P -= R*.5;// center at origin
    vec2 uv = P / R.y;// aspect correct uv

    vec4 hscene = hash42(vec2(sceneCell/500.));
    uv *= mix(.5,.8,hscene.z);
    
    float ang = atan(uv.x, uv.y);
    // find a base height around the circle
    float h = 0.;
    float f = 1.;
    float tot = mix(2.,4.,hscene.w);
    for (float i = 1.; i < 8.; ++ i) {
        h += nsin((ang+f)*i+t*f*.1);// + t*f*(hscene.w*.2));
        f *= -1.37;
    }
    h = h*h;
    
    // find ind height for 3 separate components
    vec3 h3 = h + .1*sin(t*(.1+hscene.rgb) + ang*4.);
    vec3 d3 = length(uv) - innerh - h3*.02; // distance
    d3 += (hscene.x-.2)*.2;
    d3 = max(d3, -(length(uv) - innerh - h3 * .011));// donut
    //d3 = min(d3, length(uv) - h3*0.01); // center

    vec2 shuv = uv+.06;
    vec3 dsh = length(shuv) - innerh - h3*.02; // distance
    dsh = max(dsh, -(length(shuv) - innerh - h3 * .011));// donut
    dsh = min(dsh, length(shuv) - h3*0.01); // center
    vec3 ash = dtoa(dsh, 30.)*.2;

    O = vec4(1);
    O *= 1.-min(ash.r, min(ash.g, ash.b));
    vec3 a3 = dtoa(d3, 30.);
    a3.rg *= rot2D(iTime*.4);
    a3 = clamp(a3,0.,1.);
    O.rgb = mix(O.rgb, a3, a3);
    O.rgb = mix(vec3(O.r+O.g+O.b)/3.,O.rgb,.5);
    vec2 N = P/R;
    O = pow(O, vec4(4.));
    O *= 1.-dot(N,N);
    O += (fract(sin(dot(R+t,N))*1e5)-.5)*.05;
    O.a = 1.;
}



void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
