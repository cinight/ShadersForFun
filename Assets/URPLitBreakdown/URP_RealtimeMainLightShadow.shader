Shader "URP/RealtimeMainLightShadow"
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
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
			
			struct appdata
			{
				float4 positionOS : POSITION;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				    float4 shadowCoord              : TEXCOORD6;
				#endif
			};

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher
			
			v2f vert (appdata v)
			{
				v2f o;
				
				o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
				o.positionCS = TransformWorldToHClip(o.positionWS.xyz);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
				    o.shadowCoord = GetShadowCoord(vertexInput);
				#endif
	
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float4 col = _BaseColor;

				// LitForwardPass.hlsl > InitializeInputData()
				float4 shadowCoord = float4(0, 0, 0, 0);
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				    shadowCoord = i.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
				    shadowCoord = TransformWorldToShadowCoord(i.positionWS);
				#endif
				
				Light mainLight = GetMainLight(shadowCoord, i.positionWS, 0);
				col.rgb = mainLight.shadowAttenuation;
				
				return col;
			}
			ENDHLSL
		}
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"
	}
}