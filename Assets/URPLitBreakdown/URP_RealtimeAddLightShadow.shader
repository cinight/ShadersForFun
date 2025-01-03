Shader "URP/RealtimeAddLightShadow"
{
	Properties
	{
		[MainColor] _BaseColor("Color", Color) = (0.5,0.5,0.5,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

		Pass
		{
			Tags { "LightMode" = "UniversalForward" }

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			struct appdata
			{
				float4 positionOS : POSITION;

			    float2 staticLightmapUV   : TEXCOORD1;
			    float2 dynamicLightmapUV  : TEXCOORD2;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
			};

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher
			
			v2f vert (appdata v)
			{
				v2f o;
				
				o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
				o.positionCS = TransformWorldToHClip(o.positionWS.xyz);

				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				float4 col = _BaseColor;

				// Dummy input data because LIGHT_LOOP_BEGIN uses it sneakily
				InputData inputData;
				inputData.fogCoord = 0;
				inputData.positionWS = i.positionWS;
				inputData.normalWS = 0;
				inputData.bakedGI = 0;
				inputData.positionCS = 0;
				inputData.tangentToWorld = 0;
				inputData.viewDirectionWS = 0;
				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.positionCS);
				inputData.shadowCoord = 0;
				inputData.shadowMask = 0;

				half4 shadowMask = 0;

				uint meshRenderingLayers = GetMeshRenderingLayer();
			    #if defined(_ADDITIONAL_LIGHTS)
				
					uint pixelLightCount = GetAdditionalLightsCount();

				    #if USE_FORWARD_PLUS
				    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
				    {
				        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

				        Light light = GetAdditionalLight(lightIndex, i.positionWS, shadowMask);

						#ifdef _LIGHT_LAYERS
				        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						#endif
				        {
				        	col.rgb = min(col.rgb, light.shadowAttenuation);
				        }
				    }
				    #endif

				    LIGHT_LOOP_BEGIN(pixelLightCount)
				        Light light = GetAdditionalLight(lightIndex, i.positionWS, shadowMask);

						#ifdef _LIGHT_LAYERS
				        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						#endif
				        {
				            col.rgb = min(col.rgb, light.shadowAttenuation);
				        }
				    LIGHT_LOOP_END
				
			    #endif
				
				return col;
			}
			ENDHLSL
		}
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"
	}
}