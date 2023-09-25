
public var shaderSource = """
 #include <metal_stdlib>
 using namespace metal;
 struct VertexIn {
   float4 position [[attribute(0)]];
   float4 color [[attribute(1)]];
 };
 struct VertexOut {
     float4 position [[position]];
     float4 color;
 };
 
 struct Uniforms {
    float4x4 worldMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float aspectRatio;
 };
 
 vertex VertexOut vertex_main(const VertexIn vertex_in [[stage_in]],
 constant Uniforms &uniforms[[buffer(1)]]) {
     VertexOut out;
 
     //float4x4 mvp = uniforms.worldMatrix * uniforms.viewMatrix * uniforms.projectionMatrix;
 
 float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.worldMatrix;
 
    out.position = mvp * vertex_in.position;
 
     out.color = vertex_in.color;
     out.color.rgb *= 2.0;
   return out;
 }
 fragment float4 fragment_main(const VertexOut fragment_in [[stage_in]]) {
   return fragment_in.color;
 }
 """
