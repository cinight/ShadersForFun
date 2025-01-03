Shader "URP/ReflectionProbe"
{
	Properties
	{
		[MainColor] _BaseColor("Color", Color) = (0.5,0.5,0.5,1)
		_Smoothness("Smoothness", Range(0,1)) = 0.5
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
			#pragma multi_compile _ _FORWARD_PLUS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
			
			struct appdata
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float3 normalWS : NORMAL;
			};

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			float _Smoothness;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher
			
			v2f vert (appdata v)
			{
				v2f o;
				
				o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
				o.positionCS = TransformWorldToHClip(o.positionWS.xyz);
				o.normalWS = TransformObjectToWorldNormal(v.normalOS);
	
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float4 col = _BaseColor;
				
				half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(_Smoothness);

				half3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
				float2 normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(i.positionCS);
				half3 reflectVector = reflect(-viewDirWS, i.normalWS);
				half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, i.positionWS, perceptualRoughness, 1.0h, normalizedScreenSpaceUV);

				col.rgb = indirectSpecular;
				return col;
			}
			ENDHLSL
		}
	}
}