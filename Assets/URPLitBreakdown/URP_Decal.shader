Shader "URP/Decal"
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
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			
			struct appdata
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float3 normalWS : NORMAL;
			};

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher
			
			v2f vert (appdata v)
			{
				v2f o;
				
		        o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
				o.normalWS = TransformObjectToWorldNormal(v.normalOS);
	
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float4 col = _BaseColor;

				#if defined(_DBUFFER)

				half3 baseColor = col.rgb;
				half3 specularColor = 0;
				half3 normalWS = i.normalWS;
				half metallic = 0;
				half occlusion = 1;
				half smoothness = 1;

			    ApplyDecal( i.positionCS,
			        baseColor,
			        specularColor,
			        normalWS,
			        metallic,
			        occlusion,
			        smoothness);

				col.rgb = baseColor;
				
				#endif
				
				return col;
			}
			ENDHLSL
		}
		UsePass "Universal Render Pipeline/Lit/DepthNormals"
	}
}