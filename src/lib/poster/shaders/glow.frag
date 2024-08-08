// glow.glsl
extern vec2 resolution;
extern number time;
extern Image oreTexture;
extern vec4 glowColor;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texColor = Texel(texture, texture_coords);
    vec2 uv = screen_coords / resolution;
    vec2 offset = vec2(0.01, 0.01);

    // Apply a simple glow effect
    vec4 glow = glowColor * (1.0 - length(offset));
    vec4 finalColor = texColor + glow;

    return finalColor;
}