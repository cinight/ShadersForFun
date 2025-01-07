Shader "Unlit/HDRP_RealtimeMainLight"
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
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normalWS : NORMAL;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
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

                    if (_DirectionalShadowIndex >= 0)
                    {
                        DirectionalLightData light = _DirectionalLightDatas[_DirectionalShadowIndex];
                        half NdotL = saturate(dot(i.normalWS, -light.forward));
                        half3 lightColor = light.color * GetCurrentExposureMultiplier();
                        col.rgb *= NdotL * lightColor;
                    }
            
                return col;
            }
            
            ENDHLSL
        }
        UsePass "HDRP/Lit/DEPTHONLY"
    }
}