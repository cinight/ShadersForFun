Shader "Unlit/HDRP_Lightmap"
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

            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/BuiltinGIUtilities.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 texCoord1 : TEXCOORD1;
                float2 texCoord2 : TEXCOORD2;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float2 texCoord1 : TEXCOORD1;
                float2 texCoord2 : TEXCOORD2;
                float3 positionWS : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float4 tangentWS : TANGENT;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS.xyz);
                o.texCoord1 = v.texCoord1;
                o.texCoord2 = v.texCoord2;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS = float4(TransformObjectToWorldDir(v.tangentOS.xyz), v.tangentOS.w);
                return o;
            }

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher

            float4 frag (v2f i) : SV_Target
            {
				float4 col = _BaseColor;

                float3x3 tangentToWorld = BuildTangentToWorld(i.tangentWS, i.normalWS.xyz);
                float3 backNormalWS = -tangentToWorld[2];

                PositionInputs posInput;
                posInput.positionWS = i.positionWS;

                uint renderingLayers = GetMeshRenderingLayerMask();

                float3 bakeDiffuseLighting = 0;
                float3 backBakeDiffuseLighting = 0;
                SampleBakedGI(  posInput, i.normalWS, backNormalWS, renderingLayers, i.texCoord1.xy, i.texCoord2.xy,
                                bakeDiffuseLighting, backBakeDiffuseLighting);

                col.rgb = bakeDiffuseLighting * GetCurrentExposureMultiplier();
				
				return col;
            }
            ENDHLSL
        }
        UsePass "HDRP/Lit/DEPTHONLY"
    }
}