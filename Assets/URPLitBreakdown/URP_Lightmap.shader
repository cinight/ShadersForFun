Shader "URP/Lightmap"
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
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			struct appdata
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
			    float2 staticLightmapUV   : TEXCOORD1;
			    float2 dynamicLightmapUV  : TEXCOORD2;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float3 normalWS : NORMAL;
				half3 viewDirWS : TEXCOORD7;

				float2  staticLightmapUV : TEXCOORD8;
				#ifdef DYNAMICLIGHTMAP_ON
				    float2  dynamicLightmapUV : TEXCOORD9; // Dynamic lightmap UVs
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
				o.normalWS = TransformObjectToWorldNormal(v.normalOS);
				o.viewDirWS = GetWorldSpaceNormalizeViewDir(o.positionWS);
				
				o.staticLightmapUV = v.staticLightmapUV.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#ifdef DYNAMICLIGHTMAP_ON
				    o.dynamicLightmapUV = v.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif
	
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float4 col = _BaseColor;

				// LitForwardPass.hlsl > InitializeBakedGIData()
			    #if defined(DYNAMICLIGHTMAP_ON)
			    col.rgb = SAMPLE_GI(i.staticLightmapUV, i.dynamicLightmapUV, 0, i.normalWS);
			    #elif !defined(LIGHTMAP_ON) && (defined(PROBE_VOLUMES_L1) || defined(PROBE_VOLUMES_L2))
			    col.rgb = SAMPLE_GI(0,
			        GetAbsolutePositionWS(i.positionWS),
			        i.normalWS,
			        i.viewDirWS,
			        i.positionCS.xy,
			        1.0,
			        0.0);
			    #endif
				col.rgb = SAMPLE_GI(i.staticLightmapUV, 0, i.normalWS);
				return col;
			}
			ENDHLSL
		}
		UsePass "Universal Render Pipeline/Lit/Meta"
	}
}