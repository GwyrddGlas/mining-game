#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
    #define MY_HIGHP_OR_MEDIUMP highp
#else
    #define MY_HIGHP_OR_MEDIUMP mediump
#endif

extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP vec4 colour_1;
extern MY_HIGHP_OR_MEDIUMP vec4 colour_2;
extern MY_HIGHP_OR_MEDIUMP vec4 colour_3;
extern MY_HIGHP_OR_MEDIUMP number contrast;

#define PIXEL_SIZE_FAC 600.
#define WAVE_SPEED 0.6
#define DISTORTION_AMOUNT 0.5

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    MY_HIGHP_OR_MEDIUMP number pixel_size = length(love_ScreenSize.xy) / PIXEL_SIZE_FAC;
    MY_HIGHP_OR_MEDIUMP vec2 uv = (floor(screen_coords.xy * (1. / pixel_size)) * pixel_size - 0.5 * love_ScreenSize.xy) / length(love_ScreenSize.xy);
    
    // Apply a subtle shifting wave effect
    MY_HIGHP_OR_MEDIUMP number wave = sin(uv.x * 5.0 + time * WAVE_SPEED) * cos(uv.y * 5.0 - time * WAVE_SPEED);
    uv.x += wave * DISTORTION_AMOUNT;
    uv.y -= wave * DISTORTION_AMOUNT;
    
    // Abstract paint effect
    uv *= 25.;
    MY_HIGHP_OR_MEDIUMP vec2 uv2 = uv;
    
    for(int i = 0; i < 4; i++) {
        uv2 += sin(uv * 1.1) + cos(uv.yx * 0.9);
        uv  += 0.4 * vec2(cos(uv2.y + time * 0.2), sin(uv2.x - time * 0.1));
        uv  -= 0.6 * cos(uv2.x - uv2.y) - 0.3 * sin(uv2.x * 0.5 + uv2.y);
    }
    
    MY_HIGHP_OR_MEDIUMP number paint_res = min(2., max(0., length(uv) * 0.04 * contrast));
    MY_HIGHP_OR_MEDIUMP number c1p = max(0., 1. - contrast * abs(1. - paint_res));
    MY_HIGHP_OR_MEDIUMP number c2p = max(0., 1. - contrast * abs(paint_res));
    MY_HIGHP_OR_MEDIUMP number c3p = 1. - min(1., c1p + c2p);
    
    MY_HIGHP_OR_MEDIUMP vec4 ret_col = (0.3 / contrast) * colour_1 + 
        (1. - 0.3 / contrast) * (colour_1 * c1p + colour_2 * c2p + vec4(c3p * colour_3.rgb, c3p * colour_1.a));
    
    return ret_col;
}
