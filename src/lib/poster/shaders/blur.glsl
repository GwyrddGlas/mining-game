extern float blurAmount;
extern vec2 direction;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 texelSize = 1.0 / love_ScreenSize.xy;
    vec4 sum = vec4(0.0);

    sum += texture2D(texture, texture_coords - 4.0 * blurAmount * texelSize * direction) * 0.05;
    sum += texture2D(texture, texture_coords - 3.0 * blurAmount * texelSize * direction) * 0.09;
    sum += texture2D(texture, texture_coords - 2.0 * blurAmount * texelSize * direction) * 0.12;
    sum += texture2D(texture, texture_coords - 1.0 * blurAmount * texelSize * direction) * 0.15;
    sum += texture2D(texture, texture_coords) * 0.18;
    sum += texture2D(texture, texture_coords + 1.0 * blurAmount * texelSize * direction) * 0.15;
    sum += texture2D(texture, texture_coords + 2.0 * blurAmount * texelSize * direction) * 0.12;
    sum += texture2D(texture, texture_coords + 3.0 * blurAmount * texelSize * direction) * 0.09;
    sum += texture2D(texture, texture_coords + 4.0 * blurAmount * texelSize * direction) * 0.05;

    return sum * color;
}