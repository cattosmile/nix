#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 textureCoord;

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

void main()
{
    textureCoord = qt_MultiTexCoord0;
    gl_Position = ubuf.qt_Matrix * qt_Vertex;
}
