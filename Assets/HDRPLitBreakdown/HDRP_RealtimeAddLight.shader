Shader "Unlit/HDRP_RealtimeAddLight"
{
    Properties
    {
        [MainColor] _BaseColor("Color", Color) = (0.5,0.5,0.5,1)
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
            
            // Must declare these otherwise you get "Undefined punctual shadow filter algorithm" errors
	        #pragma multi_compile_fragment PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
	        #pragma multi_compile_fragment DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
            #pragma multi_compile_fragment AREA_SHADOW_MEDIUM AREA_SHADOW_HIGH

            // For the additional lights
            #pragma multi_compile_fragment USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST

            // Need all these include files to use LightEvaluation.hlsl
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Debug.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/HDShadow.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Sky/PhysicallyBasedSky/PhysicallyBasedSkyCommon.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Builtin/BuiltinData.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/AreaLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Reflection/VolumeProjection.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightEvaluation.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD8;
                float3 normalWS : NORMAL;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS.xyz);
                o.uv = v.uv;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                return o;
            }

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher            

            float4 frag (v2f i) : SV_Target
            {
				float4 col = _BaseColor;

                uint renderingLayers = GetMeshRenderingLayerMask();
                uint2 positionSS = uint2(i.positionCS.xy);
                uint2 tileIndex = uint2(positionSS.xy) / GetTileSize();

                LightLoopContext context;

                PositionInputs posInput;
                ZERO_INITIALIZE(PositionInputs, posInput);
                posInput.positionWS = i.positionWS;
                posInput.tileCoord = tileIndex;

                // Below mainly comes from LightLoop.hlsl

                uint lightCount, lightStart;

                #ifndef LIGHTLOOP_DISABLE_TILE_AND_CLUSTER
                        GetCountAndStart(posInput, LIGHTCATEGORY_PUNCTUAL, lightStart, lightCount);
                #else   // LIGHTLOOP_DISABLE_TILE_AND_CLUSTER
                        lightCount = _PunctualLightCount;
                        lightStart = 0;
                #endif

                bool fastPath = false;
                
                #if SCALARIZE_LIGHT_LOOP
                    uint lightStartLane0;
                    fastPath = IsFastPath(lightStart, lightStartLane0);

                    if (fastPath)
                    {
                        lightStart = lightStartLane0;
                    }
                #endif

                // Scalarized loop. All lights that are in a tile/cluster touched by any pixel in the wave are loaded (scalar load), only the one relevant to current thread/pixel are processed.
                // For clarity, the following code will follow the convention: variables starting with s_ are meant to be wave uniform (meant for scalar register),
                // v_ are variables that might have different value for each thread in the wave (meant for vector registers).
                // This will perform more loads than it is supposed to, however, the benefits should offset the downside, especially given that light data accessed should be largely coherent.
                // Note that the above is valid only if wave intriniscs are supported.
                uint v_lightListOffset = 0;
                uint v_lightIdx = lightStart;

                #if NEED_TO_CHECK_HELPER_LANE
                    // On some platform helper lanes don't behave as we'd expect, therefore we prevent them from entering the loop altogether.
                    // IMPORTANT! This has implications if ddx/ddy is used on results derived from lighting, however given Lightloop is called in compute we should be
                    // sure it will not happen.
                    bool isHelperLane = WaveIsHelperLane();
                    while (!isHelperLane && v_lightListOffset < lightCount)
                #else
                    while (v_lightListOffset < lightCount)
                #endif
                {
                    v_lightIdx = FetchIndex(lightStart, v_lightListOffset);
                        
                    #if SCALARIZE_LIGHT_LOOP
                        uint s_lightIdx = ScalarizeElementIndex(v_lightIdx, fastPath);
                    #else
                        uint s_lightIdx = v_lightIdx;
                    #endif
                        
                    if (s_lightIdx == -1)
                        break;

                    LightData s_lightData = FetchLight(s_lightIdx);

                    // If current scalar and vector light index match, we process the light. The v_lightListOffset for current thread is increased.
                    // Note that the following should really be ==, however, since helper lanes are not considered by WaveActiveMin, such helper lanes could
                    // end up with a unique v_lightIdx value that is smaller than s_lightIdx hence being stuck in a loop. All the active lanes will not have this problem.
                    if (s_lightIdx >= v_lightIdx)
                    {
                        v_lightListOffset++;
                        if (IsMatchingLightLayer(s_lightData.lightLayers, renderingLayers))
                        {
                            float3 L;
                            float4 distances; // {d, d^2, 1/d, d_proj}
                            GetPunctualLightVectors(i.positionWS, s_lightData, L, distances);

                            float4 lightColor = EvaluateLight_Punctual(context, posInput, s_lightData, L, distances);
                            lightColor.rgb *= lightColor.a;
                            lightColor.rgb *= 0.05;
 
                            col.rgb += lightColor.rgb;
                        }
                    }
                }

                col.rgb *= GetCurrentExposureMultiplier();

                return col;
            }
            
            ENDHLSL
        }
        UsePass "HDRP/Lit/DEPTHONLY"
    }
}