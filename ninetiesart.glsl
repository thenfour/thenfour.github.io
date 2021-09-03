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






//const float SceneDurationSeconds = 3.;
const float Complexity = 12.;

vec4 hash42(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

float bayer8x8(vec2 uvScreenSpace) {
  return texture2D(iChannel0, uvScreenSpace / 8.).r;
}

void mainImage(out vec4 o, vec2 C) {
  vec2 uv = C / iResolution.x;

  vec2 N = C / iResolution.xy-.5;
  float SD = clamp(1.-2.*length(N),0.,1.); // radial distance
  N = abs(N);
  float SQ = 1.-2.*max(N.x,N.y); // rectangular distance
  
  uv += 100.;
  vec4 h;
  float sh = 1.0;
  
  float t = iTime * .5;

  float scene = sceneCell;// floor(iTime / SceneDurationSeconds) + 100.;
  vec4 hscene = hash42(uv - uv + scene / 5000.);
  uv.x += scene;

  for (float i = 1.0; i < Complexity; ++i) {
    vec2 cell = floor(uv);
    vec2 sq = fract(uv);
    sh *= 1. - pow(max(sq.y, max(max(1. - sq.y, .5+.5*h.z), 1. - sq.x)), 4.);
    h = hash42(cell);
    uv.x += mix(3., 6., sin((hscene.w-.5)*t*.3)*.5+.5) * sin(h.z * 6.28) * mix(SD,SQ,.5+.5*h.x)/i;//(i + 1. + SD);
    uv *= rot2D(h.w * 6.28 * hscene.z);
    uv *= 1.-h.z*.1;
  }
  o = h * sqrt(sh);
  vec4 rotated = o;
  rotated.xy *= rot2D(t * 1.5 + hscene.x * 6.2);
  rotated.yz *= rot2D(t * 2.62 + hscene.y * 6.2);
  rotated = clamp(rotated, 0., 1.);
  o *= 100.; // lol
  o = clamp(mix(o, rotated, .3), 0., 1.);

  float v = 1. - dot(N, N * 1.5);
  o += (bayer8x8(C) - .5) * .15*v;
  o = mix(o, step(.09, o), .7);
  o *= v;
}




void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
