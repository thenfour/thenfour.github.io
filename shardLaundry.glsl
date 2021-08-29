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

// const float SceneDurationSeconds = 3.;
const float Complexity = 12.;
const float ResolutionDivisor = 1.;

// see https://glslsandbox.com/e#39159.0
// there's not much way to make it 100% reliable and uniform, but scaling back the inputs can help.
vec4 hash42(vec2 p) {
  vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
  p4 += dot(p4, p4.wzxy + 19.19);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

mat2 rot2D(float r) { return mat2(cos(r), sin(r), -sin(r), cos(r)); }

float bayer8x8(vec2 uvScreenSpace) {
  return texture(iChannel0, uvScreenSpace / (ResolutionDivisor * 8.)).r;
}

void mainImage(out vec4 o, vec2 C) {
  vec2 uv = C / iResolution.xx;
  //uv += iMouse.xy/iResolution.xy*.1 - .5;
  uv += 100.; // seed @ 0 is just black because of rng
  float q = 1.;
  vec4 h;
  float sh = 1.0;

  float scene = sceneCell / 5000.; // floor((iTime + 100.) / SceneDurationSeconds);
  vec4 hscene = hash42(uv - uv + scene);
  uv.x += scene;
  vec2 escape = 1. - hscene.xy * .12;
  float Speed = hscene.z * .01;

  for (float i = 0.0; i < Complexity; ++i) {
    vec2 cell = floor(uv / q) * q;
    vec2 sq = abs(fract(uv / q));
    sh *= 1. - pow(max(sq.y, max(max(1. - sq.y, sq.x), 1. - sq.x)), 3.5);
    h = hash42(cell);
    if (i > 3. && h.w > escape[int(i) % 2])
      break;
    uv.x += iTime * sin(h.z * 6.28) * Speed * (i + 1.);
    uv *= rot2D(h.w * 6.28 * hscene.z);
    uv *= 1.2 +
          hscene.y *
              h.y; // scale; there's a small chance of under layer being bigger.
  }
  o = h * pow(sh, .25);
  //o = pow(o, vec4(.6));
  vec2 uvn = C / iResolution.xy - .5;
  float v = 1. - dot(uvn, uvn * 1.6);
  o *= v;
  o *= Complexity / 12.; // it's just really dark otherwise

  vec4 rotated = o;
  rotated.xy *= rot2D(iTime * .4);
  rotated.yz *= rot2D(iTime * .4 * .618);
  rotated = abs(rotated);
  rotated = clamp(rotated, 0., 1.);
  o = mix(o, rotated, .3);
  o = abs(o);
  o = clamp(o, 0., 1.);
  o = mix(o, o - o + (max(o.x, max(o.y, o.z))), .5);

  o += (bayer8x8(C) - .5) * .15;
  o = step(o - o + .13, o);
}

void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
