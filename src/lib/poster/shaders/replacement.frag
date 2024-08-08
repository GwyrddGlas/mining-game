extern vec4 targetColor;  // The color to replace
extern vec4 replacementColor;  // The color to use as replacement
extern float tolerance;  // The tolerance for color replacement

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    
    // Check if the pixel color is within the tolerance range of the target color
    if (distance(pixel.rgb, targetColor.rgb) < tolerance) {
        return replacementColor * pixel.a;  // Use replacement color, preserving alpha
    } else {
        return pixel * color;  // Return original color
    }
}