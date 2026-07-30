#version 440

layout(location = 0) in vec2 textureCoord;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 resolutionParams;
    vec4 fillColor;
    vec4 sceneParams;
    vec4 shapeA0;
    vec4 shapeA1;
    vec4 shapeA2;
    vec4 shapeA3;
    vec4 shapeA4;
    vec4 shapeA5;
    vec4 shapeA6;
    vec4 shapeA7;
    vec4 shapeB0;
    vec4 shapeB1;
    vec4 shapeB2;
    vec4 shapeB3;
    vec4 shapeB4;
    vec4 shapeB5;
    vec4 shapeB6;
    vec4 shapeB7;
} ubuf;

vec4 shapeA(int index)
{
    if (index == 0) return ubuf.shapeA0;
    if (index == 1) return ubuf.shapeA1;
    if (index == 2) return ubuf.shapeA2;
    if (index == 3) return ubuf.shapeA3;
    if (index == 4) return ubuf.shapeA4;
    if (index == 5) return ubuf.shapeA5;
    if (index == 6) return ubuf.shapeA6;
    return ubuf.shapeA7;
}

vec4 shapeB(int index)
{
    if (index == 0) return ubuf.shapeB0;
    if (index == 1) return ubuf.shapeB1;
    if (index == 2) return ubuf.shapeB2;
    if (index == 3) return ubuf.shapeB3;
    if (index == 4) return ubuf.shapeB4;
    if (index == 5) return ubuf.shapeB5;
    if (index == 6) return ubuf.shapeB6;
    return ubuf.shapeB7;
}

float smin(float a, float b, float smoothness)
{
    if (smoothness <= 0.0) return min(a, b);
    float h = clamp(
        0.5 + 0.5 * (b - a) / smoothness,
        0.0,
        1.0
    );
    return mix(b, a, h) - smoothness * h * (1.0 - h);
}

float shapeDistance(vec4 a, vec4 b, vec2 point)
{
    if (int(a.w + 0.5) == 1) {
        float radius = clamp(b.y, 0.0, min(a.z, b.x));
        vec2 q = abs(point - a.xy) - vec2(a.z, b.x) + radius;
        vec2 positive = max(q, 0.0);
        float smoothing = clamp(b.z, 0.0, 1.0);
        float corner;

        if (smoothing <= 0.0) {
            corner = length(positive);
        } else {
            float exponent = mix(2.0, 5.0, smoothing);
            corner = pow(
                pow(positive.x, exponent) + pow(positive.y, exponent),
                1.0 / exponent
            );
        }

        return corner + min(max(q.x, q.y), 0.0) - radius;
    }

    return length(point - a.xy) - a.z;
}

void main()
{
    int shapeCount = clamp(int(ubuf.sceneParams.x + 0.5), 0, 8);
    if (shapeCount == 0) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 point = textureCoord * ubuf.resolutionParams.xy;
    float distance = shapeDistance(shapeA(0), shapeB(0), point);
    for (int index = 1; index < 8; ++index) {
        if (index >= shapeCount) break;
        distance = smin(
            distance,
            shapeDistance(shapeA(index), shapeB(index), point),
            max(ubuf.resolutionParams.w, 0.0)
        );
    }

    float edgeSoftness = max(ubuf.resolutionParams.z, 0.0);
    float coverage;
    if (edgeSoftness <= 0.0) {
        coverage = step(distance, 0.0);
    } else {
        float antialiasing = max(fwidth(distance), 0.001) * edgeSoftness;
        coverage = 1.0 - smoothstep(
            -antialiasing,
            antialiasing,
            distance
        );
    }

    float opacity = coverage * ubuf.fillColor.a * ubuf.qt_Opacity;
    fragColor = vec4(
        ubuf.fillColor.rgb * coverage * ubuf.qt_Opacity,
        opacity
    );
}
