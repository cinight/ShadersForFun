Shader "URP/LightProbe"
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
			#pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX

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
				float3 normalWS : NORMAL;
				float3 positionWS : TEXCOORD0;

				half3 vertexSH : TEXCOORD8;
			};

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher
			
			v2f vert (appdata v)
			{
				v2f o;
				
				o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
				o.positionCS = TransformWorldToHClip(o.positionWS.xyz);
				o.normalWS = TransformObjectToWorldNormal(v.normalOS);

				float3 viewDir = GetWorldSpaceNormalizeViewDir(o.positionWS);
				o.vertexSH = SampleProbeSHVertex(o.positionWS, o.normalWS, viewDir);
	
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float4 col = _BaseColor;

				col.rgb *= SampleSHPixel(i.vertexSH, i.normalWS);
				
				
				return col;
			}
			ENDHLSL
		}
	}
}