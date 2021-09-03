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





const float PARTITIONS = 14.;

vec3 dtoa(float d, vec3 amount){
    return vec3(1. / clamp(d*amount, vec3(1), amount));
}

vec4 hash42(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}
void mainImage( out vec4 o, in vec2 fragCoord )
{
    vec2 uv = fragCoord/max(iResolution.y,iResolution.x)-.5;
    vec2 N = fragCoord/iResolution-.5;

    vec2 seed = vec2(sceneCell / 5000.);//floor(uv);// cell ID
    vec4 hscene = hash42(seed);
    float t = (iTime+1e2)*mix(.05,.3,hscene.y);

    if (hscene.x > .5) {
      uv.x += t*.2*sign(hscene.y - .5);
    } else {
      uv.y += t*.2*sign(hscene.y - .5);
    }
    //vec2 R = iResolution.xy;
    //uv.x *= R.x / R.y;
    //uv.y -= .5;
    
    vec2 cellUL = vec2(-1);
    vec2 cellBR = vec2(1);
    uv = fract(uv);
    o = vec4(1);
    N *= mix(.97, .8, hscene.z);// attempt to reduce some artifacting around edges

    float sharpness = mix(1400., 15000., 1.-hscene.w);
    float depth = mix(-0.0004, 0.000, hscene.w);

    for(float i = 1.; i <= PARTITIONS; ++ i) {
        vec4 h = hash42(seed+1e2*(vec2(cellBR.x, cellUL.y)+10.));
        vec2 test = abs(cellUL - cellBR);
        vec2 uv2 = uv;
        float dl = abs(uv2.x - cellUL.x);
        dl = min(dl, length(uv2.y - cellUL.y));
        dl = min(dl, length(uv2.x - cellBR.x));
        dl = min(dl, length(uv2.y - cellBR.y));

        vec3 col = h.rgb;
        col.rb = clamp((col.rg-.5)*rot2D(t*hscene.z*3.*(h.z+i+1.))+.5,0.,1.);
        float r = max(fract(N.x-.5), fract(.5-N.x));
        //r = max(r, fract(.5-N.y));
        //r = max(r, fract(N.y-.5));
        r = 1.-r;
        //vec3 col2 = 1.1-dtoa(dl, (h.z+.05)*vec3(sharpness)*pow(r, 1.5));
        vec3 col2 = 1.1-dtoa(dl+depth,(h.z+.05)*vec3(sharpness)*6.*r*r);
        o.rgb *= col2;
        if (h.w < hscene.x*.6)
            o.rgb *= mix(col, vec3(col.r+col.g+col.b)/3.,.6);
        vec2 pt = mix(cellUL, cellBR, h.y);
        if (uv2.x < pt.x) {// descend into quadrant. is there a more elegant way to do this?
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
    o = pow(o,o-o+.2);
    o.rgb += (hash42(fragCoord + iTime).r-.5)*.2;
    //o *= 1.-dot(N,N);
    o.a = 1.;
}





void main() {
  vec4 o;
  mainImage(o, gl_FragCoord.xy);
  fragColor = vec4(o.rgb, 1);
}
