
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
 vertex VertexOut vertex_main(const VertexIn vertex_in [[stage_in]]) {
     VertexOut out;
     out.position = vertex_in.position;
     out.color = vertex_in.color;
   return out;
 }
 fragment float4 fragment_main(const VertexOut fragment_in [[stage_in]]) {
   return fragment_in.color;
 }
 """
