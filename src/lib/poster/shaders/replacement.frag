extern vec4 targetColor;  // The color to replace
extern vec4 replacementColor;  // The primary replacement color
extern vec4 replacementColor2;  // The secondary replacement color
extern float tolerance;  // The tolerance for color replacement

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);

    // Check if the pixel color is within the tolerance range of the target color
    if (distance(pixel.rgb, targetColor.rgb) < tolerance) {
        // Use the first replacement color, preserving alpha
        return replacementColor * pixel.a;  
    } else if (distance(pixel.rgb, replacementColor.rgb) < tolerance) {
        // If the pixel matches the first replacement color, replace it with the second one
        return replacementColor2 * pixel.a;
    } else {
        // Return the original color if no replacement is applied
        return pixel * color;  
    }
}