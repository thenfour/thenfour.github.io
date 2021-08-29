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

const float lineThickness = 4.;
const float PARTITIONS = 14.;


vec4 hash42(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void mainImage( out vec4 o, in vec2 fragCoord )
{
    float t = (iTime+1e2)*.4;
    vec2 uv = fragCoord/iResolution.xy-.5;
    vec2 N = uv;
    vec2 R = iResolution.xy;
    uv.x *= R.x / R.y;
    uv.x += t*.1;
    uv.y += sin(t*.6)*.3;
    uv.y -= .5;
    uv.x += sceneCell;
    vec4 hscene = hash42(vec2(sceneCell/500.));
    
    vec2 cellUL = floor(uv);
    vec2 cellBR = cellUL + 1.;
    vec2 seed = cellUL;
    o = mix(vec4(1), hscene, hscene.w*.5);
    for(float i = 1.; i <= PARTITIONS; ++ i) {
        vec4 h = hash42(seed+1e2*(vec2(cellBR.x, cellUL.y)+10.));
        vec2 test = abs(cellUL - cellBR);
        vec2 uv2 = uv;
        float dl = abs(uv2.x - cellUL.x);
        dl = min(dl, length(uv2.y - cellUL.y));
        dl = min(dl, length(uv2.x - cellBR.x));
        dl = min(dl, length(uv2.y - cellBR.y));

        vec3 col = h.rgb;
        o.rgb *= smoothstep(0.,.00001,dl-lineThickness/max(R.x,R.y));
        if (h.w < .2)
            o.rgb *= mix(col, vec3(col.r+col.g+col.b)/3.,.6);
        vec2 pt = mix(cellUL, cellBR, h.y);

        vec2 p2 = pt - uv;
        float r = max(fract(p2.x-.5), fract(.5-p2.x));
        r = max(r, fract(.5-p2.y));
        r = max(r, fract(p2.y-.5));
        r = 1.-r;
        vec2 sz = cellBR - cellUL;
        if (pow(sz.x * sz.y, .1) < r * 1.5) {
            break;
        }
        vec2 thresh = sin(t*2.*h.xy)*.5+.5;
        thresh *= h.zw*.3;
        if (sz.x < thresh.x || sz.y < thresh.y)
            break;
        
        if (uv2.x < pt.x) {// descend into quadrant.
            if (uv2.y < pt.y) {
                cellBR = pt.xy;
            } else {
              	cellUL.y = pt.y;
              	cellBR.x = pt.x;
            }
        } else {
            if (uv2.y > pt.y) {
                cellUL = pt.xy;
            } else {
                cellUL.x = pt.x;
                cellBR.y = pt.y;
            }
	    }
    }
    
    o = clamp(o,0.,1.);
    o = pow(o,o-o+.4);
    o.rgb -= hash42(fragCoord + iTime).r*.15;

    o *= 1.-dot(N,N*1.5);
}



void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
