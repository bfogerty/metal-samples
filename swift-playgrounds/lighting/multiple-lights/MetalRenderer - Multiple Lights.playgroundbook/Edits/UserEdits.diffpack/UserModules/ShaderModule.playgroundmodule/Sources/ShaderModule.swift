
public var shaderSource = """
 #include <metal_stdlib>
 using namespace metal;
 
 struct VertexIn {
    float4 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
    float3 normal [[attribute(2)]];
 };
 
 struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float4 worldPosition;
    float4 normalInWorldSpace;
    float4 cameraPositionInWorldSpace;     
 };
 
 struct PerFrameUniforms {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3 cameraPositionInWorldSpace;
    int lightCount;
 };
 
 struct InstanceData
 {
    float4x4 worldMatrix;
 };
 
 struct LightData
 {
     int lightType;
     float3 worldPosition;
     float3 diffuseColor;
     float3 specularColor;
     float specularIntensity;
     float3 attenuation;
     float coneAngle;
     float3 coneDirection;
     float coneAttenuation;
 };
 
 vertex VertexOut vertex_main(const VertexIn vertex_in [[stage_in]],
 constant PerFrameUniforms &perFrame[[buffer(1)]],
 constant InstanceData* instanceData[[buffer(2)]],
 uint instanceId [[instance_id]]) 
 {
    VertexOut out;
 
    float4x4 mvp = perFrame.projectionMatrix * perFrame.viewMatrix * instanceData[instanceId].worldMatrix;
 
    out.position = mvp * vertex_in.position;
    out.uv = vertex_in.uv;
    out.worldPosition = instanceData[instanceId].worldMatrix * float4(vertex_in.position.xyz,1);
    out.normalInWorldSpace = instanceData[instanceId].worldMatrix * float4(vertex_in.normal.xyz,0);
     out.cameraPositionInWorldSpace = float4(perFrame.cameraPositionInWorldSpace.xyz,1);
 
    return out;
 }
 
 float computeAttenuation(float3 attenuationParams, float distanceFromLightToObjectPosition)
 {
    float attenuation = 1.0 / (attenuationParams.x + (attenuationParams.y * distanceFromLightToObjectPosition) + (attenuationParams.z * distanceFromLightToObjectPosition * distanceFromLightToObjectPosition));
 
     return attenuation;
 }
 
 float computeSpecularFactor(float3 normalAndCameraLookHalfVectorNormalized, float3 cameraLookNormalized, float specularIntensity, float diffuseFactor)
 {
    // The purpose of the step function is to ensure we don't show speculate lighting when the light position is behind the model.
    float specularFactor = pow(saturate(dot(normalAndCameraLookHalfVectorNormalized, cameraLookNormalized)), specularIntensity) * step(0.0, diffuseFactor);
 
     return specularFactor;
 }
 
 fragment float4 fragment_main(const VertexOut fragment_in [[stage_in]],
  texture2d<float> baseColorTexture [[texture(0)]],
  constant PerFrameUniforms &perFrame[[buffer(0)]],
  constant LightData* lights[[buffer(1)]]) {    
 
      constexpr sampler textureSampler;
      float3 baseColor = baseColorTexture.sample(textureSampler, fragment_in.uv).rgb;
 
     float3 worldPos = fragment_in.worldPosition.xyz;
     float3 normal = normalize(fragment_in.normalInWorldSpace.xyz);
     float3 cameraPos = fragment_in.cameraPositionInWorldSpace.xyz;
     float3 cameraLook = normalize(worldPos - cameraPos);
     float3 halfVec = normalize(normal + -cameraLook);
 
     float3 diffuseLightColor = float3(0,0,0);
     float3 specularLightColor = float3(0,0,0);
     for(int lightIndex = 0; lightIndex < perFrame.lightCount; ++lightIndex)
     {
         const LightData light = lights[lightIndex];
         float3 lightPos = light.worldPosition;
         float3 lightLook = normalize(worldPos - lightPos);
         float distanceFromLightToObject = distance(lightPos, worldPos);
         float diffuseFactor = 0;
         float diffuseFactorSaturated = 0;
         float attenuation = 0;
         float specularFactor = 0;
 
         if(light.lightType == 0) // Diffuse Light
         {
            diffuseFactor = dot(-lightLook, normal);
            diffuseFactorSaturated = saturate(diffuseFactor);
            attenuation = computeAttenuation(light.attenuation, distanceFromLightToObject);
            specularFactor = computeSpecularFactor(halfVec, -cameraLook, light.specularIntensity, diffuseFactor);
         }
         else if(light.lightType == 1) // Spot light
         {
            float3 coneDirection = normalize(light.coneDirection);
            float spotResult = dot(-lightLook, -coneDirection);
 
            if(spotResult >= cos(light.coneAngle))
            {
                diffuseFactor = dot(-lightLook, normal);
                diffuseFactorSaturated = saturate(diffuseFactor);
 
                attenuation = computeAttenuation(light.attenuation, distanceFromLightToObject);
                attenuation *= pow(spotResult, light.coneAttenuation);
 
                specularFactor = computeSpecularFactor(halfVec, -cameraLook, light.specularIntensity, diffuseFactor);
            }
         }
 
        diffuseLightColor += (baseColor.rgb * light.diffuseColor * diffuseFactorSaturated)*attenuation;
        specularLightColor += (light.specularColor * specularFactor);
     }
     
     float3 finalColor = diffuseLightColor + specularLightColor;
     return float4(finalColor.rgb, 1.0);
 }
 """
