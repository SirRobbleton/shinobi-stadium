shader_type canvas_item;
render_mode blend_add, unshaded;
void fragment()
{
// Distance from each edge in UV space (0 to 1)
float dist_left = UV.x;
float dist_right = 1.0 - UV.x;
float dist_top = UV.y;
float dist_bottom = 1.0 - UV.y;
// The closest edge distance
float closest = min(min(dist_left, dist_right), min(dist_top, dist_bottom));
// Control how much it fades from the edges (like "radius" in radial)
// 0.2 means a 20% fade zone from the outer edges
float edge_fade = 0.2;
// 1.0 - smoothstep(...) will produce a glow that’s strong at edges and
// smoothly fades inwards
float glow = 1.0 - smoothstep(0.0, edge_fade, closest);
// Glow color and alpha; feel free to adjust
COLOR = vec4(1.0, 0.8, 0.4, glow * 0.5);
}