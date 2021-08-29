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

#define BLUR
const vec2 z = vec2(1, 8);
const ivec2 samples = ivec2(2, 2);
const float complexity = 10.;
const float density = .6; // 0-1
const float sceneswitchspeed = .3;

vec4 hash42(vec2 p) {
  vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
  p4 += dot(p4, p4.wzxy + 33.33);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

#define q(x, p) (floor((x) / (p)) * (p))

vec4 tex(vec2 C) {
  vec2 R = iResolution.xy;
  vec4 o2 = vec4(1);
  vec2 uv = C / R.xy;
  //uv += iMouse.xy/iResolution.xy*.2 - .5;
  float t = iTime+10.;
  vec4 h = hash42(vec2(100. + sceneCell / 100.));// floor(uv) + floor(t * sceneswitchspeed));
  vec4 hscene = hash42(vec2(sceneCell+1.));// floor(uv) + floor(t * sceneswitchspeed));
  uv.y += uv.x * (h.x - .5);
  uv.x *= R.x / R.y;
  uv *= z;
  uv += sceneCell * z *
        h.y; // adding *h.y so vertical seams are not always in the same place
  float s = 1.;

  for (float i = 1.; i <= complexity; ++i) {
    vec2 c = floor(uv + i);
    vec4 h = hash42(c);
    vec2 p = fract(uv + i + q(t, (h.z + complexity) / i) * h.y);
    uv += p * h.z * h.xy * vec2(s, 2.);
    s = -s * (1.1 + h.y);
    if (h.w > density) {
      o2 *= h;
    }
  }
  o2 = step(.5, o2);
  return o2;
}

void mainImage(out vec4 o, vec2 C) {
  vec2 R = iResolution.xy;
  vec4 o2 = vec4(1);
  vec2 uv = C / R.xy;
  vec2 N = uv - .5;
#ifdef BLUR
  o = vec4(0.0);
  float accum = 0.;

  for (int x = -samples.x; x < samples.x; ++x) {
    vec2 offset = vec2(x, 0);
    float weight = abs(float(samples.x) - float(x));
    o += tex(C + offset) * weight;
    accum += weight;
  }
  for (int y = -samples.y; y < samples.y; ++y) {
    vec2 offset = vec2(0, y);
    float weight = abs(float(samples.y) - float(y));
    o += tex(C + offset) * weight;
    accum += weight;
  }
  o /= accum;
#else
  o = tex(C);
#endif

  o = smoothstep(.2, .8, o) * mod(C.x, 3.) / 2.5;
  o = clamp(o, 0., 1.);
  o = pow(o, o - o + .5);
  o *= 1.-dot(N,N*1.5);
}

void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
