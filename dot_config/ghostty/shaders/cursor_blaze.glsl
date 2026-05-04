lowp float ease(lowp float x) {
    lowp float invX = 1.0 - x;
    return invX * invX * invX;
}

lowp float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Branch-free winding computation with precomputed inverse squared edge length
lowp float seg(in vec2 p, in vec2 a, in vec2 b, in lowp float invLenSq, inout lowp float s, lowp float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) * invLenSq, 0.0, 1.0);
    lowp float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    lowp float c0 = step(0.0, p.y - a.y);
    lowp float c1 = 1.0 - step(0.0, p.y - b.y);
    lowp float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    lowp float allCond = c0 * c1 * c2;
    lowp float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    lowp float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

lowp float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    lowp float s = 1.0;
    lowp float d = dot(p - v0, p - v0);

    // Precompute inverse squared lengths for the two unique edge directions
    lowp float invLenSq03 = 1.0 / dot(v3 - v0, v3 - v0);
    lowp float invLenSq10 = 1.0 / dot(v0 - v1, v0 - v1);

    d = seg(p, v0, v3, invLenSq03, s, d);
    d = seg(p, v1, v0, invLenSq10, s, d);
    d = seg(p, v2, v1, invLenSq03, s, d);
    d = seg(p, v3, v2, invLenSq10, s, d);

    return s * sqrt(d);
}

vec2 normalizeCoord(vec2 value, lowp float isPosition, lowp float invResY) {
    return (value * 2.0 - iResolution.xy * isPosition) * invResY;
}

lowp float blend(lowp float t)
{
    lowp float sqr = t * t;
    return sqr / (2.0 * (sqr - t) + 1.0);
}

lowp float determineStartVertexFactor(vec2 a, vec2 b) {
    lowp float condition1 = step(b.x, a.x) * step(a.y, b.y);
    lowp float condition2 = step(a.x, b.x) * step(b.y, a.y);
    return 1.0 - max(condition1, condition2);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}

const vec4 TRAIL_COLOR = vec4(1.0, 0.46, 0.8, 1.0);
const vec4 TRAIL_COLOR_ACCENT = vec4(1.0, 0., 0., 1.0);
const lowp float DURATION = .5;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    lowp float invResY = 1.0 / iResolution.y;

    vec2 vu = normalizeCoord(fragCoord, 1., invResY);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(normalizeCoord(iCurrentCursor.xy, 1., invResY), normalizeCoord(iCurrentCursor.zw, 0., invResY));
    vec4 previousCursor = vec4(normalizeCoord(iPreviousCursor.xy, 1., invResY), normalizeCoord(iPreviousCursor.zw, 0., invResY));

    vec2 curSize = currentCursor.zw;
    vec2 prevSize = previousCursor.zw;

    lowp float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
    lowp float invertedVertexFactor = 1.0 - vertexFactor;

    vec2 v0 = vec2(currentCursor.x + curSize.x * vertexFactor, currentCursor.y - curSize.y);
    vec2 v1 = vec2(currentCursor.x + curSize.x * invertedVertexFactor, currentCursor.y);
    vec2 v2 = vec2(previousCursor.x + curSize.x * invertedVertexFactor, previousCursor.y);
    vec2 v3 = vec2(previousCursor.x + curSize.x * vertexFactor, previousCursor.y - prevSize.y);

    vec4 newColor = vec4(fragColor);

    lowp float progress = blend(clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.));
    lowp float easedProgress = ease(progress);

    vec2 centerCC = getRectangleCenter(currentCursor);
    vec2 centerCP = getRectangleCenter(previousCursor);
    lowp float lineLength = distance(centerCC, centerCP);
    lowp float distanceToEnd = distance(vu, centerCC);
    lowp float alphaModifier = clamp(distanceToEnd / (lineLength * easedProgress), 0.0, 1.0);

    lowp float sdfCursor = getSdfRectangle(vu, currentCursor.xy - curSize * offsetFactor, curSize * 0.5);
    lowp float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

    newColor = mix(newColor, TRAIL_COLOR_ACCENT, 1.0 - smoothstep(sdfTrail, -0.01, 0.001));

    lowp float aaScale = iResolution.y * 0.25;
    newColor = mix(newColor, TRAIL_COLOR, 1.0 - clamp(sdfTrail * aaScale, 0.0, 1.0));

    newColor = mix(fragColor, newColor, 1.0 - alphaModifier);
    fragColor = mix(newColor, fragColor, step(sdfCursor, 0.));
}
