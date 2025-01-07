Shader "Unlit/HDRP_SSAO"
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

            #define SHADERPASS SHADERPASS_FORWARD
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Debug.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Builtin/BuiltinData.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl" //This defines the SHADERPASS macro
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/MaterialEvaluation.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                return o;
            }

			UNITY_INSTANCING_CBUFFER_SCOPE_BEGIN(UnityPerMaterial) //SRPBatcher
			float4 _BaseColor;
			UNITY_INSTANCING_CBUFFER_SCOPE_END //SRPBatcher

            float4 frag (v2f i) : SV_Target
            {
				float4 col = _BaseColor;

                uint2 positionSS = uint2(i.positionCS.xy);
                col.rgb = GetScreenSpaceAmbientOcclusion(positionSS);
				
				return col;
            }
            ENDHLSL
        }
        UsePass "HDRP/Lit/DEPTHONLY"
    }
}