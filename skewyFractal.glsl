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

vec4 hash42(vec2 p) {
  vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
  p4 += dot(p4, p4.wzxy + 33.33);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

mat2 rot2D(float r) { return mat2(cos(r), sin(r), -sin(r), cos(r)); }

void mainImage(out vec4 o, vec2 C) {
  vec2 uv = C / iResolution.xx + 100.;
    uv += iMouse.xy/iResolution.xy*.1 - .5;
  float sh = 1.0;
  float t = (iTime - 9.) * .06 + sceneCell / 500.;
  vec4 hscene = hash42(vec2(sceneCell / 500.));
  uv *= mix(3.,6.,hscene.z);
  uv *= rot2D(floor(hscene.w*4.)/8.*6.28);
  o = vec4(0);
  for (float i = 0.; i < 24.; ++i) {
    vec4 h = hash42(floor(uv));
    vec2 sh2 = min(fract(uv), 1. - fract(uv));
    sh = min(sh2.x, sh2.y);
    o += h * sh; // accumulate color

    vec2 uv2 = uv.yx - .5; // centered uv
    uv2 -= (t + t) / (hscene.z > .5 ? ((i+1.)*hscene.z) : 1.);
    uv += (fract(uv2) - .5) * (fract(uv2) - .5)*mix(.5,1.0,hscene.y); // skew in 2d
    uv += t;
  }

  o = (sin(o * 2.) * .5 + .5) * sqrt(sh);
  o = mix(o,vec4(o.r+o.g+o.b)/3.,hscene.x);

  // post
  vec2 uvn = C / iResolution.xy - .5;
  o = clamp(o, 0., 1.);
  o = sqrt(o);
  o *= 1. - dot(uvn, uvn * 1.9); // vignette
}

void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
