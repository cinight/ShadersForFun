Shader "Unlit/HDRP_ReflectionProbe"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (0.5,0.5,0.5,1)
        _Smoothness("Smoothness", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "HDRenderPipeline" }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "Forward" }
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD8;
                float3 normalWS : NORMAL;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                return o;
            }

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
            float _Smoothness;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher

            // Copied from LightEvaluation.hlsl otherwise there will be a hell of include file dependencies
            float ComputeDistanceBaseRoughness_Copy(float distIntersectionToShadedPoint, float distIntersectionToProbeCenter, float perceptualRoughness)
            {
                float newPerceptualRoughness = clamp(distIntersectionToShadedPoint / distIntersectionToProbeCenter * perceptualRoughness, 0, perceptualRoughness);
                return lerp(newPerceptualRoughness, perceptualRoughness, perceptualRoughness);
            }

            // Copied from LightEvaluation.hlsl otherwise there will be a hell of include file dependencies
            float4 SampleEnvWithDistanceBaseRoughness_Copy(LightLoopContext lightLoopContext, PositionInputs posInput, EnvLightData lightData, float3 R, float perceptualRoughness, float intersectionDistance, int sliceIdx = 0)
            {
                // Only apply distance based roughness for non-sky reflection probe
                if (lightLoopContext.sampleReflection == SINGLE_PASS_CONTEXT_SAMPLE_REFLECTION_PROBES && IsEnvIndexCubemap(lightData.envIndex))
                {
                    perceptualRoughness = lerp(perceptualRoughness, ComputeDistanceBaseRoughness_Copy(intersectionDistance, length(R), perceptualRoughness), lightData.distanceBasedRoughness);
                }

                return SampleEnv(lightLoopContext, lightData.envIndex, R, PerceptualRoughnessToMipmapLevel(perceptualRoughness) * lightData.roughReflections, lightData.rangeCompressionFactorCompensation, posInput.positionNDC, sliceIdx);
            }
            
            float4 frag (v2f i) : SV_Target
            {
				float4 col = _BaseColor;

                PositionInputs posInput;
                posInput.positionWS = i.positionWS;
                posInput.positionSS = uint2(i.positionCS.xy);
                posInput.positionNDC = posInput.positionSS;
                posInput.positionNDC *= _ScreenSize.zw;
                
                float3 V = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float3 R = reflect(-V, i.normalWS);
                float roughness = 1.0-_Smoothness;

                LightLoopContext context;
                context.sampleReflection = SINGLE_PASS_CONTEXT_SAMPLE_REFLECTION_PROBES;

                // Scalarized loop, same rationale of the punctual light version
                uint envLightStart = 0;
                uint envLightCount =_EnvLightCount;
                uint v_envLightListOffset = 0;
                uint v_envLightIdx = envLightStart;
            
                #if NEED_TO_CHECK_HELPER_LANE
                    // On some platform helper lanes don't behave as we'd expect, therefore we prevent them from entering the loop altogether.
                    // IMPORTANT! This has implications if ddx/ddy is used on results derived from lighting, however given Lightloop is called in compute we should be
                    // sure it will not happen.
                    bool isHelperLane = WaveIsHelperLane();
                    while (!isHelperLane && v_envLightListOffset < envLightCount)
                #else
                    while (v_envLightListOffset < envLightCount)
                #endif
                {
                    v_envLightIdx = FetchIndex(envLightStart, v_envLightListOffset);
                                
                    EnvLightData s_envLightData = FetchEnvLight(v_envLightIdx);    // Scalar load.
                    float4 preLD = SampleEnvWithDistanceBaseRoughness_Copy(context, posInput, s_envLightData, R, roughness, 0.0);
                    col.rgb += preLD.rgb;

                    v_envLightListOffset++;
                }

				col.rgb *= GetCurrentExposureMultiplier();
				return col;
            }
            ENDHLSL
        }
        UsePass "HDRP/Lit/DEPTHONLY"
    }
}