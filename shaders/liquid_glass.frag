// Liquid Glass backdrop shader (Impeller only; see GlassContainer).
//
// Models a slab of glass with a flat, clear centre and a rounded bevel along
// its edge. Across the bevel the surface curves away, so light reaching the
// eye there was bent in from *outside* the shape: content around the glass is
// pulled into and squeezed along the rim (lensing), with a little chromatic
// dispersion. The centre passes the backdrop through untouched apart from an
// optional light frost, a vibrancy boost and an adaptive tint.
//
// Coordinates: as a BackdropFilter, FlutterFragCoord() is in render-target
// pixels (top-left origin on every backend) and the input texture is the
// whole backdrop, so u_rect must be the glass bounds in that same space.

#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;          // Set by the engine: backdrop texture size (px).
uniform vec4 u_rect;          // Glass bounds in backdrop px: x, y, w, h.
uniform vec4 u_shape;         // Corner radius, bevel width, max refraction
                              // offset, normal-field radius (all px).
uniform vec4 u_optics;        // Dispersion (0..1), frost radius (px),
                              // saturation, specular strength.
uniform vec4 u_tint;          // Tint colour (straight alpha) and base opacity.
uniform float u_adaptive;     // Extra tint where content would fight legibility.

uniform sampler2D u_texture;  // Set by the engine: the backdrop.

out vec4 frag_color;

const vec3 kLuma = vec3(0.2126, 0.7152, 0.0722);

// Signed distance to a rounded box centred at the origin (negative inside).
float sdRoundBox(vec2 q, vec2 halfSize, float r) {
  vec2 a = abs(q) - halfSize + r;
  return length(max(a, 0.0)) + min(max(a.x, a.y), 0.0) - r;
}

// Outward surface direction. Uses a corner radius of at least the bevel width
// so the field is smooth wherever the bevel bends light.
vec2 outwardNormal(vec2 q, vec2 halfSize, float r) {
  vec2 s = vec2(q.x < 0.0 ? -1.0 : 1.0, q.y < 0.0 ? -1.0 : 1.0);
  vec2 a = abs(q) - halfSize + r;
  if (a.x > 0.0 && a.y > 0.0) {
    return s * normalize(a);
  }
  return a.x > a.y ? vec2(s.x, 0.0) : vec2(0.0, s.y);
}

vec3 tap(vec2 px) {
  px = clamp(px, vec2(0.5), u_size - vec2(0.5));
  vec2 uv = px / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(u_texture, uv).rgb;
}

// Backdrop colour at px, optionally softened by a small 9-tap disc.
vec3 scene(vec2 px, float frost) {
  if (frost < 0.5) {
    return tap(px);
  }
  float d = frost * 0.7071;
  vec3 c = tap(px) * 0.20;
  c += (tap(px + vec2(frost, 0.0)) + tap(px - vec2(frost, 0.0)) +
        tap(px + vec2(0.0, frost)) + tap(px - vec2(0.0, frost))) * 0.12;
  c += (tap(px + vec2(d, d)) + tap(px - vec2(d, d)) +
        tap(px + vec2(d, -d)) + tap(px - vec2(d, -d))) * 0.08;
  return c;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 halfSize = u_rect.zw * 0.5;
  vec2 q = p - (u_rect.xy + halfSize);

  float radius = u_shape.x;
  float bevel = max(u_shape.y, 1.0);
  float refraction = u_shape.z;

  // 1 at the rim, 0 where the bevel meets the flat centre.
  float depth = max(-sdRoundBox(q, halfSize, radius), 0.0);
  float k = 1.0 - clamp(depth / bevel, 0.0, 1.0);
  // Circular bevel profile: zero slope at the centre, steep at the rim.
  float lens = 1.0 - sqrt(max(1.0 - k * k, 0.0));

  vec2 n = outwardNormal(q, halfSize, u_shape.w);
  vec2 offset = n * refraction * lens;

  float dispersion = u_optics.x;
  float frost = u_optics.y;
  vec3 col;
  if (dot(offset, offset) * dispersion * dispersion < 0.25) {
    col = scene(p + offset, frost);
  } else {
    // Shorter wavelengths bend more.
    col.r = scene(p + offset * (1.0 - dispersion), frost).r;
    col.g = scene(p + offset, frost).g;
    col.b = scene(p + offset * (1.0 + dispersion), frost).b;
  }

  // Vibrancy.
  col = clamp(mix(vec3(dot(col, kLuma)), col, u_optics.z), 0.0, 1.0);

  // Adaptive tint: a dark tint thickens over bright content and a light tint
  // over dark content, so foreground text stays legible on clear glass. It
  // only ramps up for strongly conflicting content; mid-tones stay clear.
  float lum = dot(col, kLuma);
  float fight = dot(u_tint.rgb, kLuma) > 0.5 ? 1.0 - lum : lum;
  fight = smoothstep(0.35, 1.0, fight);
  col = mix(col, u_tint.rgb, clamp(u_tint.a + u_adaptive * fight, 0.0, 1.0));

  // Light from the top-left catching the bevel, and a fainter internal
  // reflection on the opposite edge.
  float facing = dot(n, vec2(-0.7071, -0.7071));
  float band = k * k * k;
  float spec = band * (0.55 * pow(max(facing, 0.0), 2.0) +
                       0.25 * pow(max(-facing, 0.0), 2.0));
  col += u_optics.w * spec;

  frag_color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
