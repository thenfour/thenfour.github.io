#version 300 es
precision lowp float;
out vec4 fragColor;
uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iMouse;
uniform float sceneCell;
uniform vec4 iSceneHash;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;


//const float SceneDurationSeconds = 5.;
const int Complexity = 24;

vec4 hash42(vec2 p)
{
  vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

void mainImage(out vec4 o, vec2 C)
{
    vec2 uv = C/max(iResolution.x,iResolution.y)*4.+100.;
    uv += iMouse.xy/iResolution.xy*.2 - .5;
    uv *= .8;
    o = vec4(0);
    //float sceneCell = (iTime+100.)/SceneDurationSeconds;
    float scene = floor(sceneCell);
    float sceneP01 = fract(sceneCell);
    vec4 hscene = hash42(vec2(scene));
    float t = iTime*.15*(.1+hscene.y);
    uv.x += scene;
    uv *= rot2D(hscene.z*6.28);
    for (int i = 0;i<Complexity;++i) {
        vec4 h = hash42(floor(uv-t)); // random per cell
        vec2 uv2 = uv+t*sign(hscene.w-.5);
        uv[i%2] += abs(fract(uv2[(i+1)&1])-.5)*mix(.15,.7, hscene.w)*sign(hscene.z-.5); // skew
        vec2 sh = min(1.-fract(uv+t),fract(uv-t*.62)); // distance to box
        float sd = min(sh.x,sh.y);
        float a = smoothstep(.1+hscene.w*.1,.11+hscene.w*.1,sd);
        o = mix(o,h,sd)*a;
    }
    C = C/iResolution.xy-.5;
    // post
    o = sqrt(o*hscene);
    o = clamp(o,0.,1.);
    //o = mix(hscene,o,smoothstep(.0,.1/SceneDurationSeconds,sceneP01)); // shutter
    o *= 1.-dot(C,C*1.5);
}










void main() {
    vec4 o;
    mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
  //fragColor =      vec4(fract((gl_FragCoord.xyy - iMouse.xyy) / iResolution.xyy), 1);
  //fragColor = vec4(gl_FragCoord.xyy / iResolution.xyy, 1);
}


